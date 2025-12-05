// 临时测试脚本：测试飞书文档爬取
const axios = require('axios');
const cheerio = require('cheerio');

const link = 'https://ai.feishu.cn/wiki/UW5NwEY4wibWd2kUR9nc7vgCnvc';

async function testFetch() {
  try {
    const response = await axios.get(link, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"
      },
      timeout: 15000
    });

    const $ = cheerio.load(response.data);
    
    console.log('=== 标题提取测试 ===');
    console.log('title 标签:', $('title').text());
    console.log('h1 标签:', $('h1').first().text());
    console.log('meta og:title:', $('meta[property="og:title"]').attr('content'));
    
    console.log('\n=== 作者提取测试 ===');
    console.log('data-author:', $('[data-author]').attr('data-author'));
    console.log('.author:', $('.author').text());
    console.log('meta article:author:', $('meta[property="article:author"]').attr('content'));
    
    console.log('\n=== 内容提取测试 ===');
    const selectors = [
      '.wiki-content',
      '.doc-content',
      '.content',
      '[data-content]',
      'main article',
      'main .article-content'
    ];
    
    for (const selector of selectors) {
      const content = $(selector).first().text().trim();
      if (content.length > 50) {
        console.log(`${selector}: ${content.substring(0, 100)}...`);
      }
    }
    
    // 保存完整HTML用于分析
    require('fs').writeFileSync('feishu-page.html', response.data);
    console.log('\n完整HTML已保存到 feishu-page.html');
    
  } catch (error) {
    console.error('错误:', error.message);
  }
}

testFetch();


