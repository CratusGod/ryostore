#!/bin/bash
# SPDX-License-Identifier: MIT
# Official source: https://github.com/Sipper1236/ryoku-palette-bridge
# Ryoku ships the bridge on every edition and runs it as a session service, so
# this item only makes sure that service is on and connects it to the apps found.
set -euo pipefail

share=${RYOKU_PALETTE_BRIDGE_SHARE:-/usr/share/ryoku/palette-bridge}
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
marker_name=ryoku-palette-bridge-store-3-0-0

bridge_healthy() {
  command -v curl >/dev/null &&
    [[ $(curl --connect-timeout 2 --max-time 5 -fsS http://127.0.0.1:47616/healthz 2>/dev/null) == ok ]]
}

if ryoku-cmd-present "$marker_name" && bridge_healthy; then
  echo "ryoku-palette-bridge: already installed and healthy"
  exit 0
fi

if ! ryoku-cmd-present ryoku-palette-bridge || [[ ! -x $share/install-integrations.sh ]]; then
  echo "ryoku-palette-bridge: this system's Ryoku has no palette bridge yet; run ryoku update, then install again" >&2
  exit 1
fi

ryoku-host svc --user enable --now ryoku-palette-bridge

integrations=()
if ryoku-cmd-present spicetify; then
  integrations+=(--spotify)
fi
if ryoku-cmd-present vesktop && ryoku-cmd-present jq; then
  integrations+=(--vesktop)
fi
if [[ -f "$config_home/zen/profiles.ini" ]]; then
  integrations+=(--zen)
fi

if (("${#integrations[@]}" > 0)); then
  "$share/install-integrations.sh" "${integrations[@]}"
fi

healthy=false
for _ in {1..20}; do
  if bridge_healthy; then
    healthy=true
    break
  fi
  sleep 0.25
done
if ! $healthy; then
  echo "ryoku-palette-bridge: the bridge did not answer; run ryoku-palette-bridge-doctor for details" >&2
  exit 1
fi

echo "ryoku-palette-bridge: installed"
install -d "$HOME/.local/bin"
marker=$(mktemp)
printf '#!/bin/bash\nexec ryoku-palette-bridge-doctor "$@"\n' > "$marker"
install -m 0755 "$marker" "$HOME/.local/bin/$marker_name"
rm -f "$marker"
echo "Run $share/install-integrations.sh when you add another supported app."
