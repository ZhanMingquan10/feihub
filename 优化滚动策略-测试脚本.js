const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 测试优化后的滚动策略 ===');
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

  // 优化后的滚动策略
  console.log('=== 开始优化滚动 ===');
  
  // 获取初始状态
  let lastHeight = await page.evaluate(() => document.body.scrollHeight);
  let lastTextLength = await page.evaluate(() => document.body.innerText.length);
  console.log(`初始状态: 页面高度 ${lastHeight}px, 文本长度 ${lastTextLength} 字符`);
  console.log('');

  // 策略1: 平滑滚动到底部
  console.log('策略1: 平滑滚动到底部...');
  await page.evaluate(() => {
    window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
  });
  await new Promise(resolve => setTimeout(resolve, 3000));

  // 策略2: 逐段滚动（每次滚动一屏）
  console.log('策略2: 逐段滚动（每次一屏）...');
  let scrollPosition = 0;
  const viewportHeight = 1080;
  let noChangeCount = 0;
  
  for (let i = 0; i < 50; i++) {
    const currentHeight = await page.evaluate(() => document.body.scrollHeight);
    const currentScrollTop = await page.evaluate(() => window.pageYOffset || document.documentElement.scrollTop);
    
    // 滚动到下一个位置
    scrollPosition += viewportHeight * 0.8; // 每次滚动80%的视口高度，确保有重叠
    
    await page.evaluate((pos) => {
      window.scrollTo({ top: pos, behavior: 'smooth' });
    }, scrollPosition);
    
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // 检查页面高度和内容是否变化
    const newHeight = await page.evaluate(() => document.body.scrollHeight);
    const newTextLength = await page.evaluate(() => document.body.innerText.length);
    
    if (newHeight === lastHeight && newTextLength === lastTextLength) {
      noChangeCount++;
      if (noChangeCount >= 3) {
        console.log(`  连续 ${noChangeCount} 次无变化，尝试其他策略...`);
        break;
      }
    } else {
      noChangeCount = 0;
      console.log(`  第 ${i + 1} 轮: 页面高度 ${newHeight}px (增加 ${newHeight - lastHeight}px), 文本长度 ${newTextLength} (增加 ${newTextLength - lastTextLength} 字符)`);
      lastHeight = newHeight;
      lastTextLength = newTextLength;
    }
    
    // 如果已经滚动到底部
    if (scrollPosition >= newHeight - viewportHeight) {
      console.log('  已滚动到底部');
      break;
    }
  }

  // 策略3: 滚动到特定元素（如果有的话）
  console.log('');
  console.log('策略3: 尝试滚动到特定元素...');
  await page.evaluate(() => {
    // 尝试找到所有可能的内容元素并滚动到它们
    const contentElements = document.querySelectorAll('.page-block, .page-main-item, [class*="content"], [class*="block"]');
    contentElements.forEach((el, index) => {
      if (index % 5 === 0) { // 每5个元素滚动一次
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    });
  });
  await new Promise(resolve => setTimeout(resolve, 3000));

  // 策略4: 触发滚动事件（模拟用户交互）
  console.log('策略4: 触发滚动事件...');
  await page.evaluate(() => {
    // 触发各种滚动事件
    window.dispatchEvent(new Event('scroll'));
    window.dispatchEvent(new Event('scrollend'));
    document.dispatchEvent(new Event('scroll'));
    
    // 尝试触发 IntersectionObserver
    const event = new Event('intersect', { bubbles: true });
    document.dispatchEvent(event);
  });
  await new Promise(resolve => setTimeout(resolve, 2000));

  // 策略5: 使用 requestAnimationFrame 等待所有内容加载
  console.log('策略5: 等待内容加载完成...');
  await page.evaluate(() => {
    return new Promise((resolve) => {
      let lastContentLength = document.body.innerText.length;
      let stableCount = 0;
      
      const checkContent = () => {
        const currentLength = document.body.innerText.length;
        if (currentLength === lastContentLength) {
          stableCount++;
          if (stableCount >= 10) {
            resolve();
            return;
          }
        } else {
          stableCount = 0;
          lastContentLength = currentLength;
        }
        requestAnimationFrame(checkContent);
      };
      
      requestAnimationFrame(checkContent);
      
      // 超时保护
      setTimeout(resolve, 10000);
    });
  });

  // 最终状态
  const finalHeight = await page.evaluate(() => document.body.scrollHeight);
  const finalTextLength = await page.evaluate(() => document.body.innerText.length);
  const finalScrollTop = await page.evaluate(() => window.pageYOffset || document.documentElement.scrollTop);
  
  console.log('');
  console.log('=== 滚动完成 ===');
  console.log(`最终状态:`);
  console.log(`  页面高度: ${finalHeight}px (初始: ${lastHeight}px, 增加: ${finalHeight - lastHeight}px)`);
  console.log(`  文本长度: ${finalTextLength} 字符 (初始: ${lastTextLength}, 增加: ${finalTextLength - lastTextLength})`);
  console.log(`  当前滚动位置: ${finalScrollTop}px`);
  console.log('');

  // 提取内容
  console.log('=== 开始提取内容 ===');
  
  const extractedData = await page.evaluate(() => {
    const result = {
      selectors: [],
      bodyText: '',
      pageData: null,
      scrollInfo: {
        scrollHeight: document.body.scrollHeight,
        scrollTop: window.pageYOffset || document.documentElement.scrollTop,
        clientHeight: document.documentElement.clientHeight,
        textLength: document.body.innerText.length
      }
    };

    const selectors = [
      '.page-main.docx-width-mode',
      '.page-main-item.editor',
      '.page-block.root-block',
      '.page-block-children',
      'main .app-main.main__content:not(.catalogue__main):not(.catalogue__main-wrapper)',
      'main .app-main.main__content',
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

    for (const selector of selectors) {
      try {
        const elements = document.querySelectorAll(selector);
        for (let idx = 0; idx < elements.length; idx++) {
          const element = elements[idx];
          const clone = element.cloneNode(true);
          
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
            continue;
          }

          if (text.length > 50) {
            result.selectors.push({
              selector: selector,
              index: idx,
              textLength: text.length,
              text: text.substring(0, 1000),
              fullText: text,
              className: element.className || '',
              tagName: element.tagName || ''
            });
          }
        }
      } catch (e) {
        // 忽略错误
      }
    }

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
    result.pageData = window.__INITIAL_STATE__ || null;

    return result;
  });

  console.log('');
  console.log('=== 提取结果 ===');
  console.log(`找到 ${extractedData.selectors.length} 个有效选择器结果`);
  console.log(`滚动信息: 页面高度 ${extractedData.scrollInfo.scrollHeight}px, 文本长度 ${extractedData.scrollInfo.textLength} 字符`);
  console.log('');

  const timestamp = Date.now();
  const outputFile = `/tmp/feishu_extracted_${timestamp}.json`;
  const outputTextFile = `/tmp/feishu_extracted_${timestamp}.txt`;

  const outputData = {
    link: link,
    timestamp: new Date().toISOString(),
    scrollInfo: extractedData.scrollInfo,
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

  if (extractedData.selectors.length > 0) {
    const bestMatch = extractedData.selectors.reduce((best, current) => {
      return current.textLength > best.textLength ? current : best;
    });

    console.log('=== 最佳匹配结果 ===');
    console.log(`选择器: ${bestMatch.selector} [${bestMatch.index}]`);
    console.log(`文本长度: ${bestMatch.textLength} 字符`);
    console.log(`类名: ${bestMatch.className}`);
    console.log('');
  }

  await browser.close();
  
  console.log('✅✅✅ 提取完成！');
  console.log('');
  console.log('=== 查看 JSON 文件 ===');
  console.log(`cat ${outputFile} | python3 -m json.tool | less`);
  console.log(`或直接查看: cat ${outputFile}`);
})();

