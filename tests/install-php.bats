#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  chmod +x "$MOCKDIR/"*

  export PATH="$MOCKDIR:$PATH"

  cp ./rootfs/usr/local/bin/install-php ./install-php-test.sh
  chmod +x ./install-php-test.sh
}

teardown() {
  rm -rf "$MOCKDIR"
  rm -f ./install-php-test.sh
}

@test "fails when no arguments are given" {
  run ./install-php-test.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"PHP version is required"* ]]
}

@test "fails with invalid version format" {
  run ./install-php-test.sh notaversion
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid PHP version format"* ]]
}

@test "fails with unknown flag" {
  run ./install-php-test.sh 8.3 --bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown option"* ]]
}

@test "installs PHP without composer" {
  run ./install-php-test.sh 8.3
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing PHP 8.3 and core extensions for Laravel..."* ]]
  [[ "$output" == *"PHP 8.3 and Laravel required extensions installation completed successfully."* ]]
}

@test "installs PHP with composer" {
  run ./install-php-test.sh 8.3 --composer
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing Composer..."* ]]
  [[ "$output" == *"install-composer called"* ]]
  [[ "$output" == *"PHP 8.3, Laravel required extensions and Composer installation completed successfully."* ]]
}

@test "installs FrankenPHP without composer" {
  run ./install-php-test.sh 8.3 --frankenphp
  [ "$status" -eq 0 ]
  echo $output
  [[ "$output" == *"Installing FrankenPHP 8.3 and core extensions for Laravel..."* ]]
  [[ "$output" == *"FrankenPHP 8.3 and Laravel required extensions installation completed successfully."* ]]
}

@test "installs FrankenPHP with composer" {
  run ./install-php-test.sh 8.3 --composer --frankenphp
  [ "$status" -eq 0 ]
  echo $output
  [[ "$output" == *"Installing FrankenPHP 8.3 and core extensions for Laravel..."* ]]
  [[ "$output" == *"FrankenPHP 8.3, Laravel required extensions and Composer installation completed successfully."* ]]
}