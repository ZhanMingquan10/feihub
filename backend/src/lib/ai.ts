import OpenAI from "openai";
import * as fs from "fs";
import * as path from "path";

export interface AIGeneratedContent {
  tags: string[];
  summary: string; // 2句话总结（兼容旧格式）
  // 新的结构化格式
  angle1?: string; // 角度1
  summary1?: string; // 角度1的总结
  angle2?: string; // 角度2
  summary2?: string; // 角度2的总结
  // AI识别的文档信息（可选，用于验证）
  identifiedTitle?: string;
  identifiedDate?: string;
  identifiedContent?: string;
}

// 获取AI客户端（优先使用DeepSeek，如果没有配置则使用OpenAI）
function getAIClient(): OpenAI | null {
  // 优先使用 DeepSeek
  if (process.env.DEEPSEEK_API_KEY) {
    return new OpenAI({
      apiKey: process.env.DEEPSEEK_API_KEY,
      baseURL: "https://api.deepseek.com", // DeepSeek API 地址
    });
  }
  
  // 备用：使用 OpenAI
  if (process.env.OPENAI_API_KEY) {
    return new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }
  
  return null;
}

// 获取模型名称
function getModelName(): string {
  // DeepSeek 使用 deepseek-chat 模型
  if (process.env.DEEPSEEK_API_KEY) {
    return "deepseek-chat";
  }
  // OpenAI 使用 gpt-4o-mini（更经济）
  return "gpt-4o-mini";
}

/**
 * 读取文章分析prompt文件
 */
function loadAnalysisPrompt(): string {
  try {
    // 尝试从backend/prompts目录读取
    const promptPath = path.join(process.cwd(), "prompts", "article-analysis.txt");
    if (fs.existsSync(promptPath)) {
      return fs.readFileSync(promptPath, "utf-8");
    }

    // 如果文件不存在，使用默认prompt
    console.warn("未找到prompts/article-analysis.txt文件，使用默认prompt");
    return `你是一个专业的内容分析助手。

请分析文章内容，生成：
1. 3个核心标签（简洁、准确）
2. 从2个不同角度进行一句话总结

要求：
- 标签长度2-6个字
- 总结每句不超过50字
- 避免使用"本文"等冗余词汇`;
  } catch (error) {
    console.error("读取prompt文件失败:", error);
    return "";
  }
}

/**
 * 使用AI生成文章标签和摘要
 * 支持 DeepSeek 和 OpenAI（优先使用 DeepSeek）
 */
export async function generateAIContent(content: string): Promise<AIGeneratedContent> {
  return generateAIContentFromHTML("", content);
}

/**
 * 使用AI从HTML内容生成文章信息、标签和摘要
 * 同时提取文档信息和生成标签摘要
 */
