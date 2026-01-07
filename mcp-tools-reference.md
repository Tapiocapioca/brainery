# Brainery MCP Tools Reference

Complete reference for MCP tools used in Brainery workflows.

## Architecture Overview

| Container | Port | Purpose | MCP Tool Prefix |
|-----------|------|---------|-----------------|
| **crawl4ai** | 9100 | Web page extraction | `mcp__crawl4ai__*` |
| **yt-dlp-server** | 9101 | YouTube transcripts | `mcp__yt-dlp__*` |
| **whisper-server** | 9102 | Audio transcription | HTTP API (curl) |
| **anythingllm** | 9103 | Local RAG database | `mcp__anythingllm__*` |

---

## Crawl4AI Tools

### mcp__crawl4ai__md

Extract clean markdown from web pages.

**Parameters:**
- `url` (required): Full HTTP/HTTPS URL
- `f` (optional): Filtering strategy
  - `raw`: Full page content (default)
  - `fit`: AI-filtered relevant content only
  - `bm25`: BM25 algorithm filtering (requires `q`)
  - `llm`: LLM-based filtering (requires `q`)
- `q` (optional): Query string for BM25/LLM filters
- `c` (optional): Cache-bust counter (default: "0")

**Example:**
```
mcp__crawl4ai__md
  url: "https://example.com/article"
  f: "fit"
  q: "machine learning applications"
```

**Common Issues:**
- PDF URLs work if publicly accessible
- Use `f: "fit"` for cleaner content
- Large pages may timeout (try `f: "fast"`)

---

## YouTube Tools (yt-dlp)

### mcp__yt-dlp__ytdlp_download_transcript

Download transcript with timestamps removed.

**Parameters:**
- `url` (required): Full YouTube URL
- `language` (optional): Language code (default: "en")
  - Examples: "en", "it", "zh", "auto"

**Example:**
```
mcp__yt-dlp__ytdlp_download_transcript
  url: "https://www.youtube.com/watch?v=VIDEO_ID"
  language: "en"
```

**Returns:** Plain text transcript (timestamps removed)

### mcp__yt-dlp__ytdlp_get_video_metadata_summary

Get video metadata (title, channel, duration, views).

**Parameters:**
- `url` (required): Full YouTube URL

**Example:**
```
mcp__yt-dlp__ytdlp_get_video_metadata_summary
  url: "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Returns:** Formatted summary with title, channel, duration, views, upload date

### mcp__yt-dlp__ytdlp_download_audio

Download audio file to ~/Downloads/.

**Parameters:**
- `url` (required): Full YouTube URL

**Example:**
```
mcp__yt-dlp__ytdlp_download_audio
  url: "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Returns:** Success message with filename
**Output location:** `~/Downloads/` (usually M4A format)

---

## Whisper Transcription (HTTP API)

### HTTP POST /transcribe

Transcribe local audio files using Whisper.

**Endpoint:** `http://localhost:9102/transcribe`

**Parameters (form-data):**
- `audio` (required): Audio file path
- `language` (optional): Language code or "auto" (default: "auto")
- `model` (optional): Model size (default: "base")
  - `tiny`: Fastest, lowest quality (~39M params)
  - `base`: Fast, good quality (~74M params) **← Recommended**
  - `small`: Balanced (~244M params)
  - `medium`: High quality, slower (~769M params)
  - `large`: Best quality, slowest (~1550M params)

**Supported formats:** MP3, M4A, WAV, OGG, FLAC, WEBM

**Example:**
```bash
curl -X POST http://localhost:9102/transcribe \
  -F "audio=@$HOME/Downloads/audio.m4a" \
  -F "language=auto" \
  -F "model=base"
```

**Returns JSON:**
```json
{
  "text": "Transcribed text...",
  "language": "en",
  "duration": 125.5,
  "segments": [...]
}
```

**Extract text field:**
```bash
TRANSCRIPTION=$(curl -s -X POST http://localhost:9102/transcribe \
  -F "audio=@$HOME/Downloads/audio.m4a" \
  -F "language=auto" \
  -F "model=base")

TEXT=$(echo "$TRANSCRIPTION" | jq -r '.text')
```

**Troubleshooting:**
- Model download slow: Use `tiny` or `base` first
- Check logs: `docker logs brainery-whisper-server-1`
- Ensure audio format supported

---

## AnythingLLM Tools

### mcp__anythingllm__initialize_anythingllm

Initialize AnythingLLM client (required before first use).

**Parameters:**
- `apiKey` (required): API key from AnythingLLM settings
- `baseUrl` (optional): Base URL (default: "http://localhost:9103")

**Example:**
```
mcp__anythingllm__initialize_anythingllm
  apiKey: "YOUR_API_KEY"
  baseUrl: "http://localhost:9103"
```

**Get API key:**
1. Open http://localhost:9103
2. Settings → API Keys → Generate New API Key

### mcp__anythingllm__embed_webpage

Embed webpage content into workspace.

**Parameters:**
- `slug` (required): Workspace slug (e.g., "brainery")
- `url` (required): Full URL to embed

**Example:**
```
mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/article"
```

