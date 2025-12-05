#!/bin/bash

# 优化滚动 - 完整加载所有内容

cd /www/wwwroot/feihub/backend

echo "=== 创建优化的滚动脚本 ==="

cat > get_full_content_optimized.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始提取完整内容（优化滚动）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  
  // 监听网络请求，确保内容加载完成
  let networkIdle = false;
  page.on('response', () => {
    networkIdle = false;
  });
  
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 60000 });
  
  console.log('等待初始加载...');
  await new Promise(resolve => setTimeout(resolve, 15000));
  
  console.log('开始滚动页面（优化版）...');
  
  let previousTextLength = 0;
  let currentTextLength = 0;
  let scrollAttempts = 0;
  let stableCount = 0;
  const maxScrollAttempts = 200;
  const maxStableCount = 10; // 连续10次内容不再增加才停止
  
  // 获取初始内容长度
  currentTextLength = await page.evaluate(() => document.body.innerText.length);
  console.log(`初始内容长度: ${currentTextLength} 字符`);
  
  while (scrollAttempts < maxScrollAttempts && stableCount < maxStableCount) {
    previousTextLength = currentTextLength;
    
    // 方法1: 使用 requestAnimationFrame 平滑滚动
    await page.evaluate(async () => {
      return new Promise((resolve) => {
        const scrollStep = 100; // 每次滚动100px，更小
        const scrollDelay = 100; // 每次滚动间隔100ms
        const scrollHeight = document.body.scrollHeight;
        const viewportHeight = window.innerHeight;
        let currentPosition = window.scrollY;
        let lastHeight = scrollHeight;
        
        const scroll = () => {
          if (currentPosition + viewportHeight < scrollHeight - 50) {
            currentPosition += scrollStep;
            window.scrollTo({
              top: currentPosition,
              behavior: 'smooth'
            });
            
            // 检查高度是否增加
            const newHeight = document.body.scrollHeight;
            if (newHeight > lastHeight) {
              lastHeight = newHeight;
            }
            
            setTimeout(scroll, scrollDelay);
          } else {
            // 滚动到最底部
            window.scrollTo({
              top: scrollHeight,
              behavior: 'smooth'
            });
            setTimeout(resolve, 2000);
          }
        };
        
        scroll();
      });
    });
    
    // 等待内容加载
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // 再次滚动到底部，确保触发所有懒加载
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 检查内容长度
    currentTextLength = await page.evaluate(() => document.body.innerText.length);
    
    if (currentTextLength === previousTextLength) {
      stableCount++;
      console.log(`滚动尝试 ${scrollAttempts + 1}: 内容长度 ${currentTextLength} 字符（未增加，稳定 ${stableCount} 次）`);
    } else {
      stableCount = 0;
      console.log(`滚动尝试 ${scrollAttempts + 1}: 内容长度 ${currentTextLength} 字符（增加了 ${currentTextLength - previousTextLength} 字符）`);
    }
    
    scrollAttempts++;
    
    // 每5次滚动输出一次进度
    if (scrollAttempts % 5 === 0) {
      const pageHeight = await page.evaluate(() => document.body.scrollHeight);
      console.log(`进度: 已滚动 ${scrollAttempts} 次，内容长度: ${currentTextLength} 字符，页面高度: ${pageHeight}px`);
    }
    
    // 如果内容很长了，再滚动几次确保完整
    if (currentTextLength > 5000 && stableCount >= 3) {
      // 再滚动几次确保完整
      for (let i = 0; i < 5; i++) {
        await page.evaluate(() => {
          window.scrollTo(0, document.body.scrollHeight);
        });
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
      break;
    }
  }
  
  console.log(`滚动完成！最终内容长度: ${currentTextLength} 字符`);
  console.log(`总共滚动 ${scrollAttempts} 次`);
  
  // 最后再等待一下，确保所有内容加载完成
  await new Promise(resolve => setTimeout(resolve, 5000));
  
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
    const headings = document.body.innerText.match(/^一、[^\n]+/gm);
    result.headingCount = {
      h1: document.querySelectorAll('h1').length,
      firstLevelHeadings: headings ? headings.length : 0,
      allHeadings: document.querySelectorAll('[class*="heading"], h1, h2, h3').length
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
        if (text.length > 0) {
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
  console.log('一级标题数量:', allData.headingCount.firstLevelHeadings);
  console.log('H1 标签数量:', allData.headingCount.h1);
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
echo "=== 执行脚本（可能需要较长时间，请耐心等待）==="
node get_full_content_optimized.js

echo ""
echo "=== 查看结果 ==="
echo "Body 文本长度:"
wc -c /tmp/feishu_body_text.txt

echo ""
echo "一级标题数量（应该看到7个）:"
grep -c "^一、" /tmp/feishu_body_text.txt || echo "未找到"

echo ""
echo "所有一级标题:"
grep "^一、" /tmp/feishu_body_text.txt

echo ""
echo "=== 查看 Body 文本（前15000字符）==="
head -c 15000 /tmp/feishu_body_text.txt
echo ""
echo ""

echo "✅ 完成！"

