# Claude integration

Nothing here is an invented API. Each source below was observed on this machine
(Claude Code 2.1.301) and is labelled documented or observed.

```
 ~/.claude/sessions/*.json ┐
 ~/.claude/projects/*.jsonl ┴─ bin/companion-watch ─┐
                                                       ├─ rawState ─ ClaudeState ─ state machine ─ sprite
 claude -p --output-format stream-json ─ companion-chat ┘
```

The sprite layer only sees `animState`. It never knows which source produced it.

## ClaudeState

`service/Main.qml` exposes `claudeState`: `idle`, `thinking`, `working`, `waiting`, `success`, `error`.

| ClaudeState | How it is derived |
| --- | --- |
| `idle` | every live session has `status` other than busy/waiting |
| `thinking` | a session is `busy` and the last transcript entry is not an open tool call |
| `working` | a session is `busy` and the last assistant entry holds a `tool_use` (tool name is reported) |
| `waiting` | a session reports waiting, or has a non-empty `waitingFor` (then the widget plays ALERT first) |
| `success` | **synthesised**: busy to idle with no error seen |
| `error` | **synthesised**: busy to idle after an `isApiErrorMessage` entry, a failed chat turn, or a dead bridge |

Success and error are approximations by design: Claude Code does not publish an "outcome" event
to outside observers. A session that ends a turn politely after a failed tool still reads as success.

## Watcher: `bin/companion-watch`

- Reads `~/.claude/sessions/<pid>.json` (observed: `pid`, `sessionId`, `cwd`, `status`, `waitingFor`,
  `updatedAt`). Files whose pid is no longer in `/proc` are ignored.
- Reads the tail of `~/.claude/projects/<cwd with / and . replaced by ->/<sessionId>.jsonl` (observed
  format) to tell thinking from tool use.
- **Event-driven.** One `inotifywait -m -r` on both directories; bursts are coalesced for 200 ms and a
  line is printed only when the computed state changed. No timer polls the files.
- Honours `CLAUDE_CONFIG_DIR`. Read-only: it writes nothing.
- Lifecycle: a trap kills `inotifywait` on normal exit; a watchdog that only sleeps (10 s) kills it if
  the script is SIGKILLed on a shell reload, because `inotifywait` ignores SIGPIPE.
- The desktop host creates one service per monitor, so with two monitors there are two watchers.

Run it by hand to see the feed: `bin/companion-watch`.

```
{"state":"thinking","tool":"","waitingFor":"","sessions":1,"error":false}
{"state":"working","tool":"Bash","waitingFor":"","sessions":1,"error":false}
```

### Fragility

The session file and transcript layouts are not a documented contract and may change between Claude
Code versions. If they do, the watcher degrades to `idle` and the widget keeps working with its chat.
The supported upgrade path is hooks, which would replace the file reads with a stable push:
`UserPromptSubmit` to thinking, `PreToolUse` to working, `Notification` to waiting, `Stop` to success.
They are not installed because a plugin may not edit `~/.claude/settings.json`.

## Chat: `bin/companion-chat`

Documented interface: `claude -p --output-format stream-json --verbose --include-partial-messages`.
One process per turn, message passed as an argv element after `--` (no shell). The script reduces the
stream to `session`, `text`, `tool`, `result`, `error` lines. The conversation id is kept in
`$XDG_STATE_HOME/ryoku/plugins/claude-companion/chat-session` and passed back with `--resume`, so the thread
survives closing the panel and restarting the shell. **new** in the panel deletes it.

- Authentication is whatever `claude` already has. No key or conversation is stored by the plugin.
- Default working folder is the plugin state dir (no project files); set **Chat working folder** to
  give Claude a project. Default permission mode is `default`: tools needing approval are denied in
  headless mode and Claude says so. `plan` and `acceptEdits` are selectable.
- Network: `claude` itself talks to `api.anthropic.com`; the plugin opens no connection.

## First run

Missing `claude`, a missing sign-in, or a missing Claude Code data folder are not errors: see
[first-run.md](first-run.md). Until `~/.claude/sessions` exists the watcher reports idle with 0
sessions and waits for it.

## Failure handling

A watcher that dies, or one of `jq`/`inotifywait` vanishing after setup: the widget
plays ERROR once, returns to IDLE, and retries with back-off (5 s doubling to 60 s). The widget never
exits because Claude is unavailable.
