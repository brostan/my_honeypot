#!/bin/bash
# Backup script for Cowrie logs and downloaded files

set -e

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="cowrie_backup_$TIMESTAMP"
COWRIE_DIR="cowrie"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Cowrie Backup Script ===${NC}\n"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_NAME"

# Create temporary directory for backup
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/$BACKUP_NAME"

# Copy logs
echo "Backing up logs..."
if [ -d "$COWRIE_DIR/var/log" ]; then
    cp -r "$COWRIE_DIR/var/log" "$TEMP_DIR/$BACKUP_NAME/"
fi

# Copy downloaded files
echo "Backing up downloaded files..."
if [ -d "$COWRIE_DIR/var/lib/cowrie/downloads" ]; then
    cp -r "$COWRIE_DIR/var/lib/cowrie/downloads" "$TEMP_DIR/$BACKUP_NAME/"
fi

# Copy TTY logs (session recordings)
echo "Backing up TTY logs..."
if [ -d "$COWRIE_DIR/var/lib/cowrie/tty" ]; then
    cp -r "$COWRIE_DIR/var/lib/cowrie/tty" "$TEMP_DIR/$BACKUP_NAME/"
fi

# Copy configuration
echo "Backing up configuration..."
if [ -f "$COWRIE_DIR/etc/cowrie.cfg" ]; then
    mkdir -p "$TEMP_DIR/$BACKUP_NAME/etc"
    cp "$COWRIE_DIR/etc/cowrie.cfg" "$TEMP_DIR/$BACKUP_NAME/etc/"
fi
if [ -f "$COWRIE_DIR/etc/userdb.txt" ]; then
    cp "$COWRIE_DIR/etc/userdb.txt" "$TEMP_DIR/$BACKUP_NAME/etc/"
fi

# Create compressed archive
echo "Compressing backup..."
cd "$TEMP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
cd - > /dev/null

# Move to backup directory
mv "$TEMP_DIR/$BACKUP_NAME.tar.gz" "$BACKUP_DIR/"

# Cleanup
rm -rf "$TEMP_DIR"

# Calculate size
SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)

echo -e "\n${GREEN}Backup completed successfully!${NC}"
echo "Location: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "Size: $SIZE"

# Optional: Remove old backups (keep last 7 days)
echo -e "\n${YELLOW}Cleaning old backups (keeping last 7 days)...${NC}"
find "$BACKUP_DIR" -name "cowrie_backup_*.tar.gz" -mtime +7 -delete
echo "Cleanup complete"

# List all backups
echo -e "\nAvailable backups:"
ls -lh "$BACKUP_DIR"/cowrie_backup_*.tar.gz 2>/dev/null || echo "No backups found"

