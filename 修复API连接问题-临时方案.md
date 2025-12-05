# 修复 API 连接问题 - 临时方案

## 🔍 问题分析

从诊断结果看：
- 后端服务运行正常 ✓
- 前端环境变量配置的是 `https://feihub.top/api`
- 通过 IP 访问时，浏览器无法解析 `feihub.top` 域名，导致 API 请求失败

---

## 🔧 临时修复方案（用于测试）

在备案期间，通过 IP 访问时，需要临时修改前端环境变量使用 IP 地址。

### 步骤 1：修改前端环境变量

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub

# 获取服务器 IP（或直接使用）
SERVER_IP="121.40.214.130"

# 创建或更新 .env.production（使用 IP）
echo "VITE_API_BASE=http://${SERVER_IP}/api" > .env.production

# 验证配置
cat .env.production
```

---

### 步骤 2：重新构建前端

```bash
cd /www/wwwroot/feihub
npm run build
```

---

### 步骤 3：验证修复

1. **在浏览器访问**：`http://121.40.214.130`
2. **测试提交文档**：
   - 点击"分享文档"按钮
   - 输入飞书文档链接
   - 提交
   - 应该能成功提交

---

## 📝 备案通过后的操作

等备案通过后，需要改回使用域名：

```bash
cd /www/wwwroot/feihub

# 改回使用域名
echo "VITE_API_BASE=https://feihub.top/api" > .env.production

# 重新构建
npm run build
```

---

## 🚀 快速修复命令

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub
echo "VITE_API_BASE=http://121.40.214.130/api" > .env.production
npm run build
```

---

## ✅ 验证修复

修复后，测试：

1. **在浏览器访问**：`http://121.40.214.130`
2. **测试提交文档**：
   - 应该能成功提交
   - 文档应该能被处理并显示

---

## 🎯 现在执行

先执行快速修复命令：

```bash
cd /www/wwwroot/feihub
echo "VITE_API_BASE=http://121.40.214.130/api" > .env.production
npm run build
```

然后：
1. **在浏览器测试**：访问 `http://121.40.214.130`
2. **测试提交文档**：看看是否能成功

告诉我结果，我们继续！


