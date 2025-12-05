# 检查并配置 Chrome 路径

## 🔍 第一步：检查已安装的浏览器

在宝塔终端执行：

```bash
# 检查常见的浏览器路径
which google-chrome-stable
which chromium-browser
which chromium
which google-chrome

# 检查文件是否存在
ls -la /usr/bin/google-chrome* 2>/dev/null
ls -la /usr/bin/chromium* 2>/dev/null
ls -la /snap/bin/chromium 2>/dev/null

# 检查版本
google-chrome-stable --version 2>/dev/null || chromium-browser --version 2>/dev/null || chromium --version 2>/dev/null
```

---

## 🔧 第二步：设置环境变量

找到浏览器路径后，设置环境变量：

```bash
cd /www/wwwroot/feihub/backend

# 找到浏览器路径（选择上面找到的路径之一）
CHROME_PATH=$(which google-chrome-stable || which chromium-browser || which chromium)
echo "找到的浏览器路径: $CHROME_PATH"

# 如果找到了，添加到 .env 文件
if [ -n "$CHROME_PATH" ]; then
  # 检查 .env 文件是否存在
  if [ ! -f .env ]; then
    touch .env
  fi
  
  # 如果已经有 CHROME_PATH，更新它；否则添加
  if grep -q "CHROME_PATH" .env; then
    sed -i "s|CHROME_PATH=.*|CHROME_PATH=$CHROME_PATH|" .env
  else
    echo "CHROME_PATH=$CHROME_PATH" >> .env
  fi
  
  echo "✅ 已设置 CHROME_PATH=$CHROME_PATH"
  echo "当前 .env 中的 CHROME_PATH:"
  grep CHROME_PATH .env
else
  echo "❌ 未找到浏览器，需要安装"
fi
```

---

## 🚀 第三步：重启服务

```bash
cd /www/wwwroot/feihub/backend

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

---

## 🆘 如果还是找不到

如果上面的命令都找不到浏览器，可能需要安装：

```bash
# 安装 Chromium（轻量）
sudo apt-get update
sudo apt-get install -y chromium-browser

# 或者安装 Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get install -y ./google-chrome-stable_current_amd64.deb
```


