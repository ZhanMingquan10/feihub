const puppeteer = require('puppeteer-core');
const fs = require('fs');

const link = 'https://ai.feishu.cn/docx/CL71dvLD9oML1fxTcBDcBeHXnCb';

(async () => {
  console.log('=== 查找真实滚动容器并优化滚动 ===');
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

  // 监听网络请求
  const apiRequests = [];
  page.on('response', async (response) => {
    const url = response.url();
    if (url.includes('api') || url.includes('docx') || url.includes('feishu') || url.includes('content')) {
      apiRequests.push({
        url: url.substring(0, 150),
        status: response.status(),
        timestamp: new Date().toISOString()
      });
    }
  });

  try {
    await page.goto(link, { waitUntil: 'domcontentloaded', timeout: 120000 });
  } catch (error) {
    console.log('⚠️  页面加载超时，但继续尝试...');
  }

  console.log('等待初始加载...');
  await new Promise(resolve => setTimeout(resolve, 5000));

  // 第一步：查找真实的滚动容器
  console.log('=== 第一步：查找真实的滚动容器 ===');
  const scrollInfo = await page.evaluate(() => {
    const info = {
      bodyScrollHeight: document.body.scrollHeight,
      bodyClientHeight: document.body.clientHeight,
      documentScrollHeight: document.documentElement.scrollHeight,
      documentClientHeight: document.documentElement.clientHeight,
      scrollContainers: []
    };

    // 查找所有可能包含滚动条的元素
    const allElements = document.querySelectorAll('*');
    allElements.forEach((el) => {
      const style = window.getComputedStyle(el);
      const overflow = style.overflow + style.overflowY + style.overflowX;
      if (overflow.includes('scroll') || overflow.includes('auto')) {
        if (el.scrollHeight > el.clientHeight) {
          info.scrollContainers.push({
            tagName: el.tagName,
            className: el.className || '',
            id: el.id || '',
            scrollHeight: el.scrollHeight,
            clientHeight: el.clientHeight,
            scrollTop: el.scrollTop
          });
        }
      }
    });

    return info;
  });

  console.log('滚动容器信息:');
  console.log(`  body.scrollHeight: ${scrollInfo.bodyScrollHeight}px`);
  console.log(`  body.clientHeight: ${scrollInfo.bodyClientHeight}px`);
  console.log(`  document.scrollHeight: ${scrollInfo.documentScrollHeight}px`);
  console.log(`  document.clientHeight: ${scrollInfo.documentClientHeight}px`);
  console.log(`  找到 ${scrollInfo.scrollContainers.length} 个滚动容器:`);
  scrollInfo.scrollContainers.forEach((container, idx) => {
    console.log(`    ${idx + 1}. ${container.tagName} ${container.className || container.id || ''}`);
    console.log(`       scrollHeight: ${container.scrollHeight}px, clientHeight: ${container.clientHeight}px`);
  });
  console.log('');

  // 第二步：尝试在主滚动容器上滚动
  console.log('=== 第二步：在主滚动容器上滚动 ===');
  
  // 找到最大的滚动容器（通常是主容器）
  const mainContainer = scrollInfo.scrollContainers.length > 0 
    ? scrollInfo.scrollContainers.reduce((max, current) => 
        current.scrollHeight > max.scrollHeight ? current : max
      )
    : null;

  if (mainContainer) {
    console.log(`使用主滚动容器: ${mainContainer.tagName} ${mainContainer.className || mainContainer.id || ''}`);
    console.log(`初始 scrollHeight: ${mainContainer.scrollHeight}px`);
    console.log('');

    // 在滚动容器上滚动
    for (let i = 0; i < 50; i++) {
      await page.evaluate((containerInfo) => {
        // 找到对应的元素
        const elements = document.querySelectorAll(containerInfo.tagName);
        let targetElement = null;
        
        for (const el of elements) {
          if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
              (containerInfo.id && el.id === containerInfo.id) ||
              (!containerInfo.className && !containerInfo.id)) {
            if (el.scrollHeight > el.clientHeight) {
              targetElement = el;
              break;
            }
          }
        }
        
        if (targetElement) {
          // 滚动到下一个位置
          const scrollAmount = targetElement.clientHeight * 0.8;
          targetElement.scrollTop += scrollAmount;
          
          // 触发滚动事件
          targetElement.dispatchEvent(new Event('scroll', { bubbles: true }));
          window.dispatchEvent(new Event('scroll', { bubbles: true }));
        }
      }, {
        tagName: mainContainer.tagName,
        className: mainContainer.className,
        id: mainContainer.id
      });

      await new Promise(resolve => setTimeout(resolve, 2000));

      // 检查状态
      const currentState = await page.evaluate((containerInfo) => {
        const elements = document.querySelectorAll(containerInfo.tagName);
        let targetElement = null;
        
        for (const el of elements) {
          if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
              (containerInfo.id && el.id === containerInfo.id) ||
              (!containerInfo.className && !containerInfo.id)) {
            if (el.scrollHeight > el.clientHeight) {
              targetElement = el;
              break;
            }
          }
        }
        
        return {
          scrollHeight: targetElement ? targetElement.scrollHeight : 0,
          scrollTop: targetElement ? targetElement.scrollTop : 0,
          clientHeight: targetElement ? targetElement.clientHeight : 0,
          bodyTextLength: document.body.innerText.length
        };
      }, {
        tagName: mainContainer.tagName,
        className: mainContainer.className,
        id: mainContainer.id
      });

      if (i % 5 === 0) {
        console.log(`  第 ${i + 1} 轮: 容器高度 ${currentState.scrollHeight}px, 滚动位置 ${currentState.scrollTop}px, 文本长度 ${currentState.bodyTextLength} 字符`);
      }

      // 如果已经滚动到底部
      if (currentState.scrollTop + currentState.clientHeight >= currentState.scrollHeight - 10) {
        console.log('  已滚动到底部');
        break;
      }
    }
  } else {
    console.log('未找到滚动容器，尝试在 window 上滚动');
    
    // 策略：使用鼠标移动和键盘组合
    console.log('=== 策略：模拟鼠标移动和键盘 ===');
    
    // 先点击页面中心，确保焦点
    await page.mouse.click(960, 540);
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // 使用 PageDown 滚动
    for (let i = 0; i < 100; i++) {
      await page.keyboard.press('PageDown');
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // 同时移动鼠标（模拟真实用户）
      await page.mouse.move(960, 540 + (i % 10) * 10);
      
      const state = await page.evaluate(() => ({
        scrollHeight: document.body.scrollHeight,
        scrollTop: window.pageYOffset || document.documentElement.scrollTop,
        textLength: document.body.innerText.length
      }));
      
      if (i % 10 === 0) {
        console.log(`  第 ${i + 1} 次: 页面高度 ${state.scrollHeight}px, 滚动位置 ${state.scrollTop}px, 文本长度 ${state.textLength} 字符`);
      }
      
      // 如果滚动位置不再变化
      if (i > 5 && state.scrollTop === 0) {
        console.log('  滚动位置为0，可能容器不是window');
        break;
      }
    }
  }

  // 第三步：等待所有网络请求完成
  console.log('');
  console.log('=== 第三步：等待网络请求完成 ===');
  console.log(`已捕获 ${apiRequests.length} 个相关 API 请求`);
  await new Promise(resolve => setTimeout(resolve, 5000));

  // 最终状态
  const finalState = await page.evaluate(() => {
    // 查找所有滚动容器
    const containers = [];
    const allElements = document.querySelectorAll('*');
    allElements.forEach((el) => {
      if (el.scrollHeight > el.clientHeight) {
        containers.push({
          tagName: el.tagName,
          className: el.className || '',
          scrollHeight: el.scrollHeight,
          scrollTop: el.scrollTop
        });
      }
    });

    return {
      bodyScrollHeight: document.body.scrollHeight,
      documentScrollHeight: document.documentElement.scrollHeight,
      windowScrollTop: window.pageYOffset || document.documentElement.scrollTop,
      textLength: document.body.innerText.length,
      containers: containers
    };
  });

  console.log('');
  console.log('=== 最终状态 ===');
  console.log(`body.scrollHeight: ${finalState.bodyScrollHeight}px`);
  console.log(`document.scrollHeight: ${finalState.documentScrollHeight}px`);
  console.log(`window.scrollTop: ${finalState.windowScrollTop}px`);
  console.log(`文本长度: ${finalState.textLength} 字符`);
  console.log(`滚动容器数量: ${finalState.containers.length}`);
  finalState.containers.forEach((c, idx) => {
    console.log(`  ${idx + 1}. ${c.tagName} ${c.className.substring(0, 50)}: ${c.scrollHeight}px (滚动位置: ${c.scrollTop}px)`);
  });
  console.log('');

  // 提取内容
  console.log('=== 开始提取内容 ===');
  
  const extractedData = await page.evaluate(() => {
    const result = {
      selectors: [],
      bodyText: '',
      pageData: null,
      scrollInfo: {
        bodyScrollHeight: document.body.scrollHeight,
        documentScrollHeight: document.documentElement.scrollHeight,
        windowScrollTop: window.pageYOffset || document.documentElement.scrollTop,
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
  console.log(`滚动信息: body.scrollHeight ${extractedData.scrollInfo.bodyScrollHeight}px, 文本长度 ${extractedData.scrollInfo.textLength} 字符`);
  console.log('');

  const timestamp = Date.now();
  const outputFile = `/tmp/feishu_extracted_${timestamp}.json`;
  const outputTextFile = `/tmp/feishu_extracted_${timestamp}.txt`;

  const outputData = {
    link: link,
    timestamp: new Date().toISOString(),
    scrollInfo: extractedData.scrollInfo,
    apiRequests: apiRequests.slice(0, 20), // 只保存前20个
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

  await browser.close();
  
  console.log('✅✅✅ 提取完成！');
  console.log('');
  console.log('=== 查看 JSON 文件命令 ===');
  console.log(`cat ${outputFile} | python3 -m json.tool | less`);
})();