export async function generateAIContentFromHTML(htmlContent: string, textContent: string): Promise<AIGeneratedContent> {
  const client = getAIClient();
  
  if (!client) {
    console.error("未配置 AI API Key（DEEPSEEK_API_KEY 或 OPENAI_API_KEY）");
    return {
      tags: ["未分类"],
      summary: "内容分析中，请稍后查看。"
    };
  }

  try {
    // 读取prompt文件
    const promptTemplate = loadAnalysisPrompt();

    // 根据是否有HTML内容构建不同的prompt
    let fullPrompt: string;
    if (htmlContent) {
      // 有HTML内容时，要求AI提取所有信息
      const currentYear = new Date().getFullYear();
      fullPrompt = `${promptTemplate}

请分析以下HTML内容，识别文档信息并生成标签和摘要：

重要提示：当前年份是 ${currentYear} 年，处理日期时请注意：
1. 如果遇到"XX月XX日修改/创建"格式，请补全年份 ${currentYear}
2. 如果遇到"XXXX年XX月XX日修改/创建"格式，使用原年份

HTML内容：
${htmlContent.substring(0, 15000)} // 限制长度避免token过多

请严格按照JSON格式返回，必须包含以下所有字段：
{
  "identifiedTitle": "识别的文档标题",
  "identifiedDate": "识别的更新日期（YYYY-MM-DD格式）",
  "identifiedContent": "提取的正文内容（去除导航等无关信息）",
  "tags": ["标签1", "标签2", "标签3"],
  "angle1": "角度1的名称",
  "summary1": "角度1的一句话总结",
  "angle2": "角度2的名称",
  "summary2": "角度2的一句话总结"
}`;
      console.log(`[AI] 从HTML提取文档信息并生成标签和摘要`);
    } else {
      // 只有文本内容时，只生成标签和摘要
      fullPrompt = `${promptTemplate}

文章内容：
${textContent.substring(0, 8000)} // 限制长度避免token过多

请严格按照JSON格式返回，必须包含3个标签：
{
  "tags": ["标签1", "标签2", "标签3"],
  "angle1": "角度1的名称",
  "summary1": "角度1的一句话总结",
  "angle2": "角度2的名称",
  "summary2": "角度2的一句话总结"
}`;
      console.log(`[AI] 生成文章标签和双角度摘要`);
    }

    const model = getModelName();
    const apiProvider = process.env.DEEPSEEK_API_KEY ? "DeepSeek" : "OpenAI";

    console.log(`使用 ${apiProvider} API，模型: ${model}`);

    const completion = await client.chat.completions.create({
      model: model,
      messages: [
        {
          role: "system",
          content: "你是一个专业的内容分析助手，擅长提取关键信息和总结文章要点。请始终以JSON格式返回结果。"
        },
        {
          role: "user",
          content: fullPrompt
        }
      ],
      temperature: 0.5, // 降低温度以获得更稳定的结果
      max_tokens: 2000, // 增加token限制以支持更长的内容
      response_format: { type: "json_object" }, // 强制JSON格式
    });

    const responseText = completion.choices[0]?.message?.content || "";

    // 尝试解析JSON
    try {
      const parsed = JSON.parse(responseText);

      // 确保有3个标签
      let tags = Array.isArray(parsed.tags) ? parsed.tags : [];
      if (tags.length !== 3) {
        // 如果标签数量不对，生成默认标签
        tags = tags.length > 0 ? tags.slice(0, 3) : ["文档", "分享", "阅读"];
        while (tags.length < 3) {
          tags.push("未分类");
        }
      }

      // 构建兼容旧格式的summary
      const summary = parsed.summary1 && parsed.summary2
        ? `${parsed.angle1 || "角度1"}：${parsed.summary1}。${parsed.angle2 || "角度2"}：${parsed.summary2}。`
        : parsed.summary || "";

      // 验证和格式化日期
      let identifiedDate = parsed.identifiedDate;
      if (identifiedDate && !/^\d{4}-\d{2}-\d{2}$/.test(identifiedDate)) {
        // 如果日期格式不正确，尝试修复
        console.warn(`[AI] 识别的日期格式不正确: ${identifiedDate}`);
        identifiedDate = undefined;
      }

      // 如果有HTML内容，记录AI识别的信息
      if (htmlContent) {
        console.log(`[AI] 成功提取和生成内容:`);
        console.log(`[AI] - 识别标题: ${parsed.identifiedTitle}`);
        console.log(`[AI] - 识别日期: ${identifiedDate || "未识别"}`);
        console.log(`[AI] - 识别内容长度: ${parsed.identifiedContent?.length || 0}`);
        console.log(`[AI] - 标签数量: ${tags.length}, 角度1: ${parsed.angle1}, 角度2: ${parsed.angle2}`);
      } else {
        console.log(`[AI] 成功生成内容 - 标签数量: ${tags.length}, 角度1: ${parsed.angle1}, 角度2: ${parsed.angle2}`);
      }

      return {
        tags: tags,
        summary: summary, // 兼容旧格式
        angle1: parsed.angle1 || "",
        summary1: parsed.summary1 || "",
        angle2: parsed.angle2 || "",
        summary2: parsed.summary2 || "",
        // AI识别的文档信息（可选）
        identifiedTitle: parsed.identifiedTitle,
        identifiedDate: identifiedDate,
        identifiedContent: parsed.identifiedContent
      };
    } catch (parseError) {
      console.error("[AI] JSON解析失败:", parseError);
      // 如果JSON解析失败，尝试提取信息
      return extractFromText(responseText);
    }
  } catch (error: any) {
    console.error("AI生成内容失败:", error.message || error);
    // 返回默认值
    return {
      tags: ["文档", "分享", "阅读"], // 默认3个标签
      summary: "内容分析中，请稍后查看。"
    };
  }
}

function extractFromText(text: string): AIGeneratedContent {
  // 简单的文本提取逻辑（备用方案）
  const tags: string[] = [];
  const summary = text.split("\n").find(line => line.includes("总结") || line.length > 20) || "内容分析中。";
  
  // 尝试从文本中提取角度和总结（格式："角度1"："总结1"）
  const angle1Match = text.match(/"([^"]+)"[：:]\s*"([^"]+)"/);
  const allMatches = text.match(/"([^"]+)"[：:]\s*"([^"]+)"/g);
  
  let angle1 = "";
  let summary1 = "";
  let angle2 = "";
  let summary2 = "";
  
  if (allMatches && allMatches.length >= 2) {
    const firstMatch = allMatches[0].match(/"([^"]+)"[：:]\s*"([^"]+)"/);
    const secondMatch = allMatches[1].match(/"([^"]+)"[：:]\s*"([^"]+)"/);
    
    if (firstMatch) {
      angle1 = firstMatch[1];
      summary1 = firstMatch[2];
    }
    if (secondMatch) {
      angle2 = secondMatch[1];
      summary2 = secondMatch[2];
    }
  } else if (angle1Match) {
    angle1 = angle1Match[1];
    summary1 = angle1Match[2];
  }
  
  return { 
    tags, 
    summary,
    angle1: angle1 || undefined,
    summary1: summary1 || undefined,
    angle2: angle2 || undefined,
    summary2: summary2 || undefined
  };
}

