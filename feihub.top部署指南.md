# FeiHub 部署指南 - feihub.top

## 📋 当前环境
- 服务器：阿里云 ECS
- 应用镜像：宝塔Linux面板 9.2.0（阿里云专享版）
- 系统：Ubuntu 24.04
- 域名：feihub.top

---

## 🚀 第一步：获取服务器信息

### 1.1 获取服务器IP和密码
1. 登录阿里云控制台
2. 进入"云服务器ECS" → "实例"
3. 找到你的服务器，记录：
   - **公网IP地址**
   - **root密码**（如果忘记了，可以重置）

### 1.2 获取宝塔面板信息
1. 在阿里云控制台，点击服务器右侧"远程连接"
2. 选择"Workbench远程连接"
3. 在终端执行：
   ```bash
   bt default
   ```
4. 会显示：
   - 宝塔面板地址（如：`http://your-ip:8888`）
   - 用户名
   - 密码

---

## 🌐 第二步：配置域名解析

### 2.1 在阿里云配置域名解析
1. 登录阿里云控制台
2. 进入"域名" → "域名列表"
3. 找到 `feihub.top`，点击"解析"
4. 点击"添加记录"
5. 配置：
   - **记录类型**：A
   - **主机记录**：@（或 www，如果要支持 www.feihub.top）
   - **记录值**：你的服务器公网IP
   - **TTL**：10分钟（默认）
6. 点击"确认"
7. 如果也要支持 www 访问，再添加一条：
   - **记录类型**：A
   - **主机记录**：www
   - **记录值**：你的服务器公网IP

---

## 🔐 第三步：登录宝塔面板

1. **访问宝塔面板**
   - 在浏览器打开：`http://your-ip:8888`
   - 使用 `bt default` 显示的用户名和密码登录

2. **首次登录设置**
   - 如果提示绑定手机号，可以绑定（可选）
   - 如果提示安装LNMP，先跳过（我们稍后手动安装需要的软件）

---

## 📦 第四步：安装必要软件

### 4.1 安装 Node.js
1. 在宝塔面板，点击左侧"软件商店"
2. 搜索"Node.js版本管理器"
3. 点击"安装"
4. 安装完成后，点击"设置"
5. 选择 Node.js 18.x 或 20.x 版本，点击"安装"
6. 等待安装完成

### 4.2 安装 PostgreSQL
1. 在"软件商店"搜索"PostgreSQL"
2. 点击"安装"，选择最新版本（建议 15.x 或 16.x）
3. 等待安装完成

### 4.3 安装 Redis
1. 在"软件商店"搜索"Redis"
2. 点击"安装"，选择最新版本
3. 等待安装完成

### 4.4 安装 PM2（进程管理器）
1. 点击左侧"终端"
2. 执行：
   ```bash
   npm install -g pm2
   ```

---

## 🗄️ 第五步：创建数据库

1. **在宝塔面板创建数据库**
   - 点击左侧"数据库"
   - 点击"PostgreSQL"
   - 点击"添加数据库"
   - 填写：
     - **数据库名**：`feihub`
     - **用户名**：`feihub_user`
     - **密码**：设置一个强密码（**记住这个密码！**）
   - 点击"提交"

2. **记录数据库信息**
   - 数据库地址：`localhost` 或 `127.0.0.1`
   - 端口：`5432`
   - 数据库名：`feihub`
   - 用户名：`feihub_user`
   - 密码：你刚才设置的密码

---

## 📁 第六步：上传项目代码

### 方式一：使用宝塔文件管理器（推荐）

1. **创建项目目录**
   - 点击左侧"文件"
   - 进入 `/www/wwwroot/`
   - 点击"新建文件夹"，命名为 `feihub`
   - 进入 `feihub` 文件夹

2. **上传代码**
   - 在本地，将整个 `feihub` 项目文件夹压缩为 zip 文件
   - 在宝塔文件管理器中，点击"上传"
   - 选择 zip 文件上传
   - 上传完成后，右键 zip 文件 → "解压"
   - 解压后，删除 zip 文件

### 方式二：使用 Git（如果代码在Git仓库）

1. 在宝塔终端执行：
   ```bash
   cd /www/wwwroot/
   git clone https://your-repo-url.git feihub
   cd feihub
   ```

---

## ⚙️ 第七步：配置后端

### 7.1 安装后端依赖
在宝塔终端执行：
```bash
cd /www/wwwroot/feihub/backend
npm install --production
```

