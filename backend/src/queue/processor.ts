import Queue from "bull";
import { processDocumentSubmission } from "../services/documentProcessor";
import { processAIContent } from "../services/aiProcessor";

const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";

// 创建任务队列（添加错误处理）
export const documentQueue = new Queue("document-processing", redisUrl);
export const aiQueue = new Queue("ai-processing", redisUrl);

// 监听 Redis 连接错误
documentQueue.on("error", (error) => {
  console.error("Redis 队列连接错误:", error);
  console.error("请确保 Redis 服务正在运行 (docker-compose up -d)");
});

documentQueue.on("waiting", (jobId) => {
  console.log(`任务等待中: ${jobId}`);
});

documentQueue.on("active", (job) => {
  console.log(`任务开始处理: ${job.id}`);
});

// 处理任务
documentQueue.process(async (job) => {
  const { submissionId, link } = job.data;
  console.log(`开始处理文档: ${link}`);
  
  const result = await processDocumentSubmission(submissionId, link);
  
  if (!result.success) {
    throw new Error(result.error || "处理失败");
  }
  
  return result;
});

// 队列事件监听
documentQueue.on("completed", (job, result) => {
  console.log(`文档处理完成: ${job.data.link}`);
});

documentQueue.on("failed", (job, err) => {
  console.error(`文档处理失败: ${job.data.link}`, err);
});

// AI处理队列
aiQueue.on("error", (error) => {
  console.error("AI队列连接错误:", error);
});

aiQueue.on("waiting", (jobId) => {
  console.log(`AI任务等待中: ${jobId}`);
});

aiQueue.on("active", (job) => {
  console.log(`AI任务开始处理: ${job.id}`);
});

// 处理AI生成任务
aiQueue.process(async (job) => {
  const { documentId } = job.data;
  console.log(`开始生成AI内容: ${documentId}`);
  
  const result = await processAIContent(documentId);
  
  if (!result.success) {
    throw new Error(result.error || "AI生成失败");
  }
  
  return result;
});

aiQueue.on("completed", (job, result) => {
  console.log(`AI内容生成完成: ${job.data.documentId}`);
});

aiQueue.on("failed", (job, err) => {
  console.error(`AI内容生成失败: ${job.data.documentId}`, err);
});

export default documentQueue;


