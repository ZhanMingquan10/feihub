#!/bin/bash

# 查看所有原始 JSON 数据 - 添加滚动加载

cd /www/wwwroot/feihub/backend

echo "=== 创建诊断脚本（带滚动）==="

cat > get_all_json.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始提取所有原始数据（带滚动加载）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });
  
  // 等待初始加载
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  console.log('开始滚动页面加载所有内容...');
  
  // 滚动到底部，触发懒加载
  let previousHeight = 0;
  let currentHeight = await page.evaluate(() => document.body.scrollHeight);
  let scrollAttempts = 0;
  const maxScrollAttempts = 50; // 最多滚动50次
  
  while (scrollAttempts < maxScrollAttempts && currentHeight > previousHeight) {
    previousHeight = currentHeight;
    
    // 缓慢滚动到底部
    await page.evaluate(async () => {
      const scrollStep = 300; // 每次滚动300px
      const scrollDelay = 200; // 每次滚动间隔200ms
      const scrollHeight = document.body.scrollHeight;
      let currentPosition = window.scrollY;
      
      while (currentPosition < scrollHeight) {
        currentPosition += scrollStep;
        window.scrollTo(0, currentPosition);
        await new Promise(resolve => setTimeout(resolve, scrollDelay));
      }
    });
    
    // 等待内容加载
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // 检查页面高度是否增加
    currentHeight = await page.evaluate(() => document.body.scrollHeight);
    scrollAttempts++;
    
    console.log(`滚动尝试 ${scrollAttempts}: 页面高度 ${currentHeight}px`);
    
    // 如果高度没有变化，再等待一下确保内容加载完成
    if (currentHeight === previousHeight) {
      await new Promise(resolve => setTimeout(resolve, 3000));
      currentHeight = await page.evaluate(() => document.body.scrollHeight);
    }
  }
  
  console.log(`滚动完成，最终页面高度: ${currentHeight}px`);
  
  // 滚动回顶部
  await page.evaluate(() => window.scrollTo(0, 0));
  await new Promise(resolve => setTimeout(resolve, 1000));

  const allData = await page.evaluate(() => {
    const result = {
      pageData: window.__INITIAL_STATE__ || null,
      title: {
        fromPageData: (window.__INITIAL_STATE__ && window.__INITIAL_STATE__.pageData && window.__INITIAL_STATE__.pageData.title) || '',
        fromMeta: (document.querySelector('meta[property="og:title"]') && document.querySelector('meta[property="og:title"]').getAttribute('content')) || '',
        fromH1: (document.querySelector('h1') && document.querySelector('h1').innerText) || '',
        fromTitle: document.title || ''
      },
      date: {
        fromPageData: (window.__INITIAL_STATE__ && window.__INITIAL_STATE__.pageData && window.__INITIAL_STATE__.pageData.updateTime) || '',
        fromTimeElement: (document.querySelector('.doc-info-time-item') && document.querySelector('.doc-info-time-item').innerText) || '',
        fromAllTimeElements: Array.from(document.querySelectorAll('[class*="time"], [class*="date"]')).map(el => el.innerText).filter(t => t)
      },
      author: {
        fromPageData: (window.__INITIAL_STATE__ && window.__INITIAL_STATE__.pageData && window.__INITIAL_STATE__.pageData.author) || '',
        fromAuthorElement: (document.querySelector('[class*="author"], [class*="creator"]') && document.querySelector('[class*="author"], [class*="creator"]').innerText) || ''
      },
      bodyText: {
        full: document.body.innerText,
        length: document.body.innerText.length,
        logInIndex: document.body.innerText.indexOf('Log In or Sign Up'),
        afterLogIn: document.body.innerText.indexOf('Log In or Sign Up') > 0 ? document.body.innerText.substring(document.body.innerText.indexOf('Log In or Sign Up') + 'Log In or Sign Up'.length) : ''
      },
      metaTags: Array.from(document.querySelectorAll('meta')).map(meta => ({
        name: meta.getAttribute('name'),
        property: meta.getAttribute('property'),
        content: meta.getAttribute('content')
      })),
      selectors: [],
      pageInfo: {
        scrollHeight: document.body.scrollHeight,
        clientHeight: document.documentElement.clientHeight,
        scrollWidth: document.body.scrollWidth,
        clientWidth: document.documentElement.clientWidth
      }
    };

    const selectors = ['[class*="content"]', '[class*="body"]', '.wiki-content', '.doc-content', 'article'];
    for (const selector of selectors) {
      const elements = document.querySelectorAll(selector);
      for (let i = 0; i < Math.min(elements.length, 5); i++) {
        const el = elements[i];
        const text = (el.innerText || el.textContent || '').trim();
        result.selectors.push({
          selector: selector,
          index: i,
          textLength: text.length,
          fullText: text,
          hasChinese: /[\u4e00-\u9fa5]/.test(text),
          hasHelpCenter: text.includes('Help Center'),
          hasLogIn: text.includes('Log In or Sign Up'),
          hasCreated: text.includes('Created on'),
          hasModified: text.includes('Modified')
        });
      }
    }

    if (result.bodyText.afterLogIn) {
      const createdMatch = result.bodyText.afterLogIn.match(/Created on\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      const modifiedMatch = result.bodyText.afterLogIn.match(/Modified\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      if (createdMatch) {
        result.extractedDate = { type: 'Created', full: createdMatch[0], month: createdMatch[1], day: createdMatch[2], year: createdMatch[3] || '', index: createdMatch.index };
      } else if (modifiedMatch) {
        result.extractedDate = { type: 'Modified', full: modifiedMatch[0], month: modifiedMatch[1], day: modifiedMatch[2], year: modifiedMatch[3] || '', index: modifiedMatch.index };
      }
      if (result.extractedDate) {
        const dateStart = result.extractedDate.index;
        const dateEnd = dateStart + result.extractedDate.full.length;
        result.titleBeforeDate = result.bodyText.afterLogIn.substring(0, dateStart).trim();
        result.contentAfterDate = result.bodyText.afterLogIn.substring(dateEnd).trim();
      }
    }

    return result;
  });

  fs.writeFileSync('/tmp/feishu_all_json.json', JSON.stringify(allData, null, 2));
  console.log('✅ 完整 JSON 已保存到 /tmp/feishu_all_json.json');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('页面高度:', allData.pageInfo.scrollHeight);
  console.log('Log In or Sign Up 位置:', allData.bodyText.logInIndex);
  if (allData.extractedDate) {
    console.log('提取的日期:', allData.extractedDate.full);
    console.log('日期后的正文长度:', allData.contentAfterDate.length);
  }
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本（可能需要一些时间，因为需要滚动加载）==="
node get_all_json.js

echo ""
echo "=== 查看完整 JSON ==="
cat /tmp/feishu_all_json.json | python3 -m json.tool | head -500

echo ""
echo "✅ 完成！完整 JSON 已保存到 /tmp/feishu_all_json.json"

