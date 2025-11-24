#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  cp ./rootfs/usr/local/bin/echo-color "$MOCKDIR/echo-color"
  cp ./rootfs/usr/local/bin/list-installed-modules "$MOCKDIR/list-installed-modules"
  chmod +x "$MOCKDIR/"*

  export PATH="$MOCKDIR:$PATH"

  cp ./rootfs/usr/local/bin/add-php-extensions ./add-php-extensions-test.sh
  chmod +x ./add-php-extensions-test.sh
}

teardown() {
  rm -rf "$MOCKDIR"
  rm -f ./add-php-extensions-test.sh
}

@test "exits early when no extensions provided" {
  run ./add-php-extensions-test.sh
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No extensions to install."* ]]
}

@test "fails on invalid PHP version format" {
  # Override php to return invalid version
  echo '#!/bin/sh' > "$MOCKDIR/php"
  echo 'echo "invalid"' >> "$MOCKDIR/php"
  chmod +x "$MOCKDIR/php"

  run ./add-php-extensions-test.sh redis
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid PHP version format"* ]]
}

@test "detects and skips already installed extensions" {
  run ./add-php-extensions-test.sh date zlib
  [ "$status" -eq 0 ]
  echo "$output"
  [[ "$output" == *"These extensions are already installed and will be skipped"* ]]
  [[ "$output" == *"> date, zlib"* ]]
  [[ "$output" == *"No extensions to install."* ]]
}

@test "installs single extension" {
  run ./add-php-extensions-test.sh redis
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing extensions:"* ]]
  [[ "$output" == *"php-8.3-redis"* ]]
  [[ "$output" == *"apk called with: add --no-cache php-8.3-redis"* ]]
  [[ "$output" == *"Extensions installation complete."* ]]
}

@test "skips already installed extensions and installs new ones" {
  run ./add-php-extensions-test.sh date zlib redis gd
  [ "$status" -eq 0 ]
  echo "$output"
  [[ "$output" == *"These extensions are already installed and will be skipped"* ]]
  [[ "$output" == *"> date, zlib"* ]]
  [[ "$output" == *"Installing extensions:"* ]]
  [[ "$output" == *"> php-8.3-redis, php-8.3-gd"* ]]
  [[ "$output" == *"Extensions installation complete."* ]]
}

@test "installs mapped extensions (pgsql + pdo)" {
  run ./add-php-extensions-test.sh pgsql
  [ "$status" -eq 0 ]
  [[ "$output" == *"php-8.3-pgsql"* ]]
  [[ "$output" == *"php-8.3-pdo_pgsql"* ]]
  [[ "$output" == *"apk called with: add --no-cache php-8.3-pgsql php-8.3-pdo_pgsql"* ]]
}

@test "installs sqlite using special mapping" {
  run ./add-php-extensions-test.sh sqlite
  [ "$status" -eq 0 ]
  [[ "$output" == *"php-8.3-pdo_sqlite"* ]]
  [[ "$output" == *"apk called with: add --no-cache php-8.3-pdo_sqlite"* ]]
}

@test "installs frankenphp single extension" {
  export APK_INFO_MOCK=1

  run ./add-php-extensions-test.sh redis
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing extensions:"* ]]
  [[ "$output" == *"php-8.3-redis"* ]]
  [[ "$output" == *"apk called with: add --no-cache php-frankenphp-8.3-redis"* ]]
  [[ "$output" == *"Extensions installation complete."* ]]
}

@test "installs frankenphp mapped extensions (pgsql + pdo)" {
  export APK_INFO_MOCK=1

  run ./add-php-extensions-test.sh pgsql
  [ "$status" -eq 0 ]
  [[ "$output" == *"php-8.3-pgsql"* ]]
  [[ "$output" == *"php-8.3-pdo_pgsql"* ]]
  [[ "$output" == *"apk called with: add --no-cache php-frankenphp-8.3-pgsql php-frankenphp-8.3-pdo_pgsql"* ]]
}