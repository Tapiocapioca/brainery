# Unstructured.io Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate Unstructured.io document parsing into Brainery, adding support for local PDF, DOCX, TXT, and log files.

**Architecture:** Add 5th Docker container (unstructured-api:9104), create 2 new MCP servers (@tapiocapioca/unstructured-mcp-server and @tapiocapioca/whisper-mcp-server), update all documentation (EN/IT/ZH).

**Tech Stack:** Docker, Unstructured.io, Node.js (MCP servers), TypeScript, GitHub Actions

---

## PHASE 1: Docker Infrastructure (brainery-containers repo)

### Task 1: Fork Unstructured-IO/unstructured-api

**Files:**
- None (GitHub web operation)

**Step 1: Fork on GitHub**

1. Navigate to: https://github.com/Unstructured-IO/unstructured-api
2. Click "Fork" button
3. Set owner: `Tapiocapioca`
4. Repository name: `unstructured-api`
5. Description: "Fork of Unstructured.io API for Brainery integration"
6. Create fork

**Step 2: Verify fork**

Run: `gh repo view Tapiocapioca/unstructured-api`
Expected: Repository details displayed

**Step 3: Clone locally (optional)**

```bash
cd C:/AI/Skills/BRAINERY
git clone https://github.com/Tapiocapioca/unstructured-api.git
```

Expected: Repository cloned successfully

---

### Task 2: Create Dockerfile for unstructured-api

**Files:**
- Create: `dockerfiles/unstructured-api/Dockerfile`

**Step 1: Create directory**

```bash
cd C:/AI/Skills/BRAINERY/brainery-containers
mkdir -p dockerfiles/unstructured-api
```

**Step 2: Write Dockerfile**

```dockerfile
FROM quay.io/unstructured-io/unstructured-api:latest

# Expose port 8000 (default for unstructured-api)
EXPOSE 8000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Default command
CMD ["uvicorn", "prepline_general.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Step 3: Verify Dockerfile syntax**

Run: `docker build -t test-unstructured dockerfiles/unstructured-api/ --no-cache`
Expected: Build succeeds (may take 10-15 minutes)

**Step 4: Commit**

```bash
git add dockerfiles/unstructured-api/Dockerfile
git commit -m "feat: add Dockerfile for unstructured-api container

Add unstructured-api as 5th container for local document parsing.
Based on official unstructured.io Docker image."
```

---

### Task 3: Update docker-compose.yml

**Files:**
- Modify: `docker-compose.yml`

**Step 1: Read current docker-compose.yml**

```bash
cat docker-compose.yml
```

**Step 2: Add unstructured-api service**

Add after anythingllm service (before volumes section):

```yaml
  unstructured-api:
    image: tapiocapioca/unstructured-api:latest
    container_name: unstructured-api
    ports:
      - "${UNSTRUCTURED_PORT:-9104}:8000"
    volumes:
      # Linux/Mac - read-only mount
      - ${HOME}:/host:ro
      # Windows (uncomment if on Windows)
      # - ${USERPROFILE}:/host:ro
    environment:
      - UNSTRUCTURED_API_KEY=${UNSTRUCTURED_API_KEY:-}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Step 3: Verify YAML syntax**

Run: `docker-compose config`
Expected: Valid YAML output with all 5 services

**Step 4: Commit**

```bash
git add docker-compose.yml
git commit -m "feat: add unstructured-api service to docker-compose

Add 5th container for local document parsing:
- Port: 9104 (configurable via UNSTRUCTURED_PORT)
- Volume: Read-only home directory mount
- Health check: /health endpoint"
```

---

### Task 4: Update .env.example

**Files:**
- Modify: `.env.example`

**Step 1: Read current .env.example**

```bash
cat .env.example
```

**Step 2: Add unstructured-api configuration**

Add at the end:

```bash
# Unstructured API (Document Parsing)
UNSTRUCTURED_PORT=9104
UNSTRUCTURED_API_KEY=
```

**Step 3: Commit**

```bash
git add .env.example
git commit -m "feat: add unstructured-api environment variables

Add configuration for unstructured-api container:
- UNSTRUCTURED_PORT: Default 9104
- UNSTRUCTURED_API_KEY: Optional API key"
```

