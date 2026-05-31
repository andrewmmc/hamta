#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export HOME="$TEST_DIR"
  export XDG_CONFIG_HOME="$TEST_DIR/.config"
  HAMTA="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/bin/hamta"
}

teardown() {
  rm -rf "$TEST_DIR"
}

write_config() {
  mkdir -p "$HOME/.config/hamta"
  printf '%s\n' "$1" > "$HOME/.config/hamta/config.json"
}

write_proxychains_config() {
  write_config "{\"proxy\":{\"url\":\"${1:-http://127.0.0.1:9999}\",\"mode\":\"proxychains\"},\"verify\":{\"enabled\":false,\"expected_country\":\"JP\"}}"
}

mock_bin_dir() {
  local mock_bin="$TEST_DIR/mockbin"
  mkdir -p "$mock_bin"
  printf '%s' "$mock_bin"
}

write_verify_config() {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true,"expected_country":"JP"}}'
}

# --help / -h

@test "--help exits 0 and shows usage" {
  run "$HAMTA" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

@test "-h exits 0 and shows usage" {
  run "$HAMTA" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

# --version / -v

@test "--version exits 0 and shows version" {
  run "$HAMTA" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^hamta\ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "-v exits 0 and shows version" {
  run "$HAMTA" -v
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^hamta\ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

# init

@test "init creates config at ~/.config/hamta/config.json" {
  run "$HAMTA" init
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/hamta/config.json" ]
  [[ "$output" =~ "Config created" ]]
}

@test "init with existing config prints message and exits 0" {
  write_config '{}'
  run "$HAMTA" init
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already exists" ]]
}

@test "init when share template is missing falls back to inline JSON" {
  # Run from a dir where share/hamta/config.json doesn't exist
  local NO_SHARE="$TEST_DIR/noshare"
  mkdir -p "$NO_SHARE"
  cp "$HAMTA" "$NO_SHARE/hamta"
  chmod +x "$NO_SHARE/hamta"
  run "$NO_SHARE/hamta" init
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/hamta/config.json" ]
}

# config

@test "config prints config file contents" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"}}'
  run "$HAMTA" config
  [ "$status" -eq 0 ]
  [[ "$output" =~ "http://127.0.0.1:9999" ]]
}

@test "config without config file dies" {
  run "$HAMTA" config
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not found" ]]
}

# no args

@test "no args shows usage" {
  run "$HAMTA"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage" ]]
}

# command not found

@test "unknown command dies with error" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true,"expected_country":"JP"}}'
  run "$HAMTA" nonexistentcommand12345
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Command not found" ]]
}

# proxy.url null or empty

@test "dies when proxy.url is null" {
  write_config '{"proxy":{"url":null}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not set" ]]
}

@test "dies when proxy.url is empty string" {
  write_config '{"proxy":{"url":""}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not set" ]]
}

@test "dies when config is invalid JSON" {
  write_config '{invalid json'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not valid JSON" ]]
}

@test "dies when proxy.url is not a string" {
  write_config '{"proxy":{"url":1087}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "proxy.url" ]]
}

@test "dies when proxy.mode is not a string" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999","mode":true}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "proxy.mode" ]]
}

@test "dies when proxy.mode is unsupported" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999","mode":"vpn"}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "proxy.mode" ]]
}

@test "dies when --mode is missing a value" {
  run "$HAMTA" --mode
  [ "$status" -eq 1 ]
  [[ "$output" =~ "--mode requires" ]]
}

@test "dies when --mode is unsupported" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999","mode":"env"},"verify":{"enabled":false}}'
  run "$HAMTA" --mode vpn true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "--mode must be 'env' or 'proxychains'" ]]
}

@test "dies when verify.enabled is not a boolean" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":"yes","expected_country":"JP"}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "verify.enabled" ]]
}

@test "dies when verify is enabled without expected country" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true}}'
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "verify.expected_country" ]]
}

# run with verify disabled -> exec path

@test "runs command with verify disabled" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":false,"expected_country":"JP"}}'
  run "$HAMTA" echo "hello world"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "hello world" ]]
  [[ "$output" =~ "Running with proxy 127.0.0.1:9999" ]]
  [[ ! "$output" =~ "actual IP" ]]
  [[ "$output" =~ "Running" ]]
}

