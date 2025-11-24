#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  cp ./rootfs/usr/local/bin/echo-color "$MOCKDIR/echo-color"
  chmod +x "$MOCKDIR/"*

  export PATH="$MOCKDIR:$PATH"

  # Setup dummy composer.json/lock
  touch composer.json composer.lock

  cp ./rootfs/usr/local/bin/add-composer-extensions ./add-composer-extensions-test.sh
  chmod +x ./add-composer-extensions-test.sh
}

teardown() {
  rm -rf "$MOCKDIR"
  rm -f ./add-composer-extensions-test.sh
  rm -f composer.json composer.lock
}

@test "exits if composer.json is missing" {
  rm composer.json
  run ./add-composer-extensions-test.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"composer.json file not found"* ]]
}

@test "exits if composer.lock is missing" {
  rm composer.lock
  run ./add-composer-extensions-test.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"composer.lock file not found"* ]]
}

@test "succeeds when no missing extensions" {
  export COMPOSER_MISSING_EXTENSIONS=""
  run ./add-composer-extensions-test.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"No missing PHP extensions found."* ]]
}

@test "prints missing extensions with --check-only" {
  export COMPOSER_MISSING_EXTENSIONS="ext-pdo missing \n ext-sodium missing"
  run ./add-composer-extensions-test.sh --check-only
  [ "$status" -eq 1 ]
  [[ "$output" == *"Found missing PHP extensions."* ]]
  [[ "$output" == *"- pdo"* ]]
  [[ "$output" == *"- sodium"* ]]
}

@test "calls add-php-extensions when extensions are missing" {
  export COMPOSER_MISSING_EXTENSIONS="ext-curl missing \n ext-mbstring missing"
  run ./add-composer-extensions-test.sh
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Found missing PHP extensions."* ]]
  [[ "$output" == *"add-php-extensions called with: curl mbstring"* ]]
}
