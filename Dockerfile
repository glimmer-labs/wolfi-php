FROM cgr.dev/chainguard/wolfi-base:latest

ENV PHP_FPM_USER=www-data \
    PHP_FPM_GROUP=www-data \
    PHP_FPM_ACCESS_LOG=/proc/self/fd/2 \
    PHP_FPM_LISTEN=[::]:9000 \
    PHP_FPM_PM=dynamic \
    PHP_FPM_PM_MAX_CHILDREN=5 \
    PHP_FPM_PM_START_SERVERS=2 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=1 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=3 \
    PHP_FPM_PM_MAX_REQUESTS=0 \
    PHP_FPM_PM_STATUS_PATH=/-/fpm/status \
    PHP_FPM_PING_PATH=/-/fpm/ping \
    PHP_ERROR_REPORTING="" \
    PHP_DISPLAY_ERRORS=On \
    PHP_DISPLAY_STARTUP_ERRORS=On \
    PHP_UPLOAD_MAX_FILESIZE=8M \
    PHP_POST_MAX_SIZE=8M \
    PHP_MAX_EXECUTION_TIME=30 \
    PHP_MEMORY_LIMIT=128M \
    PHP_SESSION_HANDLER=files \
    PHP_SESSION_SAVE_PATH="" \
    PHP_SESSION_GC_PROBABILITY=1

RUN adduser -u 82 www-data -D

COPY rootfs/ /
RUN chmod +x /usr/local/bin/*
