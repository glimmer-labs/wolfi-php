#!/usr/bin/env bats

setup() {
  MOCKDIR="$(mktemp -d)"
  cp ./tests/mocks/* "$MOCKDIR/"
  cp ./rootfs/usr/local/bin/echo-color "$MOCKDIR/echo-color"
  cp ./rootfs/usr/local/bin/list-installed-modules "$MOCKDIR/list-installed-modules"
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
  [[ "$output" == *"Installing PHP 8.3..."* ]]
  [[ "$output" == *"Installing base extensions for Laravel..."* ]]
  [[ "$output" == *"PHP 8.3 and base Laravel required extensions installation completed successfully."* ]]
}

@test "installs PHP with composer" {
  run ./install-php-test.sh 8.3 --composer
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing Composer..."* ]]
  [[ "$output" == *"install-composer called"* ]]
  [[ "$output" == *"PHP 8.3, base Laravel required extensions and Composer installation completed successfully."* ]]
}

@test "installs FrankenPHP without composer" {
  run ./install-php-test.sh 8.3 --frankenphp
  [ "$status" -eq 0 ]
  echo $output
  [[ "$output" == *"Installing PHP 8.3 ZTS with FrankenPHP..."* ]]
  [[ "$output" == *"Installing base extensions for Laravel..."* ]]
  [[ "$output" == *"PHP 8.3 ZTS with FrankenPHP and base Laravel required extensions installation completed successfully."* ]]
}

@test "installs FrankenPHP with composer" {
  run ./install-php-test.sh 8.3 --composer --frankenphp
  [ "$status" -eq 0 ]
  echo $output
  [[ "$output" == *"Installing PHP 8.3 ZTS with FrankenPHP..."* ]]
  [[ "$output" == *"Installing base extensions for Laravel..."* ]]
  [[ "$output" == *"PHP 8.3 ZTS with FrankenPHP, base Laravel required extensions and Composer installation completed successfully."* ]]
}

@test "installs PHP ZTS version without composer" {
  run ./install-php-test.sh 8.3 --zts
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing PHP 8.3 ZTS..."* ]]
  [[ "$output" == *"Installing base extensions for Laravel..."* ]]
  [[ "$output" == *"PHP 8.3 ZTS and base Laravel required extensions installation completed successfully."* ]]
}

@test "installs PHP ZTS version with composer" {
  run ./install-php-test.sh 8.3 --composer --zts
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing PHP 8.3 ZTS..."* ]]
  [[ "$output" == *"Installing Composer..."* ]]
  [[ "$output" == *"install-composer called"* ]]
  [[ "$output" == *"PHP 8.3 ZTS, base Laravel required extensions and Composer installation completed successfully."* ]]
}

@test "detects PHP ZTS already installed" {
  export PHP_ZTS=1

  run ./install-php-test.sh 8.3 --composer
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing PHP 8.3 ZTS..."* ]]
  [[ "$output" == *"Installing Composer..."* ]]
  [[ "$output" == *"install-composer called"* ]]
  [[ "$output" == *"PHP 8.3 ZTS, base Laravel required extensions and Composer installation completed successfully."* ]]
}