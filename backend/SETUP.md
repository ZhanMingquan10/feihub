# FeiHub 后端完整设置指南

## 📋 前置要求

1. **Node.js** 18+ 
2. **PostgreSQL** 15+ 或使用 Docker
3. **Redis** 7+ 或使用 Docker
4. **DeepSeek API Key**（推荐）或 **OpenAI API Key**（备用）

## 🚀 快速开始

### 方式一：使用 Docker（推荐，最简单）

```bash
# 1. 启动数据库和Redis
cd backend
docker-compose up -d

# 2. 安装依赖
npm install

# 3. 配置环境变量
cp env.example .env
# 编辑 .env 文件，填入你的配置

# 4. 初始化数据库
npm run db:generate
npm run db:migrate

# 5. 启动后端服务
npm run dev
```

### 方式二：本地安装

#### 1. 安装 PostgreSQL

**Windows:**
- 下载安装包：https://www.postgresql.org/download/windows/
- 安装后记住密码

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux:**
```bash
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

创建数据库：
```sql
CREATE DATABASE feihub;
CREATE USER feihub_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE feihub TO feihub_user;
```

#### 2. 安装 Redis

**Windows:**
- 下载：https://github.com/microsoftarchive/redis/releases
- 或使用 WSL

**macOS:**
```bash
brew install redis
brew services start redis
```

**Linux:**
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

#### 3. 配置项目

```bash
cd backend
npm install
cp env.example .env
```

编辑 `.env` 文件：
```env
DATABASE_URL="postgresql://feihub_user:your_password@localhost:5432/feihub?schema=public"
REDIS_URL="redis://localhost:6379"
# 优先使用 DeepSeek（推荐，性价比高）
DEEPSEEK_API_KEY="sk-dff2ea5fca7c4829a3c840b2d597ebbb"
# 或使用 OpenAI（备用）
OPENAI_API_KEY="sk-your-openai-key-here"
```

**注意：** DeepSeek API Key 已预配置，系统会优先使用 DeepSeek。如需使用 OpenAI，请配置 `OPENAI_API_KEY`。

#### 4. 初始化数据库

```bash
npm run db:generate
npm run db:migrate
```

#### 5. 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm run build
npm start
```

## 🔑 配置 AI API Key

### DeepSeek API（推荐，已预配置）

DeepSeek API Key 已配置在 `.env` 文件中：
```env
DEEPSEEK_API_KEY=sk-dff2ea5fca7c4829a3c840b2d597ebbb
```

如需更换或获取新的 API Key：
1. 访问 https://platform.deepseek.com/
2. 注册/登录账号
3. 进入 API Keys 页面创建新的 Key
4. 更新 `.env` 文件中的 `DEEPSEEK_API_KEY`

### OpenAI API（备用）

如需使用 OpenAI API：
1. 访问 https://platform.openai.com/
2. 注册/登录账号
3. 进入 API Keys 页面创建新的 Key
4. 配置到 `.env` 文件的 `OPENAI_API_KEY`

**注意：** 
- 系统优先使用 DeepSeek API（如果已配置）
- 如果未配置 DeepSeek，则使用 OpenAI API
- API Key 仅存储在服务端，前端无法访问，确保安全

## 🧪 测试 API

### 1. 健康检查

```bash
curl http://localhost:4000/health
```

### 2. 提交文档

```bash
curl -X POST http://localhost:4000/api/submissions \
  -H "Content-Type: application/json" \
  -d '{"link": "https://feishu.cn/docx/your-doc-id"}'
```

### 3. 获取文档列表

```bash
curl http://localhost:4000/api/documents
```

## 📊 数据库管理

### 使用 Prisma Studio（可视化工具）

```bash
npm run db:studio
```

访问 http://localhost:5555 查看和编辑数据

### 查看数据库

```bash
# PostgreSQL命令行
psql -U feihub_user -d feihub

# 查看表
\dt

# 查看文档数量
SELECT COUNT(*) FROM "Document";
```

## ⚠️ 常见问题

### 1. 数据库连接失败

- 检查 PostgreSQL 是否运行
- 验证 `.env` 中的 `DATABASE_URL` 是否正确
- 确认数据库用户权限

### 2. Redis 连接失败

- 检查 Redis 是否运行：`redis-cli ping`
- 验证 `REDIS_URL` 配置

### 3. AI API 调用失败

- 检查 API Key 是否正确（DeepSeek 或 OpenAI）
- 确认账户余额充足
- 查看 API 服务状态
- 查看后端日志确认使用的 API 服务

### 4. 飞书文档无法爬取

- 确保文档设置为公开访问
- 检查文档链接格式
- 可能需要使用飞书官方API（需要配置 FEISHU_APP_ID 和 FEISHU_APP_SECRET）

## 🔧 性能优化建议

1. **数据库索引**：已自动创建，支持百万级数据
2. **连接池**：Prisma 自动管理，默认连接数已优化
3. **Redis 持久化**：生产环境建议启用 AOF
4. **AI 请求限流**：考虑使用队列限流，避免超出 API 限制

## 📈 监控建议

1. 使用 PM2 管理 Node 进程
2. 配置日志收集（如 Winston）
3. 监控数据库连接数和查询性能
4. 监控 Redis 内存使用

## 🚢 生产部署

1. 使用环境变量管理敏感信息
2. 配置 HTTPS
3. 使用 Nginx 反向代理
4. 设置数据库备份策略
5. 配置监控和告警

