#!/bin/bash
set -e

# Timestamp
BACKUP_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="mongo_backup_$BACKUP_TIME"
BACKUP_DIR="/tmp/$BACKUP_NAME"

echo "[INFO] Starting backup at $BACKUP_TIME"

# Run mongodump from any available secondary
mongodump \
  --uri="$MONGO_URI" \
  --readPreference=secondaryPreferred \
  --out="$BACKUP_DIR"

echo "[INFO] Backup completed. Uploading to S3..."

# Compress
tar -czf "$BACKUP_DIR.tar.gz" -C /tmp "$BACKUP_NAME"

Upload to S3 (ensure AWS CLI is installed)
aws s3 cp "$BACKUP_DIR.tar.gz" "s3://$S3_BUCKET/mongo_backups/$BACKUP_NAME.tar.gz"

Cleanup
rm -rf "$BACKUP_DIR" "$BACKUP_DIR.tar.gz"

echo "[INFO] Backup uploaded and cleaned up successfully."