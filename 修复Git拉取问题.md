# 修复 Git 拉取问题

## 问题说明

错误：`fatal: detected dubious ownership in repository`

这是因为 Git 检测到仓库的所有者和当前用户不匹配，出于安全考虑阻止了操作。

---

## 🔧 解决方案

### 步骤 1：添加安全目录

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub
git config --global --add safe.directory /www/wwwroot/feihub
```

---

### 步骤 2：重新拉取代码

```bash
git pull
```

---

### 步骤 3：验证拉取成功

```bash
# 检查文件是否更新
git status

# 或者检查特定文件是否已修复
grep -n "as HTMLElement" backend/src/lib/feishu-puppeteer.ts | head -5
```

---

### 步骤 4：重新构建

```bash
cd backend
npm run build
```

---

## 📋 完整操作流程

```bash
# 1. 添加安全目录
cd /www/wwwroot/feihub
git config --global --add safe.directory /www/wwwroot/feihub

# 2. 拉取最新代码
git pull

# 3. 验证拉取成功（应该看到文件更新）
git status

# 4. 重新构建
cd backend
npm run build
```

---

## ✅ 成功标志

1. **拉取成功**：应该看到类似 `Updating xxx..xxx` 的信息
2. **构建成功**：`npm run build` 没有错误，生成 `dist/` 目录

---

## 🆘 如果拉取失败

### 检查是否有冲突

```bash
git status
```

如果有冲突，需要解决冲突后再拉取。

### 检查远程仓库

```bash
git remote -v
```

应该显示：`https://github.com/ZhanMingquan/feihub.git`

### 强制拉取（谨慎使用）

```bash
git fetch origin
git reset --hard origin/main
```

**注意**：这会覆盖本地未提交的更改。

---

## 🎯 下一步

拉取成功后，继续：
1. 重新构建：`cd backend && npm run build`
2. 启动后端：`pm2 start ecosystem.config.js`
3. 构建前端：`cd .. && npm install && npm run build`


