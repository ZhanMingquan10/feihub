// 详细诊断 - 显示所有原始提取内容
const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/VGoXdFXmooasHUxsZ0icAD2WnGe';

(async () => {
  console.log('=== 开始详细诊断 ===');
  console.log('链接:', link);
  console.log('');

  const browser = await puppeteer.launch({
    executablePath: process.env.CHROME_PATH || '/usr/bin/chromium-browser',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');

  console.log('正在加载页面...');
  await page.goto(link, { waitUntil: 'networkidle2', timeout: 30000 });

  console.log('等待内容渲染...');
  await new Promise(resolve => setTimeout(resolve, 15000));

  // 提取所有原始内容
  const allContent = await page.evaluate(() => {
    const result = {
      title: {
        fromPageData: (window as any).__INITIAL_STATE__?.pageData?.title || '',
        fromMeta: document.querySelector('meta[property="og:title"]')?.getAttribute('content') || '',
        fromH1: document.querySelector('h1')?.innerText || '',
        fromTitle: document.title || ''
      },
      date: {
        fromPageData: (window as any).__INITIAL_STATE__?.pageData?.updateTime || '',
        fromTimeElement: document.querySelector('.doc-info-time-item')?.innerText || '',
        fromAllTimeElements: Array.from(document.querySelectorAll('[class*="time"], [class*="date"]')).map(el => el.innerText).filter(t => t)
      },
      author: {
        fromPageData: (window as any).__INITIAL_STATE__?.pageData?.author || '',
        fromAuthorElement: document.querySelector('[class*="author"], [class*="creator"]')?.innerText || ''
      },
      selectors: [],
      bodyText: {
        full: document.body.innerText.substring(0, 10000),
        length: document.body.innerText.length
      },
      html: {
        length: document.documentElement.outerHTML.length,
        preview: document.documentElement.outerHTML.substring(0, 5000)
      }
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
          hasChinese: /[\u4e00-\u9fa5]/.test(text),
          hasHelpCenter: text.includes('Help Center'),
          hasKeyboardShortcuts: text.includes('Keyboard Shortcuts'),
          className: el.className,
          tagName: el.tagName
        });
      }
    }

    return result;
  });

  // 保存到文件
  fs.writeFileSync('/tmp/feishu_all_content.json', JSON.stringify(allContent, null, 2));

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
  console.log('');

  console.log('=== 作者信息 ===');
  console.log('PageData:', allContent.author.fromPageData);
  console.log('Author Element:', allContent.author.fromAuthorElement);
  console.log('');

  console.log('=== Body 文本（前2000字符）===');
  console.log(allContent.bodyText.full.substring(0, 2000));
  console.log('');

  console.log('=== 选择器匹配结果 ===');
  allContent.selectors.forEach((sel, idx) => {
    console.log(`\n选择器 ${idx + 1}: ${sel.selector}[${sel.index}]`);
    console.log(`  长度: ${sel.textLength}`);
    console.log(`  包含中文: ${sel.hasChinese}`);
    console.log(`  包含 Help Center: ${sel.hasHelpCenter}`);
    console.log(`  包含 Keyboard Shortcuts: ${sel.hasKeyboardShortcuts}`);
    console.log(`  标签: ${sel.tagName}, 类名: ${sel.className}`);
    console.log(`  预览（前300字符）: ${sel.textPreview.substring(0, 300)}`);
  });

  console.log('');
  console.log('✅ 完整内容已保存到 /tmp/feishu_all_content.json');
  console.log('✅ HTML 预览已保存（前5000字符）');

  await browser.close();
  console.log('=== 诊断完成 ===');
})();

