# Develop and test live

You do not have to submit blind. Ryoku can run your work-in-progress straight
from a folder on your disk, in your own live desktop, before it ever reaches the
store. Build, point the desktop at your copy, watch it hot-reload, fix, repeat.

There are two override paths. Use the plugin one for a single plugin; use the
store one for anything else (rices, colour schemes, lockscreens, launchers,
bundles, and so on) or to preview your whole catalogue exactly as users will see
it.

## 1. Test a plugin live

A plugin runs straight from its source folder, with no registry entry and no
install. Point the shell at your plugins folder and restart it once:

```sh
systemctl --user set-environment RYOSTORE_PLUGINS_DIR="$HOME/Work/ryostore/plugins"
systemctl --user restart ryoku-shell
```

`RYOSTORE_PLUGINS_DIR` takes a colon-separated list, so you can add several
folders. Now open Settings (`Super+comma`), go to **Add-ons -> Plugins**, find
your plugin, toggle it on, and place it as a **Desktop widget** or **Frame
popout**.

Saved edits hot-reload: change `content/Widget.qml`, reopen the widget, and the
change is there (restart `ryoku-shell` if something looks cached). Watch the log
while you work:

```sh
journalctl --user -u ryoku-shell -f
```

Confirm, at every density you declare, that it reports a size and renders, that
drag / corner-resize / the right-click menu work, that every setting actually
changes the view, and that the log shows no QML errors. When you are done:

```sh
systemctl --user unset-environment RYOSTORE_PLUGINS_DIR
systemctl --user restart ryoku-shell
```

The full plugin contract, hosts, densities, settings schema, and the per-plugin
checklist, is in [`plugins/AUTHORING.md`](plugins/AUTHORING.md).

## 2. Test the whole store against your local copy

Ryostore normally fetches its catalogues from this repo on GitHub. Point it at
your own checkout instead and it serves everything, registries and art, straight
off disk: instant, offline, and exactly what a user would install.

Write the path of your checkout, as a `file://` URL, to the source override
file:

```sh
mkdir -p ~/.config/ryoku
echo "file://$HOME/Work/ryostore" > ~/.config/ryoku/ryostore-base
```

Open the Store (or Settings). Your rice, colour scheme, lockscreen, launcher,
bundle, or whatever you are building now appears in its catalogue and installs
from your disk. Edit a `registry.json`, reopen the Store, and your change is
live. A launcher you change needs a repack (`tools/pack-product.py`) and a fresh
install before Super+Space shows the new copy; `launchers/AUTHORING.md` has the
loop.

For a one-off session instead of the persistent file, set the environment
variable (a base URL for a fork, or a `file://` path for a local tree):

```sh
RYOSTORE_BASE="file://$HOME/Work/ryostore" ryostore
```

Remove the override when you are done so the Store tracks the real catalogue
again:

```sh
rm ~/.config/ryoku/ryostore-base
```

## 3. Validate before you submit

Wiring mistakes, a bundle item that points at a plugin that is not here, a
manifest whose files are missing, malformed JSON, are what break a user's
install. Catch them from the repo root:

```sh
tests/validate-catalogue.sh
```

It should print `catalogue OK`. CI runs the same check on every push and pull
request, so a green local run is a green submission.

The catalogue check validates wiring, not that your product looks and behaves
right. Do both: install and exercise the real thing in your session (step 1 or
2), then run the check.

## 4. Submit

Once it works live and the check passes, follow
[CONTRIBUTING.md](CONTRIBUTING.md) to open a pull request or the submission form.
