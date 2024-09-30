FROM php:8.3.12-fpm AS base

WORKDIR /var/www

ENV PHP_OPCACHE_ENABLE="0" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10" \
    PHP_OPCACHE_JIT_BUFFER_SIZE="0" \
    PHP_OPCACHE_JIT="0" \
    COMPOSER_ALLOW_SUPERUSER=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libpq-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*docker

RUN pecl install redis
# Install PHP extensions
RUN docker-php-ext-install mbstring exif pcntl bcmath sockets opcache pdo pdo_pgsql

RUN docker-php-ext-enable redis

COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/php/conf.d/realpath.ini /usr/local/etc/php/conf.d/realpath.ini

FROM base AS prod

COPY docker/php/conf.d/preload.ini /usr/local/etc/php/conf.d/preload.ini

COPY ./bin /app/bin
COPY ./config /app/config
COPY ./migrations /app/migrations
COPY ./public /app/public
COPY ./src /app/src
COPY composer.* /app

COPY --from=composer:2.7.2 /usr/bin/composer /usr/bin/composer

RUN composer install -o