---

### Task 5: Update GitHub Actions workflow

**Files:**
- Modify: `.github/workflows/build-and-push.yml`

**Step 1: Read current workflow**

```bash
cat .github/workflows/build-and-push.yml
```

**Step 2: Add unstructured-api to matrix**

Change line 21 from:
```yaml
        service: [crawl4ai, anythingllm, yt-dlp-server, whisper-server]
```

To:
```yaml
        service: [crawl4ai, anythingllm, yt-dlp-server, whisper-server, unstructured-api]
```

**Step 3: Verify workflow syntax**

Run: `gh workflow view "Build and Push Docker Images"`
Expected: Workflow details displayed

**Step 4: Commit**

```bash
git add .github/workflows/build-and-push.yml
git commit -m "ci: add unstructured-api to build matrix

Add unstructured-api to GitHub Actions workflow for automated
Docker image builds and pushes to Docker Hub."
```

---

### Task 6: Test container stack locally

**Files:**
- None (testing only)

**Step 1: Build unstructured-api image locally**

```bash
cd C:/AI/Skills/BRAINERY/brainery-containers
docker build -t tapiocapioca/unstructured-api:latest dockerfiles/unstructured-api/
```

Expected: Build completes successfully (~10-15 minutes)

**Step 2: Start all containers**

```bash
docker-compose up -d
```

Expected: All 5 containers start successfully

**Step 3: Verify all containers running**

```bash
docker ps --filter "name=brainery" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Expected output:
```
NAMES                STATUS          PORTS
unstructured-api     Up X seconds    0.0.0.0:9104->8000/tcp
anythingllm          Up X seconds    0.0.0.0:9103->3001/tcp
whisper-server       Up X seconds    0.0.0.0:9102->8502/tcp
yt-dlp-server        Up X seconds    0.0.0.0:9101->8501/tcp
crawl4ai             Up X seconds    0.0.0.0:9100->11235/tcp
```

**Step 4: Test health endpoints**

```bash
curl http://localhost:9100/health   # crawl4ai
curl http://localhost:9101/health   # yt-dlp-server
curl http://localhost:9102/health   # whisper-server
curl http://localhost:9103/api/ping # anythingllm
curl http://localhost:9104/health   # unstructured-api
```

Expected: All return success responses

**Step 5: Stop containers**

```bash
docker-compose down
```

---

### Task 7: Push changes and trigger GitHub Actions

**Files:**
- None (git operation)

**Step 1: Push all commits**

```bash
git push origin master
```

Expected: Push successful, GitHub Actions triggered

**Step 2: Monitor GitHub Actions**

```bash
gh run watch
```

Expected: Workflow completes successfully, all 5 images built and pushed

**Step 3: Verify images on Docker Hub**

```bash
gh api repos/Tapiocapioca/brainery-containers/actions/runs --jq '.workflow_runs[0].conclusion'
```

Expected: "success"

---

## PHASE 2: MCP Servers (2 new npm packages)

### Task 8: Create @tapiocapioca/unstructured-mcp-server repository

**Files:**
- None (GitHub + npm operations)

**Step 1: Create GitHub repository**

```bash
gh repo create Tapiocapioca/unstructured-mcp-server --public --description "MCP server for Unstructured.io document parsing"
```

**Step 2: Clone and initialize**

```bash
cd C:/AI/Skills/BRAINERY
git clone https://github.com/Tapiocapioca/unstructured-mcp-server.git
cd unstructured-mcp-server
npm init -y
```

**Step 3: Install dependencies**

```bash
npm install @modelcontextprotocol/sdk axios form-data
npm install -D @types/node typescript
```

**Step 4: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Step 5: Commit initial setup**

```bash
git add .
git commit -m "chore: initialize unstructured-mcp-server package

Initialize Node.js project with TypeScript and MCP SDK."
git push origin main
```

---

### Task 9: Implement parse_document tool

**Files:**
- Create: `src/index.ts`
- Create: `src/tools/parseDocument.ts`

**Step 1: Create src directory**

```bash
mkdir src
mkdir src/tools
```

**Step 2: Write parseDocument.ts**

Create `src/tools/parseDocument.ts`:

```typescript
import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import path from 'path';

