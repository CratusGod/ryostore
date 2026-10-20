#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$repo_root/bundles/spiceflow/installers/ryoku-palette-bridge.sh"
cmp "$installer" "$repo_root/installers/ryoku-palette-bridge.sh"
test_root=$(mktemp -d /tmp/ryostore-palette-installer.XXXXXX)
trap 'rm -rf "$test_root"' EXIT
fake_bin="$test_root/bin"
share="$test_root/share"
service_on="$test_root/service-on"
host_log="$test_root/host.log"
integrations_log="$test_root/integrations.log"
forbidden_log="$test_root/forbidden.log"
mkdir -p "$fake_bin" "$share" "$test_root/home"

# The packaged bridge: its command and its integration script.
printf '#!/usr/bin/env bash\nexit 0\n' > "$fake_bin/ryoku-palette-bridge"
cat > "$share/install-integrations.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$INTEGRATIONS_LOG"
EOF

# Presence answers only for this test's commands, never the machine running it.
cat > "$fake_bin/ryoku-cmd-present" <<'EOF'
#!/usr/bin/env bash
[[ -x ${0%/*}/$1 || -x $HOME/.local/bin/$1 ]]
EOF

# Ryoku's host seam starts the session service on systemd and runit alike.
cat > "$fake_bin/ryoku-host" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOST_LOG"
[[ $* == 'svc --user enable --now ryoku-palette-bridge' ]] && : > "$SERVICE_ON"
EOF

cat > "$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
[[ -f $SERVICE_ON ]] && printf 'ok\n'
EOF

# A distro or init tool would only work on some editions.
for tool in systemctl git go; do
  cat > "$fake_bin/$tool" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "${0##*/}" "$*" >> "$FORBIDDEN_LOG"
exit 1
EOF
done
printf '#!/usr/bin/env bash\nexit 0\n' > "$fake_bin/spicetify"
chmod +x "$fake_bin"/* "$share/install-integrations.sh"

run_installer() {
  HOME="$test_root/home" \
  XDG_CONFIG_HOME="$test_root/home/.config" \
  RYOKU_PALETTE_BRIDGE_SHARE="$share" \
  SERVICE_ON="$service_on" \
  HOST_LOG="$host_log" \
  INTEGRATIONS_LOG="$integrations_log" \
  FORBIDDEN_LOG="$forbidden_log" \
  PATH="$fake_bin:$test_root/home/.local/bin:$PATH" \
    "$installer"
}

run_installer
grep -Fxq 'svc --user enable --now ryoku-palette-bridge' "$host_log"
grep -Fxq -- '--spotify' "$integrations_log"
test -x "$test_root/home/.local/bin/ryoku-palette-bridge-store-3-0-0"
[[ ! -e $forbidden_log ]] || { cat "$forbidden_log"; exit 1; }

# Installed and healthy: a second run changes nothing.
run_installer | grep -Fq 'already installed and healthy'
[[ $(wc -l < "$host_log") == 1 && $(wc -l < "$integrations_log") == 1 ]]

# A Ryoku without the packaged bridge gets a clear way forward, not a build.
rm "$fake_bin/ryoku-palette-bridge" "$test_root/home/.local/bin/ryoku-palette-bridge-store-3-0-0"
if output=$(run_installer 2>&1); then
  echo "installer succeeded without the packaged bridge" >&2
  exit 1
fi
grep -Fq 'run ryoku update' <<<"$output"

printf 'PASS: Ryostore connects the packaged palette bridge on every edition\n'
