# FeiHub Backend API

FeiHub 后端服务，负责文档处理、AI内容生成和数据库管理。

## 技术栈

- **Node.js + Express + TypeScript** - 后端框架
- **PostgreSQL** - 数据库（支持百万级数据）
- **Prisma** - ORM（类型安全）
- **DeepSeek API / OpenAI API** - AI内容生成（优先使用 DeepSeek，性价比更高）
- **Bull + Redis** - 异步任务队列
- **Cheerio** - HTML解析（爬取飞书文档）

## 功能特性

1. ✅ 文档链接提交和验证
2. ✅ 飞书文档内容提取
3. ✅ AI生成标签和摘要（2句话总结）
4. ✅ 异步任务处理（避免阻塞）
5. ✅ 文档搜索和排序
6. ✅ 统计信息API

## 快速开始

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env` 并填写：

```bash
cp .env.example .env
```

**必须配置：**
- `DATABASE_URL` - PostgreSQL数据库连接
- `DEEPSEEK_API_KEY` 或 `OPENAI_API_KEY` - AI API密钥（优先使用 DeepSeek）
- `REDIS_URL` - Redis连接（用于任务队列）

**AI API 配置说明：**
- 系统优先使用 `DEEPSEEK_API_KEY`（如果已配置）
- 如果未配置 DeepSeek，则使用 `OPENAI_API_KEY` 作为备用
- API KEY 仅存储在服务端，前端无法访问，确保安全

### 3. 设置数据库

```bash
# 生成Prisma客户端
npm run db:generate

# 运行数据库迁移
npm run db:migrate
```

### 4. 启动服务

```bash
# 开发模式（自动重启）
npm run dev

# 生产模式
npm run build
npm start
```

## API 接口

### 提交文档

```http
POST /api/submissions
Content-Type: application/json

{
  "link": "https://feishu.cn/docx/..."
}
```

响应：
```json
{
  "success": true,
  "message": "文档已提交，正在处理中",
  "submissionId": "uuid"
}
```

### 查询提交状态

```http
GET /api/submissions/:id
```

### 获取文档列表

```http
GET /api/documents?search=关键词&sort=latest&page=1&limit=10
```

### 获取统计信息

```http
GET /api/documents/stats/summary
```

## 数据库结构

### Document 表
- `id` - UUID主键
- `title` - 标题
- `author` - 作者
- `link` - 文档链接（唯一）
- `preview` - 预览内容
- `date` - 更新时间
- `views` - 查看次数
- `tags` - 标签数组
- `aiSummary` - AI生成的摘要

### DocumentSubmission 表
- `id` - UUID主键
- `link` - 提交的链接
- `status` - 状态（pending/processing/completed/failed）
- `documentId` - 关联的文档ID

## 性能优化

1. **数据库索引**：已为常用查询字段添加索引
2. **全文搜索**：PostgreSQL全文搜索支持
3. **异步处理**：AI任务通过队列异步处理，不阻塞API
4. **连接池**：Prisma自动管理数据库连接池

## 注意事项

1. **飞书文档访问**：需要文档设置为公开访问才能爬取内容
2. **AI API限制**：注意OpenAI API的速率限制和成本
3. **Redis必需**：任务队列需要Redis，确保Redis服务运行
4. **数据量**：PostgreSQL已优化支持百万级数据

## 部署建议

1. 使用Docker部署PostgreSQL和Redis
2. 使用PM2或类似工具管理Node进程
3. 配置Nginx反向代理
4. 设置环境变量和密钥管理

