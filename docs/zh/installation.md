# 安装指南

Brainery 技能和容器的完整安装说明。

## 系统要求

- **Docker Desktop**（版本 20.10+）
- **Docker Compose**（版本 2.0+）
- **Git** 用于克隆仓库
- **最低 8GB 内存**（推荐 12GB）
- **约 13GB 磁盘空间** 用于容器和模型

### Windows 特定要求
- 启用 WSL 2 后端的 Docker Desktop
- Git Bash 或 PowerShell

### Linux/macOS
- 通过包管理器安装 Docker 和 Docker Compose

## 步骤 1：安装 Docker 容器

克隆 brainery-containers 仓库：

```bash
git clone https://github.com/Tapiocapioca/brainery-containers.git
cd brainery-containers
```

启动所有容器：

```bash
docker-compose up -d
```

这将从 Docker Hub 拉取预构建的镜像：
- `tapiocapioca/crawl4ai:latest`
- `tapiocapioca/yt-dlp-server:latest`
- `tapiocapioca/whisper-server:latest`
- `tapiocapioca/anythingllm:latest`

**首次启动需要 2-5 分钟** 来下载镜像和初始化。

## 步骤 2：验证容器

检查所有容器是否正在运行：

```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

预期输出：
```
NAMES                     STATUS          PORTS
brainery-anythingllm-1    Up 2 minutes    0.0.0.0:9103->3001/tcp
brainery-whisper-server-1 Up 2 minutes    0.0.0.0:9102->8502/tcp
brainery-yt-dlp-server-1  Up 2 minutes    0.0.0.0:9101->8501/tcp
brainery-crawl4ai-1       Up 2 minutes    0.0.0.0:9100->11235/tcp
```

测试健康检查端点：

```bash
curl http://localhost:9100/health   # crawl4ai
curl http://localhost:9101/health   # yt-dlp-server
curl http://localhost:9102/health   # whisper-server
curl http://localhost:9103/api/ping # anythingllm
```

所有端点应返回 `{"status":"ok"}` 或类似的成功响应。

## 步骤 3：配置 AnythingLLM

打开 AnythingLLM 网页界面：

```
http://localhost:9103
```

### 首次设置

1. **创建管理员账户**
   - 用户名：自定义
   - 密码：自定义（本地保存）

2. **配置 LLM 提供商**
   - 导航到：设置 → LLM 偏好
   - 选择有免费套餐的提供商（推荐：**iFlow Platform**）
   - 添加 API 凭据

#### iFlow Platform 设置（推荐）

1. 注册：https://iflow.cn/oauth?redirect=https%3A%2F%2Fvibex.iflow.cn%2Fsession%2Fsso_login
2. 从仪表板获取 API 密钥
3. 在 AnythingLLM 中：
   - 提供商：`OpenAI Compatible`
   - Base URL：`https://vibex.iflow.cn/v1`
   - 模型：`glm-4.6`
   - API Key：`<你的密钥>`

**模型优势：**
- 免费套餐：200K 上下文令牌
- 良好的多语言支持（EN/IT/ZH）
- 快速响应时间

3. **创建工作区**
   - 点击"新建工作区"
   - 名称：`brainery`（或自定义）
   - 保存工作区 slug 以供后续使用

4. **获取 API 密钥**
   - 导航到：设置 → API 密钥
   - 点击"生成新 API 密钥"
   - 复制密钥

5. **保存 API 密钥到环境变量**

编辑 `brainery-containers` 目录中的 `.env` 文件：

```bash
ANYTHINGLLM_API_KEY=你的-api-密钥
```

或添加到 Claude Code 的 CLAUDE.md：

```markdown
## AnythingLLM 配置

API Key: 你的-api-密钥
Workspace: brainery
```

## 步骤 4：安装 MCP 服务器

MCP（模型上下文协议）服务器使 Claude Code 能够与 Docker 容器交互。安装所需的服务器：

### 安装 AnythingLLM MCP 服务器（自定义 Fork）

我们使用具有附加功能的自定义 fork：

```bash
npx -y @smithery/cli install @tapiocapioca/anythingllm-mcp-server --client claude
```

