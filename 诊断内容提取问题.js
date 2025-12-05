const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/Navmd5IT6oodtVx6sgnc5KpTn7g';

(async () => {
  console.log('=== 诊断内容提取问题 ===');
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

  // 滚动加载内容
  console.log('=== 滚动加载内容 ===');
  const scrollInfo = await page.evaluate(() => {
    const info = { scrollContainers: [] };
    const allElements = document.querySelectorAll('*');
    allElements.forEach((el) => {
      const style = window.getComputedStyle(el);
      const overflow = style.overflow + style.overflowY + style.overflowX;
      if ((overflow.includes('scroll') || overflow.includes('auto')) && el.scrollHeight > el.clientHeight) {
        info.scrollContainers.push({
          tagName: el.tagName,
          className: el.className || '',
          id: el.id || '',
          scrollHeight: el.scrollHeight,
          clientHeight: el.clientHeight
        });
      }
    });
    return info;
  });

  if (scrollInfo.scrollContainers.length > 0) {
    const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => 
      current.scrollHeight > max.scrollHeight ? current : max
    );
    
    console.log(`找到滚动容器: ${mainContainer.tagName} ${(mainContainer.className || mainContainer.id || '').substring(0, 50)}, 高度: ${mainContainer.scrollHeight}px`);
    
    // 滚动到底部
    for (let i = 0; i < 50; i++) {
      const currentState = await page.evaluate((containerInfo) => {
        const elements = document.querySelectorAll(containerInfo.tagName);
        let targetElement = null;
        for (const el of Array.from(elements)) {
          if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
              (containerInfo.id && el.id === containerInfo.id)) {
            if (el.scrollHeight > el.clientHeight) {
              targetElement = el;
              break;
            }
          }
        }
        if (targetElement) {
          const scrollAmount = targetElement.clientHeight * 0.8;
          targetElement.scrollTop += scrollAmount;
          targetElement.dispatchEvent(new Event('scroll', { bubbles: true }));
          return {
            scrollHeight: targetElement.scrollHeight,
            scrollTop: targetElement.scrollTop,
            clientHeight: targetElement.clientHeight,
            textLength: document.body.innerText.length
          };
        }
        return null;
      }, {
        tagName: mainContainer.tagName,
        className: mainContainer.className,
        id: mainContainer.id
      });
      
      if (!currentState) break;
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      if (i % 5 === 0) {
        console.log(`  第 ${i + 1} 轮: 容器高度 ${currentState.scrollHeight}px, 文本长度 ${currentState.textLength} 字符`);
      }
      
      if (currentState.scrollTop + currentState.clientHeight >= currentState.scrollHeight - 10) {
        console.log('  已滚动到底部');
        break;
      }
    }
    
    // 滚动回顶部
    await page.evaluate((containerInfo) => {
      const elements = document.querySelectorAll(containerInfo.tagName);
      for (const el of Array.from(elements)) {
        if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
            (containerInfo.id && el.id === containerInfo.id)) {
          if (el.scrollHeight > el.clientHeight) {
            el.scrollTop = 0;
            break;
          }
        }
      }
    }, {
      tagName: mainContainer.tagName,
      className: mainContainer.className,
      id: mainContainer.id
    });
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  console.log('');
  console.log('=== 开始提取内容 ===');
  
  // 提取内容并诊断
  const extractedData = await page.evaluate(() => {
    const result = {
      selectors: [],
      bodyText: '',
      diagnostics: {
        allSelectors: [],
        bodyTextLength: 0,
        filteredTextLength: 0
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
      '.page-content'
    ];

    // 测试每个选择器
    for (const selector of selectors) {
      try {
        const elements = document.querySelectorAll(selector);
        for (let idx = 0; idx < elements.length; idx++) {
          const element = elements[idx];
          const clone = element.cloneNode(true);
          
          const unwanted = clone.querySelectorAll(`
            script, style, iframe, noscript, nav, header, footer,
            aside, .catalogue, .catalogue__main, .catalogue__main-wrapper,
            .left-content, .right-content,
            [class*="login"], [class*="Login"],
            [class*="help"], [class*="Help"], [class*="guide"],
            [class*="shortcut"], [class*="Shortcut"],
            button, .button, [role="button"]
          `);
          unwanted.forEach((el) => el.remove());

          let text = clone.innerText || clone.textContent || '';
          text = text.trim();

          // 记录所有选择器的结果（不过滤）
          result.diagnostics.allSelectors.push({
            selector: selector,
            index: idx,
            textLength: text.length,
            text: text.substring(0, 500),
            className: element.className || '',
            tagName: element.tagName || ''
          });

          // 应用过滤条件
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

    // 提取 body 文本
    const body = document.body.cloneNode(true);
    const unwanted = body.querySelectorAll(`
      script, style, iframe, noscript, nav, header, footer, .sidebar, .menu,
      aside, .catalogue, .catalogue__main, .catalogue__main-wrapper,
      .left-content, .right-content,
      [class*="login"], [class*="Login"],
      [class*="help"], [class*="Help"], [class*="guide"],
      [class*="shortcut"], [class*="Shortcut"],
      button, .button, [role="button"]
    `);
    unwanted.forEach((el) => el.remove());
    
    result.bodyText = (body.innerText || body.textContent || '').trim();
    result.diagnostics.bodyTextLength = result.bodyText.length;
    result.diagnostics.filteredTextLength = result.bodyText.length;

    return result;
  });

  console.log('');
  console.log('=== 诊断结果 ===');
  console.log(`找到 ${extractedData.selectors.length} 个有效选择器结果`);
  console.log(`Body 文本长度: ${extractedData.diagnostics.bodyTextLength} 字符`);
  console.log(`所有选择器测试结果: ${extractedData.diagnostics.allSelectors.length} 个`);
  console.log('');

  // 显示所有选择器的结果
  console.log('=== 所有选择器结果（包括被过滤的）===');
  extractedData.diagnostics.allSelectors.forEach((item, idx) => {
    console.log(`--- 选择器 ${idx + 1}: ${item.selector} [${item.index}] ---`);
    console.log(`类名: ${item.className}`);
    console.log(`文本长度: ${item.textLength} 字符`);
    console.log(`前500字符: ${item.text}`);
    console.log('');
  });

  // 显示有效选择器结果
  if (extractedData.selectors.length > 0) {
    console.log('=== 有效选择器结果 ===');
    extractedData.selectors.forEach((item, idx) => {
      console.log(`--- 选择器 ${idx + 1}: ${item.selector} [${item.index}] ---`);
      console.log(`文本长度: ${item.textLength} 字符`);
      console.log(`前1000字符: ${item.text}`);
      console.log('');
    });
  } else {
    console.log('⚠️  没有找到有效选择器结果！');
    console.log('可能原因：');
    console.log('1. 内容被过滤条件过滤掉了');
    console.log('2. 内容长度不足（< 50字符）');
    console.log('3. 选择器没有匹配到内容');
  }

  console.log('=== Body 文本（完整）===');
  console.log(`长度: ${extractedData.bodyText.length} 字符`);
  console.log(`前2000字符: ${extractedData.bodyText.substring(0, 2000)}`);
  console.log('');

  // 保存结果
  const timestamp = Date.now();
  const outputFile = `/tmp/feishu_diagnose_${timestamp}.json`;
  fs.writeFileSync(outputFile, JSON.stringify(extractedData, null, 2), 'utf8');

  console.log(`=== 结果已保存 ===`);
  console.log(`文件: ${outputFile}`);
  console.log('');

  await browser.close();
  
  console.log('✅✅✅ 诊断完成！');
})();

