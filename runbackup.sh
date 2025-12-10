#!/bin/bash

echo "Preparing universal backup script..."

SCRIPT="/root/manual-backup-transfer.sh"

cat << 'EOF' > $SCRIPT
#!/bin/bash

############################################################
# Multi-Folder Backup Transfer (Background + Live Progress)
############################################################

# Find all date-format backup folders
BACKUP_FOLDERS=$(ls -d /backup/20* 2>/dev/null | sort)

if [ -z "$BACKUP_FOLDERS" ]; then
    echo "No backup folders found in /backup"
    exit 1
fi

# Detect hostname
HOST=$(hostname | cut -d. -f1)

# Bucket mapping
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
    echo "ERROR: Unknown server hostname: $HOST"
    exit 1
fi

REMOTE="ImranBoss:$SERVER_BUCKET"

echo "=============================================="
echo "Server: $HOST"
echo "Bucket: $REMOTE"
echo "Folders to upload:"
echo "$BACKUP_FOLDERS"
echo "=============================================="

# Main loop
for FOLDER in $BACKUP_FOLDERS; do
    NAME=$(basename "$FOLDER")
    LOG_FILE="/root/rclone-$NAME.log"

    echo ""
    echo "----------------------------------------------"
    echo "Starting upload of: $NAME"
    echo "Log file: $LOG_FILE"
    echo "----------------------------------------------"

    # Run upload in background and store PID
    nohup rclone copy "$FOLDER" "$REMOTE/$NAME" \
        --progress --stats=10s --stats-one-line \
        > "$LOG_FILE" 2>&1 &

    PID=$!
    echo "Upload started in background (PID: $PID)"
    echo "Check progress anytime with:"
    echo "  tail -f $LOG_FILE"

    # Wait for this upload to finish before starting next
    wait $PID
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "SUCCESS: $NAME uploaded. Deleting local folder..."
        rm -rf "$FOLDER"
    else
        echo "FAILED: $NAME upload failed."
        echo "NOT deleting $FOLDER"
        echo "Stopping further uploads to prevent data loss."
        exit 1
    fi
done

echo ""
echo "=============================================="
echo "ALL BACKUPS UPLOADED SUCCESSFULLY!"
echo "=============================================="
EOF

chmod +x $SCRIPT

echo "Running backup in background..."
nohup bash $SCRIPT > /root/multi-backup-master.log 2>&1 &

echo ""
echo "Backup started!"
echo "Master process log:"
echo "  tail -f /root/multi-backup-master.log"
echo ""
echo "Individual folder logs will appear as:"
echo "  /root/rclone-<foldername>.log"
echo ""
echo "You can close this terminal safely."
