# Docker

A Ryoku bar plugin (`docker-ctl`) for the local Docker engine.

- **Bar glyph:** the Docker whale, tinted while the daemon runs, with the
  number of running containers. A click opens the panel; the glyph itself
  never changes anything.
- **Panel:**
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

`bin/dockerctl` uses Python's standard library to talk directly to the local
Docker Engine API. It never invokes the Docker command-line client, a shell,
`sudo`, `pkexec`, or a passwordless helper. It uses `DOCKER_HOST` when that
names a local `unix://` socket and otherwise uses `/var/run/docker.sock`.

The current user must already have permission to use that socket. On a regular
Docker installation this is commonly provided by membership in the `docker`
group; rootless Docker normally exports its own `DOCKER_HOST`. The plugin does
not install, start, stop, enable, or configure the Docker daemon.

The helper issues only these local Engine API requests:

- `GET /containers/json?all=1` to list containers;
- `POST /containers/<id>/start`, `/stop?t=10`, or `/restart?t=10` after a
  matching button click;
- `GET /containers/<id>/json` after a container name is clicked;
- a recreate sequence after **APPLY**: inspect, stop if running, rename, create,
  start if previously running, then remove the old container. A failed create
  removes the partial replacement and restores the old container.

Container IDs come from Docker and must be 12 to 64 lowercase hexadecimal
characters. The editor accepts structured JSON only. Ports must be in the
1-65535 range, protocols are limited to TCP, UDP and SCTP, host addresses must
be IP literals, mount targets must be absolute container paths, bind sources
must already exist, and named volumes use Docker's name character set.

## What it reads and writes

- Reads: local Docker container state through the unix socket.
- Writes: Docker container state only after a lifecycle button or **APPLY**.
- Files: none.
- Network: none. The only connection is the selected local unix socket.
