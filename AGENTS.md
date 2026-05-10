# AGENTS.md

## Project

hamta is a bash script that wraps commands in a proxy environment. Config is JSON at `~/.config/hamta/config.json`.

## Conventions

- **Shell**: Bash (`#!/usr/bin/env bash`), `set -euo pipefail`
- **Config**: JSON parsed with `jq` — never use `grep`/`sed` to parse JSON
- **Dependencies**: `jq` and `curl` — checked at runtime in `check_deps()`
- **Exit codes**: `die` for fatal errors (prints to stderr, exits 1), `warn` for non-fatal

## Testing

- `bash -n bin/hamta` — syntax check
- `bats test/hamta.bats` — full test suite (20 tests)
- Manual testing: `HOME=/tmp/hamta_test ./bin/hamta init`, `config`, `--help`, `--version`
- When changing config format, verify backward-compat loading

## Git Workflow

- Always confirm the current branch before making edits
- Run `git branch --show-current` before starting work

## Building / Installing

```bash
make install          # to /usr/local/bin
make uninstall        # remove from /usr/local/bin
bash -n bin/hamta     # syntax check
```