**Note:** Uses AnythingLLM's built-in web scraping

### mcp__anythingllm__embed_text

Embed text content into workspace.

**Parameters:**
- `slug` (required): Workspace slug
- `texts` (required): Array of text strings

**Example:**
```
mcp__anythingllm__embed_text
  slug: "brainery"
  texts: ["Text content to embed..."]
```

**Use cases:**
- Embedding transcripts from Whisper
- Embedding parsed content from crawl4ai
- Any text content to make searchable

### mcp__anythingllm__chat_with_workspace

Query RAG database with natural language.

**Parameters:**
- `slug` (required): Workspace slug
- `message` (required): Query message
- `mode` (required): **ALWAYS use "query"**
  - `"query"`: Search embedded documents (correct)
  - `"chat"`: Ignores documents, uses only LLM knowledge (wrong)

**Example:**
```
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "What are the main topics discussed?"
  mode: "query"
```

**CRITICAL:** `mode: "chat"` will ignore all embedded documents. Always use `mode: "query"` for RAG queries.

### mcp__anythingllm__create_workspace

Create new workspace.

**Parameters:**
- `name` (required): Workspace name

**Example:**
```
mcp__anythingllm__create_workspace
  name: "research-papers"
```

**Returns:** Workspace object with slug

### mcp__anythingllm__list_workspaces

List all workspaces.

**Example:**
```
mcp__anythingllm__list_workspaces
```

**Returns:** Array of workspace objects

---

## Complete Workflows

### Workflow 1: Web Page Import

```
# 1. Extract content
mcp__crawl4ai__md
  url: "https://example.com/article"
  f: "fit"

# 2. Embed into RAG
mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/article"

# 3. Query
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "Summarize the main points"
  mode: "query"
```

### Workflow 2: YouTube with Transcript

```
# 1. Download transcript
mcp__yt-dlp__ytdlp_download_transcript
  url: "https://www.youtube.com/watch?v=VIDEO_ID"
  language: "en"

# 2. Embed transcript
mcp__anythingllm__embed_text
  slug: "brainery"
  texts: ["<transcript content>"]

# 3. Query
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "What topics were discussed?"
  mode: "query"
```

### Workflow 3: YouTube without Transcript (Whisper Fallback)

```
# 1. Download audio
mcp__yt-dlp__ytdlp_download_audio
  url: "https://www.youtube.com/watch?v=VIDEO_ID"

# 2. Transcribe with Whisper
TRANSCRIPTION=$(curl -s -X POST http://localhost:9102/transcribe \
  -F "audio=@$HOME/Downloads/video-title.m4a" \
  -F "language=auto" \
  -F "model=base")

TEXT=$(echo "$TRANSCRIPTION" | jq -r '.text')

# 3. Embed transcript
mcp__anythingllm__embed_text
  slug: "brainery"
  texts: ["$TEXT"]

# 4. Query
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "What are the key takeaways?"
  mode: "query"
```

### Workflow 4: Local Audio File

```
# 1. Transcribe
curl -X POST http://localhost:9102/transcribe \
  -F "audio=@/path/to/audio.mp3" \
  -F "language=auto" \
  -F "model=base" > /tmp/transcription.json

# 2. Extract text
TEXT=$(cat /tmp/transcription.json | jq -r '.text')

# 3. Embed
mcp__anythingllm__embed_text
  slug: "brainery"
  texts: ["$TEXT"]

# 4. Query
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "What was discussed?"
  mode: "query"
```

---

## Error Handling

### AnythingLLM Not Initialized

**Error:** "Client not initialized"

**Fix:**
```
mcp__anythingllm__initialize_anythingllm
  apiKey: "<API_KEY>"
  baseUrl: "http://localhost:9103"
```

Get API key from `.env` file: `ANYTHINGLLM_API_KEY`

### Container Not Running

**Error:** Connection refused on port 9100-9103

**Fix:**
```bash
cd <brainery-containers-path>
docker-compose restart <service-name>
```

### No Transcript Available

**Error:** YouTube video has no transcript

**Solution:** Use Whisper fallback workflow (Workflow 3 above)

### Whisper Model Not Downloaded

**Symptoms:** First transcription slow (2-3 minutes)

**Explanation:** Models auto-download on first use. Wait for completion.

**Check logs:**
```bash
docker logs brainery-whisper-server-1
```

---

## Best Practices

1. **Workspace Organization**
   - Use separate workspaces for different topics
   - Example: "research-papers", "tutorials", "documentation"

2. **Content Filtering**
   - Use `f: "fit"` for focused content
   - Use `f: "raw"` for complete pages

3. **Batch Import**
   - Import multiple URLs sequentially
   - Query once after all imports complete

4. **Whisper Model Selection**
   - Use `base` for most cases (good balance)
   - Use `tiny` for long videos (faster, lower quality)
   - Use `small`/`medium` for critical transcriptions

5. **Verify Embeddings**
   - After embedding, test with simple query
   - Ensures content is accessible in RAG

6. **Clean URLs**
   - Remove tracking parameters before importing
   - Example: Remove `?utm_source=...` etc.
