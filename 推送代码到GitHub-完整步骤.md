# 推送代码到 GitHub - 完整步骤

## ⚠️ 重要提示

本地代码可能不完整（缺少 `feishu.ts` 和 `feishu-puppeteer.ts`），但服务器上有完整代码。

**建议方案**：先从服务器拉取代码到本地，然后再推送。

---

## 🔄 方案一：从服务器同步代码（推荐）

### 1. 在服务器上提交并推送

```bash
cd /www/wwwroot/feihub

# 检查状态
git status

# 添加所有更改
git add .

# 提交
git commit -m "修复日期提取问题：添加详细调试日志和日期元素查找"

# 推送到 GitHub
git push origin main
```

### 2. 在本地拉取

```bash
cd "D:\AI+CPS(只做一件事_做好一件事)\13.出海工具站\feihub"

# 拉取最新代码
git pull origin main
```

---

## 🚀 方案二：直接在本地推送（如果本地有完整代码）

如果本地代码完整，直接执行：

```bash
cd "D:\AI+CPS(只做一件事_做好一件事)\13.出海工具站\feihub"

# 检查状态
git status

# 添加所有更改
git add .

# 提交
git commit -m "修复日期提取问题：添加详细调试日志和日期元素查找"

# 推送到 GitHub
git push origin main
```

---

## 📋 检查清单

推送前，确保以下文件存在：
- ✅ `backend/src/lib/feishu.ts`
- ✅ `backend/src/lib/feishu-puppeteer.ts`
- ✅ `backend/src/lib/feishu-server.ts`

如果缺少文件，使用方案一（从服务器同步）。

