# Wolfi PHP

A Docker image based on Wolfi Linux "optimized" for Laravel applications.

```dockerfile
FROM ghcr.io/laravel-glimmer/wolfi-php@latest
```

## Overview

This Docker image provides a lightweight and secure environment for running Laravel applications. It's based on the Wolfi Linux (un)distribution, which is designed specifically for containers.

The image includes scripts to easily install PHP, Composer, and required PHP extensions for Laravel applications.

## Features

- Based on Wolfi Linux (cgr.dev/chainguard/wolfi-base)
- Supports any PHP version that Wolfi supports (8.0, 8.3, 8.4, etc.)
- Installation of default extensions required for Laravel applications
- Easy installation of extra PHP extensions supported by Wolfi
- Automatic detection and installation of extensions required by your Composer dependencies
- Adds www-data user and group for FPM process (not installed by default)

## Available Scripts

### install-php

Installs PHP and core extensions required for Laravel.

```
install-php <php_version> [--composer]
```

Arguments:
- `php_version`: PHP version to install (e.g., 8.3, 8.4)
- `--composer`: Optional flag to also install Composer

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

## Environment Variables

The image supports the following environment variables for PHP and PHP-FPM configuration:

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
PHP_ERROR_REPORTING=""
PHP_DISPLAY_ERRORS=On
PHP_DISPLAY_STARTUP_ERRORS=On
PHP_UPLOAD_MAX_FILESIZE=8M
PHP_POST_MAX_SIZE=8M
PHP_MAX_EXECUTION_TIME=30
PHP_MEMORY_LIMIT=128M
PHP_SESSION_HANDLER=files
PHP_SESSION_SAVE_PATH=""
PHP_SESSION_GC_PROBABILITY=1
```

## Common Use Cases

### Development Container with Composer

```dockerfile
FROM ghcr.io/laravel-glimmer/wolfi-php:latest

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
FROM ghcr.io/laravel-glimmer/wolfi-php:latest

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
FROM ghcr.io/laravel-glimmer/wolfi-php:latest AS base

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