### 7.2 配置环境变量
1. 在宝塔文件管理器中，进入 `/www/wwwroot/feihub/backend`
2. 创建 `.env` 文件（如果不存在）
3. 编辑 `.env` 文件，添加以下内容：
   ```env
   # 服务器配置
   PORT=4000
   NODE_ENV=production

   # 数据库配置（使用第五步创建的数据库信息）
   DATABASE_URL=postgresql://feihub_user:你的数据库密码@localhost:5432/feihub

   # Redis 配置
   REDIS_URL=redis://localhost:6379

   # AI API 配置（必须配置其中一个）
   DEEPSEEK_API_KEY=your_deepseek_api_key
   # 或
   # OPENAI_API_KEY=your_openai_api_key

   # CORS 配置（你的域名）
   CORS_ORIGIN=https://feihub.top

   # 客服图片URL（可选，如果使用CDN）
   # CUSTOMER_SERVICE_IMAGE_URL=https://your-cdn.com/kefu.png
   ```

### 7.3 运行数据库迁移
在宝塔终端执行：
```bash
cd /www/wwwroot/feihub/backend
npx prisma generate
npx prisma migrate deploy
```

### 7.4 构建后端
```bash
npm run build
```

### 7.5 使用 PM2 启动后端
```bash
# 创建日志目录
mkdir -p logs

# 启动服务
pm2 start ecosystem.config.js

# 保存配置
pm2 save

# 设置开机自启
pm2 startup
# 执行上面命令后，会显示一行命令，复制并执行它
```

### 7.6 验证后端运行
```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs feihub-backend
```

---

## 🎨 第八步：构建和部署前端

### 8.1 安装前端依赖
```bash
cd /www/wwwroot/feihub
npm install
```

### 8.2 配置前端环境变量
1. 在宝塔文件管理器中，进入 `/www/wwwroot/feihub`
2. 创建 `.env.production` 文件
3. 添加以下内容：
   ```env
   VITE_API_BASE=https://feihub.top/api
   # 如果客服图片使用CDN，取消下面的注释
   # VITE_CUSTOMER_SERVICE_IMAGE_URL=https://your-cdn.com/kefu.png
   ```

### 8.3 构建前端
```bash
npm run build
```

### 8.4 上传客服图片
1. 在宝塔文件管理器中，进入 `/www/wwwroot/feihub/dist`
2. 上传 `kefu.png` 文件到这个目录
   - 或者使用 CDN（推荐），然后在 `.env.production` 中配置 URL

---

## 🌐 第九步：配置 Nginx

### 9.1 添加网站
1. 在宝塔面板，点击左侧"网站"
2. 点击"添加站点"
3. 填写：
   - **域名**：`feihub.top`（如果要支持www，可以填写 `feihub.top www.feihub.top`）
   - **根目录**：`/www/wwwroot/feihub/dist`
   - **PHP版本**：纯静态
4. 点击"提交"

### 9.2 配置反向代理
1. 点击网站 `feihub.top` 右侧的"设置"
2. 点击"反向代理" → "添加反向代理"
3. 填写：
   - **代理名称**：`api`
   - **目标URL**：`http://127.0.0.1:4000`
   - **发送域名**：`$host`
4. 点击"提交"

### 9.3 修改 Nginx 配置
1. 在网站设置中，点击"配置文件"
2. 找到 `location /` 部分，修改为：
   ```nginx
   location / {
       try_files $uri $uri/ /index.html;
   }
   ```
3. 在 `location /` 之前添加（如果反向代理没有自动添加）：
   ```nginx
   location /api {
       proxy_pass http://127.0.0.1:4000;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection 'upgrade';
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
       proxy_cache_bypass $http_upgrade;
   }
   ```
4. 点击"保存"

### 9.4 重启 Nginx
1. 点击左侧"服务"
2. 找到 Nginx，点击"重启"

---

## 🔒 第十步：配置 SSL 证书（HTTPS）

### 10.1 申请 SSL 证书
1. 在网站设置中，点击"SSL"
2. 选择"Let's Encrypt"
3. 勾选域名：`feihub.top`（如果添加了www，也勾选）
4. 点击"申请"
5. 等待申请完成（可能需要几分钟）

### 10.2 开启强制 HTTPS
1. 申请成功后，点击"强制HTTPS"
2. 保存配置

