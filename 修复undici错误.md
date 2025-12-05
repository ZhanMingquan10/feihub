# 修复 undici File is not defined 错误

## 问题说明

错误：`ReferenceError: File is not defined` 在 `undici` 包中

这是因为：
1. `undici@7.16.0` 需要 Node.js >= 20.18.1
2. 或者 Node.js 版本不匹配导致某些 Web API 不可用

---

## 🔍 第一步：检查 Node.js 版本

在宝塔终端执行：

```bash
# 检查当前 Node.js 版本
node --version

# 检查 PM2 使用的 Node.js 版本
pm2 describe feihub-backend | grep node_version
```

---

## 🔧 解决方案

### 方案一：降级 undici（推荐）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 降级 undici 到兼容版本
npm install undici@6.19.8 --save

# 重新启动服务
pm2 restart feihub-backend
```

---

### 方案二：检查并修复依赖

```bash
cd /www/wwwroot/feihub/backend

# 删除 node_modules 和 package-lock.json
rm -rf node_modules package-lock.json

# 重新安装依赖
npm install

# 重新启动服务
pm2 restart feihub-backend
```

---

### 方案三：升级 Node.js（如果版本太低）

如果 Node.js 版本低于 20.18.1：

1. **在宝塔面板升级 Node.js**
   - 软件商店 → Node.js版本管理器 → 设置
   - 安装 Node.js 20.x 最新版本
   - 设置为默认版本

2. **重新启动服务**
   ```bash
   pm2 restart feihub-backend
   ```

---

## 🚀 快速修复（推荐方案一）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 降级 undici
npm install undici@6.19.8 --save

# 重新启动
pm2 restart feihub-backend

# 查看状态
pm2 status

# 查看日志
pm2 logs feihub-backend --lines 20
```

---

## 📝 说明

- `undici@7.16.0` 需要 Node.js >= 20.18.1
- `undici@6.19.8` 兼容更多 Node.js 版本
- 降级 undici 通常是最快的解决方案

---

## ✅ 验证修复

修复后，检查：

```bash
# 查看服务状态
pm2 status

# 查看日志（应该没有错误）
pm2 logs feihub-backend --lines 20
```

**成功标志**：
- `pm2 status` 显示 `feihub-backend` 状态为 `online`
- 日志中没有 `File is not defined` 错误

---

## 🎯 现在执行

先执行快速修复命令：

```bash
cd /www/wwwroot/feihub/backend
npm install undici@6.19.8 --save
pm2 restart feihub-backend
pm2 status
```

告诉我结果，我们继续。


