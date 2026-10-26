#!/usr/bin/env bash
# Regression tests for the ryoku-zed-theme bundle.
#
# The installer must never reload the window manager, must keep both installer
# copies byte-identical, must create its sync command before registering the
# Matugen hook, and must edit Zed's JSONC settings without losing comments or
# corrupting the file.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime="$repo_root/bundles/ryoku-zed-theme/runtime/scripts/install-sync.ts"
installer="$repo_root/bundles/ryoku-zed-theme/installers/ryoku-zed-theme.sh"

cmp "$installer" "$repo_root/installers/ryoku-zed-theme.sh"

# The command must exist before install-sync can write the post_hook.
command_line=$(grep -n 'cat > "$command_path"' "$installer" | head -n1 | cut -d: -f1)
sync_line=$(grep -n 'node scripts/install-sync.ts' "$installer" | head -n1 | cut -d: -f1)
[[ -n $command_line && -n $sync_line && $command_line -lt $sync_line ]] || {
  echo "FAIL: installer registers the hook before creating its sync command" >&2
  exit 1
}
! grep -Fq 'spawnSync("ryoku", ["materialize"]' "$runtime" || {
  echo "FAIL: install-sync still forces ryoku materialize" >&2
  exit 1
}

if ! command -v node >/dev/null 2>&1 \
  || ! node -e 'const [a, b] = process.versions.node.split(".").map(Number); process.exit(a > 22 || (a === 22 && b >= 18) ? 0 : 1)' 2>/dev/null; then
  echo "SKIP: the runtime checks need Node.js 22.18 or newer (the bundle's own requirement)"
  exit 0
fi

test_root=$(mktemp -d /tmp/ryostore-zed-theme-installer.XXXXXX)
trap 'rm -rf "$test_root"' EXIT

fake_bin="$test_root/bin"
home="$test_root/home"
ryoku_log="$test_root/ryoku.log"
sync_cmd="$home/.local/bin/ryoku-zed-theme-sync-installed"
settings="$home/.config/zed/settings.json"
mkdir -p "$fake_bin" "$home/.config/zed/themes" "$home/.local/bin" \
  "$home/.config/ryoku/user_edits/matugen"

# Minimal Matugen theme family, enough for theme.ts --sync.
cat > "$home/.config/zed/themes/matugen.json" <<'EOF'
{
  "name": "Ryoku",
  "themes": [
    {
      "name": "Ryoku Dynamic Dark",
      "appearance": "dark",
      "style": { "editor.background": "#151218" }
    },
    {
      "name": "Ryoku Dynamic Light",
      "appearance": "light",
      "style": { "editor.background": "#f8f5fa" }
    }
  ]
}
EOF

# A `ryoku materialize` would call this and leave a line in the log.
cat > "$fake_bin/ryoku" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$RYOKU_LOG"
exit 1
EOF
chmod +x "$fake_bin/ryoku"

printf '#!/usr/bin/env bash\nexit 0\n' > "$sync_cmd"
chmod 0755 "$sync_cmd"

cat > "$home/.config/ryoku/user_edits/matugen/apps.toml" <<'EOF'
# Matugen apps template
[templates.zed]
output_path = "~/.config/zed/themes/matugen.json"
EOF

# JSONC parser used to prove the edited settings are still valid JSON.
cat > "$test_root/jsonc.js" <<'EOF'
const fs = require("node:fs");
const text = fs.readFileSync(process.argv[2], "utf8");
let out = "", i = 0, quoted = false;
while (i < text.length) {
  const c = text[i];
  if (quoted) {
    out += c;
    if (c === "\\") { out += text[i + 1] ?? ""; i += 2; continue; }
    if (c === '"') quoted = false;
    i++;
    continue;
  }
  if (c === '"') { quoted = true; out += c; i++; continue; }
  if (c === "/" && text[i + 1] === "/") {
    while (i < text.length && text[i] !== "\n") i++;
    continue;
  }
  if (c === "/" && text[i + 1] === "*") {
    i += 2;
    while (i < text.length && !(text[i] === "*" && text[i + 1] === "/")) i++;
    i += 2;
    continue;
  }
  out += c;
  i++;
}
out = out.replace(/,\s*([}\]])/g, "$1");
process.stdout.write(JSON.stringify(JSON.parse(out)));
EOF

run_sync() {
  HOME="$home" XDG_CONFIG_HOME="$home/.config" RYOKU_LOG="$ryoku_log" \
    PATH="$fake_bin:$home/.local/bin:$PATH" node "$runtime" "$1"
}

