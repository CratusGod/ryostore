# Developer Essentials

A practical **developer workstation bootstrap** for Ryoku: build basics,
Git and GitHub CLI, fast shell search tools, terminal workflow helpers, native
build/debug tools, major language runtimes, Docker, and Visual Studio Code.
Install it from **Settings, Extras, Developer Essentials, Install all**.

## Core workflow tools

| Tool | What it is | Arch / CachyOS |
| --- | --- | --- |
| base-devel | Essential build toolchain (compiler, make, pkg-config) for compiling local projects. | pacman |
| git | Distributed version control. | pacman |
| github-cli | GitHub CLI (`gh`) for pull requests, issues, releases, and auth. | pacman |
| curl / wget | Command-line download and API tools. | pacman |
| jq | JSON processor for shell pipelines and API output. | pacman |
| ripgrep / fd / fzf | Fast search, file finding, and fuzzy picking for source trees. | pacman |
| tmux | Persistent terminal sessions and split-pane workflows. | pacman |

## Build and debug

| Tool | What it is | Arch / CachyOS |
| --- | --- | --- |
| cmake | Cross-platform build system generator. | pacman |
| ninja | Fast build executor, commonly paired with CMake and Meson. | pacman |
| gdb | GNU debugger for native applications. | pacman |
| clang | LLVM C/C++ compiler and tools. | pacman |
| lldb | LLVM debugger for C, C++, Rust, Swift, and other native code. | pacman |

## Languages and tooling

| Tool | What it is | Arch / CachyOS |
| --- | --- | --- |
| python / python-pip | Python runtime and package installer. | pacman |
| nodejs / npm | JavaScript runtime and package manager. | pacman |
| bun | Fast JavaScript runtime, package manager, bundler, and test runner. | pacman |
| rustup | Rust toolchain installer and version manager. | pacman |
| go | Go compiler, standard tools, and runtime. | pacman |
| jdk-openjdk | OpenJDK Java runtime and compiler. | pacman |

## Containers and editor

| Tool | What it is | Arch / CachyOS |
| --- | --- | --- |
| docker | Container engine for local services, tests, and images. | pacman |
| docker-compose | Compose plugin for multi-container dev environments. | pacman |
| visual-studio-code-bin | Official Microsoft Visual Studio Code build. | AUR |

## On Fedora and Void

The last column is where a tool comes from on Arch and CachyOS. On Fedora and
Void, Ryoku installs each tool from that edition's own repositories, under its
own package name (`base-devel` becomes GCC, make and friends on Fedora,
`docker` becomes Moby). A tool an edition does not package stays listed in the
store, greyed out with the reason and where to get it instead, and **Install
all** skips it: Bun and Microsoft's Visual Studio Code are not packaged for
Fedora or Void, and on Void npm ships inside the nodejs package.

## Notes

- Docker may need the service enabled and your user added to the `docker` group
  before rootless day-to-day use works in a new session.
- `rustup` installs Rust toolchains after package installation; run
  `rustup default stable` if no default toolchain is configured yet.
- The Java package is `jdk-openjdk` on Arch, `openjdk25` on Void and
  `java-latest-openjdk-devel` on Fedora; each provides the `java` command and
  the JDK toolchain.
