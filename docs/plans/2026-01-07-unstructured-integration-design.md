# Unstructured.io Integration Design

**Date**: 2026-01-07
**Author**: Claude (Brainstorming Session)
**Status**: Approved for Implementation

---

## Executive Summary

Integration of Unstructured.io into Brainery to enable **local document parsing** (PDF, DOCX, TXT, logs, etc.), completing the content ingestion stack. This adds a 5th Docker container and 2 new MCP servers while maintaining architectural consistency.

**Key Additions:**
- Container: `unstructured-api` (port 9104)
- MCP Server: `@tapiocapioca/unstructured-mcp-server`
- MCP Server: `@tapiocapioca/whisper-mcp-server` (refactor from HTTP)

---

## 1. Architecture Overview

### Current Stack (4 containers)
```
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ MCP Tools
       ├──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼
  ┌─────────┐ ┌────────┐ ┌─────────┐ ┌────────────┐
  │crawl4ai │ │yt-dlp  │ │whisper  │ │anythingllm │
  │  :9100  │ │ :9101  │ │ :9102   │ │   :9103    │
  └─────────┘ └────────┘ └─────────┘ └────────────┘
```

### New Stack (5 containers)
```
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ MCP Tools
       ├────────┬────────┬────────┬────────┐
       ▼        ▼        ▼        ▼        ▼
  ┌─────────┐┌───────┐┌────────┐┌──────────┐┌──────────────┐
  │crawl4ai ││yt-dlp ││whisper ││anythingllm││unstructured  │
  │  :9100  ││ :9101 ││ :9102  ││  :9103   ││    :9104     │
  └─────────┘└───────┘└────────┘└──────────┘└──────────────┘
   Web scrape YouTube  Audio     RAG DB      Doc parsing
               transc.  transc.
```

### Tool Coverage
| Use Case | Tool | Input | Output |
|----------|------|-------|--------|
| Web pages | crawl4ai | HTTP URL | Markdown |
| YouTube | yt-dlp | YouTube URL | Transcript |
| Audio files | whisper | Local audio | Transcript |
| **Documents** | **unstructured** | **Local files** | **JSON text** |
| RAG queries | anythingllm | Text/URL | Query results |

---

## 2. Component Specifications

### 2.1 Docker Container: unstructured-api

**Repository**: Fork `Unstructured-IO/unstructured-api` → `tapiocapioca/unstructured-api`

**docker-compose.yml addition:**
```yaml
  unstructured-api:
    image: tapiocapioca/unstructured-api:latest
    container_name: brainery-unstructured-1
    ports:
      - "${UNSTRUCTURED_PORT:-9104}:8000"
    volumes:
      # Linux/Mac - read-only mount
      - ${HOME}:/host:ro
      # Windows
      - ${USERPROFILE}:/host:ro
    environment:
      - UNSTRUCTURED_API_KEY=${UNSTRUCTURED_API_KEY:-}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Build Strategy:**
- GitHub Actions workflow (`.github/workflows/build-unstructured.yml`)
- Build for AMD64 + ARM64 platforms
- Push to Docker Hub: `tapiocapioca/unstructured-api:latest`
- Identical to existing workflows (crawl4ai, yt-dlp, whisper, anythingllm)

**Image Size**: ~6GB (includes all parsers + OCR dependencies)

---

### 2.2 MCP Server: @tapiocapioca/unstructured-mcp-server

**New npm package** - Publishes to npm registry

**Tools Exposed:**

1. **parse_document**
   ```typescript
   parse_document(
     file_path: string,
     strategy?: "auto" | "fast" | "hi_res" | "ocr_only"
   ): Promise<ParsedDocument>
   ```

2. **parse_batch**
   ```typescript
   parse_batch(
     file_paths: string[],
     strategy?: "auto"
   ): Promise<ParsedDocument[]>
   ```

**Internal Logic:**
1. Receive host path (e.g., `/home/user/docs/file.pdf`)
2. Translate to container path (`/host/docs/file.pdf`)
3. Call API: `POST http://localhost:9104/general/v0/general`
4. Simplify JSON response (extract text + metadata)
5. Return to Claude Code

**Supported File Types:**

