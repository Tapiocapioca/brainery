# Brainery Containers Reference

Complete infrastructure reference for Docker containers, troubleshooting, and system requirements.

## Container Architecture

```
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ MCP Tools
       ├────────┬────────┬────────┐
       ▼        ▼        ▼        ▼
  ┌─────────┐┌───────┐┌────────┐┌──────────┐
  │crawl4ai ││yt-dlp ││whisper ││anythingllm│
  │  :9100  ││ :9101 ││ :9102  ││  :9103    │
  └─────────┘└───────┘└────────┘└──────────┘
   Web scrape YouTube  Audio     RAG DB
               transc.  transc.
```

## Container Specifications

### crawl4ai
- **Image:** `tapiocapioca/crawl4ai:latest`
- **Container:** `brainery-crawl4ai-1`
- **Port:** 9100 (configurable: `CRAWL4AI_PORT`)
- **Internal:** 11235
- **Purpose:** Web page text extraction
- **Volume:** tmpfs (512MB RAM, ephemeral)
- **Health:** `http://localhost:9100/health`

### yt-dlp-server
- **Image:** `tapiocapioca/yt-dlp-server:latest`
- **Container:** `brainery-yt-dlp-server-1`
- **Port:** 9101 (configurable: `YTDLP_PORT`)
- **Internal:** 8501
- **Purpose:** YouTube transcript extraction
- **Volume:** tmpfs (1GB RAM, ephemeral)
- **Health:** `http://localhost:9101/health`

### whisper-server
- **Image:** `tapiocapioca/whisper-server:latest`
- **Container:** `brainery-whisper-server-1`
- **Port:** 9102 (configurable: `WHISPER_PORT`)
- **Internal:** 8502
- **Purpose:** Audio transcription
- **Volume:** `whisper-models` (persistent, ~3GB)
- **Health:** `http://localhost:9102/health`

### anythingllm
- **Image:** `tapiocapioca/anythingllm:latest`
- **Container:** `brainery-anythingllm-1`
- **Port:** 9103 (configurable: `ANYTHINGLLM_PORT`)
- **Internal:** 3001
- **Purpose:** Local RAG database
- **Volume:** `anythingllm-storage` (persistent)
- **Health:** `http://localhost:9103/api/ping`

## System Requirements

### Minimum
- **Docker Desktop:** 20.10+
- **RAM:** 8GB minimum
- **Disk:** ~13GB
  - Container images: ~6GB
  - Whisper models: ~3GB
  - Data volumes: ~4GB
- **OS:** Windows 10/11 (WSL 2), macOS 10.15+, Linux (kernel 3.10+)

### Recommended
- **RAM:** 12GB
- **Disk:** ~20GB (with buffer for data growth)
- **CPU:** 4+ cores (for Whisper performance)

### Breakdown

| Component | Disk Space | RAM Usage |
|-----------|------------|-----------|
| crawl4ai | ~2GB | ~512MB |
| yt-dlp-server | ~1GB | ~256MB |
| whisper-server | ~3GB | ~2GB |
| anythingllm | ~1GB | ~1GB |
| Data volumes | ~6GB | - |
| **TOTAL** | **~13GB** | **~4GB** |

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
```

### Step 2: Start Containers

```bash
docker-compose up -d
```

**First startup:** 2-5 minutes to download images and initialize.

### Step 3: Verify

```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Expected output:
```
NAMES                     STATUS          PORTS
brainery-anythingllm-1    Up 2 minutes    0.0.0.0:9103->3001/tcp
brainery-whisper-server-1 Up 2 minutes    0.0.0.0:9102->8502/tcp
brainery-yt-dlp-server-1  Up 2 minutes    0.0.0.0:9101->8501/tcp
brainery-crawl4ai-1       Up 2 minutes    0.0.0.0:9100->11235/tcp
```

### Step 4: Test Health Endpoints

```bash
curl http://localhost:9100/health   # crawl4ai
curl http://localhost:9101/health   # yt-dlp-server
curl http://localhost:9102/health   # whisper-server
curl http://localhost:9103/api/ping # anythingllm
```

All should return success responses.

## Configuration

### Environment Variables

Create `.env` file (copy from `.env.example`):

```bash
# Container Ports
CRAWL4AI_PORT=9100
YTDLP_PORT=9101
WHISPER_PORT=9102
ANYTHINGLLM_PORT=9103

# AnythingLLM API Key (get from web UI)
ANYTHINGLLM_API_KEY=your-api-key-here
```

