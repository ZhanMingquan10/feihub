# GitHub 认证配置指南

## 问题说明

GitHub 已经不再支持使用密码进行 Git 操作，需要使用以下方式之一：
1. **Personal Access Token (PAT)** - 简单快速
2. **SSH 密钥** - 更安全，推荐

---

## 方案一：使用 Personal Access Token（快速）

### 步骤 1：生成 Token

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单 → **Developer settings**
4. **Personal access tokens** → **Tokens (classic)**
5. 点击 **"Generate new token (classic)"**
6. 填写：
   - **Note**：`FeiHub 服务器部署`
   - **Expiration**：选择过期时间（建议 90 天或 No expiration）
   - **勾选权限**：`repo`（全部勾选）
7. 点击 **"Generate token"**
8. **复制 Token**（只显示一次，请保存好！）

### 步骤 2：在服务器上使用 Token

在宝塔终端执行：

```bash
cd /www/wwwroot/

# 克隆代码时，使用 Token 作为密码
git clone https://github.com/ZhanMingquan/feihub.git
```

**当提示输入用户名和密码时：**
- **用户名**：`ZhanMingquan`
- **密码**：粘贴刚才生成的 Token（不是 GitHub 密码）

---

## 方案二：使用 SSH 密钥（推荐，更安全）

### 步骤 1：在服务器生成 SSH 密钥

在宝塔终端执行：

```bash
# 生成 SSH 密钥
ssh-keygen -t ed25519 -C "feihub-server"

# 直接按 Enter 使用默认路径
# 可以设置密码或直接按 Enter 不设置密码
```

### 步骤 2：查看公钥

```bash
# 查看公钥内容
cat ~/.ssh/id_ed25519.pub
```

**复制整个公钥内容**（从 `ssh-ed25519` 开始到邮箱结束）

### 步骤 3：添加到 GitHub

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单 → **SSH and GPG keys**
4. 点击 **"New SSH key"**
5. 填写：
   - **Title**：`阿里云服务器 - FeiHub`
   - **Key**：粘贴刚才复制的公钥
6. 点击 **"Add SSH key"**

### 步骤 4：使用 SSH 地址克隆

在宝塔终端执行：

```bash
cd /www/wwwroot/

# 使用 SSH 地址克隆（不需要输入密码）
git clone git@github.com:ZhanMingquan/feihub.git
```

---

## 方案三：在 URL 中直接使用 Token（临时方案）

如果只是临时使用，可以在 URL 中直接包含 Token：

```bash
cd /www/wwwroot/

# 替换 YOUR_TOKEN 为你的 Personal Access Token
git clone https://YOUR_TOKEN@github.com/ZhanMingquan/feihub.git feihub
```

**注意**：这种方式 Token 会出现在命令历史中，不够安全，不推荐长期使用。

---

## 推荐方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| Personal Access Token | 简单快速 | 需要每次输入（可配置保存） | ⭐⭐⭐ |
| SSH 密钥 | 安全，一次配置永久使用 | 需要配置 SSH 密钥 | ⭐⭐⭐⭐⭐ |
| URL 中包含 Token | 最简单 | 不安全，Token 会暴露 | ⭐ |

---

## 配置 Git 保存凭据（可选）

如果使用 Personal Access Token，可以配置 Git 保存凭据，避免每次输入：

```bash
# 配置 Git 保存凭据
git config --global credential.helper store

# 之后第一次输入用户名和 Token 后，Git 会自动保存
```

---

## 验证配置

### 如果使用 SSH 方式：

```bash
# 测试 SSH 连接
ssh -T git@github.com

# 应该显示：Hi ZhanMingquan! You've successfully authenticated...
```

### 如果使用 Token 方式：

```bash
# 尝试克隆（会提示输入用户名和 Token）
git clone https://github.com/ZhanMingquan/feihub.git
```

---

## 快速命令（SSH 方式）

如果你想快速使用 SSH 方式，在服务器终端执行：

```bash
# 1. 生成 SSH 密钥
ssh-keygen -t ed25519 -C "feihub-server" -f ~/.ssh/id_ed25519 -N ""

# 2. 显示公钥（复制这个）
cat ~/.ssh/id_ed25519.pub

# 3. 将公钥添加到 GitHub（手动操作）

# 4. 测试连接
ssh -T git@github.com

# 5. 克隆代码
cd /www/wwwroot/
git clone git@github.com:ZhanMingquan/feihub.git
```

---

## 遇到问题？

### 问题 1：SSH 连接失败

```bash
# 检查 SSH 配置
cat ~/.ssh/config

# 如果没有配置，创建配置
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

### 问题 2：Token 无效

- 检查 Token 是否过期
- 检查 Token 是否有 `repo` 权限
- 重新生成 Token

### 问题 3：权限被拒绝

```bash
# 检查 SSH 密钥权限
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

---

## 下一步

配置好认证后，继续执行：

```bash
cd /www/wwwroot/
git clone https://github.com/ZhanMingquan/feihub.git
# 或
git clone git@github.com:ZhanMingquan/feihub.git
```

然后继续按照 `服务器部署步骤.md` 进行部署。


