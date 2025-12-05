# 检查 Puppeteer 和 Chrome 状态

## 🔍 问题分析

标题和正文都没有获取到，可能是：
1. **Chrome/Chromium 未安装**：Puppeteer 需要 Chrome 浏览器
2. **Chrome 路径不正确**：系统找不到 Chrome 可执行文件
3. **Puppeteer 启动失败**：权限问题或其他错误

---

## 🔧 检查步骤

### 第一步：检查 PM2 日志（最重要）

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 查看最新的 PM2 日志
pm2 logs feihub-backend --lines 100 --nostream | grep -E "(Puppeteer|Chrome|爬取|处理文档|错误|Error)" | tail -50

# 或者查看所有日志
pm2 logs feihub-backend --lines 200 --nostream | tail -100
```

**重点关注**：
- `[启动] ✅ Puppeteer 可用` 或 `[启动] ⚠️ Puppeteer 不可用`
- `Chrome/Chromium not found`
- `[爬取] Puppeteer 获取失败`
- `[处理文档] 处理失败`

---

### 第二步：检查 Chrome 是否安装

在宝塔终端执行：

```bash
# 检查 Chrome 是否安装
which google-chrome
which chromium
which chromium-browser

# 检查常见的 Chrome 路径
ls -la /usr/bin/google-chrome* 2>/dev/null
ls -la /usr/bin/chromium* 2>/dev/null
ls -la /snap/bin/chromium 2>/dev/null

# 检查环境变量
echo $CHROME_PATH
```

---

### 第三步：检查 Puppeteer 模块

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 检查 puppeteer-core 是否安装
npm list puppeteer-core

# 检查 node_modules
ls -la node_modules/puppeteer-core 2>/dev/null
```

---

### 第四步：测试 Puppeteer 启动

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 创建一个测试脚本
cat > test-puppeteer.js << 'EOF'
const puppeteer = require('puppeteer-core');

async function test() {
  let browser;
  try {
    console.log('开始测试 Puppeteer...');
    
    // 尝试常见的 Chrome 路径
    const paths = [
      '/usr/bin/google-chrome',
      '/usr/bin/google-chrome-stable',
      '/usr/bin/chromium',
      '/usr/bin/chromium-browser',
      '/snap/bin/chromium',
      process.env.CHROME_PATH
    ].filter(Boolean);
    
    console.log('尝试的路径:', paths);
    
    let executablePath = null;
    for (const path of paths) {
      try {
        const fs = require('fs');
        if (fs.existsSync(path)) {
          executablePath = path;
          console.log(`✅ 找到 Chrome: ${path}`);
          break;
        }
      } catch (e) {
        // 继续尝试下一个
      }
    }
    
    if (!executablePath) {
      console.error('❌ 未找到 Chrome，请安装 Chrome 或设置 CHROME_PATH 环境变量');
      process.exit(1);
    }
    
    console.log(`使用 Chrome: ${executablePath}`);
    
    browser = await puppeteer.launch({
      headless: true,
      executablePath: executablePath,
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
    console.error('错误堆栈:', error.stack);
    if (browser) {
      await browser.close();
    }
    process.exit(1);
  }
}

test();
EOF

# 运行测试
node test-puppeteer.js
```

---

## 🚀 如果 Chrome 未安装

### 安装 Chrome（Ubuntu/Debian）

在宝塔终端执行：

```bash
# 方法 1：安装 Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt-get update
sudo apt-get install -y ./google-chrome-stable_current_amd64.deb

# 验证安装
which google-chrome-stable
google-chrome-stable --version
```

或者：

```bash
# 方法 2：安装 Chromium（更轻量）
sudo apt-get update
sudo apt-get install -y chromium-browser

# 验证安装
which chromium-browser
chromium-browser --version
```

---

## 🔧 如果 Chrome 已安装但找不到

### 设置环境变量

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend

# 找到 Chrome 路径
CHROME_PATH=$(which google-chrome-stable || which chromium-browser || which chromium)
echo "Chrome 路径: $CHROME_PATH"

# 添加到 .env 文件
echo "CHROME_PATH=$CHROME_PATH" >> .env
cat .env | grep CHROME_PATH

# 重启 PM2
pm2 restart feihub-backend
```

---

## 📝 检查后端代码中的 Chrome 路径查找逻辑

让我检查一下 `getChromePath()` 函数的实现。


