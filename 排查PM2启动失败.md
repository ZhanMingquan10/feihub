# 排查 PM2 启动失败

## 问题说明

PM2 状态显示 `errored`，说明后端服务启动失败。

---

## 🔍 第一步：查看详细日志

在宝塔终端执行：

```bash
# 查看详细错误日志
pm2 logs feihub-backend --lines 50

# 或者查看最近的错误
pm2 logs feihub-backend --err --lines 50
```

**把日志内容发给我，我帮你分析问题。**

---

## 🔧 常见问题和解决方案

### 问题 1：环境变量未配置

**错误信息**：`DATABASE_URL is not defined` 或类似

**解决方案**：
```bash
cd /www/wwwroot/feihub/backend
cat .env
```

确保 `.env` 文件存在且配置正确。

---

### 问题 2：数据库连接失败

**错误信息**：`Can't reach database server` 或 `Connection refused`

**解决方案**：
```bash
# 检查数据库是否运行
ps aux | grep postgres | grep -v grep

# 测试数据库连接
psql -h localhost -U feihub_user -d feihub -c "SELECT 1;"
```

---

### 问题 3：端口被占用

**错误信息**：`EADDRINUSE: address already in use :::4000`

**解决方案**：
```bash
# 检查端口占用
netstat -tlnp | grep 4000

# 如果被占用，停止占用进程或修改 .env 中的 PORT
```

---

### 问题 4：缺少依赖

**错误信息**：`Cannot find module` 或类似

**解决方案**：
```bash
cd /www/wwwroot/feihub/backend
npm install
```

---

### 问题 5：构建文件不存在

**错误信息**：`Cannot find module './dist/index'` 或类似

**解决方案**：
```bash
cd /www/wwwroot/feihub/backend
npm run build
```

---

## 🚀 快速诊断命令

在宝塔终端执行以下命令，把结果发给我：

```bash
# 1. 查看详细日志
pm2 logs feihub-backend --lines 50

# 2. 检查环境变量
cd /www/wwwroot/feihub/backend
cat .env

# 3. 检查构建文件是否存在
ls -la dist/

# 4. 检查端口占用
netstat -tlnp | grep 4000

# 5. 检查数据库连接
psql -h localhost -U feihub_user -d feihub -c "SELECT 1;"
```

---

## 📝 临时解决方案

如果问题复杂，可以先尝试：

```bash
# 1. 停止服务
pm2 stop feihub-backend
pm2 delete feihub-backend

# 2. 检查并修复问题

# 3. 重新启动
cd /www/wwwroot/feihub/backend
pm2 start ecosystem.config.js
pm2 save
```

---

## 🎯 现在执行

先执行这个命令，把日志发给我：

```bash
pm2 logs feihub-backend --lines 50
```

这样我就能知道具体是什么错误了。


