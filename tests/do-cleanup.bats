#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  chmod +x "$MOCKDIR/"*

  export PATH="$MOCKDIR:$PATH"

  # Setup fake /usr/local/bin directory with real scripts copied
  FAKE_USR_LOCAL_BIN="$(mktemp -d)"
  export FAKE_USR_LOCAL_BIN
  cp ./rootfs/usr/local/bin/* "$FAKE_USR_LOCAL_BIN/"
  rm -rf "$FAKE_USR_LOCAL_BIN/do-cleanup"

  cp ./rootfs/usr/local/bin/do-cleanup ./do-cleanup-test.sh

  # Patch the cleanup script to remove from the fake dir, not actual /usr/local/bin
  sed -i "s|/usr/local/bin|$FAKE_USR_LOCAL_BIN|g" ./do-cleanup-test.sh
  chmod +x ./do-cleanup-test.sh
}

teardown() {
  rm -rf "$MOCKDIR" "$FAKE_USR_LOCAL_BIN"
  rm -f ./do-cleanup-test.sh
}

@test "removes all scripts including itself" {
  run ./do-cleanup-test.sh

  [ "$status" -eq 0 ]

  [[ "$output" == *"Removing cleanup script"* ]]
  [[ "$output" == *"Cleanup complete"* ]]

  # Assert that the fake /usr/local/bin folder is empty (all scripts deleted)
  [ -z "$(ls -A "$FAKE_USR_LOCAL_BIN")" ]
}
