#!/bin/bash

# 查看所有原始 JSON 数据

cd /www/wwwroot/feihub/backend

echo "=== 创建诊断脚本 ==="

cat > get_all_json.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 开始提取所有原始数据 ===');
  console.log('链接:', link);
  console.log('');

  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });
  await new Promise(resolve => setTimeout(resolve, 15000));

  const allData = await page.evaluate(() => {
    const result = {
      // PageData（__INITIAL_STATE__）
      pageData: window.__INITIAL_STATE__ || null,
      
      // 标题信息
      title: {
        fromPageData: (window.__INITIAL_STATE__ && window.__INITIAL_STATE__.pageData && window.__INITIAL_STATE__.pageData.title) || '',
        fromMeta: (document.querySelector('meta[property="og:title"]') && document.querySelector('meta[property="og:title"]').getAttribute('content')) || '',
        fromH1: (document.querySelector('h1') && document.querySelector('h1').innerText) || '',
        fromTitle: document.title || '',
        allH1: Array.from(document.querySelectorAll('h1')).map(el => el.innerText)
      },
      
      // 日期信息
      date: {
        fromPageData: (window.__INITIAL_STATE__ && window.__INITIAL_STATE__.pageData && window.__INITIAL_STATE__.pageData.updateTime) || '',
        fromTimeElement: (document.querySelector('.doc-info-time-item') && document.querySelector('.doc-info-time-item').innerText) || '',
        fromAllTimeElements: Array.from(document.querySelectorAll('[class*="time"], [class*="date"], .doc-info-time-item')).map(el => ({
          className: el.className,
          innerText: el.innerText,
          textContent: el.textContent
        }))
      },
      
      // 作者信息
      author: {
        fromPageData: (window.__INITIAL_STATE__ && window.__INITIAL_STATE__.pageData && window.__INITIAL_STATE__.pageData.author) || '',
        fromAuthorElement: (document.querySelector('[class*="author"], [class*="creator"]') && document.querySelector('[class*="author"], [class*="creator"]').innerText) || '',
        fromAllAuthorElements: Array.from(document.querySelectorAll('[class*="author"], [class*="creator"]')).map(el => ({
          className: el.className,
          innerText: el.innerText
        }))
      },
      
      // Body 完整文本
      bodyText: {
        full: document.body.innerText,
        length: document.body.innerText.length,
        logInIndex: document.body.innerText.indexOf('Log In or Sign Up'),
        afterLogIn: document.body.innerText.indexOf('Log In or Sign Up') > 0 ? document.body.innerText.substring(document.body.innerText.indexOf('Log In or Sign Up') + 'Log In or Sign Up'.length) : ''
      },
      
      // 所有 Meta 标签
      metaTags: Array.from(document.querySelectorAll('meta')).map(meta => ({
        name: meta.getAttribute('name'),
        property: meta.getAttribute('property'),
        content: meta.getAttribute('content')
      })),
      
      // 所有选择器匹配的内容
      selectors: []
    };

    // 测试所有选择器
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
      '.page-content'
    ];

    for (const selector of selectors) {
      const elements = document.querySelectorAll(selector);
      for (let i = 0; i < Math.min(elements.length, 5); i++) {
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
          hasHelpCenter: text.includes('Help Center'),
          hasLogIn: text.includes('Log In or Sign Up'),
          hasCreated: text.includes('Created on'),
          hasModified: text.includes('Modified')
        });
      }
    }

    // 查找日期模式
    if (result.bodyText.afterLogIn) {
      const createdMatch = result.bodyText.afterLogIn.match(/Created on\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      const modifiedMatch = result.bodyText.afterLogIn.match(/Modified\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      
      if (createdMatch) {
        result.extractedDate = {
          type: 'Created',
          full: createdMatch[0],
          month: createdMatch[1],
          day: createdMatch[2],
          year: createdMatch[3] || '',
          index: createdMatch.index
        };
      } else if (modifiedMatch) {
        result.extractedDate = {
          type: 'Modified',
          full: modifiedMatch[0],
          month: modifiedMatch[1],
          day: modifiedMatch[2],
          year: modifiedMatch[3] || '',
          index: modifiedMatch.index
        };
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

  // 保存到文件
  fs.writeFileSync('/tmp/feishu_all_json.json', JSON.stringify(allData, null, 2));

  console.log('=== 数据提取完成 ===');
  console.log('');
  console.log('标题信息:');
  console.log(JSON.stringify(allData.title, null, 2));
  console.log('');
  console.log('日期信息:');
  console.log(JSON.stringify(allData.date, null, 2));
  console.log('');
  console.log('Body 文本长度:', allData.bodyText.length);
  console.log('Log In or Sign Up 位置:', allData.bodyText.logInIndex);
  console.log('');
  if (allData.extractedDate) {
    console.log('提取的日期:', allData.extractedDate.full);
    console.log('日期前的标题:', allData.titleBeforeDate.substring(0, 100));
    console.log('日期后的正文长度:', allData.contentAfterDate.length);
  }
  console.log('');
  console.log('✅ 完整 JSON 已保存到 /tmp/feishu_all_json.json');
  console.log('✅ PageData 已包含在 JSON 中');

  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行脚本 ==="
node get_all_json.js

echo ""
echo "=== 查看完整 JSON ==="
cat /tmp/feishu_all_json.json | python3 -m json.tool | head -500

echo ""
echo "=== 查看 PageData ==="
cat /tmp/feishu_all_json.json | python3 -c "import json, sys; data = json.load(sys.stdin); print(json.dumps(data.get('pageData', {}), indent=2, ensure_ascii=False))" | head -200

echo ""
echo "✅ 完成！完整 JSON 已保存到 /tmp/feishu_all_json.json"