**A) Native Unstructured parsing** (advanced layout detection):
- PDF, DOCX, DOC, PPTX, PPT, XLSX, XLS
- EML, MSG (email)
- HTML, XML, EPUB, ODT

**B) Text-based files** (direct read):
- `.txt`, `.log`, `.md`, `.csv`, `.json`, `.yaml`, `.yml`
- Source code: `.sh`, `.bash`, `.py`, `.js`, `.ts`, `.java`, `.c`, `.cpp`
- Config files: `.conf`, `.cfg`, `.ini`, `.properties`, `.env`
- `.sql`, `.gitignore`, `.htaccess`
- Files without extension (fallback to text)

**Output Format:**
```json
{
  "text": "Full extracted text content...",
  "elements_count": 45,
  "file_type": "application/pdf",
  "pages": 10,
  "processing_time_ms": 1250
}
```

**Error Handling:**
- File not found
- Unsupported format
- File too large (>50MB)
- Container unreachable
- Timeout (large files)

**Path Translation (cross-platform):**
- Linux/Mac: `/home/user/file.pdf` → `/host/file.pdf`
- Windows: `C:\Users\Name\file.pdf` → `/host/Users/Name/file.pdf`
- Handle spaces in paths (proper quoting)

---

### 2.3 MCP Server: @tapiocapioca/whisper-mcp-server

**New npm package** - Refactors existing HTTP curl calls

**Tool Exposed:**

```typescript
transcribe_audio(
  file_path: string,
  language?: string,  // default: "auto"
  model?: "tiny" | "base" | "small" | "medium" | "large"  // default: "base"
): Promise<Transcription>
```

**Internal Logic:**
1. Receive host path
2. Translate to container path (`/host/audio/file.mp3`)
3. Call API: `POST http://localhost:9102/transcribe`
4. Return transcription

**Supported Audio Formats:**
- MP3, M4A, WAV, OGG, FLAC, WEBM

**Output Format:**
```json
{
  "text": "Transcribed text...",
  "language": "en",
  "language_probability": 0.98,
  "duration_seconds": 125.5,
  "processing_time_seconds": 8.2,
  "model_used": "base"
}
```

**Validation:**
- Audio format check before API call
- Progress indication for long files (>5 min)
- Model validation

---

## 3. System Requirements (UPDATED)

### Previous Requirements
- Docker Desktop 20.10+
- 8GB RAM minimum
- ~13GB disk space

### New Requirements
- Docker Desktop 20.10+
- **12GB RAM minimum (16GB recommended)**
- **~20GB disk space**

**Breakdown:**
| Component | Disk Space | RAM Usage |
|-----------|------------|-----------|
| crawl4ai | ~2GB | ~512MB |
| yt-dlp-server | ~1GB | ~256MB |
| whisper-server | ~3GB | ~2GB |
| anythingllm | ~1GB | ~1GB |
| **unstructured-api** | **~6GB** | **~4GB** |
| Data volumes | ~7GB | - |
| **TOTAL** | **~20GB** | **~8GB** |

---

## 4. Security Considerations

### Home Directory Mounting

**Configuration:**
```yaml
volumes:
  - ${HOME}:/host:ro  # read-only
```

**Security Impact:**
- ✅ Container CAN read files explicitly requested
- ✅ Container CANNOT modify, delete, or create files
- ✅ Read-only mount (`:ro` flag)
- ✅ Container only runs when Docker is active

**Documentation to add in installation.md:**

**Security Note: File Access**

⚠️ **Privacy Notice**

The `unstructured-api` container mounts your home directory as **read-only** to access local files for parsing.

**What this means:**
- ✅ Container CAN read files you explicitly request to parse
- ✅ Container CANNOT modify, delete, or create files
- ✅ Mount is read-only (`:ro` flag)
- ✅ Container only runs when Docker is active

**Best practices:**
- Only parse files you trust
- Stop containers when not in use: `docker-compose stop`
- Review container logs: `docker logs brainery-unstructured-1`

**Alternative (more restrictive):**
Create a dedicated folder:
```bash
mkdir -p ~/brainery-files
# Edit docker-compose.yml:
# - ${HOME}/brainery-files:/host:ro
```

