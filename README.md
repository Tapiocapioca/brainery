# Brainery

Claude Code skill for importing web content, YouTube videos, and PDFs into local RAG system.

[🇮🇹 Italiano](README.it.md) | [🇨🇳 中文](README.zh.md)

## Overview

Brainery enables Claude Code to import and query web content using AnythingLLM as a local RAG (Retrieval-Augmented Generation) database. Import articles, YouTube transcripts, and PDFs, then query them using natural language.

**Key Features:**
- 🌐 **Web scraping** with clean markdown extraction (Crawl4AI)
- 📺 **YouTube transcripts** with automatic fallback to audio transcription (yt-dlp + Whisper)
- 📄 **PDF import** with text extraction
- 🧠 **Local RAG database** for private, offline content querying (AnythingLLM)
- 💰 **Free LLM provider** compatible with AnythingLLM (iFlow Platform - 200K context tokens free tier)
- 🐳 **Docker-based** infrastructure with pre-built images
- 🌍 **Multilingual** documentation (EN/IT/ZH)

## Quick Start

### 1. Install Docker Containers

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
docker-compose up -d
```

**Container Stack:**
- **crawl4ai** (port 9100) - Web scraping
- **yt-dlp-server** (port 9101) - YouTube transcripts
- **whisper-server** (port 9102) - Audio transcription
- **anythingllm** (port 9103) - RAG database

### 2. Configure AnythingLLM

Open http://localhost:9103 and:
1. Create admin account
2. **Configure LLM provider** (recommended: **iFlow Platform** - free tier with 200K context tokens)
   - Provider: `OpenAI Compatible`
   - Base URL: `https://vibex.iflow.cn/v1`
   - Model: `glm-4.6`
   - Get API key from: https://iflow.cn
3. Create workspace (e.g., "brainery")
4. Generate API key in Settings → API Keys

> **💡 Why iFlow?** Free tier with excellent multilingual support (EN/IT/ZH), 200K context window, and fast response times. See [Installation Guide](docs/en/installation.md#iflow-platform-setup-recommended) for detailed setup.

### 3. Install MCP Servers

Install required MCP servers for Claude Code integration:

```bash
# Install AnythingLLM MCP server (use our fork)
npx -y @smithery/cli install @tapiocapioca/anythingllm-mcp-server --client claude

# Install other MCP servers
npx -y @smithery/cli install crawl4ai --client claude
npx -y @smithery/cli install yt-dlp --client claude
```

> **📝 Note:** We use a custom fork of AnythingLLM MCP server: https://github.com/Tapiocapioca/anythingllm-mcp-server

### 4. Install Skill

```bash
cd ~/.claude/skills
git clone https://github.com/Tapiocapioca/brainery.git
```

Restart Claude Code to load the skill.

### 5. Test Import

In Claude Code:

```
Import this article into Brainery: https://example.com/article
```

Then query:

```
What are the main points in the article I just imported?
```

## Usage Examples

### Import Web Page
```
Import this technical guide: https://example.com/docker-guide
```

### Import YouTube Video
```
Import the transcript from: https://www.youtube.com/watch?v=VIDEO_ID
```

### Batch Import
```
Import these articles:
1. https://example.com/article1
2. https://example.com/article2
3. https://example.com/article3

Then tell me what the common themes are.
```

### Query Imported Content
```
What are the key concepts discussed in all the articles I imported today?
```

## Documentation

- **[Installation Guide](docs/en/installation.md)** - Complete setup instructions
- **[Usage Examples](docs/en/usage.md)** - Practical workflows and common scenarios
- **[BRAINERY_CONTEXT.md](BRAINERY_CONTEXT.md)** - Technical implementation details

### Other Languages
- **Italiano**: [Installazione](docs/it/installation.md) | [Esempi](docs/it/usage.md)
- **中文**: [安装](docs/zh/installation.md) | [使用示例](docs/zh/usage.md)

## Architecture

Brainery uses a modular architecture with 4 Docker containers:

```
┌─────────────┐
│ Claude Code │
└──────┬──────┘
       │ MCP Tools
       │
       ├──────────────┬──────────────┬──────────────┐
       ▼              ▼              ▼              ▼
  ┌─────────┐   ┌──────────┐   ┌─────────┐   ┌──────────────┐
  │Crawl4AI │   │ yt-dlp   │   │ Whisper │   │ AnythingLLM  │
  │  :9100  │   │  :9101   │   │  :9102  │   │    :9103     │
  └─────────┘   └──────────┘   └─────────┘   └──────────────┘
   Web scraping  YouTube        Audio          RAG Database
                 transcripts    transcription
```

## System Requirements

- **Docker Desktop** 20.10+
- **Docker Compose** 2.0+
- **8GB RAM minimum** (12GB recommended)
- **~13GB disk space** for containers and models

## Port Configuration

Default ports (9100-9103) work out-of-box. To customize, create `.env` file:

```bash
cd brainery-containers
cp .env.example .env
# Edit ports in .env
docker-compose up -d
```

## Troubleshooting

### Containers Not Running
```bash
docker ps --filter "name=brainery-"
docker-compose restart <service-name>
```

### AnythingLLM "Unauthorized"
Verify API key in `.env` file and reinitialize MCP client.

### Import Fails
1. Check container health: `curl http://localhost:9100/health`
2. Verify network connectivity
3. Check logs: `docker-compose logs <service-name>`

See [Installation Guide](docs/en/installation.md) for detailed troubleshooting.

## Repository Structure

- **brainery** (this repo) - Claude Code skill with multilingual docs
- **[brainery-containers](https://github.com/Tapiocapioca/brainery-containers)** - Docker infrastructure with pre-built images on Docker Hub

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create feature branch
3. Test thoroughly
4. Submit pull request

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- **Issues**: [GitHub Issues](https://github.com/Tapiocapioca/brainery/issues)
- **Containers**: [brainery-containers issues](https://github.com/Tapiocapioca/brainery-containers/issues)
- **Documentation**: See [docs/](docs/) for detailed guides

## Version

**Current version**: 1.0.0

See [CHANGELOG.md](CHANGELOG.md) for version history.
