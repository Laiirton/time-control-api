#!/bin/sh

set -e

PORT=${PORT:-10000}
export PORT

if [ -z "$APP_KEY" ]; then
    APP_KEY=$(php -r "echo 'base64:' . base64_encode(random_bytes(32));")
    export APP_KEY
fi

mkdir -p /etc/nginx/conf.d
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

cd /var/www

if [ "${DB_FORCE_IPV4:-true}" = "true" ] && [ -n "$DB_HOST" ]; then
    DB_HOST_IPV4=$(php -r '$host = getenv("DB_HOST"); if (!$host) { exit(0); } $ipv4 = gethostbyname($host); if ($ipv4 !== $host) { echo $ipv4; }')
    if [ -n "$DB_HOST_IPV4" ]; then
        export DB_HOST="$DB_HOST_IPV4"
    fi
fi

php artisan config:cache
php artisan view:cache
php artisan migrate --force

exec /usr/bin/supervisord -c /etc/supervisord.conf