Then copy files to `~/brainery-files/` before parsing.

---

## 5. File Size Limits and Performance

### Maximum File Sizes

**Documents (PDF, DOCX, etc):**
- **Limit**: 50MB per file
- **Reason**: API timeout, memory constraints
- **Solution**: Split large PDFs or compress

**Audio Files:**
- **Limit**: 2 hours maximum duration
- **Reason**: Processing time, timeout
- **Solution**: Use `model=tiny` for initial processing

### Performance Expectations

| File Type | Size | Processing Time |
|-----------|------|-----------------|
| PDF (10 pages) | 2MB | ~2-5 seconds |
| PDF (100 pages) | 20MB | ~15-30 seconds |
| PDF (scanned, OCR) | 10MB | ~60-120 seconds |
| DOCX | 5MB | ~3-8 seconds |
| TXT/LOG | 10MB | <1 second |
| Audio (MP3, base) | 30 min | ~15-20 seconds |
| Audio (MP3, large) | 30 min | ~60-90 seconds |

### Memory Issues

**If "Out of memory" errors occur:**
1. Increase Docker memory limit (Docker Desktop → Settings → Resources)
2. Restart containers: `docker-compose restart`
3. Process smaller files or use faster strategies (`strategy=fast`)

**Troubleshooting section to add:**

**File Size Limits**

**Checking file size:**
```bash
# Linux/Mac
ls -lh file.pdf

# Windows
dir file.pdf
```

**Maximum sizes:**
- PDF/DOCX: 50MB per file
- Audio: 2 hours duration

**Solutions for large files:**
- Split PDFs: Use `pdftk` or online tools
- Compress PDFs: Use `gs` (Ghostscript)
- For audio: Use `model=tiny` first, then re-process important sections

---

## 6. Backup Strategy

**New file**: `docs/BACKUP.md` (English only - technical documentation)

### What to Backup

**Critical data (persistent volumes):**
- `anythingllm-storage` - RAG database, embeddings, documents
- `whisper-models` - Downloaded Whisper models (~3GB)

**Not needed (stateless):**
- crawl4ai, yt-dlp, unstructured-api - no persistent data

### Backup Procedure

```bash
# 1. Stop containers
cd brainery-containers
docker-compose stop

# 2. Backup AnythingLLM storage
mkdir -p ~/brainery-backup/$(date +%Y%m%d)
docker cp brainery-anythingllm-1:/app/server/storage \
  ~/brainery-backup/$(date +%Y%m%d)/anythingllm-storage

# 3. Backup Whisper models (optional, ~3GB)
docker run --rm -v whisper-models:/data \
  -v ~/brainery-backup/$(date +%Y%m%d):/backup \
  alpine tar czf /backup/whisper-models.tar.gz -C /data .

# 4. Restart containers
docker-compose start

# 5. Verify backup
ls -lh ~/brainery-backup/$(date +%Y%m%d)/
```

### Restore Procedure

```bash
# 1. Stop containers
docker-compose stop

# 2. Remove current data (CAUTION!)
docker rm brainery-anythingllm-1
docker volume rm anythingllm-storage

# 3. Recreate volume and restore
docker volume create anythingllm-storage
docker run --rm -v anythingllm-storage:/app/server/storage \
  -v ~/brainery-backup/20260107/anythingllm-storage:/backup \
  alpine cp -r /backup/. /app/server/storage/

# 4. Recreate container and verify
docker-compose up -d anythingllm
curl http://localhost:9103/api/ping
```

### Automated Backup Script

**File**: `brainery-containers/scripts/backup-brainery.sh`

```bash
#!/bin/bash
BACKUP_DIR=~/brainery-backup/$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

echo "Stopping containers..."
docker-compose stop

echo "Backing up AnythingLLM..."
docker cp brainery-anythingllm-1:/app/server/storage \
  "$BACKUP_DIR/anythingllm-storage"

echo "Restarting containers..."
docker-compose start

echo "Backup complete: $BACKUP_DIR"
```

**Backup Schedule Recommendations:**
- **Daily**: If actively importing documents
- **Weekly**: For normal usage
- **Before upgrades**: Always backup before updating containers

