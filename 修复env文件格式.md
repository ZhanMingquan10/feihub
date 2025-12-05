# 修复 .env 文件格式

## 🔧 修复 .env 文件

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 查看当前 .env 文件
cat .env

# 修复格式：确保 CHROME_PATH 在单独一行
# 如果 CHROME_PATH 被追加到其他行，需要修复
sed -i 's/CORS_ORIGIN=.*CHROME_PATH=/CORS_ORIGIN=http:\/\/121.40.214.130,https:\/\/feihub.top,http:\/\/feihub.top\nCHROME_PATH=/' .env

# 或者直接重新设置（更安全）
# 先备份
cp .env .env.bak

# 重新设置 CHROME_PATH（确保在单独一行）
if grep -q "CHROME_PATH" .env; then
  # 移除旧的 CHROME_PATH（可能在同一行）
  sed -i 's/CHROME_PATH=.*//' .env
  # 在文件末尾添加新的 CHROME_PATH（单独一行）
  echo "CHROME_PATH=/usr/bin/chromium-browser" >> .env
fi

# 验证格式
echo "=== 验证 .env 文件格式 ==="
cat .env | grep -E "(CORS_ORIGIN|CHROME_PATH)"
```

---

## 🚀 重启服务

```bash
# 重启 PM2
pm2 restart feihub-backend

# 查看启动日志，应该看到 Puppeteer 可用
pm2 logs feihub-backend --lines 50 --nostream | grep -E "(Puppeteer|Chrome|启动)"
```

---

## ✅ 验证

应该看到：
```
[启动] ✅ Puppeteer 可用，将使用 Puppeteer 方案
[Puppeteer] Using browser at: /usr/bin/chromium-browser
```


