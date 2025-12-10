#!/bin/bash

echo "Preparing universal backup script..."

SCRIPT="/root/manual-backup-transfer.sh"

# Create the universal backup script fresh each time
cat << 'EOF' > $SCRIPT
#!/bin/bash

##########################################################
# Universal Backup Transfer Script (Dynamic + Safe)
# No setup needed — works on ANY server automatically
##########################################################

# Detect latest real backup folder (YYYY-MM-DD only)
LATEST_BACKUP=$(basename $(ls -d /backup/20* 2>/dev/null | sort -r | head -n 1))

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup folder found matching /backup/20*"
    exit 1
fi

BACKUP_PATH="/backup/$LATEST_BACKUP"

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
    echo "ERROR: This server hostname '$HOST' is not in bucket map."
    echo "Add it inside MAP[] in this script."
    exit 1
fi

REMOTE="ImranBoss:$SERVER_BUCKET"
LOG_FILE="/root/rclone-$LATEST_BACKUP.log"

echo "==========================================="
echo " Backup Folder: $BACKUP_PATH"
echo " Upload Target: $REMOTE/$LATEST_BACKUP"
echo " Log File:      $LOG_FILE"
echo "==========================================="

# Upload and track progress
rclone copy "$BACKUP_PATH" "$REMOTE/$LATEST_BACKUP" \
  --progress --stats=10s --stats-one-line \
  > "$LOG_FILE" 2>&1

# Delete only after success
if [ $? -eq 0 ]; then
    echo "Upload SUCCESS. Deleting local backup..."
    rm -rf "$BACKUP_PATH"
    echo "Backup deleted successfully."
else
    echo "Upload FAILED. Backup NOT deleted."
    echo "See log: $LOG_FILE"
    exit 1
fi

EOF

chmod +x $SCRIPT

echo "Running backup now..."
bash $SCRIPT
