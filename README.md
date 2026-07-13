# claudex

Run Claude Code's interface and tools through a local CLIProxyAPI pool backed by Codex OAuth accounts, with a predictable model, effort, and permission profile.

## Which command should I use?

**Use `claudex` for your everyday Claude Code sessions.** It is the main command this project installs and accepts the same arguments you would normally pass to `claude`:

```bash
claudex
claudex -p 'Explain this repository'
claudex --continue
claudex --resume <session-id>
```

`claudexctl` is only the administrative companion for setting up and maintaining the local proxy. It does not replace `claudex` and it does not start a coding session.

| Command | Purpose |
| --- | --- |
| `claudex` | Start Claude Code through the Codex-backed route |
| `claudexctl doctor` | Diagnose the installation and model route |
| `claudexctl login` | Add another Codex/OpenAI OAuth account |
| `claudexctl test` | Run the packaged static and hermetic tests |
| `claudexctl uninstall` | Remove claudex-owned files |

The separate maintenance name prevents words such as `login`, `doctor`, and `uninstall` from being mistaken for prompts or arguments that should be forwarded to Claude Code.

## Install

macOS prerequisites: [Homebrew](https://brew.sh), `curl`, and `jq`. The installer adds Claude Code and CLIProxyAPI through Homebrew when needed, preserves compatible existing proxy configuration, and never copies or deletes OAuth credentials.

```bash
curl -fsSL https://raw.githubusercontent.com/johnlindquist/claudex/v1.0.1/install.sh | bash
```

Then start Claude Code with the command you installed:

```bash
claudex
```

Or run a noninteractive prompt:

```bash
claudex -p 'Reply with the model you are using.'
```

Use the companion diagnostic only when you want to inspect the installation or route:

```bash
claudexctl doctor
```

The public installer is pinned to a release tag. To intentionally test another immutable release, set `CLAUDEX_REF` and fetch that release's installer.

## What it installs

`claudex` is an executable wrapper, not a shell alias. It applies this contract to every new, continued, or resumed shell invocation:

- endpoint: `http://127.0.0.1:8317`
- proxy token: `claudex-local` (a loopback-only local routing token, not an OAuth credential)
- primary and subagent model: `gpt-5.6-sol`
- default reasoning effort: `medium`
- permission startup mode: `bypassPermissions`
- bypass-entry confirmation: suppressed
- tool search: disabled
- maximum tool-use concurrency: 3

The wrapper passes both the dedicated settings file and `--dangerously-skip-permissions`. It does not set `CLAUDE_CONFIG_DIR`, so Claude Code continues to discover normal `CLAUDE.md` files, skills, commands, hooks, and user/project settings. Ordinary `claude` is untouched.

Configuration is installed at `${XDG_CONFIG_HOME:-$HOME/.config}/claudex`. Both the main `claudex` executable and the administrative `claudexctl` companion are linked into Homebrew's `bin` directory.

## Accounts and profiles

The first install starts Codex OAuth login only when the local proxy does not already expose `gpt-5.6-sol`. Add a second account at any time:

```bash
claudexctl login
```

Run it again for each additional account. CLIProxyAPI stores each OAuth login separately under `~/.cli-proxy-api` and routes requests round-robin. For a terminal without a browser:

```bash
claudexctl login --no-browser
```

If the installed CLIProxyAPI supports device login:

```bash
claudexctl device-login
```

These are proxy accounts, not separate Claude Code config profiles. Do not use `CLAUDE_CONFIG_DIR` merely to add another Codex account; that would also split Claude session history and configuration.

## Models and reasoning effort

The wrapper explicitly sends `--model gpt-5.6-sol` and exports the same model for subagents. `claudexctl doctor` verifies that exact model ID appears in the authenticated proxy model list. The upstream model's behavior and entitlement are controlled by the OAuth account and CLIProxyAPI; a display name alone cannot cryptographically attest model weights.

The wrapper explicitly sends `--effort medium` and the dedicated settings file also records `"effortLevel": "medium"`. A reasoning-effort change made inside Claude Code's TUI applies to that active session. A fresh shell invocation of `claudex`, including `claudex --continue` or `claudex --resume …`, reapplies the wrapper's medium default. The wrapper deliberately does not fight an intentional in-session change.

Use overrides for experiments without editing the installed files:

```bash
CLAUDEX_EFFORT=high claudex
CLAUDEX_MODEL=gpt-5.6-sol claudex
```

## Permissions and plan mode

Every shell invocation starts in bypass mode without the dangerous-mode entry dialog. Custom subagents should also declare `"permissionMode":"bypassPermissions"`; the live test suite proves this with a real subagent-authored git commit.

Claude Code has no documented immutable “pin bypass forever” setting or hook. A user can deliberately switch modes in the TUI, managed policy can disable bypass, explicit `ask`/`deny` rules are merged from other settings scopes, MCP tools can require interaction, and upstream safety circuit breakers can still prompt. A hook cannot safely turn those exceptions into an absolute invariant, so this project guarantees the reproducible startup contract rather than installing a second permission engine. If you enter plan mode, exit and resume from the shell with `claudex --resume …` to reapply the wrapper contract.

## Verification

Static and hermetic tests do not contact the proxy:

```bash
tests/run.sh
scripts/secret-scan.sh
```

Live tests use your local OAuth-backed route. They prove:

- the runtime receipt attributes usage to exactly `gpt-5.6-sol`;
- a synthetic project `CLAUDE.md` instruction is read;
- a `/tmp` write and git commit complete with no permission denials;
- a resumed session is routed through the wrapper again;
- a real named subagent with `permissionMode: bypassPermissions` creates a git commit.

```bash
CLAUDEX_RUN_LIVE=1 tests/run.sh
```

The test fixtures use temporary repositories and synthetic commit identities. They do not modify this repository.

## Uninstall

```bash
claudexctl uninstall
```

This removes only claudex-owned files and links. It preserves CLIProxyAPI, compatible shared proxy configuration, and all OAuth credentials. If claudex originally installed the proxy components and you explicitly want them removed too:

```bash
claudexctl uninstall --purge-proxy
```

OAuth credentials under `~/.cli-proxy-api` are still preserved.

## Security boundaries

- The generated proxy config binds to loopback only.
- Existing proxy config is reused only when it already uses loopback, port 8317, and the expected local token; incompatible config is never overwritten.
- No OAuth files, tokens, shell startup files, or normal Claude settings are copied into the repository.
- Release tags are convenient immutable coordinates for the copy/paste command, but GitHub tag immutability depends on repository controls. Review `install.sh` before piping it to a shell if that matters for your threat model.

## Development

```bash
bash -n install.sh uninstall.sh bin/claudex bin/claudexctl lib/common.sh tests/*.sh scripts/*.sh
tests/run.sh
scripts/secret-scan.sh
```

Live release verification is intentionally separate from CI because it requires local OAuth credentials and a running proxy.