**为什么使用自定义 fork？**
- 我们的 fork：https://github.com/Tapiocapioca/anythingllm-mcp-server
- 基于：https://github.com/Lifeforge-app/anythingllm-mcp-server
- 包含 Brainery 工作流的修复和增强

### 安装其他 MCP 服务器

```bash
# Crawl4AI 服务器
npx -y @smithery/cli install crawl4ai --client claude

# yt-dlp 服务器
npx -y @smithery/cli install yt-dlp --client claude
```

### 验证 MCP 安装

在 Claude Code 中检查已安装的 MCP 服务器：

```bash
cat ~/.claude/config.json
```

查找类似的条目：
```json
{
  "mcpServers": {
    "anythingllm-mcp-server": { ... },
    "crawl4ai": { ... },
    "yt-dlp": { ... }
  }
}
```

**MCP 安装故障排除：**
- 如果 `@smithery/cli` 失败，手动安装：`npm install -g @smithery/cli`
- 安装 MCP 服务器后重启 Claude Code
- 检查 MCP 服务器日志：`~/.claude/logs/mcp-*.log`

## 步骤 5：安装 Brainery 技能

### 选项 A：手动安装

1. 克隆 brainery 技能仓库：

```bash
cd ~/.claude/skills  # 或你的技能目录
git clone https://github.com/Tapiocapioca/brainery.git
```

2. 重启 Claude Code 以加载技能

### 选项 B：通过 Claude Code 插件系统

在 Claude Code 中运行：

```
/install-skill https://github.com/Tapiocapioca/brainery
```

## 步骤 6：验证安装

在 Claude Code 中测试完整工作流：

1. **导入网页：**
   ```
   将这篇文章导入 Brainery：https://example.com/article
   ```

2. **查询内容：**
   ```
   我刚导入的文章的主要观点是什么？
   ```

如果两者都正常工作，安装完成！

## 故障排除

### 容器无法启动

**问题：** `docker-compose up -d` 失败

**解决方案：**
1. 检查 Docker Desktop 是否正在运行
2. 确保没有端口冲突（9100-9103）
3. 检查日志：`docker-compose logs <服务名>`

### AnythingLLM 显示 "Unauthorized"

**问题：** API 调用返回 401 错误

**解决方案：**
1. 验证 `.env` 文件中的 API 密钥
2. 在 AnythingLLM 设置中重新生成 API 密钥
3. 初始化 MCP 客户端：
   ```
   mcp__anythingllm__initialize_anythingllm
     apiKey: "你的密钥"
     baseUrl: "http://localhost:9103"
   ```

### 端口已被占用

**问题：** 容器失败并显示 "port already allocated"

**解决方案：**
1. 查找占用端口的进程：`netstat -ano | findstr :9100`（Windows）
2. 终止进程或在 `.env` 文件中更改端口：
   ```
   CRAWL4AI_PORT=9200
   YT_DLP_PORT=9201
   WHISPER_PORT=9202
   ANYTHINGLLM_PORT=9203
   ```

### Whisper 模型未下载

**问题：** 音频转录失败

**解决方案：**
模型在首次使用时自动下载。等待 2-3 分钟完成下载。

检查日志：`docker-compose logs whisper-server`

## 端口自定义

默认端口（9100-9103）适用于大多数用户。自定义端口：

1. 复制示例环境文件：
   ```bash
   cp .env.example .env
   ```

2. 使用你偏好的端口编辑 `.env`：
   ```
   CRAWL4AI_PORT=9100
   YT_DLP_PORT=9101
   WHISPER_PORT=9102
   ANYTHINGLLM_PORT=9103
   ```

3. 重启容器：
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## 更新

### 更新容器

拉取最新镜像：

```bash
cd brainery-containers
docker-compose pull
docker-compose up -d
```

### 更新技能

```bash
cd ~/.claude/skills/brainery
git pull origin main
```

## 卸载

### 删除容器

```bash
cd brainery-containers
docker-compose down -v  # -v 删除卷（会删除 RAG 数据！）
```

### 删除技能

```bash
rm -rf ~/.claude/skills/brainery
```

## 下一步

查看 [使用示例](usage.md) 了解实际工作流和常见场景。
