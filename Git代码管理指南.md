# FeiHub Git 代码管理指南

## 🎯 推荐方案：Git + GitHub

### 为什么使用 Git？
- ✅ 版本控制：记录每次修改，可以回退
- ✅ 代码备份：代码安全存储在云端
- ✅ 协作方便：可以轻松同步代码
- ✅ 部署方便：服务器可以直接从 GitHub 拉取最新代码

---

## 📦 第一步：在本地初始化 Git 仓库

### 1.1 安装 Git（如果还没安装）

**Windows：**
- 下载：https://git-scm.com/download/win
- 安装后，在项目目录右键选择"Git Bash Here"

### 1.2 初始化 Git 仓库

在本地项目目录（`D:\AI+CPS(只做一件事_做好一件事)\13.出海工具站\feihub`）执行：

```bash
# 初始化 Git 仓库
git init

# 创建 .gitignore 文件（排除不需要版本控制的文件）
```

### 1.3 创建 .gitignore 文件

在项目根目录创建 `.gitignore` 文件，内容：

```
# 依赖
node_modules/
backend/node_modules/

# 构建输出
dist/
backend/dist/

# 环境变量（包含敏感信息，不要上传）
.env
.env.local
.env.production
backend/.env

# 日志
*.log
logs/
backend/logs/

# 系统文件
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# 临时文件
*.tmp
*.temp
```

---

## 🚀 第二步：创建 GitHub 仓库

### 2.1 在 GitHub 创建仓库

1. 登录 GitHub（如果没有账号，先注册：https://github.com）
2. 点击右上角 "+" → "New repository"
3. 填写：
   - **Repository name**：`feihub`（或你喜欢的名字）
   - **Description**：FeiHub - 飞书文档知识分享平台
   - **Visibility**：Private（私有，推荐）或 Public（公开）
4. **不要**勾选 "Initialize this repository with a README"（因为我们已有代码）
5. 点击 "Create repository"

### 2.2 获取仓库地址

创建后，GitHub 会显示仓库地址，类似：
```
https://github.com/your-username/feihub.git
```
或
```
git@github.com:your-username/feihub.git
```

---

## 📤 第三步：推送代码到 GitHub

### 3.1 在本地项目目录执行

```bash
# 1. 添加所有文件到 Git
git add .

# 2. 提交代码
git commit -m "Initial commit: FeiHub project"

# 3. 添加远程仓库（替换为你的 GitHub 仓库地址）
git remote add origin https://github.com/your-username/feihub.git

# 4. 推送代码到 GitHub
git branch -M main
git push -u origin main
```

### 3.2 如果遇到认证问题

GitHub 现在要求使用 Personal Access Token：

1. **生成 Token**：
   - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - 点击 "Generate new token"
   - 勾选 `repo` 权限
   - 生成后**复制 Token**（只显示一次）

2. **使用 Token 推送**：
   ```bash
   # 推送时会提示输入用户名和密码
   # 用户名：你的 GitHub 用户名
   # 密码：使用刚才生成的 Token（不是 GitHub 密码）
   ```

---

## 🔄 第四步：服务器从 GitHub 拉取代码

### 4.1 在服务器上安装 Git

在宝塔终端执行：

```bash
apt install git -y
```

### 4.2 克隆代码到服务器

```bash
cd /www/wwwroot/

# 克隆代码（替换为你的 GitHub 仓库地址）
git clone https://github.com/your-username/feihub.git

# 如果仓库是私有的，需要配置认证
# 或者使用 SSH 方式（推荐）
```

### 4.3 配置 SSH 密钥（推荐，用于私有仓库）

1. **在服务器生成 SSH 密钥**：
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   # 直接按 Enter 使用默认路径
   # 可以设置密码或直接按 Enter 不设置密码
   ```

2. **查看公钥**：
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

3. **添加到 GitHub**：
   - GitHub → Settings → SSH and GPG keys → New SSH key
   - 标题：`阿里云服务器`
   - 内容：粘贴刚才复制的公钥
   - 点击 "Add SSH key"

4. **使用 SSH 地址克隆**：
   ```bash
   git clone git@github.com:your-username/feihub.git
   ```

---

## 🔧 第五步：日常开发工作流程

### 5.1 本地修改代码后

```bash
# 1. 查看修改
git status

# 2. 添加修改的文件
git add .

# 3. 提交修改
git commit -m "描述你的修改内容"

# 4. 推送到 GitHub
git push
```

### 5.2 服务器更新代码

```bash
cd /www/wwwroot/feihub

# 拉取最新代码
git pull

# 更新后端依赖（如果有新依赖）
cd backend
npm install --production
npm run build
pm2 restart feihub-backend

# 更新前端依赖（如果有新依赖）
cd ..
npm install
npm run build
```

---

## 📝 最佳实践

### 1. 提交信息规范

```bash
# 好的提交信息
git commit -m "feat: 添加客服弹窗功能"
git commit -m "fix: 修复热搜词显示问题"
git commit -m "docs: 更新部署指南"

# 提交信息前缀：
# feat: 新功能
# fix: 修复bug
# docs: 文档更新
# style: 代码格式调整
# refactor: 代码重构
# test: 测试相关
```

### 2. 分支管理（可选）

```bash
# 创建开发分支
git checkout -b develop

# 开发完成后合并到主分支
git checkout main
git merge develop
git push
```

### 3. 不要上传敏感信息

- ❌ `.env` 文件（包含 API Key、数据库密码等）
- ❌ `node_modules/`（太大，服务器上重新安装）
- ✅ 使用 `.gitignore` 排除这些文件

---

## 🚨 重要提示

### 1. 环境变量文件

**不要**将 `.env` 文件上传到 GitHub！

- 在服务器上手动创建 `.env` 文件
- 在 `.gitignore` 中已排除 `.env`

### 2. 首次部署

1. 在服务器克隆代码
2. 手动创建 `.env` 文件并配置
3. 运行 `npm install` 安装依赖
4. 运行数据库迁移
5. 启动服务

### 3. 后续更新

1. 本地修改代码 → `git push`
2. 服务器执行 `git pull`
3. 重新构建和重启服务

---

## 📋 快速命令参考

### 本地开发
```bash
git add .
git commit -m "描述修改"
git push
```

### 服务器更新
```bash
cd /www/wwwroot/feihub
git pull
cd backend && npm install --production && npm run build && pm2 restart feihub-backend
cd .. && npm install && npm run build
```

---

## 🎉 开始使用

1. **现在**：在本地初始化 Git 并推送到 GitHub
2. **然后**：在服务器从 GitHub 克隆代码
3. **后续**：每次修改代码后，本地 push，服务器 pull

需要我帮你创建 `.gitignore` 文件吗？


