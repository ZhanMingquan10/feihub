#!/bin/bash

# 改进滚动 - 完整加载所有内容

cd /www/wwwroot/feihub/backend

echo "=== 创建改进的滚动脚本 ==="

cat > get_full_content_improved.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始提取完整内容（改进滚动）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });
  
  // 等待初始加载
  console.log('等待初始加载...');
  await new Promise(resolve => setTimeout(resolve, 10000));
  
  // 改进的滚动逻辑
  console.log('开始滚动页面...');
  
  let previousTextLength = 0;
  let currentTextLength = 0;
  let scrollAttempts = 0;
  let stableCount = 0;
  const maxScrollAttempts = 100;
  const maxStableCount = 5; // 连续5次内容不再增加才停止
  
  while (scrollAttempts < maxScrollAttempts && stableCount < maxStableCount) {
    // 获取当前内容长度
    currentTextLength = await page.evaluate(() => document.body.innerText.length);
    
    if (currentTextLength === previousTextLength) {
      stableCount++;
    } else {
      stableCount = 0;
      console.log(`滚动尝试 ${scrollAttempts + 1}: 内容长度 ${currentTextLength} 字符（增加了 ${currentTextLength - previousTextLength} 字符）`);
    }
    
    previousTextLength = currentTextLength;
    
    // 缓慢滚动到底部
    await page.evaluate(async () => {
      const scrollStep = 200; // 每次滚动200px，更慢
      const scrollDelay = 300; // 每次滚动间隔300ms，更长
      const scrollHeight = document.body.scrollHeight;
      const viewportHeight = window.innerHeight;
      let currentPosition = window.scrollY;
      
      // 滚动到底部
      while (currentPosition + viewportHeight < scrollHeight - 100) {
        currentPosition += scrollStep;
        window.scrollTo(0, currentPosition);
        await new Promise(resolve => setTimeout(resolve, scrollDelay));
      }
      
      // 确保滚动到最底部
      window.scrollTo(0, scrollHeight);
      await new Promise(resolve => setTimeout(resolve, 500));
    });
    
    // 等待内容加载
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 检查页面高度是否增加
    const newHeight = await page.evaluate(() => document.body.scrollHeight);
    const newTextLength = await page.evaluate(() => document.body.innerText.length);
    
    // 如果内容增加了，继续滚动
    if (newTextLength > currentTextLength) {
      currentTextLength = newTextLength;
      stableCount = 0;
    }
    
    scrollAttempts++;
    
    // 每10次滚动输出一次进度
    if (scrollAttempts % 10 === 0) {
      console.log(`进度: 已滚动 ${scrollAttempts} 次，当前内容长度: ${currentTextLength} 字符，页面高度: ${newHeight}px`);
    }
  }
  
  console.log(`滚动完成！最终内容长度: ${currentTextLength} 字符`);
  console.log(`总共滚动 ${scrollAttempts} 次`);
  
  // 滚动回顶部
  await page.evaluate(() => window.scrollTo(0, 0));
  await new Promise(resolve => setTimeout(resolve, 2000));

  // 提取所有原始内容
  const allData = await page.evaluate(() => {
    const result = {
      pageData: window.__INITIAL_STATE__ || null,
      bodyText: {
        full: document.body.innerText,
        length: document.body.innerText.length
      },
      selectors: [],
      pageInfo: {
        scrollHeight: document.body.scrollHeight,
        clientHeight: document.documentElement.clientHeight
      }
    };

    // 统计一级标题数量
    const h1Count = document.querySelectorAll('h1').length;
    const headingCount = document.querySelectorAll('[class*="heading"], h1, h2').length;
    result.headingCount = {
      h1: h1Count,
      allHeadings: headingCount
    };

    // 测试所有可能的选择器
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
          fullText: text,
          className: el.className,
          tagName: el.tagName,
          id: el.id
        });
      }
    }

    return result;
  });

  // 保存 JSON（中文显示）
  fs.writeFileSync('/tmp/feishu_full_content.json', JSON.stringify(allData, null, 2));
  
  // 保存 Body 文本
  fs.writeFileSync('/tmp/feishu_body_text.txt', allData.bodyText.full, 'utf8');
  
  console.log('=== 提取完成 ===');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('页面高度:', allData.pageInfo.scrollHeight);
  console.log('一级标题数量:', allData.headingCount.h1);
  console.log('所有标题数量:', allData.headingCount.allHeadings);
  console.log('选择器数量:', allData.selectors.length);
  console.log('');
  console.log('✅ 完整 JSON（中文显示）已保存到 /tmp/feishu_full_content.json');
  console.log('✅ Body 文本已保存到 /tmp/feishu_body_text.txt');
  
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本（可能需要较长时间）==="
node get_full_content_improved.js

echo ""
echo "=== 查看 Body 文本长度 ==="
wc -c /tmp/feishu_body_text.txt

echo ""
echo "=== 查看 Body 文本（前5000字符）==="
head -c 5000 /tmp/feishu_body_text.txt
echo ""
echo ""

echo "=== 统计一级标题 ==="
grep -c "^一、" /tmp/feishu_body_text.txt || echo "未找到一级标题"

echo ""
echo "✅ 完成！"

