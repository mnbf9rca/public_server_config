#!/bin/bash

# see https://blog.cynexia.com/use-barman-to-back-up-postgresql-to-azure-blob/

# Variables
BACKUP_DIR="/var/lib/postgresql/backup"
DATE_SUFFIX=$(date +%F_%H-%M-%S)
LOG_FILE="$BACKUP_DIR/barman_backup_log_$DATE_SUFFIX.txt"
AZURE_CONTAINER="azure://<container>.blob.core.windows.net/backup"  # Replace with your Azure Blob Storage container URL
HEALTHCHECK_URL="https://hc-ping.com/<slug>"
SERVER_NAME="pg"
RETENTION_POLICY="RECOVERY WINDOW OF 30 DAYS"  # Adjust the retention policy as needed
RETAIN_LOG_DAYS=7

# create backup temp dir if it doesnt exist
mkdir -p $BACKUP_DIR

# Redirect all output to log file
exec > "$LOG_FILE" 2>&1

# Function to send log to healthchecks.io
send_log() {
    local url="$1"
    curl -fsS --retry 3 -m 10 -X POST -H "Content-Type: text/plain" --data-binary "@$LOG_FILE" "$url"
}

# Perform backup with Barman
# dont use verbose (-v) as output will be too long for healthchecks.io
barman-cloud-backup --cloud-provider azure-blob-storage --azure-credential=managed-identity --snappy -p 31432 -d postgres  "$AZURE_CONTAINER" "$SERVER_NAME" || {
    send_log "$HEALTHCHECK_URL/fail"
    exit 1
}

# Delete old backups according to retention policy
barman-cloud-backup-delete --cloud-provider azure-blob-storage --retention-policy "$RETENTION_POLICY" "$AZURE_CONTAINER" "$SERVER_NAME" || {
    send_log "$HEALTHCHECK_URL/fail"
    exit 1
}

# Notify healthchecks.io of success and send log
send_log "$HEALTHCHECK_URL"

# Finally, delete old log files in BACKUP_DIR
find "$BACKUP_DIR" -type f -name 'barman_backup_log_*.txt' -mtime +$RETAIN_LOG_DAYS -exec rm -f {} \;