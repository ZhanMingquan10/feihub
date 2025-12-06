import puppeteer from "puppeteer-core";
import { FeishuDocumentData } from "./feishu";
import { generateAIContentFromHTML } from "./ai";

/**
 * 获取飞书文档内容（使用 Puppeteer + AI智能提取）
 */
export async function fetchFeishuDocument(link: string): Promise<FeishuDocumentData> {
  let browser;
  try {
    console.log(`开始获取飞书文档: ${link}`);

    // 启动浏览器
    browser = await puppeteer.launch({
      headless: true,
      executablePath: '/snap/bin/chromium',
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

    // 获取页面HTML内容
    let htmlContent = "";
    try {
      htmlContent = await page.content();
      console.log(`获取到HTML内容，长度: ${htmlContent.length}`);
    } catch (e) {
      console.error(`获取HTML内容失败:`, e);
      throw new Error("无法获取页面HTML内容");
    }

    // 使用AI一次性提取所有信息
    console.log(`使用AI提取所有信息...`);
    let title = "";
    let date = new Date().toISOString().split("T")[0];
    let content = "";
    let tags: string[] = ["文档", "分享", "阅读"]; // 默认标签
    let aiAngle1 = "";
    let aiSummary1 = "";
    let aiAngle2 = "";
    let aiSummary2 = "";

    try {
      // 使用AI提取所有信息
      const aiResult = await generateAIContentFromHTML(htmlContent, "");

      if (aiResult.identifiedTitle) title = aiResult.identifiedTitle;
      if (aiResult.identifiedDate) date = aiResult.identifiedDate;
      if (aiResult.identifiedContent) content = aiResult.identifiedContent;

      tags = aiResult.tags;
      aiAngle1 = aiResult.angle1 || "";
      aiSummary1 = aiResult.summary1 || "";
      aiAngle2 = aiResult.angle2 || "";
      aiSummary2 = aiResult.summary2 || "";

      console.log(`AI提取成功:`);
      console.log(`- 标题: ${title}`);
      console.log(`- 日期: ${date}`);
      console.log(`- 内容长度: ${content.length}`);
      console.log(`- 标签: ${tags.join(", ")}`);
      console.log(`- 角度1: ${aiAngle1} - ${aiSummary1}`);
      console.log(`- 角度2: ${aiAngle2} - ${aiSummary2}`);
    } catch (aiError) {
      console.error(`AI提取失败，使用备用方法:`, aiError);

      // 备用提取方法
      try {
        // 备用标题提取
        title = await page.evaluate(() => {
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

        // 备用内容提取
        content = await page.evaluate(() => {
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

      } catch (fallbackError) {
        console.error(`备用提取也失败:`, fallbackError);
        title = "分享的文档";
        content = "文档内容无法自动提取，请查看原文档链接获取完整内容。";
      }
    }

    // 最终验证
    if (!title || title.length < 2) {
      title = "分享的文档";
    }

    if (!content || content.length < 20) {
      content = title || "文档内容无法自动提取，请查看原文档链接获取完整内容。";
    }

    console.log(`最终提取结果 - 标题: "${title}", 内容长度: ${content.length}`);

    return {
      title: title,
      author: "社区贡献者",
      date: date,
      content: content,
      // 添加AI生成的信息
      tags: tags,
      aiAngle1: aiAngle1,
      aiSummary1: aiSummary1,
      aiAngle2: aiAngle2,
      aiSummary2: aiSummary2
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