# 使用示例

Brainery 常见工作流的实用示例。

## 先决条件

确保容器正在运行且 AnythingLLM 已配置：

```bash
docker ps --filter "name=brainery-" --format "table {{.Names}}\t{{.Status}}"
curl http://localhost:9103/api/ping
```

## 示例 1：导入网页文章

**场景：** 将技术博客文章导入 Brainery 以供日后参考。

### 步骤 1：导入文章

在 Claude Code 中：

```
将这篇文章导入 Brainery：https://example.com/blog/docker-best-practices
```

Claude 将使用：
```
mcp__crawl4ai__md
  url: "https://example.com/blog/docker-best-practices"
  f: "fit"

mcp__anythingllm__embed_webpage
  slug: "brainery"
  url: "https://example.com/blog/docker-best-practices"
```

### 步骤 2：查询内容

```
我刚导入的文章中提到的前 3 个 Docker 最佳实践是什么？
```

Claude 将使用：
```
mcp__anythingllm__chat_with_workspace
  slug: "brainery"
  message: "前 3 个 Docker 最佳实践是什么？"
  mode: "query"
```

**结果：** Claude 从导入的文章中检索相关部分并总结关键实践。

---

## 示例 2：导入 YouTube 视频转录

**场景：** 从教育 YouTube 视频中提取并保存转录。

### 步骤 1：导入转录

```
导入此视频的转录：https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Claude 将：
1. 提取转录：`mcp__yt-dlp__ytdlp_download_transcript`
2. 嵌入 AnythingLLM：`mcp__anythingllm__embed_text`

### 步骤 2：查询内容

```
总结我刚导入的视频转录中涵盖的主要主题。
```

**结果：** Claude 根据转录内容提供结构化摘要。

---

## 示例 3：批量导入多篇文章

**场景：** 导入同一主题的多篇相关文章。

```
将这些文章导入 Brainery：
1. https://example.com/kubernetes-intro
2. https://example.com/kubernetes-networking
3. https://example.com/kubernetes-security

然后告诉我所有三篇文章的共同主题是什么。
```

Claude 将：
1. 依次导入每篇文章
2. 使用单个 RAG 查询所有导入的内容
3. 分析文档之间的共同主题

**优势：** 所有三篇文章可以一起搜索，实现跨文档分析。

---

## 示例 4：PDF 导入

**场景：** 导入研究论文 PDF 进行分析。

### 如果 PDF 可通过 URL 访问：

```
导入这篇研究论文：https://arxiv.org/pdf/2301.12345.pdf
```

Claude 将使用 Crawl4AI 提取文本并嵌入。

### 如果 PDF 在本地：

1. **将 PDF 转换为文本**（一次性设置）：
   ```bash
   pdftotext document.pdf document.txt
   ```

2. **上传到临时 URL** 或使用 AnythingLLM 的网页界面文档上传功能

3. **查询内容**：
   ```
   我上传的研究论文的主要结论是什么？
   ```

---

## 示例 5：本地音频文件导入

**场景：** 转录并导入本地计算机上的播客剧集或会议录音。

### 步骤 1：准备音频文件

确保您的音频文件格式受支持（MP3、WAV、M4A、OGG、FLAC、WEBM）。

### 步骤 2：使用 Whisper 转录

```
转录这个本地音频文件：/home/user/podcasts/episode-123.mp3
```

Claude 将执行：

1. **调用 Whisper 服务器**：
   ```bash
   curl -X POST http://localhost:9102/transcribe \
     -F "audio=@/home/user/podcasts/episode-123.mp3" \
     -F "language=auto" \
     -F "model=base"
   ```

2. **从 JSON 响应中提取转录文本**

3. **嵌入到 AnythingLLM**：
   ```
   mcp__anythingllm__embed_text
     slug: "brainery"
     texts: ["<转录文本>"]
   ```

### 步骤 3：查询内容

```
我刚导入的播客剧集中讨论了哪些关键主题？
```

**结果：** Claude 检索转录文本并总结主要讨论要点。

### 提示

- **对于长文件（>30 分钟）**：使用 `model=tiny` 以加快处理速度，然后使用 `model=base` 或 `model=small` 重新转录重要部分
- **语言检测**：如果不确定，使用 `language=auto`，或明确指定（`en`、`it`、`zh`）
- **文件路径**：使用绝对路径（例如 `/home/user/file.mp3`）或相对于 Claude Code 工作目录的路径

**常见用例：**
- 研究用播客剧集
- 笔记用会议录音
- 分析用访谈转录
- 个人知识库用语音备忘录

---

## 示例 6：创建特定主题工作区

**场景：** 使用单独的工作区按主题组织内容。

### 步骤 1：创建工作区

```
创建一个名为 "machine-learning" 的新 AnythingLLM 工作区
```

Claude 将使用：
```
mcp__anythingllm__create_workspace
  name: "machine-learning"
