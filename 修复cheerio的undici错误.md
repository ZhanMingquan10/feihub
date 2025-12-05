# 修复 cheerio 的 undici 错误

## 问题说明

错误来自 `cheerio/node_modules/undici`，说明 `cheerio` 也有自己的 `undici` 依赖，需要修复。

---

## 🔧 解决方案

### 方案一：降级 cheerio（推荐）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 降级 cheerio 到兼容版本
npm install cheerio@1.0.0-rc.12 --save

# 重新启动服务
pm2 restart feihub-backend

# 查看状态
pm2 status

# 查看日志
pm2 logs feihub-backend --lines 20
```

---

### 方案二：修复 cheerio 的 undici 依赖

```bash
cd /www/wwwroot/feihub/backend

# 进入 cheerio 的 node_modules
cd node_modules/cheerio/node_modules

# 如果有 undici，降级它
if [ -d "undici" ]; then
  cd undici
  npm install undici@6.19.8
  cd ../..
fi

# 回到项目根目录
cd /www/wwwroot/feihub/backend

# 重新启动服务
pm2 restart feihub-backend
```

---

### 方案三：删除并重新安装依赖（最彻底）

```bash
cd /www/wwwroot/feihub/backend

# 删除 node_modules 和 package-lock.json
rm -rf node_modules package-lock.json

# 重新安装依赖
npm install

# 如果还有问题，降级 cheerio
npm install cheerio@1.0.0-rc.12 --save

# 重新启动服务
pm2 restart feihub-backend
```

---

## 🚀 快速修复（推荐方案一）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 降级 cheerio
npm install cheerio@1.0.0-rc.12 --save

# 重新启动
pm2 restart feihub-backend

# 查看状态
pm2 status

# 查看日志（应该没有错误了）
pm2 logs feihub-backend --lines 20
```

---

## 📝 说明

- `cheerio@1.1.2` 依赖的 `undici` 版本太新
- `cheerio@1.0.0-rc.12` 是稳定版本，兼容性更好
- 降级 cheerio 通常是最快的解决方案

---

## ✅ 验证修复

修复后，检查：

```bash
# 查看服务状态（应该是 online）
pm2 status

# 查看日志（应该没有 File is not defined 错误）
pm2 logs feihub-backend --lines 20

# 测试 API（如果配置了健康检查）
curl http://localhost:4000/health
```

**成功标志**：
- `pm2 status` 显示 `feihub-backend` 状态为 `online`
- 日志中没有 `File is not defined` 错误
- 服务正常运行

---

## 🎯 现在执行

先执行快速修复命令：

```bash
cd /www/wwwroot/feihub/backend
npm install cheerio@1.0.0-rc.12 --save
pm2 restart feihub-backend
pm2 logs feihub-backend --lines 20
```

告诉我结果，我们继续。


