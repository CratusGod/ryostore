# Installers

Small, auditable scripts for tools that do not come from a system package
manager. Each script lives at `bundles/<id>/installers/<name>.sh` beside the one
bundle that owns it, and covers a curl, npm, Go, Cargo, or pipx install path
pinned to an official upstream. `ryostore-install` runs it when the referenced
tool is missing.

## Adding an installer

1. Create `bundles/<id>/installers/<name>.sh`. `<name>` is the bundle item name without the `.sh`.
2. Start with `#!/bin/bash` and `set -euo pipefail`.
3. Name the official source URL in a header comment so the script stays auditable.
4. Be idempotent: detect first, and exit `0` early when the tool is already present.

   ```bash
   if ryoku-cmd-present <command>; then
     echo "<name>: already installed"
     exit 0
   fi
   ```

5. Install into `~/.local/bin` without root. Installers run under bash, which does
   not carry the interactive shell's environment, so set the destination
   explicitly:

   - npm: `npm install -g --prefix="$HOME/.local" <pkg>`
   - go: `GOBIN="$HOME/.local/bin" go install <module>@latest`
   - cargo: `cargo install --root "$HOME/.local" <crate>`
   - pipx: `pipx install <pkg>` (pipx already targets `~/.local/bin`)
   - curl: the vendor's own installer, when `~/.local/bin` is its documented target

6. Let failures surface: `set -e` plus a non-zero exit tells the actuator the item
   failed. When a tool the script needs is missing, say which one in one line
   before exiting.

## Every Ryoku edition

The same script runs on Arch, CachyOS, Fedora and Void, so it never calls a
distribution's own tools (`pacman`, `dnf`, `xbps-install`, `systemctl`, `sv`,
...). The security screen rejects a script that does. Go through Ryoku's seam
instead, which does the right thing on each edition:

- `ryoku-host svc --user enable --now <unit>` for a user service;
- `ryoku-host inhibit`, `ryoku-host transient` and `ryoku-host power` for the
  rest of what systemd or elogind would do;
- `ryoku update --system` to point someone at a system upgrade.

A system package the script needs (npm, Go, a library) is a `package` item in
the same bundle, so the bundle's edition tables name it everywhere and the
actuator installs it first. Do not install packages from inside the script.
An installer that cannot work on some edition at all is gated with
`packageManagers` on its item; see [`bundles/README.md`](../bundles/README.md).

Run the script as an ordinary user in a Void and a Fedora container before you
submit, with its bundle's packages installed, and check the tool lands on
`~/.local/bin`.

## Referencing it from a bundle

Add a `script` item to the bundle's `bundle.json`:

```jsonc
{ "type": "script", "name": "claude-code", "detect": "claude", "summary": "Anthropic CLI.",
  "source": "curl", "upstream": "https://github.com/anthropics/claude-code" }
```

- `name` matches the script filename without `.sh` (`claude-code` -> `bundles/the-vibecoder/installers/claude-code.sh`).
- `detect` is the command the script produces; the actuator skips the item when that
  command is already on `PATH`.
