#!/bin/bash

# 诊断文档 - 查看所有原始数据

cd /www/wwwroot/feihub/backend

echo "=== 创建诊断脚本 ==="

cat > diagnose_doc.js << 'JSEOF'
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/Navmd5IT6oodtVx6sgnc5KpTn7g';

(async () => {
  console.log('=== 开始详细诊断 ===');
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

  const allContent = await page.evaluate(() => {
    const result = {
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
      selectors: []
    };

    // 测试所有选择器
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
          textPreview: text.substring(0, 500),
          fullText: text,
          hasChinese: /[\u4e00-\u9fa5]/.test(text),
          hasHelpCenter: text.includes('Help Center'),
          hasLogIn: text.includes('Log In or Sign Up')
        });
      }
    }

    // 查找日期模式
    if (result.bodyText.afterLogIn) {
      const dateMatch = result.bodyText.afterLogIn.match(/Modified\s+([A-Za-z]+)\s+(\d{1,2})(?:,\s*(\d{4}))?/i);
      if (dateMatch) {
        result.extractedDate = {
          full: dateMatch[0],
          month: dateMatch[1],
          day: dateMatch[2],
          year: dateMatch[3] || '',
          index: dateMatch.index
        };
        // 提取日期前后的内容
        const dateStart = dateMatch.index;
        const dateEnd = dateStart + dateMatch[0].length;
        result.titleBeforeDate = result.bodyText.afterLogIn.substring(0, dateStart).trim();
        result.contentAfterDate = result.bodyText.afterLogIn.substring(dateEnd).trim();
      }
    }

    return result;
  });

  fs.writeFileSync('/tmp/feishu_doc_all_content.json', JSON.stringify(allContent, null, 2));

  console.log('=== 标题信息 ===');
  console.log('PageData:', allContent.title.fromPageData);
  console.log('Meta OG:', allContent.title.fromMeta);
  console.log('H1:', allContent.title.fromH1);
  console.log('Title:', allContent.title.fromTitle);
  console.log('');

  console.log('=== 日期信息 ===');
  console.log('PageData:', allContent.date.fromPageData);
  console.log('Time Element:', allContent.date.fromTimeElement);
  console.log('All Time Elements:', allContent.date.fromAllTimeElements);
  if (allContent.extractedDate) {
    console.log('提取的日期:', allContent.extractedDate.full);
    console.log('日期位置:', allContent.extractedDate.index);
  }
  console.log('');

  console.log('=== Body 文本信息 ===');
  console.log('总长度:', allContent.bodyText.length);
  console.log('Log In or Sign Up 位置:', allContent.bodyText.logInIndex);
  console.log('Log In 之后的内容长度:', allContent.bodyText.afterLogIn.length);
  console.log('');

  if (allContent.titleBeforeDate) {
    console.log('=== 日期前的标题部分 ===');
    console.log(allContent.titleBeforeDate.substring(0, 200));
    console.log('');
  }

  if (allContent.extractedDate) {
    console.log('=== 提取的日期 ===');
    console.log(allContent.extractedDate.full);
    console.log('');
  }

  if (allContent.contentAfterDate) {
    console.log('=== 日期后的正文部分（前1000字符）===');
    console.log(allContent.contentAfterDate.substring(0, 1000));
    console.log('');
  }

  console.log('=== Body 完整文本（前3000字符）===');
  console.log(allContent.bodyText.full.substring(0, 3000));
  console.log('');

  console.log('=== 选择器匹配结果 ===');
  allContent.selectors.forEach((sel, idx) => {
    console.log(`\n选择器 ${idx + 1}: ${sel.selector}[${sel.index}]`);
    console.log(`  长度: ${sel.textLength}, 包含中文: ${sel.hasChinese}`);
    console.log(`  包含 Help Center: ${sel.hasHelpCenter}, 包含 Log In: ${sel.hasLogIn}`);
    console.log(`  预览: ${sel.textPreview.substring(0, 300)}`);
  });

  console.log('');
  console.log('✅ 完整内容已保存到 /tmp/feishu_doc_all_content.json');
  await browser.close();
})();
JSEOF

echo "✅ 脚本已创建"
echo ""
echo "=== 执行诊断 ==="
node diagnose_doc.js

echo ""
echo "=== 查看完整 JSON ==="
cat /tmp/feishu_doc_all_content.json | python3 -m json.tool | head -400

echo ""
echo "✅ 诊断完成！"

