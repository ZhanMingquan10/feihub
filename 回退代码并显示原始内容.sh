#!/bin/bash

# 回退代码并显示原始内容

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：回退代码 ==="

# 查找最早的备份文件
BACKUP=$(ls -t feishu-puppeteer.ts.bak* 2>/dev/null | tail -1)

if [ -z "$BACKUP" ]; then
    echo "未找到备份文件，从 Git 恢复..."
    cd /www/wwwroot/feihub
    git checkout HEAD -- backend/src/lib/feishu-puppeteer.ts
    echo "✅ 已从 Git 恢复"
else
    echo "找到备份文件: $BACKUP"
    cp "$BACKUP" feishu-puppeteer.ts
    echo "✅ 已恢复备份: $BACKUP"
fi

echo ""
echo "=== 第二步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 第三步：重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 回退完成！"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi

echo ""
echo "=== 第四步：创建显示原始内容的脚本 ==="
cd /www/wwwroot/feihub/backend

cat > show_raw_content.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 显示所有原始内容（不做任何处理）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(link, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await new Promise(resolve => setTimeout(resolve, 20000));

  const rawData = await page.evaluate(() => {
    return {
      // PageData
      pageData: window.__INITIAL_STATE__ || null,
      
      // Body 完整文本（不做任何处理）
      bodyText: document.body.innerText,
      bodyTextLength: document.body.innerText.length,
      
      // HTML（完整）
      html: document.documentElement.outerHTML,
      htmlLength: document.documentElement.outerHTML.length,
      
      // 所有选择器的完整内容（不做任何处理）
      selectors: []
    };
  });

  // 测试所有选择器
  const selectors = [
    '[class*="content"]',
    '[class*="body"]',
    '[class*="main"]',
    '.wiki-content',
    '.doc-content',
    'main article',
    'article',
    '[role="main"]',
    '.document-content',
    '.page-content',
    'main',
    '[class*="document"]',
    '[class*="page"]'
  ];

  for (const selector of selectors) {
    const elements = await page.$$(selector);
    for (let i = 0; i < Math.min(elements.length, 10); i++) {
      const text = await page.evaluate(el => (el.innerText || el.textContent || '').trim(), elements[i]);
      if (text.length > 0) {
        rawData.selectors.push({
          selector: selector,
          index: i,
          textLength: text.length,
          fullText: text
        });
      }
    }
  }

  // 保存 JSON（中文显示）
  fs.writeFileSync('/tmp/feishu_raw_content.json', JSON.stringify(rawData, null, 2));
  
  // 保存 Body 文本
  fs.writeFileSync('/tmp/feishu_raw_body.txt', rawData.bodyText, 'utf8');
  
  // 保存 HTML（如果太大，只保存前10MB）
  if (rawData.html.length > 10 * 1024 * 1024) {
    fs.writeFileSync('/tmp/feishu_raw_html_part1.html', rawData.html.substring(0, 10 * 1024 * 1024), 'utf8');
    fs.writeFileSync('/tmp/feishu_raw_html_part2.html', rawData.html.substring(10 * 1024 * 1024), 'utf8');
  } else {
    fs.writeFileSync('/tmp/feishu_raw_html.html', rawData.html, 'utf8');
  }
  
  console.log('=== 原始内容提取完成 ===');
  console.log('Body 文本长度:', rawData.bodyTextLength);
  console.log('HTML 长度:', rawData.htmlLength);
  console.log('选择器数量:', rawData.selectors.length);
  console.log('');
  console.log('✅ 原始 JSON 已保存到 /tmp/feishu_raw_content.json');
  console.log('✅ 原始 Body 文本已保存到 /tmp/feishu_raw_body.txt');
  console.log('✅ 原始 HTML 已保存到 /tmp/feishu_raw_html.html');
  
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本显示原始内容 ==="
node show_raw_content.js

echo ""
echo "=== 查看原始 Body 文本（前5000字符）==="
head -c 5000 /tmp/feishu_raw_body.txt
echo ""
echo ""

echo "✅ 完成！原始内容已保存到 /tmp/feishu_raw_*.json, /tmp/feishu_raw_body.txt, /tmp/feishu_raw_html.html"

