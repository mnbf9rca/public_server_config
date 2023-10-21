#!/bin/bash

# Variables
# assumes database is called tsdb
BACKUP_DIR="/backup"
DATE_SUFFIX=$(date +%F)
BACKUP_FILE="$BACKUP_DIR/tsdb_backup_$DATE_SUFFIX.sql"
ZIP_FILE="$BACKUP_DIR/tsdb_backup_$DATE_SUFFIX.zip"
LOG_FILE="$BACKUP_DIR/tsdb_backup_log_$DATE_SUFFIX.txt"
S3_BUCKET="s3://bucket"
HEALTHCHECK_URL="https://hc-ping.com/slug"
PG_BACKUP_USER="backup_user"
PG_PORT="<port>"
RETAIN_BACKUPS_AWS=7  # Number of backups to retain in AWS
RETAIN_BACKUPS_LOCAL=1 # Number of backups to retain locally

# Redirect all output to log file
exec > "$LOG_FILE" 2>&1

# Function to send log to healthchecks.io
send_log() {
    local url="$1"
    curl -fsS --retry 3 -m 10 -X POST -H "Content-Type: text/plain" --data-binary "@$LOG_FILE" "$url"
}

# Check Database Integrity
pg_dump -U $PG_BACKUP_USER -h localhost -p $PG_PORT tsdb -f "$BACKUP_FILE" || {
    send_log "$HEALTHCHECK_URL/fail"
    exit 1
}

zip -9 "$ZIP_FILE" "$BACKUP_FILE" || {
    send_log "$HEALTHCHECK_URL/fail"
    exit 1
}

# Delete all but the most recent $RETAIN_BACKUPS_LOCAL backups and logs in BACKUP_DIR
find "$BACKUP_DIR" -type f -name 'tsdb_backup_*.sql' | sort | head -n -"$RETAIN_BACKUPS_LOCAL" | xargs rm -f
find "$BACKUP_DIR" -type f -name 'tsdb_backup_*.zip' | sort | head -n -"$RETAIN_BACKUPS_LOCAL" | xargs rm -f
find "$BACKUP_DIR" -type f -name 'tsdb_backup_log_*.txt' | sort | head -n -"$RETAIN_BACKUPS_LOCAL" | xargs rm -f

# Upload to AWS S3
aws s3 cp "$ZIP_FILE" "$S3_BUCKET" --no-progress || {
    send_log "$HEALTHCHECK_URL/fail"
    exit 1
}

# Manage Retention
aws s3 ls "$S3_BUCKET" | sort | head -n -"$RETAIN_BACKUPS_AWS" | awk '{print $4}' | xargs -I {} aws s3 rm "$S3_BUCKET"/{} || {
    send_log "$HEALTHCHECK_URL/fail"
    exit 1
}

# Notify healthchecks.io and send log
send_log "$HEALTHCHECK_URL"
