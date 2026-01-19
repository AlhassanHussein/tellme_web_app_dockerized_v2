#!/bin/bash

# Backup SQLite database
# Creates timestamped backup in backups/ directory

set -e

# Create backups directory
mkdir -p backups

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="backups/database_backup_${TIMESTAMP}.db"

echo "=== Database Backup ==="
echo "Backing up database..."

# Copy database from Docker volume
docker-compose exec -T backend cat /app/data/database.db > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    # Get file size
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    
    echo "✓ Backup completed successfully!"
    echo "File: $BACKUP_FILE"
    echo "Size: $SIZE"
    echo ""
    
    # Keep only last 10 backups
    echo "Cleaning old backups (keeping last 10)..."
    ls -t backups/database_backup_*.db | tail -n +11 | xargs -r rm
    
    echo "Done!"
else
    echo "✗ Backup failed!"
    rm -f "$BACKUP_FILE"
    exit 1
fi
