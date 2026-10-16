# First run: install and sign-in

A new user has two things the original author never had to think about: Claude Code may
not be installed, and it may not be signed in. The widget handles both, in the panel, and
never fails silently.

## The decision

`bin/companion-check` prints one JSON line when the widget starts and after every
sign-in attempt:

```
{"cli":true,"version":"2.1.301","jq":true,"inotify":true,"loggedIn":true,"method":"claude.ai","reducedMotion":false}
```

`service/Main.qml` turns it into `setup`:

| `setup` | Condition | Panel | Spark |
| --- | --- | --- | --- |
| `checking` | the probe is running | normal chat | idle |
| `noCli` | no `claude` on `PATH` | install guide + *Check again* | `?` |
| `noJq` | `claude` found, `jq` missing | what to install + *Check again* | `?` |
| `signedOut` | `claude auth status` says not logged in | *Sign in* | `?` |
| `signingIn` | `claude auth login` is running | link, code field, *Cancel* | `?` |
| `ready` | everything present and signed in | chat | normal |

Details that matter:

- **`PATH`.** Quickshell is usually started by the compositor, so it does not have the
  `PATH` of your interactive shell, and the official installer puts `claude` in
  `~/.local/bin`. Every script prepends `~/.local/bin`, `~/.claude/local` and
  `/usr/local/bin` before looking for `claude`.
- **No account data.** `claude auth status` prints the account email and organisation.
  The probe keeps only `loggedIn` and `authMethod`.
- **Missing `inotifywait` only.** Chat still works; the session watcher is skipped (the
  spark then reflects chat turns only).
- **No Claude Code data folder yet.** `~/.claude/sessions` appears the first time Claude
  Code runs. Until then the watcher reports "idle, 0 sessions" and checks every 5 s for
  the folders (the only timer-based wait in the plugin) instead of failing.

## Sign-in

`bin/companion-login` runs the official `claude auth login --claudeai` (or `--console`,
chosen by the *Sign-in account type* setting) and reports three kinds of line:

```
{"k":"url","url":"https://claude.com/cai/oauth/authorize?..."}   link to open
{"k":"fail","msg":"Login failed: Request failed with status code 400"}
{"k":"done"}                                                       the CLI exited
```

Observed with Claude Code 2.1.301 (not a documented interface): the CLI opens the browser,
prints the link, and shows `Paste code here if prompted >`; if the browser page shows a
code, pasting it completes the login. The widget keeps the CLI's stdin open and forwards
the code you type. The exit code is not a reliable success signal (it can be `0` after a
failed login), so on `done` the widget asks `claude auth status` again and trusts only that.

Cancelling the panel, or losing the widget, stops the CLI: the script runs it as a
coprocess, stops it on `SIGTERM`/`SIGHUP`/`SIGINT` and when its stdin closes, so no
`claude auth login` is left waiting for a browser callback.

## When the login expires later

`bin/companion-chat` maps Claude Code's `authentication_failed` / "Not logged in" results
to a single `{"k":"auth"}` line. The widget then switches to `signedOut` with a note,
instead of showing a cryptic error.

## Testing every state on a machine that is already signed in

Point the scripts at an empty config directory; nothing of your real login is touched:

```
tmp=$(mktemp -d)
CLAUDE_CONFIG_DIR=$tmp bin/companion-check          # loggedIn:false -> signedOut
CLAUDE_CONFIG_DIR=$tmp bin/companion-chat send "$tmp" "" default hi   # prints {"k":"auth"}
HOME=$(mktemp -d) PATH=/usr/bin:/bin bin/companion-check              # cli:false -> noCli
```

The *Force a state* debug setting only changes the animation, not the setup panel.

## Not covered by automated checks

The real end of the browser flow (approving in the browser, or pasting a real code) needs a
human and an account; it has been exercised up to the point of a wrong code (the CLI
answers `Login failed`, shown in the panel) but a successful sign-in from the widget has to
be confirmed by whoever installs it first.
