#!/bin/bash

echo "Preparing universal backup script..."

SCRIPT="/root/manual-backup-transfer.sh"

# Create the universal backup script fresh each time
cat << 'EOF' > $SCRIPT
#!/bin/bash

##########################################################
# Universal Backup Transfer Script (Multi-Folder Safe)
# Uploads ALL backup folders (YYYY-MM-DD) one-by-one
# Deletes only after successful upload
##########################################################

# Detect all backup folder names matching /backup/YYYY-MM-DD
BACKUP_FOLDERS=$(ls -d /backup/20* 2>/dev/null | sort)

if [ -z "$BACKUP_FOLDERS" ]; then
    echo "ERROR: No backup folders found in /backup"
    exit 1
fi

# Detect hostname
HOST=$(hostname | cut -d. -f1)

# Map hostname → bucket
declare -A MAP=(
  ["nebula"]="Nebula-Screative"
  ["apollo"]="Apollo-Screative"
  ["aurora"]="Aurora-Screative"
  ["flux"]="Flux-Screative"
  ["ignite"]="Ignite-Screative"
  ["hostnin"]="Hostnin-Screative"
)

SERVER_BUCKET=${MAP[$HOST]}

if [ -z "$SERVER_BUCKET" ]; then
    echo "ERROR: Unknown hostname: $HOST"
    exit 1
fi

REMOTE="ImranBoss:$SERVER_BUCKET"

echo "==========================================="
echo " Uploading All Backups for Server: $HOST"
echo " Bucket: $REMOTE"
echo "==========================================="

# Loop through each backup folder
for FOLDER in $BACKUP_FOLDERS; do
    NAME=$(basename "$FOLDER")
    LOG_FILE="/root/rclone-$NAME.log"

    echo ""
    echo "-------------------------------------------"
    echo " Uploading Backup Folder: $FOLDER"
    echo " Log File: $LOG_FILE"
    echo "-------------------------------------------"

    # Upload folder
    rclone copy "$FOLDER" "$REMOTE/$NAME" \
      --progress --stats=10s --stats-one-line \
      > "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "SUCCESS: $NAME uploaded. Deleting folder..."
        rm -rf "$FOLDER"
    else
        echo "FAILED: $NAME upload failed!"
        echo "Backup NOT deleted. Check log: $LOG_FILE"
        echo "Stopping further uploads to prevent data loss."
        exit 1
    fi
done

echo ""
echo "==========================================="
echo "All backups uploaded and deleted successfully!"
echo "==========================================="

EOF

chmod +x $SCRIPT

echo "Running backup now..."
bash $SCRIPT
