#!/bin/bash

# 详细诊断 - 查看滚动后的实际内容

cd /www/wwwroot/feihub/backend

echo "=== 创建详细诊断脚本 ==="

cat > diagnose_scrolled.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始详细诊断（带滚动）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  console.log('开始滚动页面...');
  
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

  const allData = await page.evaluate(() => {
    const result = {
      bodyText: {
        full: document.body.innerText,
        length: document.body.innerText.length,
        logInIndex: document.body.innerText.indexOf('Log In or Sign Up'),
        afterLogIn: document.body.innerText.indexOf('Log In or Sign Up') > 0 ? document.body.innerText.substring(document.body.innerText.indexOf('Log In or Sign Up') + 'Log In or Sign Up'.length) : '',
        containsTargetText: document.body.innerText.includes('一、创建知识库')
      },
      selectors: []
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
          textPreview: text.substring(0, 500),
          fullText: text,
          className: el.className,
          tagName: el.tagName,
          id: el.id,
          hasChinese: /[\u4e00-\u9fa5]/.test(text),
          hasTargetText: text.includes('一、创建知识库'),
          hasHelpCenter: text.includes('Help Center'),
          hasLogIn: text.includes('Log In or Sign Up')
        });
      }
    }

    // 查找包含目标文本的元素
    const allElements = document.querySelectorAll('*');
    const targetElements = [];
    for (let i = 0; i < Math.min(allElements.length, 1000); i++) {
      const el = allElements[i];
      const text = (el.innerText || el.textContent || '').trim();
      if (text.includes('一、创建知识库') && text.length > 100) {
        targetElements.push({
          tagName: el.tagName,
          className: el.className,
          id: el.id,
          textLength: text.length,
          textPreview: text.substring(0, 300)
        });
      }
    }
    result.targetElements = targetElements;

    // 查找日期
    if (result.bodyText.afterLogIn) {
      const createdMatch = result.bodyText.afterLogIn.match(/Created on\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      const modifiedMatch = result.bodyText.afterLogIn.match(/Modified\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      if (createdMatch) {
        result.extractedDate = { type: 'Created', full: createdMatch[0] };
      } else if (modifiedMatch) {
        result.extractedDate = { type: 'Modified', full: modifiedMatch[0] };
      }
    }

    return result;
  });

  fs.writeFileSync('/tmp/feishu_detailed.json', JSON.stringify(allData, null, 2));
  
  console.log('=== 诊断结果 ===');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('包含目标文本（一、创建知识库）:', allData.bodyText.containsTargetText);
  console.log('Log In or Sign Up 位置:', allData.bodyText.logInIndex);
  console.log('Log In 之后的内容长度:', allData.bodyText.afterLogIn.length);
  console.log('');
  
  console.log('=== 包含目标文本的元素 ===');
  if (allData.targetElements && allData.targetElements.length > 0) {
    allData.targetElements.forEach((el, idx) => {
      console.log(`元素 ${idx + 1}: ${el.tagName}.${el.className || '无类名'}#${el.id || '无ID'}`);
      console.log(`  文本长度: ${el.textLength}`);
      console.log(`  预览: ${el.textPreview.substring(0, 200)}`);
    });
  } else {
    console.log('未找到包含目标文本的元素');
  }
  console.log('');
  
  console.log('=== 选择器匹配结果（包含目标文本的）===');
  const matchingSelectors = allData.selectors.filter(s => s.hasTargetText);
  if (matchingSelectors.length > 0) {
    matchingSelectors.forEach((sel, idx) => {
      console.log(`\n选择器 ${idx + 1}: ${sel.selector}[${sel.index}]`);
      console.log(`  标签: ${sel.tagName}, 类名: ${sel.className}`);
      console.log(`  文本长度: ${sel.textLength}`);
      console.log(`  完整文本（前1000字符）: ${sel.fullText.substring(0, 1000)}`);
    });
  } else {
    console.log('未找到包含目标文本的选择器匹配');
  }
  console.log('');
  
  console.log('✅ 详细数据已保存到 /tmp/feishu_detailed.json');
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行诊断（可能需要一些时间）==="
node diagnose_scrolled.js

echo ""
echo "=== 查看详细 JSON ==="
cat /tmp/feishu_detailed.json | python3 -m json.tool | head -600

echo ""
echo "✅ 完成！"

