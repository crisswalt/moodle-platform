#!/bin/bash
set -euo pipefail

# Function to wait for database
wait_for_db() {
    echo "Waiting for database connection..."
    while ! mysqladmin ping -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" --silent; do
        sleep 2
    done
    echo "Database is ready!"
}

# Function to clone/update Moodle if needed
setup_moodle_code() {
    if [ ! -f "/var/www/html/version.php" ]; then
        echo "Moodle code not found. Cloning from repository..."
        
        # Remove any existing files (like .gitkeep)
        rm -rf /var/www/html/*
        rm -rf /var/www/html/.[^.]*
        
        # Clone Moodle
        git clone -b ${MOODLE_RELEASE} --depth 1 https://github.com/moodle/moodle.git /tmp/moodle
        
        # Move files to html directory
        mv /tmp/moodle/* /var/www/html/
        mv /tmp/moodle/.[^.]* /var/www/html/ 2>/dev/null || true
        
        # Clean up
        rm -rf /tmp/moodle
        
        # Set correct permissions
        chown -R www-data:www-data /var/www/html
        chmod -R 755 /var/www/html
        
        echo "Moodle code cloned successfully!"
    else
        echo "Moodle code already exists. Skipping clone."
    fi
}

# Function to substitute environment variables in PHP config
substitute_env_vars() {
    # Substitute environment variables in PHP configuration
    envsubst '${PHP_MEMORY_LIMIT} ${PHP_MAX_EXECUTION_TIME} ${PHP_UPLOAD_MAX_FILESIZE} ${PHP_POST_MAX_SIZE} ${PHP_MAX_INPUT_VARS} ${TZ}' \
        < /usr/local/etc/php/conf.d/moodle.ini > /tmp/moodle.ini && \
        mv /tmp/moodle.ini /usr/local/etc/php/conf.d/moodle.ini
}

# Function to create Moodle config if it doesn't exist
create_moodle_config() {
    if [ ! -f "/var/www/html/config.php" ]; then
        echo "Creating Moodle configuration..."
        
        cat > /var/www/html/config.php << EOF
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mysqli';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${DB_HOST}';
\$CFG->dbname    = '${DB_NAME}';
\$CFG->dbuser    = '${DB_USER}';
\$CFG->dbpass    = '${DB_PASSWORD}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => '${DB_PORT}',
    'dbhandlesoptions' => false,
    'dbcollation' => 'utf8mb4_unicode_ci',
);

\$CFG->wwwroot   = '${MOODLE_URL}';
\$CFG->dataroot  = '${MOODLE_DATA_PATH}';
\$CFG->directorypermissions = 02777;
\$CFG->admin     = 'admin';

// Performance and security settings
\$CFG->session_handler_class = '\core\session\file';
\$CFG->session_file_save_path = \$CFG->dataroot.'/sessions';

// Cache settings (Redis if available)
EOF

        if [ ! -z "${REDIS_HOST:-}" ]; then
            cat >> /var/www/html/config.php << EOF
\$CFG->session_handler_class = '\core\session\redis';
\$CFG->session_redis_host = '${REDIS_HOST}';
\$CFG->session_redis_port = ${REDIS_PORT};
\$CFG->session_redis_acquire_lock_timeout = 120;

// Redis cache store
\$CFG->cachestores = array(
    'redis' => array(
        'type' => 'redis',
        'server' => '${REDIS_HOST}:${REDIS_PORT}',
        'database' => 1,
    ),
);
EOF
        fi

        cat >> /var/www/html/config.php << EOF

// Debug settings
EOF
        if [ "${MOODLE_DEBUG:-false}" == "true" ]; then
            cat >> /var/www/html/config.php << EOF
\$CFG->debug = (E_ALL | E_STRICT);
\$CFG->debugdisplay = 1;
EOF
        else
            cat >> /var/www/html/config.php << EOF
\$CFG->debug = 0;
\$CFG->debugdisplay = 0;
EOF
        fi

        cat >> /var/www/html/config.php << EOF

require_once(__DIR__ . '/lib/setup.php');
// End of config
EOF

        chown www-data:www-data /var/www/html/config.php
        chmod 644 /var/www/html/config.php
        echo "Moodle configuration created successfully!"
    fi
}

# Function to install Moodle if not already installed
install_moodle() {
    if [ ! -f "/var/www/moodledata/.installed" ]; then
        echo "Installing Moodle..."
        
        # Wait for database
        wait_for_db
        
        # Run Moodle CLI installation
        php /var/www/html/admin/cli/install_database.php \
            --agree-license \
            --adminuser="${MOODLE_ADMIN_USER}" \
            --adminpass="${MOODLE_ADMIN_PASSWORD}" \
            --adminemail="${MOODLE_ADMIN_EMAIL}" \
            --fullname="${MOODLE_FULL_NAME}" \
            --shortname="${MOODLE_SHORT_NAME}"
            
        # Mark as installed
        touch /var/www/moodledata/.installed
        chown moodle:moodle /var/www/moodledata/.installed
        
        echo "Moodle installation completed!"
    else
        echo "Moodle is already installed."
    fi
}

# Main execution
echo "Starting Moodle container initialization..."

# Set default environment variables
export DB_HOST=${DB_HOST:-db}
export DB_PORT=${DB_PORT:-3306}
export DB_NAME=${DB_NAME:-moodle}
export DB_USER=${DB_USER:-moodle}
export DB_PASSWORD=${DB_PASSWORD:-moodle}
export MOODLE_URL=${MOODLE_URL:-http://localhost}
export MOODLE_DATA_PATH=${MOODLE_DATA_PATH:-/var/www/moodledata}
export MOODLE_RELEASE=${MOODLE_RELEASE:-MOODLE_500_STABLE}
export MOODLE_ADMIN_USER=${MOODLE_ADMIN_USER:-admin}
export MOODLE_ADMIN_PASSWORD=${MOODLE_ADMIN_PASSWORD:-Admin123!}
export MOODLE_ADMIN_EMAIL=${MOODLE_ADMIN_EMAIL:-admin@example.com}
export MOODLE_FULL_NAME=${MOODLE_FULL_NAME:-"Moodle Learning Platform"}
export MOODLE_SHORT_NAME=${MOODLE_SHORT_NAME:-Moodle}
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256M}
export PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME:-300}
export PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-100M}
export PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-100M}
export PHP_MAX_INPUT_VARS=${PHP_MAX_INPUT_VARS:-5000}
export TZ=${TZ:-UTC}

# Setup Moodle code first
setup_moodle_code

# Ensure correct permissions
chown -R www-data:www-data /var/www/html
chown -R moodle:moodle /var/www/moodledata
chmod -R 755 /var/www/html
chmod -R 777 /var/www/moodledata

# Substitute environment variables in configuration files
substitute_env_vars

# Create Moodle config
create_moodle_config

# Install Moodle if needed (only on first run)
if [ "$1" = "apache2-foreground" ]; then
    install_moodle > /var/log/moodle-install.log 2>&1 &
fi

echo "Moodle container initialization completed!"

# Execute the main command
exec "$@"