# Brainery - Web Content to RAG Import Skill

## Overview

Brainery imports web content (web pages, YouTube videos, PDFs) into AnythingLLM, a local RAG (Retrieval-Augmented Generation) system. This allows you to query imported content using natural language.

## Architecture

Brainery uses 4 Docker containers working together:

| Container | Port | Purpose | MCP Tool Prefix |
|-----------|------|---------|-----------------|
| **crawl4ai** | 9100 | Clean text extraction from web pages | `mcp__crawl4ai__*` |
| **yt-dlp-server** | 9101 | YouTube transcript extraction | `mcp__yt-dlp__*` |
| **whisper-server** | 9102 | Audio transcription (fallback) | N/A (used internally) |
| **anythingllm** | 9103 | Local RAG database | `mcp__anythingllm__*` |

## Prerequisites

Before using this skill, verify prerequisites are met:

1. **Docker Desktop** running with containers started
2. **AnythingLLM workspace** created (default: "brainery")
3. **LLM provider configured** in AnythingLLM (e.g., iFlow Platform with glm-4.6 model)

**Check prerequisites:**
```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}"
curl http://localhost:9103/api/ping
```

If containers are not running:
```bash
cd <brainery-containers-path>
docker-compose up -d
```

## Workflow

### 1. Web Page Import

Use Crawl4AI to extract clean markdown from web pages:

```
mcp__crawl4ai__md
  url: "https://example.com/article"
  f: "fit"
  q: "optional search query for content filtering"
```

Then embed into AnythingLLM:
```
mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/article"
```

**Markdown filtering strategies (parameter `f`):**
- `raw`: Full page content (default)
- `fit`: AI-filtered relevant content only
- `bm25`: BM25 algorithm filtering with query `q`
- `llm`: LLM-based filtering with query `q`

### 2. YouTube Video Import

Extract transcripts with yt-dlp:

```
mcp__yt-dlp__ytdlp_download_transcript
  url: "https://www.youtube.com/watch?v=VIDEO_ID"
  language: "en"
```

Then embed transcript as text:
```
mcp__anythingllm__embed_text
  slug: "brainery"
  texts: ["<transcript content>"]
```

**Alternative: Video metadata only**
```
mcp__yt-dlp__ytdlp_get_video_metadata_summary
  url: "https://www.youtube.com/watch?v=VIDEO_ID"
```

### 3. PDF Import

For PDF files, use Crawl4AI if the PDF is accessible via URL:

```
mcp__crawl4ai__md
  url: "https://example.com/document.pdf"
  f: "fit"
```

Then embed:
```
mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/document.pdf"
```

**Note:** Local PDF files require conversion to text first using `pdftotext` (part of poppler-utils).

### 4. Query RAG Database

Always use `mode: "query"` to search documents:

```
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "What are the main topics discussed in the articles?"
  mode: "query"
```

**Important:** `mode: "chat"` ignores embedded documents and only uses LLM knowledge. Always use `mode: "query"` for RAG queries.

## Error Handling

### AnythingLLM Not Initialized

If you get "Client not initialized" error:

```
mcp__anythingllm__initialize_anythingllm
  apiKey: "<API_KEY>"
  baseUrl: "http://localhost:9103"
```

API key is in: `<brainery-containers-path>/.env` as `ANYTHINGLLM_API_KEY`

### Container Not Running

If connection refused errors:

```bash
cd <brainery-containers-path>
docker-compose restart <service-name>
```

### No Transcript Available

If YouTube video has no transcript, use Whisper for audio transcription:

1. Download audio: `mcp__yt-dlp__ytdlp_download_audio`
2. Transcribe with Whisper (manually via curl to port 9102)
3. Embed result with `mcp__anythingllm__embed_text`

## Best Practices

1. **Workspace Organization**: Use separate workspaces for different topics
   ```
   mcp__anythingllm__create_workspace
     name: "research-papers"
   ```

2. **Content Filtering**: Use `f: "fit"` for focused content, `f: "raw"` for complete pages

3. **Batch Import**: Import multiple URLs in sequence, then query once

4. **Clean URLs**: Remove tracking parameters before importing

5. **Verify Embeddings**: After embedding, test with a simple query to ensure content is accessible

## Troubleshooting

Refer to `BRAINERY_CONTEXT.md` for:
- Detailed installation steps
- Architecture decisions
- Common issues and solutions
- Advanced configuration options

## Rate Limiting

MCP tools are subject to rate limits. If you encounter 429 errors:
- Wait 60 seconds before retrying
- Use local tools (Read, Write, Bash) during cooldown
- Avoid parallel MCP tool calls

## Documentation

- **English**: `docs/en/`
- **Italiano**: `docs/it/`
- **中文**: `docs/zh/`

Each language folder contains:
- `installation.md`: Setup instructions
- `usage.md`: Practical examples

## Support

For issues, refer to:
- [brainery-containers repository](https://github.com/Tapiocapioca/brainery-containers) for Docker infrastructure
- [brainery repository](https://github.com/Tapiocapioca/brainery) for skill-related questions
