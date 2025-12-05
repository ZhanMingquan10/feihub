import { prisma } from "../lib/prisma";
import { fetchFeishuDocument } from "../lib/feishu";

export interface ProcessDocumentResult {
  success: boolean;
  documentId?: string;
  error?: string;
}

/**
 * 处理文档提交：获取内容、生成AI摘要、保存到数据库
 */
export async function processDocumentSubmission(
  submissionId: string,
  link: string
): Promise<ProcessDocumentResult> {
  try {
    console.log(`[处理文档] 开始处理 submissionId: ${submissionId}, link: ${link}`);
    
    // 0. 检查提交状态，避免重复处理
    const submission = await prisma.documentSubmission.findUnique({
      where: { id: submissionId }
    });
    
    if (!submission) {
      return { success: false, error: "提交记录不存在" };
    }
    
    // 如果已经完成，直接返回
    if (submission.status === "completed" && submission.documentId) {
      console.log(`[处理文档] 提交已完成，跳过处理: ${submission.documentId}`);
      return { success: true, documentId: submission.documentId };
    }
    
    // 如果正在处理中，检查是否超时（超过5分钟认为超时，可以重试）
    if (submission.status === "processing") {
      const processingTime = Date.now() - submission.updatedAt.getTime();
      const timeout = 5 * 60 * 1000; // 5分钟
      if (processingTime < timeout) {
        console.log(`[处理文档] 提交正在处理中，跳过重复处理（已处理 ${Math.floor(processingTime / 1000)} 秒）`);
        return { success: false, error: "任务正在处理中，请勿重复提交" };
      } else {
        console.log(`[处理文档] 提交处理超时（${Math.floor(processingTime / 1000)} 秒），允许重试`);
      }
    }
    
    // 1. 更新状态为处理中
    await prisma.documentSubmission.update({
      where: { id: submissionId },
      data: { status: "processing" }
    });
    console.log(`[处理文档] 状态已更新为 processing`);

    // 2. 检查文档是否已存在（排除临时文档）
    const existing = await prisma.document.findUnique({
      where: { link }
    });

    if (existing && existing.title !== "内容正在联网获取...") {
      console.log(`[处理文档] 文档已存在: ${existing.id}`);
      await prisma.documentSubmission.update({
        where: { id: submissionId },
        data: {
          status: "completed",
          documentId: existing.id
        }
      });
      return { success: true, documentId: existing.id };
    }
    
    // 如果存在临时文档，继续处理（更新它）
    if (existing && existing.title === "内容正在联网获取...") {
      console.log(`[处理文档] 找到临时文档，将继续处理并更新: ${existing.id}`);
    }

    // 3. 获取飞书文档内容（AI已一次性提取所有信息）
    console.log(`[处理文档] 开始获取飞书文档内容...`);
    const docData = await fetchFeishuDocument(link);
    console.log(`[处理文档] 文档内容获取结果:`);
    console.log(`[处理文档] - 标题: "${docData.title}"`);
    console.log(`[处理文档] - 内容长度: ${docData.content.length}`);
    console.log(`[处理文档] - 内容预览: ${docData.content.substring(0, 200)}...`);

    // AI信息已经在fetchFeishuDocument中生成
    const aiTags = docData.tags || [];
    const aiAngle1 = docData.aiAngle1 || "";
    const aiSummary1 = docData.aiSummary1 || "";
    const aiAngle2 = docData.aiAngle2 || "";
    const aiSummary2 = docData.aiSummary2 || "";

    console.log(`[处理文档] AI生成信息:`);
    console.log(`[处理文档] - 标签: ${aiTags.join(", ")}`);
    console.log(`[处理文档] - 标签数量: ${aiTags.length}`);
    console.log(`[处理文档] - 角度1: ${aiAngle1 || "无"} - ${aiSummary1 || "无"}`);
    console.log(`[处理文档] - 角度2: ${aiAngle2 || "无"} - ${aiSummary2 || "无"}`);

    // 4. 检查是否已有临时文档记录（提交时创建的）
    // 重新获取 submission（因为可能已经更新）
    const updatedSubmission = await prisma.documentSubmission.findUnique({
      where: { id: submissionId }
    });
    
    let existingTempDoc = null;
    if (updatedSubmission?.documentId) {
      existingTempDoc = await prisma.document.findUnique({
        where: { id: updatedSubmission.documentId }
      });
    }

    // 生成预览文本（前500字，保留格式）
    const previewText = docData.content.length > 500 
      ? docData.content.substring(0, 500) + "..."
      : docData.content;

    // 构建兼容旧格式的summary
    const summary = aiSummary1 && aiSummary2
      ? `${aiAngle1 || "角度1"}：${aiSummary1}。${aiAngle2 || "角度2"}：${aiSummary2}。`
      : "";

    let document;
    if (existingTempDoc && existingTempDoc.title === "内容正在联网获取...") {
      // 更新临时文档记录
      console.log(`[处理文档] 更新临时文档记录: ${existingTempDoc.id}`);
      document = await prisma.document.update({
        where: { id: existingTempDoc.id },
        data: {
          title: docData.title,
          author: docData.author,
          preview: previewText, // 前500字作为预览
          content: docData.content, // 保存完整内容（保留格式）
          date: new Date(docData.date),
          tags: aiTags, // 标签数组
          aiSummary: summary, // 兼容旧格式
          aiAngle1: aiAngle1 || null,
          aiSummary1: aiSummary1 || null,
          aiAngle2: aiAngle2 || null,
          aiSummary2: aiSummary2 || null
        }
      });
      console.log(`[处理文档] 临时文档已更新，ID: ${document.id}`);
      console.log(`[处理文档] 保存的标签:`, JSON.stringify(document.tags));
    } else {
      // 创建新文档记录
      console.log(`[处理文档] 创建新文档记录...`);
      document = await prisma.document.create({
        data: {
          title: docData.title,
          author: docData.author,
          link: link,
          preview: previewText, // 前500字作为预览
          content: docData.content, // 保存完整内容（保留格式）
          date: new Date(docData.date),
          tags: aiTags, // 标签数组
          aiSummary: summary, // 兼容旧格式
          aiAngle1: aiAngle1 || null,
          aiSummary1: aiSummary1 || null,
          aiAngle2: aiAngle2 || null,
          aiSummary2: aiSummary2 || null,
          views: 0
        }
      });
      console.log(`[处理文档] 文档已保存到数据库，ID: ${document.id}`);
      console.log(`[处理文档] 保存的标签:`, JSON.stringify(document.tags));
    }

    // 6. 更新提交状态
    await prisma.documentSubmission.update({
      where: { id: submissionId },
      data: {
        status: "completed",
        documentId: document.id
      }
    });
    console.log(`[处理文档] 处理完成，文档ID: ${document.id}`);
    console.log(`[处理文档] 文档已包含标签: ${document.tags.join(", ")}`);
    // 注意：AI内容已在步骤4中同步生成，无需再添加到队列

    return { success: true, documentId: document.id };
  } catch (error: any) {
    console.error("[处理文档] 处理失败:", error);
    console.error("[处理文档] 错误堆栈:", error.stack);

    // 更新错误状态
    await prisma.documentSubmission.update({
      where: { id: submissionId },
      data: {
        status: "failed",
        error: error.message
      }
    });

    return { success: false, error: error.message };
  }
}


