# Wolfi PHP

A Docker image based on Wolfi Linux "optimized" for Laravel applications.

```dockerfile
FROM ghcr.io/glimmer-labs/wolfi-php:latest
```

## Overview

This Docker image provides a lightweight and secure environment for running Laravel applications. It's based on the Wolfi Linux (un)distribution, which is designed specifically for containers.

The image includes scripts to easily install PHP, Composer, and required PHP extensions for Laravel applications.

## Base Features

- Based on Wolfi Linux (cgr.dev/chainguard/wolfi-base)
- Supports any PHP version that Wolfi supports (8.0, 8.3, 8.4, etc.)
- Installation of default extensions required for Laravel applications
- Easy installation of extra PHP extensions supported by Wolfi
- Automatic detection and installation of extensions required by your Composer dependencies
- Adds www-data user and group for FPM process (not installed by default)
- Supports using FrankenPHP as an alternative to base PHP (uses [Shyim repository](https://github.com/shyim/wolfi-php))

## FrankenPHP Features
If you choose to use FrankenPHP instead of the base PHP, the image will also include the following features:
- Support for runnning Laravel Octane applications with FrankenPHP (requires `pcntl` extension, which is installed by default when using FrankenPHP)
- XDG Config and Data directories set in the same way as the official FrankenPHP image
- A default Caddyfile as the official FrankenPHP does, with the same available environment variables:
    - `SERVER_NAME` - The server name for Caddy. Default is `localhost` - This controls also the listing port of Caddy, use `:8000` as example for port `8000`
    - `FRANKENPHP_CONFIG` - Allows setting configuration for FrankenPHP specific like: `worker ./public/index.php`
    - `CADDY_GLOBAL_OPTIONS` - Allows setting global options for Caddy like: `debug`
    - `CADDY_EXTRA_CONFIG` - Allows setting extra Caddy configuration like add new virtual host: `foo.com { root /app/public }`
    - `CADDY_SERVER_EXTRA_DIRECTIVES` - Allows setting extra Caddy configuration for the default virtual host.
- You can override the default Caddyfile by mounting your own Caddyfile at `/etc/caddy/Caddyfile` in your Dockerfile or at runtime.

## Notes
This image has a default `WORKDIR` which is `/app`, so you can use it as your application root. You can change it in your Dockerfile if needed.

This image doesn't contain a default `ENTRYPOINT` or `CMD`, so you must set it in your Dockerfile. For example:
- PHP-FPM:
    ```dockerfile
    ENTRYPOINT [ "php-fpm"] 
    CMD [ "--nodaemonize" ]
    ```
- FrankenPHP:
    ```dockerfile
    ENTRYPOINT [ "frankenphp", "run" ]
    CMD [ "--config", "/etc/caddy/Caddyfile" ]
    ```

Nor does it have a Healthcheck set, so you can add one in your Dockerfile if needed. For example:
- PHP-FPM:
    ```dockerfile
    ADD --chmod=0755 https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck /usr/local/bin/php-fpm-healthcheck

    HEALTHCHECK --interval=5s --timeout=1s CMD php-fpm-healthcheck || exit 1
    ```
- FrankenPHP:
    ```dockerfile
    HEALTHCHECK CMD curl -f http://localhost:2019/metrics || exit 1
    ```

## Available Scripts

### install-php

Installs PHP and core extensions required for Laravel.

```
install-php <php_version> [--composer] [--frankenphp]
```

Arguments:
- `php_version`: PHP version to install (e.g., 8.3, 8.4)
- `--composer`: Optional flag to also install Composer
- `--frankenphp`: Optional flag to install FrankenPHP instead of base PHP (uses [Shyim repository](https://github.com/shyim/wolfi-php))

### add-php-extensions

Installs additional PHP extensions.

```
add-php-extensions extension1 [extension2 ...]
```

### add-composer-extensions

Checks composer.json/composer.lock for required PHP extensions and installs them.

```
add-composer-extensions [--no-dev] [--check-only]
```

Options:
- `--no-dev`: Skips dev dependencies and extensions (recommended for production containers)
- `--check-only`: Checks only for required extensions, doesn't install them (recommended for production containers)

The `--check-only` flag is particularly important for production containers as it:
- Ensures all required extensions are already installed in the image
- Fails the build if any required extensions are missing
- Makes the build process more deterministic and secure

### install-composer

Installs Composer globally.

```
install-composer
```

### remove-composer

Removes Composer from the image.

```
remove-composer
```

### do-cleanup

Removes all utility scripts to reduce the final image size.

```
do-cleanup
```

Options:
- `--wolfi-base`: Deletes the wolfi-base package, which is not needed in production images

## Environment Variables

The image supports the following environment variables for PHP configuration (with their default values):

```
PHP_EXPOSE=Off
PHP_ERROR_REPORTING=""
PHP_DISPLAY_ERRORS=Off
PHP_DISPLAY_STARTUP_ERRORS=Off
PHP_LOG_ERRORS=Off
PHP_ERROR_LOG=/var/log/php_errors.log
PHP_MAX_FILE_UPLOADS=20
PHP_UPLOAD_MAX_FILESIZE=8M
PHP_POST_MAX_SIZE=8M
PHP_MAX_EXECUTION_TIME=30
PHP_MEMORY_LIMIT=128M
PHP_SESSION_HANDLER=files
PHP_SESSION_SAVE_PATH=""
PHP_SESSION_GC_PROBABILITY=1
```

And for PHP-FPM:

```
PHP_FPM_USER=www-data
PHP_FPM_GROUP=www-data
PHP_FPM_ACCESS_LOG=/proc/self/fd/2
PHP_FPM_LISTEN=[::]:9000
PHP_FPM_PM=dynamic
PHP_FPM_PM_MAX_CHILDREN=5
PHP_FPM_PM_START_SERVERS=2
PHP_FPM_PM_MIN_SPARE_SERVERS=1
PHP_FPM_PM_MAX_SPARE_SERVERS=3
PHP_FPM_PM_MAX_REQUESTS=0
PHP_FPM_PM_STATUS_PATH=/-/fpm/status
PHP_FPM_PING_PATH=/-/fpm/ping
```

## Common Use Cases

### Development Container with Composer

```dockerfile
FROM ghcr.io/glimmer-labs/wolfi-php:latest

RUN install-php 8.4 --composer
# Add specific extensions needed by your application
RUN add-php-extensions pgsql redis

COPY ./composer.json composer.lock ./
# Automatically install required PHP extensions based on composer.json
RUN add-composer-extensions

RUN composer install

COPY . .
```

### Production-Ready Container

For production environments, it's recommended to use the `--check-only` flag with `add-composer-extensions` to ensure all required extensions are already installed.
> We recommend using a [multi-stage](#multi-stage-build-pattern) build pattern for production containers to keep the final image size small and secure.

```dockerfile
FROM ghcr.io/glimmer-labs/wolfi-php:latest

RUN install-php 8.4 --composer
RUN add-php-extensions pgsql redis

COPY ./composer.json composer.lock ./
# Verify all required extensions are installed (fails if any are missing)
RUN add-composer-extensions --no-dev --check-only

RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --no-scripts
COPY . .
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

# Set permissions to folders by the web server user
# You can create a new user or adjust it as needed
# www-data already exists in the base image
RUN chown -R www-data:www-data storage bootstrap/cache

# Clean up helper scripts
RUN do-cleanup

ENTRYPOINT ["your-entrypoint-command"]
```

### Multi-Stage Build Pattern

We recommend using a multi-stage build pattern for production containers to keep the final image size small and secure.

```dockerfile
# Base stage
FROM ghcr.io/glimmer-labs/wolfi-php:latest AS base

RUN install-php 8.4
RUN add-php-extensions pgsql redis

WORKDIR /app

# Composer dependency installation stage
FROM base as composer

RUN install-composer

COPY ./composer.json composer.lock ./
# Check if all required PHP extensions are installed
RUN add-composer-extensions --no-dev --check-only

RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --no-scripts
COPY . .
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader

# Production stage
FROM base

COPY --link --from=composer /app /app

# Set permissions to folders by the web server user
# You can create a new user or adjust it as needed
# www-data already exists in the base image
RUN chown -R www-data:www-data storage bootstrap/cache

RUN do-cleanup

ENTRYPOINT ["your-entrypoint-command"]
```
