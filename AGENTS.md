# Contributor instructions

- Keep `claudex` isolated from ordinary `claude`; never set `CLAUDE_CONFIG_DIR` or edit a user's Claude settings.
- Never copy, print, commit, or remove OAuth credentials from `~/.cli-proxy-api`.
- Keep the proxy bound to loopback and preserve compatible existing proxy configuration.
- The wrapper contract must retain the dedicated settings overlay, `gpt-5.6-sol`, medium effort, `--dangerously-skip-permissions`, and the Agent `PreToolUse` mode normalizer.
- Run `tests/run.sh` and `scripts/secret-scan.sh` before publishing.
