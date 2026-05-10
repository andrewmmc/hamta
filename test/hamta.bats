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
  mkdir -p "$HOME/.config/hamta"
  echo '{}' > "$HOME/.config/hamta/config.json"
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
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"}}' > "$HOME/.config/hamta/config.json"
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
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true,"expected_country":"JP"},"prompt":true}' \
    > "$HOME/.config/hamta/config.json"
  run "$HAMTA" nonexistentcommand12345
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Command not found" ]]
}

# proxy.url null or empty

@test "dies when proxy.url is null" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":null}}' > "$HOME/.config/hamta/config.json"
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not set" ]]
}

@test "dies when proxy.url is empty string" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":""}}' > "$HOME/.config/hamta/config.json"
  run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "not set" ]]
}

# run with verify disabled and prompt disabled -> exec path

@test "runs command with verify and prompt disabled" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":false,"expected_country":"JP"},"prompt":false}' \
    > "$HOME/.config/hamta/config.json"
  run "$HAMTA" echo "hello world"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "hello world" ]]
  [[ "$output" =~ "Running" ]]
}

# proxy env vars are exported

@test "exports proxy environment variables" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":false,"expected_country":"JP"},"prompt":false}' \
    > "$HOME/.config/hamta/config.json"
  run "$HAMTA" env
  [ "$status" -eq 0 ]
  [[ "$output" =~ "HTTP_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "HTTPS_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "ALL_PROXY=http://127.0.0.1:9999" ]]
  [[ "$output" =~ "NODE_USE_ENV_PROXY=1" ]]
}

# verify.proxy is called when enabled (mock curl)

@test "verify proxy succeeds with matching country" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true,"expected_country":"JP"},"prompt":false}' \
    > "$HOME/.config/hamta/config.json"

  # Create a mock curl that returns JP country
  local MOCK_BIN="$TEST_DIR/mockbin"
  mkdir -p "$MOCK_BIN"
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
}

@test "verify proxy fails with wrong country" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true,"expected_country":"JP"},"prompt":false}' \
    > "$HOME/.config/hamta/config.json"

  local MOCK_BIN="$TEST_DIR/mockbin"
  mkdir -p "$MOCK_BIN"
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
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":true,"expected_country":"JP"},"prompt":false}' \
    > "$HOME/.config/hamta/config.json"

  local MOCK_BIN="$TEST_DIR/mockbin"
  mkdir -p "$MOCK_BIN"
  cat > "$MOCK_BIN/curl" <<'MOCKEOF'
#!/usr/bin/env bash
exit 1
MOCKEOF
  chmod +x "$MOCK_BIN/curl"

  PATH="$MOCK_BIN:$PATH" run "$HAMTA" true
  [ "$status" -eq 1 ]
  [[ "$output" =~ "ipinfo.io" ]]
}

# prompt answers 'y' and continues

@test "prompt with 'y' continues to run command" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":false,"expected_country":"JP"},"prompt":true}' \
    > "$HOME/.config/hamta/config.json"

  run bash -c "echo y | \"$HAMTA\" echo ok"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ok" ]]
}

@test "prompt with 'n' cancels" {
  mkdir -p "$HOME/.config/hamta"
  echo '{"proxy":{"url":"http://127.0.0.1:9999"},"verify":{"enabled":false,"expected_country":"JP"},"prompt":true}' \
    > "$HOME/.config/hamta/config.json"

  run bash -c "echo n | \"$HAMTA\" echo ok"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Cancelled" ]]
}
