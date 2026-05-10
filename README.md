# hamta

Run commands through a configurable proxy environment with IP verification.

## Install

```bash
git clone https://github.com/andrewmmc/hamta.git
cd hamta
make install                 # to /usr/local/bin
make install PREFIX=$HOME/.local  # user-local install
```

Or via Homebrew:

```bash
brew install --build-from-source ./Formula/hamta.rb
```

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
  },
  "prompt": true
}
```

## Usage

```bash
hamta opencode               # run opencode through proxy
hamta claude                  # run claude through proxy
hamta npm install react       # proxy npm too
hamta --help                  # show help
hamta config                  # print current config
```

On each run, hamta will:
1. Set proxy environment variables (HTTP_PROXY, HTTPS_PROXY, ALL_PROXY, npm_config_proxy, etc.)
2. Verify the proxy is working by checking your IP country via `ipinfo.io`
3. Prompt for confirmation (y/N)
4. Execute the command

Set `verify.enabled` to `false` to skip the IP country check. Set `prompt` to `false` to run without confirmation.
