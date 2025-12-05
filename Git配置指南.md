# Git 配置指南

## ⚠️ 关于 LF/CRLF 警告

这些警告是正常的，因为：
- Windows 使用 CRLF（\r\n）作为换行符
- Linux/Mac 使用 LF（\n）作为换行符
- Git 会自动转换，不影响使用

可以忽略这些警告，或者配置 Git 自动处理：

```bash
# 配置 Git 自动转换换行符（推荐）
git config --global core.autocrlf true
```

---

## 👤 配置 Git 用户信息

Git 需要知道你是谁，才能记录提交信息。

### 配置全局用户信息（推荐）

```bash
# 设置用户名（替换为你的名字或 GitHub 用户名）
git config --global user.name "Your Name"

# 设置邮箱（使用你的 GitHub 邮箱，或任意邮箱）
git config --global user.email "your-email@example.com"
```

### 只配置当前仓库（如果不想全局配置）

```bash
git config user.name "Your Name"
git config user.email "your-email@example.com"
```

---

## ✅ 验证配置

```bash
git config --global user.name
git config --global user.email
```

应该显示你刚才设置的值。

---

## 🚀 继续提交

配置完成后，继续执行：

```bash
git commit -m "Initial commit: FeiHub project"
```


