#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  cp ./rootfs/usr/local/bin/echo-color "$MOCKDIR/echo-color"
  cp ./rootfs/usr/local/bin/list-installed-modules "$MOCKDIR/list-installed-modules"
  chmod +x "$MOCKDIR/"*

  export PATH="$MOCKDIR:$PATH"

  cp ./rootfs/usr/local/bin/list-installed-modules ./list-installed-modules-test.sh
  chmod +x ./list-installed-modules-test.sh
}

teardown() {
  rm -rf "$MOCKDIR"
  rm -f ./list-installed-modules-test.sh
}

@test "lists installed modules correctly" {
  run ./list-installed-modules-test.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"date"* ]]
  [[ "$output" == *"zlib"* ]]
  [[ "$output" == *"opcache"* ]]
}

@test "hides defaults modules" {
    run ./list-installed-modules-test.sh
    [ "$status" -eq 0 ]
    [[ "$output" != *"core"* ]]
    [[ "$output" != *"spl"* ]]
}