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

php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan migrate --force

exec /usr/bin/supervisord -c /etc/supervisord.conf