---

## 7. Documentation Updates

### 7.1 Multilingual Documentation Strategy

**Files requiring EN/IT/ZH versions:**
- README.md
- docs/*/installation.md
- docs/*/usage.md

**Files in English only:**
- Code, comments, technical docs
- MCP server documentation
- CHANGELOG.md
- BACKUP.md (technical guide)
- BRAINERY_CONTEXT.md

### 7.2 iFlow Platform Emphasis

**CRITICAL**: Every installation guide must prominently feature iFlow Platform as the recommended free LLM provider.

**Callout box in all installation.md files:**

```markdown
> **💡 Why iFlow Platform?** Free tier with 200K context tokens, excellent
> multilingual support (EN/IT/ZH), and fast response times.
>
> **No Chinese phone number required!** Use this registration link:
> https://iflow.cn/oauth?redirect=https%3A%2F%2Fvibex.iflow.cn%2Fsession%2Fsso_login
>
> **Configuration:**
> - Provider: OpenAI Compatible
> - Base URL: https://vibex.iflow.cn/v1
> - Model: glm-4.6
> - Get API key from dashboard after registration
```

**Include in:**
- All README.md files (EN/IT/ZH) - Quick Start section
- All installation.md files (EN/IT/ZH) - Step 3: Configure AnythingLLM
- prompt.md - Prerequisites section

---

## 8. Implementation Phases

### Phase 1: Docker Infrastructure (brainery-containers)
1. Fork Unstructured-IO/unstructured-api
2. Create GitHub Actions workflow
3. Build and push to Docker Hub
4. Update docker-compose.yml
5. Update .env.example
6. Test container stack

### Phase 2: MCP Servers
1. Create @tapiocapioca/unstructured-mcp-server repository
2. Implement parse_document and parse_batch tools
3. Test with local files (PDF, DOCX, TXT, logs)
4. Publish to npm
5. Create @tapiocapioca/whisper-mcp-server repository
6. Implement transcribe_audio tool
7. Publish to npm

### Phase 3: Documentation (brainery)
1. Update prompt.md - add Section 5: Local Document Import
2. Update architecture table
3. Create docs/BACKUP.md
4. Update README.md (EN/IT/ZH)
5. Update installation.md (EN/IT/ZH) - add MCP installation, security note, system requirements
6. Update usage.md (EN/IT/ZH) - add Example 6: Local Document Import
7. Emphasize iFlow Platform in all guides

### Phase 4: Testing and Validation
1. Test complete workflow: parse → embed → query
2. Test batch processing
3. Test cross-platform paths (Windows/Linux/Mac)
4. Test file size limits
5. Test error handling
6. Run automated test scripts

---

## 9. Success Criteria

**Integration is complete when:**

✅ All 5 containers running and healthy
✅ unstructured-api accessible on port 9104
✅ Both MCP servers published to npm
✅ MCP servers installable via @smithery/cli
✅ Can parse PDF and extract text
✅ Can parse DOCX and extract text
✅ Can parse TXT/LOG files
✅ Whisper MCP server works for audio
✅ All documentation updated (EN/IT/ZH)
✅ BACKUP.md created with procedures
✅ System requirements updated everywhere
✅ Security notes added to installation guides
✅ iFlow Platform prominently featured
✅ Test scripts pass
✅ Complete workflow validated: local file → RAG → query

---

## 10. Future Enhancements (v2.0)

**Not in v1.0 scope:**
- Migration guide for existing users
- Advanced unstructured features (chunking, embeddings)
- Performance tuning guide
- Automated integration tests
- MCP server for Whisper models management

---

## Conclusion

This design integrates Unstructured.io into Brainery with:
- **Minimal complexity**: Only essential features in v1.0
- **Architectural consistency**: Follows existing patterns
- **Security**: Read-only file access
- **Documentation**: Complete multilingual guides
- **Backup strategy**: Data protection procedures
- **Performance awareness**: File limits and requirements documented

The integration completes Brainery's content ingestion stack, enabling users to import web pages (crawl4ai), YouTube videos (yt-dlp), audio files (whisper), and **local documents** (unstructured) into a unified RAG system.