settings_json() {
  node "$test_root/jsonc.js" "$settings"
}

assert_theme() {
  local expected=$1 actual
  actual=$(settings_json | jq -r "$2")
  [[ $actual == "$expected" ]] || {
    echo "FAIL: $2 is '$actual', expected '$expected'" >&2
    cat "$settings" >&2
    exit 1
  }
}

# CASE 1: JSONC object theme, comments (one with an emoji), trailing comma.
printf '// top comment with emoji 😀\n/* block */\n{\n  "theme": {\n    "mode": "system",\n    "light": "Ayu Light",\n    "dark": "Ayu Dark",\n  },\n  "buffer_font_size": 14,\n}\n' > "$settings"
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme.dark
assert_theme "Ryoku Dynamic Light" .theme.light
assert_theme "system" .theme.mode
assert_theme "14" .buffer_font_size
grep -q '😀' "$settings" && grep -q 'block' "$settings"
ls "$settings.ryoku-backup-"* >/dev/null 2>&1
grep -q 'post_hook.*ryoku-zed-theme-sync-installed' "$home/.config/ryoku/user_edits/matugen/apps.toml"
[[ ! -s $ryoku_log ]] || {
  echo "FAIL: the installer called ryoku" >&2
  cat "$ryoku_log" >&2
  exit 1
}

# CASE 2: plain string theme.
printf '{\n  "theme": "Ayu Dark",\n  "font_family": "Mono"\n}\n' > "$settings"
rm -f "$ryoku_log" "$settings.ryoku-backup-"*
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme

# CASE 3: comment after the last property; comma must stay out of the comment.
printf '{\n  "theme": {\n    "mode": "system" // trailing comment\n  }\n}\n' > "$settings"
rm -f "$ryoku_log" "$settings.ryoku-backup-"*
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme.dark
assert_theme "Ryoku Dynamic Light" .theme.light
grep -q '"mode": "system", // trailing comment' "$settings"
! grep -q '// trailing comment,' "$settings"

# CASE 4: empty theme object gets both keys, comma-separated and valid.
printf '{\n  "theme": {}\n}\n' > "$settings"
rm -f "$ryoku_log" "$settings.ryoku-backup-"*
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme.dark
assert_theme "Ryoku Dynamic Light" .theme.light

# CASE 5: theme object with an existing property and no trailing comment.
printf '{\n  "theme": { "mode": "system" }\n}\n' > "$settings"
rm -f "$ryoku_log" "$settings.ryoku-backup-"*
run_sync "$sync_cmd"
assert_theme "system" .theme.mode
assert_theme "Ryoku Dynamic Dark" .theme.dark
assert_theme "Ryoku Dynamic Light" .theme.light

# CASE 6: no theme key at all; insert one without touching a nested "theme".
printf '{\n  // keep this comment\n  "vim_mode": true,\n  "editor": { "theme": "nested" }\n}\n' > "$settings"
rm -f "$ryoku_log" "$settings.ryoku-backup-"*
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme
assert_theme "nested" .editor.theme
assert_theme "true" .vim_mode
grep -q 'keep this comment' "$settings"

# CASE 7: root insertion must keep the comma out of a trailing comment.
printf '{\n  "vim_mode": true // trailing\n}\n' > "$settings"
rm -f "$ryoku_log" "$settings.ryoku-backup-"*
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme
assert_theme "true" .vim_mode
grep -q '"vim_mode": true, // trailing' "$settings"

# CASE 8: root array is not a Zed settings object; leave it untouched.
printf '[\n  "item1"\n]\n' > "$settings"
cp "$settings" "$settings.expected"
rm -f "$ryoku_log"
run_sync "$sync_cmd" 2>&1 | grep -q 'Warning.*no root object'
cmp "$settings" "$settings.expected"

# CASE 9: missing settings.json is created.
rm -f "$settings" "$settings.expected"
run_sync "$sync_cmd"
assert_theme "Ryoku Dynamic Dark" .theme

# CASE 10: a missing sync command aborts before touching apps.toml.
cp "$home/.config/ryoku/user_edits/matugen/apps.toml" "$test_root/apps.expected"
if run_sync "/nonexistent/path" >/dev/null 2>&1; then
  echo "FAIL: expected a non-zero exit for a missing sync command" >&2
  exit 1
fi
cmp "$home/.config/ryoku/user_edits/matugen/apps.toml" "$test_root/apps.expected"

printf 'PASS: ryoku-zed-theme installer never reloads the WM and preserves Zed JSONC\n'
