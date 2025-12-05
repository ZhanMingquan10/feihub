#!/bin/bash

# 保存页面 HTML - 查看所有内容

cd /www/wwwroot/feihub/backend

echo "=== 创建脚本保存页面 HTML ==="

cat > save_page_html.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

(async () => {
  console.log('=== 开始保存页面 HTML ===');
  const link = 'https://ai.feishu.cn/docx/VGoXdFXmooasHUxsZ0icAD2WnGe';
  
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });
  
  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
  
  console.log('正在加载页面...');
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });
  
  console.log('等待内容渲染...');
  await new Promise(resolve => setTimeout(resolve, 15000));
  
  // 保存完整 HTML
  const html = await page.content();
  fs.writeFileSync('/tmp/feishu_page_full.html', html);
  console.log('✅ 完整 HTML 已保存到 /tmp/feishu_page_full.html');
  
  // 提取并保存正文内容（尝试多种选择器）
  const contentInfo = await page.evaluate(() => {
    const result = {
      selectors: [],
      bodyText: document.body.innerText.substring(0, 5000)
    };
    
    const selectors = [
      '[class*="content"]',
      '[class*="body"]',
      '[class*="main"]',
      '.wiki-content',
      '.doc-content',
      'article',
      '[role="main"]'
    ];
    
    for (const selector of selectors) {
      const elements = document.querySelectorAll(selector);
      for (let i = 0; i < Math.min(elements.length, 3); i++) {
        const el = elements[i];
        const text = (el.innerText || el.textContent || '').trim();
        result.selectors.push({
          selector: selector,
          index: i,
          textLength: text.length,
          textPreview: text.substring(0, 200),
          hasChinese: /[\u4e00-\u9fa5]/.test(text),
          hasHelpCenter: text.includes('Help Center')
        });
      }
    }
    
    return result;
  });
  
  fs.writeFileSync('/tmp/feishu_content_info.json', JSON.stringify(contentInfo, null, 2));
  console.log('✅ 内容信息已保存到 /tmp/feishu_content_info.json');
  
  await browser.close();
  console.log('=== 完成 ===');
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本 ==="
node save_page_html.js

echo ""
echo "=== 查看内容信息 ==="
cat /tmp/feishu_content_info.json

echo ""
echo "=== 查找正文内容 ==="
echo "在 HTML 中查找 '嗨，你好'："
grep -o -A 20 -B 5 "嗨，你好" /tmp/feishu_page_full.html | head -50

echo ""
echo "=== 查看 HTML 文件大小 ==="
ls -lh /tmp/feishu_page_full.html

echo ""
echo "✅ 完成！请查看 /tmp/feishu_content_info.json 和 /tmp/feishu_page_full.html"

