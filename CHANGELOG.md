# Changelog

All notable changes to the Brainery skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-07

### Added
- Initial release of Brainery skill
- Web page import via Crawl4AI with multiple filtering strategies (fit, raw, bm25, llm)
- YouTube transcript extraction via yt-dlp-server
- Audio transcription fallback via Whisper
- PDF import support for URL-accessible documents
- Local RAG database integration with AnythingLLM
- Docker-based infrastructure with 4 pre-built containers
- Multilingual documentation (English, Italian, Chinese)
- Comprehensive installation guide
- Practical usage examples for common workflows
- MCP tool integration for seamless Claude Code usage
- Workspace organization support
- Content verification and error handling
- Port customization via .env file

### Documentation
- English: Installation guide, usage examples, README
- Italian: Guida installazione, esempi d'uso, README
- Chinese: 安装指南, 使用示例, README
- Technical implementation details in BRAINERY_CONTEXT.md
- Skill prompt with workflow instructions

### Infrastructure
- Pre-built Docker images on Docker Hub (tapiocapioca/*)
- Automated CI/CD with GitHub Actions
- Port range 9100-9103 for minimal conflicts
- RAM-based temporary caches for performance
- Persistent volumes for RAG data and Whisper models

## [Unreleased]

### Planned
- Support for local PDF file import without URL
- Batch document management tools
- Advanced filtering configuration
- Integration with additional LLM providers
- Performance optimization for large documents

---

## Version Links

[1.0.0]: https://github.com/Tapiocapioca/brainery/releases/tag/v1.0.0
