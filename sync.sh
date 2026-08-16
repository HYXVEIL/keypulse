#!/bin/sh

set -u

CONFIG="/etc/keypulse/config"
PASSWORD_FILE="/etc/keypulse/sftp_password"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config not found: $CONFIG"
    exit 1
fi

if [ ! -f "$PASSWORD_FILE" ]; then
    echo "ERROR: Password file not found: $PASSWORD_FILE"
    exit 1
fi

. "$CONFIG"

SFTP_PASSWORD="$(cat "$PASSWORD_FILE")"

mkdir -p "$LOCAL_DIR"

while true; do

    echo "Starting synchronization..."

    TMP_DIR="$(mktemp -d)"

    SUCCESS=1

    for FILE in $FILES; do
        echo "Downloading: $FILE"

sshpass -p "$SFTP_PASSWORD" sftp \
    -P "$SFTP_PORT" \
    -o StrictHostKeyChecking=no \
    "$SFTP_USER@$SFTP_HOST" <<EOF >/dev/null 2>&1
get "$REMOTE_DIR/$FILE" "$TMP_DIR/$FILE"
bye
EOF
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to download $FILE"
            SUCCESS=0
            break
        fi
    done

if [ "$SUCCESS" -eq 1 ]; then
    for FILE in $FILES; do
        mv "$TMP_DIR/$FILE" "$LOCAL_DIR/$FILE"
    done

    echo "OK: Files synchronized"

    if [ "$RELOAD_NGINX" = "true" ]; then
        echo "Reloading nginx..."
        systemctl reload nginx
    fi

    if [ "$RELOAD_CADDY" = "true" ]; then
        echo "Reloading caddy..."
        systemctl reload caddy
    fi

    if [ "$RELOAD_OPENRESTY" = "true" ]; then
        echo "Reloading openresty..."
        systemctl reload openresty
    fi
else
    echo "ERROR: Synchronization failed"
fi
    rm -rf "$TMP_DIR"

    echo "Next synchronization in ${SYNC_INTERVAL}s..."

    sleep "$SYNC_INTERVAL"

done
