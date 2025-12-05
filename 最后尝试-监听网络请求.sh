#!/bin/bash

# 最后尝试 - 监听网络请求

cd /www/wwwroot/feihub/backend

echo "=== 创建监听网络请求的脚本 ==="

cat > get_full_content_final.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 最后尝试：监听网络请求 ===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--window-size=1920,1080',
      '--disable-dev-shm-usage'
    ]
  });

  const page = await browser.newPage();
  
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, 'webdriver', {
      get: () => false,
    });
  });
  
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
  await page.setViewport({ width: 1920, height: 1080 });
  
  // 监听所有网络请求
  const apiRequests = [];
  page.on('response', async (response) => {
    const url = response.url();
    if (url.includes('api') || url.includes('docx') || url.includes('feishu')) {
      apiRequests.push({
        url: url,
        status: response.status(),
        headers: response.headers()
      });
      console.log(`API 请求: ${url.substring(0, 100)}... (状态: ${response.status()})`);
    }
  });
  
  try {
    await page.goto(link, { 
      waitUntil: 'domcontentloaded',
      timeout: 120000
    });
  } catch (error) {
    console.log('页面加载超时，但继续尝试...');
  }
  
  console.log('等待初始加载和API请求...');
  await new Promise(resolve => setTimeout(resolve, 30000));
  
  // 尝试滚动并等待API请求
  console.log('开始滚动并监听API请求...');
  for (let i = 0; i < 50; i++) {
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    const state = await page.evaluate(() => ({
      scrollHeight: document.body.scrollHeight,
      textLength: document.body.innerText.length
    }));
    
    if (i % 10 === 0) {
      console.log(`第 ${i + 1} 轮: 文本长度 ${state.textLength}, 页面高度 ${state.scrollHeight}px, API请求数 ${apiRequests.length}`);
    }
  }
  
  await new Promise(resolve => setTimeout(resolve, 10000));
  
  const allData = await page.evaluate(() => {
    return {
      pageData: window.__INITIAL_STATE__ || null,
      bodyText: {
        full: document.body.innerText,
        length: document.body.innerText.length
      },
      pageInfo: {
        scrollHeight: document.body.scrollHeight,
        allElements: document.querySelectorAll('*').length
      }
    };
  });
  
  allData.apiRequests = apiRequests;
  
  fs.writeFileSync('/tmp/feishu_full_content.json', JSON.stringify(allData, null, 2));
  fs.writeFileSync('/tmp/feishu_body_text.txt', allData.bodyText.full, 'utf8');
  
  console.log('=== 提取完成 ===');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('页面高度:', allData.pageInfo.scrollHeight);
  console.log('API请求数量:', apiRequests.length);
  console.log('');
  console.log('✅ 完整 JSON 已保存到 /tmp/feishu_full_content.json');
  console.log('✅ Body 文本已保存到 /tmp/feishu_body_text.txt');
  
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本 ==="
node get_full_content_final.js

echo ""
echo "=== 如果还是不行，准备回退代码 ==="