# proxy env vars are exported

@test "exports proxy environment variables" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":false,"expected_country":"JP"}}'
  run "$HAMTA" env
  [ "$status" -eq 0 ]
  [[ "$output" =~ "HTTP_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "HTTPS_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "ALL_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "NODE_USE_ENV_PROXY=1" ]]
}

@test "command line --mode proxychains overrides config env mode" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999","mode":"env"},"verify":{"enabled":false,"expected_country":"JP"}}'

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/proxychains4" <<'MOCKEOF'
#!/usr/bin/env bash
if [[ "$1" != "-f" ]]; then
  echo "missing -f" >&2
  exit 2
fi
config="$2"
shift 2
cat "$config"
echo "proxychains command: $*"
"$@"
MOCKEOF
  chmod +x "$MOCK_BIN/proxychains4"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" --mode proxychains echo "override hello"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "proxy_dns" ]]
  [[ "$output" =~ "proxychains command: echo override hello" ]]
  [[ "$output" =~ "override hello" ]]
}

@test "command line --mode env overrides config proxychains mode" {
  write_proxychains_config

  run "$HAMTA" --mode env env
  [ "$status" -eq 0 ]
  [[ "$output" =~ "HTTP_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "NODE_USE_ENV_PROXY=1" ]]
}

@test "double dash allows commands after mode override" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999","mode":"env"},"verify":{"enabled":false,"expected_country":"JP"}}'

  run "$HAMTA" --mode env -- env
  [ "$status" -eq 0 ]
  [[ "$output" =~ "HTTP_PROXY=http://127.0.0.1:9999" ]]
}

@test "proxychains mode runs command through generated proxychains config with proxy_dns" {
  write_proxychains_config

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/proxychains4" <<'MOCKEOF'
#!/usr/bin/env bash
if [[ "$1" != "-f" ]]; then
  echo "missing -f" >&2
  exit 2
fi
config="$2"
shift 2
cat "$config"
echo "proxychains command: $*"
"$@"
MOCKEOF
  chmod +x "$MOCK_BIN/proxychains4"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" echo "proxied hello"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Running with proxy 127.0.0.1:9999" ]]
  [[ "$output" =~ "proxy_dns" ]]
  [[ "$output" =~ "http 127.0.0.1 9999" ]]
  [[ "$output" =~ "proxychains command: echo proxied hello" ]]
  [[ "$output" =~ "proxied hello" ]]
}

@test "proxychains mode clears proxy environment variables before running command" {
  write_proxychains_config

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/proxychains4" <<'MOCKEOF'
#!/usr/bin/env bash
shift 2
"$@"
MOCKEOF
  chmod +x "$MOCK_BIN/proxychains4"

  HTTP_PROXY="http://preexisting.example:8080" \
    HTTPS_PROXY="http://preexisting.example:8080" \
    ALL_PROXY="http://preexisting.example:8080" \
    http_proxy="http://preexisting.example:8080" \
    https_proxy="http://preexisting.example:8080" \
    npm_config_proxy="http://preexisting.example:8080" \
    npm_config_https_proxy="http://preexisting.example:8080" \
    NODE_USE_ENV_PROXY=1 \
    PATH="$MOCK_BIN:$PATH" run "$HAMTA" env

  [ "$status" -eq 0 ]
  [[ ! "$output" =~ "HTTP_PROXY=" ]]
  [[ ! "$output" =~ "HTTPS_PROXY=" ]]
  [[ ! "$output" =~ "ALL_PROXY=" ]]
  [[ ! "$output" =~ "http_proxy=" ]]
  [[ ! "$output" =~ "https_proxy=" ]]
  [[ ! "$output" =~ "npm_config_proxy=" ]]
  [[ ! "$output" =~ "npm_config_https_proxy=" ]]
  [[ ! "$output" =~ "NODE_USE_ENV_PROXY=" ]]
}

@test "proxychains mode supports socks5h proxy URLs as socks5 with proxy_dns" {
  write_proxychains_config "socks5h://127.0.0.1:1080"

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/proxychains4" <<'MOCKEOF'
#!/usr/bin/env bash
config="$2"
shift 2
cat "$config"
"$@"
MOCKEOF
  chmod +x "$MOCK_BIN/proxychains4"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "proxy_dns" ]]
  [[ "$output" =~ "socks5 127.0.0.1 1080" ]]
}

