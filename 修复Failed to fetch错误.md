# 修复 "Failed to fetch" 错误

## 🔍 问题说明

"Failed to fetch" 错误通常表示前端无法连接到后端 API。

**可能原因**：
1. 前端环境变量配置的 API 地址无法访问（通过 IP 访问时，域名可能无法解析）
2. 后端服务未运行
3. 反向代理配置有问题
4. CORS 配置有问题

---

## 🔧 解决方案

### 第一步：检查后端服务是否运行

在宝塔终端执行：

```bash
# 检查后端服务状态
pm2 status

# 查看后端日志
pm2 logs feihub-backend --lines 20
```

**应该看到**：
- `feihub-backend` 状态为 `online`
- 日志中没有错误信息

---

### 第二步：检查前端环境变量配置

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub`
2. 检查 `.env.production` 文件
3. 确认 `VITE_API_BASE` 的配置

**问题**：如果配置的是 `https://feihub.top/api`，通过 IP 访问时可能无法解析。

**临时解决方案**（用于测试）：
- 修改 `.env.production` 为：
  ```env
  VITE_API_BASE=http://你的服务器IP/api
  ```
- 重新构建前端：
  ```bash
  cd /www/wwwroot/feihub
  npm run build
  ```

**注意**：这只是临时方案，等备案通过后，应该改回使用域名。

---

### 第三步：检查反向代理配置

在宝塔面板：
1. 网站 → `feihub.top` → 设置 → 反向代理
2. 确认反向代理配置正确：
   - 代理名称：`api`
   - 目标URL：`http://127.0.0.1:4000`
   - 发送域名：`$host`

---

### 第四步：测试 API 连接

在宝塔终端执行：

```bash
# 1. 测试后端 API 是否正常
curl http://localhost:4000/api/health 2>&1

# 2. 测试反向代理是否正常
curl -H "Host: feihub.top" http://localhost/api/health 2>&1

# 3. 测试文档提交接口
curl -X POST http://localhost:4000/api/submissions \
  -H "Content-Type: application/json" \
  -d '{"link":"https://test.feishu.cn/test"}' 2>&1
```

---

### 第五步：检查浏览器控制台

在浏览器中：
1. 按 `F12` 打开开发者工具
2. 点击 **"控制台"**（Console）标签
3. 查看是否有错误信息
4. 点击 **"网络"**（Network）标签
5. 刷新页面，查看 API 请求
6. 点击失败的请求，查看详细信息

**把错误信息发给我，我帮你分析。**

---

## 🚀 快速诊断

在宝塔终端执行以下命令，把结果发给我：

```bash
# 1. 检查后端服务
pm2 status

# 2. 测试后端 API
curl http://localhost:4000/api/health 2>&1

# 3. 检查前端环境变量
cat /www/wwwroot/feihub/.env.production 2>/dev/null || echo "文件不存在"

# 4. 检查反向代理配置
cat /www/server/panel/vhost/nginx/proxy/feihub.top/*.conf
```

---

## 🔧 临时修复方案（用于测试）

如果通过 IP 访问时 API 无法连接，可以临时修改前端环境变量：

```bash
cd /www/wwwroot/feihub

# 获取服务器 IP
SERVER_IP=$(curl -s ifconfig.me)

# 创建或更新 .env.production
echo "VITE_API_BASE=http://${SERVER_IP}/api" > .env.production

# 重新构建前端
npm run build
```

**注意**：这只是临时方案，等备案通过后，应该改回使用域名。

---

## 📝 正确的配置（备案通过后）

等备案通过后，`.env.production` 应该是：

```env
VITE_API_BASE=https://feihub.top/api
```

然后重新构建前端即可。

---

## 🎯 现在执行

先执行快速诊断命令，把结果发给我：

```bash
pm2 status
curl http://localhost:4000/api/health 2>&1
cat /www/wwwroot/feihub/.env.production 2>/dev/null || echo "文件不存在"
```

同时，在浏览器中：
1. 按 `F12` 打开开发者工具
2. 查看控制台和网络标签的错误信息
3. 把错误信息发给我

这样我就能知道具体是什么问题了。


