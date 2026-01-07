# Brainery

用于将网页内容、YouTube 视频和 PDF 导入本地 RAG 系统的 Claude Code 技能。

[🇬🇧 English](README.md) | [🇮🇹 Italiano](README.it.md)

## 概述

Brainery 使 Claude Code 能够使用 AnythingLLM 作为本地 RAG（检索增强生成）数据库导入和查询网页内容。导入文章、YouTube 转录和 PDF，然后使用自然语言查询它们。

**主要功能：**
- 🌐 **网页抓取** 与干净的 markdown 提取（Crawl4AI）
- 📺 **YouTube 转录** 自动回退到音频转录（yt-dlp + Whisper）
- 📄 **PDF 导入** 带文本提取
- 🧠 **本地 RAG 数据库** 用于私有、离线内容查询（AnythingLLM）
- 🐳 **基于 Docker** 的基础设施，带预构建镜像
- 🌍 **多语言** 文档（EN/IT/ZH）

## 快速开始

### 1. 安装 Docker 容器

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
docker-compose up -d
```

**容器栈：**
- **crawl4ai**（端口 9100）- 网页抓取
- **yt-dlp-server**（端口 9101）- YouTube 转录
- **whisper-server**（端口 9102）- 音频转录
- **anythingllm**（端口 9103）- RAG 数据库

### 2. 配置 AnythingLLM

打开 http://localhost:9103 并：
1. 创建管理员账户
2. 配置 LLM 提供商（推荐：iFlow Platform 与 glm-4.6 模型）
3. 创建工作区（例如 "brainery"）
4. 在设置 → API 密钥中生成 API 密钥

### 3. 安装技能

```bash
cd ~/.claude/skills
git clone https://github.com/Tapiocapioca/brainery.git
```

重启 Claude Code 以加载技能。

### 4. 测试导入

在 Claude Code 中：

```
将这篇文章导入 Brainery：https://example.com/article
```

然后查询：

```
我刚导入的文章的主要观点是什么？
```

## 使用示例

### 导入网页
```
导入这个技术指南：https://example.com/docker-guide
```

### 导入 YouTube 视频
```
导入此视频的转录：https://www.youtube.com/watch?v=VIDEO_ID
```

### 批量导入
```
导入这些文章：
1. https://example.com/article1
2. https://example.com/article2
3. https://example.com/article3

然后告诉我共同的主题是什么。
```

### 查询导入的内容
```
我今天导入的所有文章中讨论的关键概念是什么？
```

## 文档

- **[安装指南](docs/zh/installation.md)** - 完整设置说明
- **[使用示例](docs/zh/usage.md)** - 实际工作流和常见场景
- **[BRAINERY_CONTEXT.md](BRAINERY_CONTEXT.md)** - 技术实现细节

### 其他语言
- **English**: [Installation](docs/en/installation.md) | [Usage](docs/en/usage.md)
- **Italiano**: [Installazione](docs/it/installation.md) | [Esempi](docs/it/usage.md)

## 架构

Brainery 使用模块化架构，包含 4 个 Docker 容器：

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
   网页抓取      YouTube        音频转录        RAG 数据库
                转录
```

## 系统要求

- **Docker Desktop** 20.10+
- **Docker Compose** 2.0+
- **最低 8GB 内存**（推荐 12GB）
- **约 13GB 磁盘空间** 用于容器和模型

## 端口配置

默认端口（9100-9103）开箱即用。要自定义，创建 `.env` 文件：

```bash
cd brainery-containers
cp .env.example .env
# 在 .env 中编辑端口
docker-compose up -d
```

## 故障排除

### 容器未运行
```bash
docker ps --filter "name=brainery-"
docker-compose restart <服务名>
```

### AnythingLLM "Unauthorized"
验证 `.env` 文件中的 API 密钥并重新初始化 MCP 客户端。

### 导入失败
1. 检查容器健康状况：`curl http://localhost:9100/health`
2. 验证网络连接
3. 检查日志：`docker-compose logs <服务名>`

查看 [安装指南](docs/zh/installation.md) 了解详细故障排除。

## 仓库结构

- **brainery**（此仓库）- 带多语言文档的 Claude Code 技能
- **[brainery-containers](https://github.com/Tapiocapioca/brainery-containers)** - Docker 基础设施，在 Docker Hub 上有预构建镜像

## 贡献

欢迎贡献！请：
1. Fork 仓库
2. 创建功能分支
3. 彻底测试
4. 提交 pull request

## 许可证

MIT 许可证 - 查看 [LICENSE](LICENSE) 文件。

## 支持

- **Issues**: [GitHub Issues](https://github.com/Tapiocapioca/brainery/issues)
- **容器**: [brainery-containers issues](https://github.com/Tapiocapioca/brainery-containers/issues)
- **文档**: 查看 [docs/](docs/) 了解详细指南

## 版本

**当前版本**: 1.0.0

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本历史。