@test "proxychains mode keeps proxy credentials in generated config" {
  write_proxychains_config "http://user:pass@127.0.0.1:9999"

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/proxychains4" <<'MOCKEOF'
#!/usr/bin/env bash
config="$2"
shift 2
cat "$config"
"$@"
MOCKEOF
  chmod +x "$MOCK_BIN/proxychains4"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Running with proxy 127.0.0.1:9999" ]]
  [[ "$output" =~ "http 127.0.0.1 9999 user pass" ]]
}

@test "proxychains mode fails before IP verification when proxychains4 is missing" {
  write_config '{"proxy":{"url":"http://127.0.0.1:9999","mode":"proxychains"},"verify":{"enabled":true,"expected_country":"JP"}}'

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  ln -s /bin/bash "$MOCK_BIN/bash"
  ln -s "$(command -v jq)" "$MOCK_BIN/jq"
  cat > "$MOCK_BIN/curl" <<'MOCKEOF'
#!/usr/bin/env bash
echo "curl should not be called"
exit 1
MOCKEOF
  chmod +x "$MOCK_BIN/curl"

  PATH="$MOCK_BIN" run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "proxychains4 was not found" ]]
  [[ ! "$output" =~ "Running IP check" ]]
  [[ ! "$output" =~ "curl should not be called" ]]
}

# verify.proxy is called when enabled (mock curl)

@test "verify proxy succeeds with matching country" {
  write_verify_config

  # Create a mock curl that returns JP country
  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/curl" <<'MOCKEOF'
#!/usr/bin/env bash
if [[ "$*" =~ "ipinfo.io" ]]; then
  echo '{"country": "JP"}'
else
  /usr/bin/curl "$@"
fi
MOCKEOF
  chmod +x "$MOCK_BIN/curl"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "JP" ]]
  [[ ! "$output" =~ "✓" ]]
  [[ "$output" =~ "Running with proxy" ]]
  [[ "$output" =~ "actual IP unknown" ]]
  [[ ! "$output" =~ "country JP" ]]
  [[ ! "$output" =~ "HTTP_PROXY" ]]
  [[ ! "$output" =~ "HTTPS_PROXY" ]]
  [[ ! "$output" =~ "Running IP check via" ]]
  [[ ! "$output" =~ '\{"country": "JP"\}' ]]
}

@test "verify proxy shows proxy IP and country before running command" {
  write_verify_config

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/curl" <<'MOCKEOF'
#!/usr/bin/env bash
if [[ "$*" =~ "ipinfo.io" ]]; then
  echo '{"ip": "203.0.113.10", "country": "JP"}'
else
  /usr/bin/curl "$@"
fi
MOCKEOF
  chmod +x "$MOCK_BIN/curl"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Running with proxy 127.0.0.1:9999; actual IP 203.0.113.10" ]]
  [[ ! "$output" =~ "✓" ]]
  [[ ! "$output" =~ "(JP)" ]]
  [[ ! "$output" =~ "HTTP_PROXY" ]]
  [[ ! "$output" =~ "HTTPS_PROXY" ]]
  [[ ! "$output" =~ "Running IP check via" ]]
  [[ ! "$output" =~ '\{"ip": "203.0.113.10", "country": "JP"\}' ]]
}

@test "verify proxy fails with wrong country" {
  write_verify_config

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/curl" <<'MOCKEOF'
#!/usr/bin/env bash
if [[ "$*" =~ "ipinfo.io" ]]; then
  echo '{"country": "US"}'
else
  /usr/bin/curl "$@"
fi
MOCKEOF
  chmod +x "$MOCK_BIN/curl"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "mismatch" ]]
}

@test "verify proxy fails when curl fails" {
  write_verify_config

  local MOCK_BIN
  MOCK_BIN="$(mock_bin_dir)"
  cat > "$MOCK_BIN/curl" <<'MOCKEOF'
#!/usr/bin/env bash
exit 1
MOCKEOF
  chmod +x "$MOCK_BIN/curl"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "ipinfo.io" ]]
}
