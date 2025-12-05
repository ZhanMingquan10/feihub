# 修复构建错误 - .user.ini 问题

## 🔍 问题说明

错误：`ENOTDIR: not a directory, scandir '/www/wwwroot/feihub/dist/.user.ini'`

这是因为 `dist/.user.ini` 文件导致 Vite 构建时无法清空目录。

---

## 🔧 解决方案

### 方案一：删除 .user.ini 文件（推荐）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub

# 删除 .user.ini 文件
rm -f dist/.user.ini

# 重新构建
npm run build
```

---

### 方案二：清空 dist 目录后重建

```bash
cd /www/wwwroot/feihub

# 清空 dist 目录（保留 .htaccess 等必要文件）
rm -rf dist/*
rm -rf dist/.*

# 重新构建
npm run build
```

---

### 方案三：修改构建配置（如果方案一不行）

如果删除后还是有问题，可以修改 `vite.config.ts`，在构建前清理目录。

---

## 🚀 快速修复（推荐方案一）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub

# 删除 .user.ini 文件
rm -f dist/.user.ini

# 重新构建
npm run build
```

---

## ✅ 验证修复

构建成功后，应该看到：

```
✓ built in X.XXs
```

然后：
1. **在浏览器访问**：`http://121.40.214.130`
2. **清除浏览器缓存**（按 `Ctrl + F5`）
3. **测试提交文档**

---

## 📝 关于 .user.ini 文件

`.user.ini` 是宝塔面板自动创建的文件，用于 PHP 配置。对于纯静态网站，可以删除。

如果删除后宝塔面板又自动创建，可以在构建脚本中自动删除。

---

## 🎯 现在执行

先执行快速修复命令：

```bash
cd /www/wwwroot/feihub
rm -f dist/.user.ini
npm run build
```

告诉我结果，我们继续！


