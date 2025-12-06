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

    // 尝试提取页面中的日期信息（通过JavaScript执行）
    const extractedDate = await page.evaluate(() => {
      // 查找可能的日期元素
      const dateSelectors = [
        '[data-date]',
        '[data-time]',
        'time',
        '[class*="date"]',
        '[class*="time"]',
        '[class*="update"]',
        '[class*="modified"]',
        '.metadata',
        '.doc-info',
        '.wiki-info',
        '[class*="meta"]'
      ];

      for (const selector of dateSelectors) {
        const elements = document.querySelectorAll(selector);
        for (let i = 0; i < elements.length; i++) {
          const el = elements[i];
          // 检查属性
          const dateAttr = el.getAttribute('data-date') ||
                         el.getAttribute('data-time') ||
                         el.getAttribute('datetime');
          if (dateAttr) return dateAttr;

          // 检查文本内容
          const text = el.textContent || '';
          const dateMatch = text.match(/(\d{4})[-年](\d{1,2})[-月](\d{1,2})日?/);
          if (dateMatch) {
            return `${dateMatch[1]}-${dateMatch[2].padStart(2, '0')}-${dateMatch[3].padStart(2, '0')}`;
          }

          // 检查"X月X日修改"格式
          const modMatch = text.match(/(\d{1,2})月(\d{1,2})日[创建修改]/);
          if (modMatch) {
            const year = new Date().getFullYear();
            return `${year}-${modMatch[1].padStart(2, '0')}-${modMatch[2].padStart(2, '0')}`;
          }
        }
      }

      return null;
    });

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
    let date = extractedDate || new Date().toISOString().split("T")[0];
    let content = "";
    let tags: string[] = ["文档", "分享", "阅读"]; // 默认标签
    let aiAngle1 = "";
    let aiSummary1 = "";
    let aiAngle2 = "";
    let aiSummary2 = "";

    try {
      // 使用AI提取所有信息，传递提取到的日期作为参考
      const dateHint = extractedDate ? `（提示：在页面中发现的日期：${extractedDate}）` : '';
      const aiResult = await generateAIContentFromHTML(htmlContent, dateHint);

      if (aiResult.identifiedTitle) title = aiResult.identifiedTitle;
      // 优先使用提取的日期，然后使用AI识别的日期
      if (aiResult.identifiedDate && aiResult.identifiedDate !== 'null') {
        date = aiResult.identifiedDate;
      }
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

        // 备用内容提取 - 保留原始格式和分段
        content = await page.evaluate(() => {
          // 尝试多种选择器获取正文内容
          const selectors = [
            '.wiki-content',
            '.doc-content',
            '[data-testid="wiki-content"]',
            '[data-testid="doc-content"]',
            '[class*="content-wrapper"]',
            '[class*="editor-content"]',
            '[class*="render-content"]',
            'main article',
            '[class*="content"]',
            'main',
            'article',
            '.suite-content',
            '.slate-content-wrapper',
            '.slate-content'
          ];

          // 首先尝试获取保持格式的HTML内容
          for (const selector of selectors) {
            const element = document.querySelector(selector);
            if (element) {
              // 获取元素的HTML内容，保留段落格式
              const html = (element as HTMLElement).innerHTML || '';
              if (html && html.length > 100) {
                return html;
              }
            }
          }

          // 如果HTML失败，尝试获取文本内容
          for (const selector of selectors) {
            const element = document.querySelector(selector);
            if (element) {
              const text = (element as HTMLElement).innerText || element.textContent || '';
              const cleanText = text.trim();
              if (cleanText.length > 100) {
                // 将文本转换为段落格式
                return cleanText.split('\n\n').map(p => p.trim()).filter(p => p).join('\n\n');
              }
            }
          }

          // 最后尝试获取整个body的内容
          const bodyText = document.body.innerText || '';
          return bodyText.split('\n\n').map(p => p.trim()).filter(p => p).join('\n\n');
        });

        // 清理内容，但保留段落格式
        // 不替换多个空格，保持原有的格式
        content = content.trim();

        // 如果内容太长，尝试在段落边界截断
        if (content.length > 8000) {
          // 尝试在段落后截断
          const paragraphs = content.split('\n\n');
          let truncatedContent = '';
          for (const para of paragraphs) {
            if ((truncatedContent + para).length > 8000) {
              truncatedContent += '\n\n...';
              break;
            }
            truncatedContent += (truncatedContent ? '\n\n' : '') + para;
          }
          content = truncatedContent || content.substring(0, 8000) + '...';
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