import { spawnSync } from "node:child_process";
import { copyFile, mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { constants } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

const home = homedir();
const root = resolve(import.meta.dirname, "..");
const config = process.env.XDG_CONFIG_HOME ?? join(home, ".config");
const syncCommand = process.argv[2];
if (!syncCommand) throw new Error("usage: install-sync.ts <sync command path>");

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
const materialize = spawnSync("ryoku", ["materialize"], { stdio: "inherit" });
if (materialize.status !== 0) throw new Error(`ryoku materialize exited with ${materialize.status ?? materialize.error}; the palette hook is saved in ${overlayApps} and applies on the next one.`);

const settings = join(home, ".config/zed/settings.json");
const currentSettings = await readFile(settings, "utf8");
const themeField = /^([\t ]*"theme"[\t ]*:[\t ]*)"(?:[^"\\]|\\.)*"([\t ]*,?)[\t ]*$/gm;
const matches = [...currentSettings.matchAll(themeField)];
if (matches.length !== 1) throw new Error(`Expected one string-valued theme setting in ${settings}; left it unchanged.`);
const selectedSettings = currentSettings.replace(themeField, `$1"Ryoku Dynamic Dark"$2`);
if (selectedSettings !== currentSettings) {
  const backup = `${settings}.ryoku-backup-${Date.now()}`;
  await copyFile(settings, backup, constants.COPYFILE_EXCL);
  const temp = `${settings}.ryoku-tmp-${Date.now()}`;
  await writeFile(temp, selectedSettings, { mode: 0o600, flag: "wx" });
  await rename(temp, settings);
  console.log(`Selected Ryoku Dynamic Dark in ${settings}; preserved the original as ${backup}.`);
} else {
  console.log(`Ryoku Dynamic Dark is already selected in ${settings}; left settings unchanged.`);
}
console.log("Installed the palette hook. Matugen runs it after each palette change; it writes ryoku-dynamic.json beside matugen.json.");