```

### 步骤 2：将内容导入特定工作区

```
将这篇文章导入 "machine-learning" 工作区：https://example.com/ml-tutorial
```

Claude 在嵌入期间将指定工作区 slug：
```
mcp__anythingllm__embed_webpage
  slug: "machine-learning"
  url: "https://example.com/ml-tutorial"
```

### 步骤 3：查询特定工作区

```
查询 machine-learning 工作区：机器学习的关键概念是什么？
```

**优势：** 内容按主题组织，防止不相关文档之间的交叉污染。

---

## 示例 7：高级内容过滤

**场景：** 从长篇文章中仅提取相关部分。

### 选项 A：BM25 过滤

```
使用 BM25 过滤导入此文章，查询为 "Docker security"：
https://example.com/docker-complete-guide
```

Claude 将使用：
```
mcp__crawl4ai__md
  url: "https://example.com/docker-complete-guide"
  f: "bm25"
  q: "Docker security"
```

### 选项 B：LLM 过滤

```
导入此文章，但仅包含关于性能优化的部分：
https://example.com/web-development-guide
```

Claude 将使用：
```
mcp__crawl4ai__md
  url: "https://example.com/web-development-guide"
  f: "llm"
  q: "performance optimization"
```

**优势：** 减少令牌使用并仅关注相关内容。

---

## 示例 8：验证导入成功

**场景：** 在继续之前确保内容已成功嵌入。

```
导入此文章：https://example.com/article

然后通过询问验证它是否正确导入："我导入的最后一篇文章的标题是什么？"
```

Claude 将：
1. 导入文章
2. 查询 AnythingLLM 以确认内容可检索
3. 报告成功或失败

**最佳实践：** 始终验证导入，特别是对于关键文档。

---

## 示例 9：多语言内容

**场景：** 导入不同语言的内容（英语、意大利语、中文）。

### 英语文章：
```
导入：https://example.com/en/article
```

### 意大利语文章：
```
导入：https://example.com/it/articolo
```

### 中文文章：
```
导入：https://example.com/zh/文章
```

### 用任何语言查询：
```
所有三篇文章的共同主题是什么？（用中文回答）
```

**优势：** Brainery 支持多语言内容。LLM 提供商（例如 iFlow 的 glm-4.6）在查询期间处理翻译。

---

## 示例 10：删除旧内容

**场景：** 从工作区中删除过时的内容。

### 列出文档：
```
显示 brainery 工作区中的所有文档
```

Claude 将使用：
```
mcp__anythingllm__list_documents
  slug: "brainery"
```

### 删除特定文档：
```
删除 ID 为 "doc_abc123" 的文档
```

Claude 将使用：
```
mcp__anythingllm__delete_document
  slug: "brainery"
  documentId: "doc_abc123"
```

---

## 示例 10：排查导入失败

**场景：** 由于连接问题导入失败。

### 错误消息：
```
Error: Failed to connect to http://localhost:9100
```

### 解决方案：
1. **检查容器状态：**
   ```bash
   docker ps --filter "name=brainery-crawl4ai"
   ```

2. **如有必要重启容器：**
   ```bash
   docker-compose restart crawl4ai
   ```

3. **重试导入：**
   ```
   导入：https://example.com/article
   ```

---

## 常见模式

### 模式 1：导入 → 验证 → 查询

```
1. 导入内容
2. 验证："我导入的最后一篇文章是什么？"
3. 查询："关键点是什么？"
```

### 模式 2：批量导入 → 聚合查询

```
1. 导入多篇相关文章
2. 查询："所有文章的共同主题是什么？"
```

### 模式 3：工作区组织

```
1. 创建特定主题工作区
2. 将所有相关内容导入该工作区
3. 查询工作区以获得聚焦结果
```

---

## 技巧和最佳实践

1. **对大多数网页使用 `f: "fit"`** - 提取干净、相关的内容，不包含广告/导航

2. **验证导入** - 导入关键文档后始终使用简单查询进行测试

3. **按工作区组织** - 将不相关的主题分隔到不同的工作区

4. **清理 URL** - 导入前删除跟踪参数：
   ```
   ❌ https://example.com/article?utm_source=twitter&ref=123
   ✅ https://example.com/article
   ```

5. **检查速率限制** - 如果遇到 429 错误，等待 60 秒后重试

6. **使用 mode: "query"** - RAG 查询始终使用 `mode: "query"`，而非 `mode: "chat"`

---

## 下一步

- 查看 [安装指南](installation.md) 获取设置说明
- 查看 [BRAINERY_CONTEXT.md](../../BRAINERY_CONTEXT.md) 了解高级配置
- 访问 [brainery-containers](https://github.com/Tapiocapioca/brainery-containers) 查看容器文档
