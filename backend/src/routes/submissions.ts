import express from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { documentQueue } from "../queue/processor";

const router = express.Router();

// 验证提交数据的schema
const submitSchema = z.object({
  link: z.string().url("必须是有效的URL")
});

/**
 * POST /api/submissions
 * 提交文档链接
 */
router.post("/", async (req, res) => {
  try {
    console.log("收到文档提交请求:", req.body);
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

      // 添加到任务队列（异步处理）
      try {
        console.log("添加到任务队列...");
        const job = await documentQueue.add({
          submissionId: submission.id,
          link
        }, {
          jobId: submission.id, // 使用 submissionId 作为 jobId，防止重复
          attempts: 2, // 只重试1次（总共2次尝试）
          backoff: {
            type: "exponential",
            delay: 5000 // 5秒后重试
          },
          removeOnComplete: true, // 完成后删除任务
          removeOnFail: false // 失败后保留任务（用于调试）
        });
        console.log("任务已添加到队列:", job.id);
    } catch (queueError: any) {
      console.error("添加到队列失败:", queueError);
      console.error("错误详情:", queueError.message, queueError.stack);
      // 如果队列失败，更新提交状态为失败
      await prisma.documentSubmission.update({
        where: { id: submission.id },
        data: {
          status: "failed",
          error: `队列错误: ${queueError.message || "Redis 连接失败，请检查 Redis 服务"}`
        }
      });
      return res.status(500).json({
        success: false,
        error: `队列服务错误: ${queueError.message || "请检查 Redis 服务"}`
      });
    }

    console.log("提交成功，返回响应");
    res.json({
      success: true,
      message: "文档已提交，AI正在处理中，预计需要几分钟...",
      submissionId: submission.id,
      documentId: tempDocument.id // 返回临时文档ID，前端可以立即显示
    });
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
 * GET /api/submissions/:id
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


