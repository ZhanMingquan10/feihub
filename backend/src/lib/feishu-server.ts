import puppeteer from "puppeteer-core";
import { FeishuDocumentData } from "./feishu";
import { generateAIContentFromHTML } from "./ai";

/**
 * 服务器端飞书文档爬取（使用 Puppeteer + Chromium）
 * 适用于云服务器部署
 */
export async function fetchFeishuDocumentServer(link: string): Promise<FeishuDocumentData> {
  let browser;
  try {
    console.log(`[服务器爬取] 开始获取飞书文档: ${link}`);
    
    // 启动浏览器（服务器环境配置）
    browser = await puppeteer.launch({
      headless: true, // 无头模式，适合服务器
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--disable-gpu',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process',
        '--single-process', // 单进程模式，减少资源占用
        '--disable-background-networking',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-breakpad',
        '--disable-client-side-phishing-detection',
        '--disable-component-update',
        '--disable-default-apps',
        '--disable-domain-reliability',
        '--disable-extensions',
        '--disable-hang-monitor',
        '--disable-ipc-flooding-protection',
        '--disable-notifications',
        '--disable-offer-store-unmasked-wallet-cards',
        '--disable-popup-blocking',
        '--disable-print-preview',
        '--disable-prompt-on-repost',
        '--disable-renderer-backgrounding',
        '--disable-speech-api',
        '--disable-sync',
        '--hide-scrollbars',
        '--ignore-gpu-blacklist',
        '--metrics-recording-only',
        '--mute-audio',
        '--no-first-run',
        '--no-pings',
        '--no-zygote',
        '--password-store=basic',
        '--use-mock-keychain',
        '--window-size=1920,1080'
      ],
      // 设置超时时间
      timeout: 60000
    });

    const page = await browser.newPage();
    
    // 设置视口和 User-Agent
    await page.setViewport({ width: 1920, height: 1080 });
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    // 设置请求拦截，移除不必要的资源加载（加快速度）
    await page.setRequestInterception(true);
    page.on('request', (req: any) => {
      const resourceType = req.resourceType();
      // 只加载必要的资源
      if (['image', 'font', 'media'].includes(resourceType)) {
        req.abort();
      } else {
        req.continue();
      }
    });
    
    // 访问页面
    console.log(`[服务器爬取] 正在加载页面...`);
    await page.goto(link, {
      waitUntil: 'networkidle2', // 等待网络空闲
      timeout: 30000
    });

    // 等待内容加载（飞书文档可能需要一些时间渲染）
    console.log(`[服务器爬取] 等待内容渲染...`);
    await new Promise(resolve => setTimeout(resolve, 5000)); // 等待 5 秒让 JavaScript 渲染完成

    // 获取页面HTML内容
    let htmlContent = "";
    try {
      htmlContent = await page.content();
      console.log(`[服务器爬取] 获取到HTML内容，长度: ${htmlContent.length}`);
    } catch (e) {
      console.error(`[服务器爬取] 获取HTML内容失败:`, e);
      throw new Error("无法获取页面HTML内容");
    }

    // 使用AI一次性提取所有信息（文档信息+标签+总结）
    console.log(`[服务器爬取] 使用AI一次性提取所有信息...`);
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

      console.log(`[服务器爬取] AI一次提取成功:`);
      console.log(`[服务器爬取] - 标题: ${title}`);
      console.log(`[服务器爬取] - 日期: ${date}`);
      console.log(`[服务器爬取] - 内容长度: ${content.length}`);
      console.log(`[服务器爬取] - 标签: ${tags.join(", ")}`);
      console.log(`[服务器爬取] - 角度1: ${aiAngle1} - ${aiSummary1}`);
      console.log(`[服务器爬取] - 角度2: ${aiAngle2} - ${aiSummary2}`);
    } catch (aiError) {
      console.error(`[服务器爬取] AI提取失败，使用备用方法:`, aiError);

      // 备用提取方法（原有的逻辑）
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
            '[class*="content"]'
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
        console.error(`[服务器爬取] 备用提取也失败:`, fallbackError);
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

    console.log(`[服务器爬取] 最终提取结果 - 标题: "${title}", 内容长度: ${content.length}`);

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
    console.error("[服务器爬取] 获取飞书文档失败:", error.message);
    throw error;
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

