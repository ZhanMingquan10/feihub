# 修复 Puppeteer 问题 - 快速指南

## 🚀 快速诊断

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub

# 下载并运行诊断脚本
wget -O /tmp/diagnose.sh https://raw.githubusercontent.com/your-repo/feihub/main/诊断Puppeteer问题.sh 2>/dev/null || cat > /tmp/diagnose.sh << 'EOF'
# 诊断脚本内容（见下方）
EOF

# 或者直接运行诊断命令
cd /www/wwwroot/feihub/backend

# 1. 查看 PM2 日志（最重要）
echo "=== PM2 日志（最近 100 行）==="
pm2 logs feihub-backend --lines 100 --nostream | tail -50

# 2. 检查 Chrome
echo "=== 检查 Chrome ==="
which google-chrome-stable || which chromium-browser || which chromium || echo "❌ Chrome 未安装"

# 3. 检查环境变量
echo "=== 检查环境变量 ==="
grep CHROME_PATH .env 2>/dev/null || echo "⚠️ 未设置 CHROME_PATH"
```

---

## 🔧 解决方案

### 情况 1：Chrome 未安装

**安装 Chrome（推荐）**：

```bash
# 安装 Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get update
sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# 验证
google-chrome-stable --version
```

**或者安装 Chromium（更轻量）**：

```bash
sudo apt-get update
sudo apt-get install -y chromium-browser

# 验证
chromium-browser --version
```

---

### 情况 2：Chrome 已安装但找不到

**设置环境变量**：

```bash
cd /www/wwwroot/feihub/backend

# 找到 Chrome 路径
CHROME_PATH=$(which google-chrome-stable || which chromium-browser || which chromium)
echo "Chrome 路径: $CHROME_PATH"

# 添加到 .env 文件
if [ -n "$CHROME_PATH" ]; then
  if grep -q "CHROME_PATH" .env; then
    sed -i "s|CHROME_PATH=.*|CHROME_PATH=$CHROME_PATH|" .env
  else
    echo "CHROME_PATH=$CHROME_PATH" >> .env
  fi
  echo "✅ 已设置 CHROME_PATH=$CHROME_PATH"
  cat .env | grep CHROME_PATH
else
  echo "❌ 未找到 Chrome，请先安装"
fi
```

---

### 情况 3：重启服务

**重启 PM2**：

```bash
cd /www/wwwroot/feihub/backend

# 重启服务
pm2 restart feihub-backend

# 查看启动日志
pm2 logs feihub-backend --lines 20 --nostream

# 应该看到：
# [启动] ✅ Puppeteer 可用，将使用 Puppeteer 方案
```

---

## 📝 完整诊断脚本

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 1. 检查 PM2 日志
echo "=== [1] PM2 日志（最近 50 行，包含 Puppeteer/Chrome/错误）==="
pm2 logs feihub-backend --lines 50 --nostream | grep -E "(Puppeteer|Chrome|爬取|处理文档|错误|Error|启动)" | tail -30
echo ""

# 2. 检查 Chrome
echo "=== [2] 检查 Chrome 是否安装 ==="
CHROME_PATHS=("/usr/bin/google-chrome" "/usr/bin/google-chrome-stable" "/usr/bin/chromium" "/usr/bin/chromium-browser" "/snap/bin/chromium")
FOUND=""
for path in "${CHROME_PATHS[@]}"; do
  if [ -f "$path" ]; then
    echo "✅ 找到: $path"
    $path --version 2>/dev/null || echo "   (无法获取版本)"
    FOUND="$path"
    break
  fi
done
if [ -z "$FOUND" ]; then
  echo "❌ 未找到 Chrome/Chromium"
fi
echo ""

# 3. 检查环境变量
echo "=== [3] 检查环境变量 ==="
if [ -f ".env" ]; then
  if grep -q "CHROME_PATH" .env; then
    echo "✅ .env 中设置了 CHROME_PATH:"
    grep "CHROME_PATH" .env
  else
    echo "⚠️  .env 中未设置 CHROME_PATH"
  fi
else
  echo "⚠️  .env 文件不存在"
fi
echo ""

# 4. 检查 puppeteer-core
echo "=== [4] 检查 puppeteer-core ==="
if [ -d "node_modules/puppeteer-core" ]; then
  echo "✅ puppeteer-core 已安装"
  npm list puppeteer-core 2>/dev/null | head -2
else
  echo "❌ puppeteer-core 未安装"
fi
echo ""

# 5. 检查最近的文档处理日志
echo "=== [5] 最近的文档处理日志 ==="
pm2 logs feihub-backend --lines 200 --nostream | grep -E "\[处理文档\]|\[爬取\]|\[Puppeteer\]" | tail -20
```

---

## ✅ 验证修复

修复后，重新提交一个文档，然后检查日志：

```bash
# 实时查看日志
pm2 logs feihub-backend

# 应该看到：
# [启动] ✅ Puppeteer 可用，将使用 Puppeteer 方案
# [Puppeteer] 开始获取飞书文档: https://...
# [Puppeteer] Using browser at: /usr/bin/google-chrome-stable
# [Puppeteer] 页面加载完成
# [处理文档] 文档内容获取结果:
# [处理文档] - 标题: "xxx"
# [处理文档] - 内容长度: xxx
```

---

## 🆘 如果还是不行

如果安装 Chrome 后还是不行，请把以下信息发给我：

1. **PM2 日志**（最近 100 行）：
   ```bash
   pm2 logs feihub-backend --lines 100 --nostream | tail -50
   ```

2. **Chrome 路径**：
   ```bash
   which google-chrome-stable || which chromium-browser || which chromium
   ```

3. **环境变量**：
   ```bash
   cat /www/wwwroot/feihub/backend/.env | grep CHROME_PATH
   ```

4. **系统信息**：
   ```bash
   uname -a
   lsb_release -a
   ```


