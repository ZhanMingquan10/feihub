import puppeteer from "puppeteer";
import { FeishuDocumentData } from "./feishu";

/**
 * 获取飞书文档内容（使用 Puppeteer）
 */
export async function fetchFeishuDocument(link: string): Promise<FeishuDocumentData> {
  let browser;
  try {
    console.log(`开始获取飞书文档: ${link}`);

    // 启动浏览器
    browser = await puppeteer.launch({
      headless: true,
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
        '--window-size=1920,1080'
      ]
    });

    const page = await browser.newPage();

    // 设置视口和 User-Agent
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    // 访问页面
    console.log(`正在加载页面...`);
    await page.goto(link, {
      waitUntil: 'networkidle0',
      timeout: 60000
    });

    // 等待内容加载
    console.log(`等待内容渲染...`);
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 提取标题
    const title = await page.evaluate(() => {
      const h1 = document.querySelector('h1');
      if (h1) return h1.innerText.trim();

      const titleEl = document.querySelector('.wiki-title, .doc-title, .title') as HTMLElement | null;
      if (titleEl) return titleEl.innerText.trim();

      const titleTag = document.title;
      if (titleTag) {
        return titleTag
          .replace(/\s*[-|]\s*飞书.*$/i, '')
          .replace(/\s*[-|]\s*Feishu.*$/i, '')
          .replace(/\s*[-|]\s*Lark.*$/i, '')
          .trim();
      }

      return '';
    });

    // 提取内容
    let content = await page.evaluate(() => {
      const selectors = [
        '.wiki-content',
        '.doc-content',
        'main article',
        '[class*="content"]',
        'main',
        'article'
      ];

      for (const selector of selectors) {
        const element = document.querySelector(selector);
        if (element) {
          const text = (element as HTMLElement).innerText || element.textContent || '';
          const cleanText = text.trim();
          if (cleanText.length > 100) {
            return cleanText;
          }
        }
      }

      return document.body.innerText || '';
    });

    // 清理内容
    content = content.replace(/\s+/g, ' ').trim();

    if (content.length > 8000) {
      content = content.substring(0, 8000) + '...';
    }

    // 使用AI生成标签和总结（如果需要）
    const tags = ["文档", "分享", "阅读"]; // 默认标签
    const aiAngle1 = "";
    const aiSummary1 = "";
    const aiAngle2 = "";
    const aiSummary2 = "";

    console.log(`文档提取完成 - 标题: "${title}", 内容长度: ${content.length}`);

    return {
      title: title || "分享的文档",
      author: "社区贡献者",
      date: new Date().toISOString().split("T")[0],
      content: content || title || "文档内容无法自动提取，请查看原文档链接获取完整内容。",
      tags,
      aiAngle1,
      aiSummary1,
      aiAngle2,
      aiSummary2
    };

  } catch (error: any) {
    console.error("获取飞书文档失败:", error.message);
    throw error;
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}