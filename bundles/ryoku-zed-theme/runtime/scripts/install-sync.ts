import { spawnSync } from "node:child_process";
import { access, copyFile, mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

const home = homedir();
const root = resolve(import.meta.dirname, "..");
const config = process.env.XDG_CONFIG_HOME ?? join(home, ".config");
const syncCommand = process.argv[2];
if (!syncCommand) throw new Error("usage: install-sync.ts <sync command path>");
if (!isAbsolute(syncCommand)) throw new Error(`sync command must be an absolute path: ${syncCommand}`);

// Validate that the sync command exists and is executable before touching
// apps.toml, so a later failure cannot leave a post_hook pointing at nothing.
try {
  await access(syncCommand, constants.X_OK);
} catch {
  throw new Error(`sync command does not exist or is not executable: ${syncCommand}`);
}

const initialSync = spawnSync(process.execPath, [join(root, "scripts/theme.ts"), "--sync"], { cwd: root, stdio: "inherit" });
if (initialSync.status !== 0) throw new Error(`Initial theme sync exited with ${initialSync.status}; no palette hook was installed.`);

// Matugen renders matugen.json on every palette change, on every Ryoku edition,
// so a post_hook on that template keeps ryoku-dynamic.json in step without a
// watcher service. Ryoku keeps user changes to apps.toml in its user_edits
// overlay (seeded from the shipped file, as the palette bridge does).
const overlayDir = join(config, "ryoku/user_edits/matugen");
const overlayApps = join(overlayDir, "apps.toml");
let apps: string;
try {
  apps = await readFile(overlayApps, "utf8");
} catch (error) {
  if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) throw error;
  apps = await readFile(join(config, "matugen/apps.toml"), "utf8");
}
const lines = apps.split("\n");
const start = lines.findIndex((line) => line.trim() === "[templates.zed]");
if (start < 0) throw new Error(`${overlayApps} has no [templates.zed] section; the hook was not installed.`);
let end = lines.findIndex((line, index) => index > start && /^\s*\[/.test(line));
if (end < 0) end = lines.length;
const body = lines.slice(start + 1, end).filter((line) => !/^\s*post_hook\s*=/.test(line));
let last = body.length;
while (last > 0 && body[last - 1].trim() === "") last--;
const quoted = `'${syncCommand.replaceAll("'", `'\\''`)}'`;
body.splice(last, 0, `post_hook = ${JSON.stringify(quoted)}`);
const updated = [...lines.slice(0, start + 1), ...body, ...lines.slice(end)].join("\n");
if (updated !== apps) {
  await mkdir(overlayDir, { recursive: true });
  const temp = `${overlayApps}.ryoku-tmp-${Date.now()}`;
  await writeFile(temp, updated, { mode: 0o644, flag: "wx" });
  await rename(temp, overlayApps);
}

// Do NOT call `ryoku materialize` here. It reloads the window manager
// (Hyprland config.reload), which re-initialises DRM/KMS on hybrid NVIDIA
// multi-monitor setups, drops signal (black screens) and can change resolution.
// The initial theme sync above already generated the theme JSON; the post_hook
// we just registered will apply it on the next palette change.

const settings = join(home, ".config/zed/settings.json");

// --- JSONC-aware Zed settings editor ---
// Supports // line comments, /* block */ comments, trailing commas, escaped
// quotes in strings. A "theme" inside a comment, string value, or nested object
// is never treated as the top-level setting.

type Span = { start: number; end: number };
type Replace = { start: number; end: number; value: string };

// Mask JSONC source into structure-only text using UTF-16 code units, so
// masked.length === text.length even with non-BMP characters (emojis).
function maskJsonc(text: string): string {
  const out = text.split("");
  let i = 0;
  while (i < out.length) {
    if (out[i] === "/" && out[i + 1] === "/") {
      out[i] = " "; out[i + 1] = " ";
      i += 2;
      while (i < out.length && out[i] !== "\n") { out[i] = " "; i++; }
      continue;
    }
    if (out[i] === "/" && out[i + 1] === "*") {
      out[i] = " "; out[i + 1] = " ";
      i += 2;
      while (i < out.length && !(out[i] === "*" && out[i + 1] === "/")) { out[i] = " "; i++; }
      if (i < out.length) { out[i] = " "; out[i + 1] = " "; i += 2; }
      continue;
    }
    if (out[i] === '"') {
      out[i] = '"';
      i++;
      while (i < out.length && out[i] !== '"') {
        if (out[i] === "\\" && i + 1 < out.length) { out[i] = " "; out[i + 1] = " "; i += 2; }
        else { out[i] = " "; i++; }
      }
      if (i < out.length) { out[i] = '"'; i++; }
      continue;
    }
    i++;
  }
  return out.join("");
}

function skipWS(masked: string, pos: number): number {
  while (pos < masked.length) {
    if (/\s/.test(masked[pos])) { pos++; continue; }
    if (masked[pos] === "/" && masked[pos + 1] === "/") {
      pos += 2;
      while (pos < masked.length && masked[pos] !== "\n") pos++;
      continue;
    }
    if (masked[pos] === "/" && masked[pos + 1] === "*") {
      pos += 2;
      while (pos < masked.length && !(masked[pos] === "*" && masked[pos + 1] === "/")) pos++;
      if (pos < masked.length) pos += 2;
      continue;
    }
    break;
  }
  return pos;
}

function findBrace(masked: string, openPos: number): number {
  let depth = 0;
  for (let i = openPos; i < masked.length; i++) {
    if (masked[i] === "{") depth++;
    else if (masked[i] === "}") { depth--; if (depth === 0) return i; }
  }
  return -1;
}

function strSpan(text: string, qPos: number): Span {
  let i = qPos + 1;
  while (i < text.length && text[i] !== '"') {
    if (text[i] === "\\" && i + 1 < text.length) i += 2;
    else i++;
  }
  return { start: qPos, end: i + 1 };
}

// End of a scalar/array/object value starting at pos in masked text.
function valueEnd(masked: string, pos: number): number {
  pos = skipWS(masked, pos);
  if (pos >= masked.length) return pos;
  if (masked[pos] === '"') return strSpan(masked, pos).end;
  if (masked[pos] === "{") return findBrace(masked, pos) + 1;
  if (masked[pos] === "[") {
    let d = 0, j = pos;
    while (j < masked.length) { if (masked[j] === "[") d++; else if (masked[j] === "]") { d--; if (d === 0) return j + 1; } j++; }
    return masked.length;
  }
  let j = pos;
  while (j < masked.length && !/[,\]}]/.test(masked[j]) && /\S/.test(masked[j])) j++;
  return j;
}

// Last non-whitespace position in masked text within [start, end).
function lastNonSpace(masked: string, start: number, end: number): number {
  let p = end - 1;
  while (p >= start && /\s/.test(masked[p])) p--;
  return p;
}

function findRootObject(masked: string): Span | null {
  let pos = skipWS(masked, 0);
  if (pos >= masked.length || masked[pos] !== "{") return null;
  const cb = findBrace(masked, pos);
  return cb >= 0 ? { start: pos, end: cb } : null;
}

type ThemeLookup =
  | { valueStart: number }
  | { noTheme: true; hasProps: boolean; lastValueEnd: number }
  | { malformed: true };

function findThemeKey(masked: string, text: string): ThemeLookup {
  const root = findRootObject(masked);
  if (!root) return { malformed: true };
  let pos = root.start + 1, hasProps = false, lastValueEnd = 0;
  while (pos < root.end) {
    pos = skipWS(masked, pos);
    if (pos >= root.end || masked[pos] === "}") break;
    if (masked[pos] === ",") { pos++; continue; }
    if (masked[pos] !== '"') return { malformed: true };
    const ks = strSpan(text, pos);
    if (ks.end > root.end) return { malformed: true };
    const key = text.slice(ks.start + 1, ks.end - 1);
    pos = skipWS(masked, ks.end);
    if (pos >= root.end || masked[pos] !== ":") return { malformed: true };
    pos++;
    const vs = skipWS(masked, pos);
    if (vs >= root.end) return { malformed: true };
    if (key === "theme") return { valueStart: vs };
    const ve = valueEnd(masked, vs);
    if (ve <= vs) return { malformed: true };
    hasProps = true;
    lastValueEnd = ve;
    pos = skipWS(masked, ve);
    if (pos < root.end && masked[pos] === ",") pos++;
  }
  return { noTheme: true, hasProps, lastValueEnd };
}

function applyReplacements(text: string, replacements: Replace[]): string {
  replacements.sort((a, b) => b.start - a.start);
  let out = text;
  for (const r of replacements) out = out.slice(0, r.start) + r.value + out.slice(r.end);
  return out;
}

// Insert one or more properties at the end of a JSONC object. The comma stays
// attached to the last value (before any trailing comment), and the new lines
// go after that comment, next to the closing brace.
function appendProperties(
  text: string,
  masked: string,
  containerStart: number,
  containerEnd: number,
  hasProps: boolean,
  lastValueEnd: number,
  indent: string,
  lines: string[],
  closingIndent: string,
): Replace[] {
  const insertAt = lastNonSpace(text, containerStart, containerEnd) + 1;
  const suffix = text[insertAt] === "}" ? `\n${closingIndent}` : "";
  const body = `\n${indent}${lines.join(`,\n${indent}`)}${suffix}`;
  const needsComma = hasProps && !masked.slice(lastValueEnd, containerEnd).includes(",");
  if (needsComma && insertAt === lastValueEnd) {
    return [{ start: insertAt, end: insertAt, value: `,${body}` }];
  }
  const replacements: Replace[] = [];
  if (needsComma) replacements.push({ start: lastValueEnd, end: lastValueEnd, value: "," });
  replacements.push({ start: insertAt, end: insertAt, value: body });
  return replacements;
}

function detectIndent(text: string, fallback = "  "): string {
  const m = text.match(/^(\s+)"/m);
  return m ? m[1] : fallback;
}

function detectInnerIndent(text: string, base: string): string {
  if (base.includes("\t")) return base + "\t";
  return base + "  ";
}

async function selectTheme(): Promise<void> {
  let cur: string;
  try { cur = await readFile(settings, "utf8"); }
  catch (e) {
    if (e instanceof Error && "code" in e && e.code === "ENOENT") {
      await mkdir(join(settings, ".."), { recursive: true });
      const fresh = '{\n  "theme": "Ryoku Dynamic Dark"\n}\n';
      const t = `${settings}.ryoku-tmp-${Date.now()}`;
      await writeFile(t, fresh, { mode: 0o600, flag: "wx" });
      await rename(t, settings);
      console.log(`Created ${settings} with Ryoku Dynamic Dark selected.`);
      return;
    }
    throw e;
  }

  const masked = maskJsonc(cur);
  const rootObj = findRootObject(masked);
  if (!rootObj) {
    console.warn(`Warning: ${settings} has no root object; left it unchanged.`);
    return;
  }

  const info = findThemeKey(masked, cur);

  if (info && "malformed" in info) {
    console.warn(`Warning: ${settings} is not valid JSONC; left it unchanged.`);
    return;
  }

  if (info && "noTheme" in info) {
    // No top-level theme property: attach a comma to the last value (before any
    // trailing comment) and insert the property after the comment.
    const ind = detectIndent(cur);
    const repls = appendProperties(
      cur, masked, rootObj.start, rootObj.end, info.hasProps, info.lastValueEnd,
      ind, ['"theme": "Ryoku Dynamic Dark"'], "",
    );
    const out = applyReplacements(cur, repls);
    const bk = `${settings}.ryoku-backup-${Date.now()}`;
    await copyFile(settings, bk, constants.COPYFILE_EXCL);
    const t = `${settings}.ryoku-tmp-${Date.now()}`;
    await writeFile(t, out, { mode: 0o600, flag: "wx" });
    await rename(t, settings);
    console.log(`Selected Ryoku Dynamic Dark in ${settings}; preserved the original as ${bk}.`);
    return;
  }

  const { valueStart: vs } = info;
  if (vs >= masked.length) { console.warn(`Warning: ${settings} has incomplete theme value; left it unchanged.`); return; }

  if (masked[vs] === '"') {
    const ss = strSpan(cur, vs);
    if (cur.slice(ss.start + 1, ss.end - 1) === "Ryoku Dynamic Dark") {
      console.log(`Ryoku Dynamic Dark is already selected in ${settings}; left settings unchanged.`); return;
    }
    const out = cur.slice(0, ss.start) + '"Ryoku Dynamic Dark"' + cur.slice(ss.end);
    const bk = `${settings}.ryoku-backup-${Date.now()}`;
    await copyFile(settings, bk, constants.COPYFILE_EXCL);
    const t = `${settings}.ryoku-tmp-${Date.now()}`;
    await writeFile(t, out, { mode: 0o600, flag: "wx" });
    await rename(t, settings);
    console.log(`Selected Ryoku Dynamic Dark in ${settings}; preserved the original as ${bk}.`);
    return;
  }

  if (masked[vs] === "{") {
    const cb = findBrace(masked, vs);
    if (cb < 0) { console.warn(`Warning: ${settings} has malformed theme object; left it unchanged.`); return; }
    const objM = masked.slice(vs, cb + 1);
    const objT = cur.slice(vs, cb + 1);
    const repls: Replace[] = [];
    let sp = 1, fd = false, fl = false, hasProps = false, lastValEnd = 1;
    while (sp < objM.length) {
      sp = skipWS(objM, sp);
      if (sp >= objM.length || objM[sp] === "}") break;
      if (objM[sp] === ",") { sp++; continue; }
      if (objM[sp] !== '"') { console.warn(`Warning: ${settings} has a malformed theme object; left it unchanged.`); return; }
      const ks = strSpan(objT, sp);
      const kv = objT.slice(ks.start + 1, ks.end - 1);
      sp = skipWS(objM, ks.end);
      if (sp >= objM.length || objM[sp] !== ":") { console.warn(`Warning: ${settings} has a malformed theme object; left it unchanged.`); return; }
      sp++;
      const vst = skipWS(objM, sp);
      if (vst >= objM.length) { console.warn(`Warning: ${settings} has a malformed theme object; left it unchanged.`); return; }
      const ve = valueEnd(objM, vst);
      if (ve <= vst) { console.warn(`Warning: ${settings} has a malformed theme object; left it unchanged.`); return; }
      if (kv === "dark" || kv === "light") {
        const want = kv === "dark" ? "Ryoku Dynamic Dark" : "Ryoku Dynamic Light";
        if (objM[vst] === '"') {
          const vsp = strSpan(objT, vst);
          if (objT.slice(vsp.start + 1, vsp.end - 1) !== want)
            repls.push({ start: vs + vsp.start, end: vs + vsp.end, value: `"${want}"` });
        } else {
          repls.push({ start: vs + vst, end: vs + ve, value: `"${want}"` });
        }
        if (kv === "dark") fd = true;
        else fl = true;
      }
      hasProps = true;
      lastValEnd = ve;
      sp = skipWS(objM, ve);
      if (sp < objM.length && objM[sp] === ",") sp++;
    }
    if (!fd || !fl) {
      const ind = detectInnerIndent(objT.slice(1, objT.length - 1), detectIndent(cur));
      const missing: string[] = [];
      if (!fd) missing.push('"dark": "Ryoku Dynamic Dark"');
      if (!fl) missing.push('"light": "Ryoku Dynamic Light"');
      repls.push(...appendProperties(cur, masked, vs, cb, hasProps, vs + lastValEnd, ind, missing, detectIndent(cur)));
    }
    if (repls.length === 0) {
      console.log(`Ryoku Dynamic themes are already selected in ${settings}; left settings unchanged.`); return;
    }
    const out = applyReplacements(cur, repls);
    const bk = `${settings}.ryoku-backup-${Date.now()}`;
    await copyFile(settings, bk, constants.COPYFILE_EXCL);
    const t = `${settings}.ryoku-tmp-${Date.now()}`;
    await writeFile(t, out, { mode: 0o600, flag: "wx" });
    await rename(t, settings);
    console.log(`Selected Ryoku Dynamic themes in ${settings}; preserved the original as ${bk}.`);
    return;
  }

  console.warn(`Warning: ${settings} has an unexpected theme value type; left it unchanged.`);
}

await selectTheme();
console.log("Installed the palette hook. Matugen runs it after each palette change; it writes ryoku-dynamic.json beside matugen.json.");
