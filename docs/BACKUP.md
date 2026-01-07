# Backup and Restore Procedures

Guide for backing up and restoring Brainery persistent data.

## What Needs Backup

### 1. AnythingLLM Storage
- **Location:** Docker volume `anythingllm-storage`
- **Contains:** RAG database, embedded documents, workspace configuration
- **Size:** Varies (grows with imported content)

### 2. Whisper Models
- **Location:** Docker volume `whisper-models`
- **Contains:** Downloaded Whisper model files (tiny, base, small, medium, large)
- **Size:** ~3GB (if all models downloaded)

## Backup Procedures

### Manual Backup

**Backup AnythingLLM storage:**
```bash
docker run --rm \
  -v anythingllm-storage:/data \
  -v ~/brainery-backups:/backup \
  alpine tar czf /backup/anythingllm-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

**Backup Whisper models:**
```bash
docker run --rm \
  -v whisper-models:/data \
  -v ~/brainery-backups:/backup \
  alpine tar czf /backup/whisper-models-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

### Automated Backup Script

Create `backup-brainery.sh`:

```bash
#!/bin/bash
BACKUP_DIR=~/brainery-backups
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Backing up AnythingLLM storage..."
docker run --rm \
  -v anythingllm-storage:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/anythingllm-$DATE.tar.gz -C /data .

echo "Backing up Whisper models..."
docker run --rm \
  -v whisper-models:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/whisper-models-$DATE.tar.gz -C /data .

echo "Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
```

**Setup cron job (Linux/Mac):**
```bash
chmod +x backup-brainery.sh
crontab -e
# Add: 0 2 * * * /path/to/backup-brainery.sh
```

## Restore Procedures

### Restore AnythingLLM Storage

```bash
# Stop container first
docker-compose stop anythingllm

# Restore backup
docker run --rm \
  -v anythingllm-storage:/data \
  -v ~/brainery-backups:/backup \
  alpine tar xzf /backup/anythingllm-20260107-143000.tar.gz -C /data

# Restart container
docker-compose start anythingllm
```

### Restore Whisper Models

```bash
# No need to stop containers for model restore
docker run --rm \
  -v whisper-models:/data \
  -v ~/brainery-backups:/backup \
  alpine tar xzf /backup/whisper-models-20260107-143000.tar.gz -C /data
```

## Best Practices

1. **Backup frequency:**
   - AnythingLLM: Daily if actively importing content
   - Whisper models: Once after all models downloaded

2. **Retention:**
   - Keep last 7 daily backups
   - Keep last 4 weekly backups
   - Keep last 12 monthly backups

3. **Testing:**
   - Test restore procedure monthly
   - Verify backup integrity with `tar -tzf backup.tar.gz`

4. **Off-site backup:**
   - Copy backups to external drive or cloud storage
   - Use encryption for sensitive content
