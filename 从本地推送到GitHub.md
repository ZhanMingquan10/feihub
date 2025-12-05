# 从本地推送到 GitHub 指南

## 步骤 1: 确认本地代码是最新的

### 方法 A: 如果本地已有代码
```bash
# 在本地项目目录
cd "D:\AI+CPS(只做一件事_做好一件事)\13.出海工具站\feihub"

# 检查 Git 状态
git status

# 如果有未提交的更改，先提交
git add .
git commit -m "更新代码"
```

### 方法 B: 如果本地代码不是最新的，从服务器同步
你可以：
1. 通过 SFTP/FTP 从服务器下载最新文件
2. 或者直接在本地重新构建（如果代码源文件一致）

## 步骤 2: 配置 Git（如果还没配置）

```bash
# 设置用户信息（如果还没设置）
git config --global user.name "ZhanMingquan"
git config --global user.email "your-email@example.com"

# 检查远程仓库
git remote -v

# 如果没有远程仓库，添加
git remote add origin https://github.com/ZhanMingquan/feihub.git
```

## 步骤 3: 推送到 GitHub

```bash
# 确保在项目根目录
cd "D:\AI+CPS(只做一件事_做好一件事)\13.出海工具站\feihub"

# 添加所有文件
git add .

# 提交更改
git commit -m "统一版本：同步最新代码 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 推送到 GitHub
git push -u origin main
# 或如果默认分支是 master
git push -u origin master
```

## 步骤 4: 如果推送需要认证

### 使用 Personal Access Token
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 生成新 token，勾选 `repo` 权限
3. 推送时使用 token 作为密码

### 或使用 SSH（推荐）
```bash
# 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -C "your-email@example.com"

# 将公钥添加到 GitHub
# Settings → SSH and GPG keys → New SSH key
# 复制 ~/.ssh/id_ed25519.pub 的内容

# 使用 SSH URL
git remote set-url origin git@github.com:ZhanMingquan/feihub.git
git push -u origin main
```

## 注意事项

1. **不要提交敏感文件**
   - `.env` 文件
   - `backend/.env` 文件
   - 包含 API 密钥的文件

2. **确保 .gitignore 正确**
   ```gitignore
   node_modules/
   dist/
   .env
   *.log
   ```

3. **如果推送失败**
   - 检查网络连接
   - 检查 GitHub 认证
   - 检查分支名称是否正确

## 验证推送成功

推送成功后，访问 GitHub 仓库确认：
- https://github.com/ZhanMingquan/feihub

应该能看到所有文件都已上传。

