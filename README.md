# hamta

Run commands through a configurable proxy environment with IP verification.

hamta is a small Bash wrapper for tools that should run through a local or remote proxy. It loads a JSON config, exports common proxy environment variables, optionally verifies the exit country with `ipinfo.io`, then runs your command unchanged.

It is useful when you want one-off commands such as coding agents, package managers, or CLIs to use a proxy without changing your whole shell session.

## Quick setup

```bash
brew install andrewmmc/tap/hamta

hamta init
$EDITOR ~/.config/hamta/config.json

hamta curl https://ipinfo.io
```

## Install

With Homebrew:

```bash
brew install andrewmmc/tap/hamta
```

From source:

```bash
git clone https://github.com/andrewmmc/hamta.git
cd hamta
make install                 # to /usr/local/bin
make install PREFIX=$HOME/.local  # user-local install
```

Make sure `$HOME/.local/bin` is on your `PATH` if you use the user-local install.

Requires `jq` and `curl`.

## Setup

```bash
hamta init                   # creates ~/.config/hamta/config.json
```

Edit `~/.config/hamta/config.json` to set your proxy URL and expected country:

```json
{
  "proxy": {
    "url": "http://127.0.0.1:1087"
  },
  "verify": {
    "enabled": true,
    "expected_country": "JP"
  }
}
```

## Usage

```bash
hamta opencode                # run opencode through proxy
hamta claude                  # run claude through proxy
hamta npm install react       # proxy npm too
hamta --help                  # show help
hamta config                  # print current config
```

On each run, hamta will:
1. Set proxy environment variables (HTTP_PROXY, HTTPS_PROXY, ALL_PROXY, npm_config_proxy, etc.)
2. Verify the proxy is working by checking your IP country via `ipinfo.io`
3. Execute the command

Set `verify.enabled` to `false` to skip the IP country check.

## Flow

```diagram
╭──────────────╮
│ hamta <cmd>  │
╰──────┬───────╯
       ▼
╭────────────────────────────╮
│ Load config.json with jq   │
╰──────┬─────────────────────╯
       ▼
╭────────────────────────────╮
│ Export proxy env variables │
╰──────┬─────────────────────╯
       ▼
╭────────────────────────────╮
│ verify.enabled?            │
╰──────┬───────────────┬─────╯
       │ yes           │ no
       ▼               │
╭────────────────────╮ │
│ Check ipinfo.io    │ │
│ country matches?   │ │
╰──────┬─────────────╯ │
       ▼               ▼
╭────────────────────────────╮
│ exec command with args     │
╰────────────────────────────╯
```
