# 验证并修复 Chrome 路径

## 🔍 第一步：验证 .env 文件

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 查看 .env 文件内容
echo "=== .env 文件内容 ==="
cat .env

# 检查 CHROME_PATH 是否在单独一行
echo ""
echo "=== 检查 CHROME_PATH ==="
grep CHROME_PATH .env
```

---

## 🔧 第二步：修复 .env 文件格式

如果 `CHROME_PATH` 还在同一行，修复它：

```bash
cd /www/wwwroot/feihub/backend

# 备份
cp .env .env.bak

# 移除旧的 CHROME_PATH（可能在同一行）
sed -i 's/CHROME_PATH=.*//' .env

# 确保 CORS_ORIGIN 行正确（如果被破坏了）
sed -i 's/CORS_ORIGIN=.*CHROME_PATH.*/CORS_ORIGIN=http:\/\/121.40.214.130,https:\/\/feihub.top,http:\/\/feihub.top/' .env

# 在文件末尾添加 CHROME_PATH（单独一行）
echo "CHROME_PATH=/usr/bin/chromium-browser" >> .env

# 验证格式
echo ""
echo "=== 验证修复后的格式 ==="
cat .env | grep -E "(CORS_ORIGIN|CHROME_PATH)"
```

应该看到：
```
CORS_ORIGIN=http://121.40.214.130,https://feihub.top,http://feihub.top
CHROME_PATH=/usr/bin/chromium-browser
```

---

## 🚀 第三步：重新构建并重启

```bash
cd /www/wwwroot/feihub/backend

# 重新构建
npm run build

# 重启 PM2
pm2 restart feihub-backend

# 查看启动日志
pm2 logs feihub-backend --lines 100 --nostream | grep -E "(启动|CHROME_PATH|getChromePath|Puppeteer)" | tail -30
```

---

## ✅ 验证

应该看到：
```
[启动] 环境变量 CHROME_PATH: "/usr/bin/chromium-browser"
[getChromePath] 检查环境变量 CHROME_PATH: "/usr/bin/chromium-browser"
[getChromePath] ✅ 找到 Chrome: /usr/bin/chromium-browser
[Puppeteer] Using browser at: /usr/bin/chromium-browser
```

---

## 🆘 如果还是不行

如果环境变量还是读取不到，可能需要：

1. **检查 .env 文件编码**：确保是 UTF-8，没有 BOM
2. **检查文件权限**：确保可读
3. **手动测试环境变量**：

```bash
cd /www/wwwroot/feihub/backend

# 手动加载 .env 并测试
export CHROME_PATH=/usr/bin/chromium-browser
node -e "require('dotenv').config(); console.log('CHROME_PATH:', process.env.CHROME_PATH);"
```


