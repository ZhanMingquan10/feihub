const puppeteer = require('puppeteer-core');

async function test() {
  let browser;
  try {
    console.log('Starting browser...');
    browser = await puppeteer.launch({
      headless: true,
      executablePath: '/snap/bin/chromium',
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage'
      ]
    });

    const page = await browser.newPage();
    console.log('Navigating to https://www.baidu.com...');

    await page.goto('https://www.baidu.com', { timeout: 30000 });

    const title = await page.title();
    console.log('Page title:', title);
    console.log('Test successful!');
  } catch (error) {
    console.error('Test failed:', error);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

test();