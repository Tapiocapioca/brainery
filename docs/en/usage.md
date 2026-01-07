# Usage Examples

Practical examples for common Brainery workflows.

## Prerequisites

Ensure containers are running and AnythingLLM is configured:

```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}"
curl http://localhost:9103/api/ping
```

## Example 1: Import Web Article

**Scenario:** Import a technical blog post into Brainery for later reference.

### Step 1: Import the article

In Claude Code:

```
Import this article into Brainery: https://example.com/blog/docker-best-practices
```

Claude will use:
```
mcp__crawl4ai__md
  url: "https://example.com/blog/docker-best-practices"
  f: "fit"

mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/blog/docker-best-practices"
```

### Step 2: Query the content

```
What are the top 3 Docker best practices mentioned in the article I just imported?
```

Claude will use:
```
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "What are the top 3 Docker best practices?"
  mode: "query"
```

**Result:** Claude retrieves relevant sections from the imported article and summarizes the key practices.

---

## Example 2: Import YouTube Video Transcript

**Scenario:** Extract and save the transcript from an educational YouTube video.

### Step 1: Import the transcript

```
Import the transcript from this video: https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Claude will:
1. Extract transcript: `mcp__yt-dlp__ytdlp_download_transcript`
2. Embed into AnythingLLM: `mcp__anythingllm__embed_text`

### Step 2: Query the content

```
Summarize the main topics covered in the video transcript I just imported.
```

**Result:** Claude provides a structured summary based on the transcript content.

---

## Example 3: Batch Import Multiple Articles

**Scenario:** Import several related articles on the same topic.

```
Import these articles into Brainery:
1. https://example.com/kubernetes-intro
2. https://example.com/kubernetes-networking
3. https://example.com/kubernetes-security

Then tell me what the common themes are across all three articles.
```

Claude will:
1. Import each article sequentially
2. Query all imported content with a single RAG query
3. Analyze common themes across documents

**Benefit:** All three articles are searchable together, enabling cross-document analysis.

---

## Example 4: PDF Import

**Scenario:** Import a research paper PDF for analysis.

### If PDF is accessible via URL:

```
Import this research paper: https://arxiv.org/pdf/2301.12345.pdf
```

Claude will use Crawl4AI to extract text and embed it.

### If PDF is local:

1. **Convert PDF to text** (one-time setup):
   ```bash
   pdftotext document.pdf document.txt
   ```

2. **Upload to a temporary URL** or use AnythingLLM's document upload feature via web interface

3. **Query the content**:
   ```
   What is the main conclusion of the research paper I uploaded?
   ```

---

## Example 5: Local Audio File Import

**Scenario:** Transcribe and import a podcast episode or meeting recording from your local machine.

### Step 1: Prepare audio file

Ensure your audio file is in a supported format (MP3, WAV, M4A, OGG, FLAC, WEBM).

### Step 2: Transcribe with Whisper

```
Transcribe this local audio file: /home/user/podcasts/episode-123.mp3
```

Claude will:

1. **Call Whisper server**:
   ```bash
   curl -X POST http://localhost:9102/transcribe \
     -F "audio=@/home/user/podcasts/episode-123.mp3" \
     -F "language=auto" \
     -F "model=base"
   ```

2. **Extract transcript** from JSON response

3. **Embed into AnythingLLM**:
   ```
   mcp__anythingllm__embed_text
     slug: "brainery"
     texts: ["<transcription text>"]
   ```

### Step 3: Query the content

```
What are the key topics discussed in the podcast episode I just imported?
```

**Result:** Claude retrieves the transcript and summarizes the main discussion points.

### Tips

- **For long files (>30 minutes)**: Use `model=tiny` for faster processing, then re-transcribe important sections with `model=base` or `model=small`
- **Language detection**: Use `language=auto` if unsure, or specify explicitly (`en`, `it`, `zh`)
- **File path**: Use absolute paths (e.g., `/home/user/file.mp3`) or relative to Claude Code's working directory

**Common use cases:**
- Podcast episodes for research
- Meeting recordings for note-taking
- Interview transcripts for analysis
- Voice memos for personal knowledge base

---

## Example 6: Create Topic-Specific Workspace

**Scenario:** Organize content by topic using separate workspaces.

### Step 1: Create workspace

```
Create a new AnythingLLM workspace called "machine-learning"
```

Claude will use:
```
mcp__anythingllm__create_workspace
  name: "machine-learning"
