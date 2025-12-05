#!/bin/bash

echo "=========================================="
echo "  Puppeteer 和 Chrome 诊断脚本"
echo "=========================================="
echo ""

# 1. 检查 PM2 日志
echo "[1/6] 检查 PM2 日志（最近 50 行）..."
echo "----------------------------------------"
cd /www/wwwroot/feihub/backend
pm2 logs feihub-backend --lines 50 --nostream | grep -E "(Puppeteer|Chrome|爬取|处理文档|错误|Error|启动)" | tail -30
echo ""

# 2. 检查 Chrome 是否安装
echo "[2/6] 检查 Chrome 是否安装..."
echo "----------------------------------------"
CHROME_PATHS=(
  "/usr/bin/google-chrome"
  "/usr/bin/google-chrome-stable"
  "/usr/bin/chromium"
  "/usr/bin/chromium-browser"
  "/snap/bin/chromium"
)

FOUND_CHROME=""
for path in "${CHROME_PATHS[@]}"; do
  if [ -f "$path" ]; then
    echo "✅ 找到 Chrome: $path"
    FOUND_CHROME="$path"
    # 检查版本
    $path --version 2>/dev/null || echo "   (无法获取版本)"
    break
  fi
done

if [ -z "$FOUND_CHROME" ]; then
  echo "❌ 未找到 Chrome/Chromium"
  echo "   请安装 Chrome 或设置 CHROME_PATH 环境变量"
fi
echo ""

# 3. 检查环境变量
echo "[3/6] 检查环境变量..."
echo "----------------------------------------"
if [ -f ".env" ]; then
  if grep -q "CHROME_PATH" .env; then
    echo "✅ .env 文件中设置了 CHROME_PATH:"
    grep "CHROME_PATH" .env
  else
    echo "⚠️  .env 文件中未设置 CHROME_PATH"
  fi
else
  echo "⚠️  .env 文件不存在"
fi
echo ""

# 4. 检查 puppeteer-core
echo "[4/6] 检查 puppeteer-core 模块..."
echo "----------------------------------------"
if [ -d "node_modules/puppeteer-core" ]; then
  echo "✅ puppeteer-core 已安装"
  npm list puppeteer-core 2>/dev/null | head -2
else
  echo "❌ puppeteer-core 未安装"
  echo "   请运行: npm install puppeteer-core"
fi
echo ""

# 5. 检查最近的文档处理日志
echo "[5/6] 检查最近的文档处理日志..."
echo "----------------------------------------"
pm2 logs feihub-backend --lines 200 --nostream | grep -E "\[处理文档\]|\[爬取\]|\[Puppeteer\]" | tail -20
echo ""

# 6. 测试 Puppeteer（如果 Chrome 已找到）
echo "[6/6] 测试 Puppeteer 启动..."
echo "----------------------------------------"
if [ -n "$FOUND_CHROME" ]; then
  cat > /tmp/test-puppeteer.js << 'EOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

async function test() {
  let browser;
  try {
    const chromePath = process.argv[2];
    console.log(`尝试使用 Chrome: ${chromePath}`);
    
    browser = await puppeteer.launch({
      headless: true,
      executablePath: chromePath,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu'
      ],
      timeout: 30000
    });
    
    console.log('✅ Puppeteer 启动成功！');
    
    const page = await browser.newPage();
    await page.goto('https://www.baidu.com', { timeout: 10000 });
    console.log('✅ 页面加载成功！');
    
    await browser.close();
    console.log('✅ 测试完成！');
    
  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    if (browser) {
      await browser.close();
    }
    process.exit(1);
  }
}

test();
EOF

  node /tmp/test-puppeteer.js "$FOUND_CHROME" 2>&1
  rm -f /tmp/test-puppeteer.js
else
  echo "⚠️  跳过测试（Chrome 未找到）"
fi

echo ""
echo "=========================================="
echo "  诊断完成"
echo "=========================================="


