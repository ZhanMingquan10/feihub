#!/bin/bash

# 改进脚本 - 禁用 webdriver 检测，优化滚动

cd /www/wwwroot/feihub/backend

echo "=== 创建改进脚本（禁用 webdriver 检测）==="

cat > get_full_content_fixed.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始提取完整内容（禁用 webdriver 检测）===');
  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--window-size=1920,1080',
      '--disable-dev-shm-usage',
      '--disable-gpu'
    ]
  });

  const page = await browser.newPage();
  
  // 禁用 webdriver 检测
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, 'webdriver', {
      get: () => false,
    });
    
    // 覆盖 plugins
    Object.defineProperty(navigator, 'plugins', {
      get: () => [1, 2, 3, 4, 5],
    });
    
    // 覆盖 languages
    Object.defineProperty(navigator, 'languages', {
      get: () => ['zh-CN', 'zh', 'en'],
    });
  });
  
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
  await page.setViewport({ width: 1920, height: 1080 });
  
  // 设置额外的 headers
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  });
  
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 60000 });
  
  console.log('等待初始加载...');
  await new Promise(resolve => setTimeout(resolve, 20000));
  
  let initialState = await page.evaluate(() => ({
    scrollHeight: document.body.scrollHeight,
    textLength: document.body.innerText.length
  }));
  console.log(`初始状态: 页面高度 ${initialState.scrollHeight}px, 文本长度 ${initialState.textLength} 字符`);
  
  console.log('开始改进的滚动...');
  
  // 使用更激进的滚动策略
  for (let round = 0; round < 100; round++) {
    const beforeState = await page.evaluate(() => ({
      scrollHeight: document.body.scrollHeight,
      textLength: document.body.innerText.length,
      scrollY: window.scrollY
    }));
    
    // 方法1: 使用 scrollBy 逐步滚动
    await page.evaluate(async () => {
      return new Promise((resolve) => {
        let totalHeight = 0;
        const distance = 100; // 每次滚动100px
        const scrollHeight = document.body.scrollHeight;
        const viewportHeight = window.innerHeight;
        
        const timer = setInterval(() => {
          window.scrollBy(0, distance);
          totalHeight += distance;
          
          // 检查是否需要继续滚动
          const currentScrollY = window.scrollY;
          const remainingHeight = scrollHeight - currentScrollY - viewportHeight;
          
          if (remainingHeight <= 0) {
            // 滚动到底部
            window.scrollTo(0, scrollHeight);
            clearInterval(timer);
            setTimeout(resolve, 2000);
          }
        }, 200); // 每200ms滚动一次
      });
    });
    
    // 等待内容加载
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // 方法2: 再次滚动到底部
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 方法3: 触发所有可能的滚动事件
    await page.evaluate(() => {
      window.dispatchEvent(new Event('scroll'));
      window.dispatchEvent(new Event('scrollend'));
      document.dispatchEvent(new Event('scroll'));
    });
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    const afterState = await page.evaluate(() => ({
      scrollHeight: document.body.scrollHeight,
      textLength: document.body.innerText.length,
      scrollY: window.scrollY
    }));
    
    const textIncreased = afterState.textLength > beforeState.textLength;
    const heightIncreased = afterState.scrollHeight > beforeState.scrollHeight;
    
    if (textIncreased || heightIncreased) {
      console.log(`第 ${round + 1} 轮: 文本 ${beforeState.textLength} -> ${afterState.textLength} (+${afterState.textLength - beforeState.textLength}), 高度 ${beforeState.scrollHeight} -> ${afterState.scrollHeight} (+${afterState.scrollHeight - beforeState.scrollHeight})`);
    } else {
      if ((round + 1) % 5 === 0) {
        console.log(`第 ${round + 1} 轮: 内容未增加（文本: ${afterState.textLength}, 高度: ${afterState.scrollHeight}px）`);
      }
    }
    
    // 如果连续多轮没有增加，尝试其他方法
    if (!textIncreased && !heightIncreased && round >= 20) {
      // 尝试点击页面触发加载
      await page.evaluate(() => {
        document.body.click();
      });
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // 再次滚动
      await page.evaluate(() => {
        window.scrollTo(0, document.body.scrollHeight);
      });
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const finalState = await page.evaluate(() => ({
        textLength: document.body.innerText.length,
        scrollHeight: document.body.scrollHeight
      }));
      
      if (finalState.textLength === afterState.textLength && finalState.scrollHeight === afterState.scrollHeight) {
        console.log('内容似乎已经加载完成，再滚动几轮确保完整...');
        for (let i = 0; i < 10; i++) {
          await page.evaluate(() => {
            window.scrollTo(0, document.body.scrollHeight);
          });
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
        break;
      }
    }
    
    if ((round + 1) % 10 === 0) {
      const headings = await page.evaluate(() => {
        const text = document.body.innerText;
        const matches = text.match(/^一、[^\n]+/gm);
        return matches ? matches.length : 0;
      });
      console.log(`--- 第 ${round + 1} 轮总结: 文本长度 ${afterState.textLength} 字符, 页面高度 ${afterState.scrollHeight}px, 一级标题 ${headings} 个 ---`);
    }
  }
  
  console.log('滚动完成，最后等待...');
  await new Promise(resolve => setTimeout(resolve, 10000));
  await page.evaluate(() => window.scrollTo(0, 0));
  await new Promise(resolve => setTimeout(resolve, 2000));

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

    const headings = document.body.innerText.match(/^一、[^\n]+/gm);
    result.headingCount = {
      h1: document.querySelectorAll('h1').length,
      firstLevelHeadings: headings ? headings.length : 0
    };

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
            tagName: el.tagName
          });
        }
      }
    }

    return result;
  });

  fs.writeFileSync('/tmp/feishu_full_content.json', JSON.stringify(allData, null, 2));
  fs.writeFileSync('/tmp/feishu_body_text.txt', allData.bodyText.full, 'utf8');
  
  console.log('=== 提取完成 ===');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('页面高度:', allData.pageInfo.scrollHeight);
  console.log('一级标题数量:', allData.headingCount.firstLevelHeadings);
  console.log('H1 标签数量:', allData.headingCount.h1);
  console.log('');
  console.log('✅ 完整 JSON 已保存到 /tmp/feishu_full_content.json');
  console.log('✅ Body 文本已保存到 /tmp/feishu_body_text.txt');
  
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本 ==="
node get_full_content_fixed.js

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
echo "✅ 完成！"