interface ParsedDocument {
  text: string;
  elements_count: number;
  file_type: string;
  pages?: number;
  processing_time_ms: number;
}

export async function parseDocument(
  filePath: string,
  strategy: 'auto' | 'fast' | 'hi_res' | 'ocr_only' = 'auto'
): Promise<ParsedDocument> {
  const startTime = Date.now();

  // Path translation: host path -> container path
  const containerPath = translatePath(filePath);

  // Check file exists
  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  // Check file size (50MB limit)
  const stats = fs.statSync(filePath);
  if (stats.size > 50 * 1024 * 1024) {
    throw new Error(`File too large: ${(stats.size / 1024 / 1024).toFixed(2)}MB (max 50MB)`);
  }

  // Detect file type
  const ext = path.extname(filePath).toLowerCase();

  // Text-based files: direct read
  const textExtensions = ['.txt', '.log', '.md', '.csv', '.json', '.yaml', '.yml',
    '.sh', '.bash', '.py', '.js', '.ts', '.java', '.c', '.cpp',
    '.conf', '.cfg', '.ini', '.properties', '.env', '.sql', '.gitignore', '.htaccess'];

  if (textExtensions.includes(ext) || !ext) {
    const text = fs.readFileSync(filePath, 'utf-8');
    return {
      text,
      elements_count: 1,
      file_type: 'text/plain',
      processing_time_ms: Date.now() - startTime
    };
  }

  // Unstructured.io parsing for documents
  const form = new FormData();
  form.append('files', fs.createReadStream(filePath));
  form.append('strategy', strategy);

  try {
    const response = await axios.post('http://localhost:9104/general/v0/general', form, {
      headers: form.getHeaders(),
      timeout: 120000 // 2 minutes
    });

    // Simplify response
    const elements = response.data;
    const text = elements.map((e: any) => e.text).join('\n\n');

    return {
      text,
      elements_count: elements.length,
      file_type: elements[0]?.metadata?.filetype || 'unknown',
      pages: elements[0]?.metadata?.page_number,
      processing_time_ms: Date.now() - startTime
    };
  } catch (error: any) {
    if (error.code === 'ECONNREFUSED') {
      throw new Error('Unstructured API not reachable. Is the container running?');
    }
    throw new Error(`Parse failed: ${error.message}`);
  }
}

function translatePath(hostPath: string): string {
  // Windows: C:\Users\Name\file.pdf -> /host/Users/Name/file.pdf
  if (process.platform === 'win32') {
    return hostPath.replace(/^[A-Z]:\\/, '/host/').replace(/\\/g, '/');
  }
  // Linux/Mac: /home/user/file.pdf -> /host/file.pdf
  return hostPath.replace(/^\/home\/[^\/]+/, '/host');
}
```

**Step 3: Write index.ts**

Create `src/index.ts`:

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { parseDocument } from './tools/parseDocument.js';

const server = new Server(
  {
    name: 'unstructured-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'parse_document',
      description: 'Parse local document (PDF, DOCX, TXT, logs) and extract text',
      inputSchema: {
        type: 'object',
        properties: {
          file_path: {
            type: 'string',
            description: 'Absolute path to file on host machine'
          },
          strategy: {
            type: 'string',
            enum: ['auto', 'fast', 'hi_res', 'ocr_only'],
            description: 'Parsing strategy (default: auto)'
          }
        },
        required: ['file_path']
      }
    }
  ]
}));

server.setRequestHandler('tools/call', async (request) => {
  if (request.params.name === 'parse_document') {
    const { file_path, strategy } = request.params.arguments as any;
    const result = await parseDocument(file_path, strategy);
    return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
  }
  throw new Error(`Unknown tool: ${request.params.name}`);
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
```

**Step 4: Update package.json**

Add to package.json:

