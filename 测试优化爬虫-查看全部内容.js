const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 测试优化后的爬虫 ===');
  console.log(`链接: ${link}`);
  console.log('');
  
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
  
  // 反爬虫检测
  await page.evaluateOnNewDocument(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => false });
    Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
    Object.defineProperty(navigator, 'languages', { get: () => ['zh-CN', 'zh', 'en'] });
  });
  
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
  await page.setViewport({ width: 1920, height: 1080 });
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8'
  });

  try {
    await page.goto(link, { waitUntil: 'domcontentloaded', timeout: 120000 });
  } catch (error) {
    console.log('⚠️  页面加载超时，但继续尝试...');
  }

  console.log('等待初始加载...');
  await new Promise(resolve => setTimeout(resolve, 5000));

  // 滚动页面以触发懒加载
  console.log('开始滚动页面...');
  for (let i = 0; i < 20; i++) {
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    if (i % 5 === 0) {
      const state = await page.evaluate(() => ({
        scrollHeight: document.body.scrollHeight,
        textLength: document.body.innerText.length
      }));
      console.log(`  第 ${i + 1} 轮: 文本长度 ${state.textLength}, 页面高度 ${state.scrollHeight}px`);
    }
  }

  await new Promise(resolve => setTimeout(resolve, 5000));

  console.log('');
  console.log('=== 开始提取内容 ===');
  
  // 使用优化后的选择器和排除逻辑提取内容
  const extractedData = await page.evaluate(() => {
    const result = {
      selectors: [],
      bodyText: '',
      pageData: null
    };

    // 优化后的精确选择器（优先匹配中间内容区域）
    const selectors = [
      '.page-main.docx-width-mode', // 主要内容区域
      '.page-main-item.editor', // 编辑器区域
      '.page-block.root-block', // 页面块
      '.page-block-children', // 页面块内容
      'main .app-main.main__content:not(.catalogue__main):not(.catalogue__main-wrapper)', // 主内容区域（排除目录）
      'main .app-main.main__content', // 主内容区域（备用）
      '.wiki-content',
      '.wiki-body',
      '.doc-content',
      '.doc-body',
      '[data-content]',
      'main article',
      'article .content',
      '.page-content',
      '[class*="content"]:not(.left-content):not(.right-content)',
      '[class*="body"]:not(.suite-body)',
      '[class*="main"]:not(.catalogue__main):not(.catalogue__main-wrapper)'
    ];

    // 测试每个选择器
    for (const selector of selectors) {
      try {
        const elements = document.querySelectorAll(selector);
        for (let idx = 0; idx < elements.length; idx++) {
          const element = elements[idx];
          const clone = element.cloneNode(true);
          
          // 排除不需要的元素（根据截图优化）
          const unwanted = clone.querySelectorAll(`
            script, style, iframe, noscript, nav, header, footer,
            .ad, .gtm, .header, .footer, .sidebar, .menu,
            h1, .title, .author, .user-name, .creator-name,
            [class*="header"], [class*="footer"], [class*="nav"],
            [class*="menu"], [class*="sidebar"], [class*="toolbar"],
            [class*="image"], [class*="attachment"], [class*="media"],
            [class*="comment"], [class*="Comment"], [class*="highlight"],
            [class*="Highlight"], [class*="annotation"], [class*="Annotation"],
            aside, .catalogue, .catalogue__main, .catalogue__main-wrapper,
            .left-content, .right-content,
            [class*="login"], [class*="Login"],
            [class*="help"], [class*="Help"], [class*="guide"], [class*="Guide"],
            [class*="shortcut"], [class*="Shortcut"], [class*="Shortcuts"],
            [class*="comment"], [class*="Comment"], [class*="查看全文"],
            button, .button, [role="button"],
            [class*="action"], [class*="Action"],
            [aria-label*="Help"], [aria-label*="help"], [aria-label*="帮助"],
            [aria-label*="登录"], [aria-label*="Login"], [aria-label*="注册"],
            img, picture, video, audio
          `);
          unwanted.forEach((el) => el.remove());

          let text = clone.innerText || clone.textContent || '';
          text = text.trim();

          // 验证内容：排除导航栏、标题栏、按钮和帮助中心
          if (text && (
            text.includes('Help Center') ||
            text.includes('Keyboard Shortcuts') ||
            text.includes('Token Limit') ||
            text.includes('帮助中心') ||
            text.includes('快捷键') ||
            text.includes('登录') ||
            text.includes('注册') ||
            text.includes('Login') ||
            text.includes('Sign Up') ||
            text.includes('查看全文') ||
            text.includes('评论') ||
            (text.substring(0, 200).match(/^[一二三四五六七八九十]+[、\.]/) && text.length < 500) ||
            text.trim().split(/\s+/).length < 10 ||
            (!/[\u4e00-\u9fa5]/.test(text) && text.length < 200)
          )) {
            continue; // 跳过无效内容
          }

          if (text.length > 50) {
            result.selectors.push({
              selector: selector,
              index: idx,
              textLength: text.length,
              text: text.substring(0, 1000), // 前1000字符
              fullText: text,
              className: element.className || '',
              tagName: element.tagName || ''
            });
          }
        }
      } catch (e) {
        // 忽略错误，继续下一个选择器
      }
    }

    // 提取 body 文本（完整内容）
    const body = document.body.cloneNode(true);
    const unwanted = body.querySelectorAll(`
      script, style, iframe, noscript, nav, header, footer, .sidebar, .menu,
      aside, .catalogue, .catalogue__main, .catalogue__main-wrapper,
      .left-content, .right-content,
      [class*="login"], [class*="Login"],
      [class*="help"], [class*="Help"], [class*="guide"], [class*="Guide"],
      [class*="shortcut"], [class*="Shortcut"], [class*="Shortcuts"],
      [class*="comment"], [class*="Comment"], [class*="查看全文"],
      button, .button, [role="button"],
      [class*="action"], [class*="Action"],
      [aria-label*="Help"], [aria-label*="help"], [aria-label*="帮助"],
      [aria-label*="登录"], [aria-label*="Login"], [aria-label*="注册"],
      h1, .title, .author, .user-name, .creator-name,
      [class*="header"], [class*="footer"], [class*="nav"],
      [class*="menu"], [class*="sidebar"], [class*="toolbar"],
      [class*="image"], [class*="attachment"], [class*="media"],
      [class*="comment"], [class*="Comment"], [class*="highlight"],
      [class*="Highlight"], [class*="annotation"], [class*="Annotation"],
      img, picture, video, audio
    `);
    unwanted.forEach((el) => el.remove());
    
    result.bodyText = (body.innerText || body.textContent || '').trim();

    // 提取 pageData（如果有）
    result.pageData = window.__INITIAL_STATE__ || null;

    return result;
  });

  // 输出结果
  console.log('');
  console.log('=== 提取结果 ===');
  console.log('');
  console.log(`找到 ${extractedData.selectors.length} 个有效选择器结果`);
  console.log('');

  // 显示每个选择器的结果
  extractedData.selectors.forEach((item, idx) => {
    console.log(`--- 选择器 ${idx + 1}: ${item.selector} [${item.index}] ---`);
    console.log(`类名: ${item.className}`);
    console.log(`标签: ${item.tagName}`);
    console.log(`文本长度: ${item.textLength} 字符`);
    console.log(`前1000字符:`);
    console.log(item.text);
    console.log('');
  });

  // 显示完整 body 文本
  console.log('=== 完整 Body 文本（排除不需要的元素后）===');
  console.log(`长度: ${extractedData.bodyText.length} 字符`);
  console.log('');
  console.log(extractedData.bodyText);
  console.log('');

  // 保存到文件
  const outputDir = '/tmp';
  const outputFile = `${outputDir}/feishu_extracted_content_${Date.now()}.json`;
  const outputTextFile = `${outputDir}/feishu_extracted_content_${Date.now()}.txt`;

  const outputData = {
    link: link,
    timestamp: new Date().toISOString(),
    selectors: extractedData.selectors.map(item => ({
      selector: item.selector,
      index: item.index,
      textLength: item.textLength,
      className: item.className,
      tagName: item.tagName,
      text: item.fullText
    })),
    bodyText: {
      length: extractedData.bodyText.length,
      content: extractedData.bodyText
    },
    pageData: extractedData.pageData
  };

  fs.writeFileSync(outputFile, JSON.stringify(outputData, null, 2), 'utf8');
  fs.writeFileSync(outputTextFile, extractedData.bodyText, 'utf8');

  console.log('=== 文件已保存 ===');
  console.log(`JSON: ${outputFile}`);
  console.log(`文本: ${outputTextFile}`);
  console.log('');

  // 显示最佳结果
  if (extractedData.selectors.length > 0) {
    const bestMatch = extractedData.selectors.reduce((best, current) => {
      return current.textLength > best.textLength ? current : best;
    });

    console.log('=== 最佳匹配结果 ===');
    console.log(`选择器: ${bestMatch.selector} [${bestMatch.index}]`);
    console.log(`文本长度: ${bestMatch.textLength} 字符`);
    console.log(`类名: ${bestMatch.className}`);
    console.log('');
    console.log('完整内容:');
    console.log(bestMatch.fullText);
    console.log('');
  }

  await browser.close();
  
  console.log('✅✅✅ 提取完成！');
})();

