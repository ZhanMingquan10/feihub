# FeiHub 项目文档

## 项目概述

FeiHub 是一个飞书文档分享平台，允许用户分享飞书文档链接，系统自动爬取文档内容并生成 AI 摘要和标签。

## 技术栈

### 前端
- **框架**: React + TypeScript
- **构建工具**: Vite
- **UI 库**: Tailwind CSS
- **状态管理**: Zustand
- **动画**: Framer Motion
- **图标**: Lucide React
- **HTTP 客户端**: TanStack Query (React Query)

### 后端
- **运行时**: Node.js
- **框架**: Express
- **数据库**: PostgreSQL (通过 Prisma ORM)
- **爬虫**: Puppeteer (puppeteer-core)
- **AI 服务**: DeepSeek API
- **进程管理**: PM2

### 部署
- **服务器**: 阿里云 ECS
- **Web 服务器**: Nginx (宝塔面板)
- **域名**: feihub.top
- **IP**: 121.40.214.130

## 项目结构

```
feihub/
├── src/                    # 前端源码
│   ├── App.tsx            # 主应用组件
│   ├── components/        # React 组件
│   │   └── ModalShell.tsx # 模态框组件
│   ├── store/             # Zustand 状态管理
│   │   └── useDocumentStore.ts
│   ├── utils/             # 工具函数
│   │   └── highlightKeyword.ts
│   ├── hooks/             # 自定义 Hooks
│   │   └── useAntiScrapeShield.ts
│   └── types/             # TypeScript 类型定义
├── backend/               # 后端源码
│   ├── src/
│   │   ├── index.ts       # 入口文件
│   │   ├── lib/
│   │   │   └── feishu-puppeteer.ts  # 飞书爬虫
│   │   └── services/     # 业务服务
│   ├── ecosystem.config.js # PM2 配置
│   └── .env              # 环境变量
├── dist/                  # 前端构建输出
└── public/                # 静态资源
```

## 关键功能

### 1. 文档分享
- 用户提交飞书文档链接
- 系统自动爬取文档内容（标题、正文、日期、作者）
- AI 生成摘要和标签
- 支持关键词高亮

### 2. 文档展示
- 文档列表展示（支持搜索、排序）
- 10 行内容预览（使用 WebkitLineClamp）
- AI 速读功能（双角度摘要）
- 热门关键词展示

### 3. 响应式设计
- PC 端和移动端适配
- 移动端优化（缩小间距、字体、热搜词只显示 3 个）
- 滚动折叠特效（分享按钮）

### 4. 主题切换
- 深色模式和浅色模式
- 优化的颜色对比度

## 部署信息

### 服务器路径
- **项目根目录**: `/www/wwwroot/feihub`
- **前端构建目录**: `/www/wwwroot/feihub/dist`
- **后端目录**: `/www/wwwroot/feihub/backend`
- **Nginx 配置**: `/www/server/panel/vhost/nginx/feihub.top.conf`
- **默认 server 配置**: `/www/server/panel/vhost/nginx/0.default.conf`

### 服务管理
- **后端服务**: PM2 (`feihub-backend`)
- **Web 服务器**: Nginx
- **进程管理**: `pm2 start/stop/restart feihub-backend`

### 端口配置
- **前端**: 80 (HTTP)
- **后端 API**: 4000
- **宝塔面板**: 8888

## 环境变量

### 后端 (.env)
```env
PORT=4000
DATABASE_URL=postgresql://...
DEEPSEEK_API_KEY=...
CORS_ORIGIN=http://121.40.214.130,https://feihub.top,http://feihub.top
```

## Nginx 配置要点

### feihub.top.conf
- **root**: `/www/wwwroot/feihub/dist`
- **API 代理**: `location /api/` → `http://127.0.0.1:4000/api/`
- **静态资源**: `/assets/` 和文件扩展名匹配
- **SPA 路由**: `try_files $uri $uri/ /index.html;`

### 0.default.conf (默认 server)
- 用于通过 IP 访问的情况
- 配置与 feihub.top.conf 相同

## 常见问题与解决方案

### 1. 服务器重启后服务未启动
```bash
# 启动宝塔
systemctl start bt

# 启动后端
cd /www/wwwroot/feihub/backend
pm2 start ecosystem.config.js
pm2 save

# 启动 Nginx
systemctl start nginx
```

### 2. 403 Forbidden
- 检查文件权限: `chown -R www:www /www/wwwroot/feihub`
- 检查 dist 目录是否存在: `ls -la /www/wwwroot/feihub/dist`
- 如果不存在，重新构建: `cd /www/wwwroot/feihub && npm run build`

### 3. API 404 错误
- 检查后端服务: `pm2 list`
- 检查后端端口: `netstat -tuln | grep 4000`
- 检查 Nginx 代理配置: `grep -A 10 "location /api" /www/server/panel/vhost/nginx/feihub.top.conf`

### 4. 空白页面
- 检查静态资源权限
- 检查 Nginx 配置中的静态资源 location
- 检查浏览器控制台错误

### 5. 内容爬取不完整
- 检查 Puppeteer 滚动逻辑
- 检查页面高度变化
- 查看后端日志: `pm2 logs feihub-backend`

## 开发历史

### 主要里程碑
1. **初始开发**: TypeScript 配置、基础功能实现
2. **内容爬取优化**: 多次优化 Puppeteer 滚动和内容提取
3. **日期解析修复**: 修复英文日期格式解析问题
4. **UI/UX 优化**: 深色/浅色模式、响应式设计
5. **移动端优化**: 间距、字体、热搜词显示
6. **服务器重启恢复**: 修复服务自启动、Nginx 配置

### 关键修复
- **日期解析**: 修复 "Modified January 9, 2024" 等格式
- **内容提取**: 实现滚动容器检测和完整内容提取
- **关键词高亮**: 实现 React 组件中的关键词高亮
- **Nginx 配置**: 修复默认 server 块，支持 IP 访问

## 后续优化建议

1. **性能优化**
   - 前端代码分割
   - 图片懒加载
   - API 响应缓存

2. **功能增强**
   - 用户系统
   - 文档收藏
   - 评论功能
   - 搜索优化

3. **监控与日志**
   - 错误监控
   - 性能监控
   - 访问统计

4. **安全加固**
   - API 限流
   - 输入验证
   - XSS 防护

## 联系方式

- **GitHub**: [项目仓库地址]
- **域名**: https://feihub.top
- **服务器**: 121.40.214.130

## 更新日志

### 2025-12-02
- 修复服务器重启后的服务恢复
- 修复 Nginx 配置，支持 IP 访问
- 修复 vite.svg 404 错误
- 统一线上、本地、GitHub 版本

---

**最后更新**: 2025-12-02
**文档维护者**: AI Assistant

