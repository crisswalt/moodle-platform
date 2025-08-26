FROM php:8.2-apache

# Build arguments
ARG RELEASE=MOODLE_500_STABLE

# Install system dependencies and clean up in single layer
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt-dev \
    libonig-dev \
    libc-client-dev \
    libkrb5-dev \
    ghostscript \
    graphviz \
    aspell \
    libaspell-dev \
    clamav \
    clamav-daemon \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extension installer
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install PHP extensions using the installer
RUN install-php-extensions \
    mysqli \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    gd \
    zip \
    intl \
    soap \
    xmlrpc \
    opcache \
    mbstring \
    curl \
    openssl \
    tokenizer \
    xml \
    ctype \
    json \
    iconv \
    simplexml \
    dom \
    zip \
    fileinfo \
    sodium \
    exif \
    ldap \
    imap

# Configure Apache
RUN a2enmod rewrite ssl headers
COPY apache-config.conf /etc/apache2/sites-available/moodle.conf
RUN a2ensite moodle && a2dissite 000-default

# Create moodle user and directories
RUN useradd -r -u 1000 -m -c "Moodle user" -d /var/www -s /bin/false moodle \
    && mkdir -p /var/www/moodledata \
    && mkdir -p /var/www/html \
    && chown -R moodle:moodle /var/www

# Clone Moodle from Git repository
WORKDIR /var/www/html
RUN git clone -b ${RELEASE} --depth 1 https://github.com/moodle/moodle.git . \
    && rm -rf .git \
    && chown -R www-data:www-data /var/www/html \
    && chown -R moodle:moodle /var/www/moodledata \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/moodledata

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/moodle.ini

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/login/index.php || exit 1

# Set working directory
WORKDIR /var/www/html

# Use custom entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]