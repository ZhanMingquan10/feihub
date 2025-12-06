const puppeteer = require('puppeteer-core');

async function test() {
  console.log('启动测试...');
  let browser;
  try {
    console.log('正在启动浏览器...');
    browser = await puppeteer.launch({
      headless: true,
      executablePath: '/snap/bin/chromium',
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--no-first-run',
        '--no-zygote',
        '--single-process'
      ]
    });
    console.log('浏览器启动成功');

    const page = await browser.newPage();
    console.log('新页面创建成功');

    // 设置更长的超时时间
    page.setDefaultTimeout(30000);
    page.setDefaultNavigationTimeout(30000);

    console.log('正在导航到 https://www.baidu.com...');
    await page.goto('https://www.baidu.com', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    const title = await page.title();
    console.log('页面标题:', title);
    console.log('测试成功！');
  } catch (error) {
    console.error('测试失败:', error.message);
    console.error('错误堆栈:', error.stack);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

test();