```

### Step 2: Import content to specific workspace

```
Import this article into the "machine-learning" workspace: https://example.com/ml-tutorial
```

Claude will specify the workspace slug during embedding:
```
mcp__anythingllm__embed_webpage
  slug: "machine-learning"
  url: "https://example.com/ml-tutorial"
```

### Step 3: Query specific workspace

```
Query the machine-learning workspace: What are the key concepts in ML?
```

**Benefit:** Content is organized by topic, preventing cross-contamination between unrelated documents.

---

## Example 7: Advanced Content Filtering

**Scenario:** Extract only relevant sections from a long article.

### Option A: BM25 Filtering

```
Import this article using BM25 filtering with query "Docker security":
https://example.com/docker-complete-guide
```

Claude will use:
```
mcp__crawl4ai__md
  url: "https://example.com/docker-complete-guide"
  f: "bm25"
  q: "Docker security"
```

### Option B: LLM Filtering

```
Import this article, but only sections about performance optimization:
https://example.com/web-development-guide
```

Claude will use:
```
mcp__crawl4ai__md
  url: "https://example.com/web-development-guide"
  f: "llm"
  q: "performance optimization"
```

**Benefit:** Reduces token usage and focuses on relevant content only.

---

## Example 8: Verify Import Success

**Scenario:** Ensure content was successfully embedded before proceeding.

```
Import this article: https://example.com/article

Then verify it was imported correctly by asking: "What is the title of the last article I imported?"
```

Claude will:
1. Import the article
2. Query AnythingLLM to confirm content is retrievable
3. Report success or failure

**Best Practice:** Always verify imports, especially for critical documents.

---

## Example 9: Multi-Language Content

**Scenario:** Import content in different languages (English, Italian, Chinese).

### English article:
```
Import: https://example.com/en/article
```

### Italian article:
```
Import: https://example.com/it/articolo
```

### Chinese article:
```
Import: https://example.com/zh/文章
```

### Query in any language:
```
What are the common themes in all three articles? (Answer in English)
```

**Benefit:** Brainery supports multilingual content. The LLM provider (e.g., iFlow's glm-4.6) handles translation during queries.

---

## Example 10: Delete Old Content

**Scenario:** Remove outdated content from workspace.

### List documents:
```
Show me all documents in the brainery workspace
```

Claude will use:
```
mcp__anythingllm__list_documents
  slug: "brainery"
```

### Delete specific document:
```
Delete the document with ID "doc_abc123"
```

Claude will use:
```
mcp__anythingllm__delete_document
  slug: "brainery"
  documentId: "doc_abc123"
```

---

## Example 11: Troubleshooting Failed Import

**Scenario:** Import fails due to connection issue.

### Error message:
```
Error: Failed to connect to http://localhost:9100
```

### Resolution:
1. **Check container status:**
   ```bash
   docker ps --filter "name=brainery-crawl4ai"
   ```

2. **Restart container if needed:**
   ```bash
   docker-compose restart crawl4ai
   ```

3. **Retry import:**
   ```
   Import: https://example.com/article
   ```

---

## Common Patterns

### Pattern 1: Import → Verify → Query

```
1. Import content
2. Verify: "What was the last article I imported?"
3. Query: "What are the key points?"
```

### Pattern 2: Batch Import → Aggregate Query

```
1. Import multiple related articles
2. Query: "What are the common themes across all articles?"
```

### Pattern 3: Workspace Organization

```
1. Create topic-specific workspace
2. Import all related content to that workspace
3. Query workspace for focused results
```

---

## Tips and Best Practices

1. **Use `f: "fit"` for most web pages** - Extracts clean, relevant content without ads/navigation

2. **Verify imports** - Always test with a simple query after importing critical documents

3. **Organize by workspace** - Separate unrelated topics into different workspaces

4. **Clean URLs** - Remove tracking parameters before importing:
   ```
   ❌ https://example.com/article?utm_source=twitter&ref=123
   ✅ https://example.com/article
   ```

5. **Check rate limits** - If you get 429 errors, wait 60 seconds before retrying

6. **Use mode: "query"** - Always use `mode: "query"` for RAG queries, not `mode: "chat"`

---

## Next Steps

- Review [Installation Guide](installation.md) for setup instructions
- Check [BRAINERY_CONTEXT.md](../../BRAINERY_CONTEXT.md) for advanced configuration
- Visit [brainery-containers](https://github.com/Tapiocapioca/brainery-containers) for container documentation
