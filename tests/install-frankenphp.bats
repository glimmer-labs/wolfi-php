#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  cp ./rootfs/usr/local/bin/echo-color "$MOCKDIR/echo-color"
  cp ./rootfs/usr/local/bin/list-installed-modules "$MOCKDIR/list-installed-modules"
  chmod +x "$MOCKDIR/"*

  export PATH="$MOCKDIR:$PATH"

  cp ./rootfs/usr/local/bin/install-frankenphp ./install-frankenphp-test.sh
  chmod +x ./install-frankenphp-test.sh
}

teardown() {
  rm -rf "$MOCKDIR"
  rm -f ./install-frankenphp-test.sh
}

@test "fails with invalid PHP version format" {
  # Override php to return invalid version
  echo '#!/bin/sh' > "$MOCKDIR/php"
  echo 'echo "invalid"' >> "$MOCKDIR/php"
  chmod +x "$MOCKDIR/php"

  run ./install-frankenphp-test.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid PHP version format"* ]]
}

@test "fails when PHP is not ZTS" {
  run ./install-frankenphp-test.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"FrankenPHP requires ZTS (Zend Thread Safety) enabled PHP"* ]]
}

@test "installs FrankenPHP with pcntl extension" {
  export PHP_ZTS=1

  run ./install-frankenphp-test.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing FrankenPHP"* ]]
  [[ "$output" == *"installed successfully"* ]]
}