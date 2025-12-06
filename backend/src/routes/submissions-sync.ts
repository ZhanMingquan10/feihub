import express from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { processDocumentSubmission } from "../services/documentProcessor";

const router = express.Router();

// 验证提交数据的schema
const submitSchema = z.object({
  link: z.string().url("必须是有效的URL")
});

/**
 * POST /api/submissions-sync
 * 提交文档链接（同步处理版本）
 */
router.post("/", async (req, res) => {
  try {
    console.log("收到文档提交请求（同步处理）:", req.body);
    const { link } = submitSchema.parse(req.body);
    console.log("验证通过，链接:", link);

    // 检查是否已存在（排除临时文档）
    const existing = await prisma.document.findUnique({
      where: { link }
    });

    if (existing && existing.title !== "内容正在联网获取...") {
      console.log("文档已存在:", existing.id);
      return res.json({
        success: true,
        message: "文档已存在",
        documentId: existing.id
      });
    }

    // 如果存在临时文档，删除它（重新创建）
    if (existing && existing.title === "内容正在联网获取...") {
      console.log("删除旧的临时文档:", existing.id);
      await prisma.document.delete({
        where: { id: existing.id }
      });
    }

    // 创建提交记录
    console.log("创建提交记录...");
    const submission = await prisma.documentSubmission.create({
      data: {
        link,
        status: "pending"
      }
    });
    console.log("提交记录已创建:", submission.id);

    // 立即创建一条临时文档记录，显示"内容正在联网获取"
    console.log("创建临时文档记录...");
    const tempDocument = await prisma.document.create({
      data: {
        title: "内容正在联网获取...",
        author: "系统",
        link: link,
        preview: "正在从飞书文档获取内容，请稍候...",
        date: new Date(),
        tags: ["处理中"],
        aiSummary: "内容正在联网获取中，请稍候...",
        views: 0
      }
    });
    console.log("临时文档记录已创建:", tempDocument.id);

    // 更新提交记录，关联临时文档
    await prisma.documentSubmission.update({
      where: { id: submission.id },
      data: { documentId: tempDocument.id }
    });

    // 设置请求超时时间（2分钟）
    req.setTimeout(2 * 60 * 1000);

    // 同步处理文档（不使用队列）
    console.log("开始同步处理文档...");
    try {
      const result = await processDocumentSubmission(submission.id, link);

      if (!result.success) {
        console.error("同步处理失败:", result.error);
        return res.status(500).json({
          success: false,
          error: result.error || "处理失败"
        });
      }

      console.log("同步处理完成，文档ID:", result.documentId);
      res.json({
        success: true,
        message: "文档处理完成",
        documentId: result.documentId
      });
    } catch (processError: any) {
      console.error("同步处理异常:", processError);
      res.status(500).json({
        success: false,
        error: processError.message || "处理异常"
      });
    }
  } catch (error: any) {
    if (error instanceof z.ZodError) {
      console.error("验证错误:", error.errors);
      return res.status(400).json({
        success: false,
        error: error.errors[0].message
      });
    }

    console.error("提交文档失败:", error);
    console.error("错误堆栈:", error.stack);
    res.status(500).json({
      success: false,
      error: error.message || "提交失败，请稍后重试"
    });
  }
});

/**
 * GET /api/submissions-sync/:id
 * 查询提交状态
 */
router.get("/:id", async (req, res) => {
  try {
    const submission = await prisma.documentSubmission.findUnique({
      where: { id: req.params.id }
    });

    if (!submission) {
      return res.status(404).json({
        success: false,
        error: "提交记录不存在"
      });
    }

    res.json({
      success: true,
      submission
    });
  } catch (error: any) {
    console.error("查询提交状态失败:", error);
    res.status(500).json({
      success: false,
      error: "查询失败"
    });
  }
});

export default router;