```json
{
  "name": "@tapiocapioca/unstructured-mcp-server",
  "version": "1.0.0",
  "main": "dist/index.js",
  "bin": {
    "unstructured-mcp-server": "dist/index.js"
  },
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

**Step 5: Build and test**

```bash
npm run build
```

Expected: TypeScript compiles successfully to dist/

**Step 6: Commit**

```bash
git add .
git commit -m "feat: implement parse_document tool

Add document parsing tool with:
- Support for PDF, DOCX, PPTX, XLSX, etc
- Text-based file detection (.txt, .log, .py, etc)
- Path translation (Windows/Linux/Mac)
- File size validation (50MB limit)
- Error handling"
git push origin main
```

---

### Task 10: Implement parse_batch tool

**Files:**
- Create: `src/tools/parseBatch.ts`
- Modify: `src/index.ts`

**Step 1: Write parseBatch.ts**

Create `src/tools/parseBatch.ts`:

```typescript
import { parseDocument } from './parseDocument.js';

export async function parseBatch(filePaths: string[]): Promise<any[]> {
  const results = [];

  for (const filePath of filePaths) {
    try {
      const result = await parseDocument(filePath, 'auto');
      results.push({ file: filePath, success: true, ...result });
    } catch (error: any) {
      results.push({ file: filePath, success: false, error: error.message });
    }
  }

  return results;
}
```

**Step 2: Add to index.ts**

Add to tools list in `src/index.ts`:

```typescript
{
  name: 'parse_batch',
  description: 'Parse multiple documents in batch',
  inputSchema: {
    type: 'object',
    properties: {
      file_paths: {
        type: 'array',
        items: { type: 'string' },
        description: 'Array of absolute paths to files'
      }
    },
    required: ['file_paths']
  }
}
```

Add handler:

```typescript
if (request.params.name === 'parse_batch') {
  const { file_paths } = request.params.arguments as any;
  const results = await parseBatch(file_paths);
  return { content: [{ type: 'text', text: JSON.stringify(results, null, 2) }] };
}
```

**Step 3: Build**

```bash
npm run build
```

**Step 4: Commit**

```bash
git add .
git commit -m "feat: add parse_batch tool for multiple files

Add batch processing capability to parse multiple documents
in a single call with error handling per file."
git push origin main
```

---

### Task 11: Publish unstructured-mcp-server to npm

**Files:**
- Modify: `package.json` (add repository, keywords)
- Create: `README.md`

**Step 1: Add metadata to package.json**

```json
{
  "repository": {
    "type": "git",
    "url": "https://github.com/Tapiocapioca/unstructured-mcp-server.git"
  },
  "keywords": ["mcp", "unstructured", "document-parsing", "pdf", "docx"],
  "author": "Tapiocapioca",
  "license": "MIT"
}
```

**Step 2: Create README.md**

```markdown
# @tapiocapioca/unstructured-mcp-server

MCP server for Unstructured.io document parsing.

## Installation

\`\`\`bash
npx -y @smithery/cli install @tapiocapioca/unstructured-mcp-server --client claude
\`\`\`

## Tools

- \`parse_document\`: Parse single document
- \`parse_batch\`: Parse multiple documents
```

**Step 3: Build final version**

```bash
npm run build
```

**Step 4: Publish to npm**

```bash
npm login
npm publish --access public
```

Expected: Package published successfully

**Step 5: Commit**

```bash
git add .
git commit -m "chore: prepare for npm publication

Add package metadata and README for npm registry."
git push origin main
```

---

### Task 12-17: Create @tapiocapioca/whisper-mcp-server

(Similar structure to Tasks 8-11, but for Whisper MCP server)

**Summary:**
- Create repository: `Tapiocapioca/whisper-mcp-server`
- Implement `transcribe_audio` tool
- Path translation, audio format validation
- Publish to npm

---

## PHASE 3: Documentation Updates (brainery repo)

### Task 18: Update prompt.md

**Files:**
- Modify: `prompt.md`

**Step 1: Add Section 5: Local Document Import**

Add after Section 4 (Local Audio File Import):

