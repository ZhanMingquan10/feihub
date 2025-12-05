# Git 快速开始指南

## 🚀 5分钟快速设置

### 第一步：在本地初始化 Git

在项目目录（`feihub` 文件夹）打开终端或 Git Bash，执行：

```bash
# 1. 初始化 Git
git init

# 2. 添加所有文件
git add .

# 3. 首次提交
git commit -m "Initial commit: FeiHub project"
```

### 第二步：创建 GitHub 仓库

1. 访问 https://github.com
2. 登录（如果没有账号，先注册）
3. 点击右上角 "+" → "New repository"
4. 仓库名：`feihub`
5. 选择 Private（私有）或 Public（公开）
6. **不要**勾选 "Initialize with README"
7. 点击 "Create repository"

### 第三步：推送代码到 GitHub

GitHub 创建仓库后会显示命令，执行：

```bash
# 添加远程仓库（替换 your-username 为你的 GitHub 用户名）
git remote add origin https://github.com/your-username/feihub.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

**如果提示输入用户名和密码：**
- 用户名：你的 GitHub 用户名
- 密码：使用 Personal Access Token（不是 GitHub 密码）
  - 生成 Token：GitHub → Settings → Developer settings → Personal access tokens → Generate new token
  - 勾选 `repo` 权限
  - 复制生成的 Token 作为密码

### 第四步：服务器从 GitHub 拉取

在宝塔终端执行：

```bash
# 安装 Git
apt install git -y

# 克隆代码（替换为你的 GitHub 仓库地址）
cd /www/wwwroot/
git clone https://github.com/your-username/feihub.git

# 如果仓库是私有的，需要配置认证
```

---

## 📝 日常使用

### 本地修改代码后

```bash
git add .
git commit -m "描述你的修改"
git push
```

### 服务器更新代码

```bash
cd /www/wwwroot/feihub
git pull
```

---

## ⚠️ 重要提示

1. **不要上传 `.env` 文件**（已在 `.gitignore` 中排除）
2. **服务器上需要手动创建 `.env` 文件**
3. **每次更新代码后，需要重新构建和重启服务**


