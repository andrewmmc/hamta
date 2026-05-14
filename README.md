# hamta

Run commands through a configurable proxy environment with IP verification.

hamta is a small Bash wrapper for tools that should run through a local or remote proxy. It loads a JSON config, exports common proxy environment variables, optionally verifies the exit country with `ipinfo.io`, then runs your command.

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

Requires `jq` and `curl`. `proxy.mode: "proxychains"` also requires `proxychains-ng` / `proxychains4`.

## Setup

```bash
hamta init                   # creates ~/.config/hamta/config.json
```

Edit `~/.config/hamta/config.json` to set your proxy URL and expected country:

```json
{
  "proxy": {
    "url": "http://127.0.0.1:1087",
    "mode": "env"
  },
  "verify": {
    "enabled": true,
    "expected_country": "JP"
  }
}
```

`proxy.mode` can be `env` or `proxychains`.

### `env` mode

`env` is the default mode. It exports standard proxy environment variables and runs the command directly:

```json
{
  "proxy": {
    "url": "http://127.0.0.1:1087",
    "mode": "env"
  },
  "verify": {
    "enabled": true,
    "expected_country": "JP"
  }
}
```

Use this for apps that honor `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, or npm proxy environment variables. This mode requires only `jq` and `curl`.

### `proxychains` mode

`proxychains` mode exports the same proxy environment variables, then runs the command through `proxychains4` with a generated config:

```json
{
  "proxy": {
    "url": "socks5h://127.0.0.1:1080",
    "mode": "proxychains"
  },
  "verify": {
    "enabled": true,
    "expected_country": "JP"
  }
}
```

Use this for many TCP CLI apps that ignore proxy environment variables. Install `proxychains-ng` first:

```bash
brew install proxychains-ng
```

If `proxy.mode` is `proxychains` but `proxychains4` is not installed, hamta exits with:

```text
Error: proxy.mode is proxychains, but proxychains4 was not found. Install proxychains-ng and try again.
```

Supported proxychains URL schemes are `http://`, `socks4://`, `socks5://`, and `socks5h://`. `socks5h://` is written as a SOCKS5 proxy in the generated proxychains config; DNS leak prevention comes from `proxy_dns`.

Mode comparison:

| Mode | How command is run | Extra dependency | Helps apps that ignore env vars? | DNS leak protection |
|---|---|---|---|---|
| `env` | Direct `exec` with proxy environment variables | none beyond `jq`/`curl` | No | No |
| `proxychains` | Via `proxychains4 -f <generated-config>` | `proxychains-ng` | Often, for TCP apps | Uses `proxy_dns` for intercepted lookups |

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
3. Execute the command directly or through `proxychains4`, depending on `proxy.mode`

Set `verify.enabled` to `false` to skip the IP country check.

## DNS leaks

In `env` mode, hamta cannot prevent DNS leaks for apps that ignore proxy environment variables or resolve names locally. It only provides proxy environment variables.

In `proxychains` mode, hamta generates a temporary proxychains config with:

```conf
proxy_dns
```

That tells proxychains to proxy DNS resolution for intercepted hostname lookups. This reduces DNS leaks for many TCP CLI apps, but it is not a perfect system-wide guarantee: apps that bypass proxychains injection, use unsupported UDP paths, or are protected by OS restrictions may still bypass it. For the strongest guarantee, use a tun/VPN-style transparent proxy or OS-level firewall/routing rules.

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
│ run command with args      │
╰────────────────────────────╯
```
