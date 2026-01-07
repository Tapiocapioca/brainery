# Installation Guide

Complete setup instructions for Brainery skill and containers.

## Prerequisites

- **Docker Desktop** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **Git** for cloning repositories
- **8GB RAM minimum** (12GB recommended)
- **~13GB disk space** for containers and models

### Windows-Specific
- Docker Desktop with WSL 2 backend enabled
- Git Bash or PowerShell

### Linux/macOS
- Docker and Docker Compose installed via package manager

## Step 1: Install Docker Containers

Clone the brainery-containers repository:

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
```

Start all containers:

```bash
docker-compose up -d
```

This will pull pre-built images from Docker Hub:
- `tapiocapioca/crawl4ai:latest`
- `tapiocapioca/yt-dlp-server:latest`
- `tapiocapioca/whisper-server:latest`
- `tapiocapioca/anythingllm:latest`

**First startup takes 2-5 minutes** to download images and initialize.

## Step 2: Verify Containers

Check all containers are running:

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

Test health endpoints:

```bash
curl http://localhost:9100/health   # crawl4ai
curl http://localhost:9101/health   # yt-dlp-server
curl http://localhost:9102/health   # whisper-server
curl http://localhost:9103/api/ping # anythingllm
```

All should return `{"status":"ok"}` or similar success response.

## Step 3: Configure AnythingLLM

Open AnythingLLM web interface:

```
http://localhost:9103
```

### First-Time Setup

1. **Create Admin Account**
   - Username: your choice
   - Password: your choice (saved locally)

2. **Configure LLM Provider**
   - Navigate to: Settings → LLM Preference
   - Select provider with free tier (recommended: **iFlow Platform**)
   - Add API credentials

#### iFlow Platform Setup (Recommended)

1. Register at: https://iflow.cn/oauth?redirect=https%3A%2F%2Fvibex.iflow.cn%2Fsession%2Fsso_login
2. Get API key from dashboard
3. In AnythingLLM:
   - Provider: `OpenAI Compatible`
   - Base URL: `https://vibex.iflow.cn/v1`
   - Model: `glm-4.6`
   - API Key: `<your-key>`

**Model benefits:**
- Free tier: 200K context tokens
- Good multilingual support (EN/IT/ZH)
- Fast response times

3. **Create Workspace**
   - Click "New Workspace"
   - Name: `brainery` (or your preference)
   - Save workspace slug for later use

4. **Get API Key**
   - Navigate to: Settings → API Keys
   - Click "Generate New API Key"
   - Copy the key

5. **Save API Key to Environment**

Edit `.env` file in `brainery-containers` directory:

```bash
ANYTHINGLLM_API_KEY=your-api-key-here
```

Or add to your Claude Code CLAUDE.md:

```markdown
## AnythingLLM Configuration

API Key: your-api-key-here
Workspace: brainery
```

## Step 4: Install Brainery Skill

### Option A: Manual Installation

1. Clone the brainery skill repository:

```bash
cd ~/.claude/skills  # or your skills directory
git clone https://github.com/Tapiocapioca/brainery.git
```

2. Restart Claude Code to load the skill

### Option B: Via Claude Code Plugin System

In Claude Code, run:

```
/install-skill https://github.com/Tapiocapioca/brainery
```

## Step 5: Verify Installation

Test the complete workflow in Claude Code:

1. **Import a web page:**
   ```
   Import this article into Brainery: https://example.com/article
   ```

2. **Query the content:**
   ```
   What are the main points in the article I just imported?
   ```

If both work, installation is complete!

## Troubleshooting

### Containers Not Starting

**Issue:** `docker-compose up -d` fails

**Solution:**
1. Check Docker Desktop is running
2. Ensure no port conflicts (9100-9103)
3. Check logs: `docker-compose logs <service-name>`

### AnythingLLM Shows "Unauthorized"

**Issue:** API calls return 401 error

**Solution:**
1. Verify API key in `.env` file
2. Regenerate API key in AnythingLLM settings
3. Initialize MCP client:
   ```
   mcp__anythingllm__initialize_anythingllm
     apiKey: "your-key"
     baseUrl: "http://localhost:9103"
   ```

### Port Already in Use

**Issue:** Container fails with "port already allocated"

**Solution:**
1. Find process using port: `netstat -ano | findstr :9100` (Windows)
2. Kill process or change ports in `.env` file:
   ```
   CRAWL4AI_PORT=9200
   YT_DLP_PORT=9201
   WHISPER_PORT=9202
   ANYTHINGLLM_PORT=9203
   ```

### Whisper Model Not Downloaded

**Issue:** Audio transcription fails

**Solution:**
Models are auto-downloaded on first use. Wait 2-3 minutes for download to complete.

Check logs: `docker-compose logs whisper-server`

## Port Customization

Default ports (9100-9103) work for most users. To customize:

1. Copy example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your preferred ports:
   ```
   CRAWL4AI_PORT=9100
   YT_DLP_PORT=9101
   WHISPER_PORT=9102
   ANYTHINGLLM_PORT=9103
   ```

3. Restart containers:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Updating

### Update Containers

Pull latest images:

```bash
cd brainery-containers
docker-compose pull
docker-compose up -d
```

### Update Skill

```bash
cd ~/.claude/skills/brainery
git pull origin main
```

## Uninstallation

### Remove Containers

```bash
cd brainery-containers
docker-compose down -v  # -v removes volumes (deletes RAG data!)
```

### Remove Skill

```bash
rm -rf ~/.claude/skills/brainery
```

## Next Steps

See [Usage Examples](usage.md) for practical workflows and common scenarios.