### Custom Ports

Edit `.env` file:
```bash
CRAWL4AI_PORT=9200
YTDLP_PORT=9201
WHISPER_PORT=9202
ANYTHINGLLM_PORT=9203
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

## Troubleshooting

### Containers Not Starting

**Issue:** `docker-compose up -d` fails

**Diagnosis:**
```bash
docker-compose logs <service-name>
```

**Common causes:**
1. **Docker Desktop not running**
   - Start Docker Desktop
   - Wait for "Docker Desktop is running"

2. **Port conflicts** (9100-9103 already in use)
   - Find process using port: `netstat -ano | findstr :9100` (Windows)
   - Kill process or change port in `.env`

3. **Insufficient disk space**
   - Check: `docker system df`
   - Clean: `docker system prune -a`

### Container Exits Immediately

**Issue:** Container status "Exited (1)"

**Diagnosis:**
```bash
docker logs <container-name>
```

**Solutions:**
- Read error message in logs
- Check volume permissions
- Verify image pulled successfully: `docker images | grep brainery`

### Port Already Allocated

**Error:** `bind: address already in use`

**Solution 1: Find conflicting process**
```bash
# Windows
netstat -ano | findstr :9100

# Linux/Mac
lsof -i :9100
```

Kill process or change port.

**Solution 2: Change port**
Edit `.env`:
```bash
CRAWL4AI_PORT=9200  # Use different port
```

### Health Check Failing

**Issue:** Container running but health check fails

**Diagnosis:**
```bash
docker inspect <container-name> | grep -A 10 Health
```

**Solutions:**
1. Wait 30-60 seconds (health checks have retry logic)
2. Check container logs: `docker logs <container-name>`
3. Test endpoint manually: `curl http://localhost:PORT/health`
4. Restart container: `docker-compose restart <service-name>`

### AnythingLLM "Unauthorized"

**Issue:** API calls return 401 error

**Solution:**
1. Get API key from web UI:
   - Open http://localhost:9103
   - Settings → API Keys → Generate New API Key
   - Copy key

2. Update `.env`:
   ```bash
   ANYTHINGLLM_API_KEY=your-new-key
   ```

3. Initialize MCP client:
   ```
   mcp__anythingllm__initialize_anythingllm
     apiKey: "your-new-key"
     baseUrl: "http://localhost:9103"
   ```

### Whisper Model Not Downloading

**Issue:** First transcription fails or hangs

**Diagnosis:**
```bash
docker logs brainery-whisper-server-1 | grep -i download
```

**Solution:**
Models auto-download on first use. Wait 2-3 minutes.

**Manual check:**
```bash
docker exec brainery-whisper-server-1 ls /app/models
```

Should show model files after download completes.

### Out of Memory Errors

**Issue:** Container crashes with OOM errors

**Solutions:**
1. **Increase Docker memory limit**
   - Docker Desktop → Settings → Resources
   - Increase memory to 12GB+

2. **Restart containers**
   ```bash
   docker-compose restart
   ```

3. **Use smaller Whisper model**
   - Change from `medium`/`large` to `base` or `tiny`

### Slow Performance

**Issue:** Operations taking too long

**Diagnosis:**
```bash
docker stats
```

**Solutions:**
1. **CPU-bound (Whisper transcription)**
   - Use faster model (`tiny` instead of `large`)
   - Increase CPU allocation in Docker Desktop

2. **Network-bound (crawl4ai, yt-dlp)**
   - Check internet connection
   - Try different content source

3. **Disk I/O bound**
   - Check disk usage: `docker system df`
   - Prune unused data: `docker system prune`

### Container Won't Stop

**Issue:** `docker-compose down` hangs

**Solution:**
```bash
# Force stop
docker-compose down -t 0

# If still hanging, force kill
docker kill $(docker ps -q --filter "name=brainery-")
```

## Maintenance

### Update Containers

```bash
cd brainery-containers
docker-compose pull
docker-compose up -d
```

### View Logs

```bash
# All containers
docker-compose logs -f

# Specific container
docker-compose logs -f <service-name>

# Last 100 lines
docker-compose logs --tail=100 <service-name>
```

### Restart Containers

```bash
# All containers
docker-compose restart

# Specific container
docker-compose restart <service-name>
```

### Stop Containers

