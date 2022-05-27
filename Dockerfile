FROM php:8.1-fpm-alpine

RUN set -xe; \
    apk add --no-cache \
      imagemagick \
      wget \
      fcgi \
      libmcrypt \
      libjpeg-turbo-utils \
      jpeg-dev \
      mariadb-client \
      unzip \
      zip; \
    apk add --no-cache --virtual .build-deps \
      imap-dev \
      krb5-dev \
      freetype-dev \
      libpng-dev \
      imagemagick-dev \
      libxml2-dev \
      libzip-dev \
      libressl-dev \
      autoconf \
      make \
      g++; \
    pecl install imagick; \
    pecl install redis; \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/; \
    docker-php-ext-configure zip; \
    docker-php-ext-enable \
      imagick \
      redis; \
    docker-php-ext-install -j$(nproc) \
      imap \
      pdo_mysql \
      mysqli \
      opcache \
      soap \
      zip \
      exif \
      gd \
      zip \
      opcache; \
    apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf; \
    wget -O /usr/local/bin/php-fpm-healthcheck \
    https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck; \
    chmod +x /usr/local/bin/php-fpm-healthcheck