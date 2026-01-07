---
name: brainery-rag-import
description: Use when importing web content (pages, YouTube videos, PDFs, audio) into local RAG for natural language queries. Trigger when user wants to save content for later querying or needs searchable knowledge base.
---

# Brainery RAG Import

## Overview

Import web content into local RAG (AnythingLLM) for natural language queries. Core pattern: fetch → parse → embed → query.

## When to Use

- User wants to save articles/videos for later querying
- Building searchable knowledge base from web content
- Need to query multiple sources with natural language
- YouTube videos without transcripts (Whisper fallback)
- Local PDFs/documents to import

**When NOT to use:**
- One-time content reading (just use web fetch)
- Real-time web scraping without persistence
- Content doesn't need querying later

## Quick Reference

| Content Type | Tool Chain | Output |
|--------------|------------|--------|
| Web page | crawl4ai → embed_webpage | In RAG |
| YouTube (with subs) | yt-dlp transcript → embed_text | In RAG |
| YouTube (no subs) | yt-dlp audio → whisper → embed_text | In RAG |
| Local audio | whisper → embed_text | In RAG |
| PDF URL | crawl4ai → embed_webpage | In RAG |

## Core Pattern

**Before:**
```
User: "What did that article say about X?"
Claude: *re-fetches URL, reads again, forgets after session*
```

**After:**
```
User: "What did that article say about X?"
Claude: *queries RAG with workspace context, instant recall*
```

## Implementation

See @mcp-tools-reference.md for complete MCP tool documentation.
See @containers-reference.md for infrastructure setup and troubleshooting.

### Basic Workflow

1. **Verify prerequisites**
   ```bash
   docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}"
   curl http://localhost:9103/api/ping
   ```

2. **Import content** (example: web page)
   ```
   mcp__crawl4ai__md
     url: "https://example.com/article"
     f: "fit"  # AI-filtered relevant content

   mcp__anythingllm__embed_webpage
     slug: "brainery"
     url: "https://example.com/article"
   ```

3. **Query RAG**
   ```
   mcp__anythingllm__chat_with_workspace
     slug: "brainery"
     message: "What are the main points?"
     mode: "query"  # CRITICAL: Always use "query" mode
   ```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Used `mode: "chat"` in RAG query | Always use `mode: "query"` - chat mode ignores documents |
| Containers not running | Check `docker ps`, start with `docker-compose up -d` |
| AnythingLLM "Unauthorized" | Initialize: `mcp__anythingllm__initialize_anythingllm` |
| No transcript for YouTube | Use Whisper fallback workflow (see @mcp-tools-reference.md) |
| Forgot to embed after parsing | Parse doesn't auto-embed - always call embed_text/embed_webpage |

## Real-World Impact

**Without Brainery:**
- Re-fetch content every session (API costs, latency)
- Lose context after conversation ends
- Can't cross-reference multiple sources

**With Brainery:**
- Instant queries across all imported content
- Persistent knowledge base
- Natural language search across sources
