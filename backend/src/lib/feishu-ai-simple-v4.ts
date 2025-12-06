import puppeteer from "puppeteer-core";
import { FeishuDocumentData } from "./feishu";
import { generateAIContentFromHTML } from "./ai";

/**
 * 获取飞书文档内容（带滚动加载和AI分析渲染后页面）
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

    // 模拟用户缓慢滚动以加载完整内容
    console.log(`开始模拟用户滚动加载内容...`);
    let previousHeight = 0;
    let currentHeight = 0;
    let scrollAttempts = 0;
    const maxScrollAttempts = 50; // 最大滚动次数

    while (scrollAttempts < maxScrollAttempts) {
      // 获取当前页面高度
      currentHeight = await page.evaluate(() => document.body.scrollHeight);

      // 滚动到页面底部
      await page.evaluate(() => {
        window.scrollTo(0, document.body.scrollHeight);
      });

      // 等待新内容加载
      await new Promise(resolve => setTimeout(resolve, 1000));

      // 检查页面高度是否有变化
      if (currentHeight === previousHeight) {
        // 页面高度没有变化，可能已经到底了
        break;
      }

      previousHeight = currentHeight;
      scrollAttempts++;

      console.log(`滚动 ${scrollAttempts}: 当前页面高度 ${currentHeight}px`);
    }

    console.log(`滚动完成，共滚动 ${scrollAttempts} 次，最终页面高度: ${currentHeight}px`);

    // 再次等待，确保懒加载的内容都渲染完成
    await new Promise(resolve => setTimeout(resolve, 3000));

    // 初始化变量
    console.log(`开始提取内容...`);
    let title = "";
    let date = extractedDate || new Date().toISOString().split("T")[0];
    let content = "";
    let tags: string[] = ["文档", "分享", "阅读"]; // 默认标签
    let aiAngle1 = "";
    let aiSummary1 = "";
    let aiAngle2 = "";
    let aiSummary2 = "";

    // 第一步：直接提取正文内容
    try {
      // 提取标题
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

      // 提取正文内容（提取渲染后的文本内容）
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
          '.slate-content',
          '.slate-string-group',
          '.slate-leaf',
          '[data-slate-editor="true"]',
          '.render-container',
          '.doc-container',
          '.wiki-body',
          '.wiki-main-content'
        ];

        // 获取文本内容，保留段落格式
        for (const selector of selectors) {
          const element = document.querySelector(selector);
          if (element) {
            const text = (element as HTMLElement).innerText || element.textContent || '';
            const cleanText = text.trim();
            if (cleanText.length > 100) {
              // 保留段落结构和换行
              return cleanText;
            }
          }
        }

        // 最后尝试获取整个body的内容
        const bodyText = document.body.innerText || '';
        return bodyText;
      });

      // 如果内容太长，截取前8000个字符（在段落边界）
      if (content.length > 8000) {
        const truncated = content.substring(0, 8000);
        // 找到最后一个句号或换行符的位置
        const lastSentence = Math.max(
          truncated.lastIndexOf('。'),
          truncated.lastIndexOf('！'),
          truncated.lastIndexOf('？'),
          truncated.lastIndexOf('\n\n')
        );
        if (lastSentence > 7000) {
          content = truncated.substring(0, lastSentence + 1) + '\n\n...';
        } else {
          content = truncated + '...';
        }
      }

      console.log(`直接提取完成:`);
      console.log(`- 标题: ${title}`);
      console.log(`- 内容长度: ${content.length}`);

      // 如果内容看起来像是错误信息，则使用AI分析渲染后的页面
      if (content.includes('HTML内容中未提供明确的正文内容') ||
          content.includes('无法获取') ||
          content.length < 50) {
        console.log(`内容看起来无效，尝试AI分析渲染后的页面...`);
        throw new Error('直接提取失败，需要AI分析');
      }

    } catch (directError) {
      console.error(`直接提取失败，尝试AI分析渲染后的页面:`, directError);

      // 第二步：让AI分析渲染后的页面
      try {
        // 获取渲染后的文本内容（不是HTML）
        const renderedText = await page.evaluate(() => {
          // 获取整个页面的文本内容
          const bodyText = document.body.innerText || '';
          return bodyText;
        });

        console.log(`获取到渲染后文本，长度: ${renderedText.length}`);

        // 使用AI分析渲染后的文本内容
        // 注意：这里传递的是纯文本，不是HTML
        const aiResult = await generateAIContentFromHTML(renderedText,
          extractedDate ? `（提示：在页面中发现的日期：${extractedDate}）` : '');

        if (aiResult.identifiedTitle) title = aiResult.identifiedTitle;
        if (aiResult.identifiedDate && aiResult.identifiedDate !== 'null') {
          date = aiResult.identifiedDate;
        }
        if (aiResult.identifiedContent) content = aiResult.identifiedContent;

        tags = aiResult.tags;
        aiAngle1 = aiResult.angle1 || "";
        aiSummary1 = aiResult.summary1 || "";
        aiAngle2 = aiResult.angle2 || "";
        aiSummary2 = aiResult.summary2 || "";

        console.log(`AI分析成功:`);
        console.log(`- 标题: ${title}`);
        console.log(`- 日期: ${date}`);
        console.log(`- 内容长度: ${content.length}`);
      } catch (aiError) {
        console.error(`AI分析也失败:`, aiError);

        // 第三步：最后的备用方法
        try {
          // 备用标题提取
          if (!title) {
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
          }

          // 获取页面所有文本作为内容
          if (!content || content.length < 20) {
            content = await page.evaluate(() => {
              return document.body.innerText || '';
            });
          }

          // 截取前8000个字符
          if (content.length > 8000) {
            content = content.substring(0, 8000) + '...';
          }

        } catch (fallbackError) {
          console.error(`备用提取也失败:`, fallbackError);
          title = "分享的文档";
          content = "文档内容无法自动提取，请查看原文档链接获取完整内容。";
        }
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