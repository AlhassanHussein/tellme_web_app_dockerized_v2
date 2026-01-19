#!/bin/bash

# Restore SQLite database from backup
# Usage: ./restore-db.sh <backup_file>

set -e

if [ -z "$1" ]; then
    echo "Usage: ./restore-db.sh <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh backups/database_backup_*.db 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "=== Database Restore ==="
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "This will REPLACE the current database. Continue? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

echo "Stopping backend container..."
docker-compose stop backend

echo "Restoring database..."
docker-compose run --rm -v $(pwd)/$BACKUP_FILE:/backup.db backend sh -c "cp /backup.db /app/data/database.db"

if [ $? -eq 0 ]; then
    echo "✓ Database restored successfully!"
    echo ""
    echo "Starting backend container..."
    docker-compose start backend
    echo "Done!"
else
    echo "✗ Restore failed!"
    docker-compose start backend
    exit 1
fi
