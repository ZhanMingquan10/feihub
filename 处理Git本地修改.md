# 处理 Git 本地修改

## 问题说明

错误：`Your local changes to the following files would be overwritten by merge`

这是因为你在服务器上手动修改了文件，现在需要拉取最新的代码。

---

## 🔧 解决方案

### 方案一：保存本地修改后拉取（推荐）

如果你想保留本地修改，可以先保存（stash），然后拉取，再决定是否应用：

```bash
cd /www/wwwroot/feihub

# 1. 保存本地修改
git stash

# 2. 拉取最新代码
git pull

# 3. 查看保存的修改（可选）
git stash list

# 4. 如果需要应用本地修改（通常不需要，因为最新代码已经包含修复）
# git stash pop
```

---

### 方案二：放弃本地修改后拉取（推荐，因为最新代码已包含修复）

如果你不需要保留本地修改（因为最新代码已经包含所有修复），可以直接放弃：

```bash
cd /www/wwwroot/feihub

# 1. 放弃本地修改
git checkout -- backend/src/lib/feishu-puppeteer.ts
git checkout -- backend/src/lib/feishu-server.ts
git checkout -- backend/tsconfig.json

# 2. 拉取最新代码
git pull
```

---

### 方案三：强制拉取（最简单，但会丢失本地修改）

```bash
cd /www/wwwroot/feihub

# 1. 强制拉取（会覆盖本地修改）
git fetch origin
git reset --hard origin/main
```

**注意**：这会覆盖所有本地未提交的修改。

---

## 🚀 推荐操作（方案二）

由于最新代码已经包含所有修复，推荐使用方案二：

```bash
cd /www/wwwroot/feihub

# 放弃本地修改
git checkout -- backend/src/lib/feishu-puppeteer.ts
git checkout -- backend/src/lib/feishu-server.ts
git checkout -- backend/tsconfig.json

# 拉取最新代码
git pull

# 验证拉取成功
git status

# 重新构建
cd backend
npm run build
```

---

## ✅ 验证拉取成功

拉取后，可以验证文件是否已修复：

```bash
# 检查 tsconfig.json 是否包含 DOM
grep -n "DOM" backend/tsconfig.json

# 检查 feishu-server.ts 是否使用 puppeteer-core
grep -n "puppeteer-core" backend/src/lib/feishu-server.ts

# 检查是否有类型转换
grep -n "as HTMLElement" backend/src/lib/feishu-puppeteer.ts | head -3
```

---

## 🎯 下一步

拉取成功后：
1. 重新构建：`cd backend && npm run build`
2. 如果构建成功，继续启动后端服务
3. 然后构建前端

---

## 📝 说明

- **方案一**：如果你想保留本地修改（通常不需要）
- **方案二**：推荐，因为最新代码已包含所有修复
- **方案三**：最简单，但会丢失所有本地修改


