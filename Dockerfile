FROM cgr.dev/chainguard/wolfi-base:latest

# FrankenPHP
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data
ENV GODEBUG=cgocheck=0

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

# PHP
ENV PHP_EXPOSE=Off \
    PHP_ERROR_REPORTING="" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_LOG_ERRORS=Off \
    PHP_ERROR_LOG=/var/log/php_errors.log \
    PHP_MAX_FILE_UPLOADS=20 \
    PHP_UPLOAD_MAX_FILESIZE=8M \
    PHP_POST_MAX_SIZE=8M \
    PHP_MAX_EXECUTION_TIME=30 \
    PHP_MEMORY_LIMIT=128M \
    PHP_SESSION_HANDLER=files \
    PHP_SESSION_SAVE_PATH="" \
    PHP_SESSION_GC_PROBABILITY=1

# PHP-FPM
ENV PHP_FPM_USER=php \
    PHP_FPM_GROUP=php \
    PHP_FPM_ACCESS_LOG=/proc/self/fd/2 \
    PHP_FPM_LISTEN=[::]:9000 \
    PHP_FPM_PM=dynamic \
    PHP_FPM_PM_MAX_CHILDREN=5 \
    PHP_FPM_PM_START_SERVERS=2 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=1 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_REQUESTS=0 \
    PHP_FPM_PM_STATUS_PATH=/-/fpm/status \
    PHP_FPM_PING_PATH=/-/fpm/ping

EXPOSE 9000

COPY rootfs/ /
RUN chmod +x /usr/local/bin/*

RUN add-glimmer-labs-repo

# Create non-root user for running PHP / PHP-FPM / FrankenPHP
RUN addgroup -S php 2>/dev/null || true && \
    adduser -S -D -H -G php php 2>/dev/null || true

# Prepare runtime directories and hand ownership to php
RUN mkdir -p /var/log /config /data /app && \
    chown -R php:php /var/log /config /data /app

WORKDIR /app