```markdown
### 5. Local Document Import

For local documents (PDF, DOCX, TXT, logs), use Unstructured MCP server:

**Step 1: Parse document**

\`\`\`
mcp__tapiocapioca_unstructured-mcp-server__parse_document
  file_path: "/path/to/document.pdf"
  strategy: "auto"
\`\`\`

**Supported file types:**
- Documents: PDF, DOCX, PPTX, XLSX, EML, HTML
- Text files: .txt, .log, .md, .csv, .json, .py, .js, .conf

**Step 2: Embed into RAG**

\`\`\`
mcp__anythingllm__embed_text
  slug: "brainery"
  texts: ["<extracted text>"]
\`\`\`
```

**Step 2: Update architecture table**

Change from 4 containers to 5:

```markdown
| Container | Port | Purpose | MCP Tool Prefix |
|-----------|------|---------|--------------------|
| **crawl4ai** | 9100 | Web page extraction | `mcp__crawl4ai__*` |
| **yt-dlp-server** | 9101 | YouTube transcripts | `mcp__yt-dlp__*` |
| **whisper-server** | 9102 | Audio transcription | `mcp__tapiocapioca_whisper-mcp-server__*` |
| **anythingllm** | 9103 | Local RAG database | `mcp__anythingllm__*` |
| **unstructured-api** | 9104 | Document parsing | `mcp__tapiocapioca_unstructured-mcp-server__*` |
```

**Step 3: Commit**

```bash
git add prompt.md
git commit -m "docs: add local document import section

Add Section 5 with Unstructured MCP server usage and
update architecture table with 5th container."
```

---

### Task 19: Create docs/BACKUP.md

**Files:**
- Create: `docs/BACKUP.md`

**Step 1: Write BACKUP.md**

(Content from design document, Section 6: Backup Strategy)

**Step 2: Commit**

```bash
git add docs/BACKUP.md
git commit -m "docs: add backup and restore procedures

Add comprehensive backup guide for persistent volumes:
- AnythingLLM storage
- Whisper models
- Automated backup scripts"
```

---

### Task 20-25: Update multilingual documentation

**Files to update (6 tasks):**
1. `README.md` (EN)
2. `README.it.md` (IT)
3. `README.zh.md` (ZH)
4. `docs/en/installation.md`
5. `docs/it/installation.md`
6. `docs/zh/installation.md`

**Changes per file:**
- Update system requirements (8GB → 12GB RAM, 13GB → 20GB disk)
- Add unstructured-mcp-server and whisper-mcp-server installation
- Add security note about home directory mount
- Emphasize iFlow Platform with callout box

---

### Task 26-28: Update usage.md files

**Files:**
- `docs/en/usage.md`
- `docs/it/usage.md`
- `docs/zh/usage.md`

**Add Example 6: Local Document Import**

Similar structure to existing examples, with complete workflow.

---

## PHASE 4: Testing and Validation

### Task 29: Test complete workflow

**Step 1: Start all containers**

```bash
cd C:/AI/Skills/BRAINERY/brainery-containers
docker-compose up -d
```

**Step 2: Test parse → embed → query**

1. Parse a local PDF
2. Embed text into AnythingLLM
3. Query the content

**Step 3: Verify results**

Expected: Query returns relevant content from parsed PDF

---

### Task 30: Test batch processing

Test `parse_batch` with multiple files of different types.

---

### Task 31: Test cross-platform paths

Test path translation on Windows, Linux paths.

---

### Task 32: Test file size limits

Test with files >50MB (should fail gracefully).

---

### Task 33: Test error handling

Test with:
- Non-existent files
- Unsupported formats
- Container not running

---

## Success Criteria Checklist

- [ ] All 5 containers running and healthy
- [ ] unstructured-api accessible on port 9104
- [ ] Both MCP servers published to npm
- [ ] MCP servers installable via @smithery/cli
- [ ] Can parse PDF and extract text
- [ ] Can parse DOCX and extract text
- [ ] Can parse TXT/LOG files
- [ ] Whisper MCP server works for audio
- [ ] All documentation updated (EN/IT/ZH)
- [ ] BACKUP.md created with procedures
- [ ] System requirements updated everywhere
- [ ] Security notes added to installation guides
- [ ] iFlow Platform prominently featured
- [ ] Test scripts pass
- [ ] Complete workflow validated: local file → RAG → query

---

**End of Implementation Plan**
