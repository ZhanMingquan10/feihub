import { prisma } from "../lib/prisma";
import { generateAIContent } from "../lib/ai";

export interface ProcessAIResult {
  success: boolean;
  error?: string;
}

/**
 * 处理AI内容生成：生成标签和摘要
 */
export async function processAIContent(documentId: string): Promise<ProcessAIResult> {
  try {
    console.log(`[AI处理] 开始处理文档ID: ${documentId}`);
    
    // 1. 获取文档内容
    const document = await prisma.document.findUnique({
      where: { id: documentId },
      select: { id: true, content: true, title: true }
    });

    if (!document) {
      return { success: false, error: "文档不存在" };
    }

    // 2. 检查是否已有AI内容（避免重复生成）
    const existingDoc = await prisma.document.findUnique({
      where: { id: documentId },
      select: { tags: true, aiSummary: true }
    });

    if (existingDoc && existingDoc.tags && existingDoc.tags.length > 0 && existingDoc.aiSummary) {
      console.log(`[AI处理] 文档已有AI内容，跳过生成`);
      return { success: true };
    }

    // 3. 生成AI内容
    console.log(`[AI处理] 开始生成AI内容...`);
    const content = document.content || document.title || "";
    const aiContent = await generateAIContent(content);
    console.log(`[AI处理] AI内容生成成功，标签: ${aiContent.tags.join(", ")}, 摘要长度: ${aiContent.summary.length}`);

    // 4. 更新文档
    console.log(`[AI处理] 准备更新文档，标签:`, JSON.stringify(aiContent.tags));
    console.log(`[AI处理] 标签类型:`, typeof aiContent.tags);
    console.log(`[AI处理] 标签是否为数组:`, Array.isArray(aiContent.tags));
    console.log(`[AI处理] 标签数量:`, aiContent.tags ? aiContent.tags.length : 0);
    
    const updatedDoc = await prisma.document.update({
      where: { id: documentId },
      data: {
        tags: aiContent.tags || [], // 确保是数组
        aiSummary: aiContent.summary, // 兼容旧格式
        aiAngle1: aiContent.angle1 || null,
        aiSummary1: aiContent.summary1 || null,
        aiAngle2: aiContent.angle2 || null,
        aiSummary2: aiContent.summary2 || null
      }
    });
    console.log(`[AI处理] 文档已更新，ID: ${documentId}`);
    console.log(`[AI处理] 更新后的标签:`, JSON.stringify(updatedDoc.tags));
    console.log(`[AI处理] 更新后的标签类型:`, typeof updatedDoc.tags);
    console.log(`[AI处理] 更新后的标签是否为数组:`, Array.isArray(updatedDoc.tags));
    console.log(`[AI处理] 角度1: ${aiContent.angle1 || "无"} - ${aiContent.summary1 || "无"}`);
    console.log(`[AI处理] 角度2: ${aiContent.angle2 || "无"} - ${aiContent.summary2 || "无"}`);

    return { success: true };
  } catch (error: any) {
    console.error("[AI处理] 处理失败:", error);
    console.error("[AI处理] 错误堆栈:", error.stack);
    return { success: false, error: error.message };
  }
}

