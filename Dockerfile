FROM php:8.2-apache

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (Unificado en una sola capa limpia)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    ghostscript \
    graphviz \
    aspell \
    curl \
    gettext-base \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Reset environment variable
ENV DEBIAN_FRONTEND=dialog

# Install PHP extension installer de mlocati
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install PHP extensions (CORREGIDO: Agregado redis y eliminadas redundancias)
RUN install-php-extensions \
    mysqli \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    gd \
    zip \
    intl \
    soap \
    opcache \
    mbstring \
    curl \
    xml \
    simplexml \
    dom \
    fileinfo \
    sodium \
    exif \
    ldap \
    imap \
    redis

# Configure Apache
RUN a2enmod rewrite ssl headers
COPY apache-config.conf /etc/apache2/sites-available/moodle.conf
RUN a2ensite moodle && a2dissite 000-default

# Estructura de directorios estándar garantizando que Apache (www-data) sea dueño
RUN mkdir -p /var/www/moodledata \
    && mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www

# Set working directory antes de operaciones de archivo
WORKDIR /var/www/html

# Ajuste estricto de permisos para Moodle
RUN chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/moodledata

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/moodle.ini

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 80

# Use custom entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