### 10.3 更新前端环境变量
1. 编辑 `/www/wwwroot/feihub/.env.production`
2. 确保 API 地址使用 HTTPS：
   ```env
   VITE_API_BASE=https://feihub.top/api
   ```
3. 重新构建前端：
   ```bash
   cd /www/wwwroot/feihub
   npm run build
   ```

---

## 🔥 第十一步：配置防火墙

### 11.1 在宝塔面板配置防火墙
1. 点击左侧"安全"
2. 确保以下端口已开放：
   - ✅ 22（SSH）
   - ✅ 80（HTTP）
   - ✅ 443（HTTPS）
   - ✅ 8888（宝塔面板，建议修改）

### 11.2 在阿里云配置安全组
1. 在阿里云控制台，进入"云服务器ECS" → "实例"
2. 点击你的服务器 → "安全组" → "配置规则"
3. 确保以下端口已开放：
   - ✅ 22（SSH）
   - ✅ 80（HTTP）
   - ✅ 443（HTTPS）
   - ✅ 8888（宝塔面板）

---

## ✅ 第十二步：测试部署

### 12.1 测试访问
1. 在浏览器访问：`https://feihub.top`
2. 检查：
   - ✅ 页面是否正常显示
   - ✅ 是否可以搜索文档
   - ✅ 是否可以提交文档
   - ✅ API 是否正常工作

### 12.2 检查服务状态
在宝塔终端执行：
```bash
# 检查 PM2 服务
pm2 status

# 检查后端日志
pm2 logs feihub-backend --lines 50

# 检查 Nginx 状态
systemctl status nginx

# 检查 PostgreSQL 状态
systemctl status postgresql

# 检查 Redis 状态
systemctl status redis
```

---

## 🔧 常用维护命令

### 查看后端日志
```bash
pm2 logs feihub-backend
```

### 重启后端服务
```bash
pm2 restart feihub-backend
```

### 更新代码后重新部署
```bash
# 1. 上传新代码到 /www/wwwroot/feihub

# 2. 更新后端
cd /www/wwwroot/feihub/backend
npm install --production
npm run build
pm2 restart feihub-backend

# 3. 更新前端
cd /www/wwwroot/feihub
npm install
npm run build
```

### 备份数据库
- 在宝塔面板，点击"数据库" → "PostgreSQL"
- 找到 `feihub` 数据库
- 点击"备份" → "立即备份"

---

## 🚨 常见问题排查

### 1. 无法访问网站
- ✅ 检查域名解析是否正确（ping feihub.top 应该返回服务器IP）
- ✅ 检查 Nginx 是否运行
- ✅ 检查防火墙是否开放 80/443 端口
- ✅ 检查阿里云安全组是否开放端口

### 2. API 请求失败（404 或 500）
- ✅ 检查后端服务是否运行：`pm2 status`
- ✅ 检查后端日志：`pm2 logs feihub-backend`
- ✅ 检查 Nginx 反向代理配置
- ✅ 检查 `.env` 文件配置是否正确

### 3. 数据库连接失败
- ✅ 检查 PostgreSQL 是否运行
- ✅ 检查 `.env` 中的 `DATABASE_URL` 是否正确
- ✅ 检查数据库用户权限

### 4. SSL 证书申请失败
- ✅ 确保域名已正确解析到服务器IP
- ✅ 确保 80 端口已开放
- ✅ 等待几分钟后重试

---

## 📝 部署检查清单

- [ ] 服务器已购买并配置
- [ ] 域名已解析到服务器IP
- [ ] 宝塔面板已登录
- [ ] Node.js 已安装
- [ ] PostgreSQL 已安装并创建数据库
- [ ] Redis 已安装并运行
- [ ] PM2 已安装
- [ ] 项目代码已上传
- [ ] 后端环境变量已配置
- [ ] 数据库迁移已执行
- [ ] 后端服务已启动（PM2）
- [ ] 前端代码已构建
- [ ] Nginx 已配置网站和反向代理
- [ ] SSL 证书已申请
- [ ] 防火墙已配置
- [ ] 测试访问正常

---

## 🎉 部署完成！

部署完成后，访问 `https://feihub.top` 即可使用 FeiHub！

---

## 📞 需要帮助？

如果遇到问题，请提供：
1. 具体的错误信息
2. 后端日志：`pm2 logs feihub-backend`
3. Nginx 错误日志（在宝塔面板网站设置中查看）


