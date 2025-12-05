# 修复 Chrome 安装

## 🔧 方法 1：使用 dpkg 安装（推荐）

在宝塔终端执行：

```bash
# 1. 切换到下载目录（如果不在当前目录）
cd ~

# 2. 使用 dpkg 安装（会自动处理依赖）
sudo dpkg -i google-chrome-stable_current_amd64.deb

# 3. 如果遇到依赖问题，修复依赖
sudo apt-get install -f -y

# 4. 验证安装
google-chrome-stable --version
```

---

## 🔧 方法 2：如果方法 1 失败，尝试安装最小依赖

```bash
# 安装 Chrome 所需的最小依赖
sudo apt-get install -y \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libatspi2.0-0 \
  libcups2 \
  libdbus-1-3 \
  libdrm2 \
  libgbm1 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  xdg-utils

# 然后安装 Chrome
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f -y
```

---

## 🔧 方法 3：如果还是失败，使用 Chromium（更轻量，已安装）

如果 Google Chrome 安装困难，可以使用已安装的 Chromium：

```bash
# 检查 Chromium 是否可用
which chromium-browser
chromium-browser --version

# 设置环境变量（使用 Chromium）
cd /www/wwwroot/feihub/backend
sed -i 's/CHROME_PATH=.*//' .env
echo "CHROME_PATH=/usr/bin/chromium-browser" >> .env

# 验证
cat .env | grep CHROME_PATH

# 重启服务
pm2 restart feihub-backend --update-env
```


