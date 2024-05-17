# checkov:skip=CKV_DOCKER_3 user cannot be determined at this stage.
FROM php:nginx as connect-target
LABEL maintainer="Matthew Baggett <matthew@baggett.me>" \
      org.label-schema.vcs-url="https://github.com/benzine-framework/docker-swarm-connectivity-tester" \
      org.opencontainers.image.source="https://github.com/benzine-framework/docker-swarm-connectivity-tester"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo -e "#!/bin/bash\n\ntail -f /var/log/php8.2-fpm.log" > /etc/service/logs-phpfpm-error/run && \
    chmod +x /etc/service/logs-phpfpm-error/run

WORKDIR /app
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ping.php || exit 1
COPY ./public-target /app/public

# checkov:skip=CKV_DOCKER_3 user cannot be determined at this stage.
FROM php:nginx as connect-reporter
LABEL maintainer="Matthew Baggett <matthew@baggett.me>" \
      org.label-schema.vcs-url="https://github.com/benzine-framework/docker-swarm-connectivity-tester" \
      org.opencontainers.image.source="https://github.com/benzine-framework/docker-swarm-connectivity-tester"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo -e "#!/bin/bash\n\ntail -f /var/log/php8.2-fpm.log" > /etc/service/logs-phpfpm-error/run && \
    chmod +x /etc/service/logs-phpfpm-error/run
WORKDIR /app
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ping.php || exit 1
COPY ./composer.* /app/
COPY ./vendor /app/vendor
RUN composer install -q

COPY ./public-reporter /app/public

