# 修复 CORS 和 API 连接问题

## 🔍 问题分析

构建成功，但还是报错 "Failed to fetch"，可能是：
1. **CORS 配置问题**：后端 CORS 配置不允许来自 IP 地址的请求
2. **浏览器缓存**：虽然强制刷新了，但可能还有缓存
3. **API 请求路径问题**：请求的 URL 不正确

---

## 🔧 解决方案

### 第一步：检查后端 CORS 配置

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 检查 .env 文件中的 CORS_ORIGIN
cat .env | grep CORS_ORIGIN
```

**如果 CORS_ORIGIN 配置的是域名，需要临时添加 IP 地址。**

---

### 第二步：修改后端 CORS 配置（临时方案）

在宝塔文件管理器中：
1. 进入 `/www/wwwroot/feihub/backend`
2. 编辑 `.env` 文件
3. 找到 `CORS_ORIGIN` 配置
4. 修改为（支持多个来源）：
   ```env
   CORS_ORIGIN=http://121.40.214.130,https://feihub.top,http://feihub.top
   ```

**或者使用终端命令**：

```bash
cd /www/wwwroot/feihub/backend

# 备份 .env 文件
cp .env .env.backup

# 修改 CORS_ORIGIN（添加 IP 地址）
sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://121.40.214.130,https://feihub.top,http://feihub.top|' .env

# 验证修改
cat .env | grep CORS_ORIGIN

# 重启后端服务
pm2 restart feihub-backend
```

---

### 第三步：检查浏览器控制台

在浏览器中：
1. 按 `F12` 打开开发者工具
2. 点击 **"控制台"**（Console）标签
3. 查看错误信息
4. 点击 **"网络"**（Network）标签
5. 刷新页面
6. 找到失败的 API 请求（通常是 `/api/submissions` 或 `/api/documents`）
7. 点击请求，查看：
   - **请求 URL**：是否正确
   - **状态码**：是什么（404、500、CORS 错误等）
   - **响应内容**：是什么

**把错误信息发给我，我帮你分析。**

---

### 第四步：测试 API 连接

在宝塔终端执行：

```bash
# 测试后端 API（直接访问）
curl -X POST http://localhost:4000/api/submissions \
  -H "Content-Type: application/json" \
  -H "Origin: http://121.40.214.130" \
  -d '{"link":"https://test.feishu.cn/test"}' 2>&1

# 测试反向代理
curl -X POST http://localhost/api/submissions \
  -H "Content-Type: application/json" \
  -H "Host: feihub.top" \
  -H "Origin: http://121.40.214.130" \
  -d '{"link":"https://test.feishu.cn/test"}' 2>&1
```

---

## 🚀 快速修复（推荐）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 修改 CORS_ORIGIN（添加 IP 地址）
sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://121.40.214.130,https://feihub.top,http://feihub.top|' .env

# 验证修改
cat .env | grep CORS_ORIGIN

# 重启后端服务
pm2 restart feihub-backend

# 查看日志
pm2 logs feihub-backend --lines 10
```

---

## ✅ 验证修复

修复后：

1. **在浏览器访问**：`http://121.40.214.130`
2. **清除浏览器缓存**（重要）：
   - 按 `Ctrl + Shift + Delete`
   - 清除所有缓存
   - 或者使用无痕模式访问
3. **测试提交文档**：
   - 应该能成功提交

---

## 📝 备案通过后的操作

等备案通过后，可以改回只使用域名：

```env
CORS_ORIGIN=https://feihub.top
```

然后重启后端服务。

---

## 🎯 现在执行

先执行快速修复命令：

```bash
cd /www/wwwroot/feihub/backend
sed -i 's|CORS_ORIGIN=.*|CORS_ORIGIN=http://121.40.214.130,https://feihub.top,http://feihub.top|' .env
cat .env | grep CORS_ORIGIN
pm2 restart feihub-backend
```

然后：
1. **在浏览器清除缓存**（使用无痕模式或清除所有缓存）
2. **测试提交文档**
3. **查看浏览器控制台的错误信息**（如果还是失败）

告诉我结果，我们继续！


