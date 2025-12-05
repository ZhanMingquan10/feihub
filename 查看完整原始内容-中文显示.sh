#!/bin/bash

# 查看完整原始内容 - 中文显示

cd /www/wwwroot/feihub/backend

echo "=== 创建脚本（中文显示，完整原始内容）==="

cat > get_full_content.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始提取完整原始内容（带滚动，中文显示）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  console.log('开始滚动页面加载所有内容...');
  
  // 滚动到底部
  let previousHeight = 0;
  let currentHeight = await page.evaluate(() => document.body.scrollHeight);
  let scrollAttempts = 0;
  
  while (scrollAttempts < 50 && currentHeight > previousHeight) {
    previousHeight = currentHeight;
    
    await page.evaluate(async () => {
      const scrollStep = 300;
      const scrollDelay = 200;
      const scrollHeight = document.body.scrollHeight;
      let currentPosition = window.scrollY;
      
      while (currentPosition < scrollHeight) {
        currentPosition += scrollStep;
        window.scrollTo(0, currentPosition);
        await new Promise(resolve => setTimeout(resolve, scrollDelay));
      }
    });
    
    await new Promise(resolve => setTimeout(resolve, 2000));
    currentHeight = await page.evaluate(() => document.body.scrollHeight);
    scrollAttempts++;
    
    if (scrollAttempts % 10 === 0) {
      console.log(`滚动尝试 ${scrollAttempts}: 页面高度 ${currentHeight}px`);
    }
    
    if (currentHeight === previousHeight) {
      await new Promise(resolve => setTimeout(resolve, 3000));
      currentHeight = await page.evaluate(() => document.body.scrollHeight);
    }
  }
  
  console.log(`滚动完成，最终页面高度: ${currentHeight}px`);
  await page.evaluate(() => window.scrollTo(0, 0));
  await new Promise(resolve => setTimeout(resolve, 1000));

  // 提取所有原始内容
  const allData = await page.evaluate(() => {
    const result = {
      // 完整 HTML
      html: document.documentElement.outerHTML,
      htmlLength: document.documentElement.outerHTML.length,
      
      // PageData
      pageData: window.__INITIAL_STATE__ || null,
      
      // Body 完整文本（不做任何处理）
      bodyText: {
        full: document.body.innerText,
        length: document.body.innerText.length
      },
      
      // 所有选择器的完整内容（不做任何处理）
      selectors: []
    };

    // 测试所有可能的选择器，保存完整内容
    const selectors = [
      '[class*="content"]',
      '[class*="body"]',
      '[class*="main"]',
      '.wiki-content',
      '.wiki-body',
      '.doc-content',
      '.doc-body',
      'main article',
      'article',
      '[role="main"]',
      '.document-content',
      '.page-content',
      '[data-content]',
      'main',
      '[class*="document"]',
      '[class*="page"]'
    ];

    for (const selector of selectors) {
      const elements = document.querySelectorAll(selector);
      for (let i = 0; i < Math.min(elements.length, 10); i++) {
        const el = elements[i];
        const text = (el.innerText || el.textContent || '').trim();
        result.selectors.push({
          selector: selector,
          index: i,
          textLength: text.length,
          fullText: text,  // 完整文本，不做任何处理
          className: el.className,
          tagName: el.tagName,
          id: el.id
        });
      }
    }

    return result;
  });

  // 保存 JSON（使用 ensure_ascii: false 显示中文）
  fs.writeFileSync('/tmp/feishu_full_content.json', JSON.stringify(allData, null, 2));
  
  // 单独保存 Body 文本（纯文本，方便查看）
  fs.writeFileSync('/tmp/feishu_body_text.txt', allData.bodyText.full, 'utf8');
  
  // 单独保存 HTML（如果太大，只保存前10MB）
  const htmlContent = allData.html;
  if (htmlContent.length > 10 * 1024 * 1024) {
    fs.writeFileSync('/tmp/feishu_html_part1.html', htmlContent.substring(0, 10 * 1024 * 1024), 'utf8');
    fs.writeFileSync('/tmp/feishu_html_part2.html', htmlContent.substring(10 * 1024 * 1024), 'utf8');
    console.log('HTML 太大，已分成两部分保存');
  } else {
    fs.writeFileSync('/tmp/feishu_html.html', htmlContent, 'utf8');
  }
  
  console.log('=== 提取完成 ===');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('HTML 长度:', allData.htmlLength);
  console.log('选择器数量:', allData.selectors.length);
  console.log('');
  console.log('✅ 完整 JSON（中文显示）已保存到 /tmp/feishu_full_content.json');
  console.log('✅ Body 文本已保存到 /tmp/feishu_body_text.txt');
  console.log('✅ HTML 已保存到 /tmp/feishu_html.html');
  
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本（可能需要一些时间）==="
node get_full_content.js

echo ""
echo "=== 查看 Body 文本（前2000字符）==="
head -c 2000 /tmp/feishu_body_text.txt
echo ""
echo ""

echo "=== 查看完整 JSON（中文显示）==="
cat /tmp/feishu_full_content.json | python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps(data, indent=2, ensure_ascii=False))" | head -1000

echo ""
echo "=== 查看选择器内容（前5个，完整文本）==="
cat /tmp/feishu_full_content.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for i, sel in enumerate(data['selectors'][:5]):
    print(f'\n选择器 {i+1}: {sel[\"selector\"]}[{sel[\"index\"]}]')
    print(f'  标签: {sel[\"tagName\"]}, 类名: {sel.get(\"className\", \"无\")}')
    print(f'  文本长度: {sel[\"textLength\"]}')
    print(f'  完整文本（前2000字符）:')
    print(sel['fullText'][:2000])
"

echo ""
echo "✅ 完成！"
echo "完整内容文件："
echo "  - /tmp/feishu_full_content.json (JSON，中文显示)"
echo "  - /tmp/feishu_body_text.txt (Body 纯文本)"
echo "  - /tmp/feishu_html.html (完整 HTML)"