```bash
# Stop (preserves data)
docker-compose stop

# Stop and remove (preserves volumes)
docker-compose down

# Stop, remove, and DELETE volumes (⚠️ loses RAG data)
docker-compose down -v
```

### Backup Data

**Backup AnythingLLM storage:**
```bash
docker cp brainery-anythingllm-1:/app/server/storage ~/brainery-backup/anythingllm-$(date +%Y%m%d)
```

**Backup Whisper models:**
```bash
docker run --rm -v whisper-models:/data \
  -v ~/brainery-backup:/backup \
  alpine tar czf /backup/whisper-models-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore Data

**Restore AnythingLLM storage:**
```bash
docker-compose stop anythingllm
docker cp ~/brainery-backup/anythingllm-20260107 brainery-anythingllm-1:/app/server/storage
docker-compose start anythingllm
```

**Restore Whisper models:**
```bash
docker run --rm -v whisper-models:/data \
  -v ~/brainery-backup:/backup \
  alpine tar xzf /backup/whisper-models-20260107.tar.gz -C /data
```

## Uninstallation

### Remove Containers Only (Keep Data)

```bash
docker-compose down
```

**Data preserved:**
- `anythingllm-storage` volume (RAG database)
- `whisper-models` volume (downloaded models)

### Remove Everything (Including Data)

⚠️ **WARNING:** This deletes all imported content from RAG database.

```bash
docker-compose down -v
```

### Remove Images

```bash
docker rmi tapiocapioca/crawl4ai:latest
docker rmi tapiocapioca/yt-dlp-server:latest
docker rmi tapiocapioca/whisper-server:latest
docker rmi tapiocapioca/anythingllm:latest
```

## Advanced Configuration

### Custom Docker Compose

Edit `docker-compose.yml` for advanced configurations:

**Example: Limit memory usage**
```yaml
services:
  whisper-server:
    # ... existing config ...
    deploy:
      resources:
        limits:
          memory: 4G
```

**Example: Add environment variable**
```yaml
services:
  anythingllm:
    # ... existing config ...
    environment:
      - STORAGE_DIR=/app/server/storage
      - LOG_LEVEL=debug  # Add custom env var
```

### Network Configuration

Default: All containers in `brainery-containers_default` network.

**Check network:**
```bash
docker network inspect brainery-containers_default
```

### Volume Management

**List volumes:**
```bash
docker volume ls | grep brainery
```

**Inspect volume:**
```bash
docker volume inspect anythingllm-storage
```

**Check volume size:**
```bash
docker system df -v | grep -A 5 "Local Volumes"
```

## Security Considerations

### Container Isolation

- Containers run isolated from host
- No direct host filesystem access (except volumes)
- Network isolated by default

### Ports

- Ports 9100-9103 exposed only on localhost
- Not accessible from external network
- Use firewall if exposing externally (not recommended)

### API Keys

- AnythingLLM API key stored in `.env`
- `.env` should be in `.gitignore`
- Never commit API keys to git

### Updates

- Regularly update container images: `docker-compose pull`
- Monitor security advisories for base images
- Keep Docker Desktop updated

## Performance Tuning

### Docker Desktop Settings

**Recommended:**
- **CPUs:** 4-6 cores
- **Memory:** 12GB
- **Disk:** 20GB+ (dynamic allocation)
- **Swap:** 2GB

### Container-Specific Tuning

**Whisper (CPU-intensive):**
- Use `base` model for balance
- Use `tiny` for speed
- Increase CPU allocation in Docker Desktop

**AnythingLLM (Memory-intensive):**
- Increase Docker memory limit
- Monitor with `docker stats`

**crawl4ai (Network-bound):**
- Minimal tuning needed
- Performance depends on target website

## Monitoring

### Real-time stats

```bash
docker stats
```

Shows CPU, memory, network, disk I/O for all containers.

### Health check status

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Disk usage

```bash
docker system df
```

Shows disk usage by images, containers, volumes.

### Detailed inspection

```bash
docker inspect <container-name>
```

Returns full container configuration and state.

## Support

**Issues with containers:**
- Repository: https://github.com/Tapiocapioca/brainery-containers
- Issues: https://github.com/Tapiocapioca/brainery-containers/issues

**Issues with skill:**
- Repository: https://github.com/Tapiocapioca/brainery
- Issues: https://github.com/Tapiocapioca/brainery/issues
