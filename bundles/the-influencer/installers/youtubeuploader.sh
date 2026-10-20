#!/bin/bash

# youtubeuploader: Scripted YouTube uploads.
# Upstream: https://github.com/porjo/youtubeuploader

set -euo pipefail

if ryoku-cmd-present youtubeuploader; then
  echo "youtubeuploader: already installed"
  exit 0
fi

ryoku-cmd-present go || {
  echo "youtubeuploader: needs Go, which this bundle installs first" >&2
  exit 1
}

GOBIN="$HOME/.local/bin" go install github.com/porjo/youtubeuploader/cmd/youtubeuploader@latest
