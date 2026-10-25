# Docker

A Ryoku bar plugin (`docker-ctl`) for the local Docker engine.

- **Bar glyph:** the Docker whale, tinted while the daemon runs, with the
  number of running containers. A click opens the panel; the glyph itself
  never changes anything.
- **Panel:**
  - **START / STOP** the Docker daemon, and **BOOT: ON / OFF** to set whether
    it starts at boot. These ask for a password once, then never again.
  - Every container, with its image, status and published ports, plus
    **START / STOP** and **RESTART**.
  - Click a container's name to edit its **published ports** and **mounts**
    (bind paths or named volumes, read-only or read-write). **APPLY** recreates
    the container with the new settings.

Settings (QS Bar Settings > Community): show the running count, list stopped
containers, refresh interval.

## How "edit ports and mounts" works

Docker can't change the ports or mounts of an existing container, so APPLY
recreates it:

1. It reads the container's full config from the Engine API and checks the new
   ports and mounts first. Nothing is touched if that check fails.
2. It stops the container and renames it `<name>-old-<timestamp>`.
3. It creates a new container with the same name, the same image (by ID),
   environment, command, labels, restart policy and networks (aliases kept),
   plus the new port bindings and mounts. It starts the new container if the
   old one was running.
4. If it succeeds, it removes the old container. Volumes are never deleted. If
   any step fails, it drops the new container, renames the old one back and
   starts it again.

**Compose projects:** if a container belongs to a `docker compose` project,
the next `docker compose up` for that project rebuilds it from the compose
file, which puts the file's ports and mounts back. To make an edit permanent,
change the compose file too.

## What it runs

- `bin/dockerctl` (Python 3, standard library only). It talks to the Docker
  Engine API over `/var/run/docker.sock`, so you need permission to use that
  socket (membership in the `docker` group).
- `ryoku-host svc --system is-active` / `is-enabled` for `docker.service` and
  `docker.socket` (reads only; Ryoku's init-neutral service seam).

### Privileged commands (one password, once)

Starting, stopping, enabling and disabling Docker needs root. The plugin asks
for your password **once**: when you click **ALLOW** on the panel's setup
banner, or the first time you use a daemon button. That runs:

| When | Command |
| --- | --- |
| First use / ALLOW | `pkexec bin/docker-ctl-setup install` |

`docker-ctl-setup install` writes two root-owned files:

- `/usr/local/libexec/docker-ctl-daemon`: a 10-line helper that accepts exactly
  `start`, `stop`, `enable` and `disable`, and runs fixed
  `ryoku-host svc --system` commands for `docker.service` and `docker.socket`.
- `/usr/share/polkit-1/actions/dev.ryoku.docker-ctl.policy`: a polkit action
  that lets the active local session run that helper without a password.
  Inactive and remote sessions still need the admin password.

After that, the daemon buttons run these without asking:

| Button | Command |
| --- | --- |
| START | `pkexec /usr/local/libexec/docker-ctl-daemon start` |
| STOP | `pkexec /usr/local/libexec/docker-ctl-daemon stop` (also stops `docker.socket`) |
| BOOT: OFF → ON | `pkexec /usr/local/libexec/docker-ctl-daemon enable` |
| BOOT: ON → OFF | `pkexec /usr/local/libexec/docker-ctl-daemon disable` (also disables `docker.socket`) |

The helper is a root-owned copy, not a file in the plugin folder. A
password-free root command must not run anything the user can edit.

To undo it (the buttons go back to asking every time):
`pkexec ~/.local/share/ryoku/plugins/docker-ctl/bin/docker-ctl-setup uninstall`.
`ryoku plugin remove docker-ctl` does not remove these two files, so run the
uninstall first.

## What it reads and writes

- Reads: the Docker Engine API, and systemd unit state.
- Writes: no files in your home. One-time setup writes the two root-owned files above.
  Docker state (containers, daemon) changes only when you click a button.
- Network: none. The only connection is the local unix socket.
