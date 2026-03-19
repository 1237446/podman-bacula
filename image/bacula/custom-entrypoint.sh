#!/usr/bin/env bash
set -e

# Cargamos funciones por defecto si existen
. /docker-entrypoint.inc || true

# 1. Anular inicialización de DB interna
function init_bacula() {
    echo "--> SALTAR: Inicialización de catálogo interno omitida."
}

# 2. Arrancar el binario directamente
function start_bacula_dir() {
    echo "--> INICIANDO BACULA DIRECTOR..."
    /usr/sbin/bacula-dir -c /etc/bacula/bacula-dir.conf
    sleep 2
    if pgrep bacula-dir > /dev/null; then
       echo "--> ÉXITO: Bacula Director está corriendo."
    else
       echo "--> ERROR: Bacula Director falló."
       exit 1
    fi
}

function start() {
    echo "--> Iniciando secuencia personalizada..."
    start_bacula_dir
    echo "--> Iniciando PHP-FPM..."
    # Usamos la versión de PHP que instalamos (84)
    php-fpm84
}

start

echo "--> Arrancando Nginx..."
exec "$@"
