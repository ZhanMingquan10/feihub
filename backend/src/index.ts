import express from "express";
import cors from "cors";
import { PrismaClient } from "@prisma/client";
import documentsRouter from "./routes/documents";
import submissionsRouter from "./routes/submissions";
// 确保队列处理器被导入和执行
require("./queue/processor"); // 导入队列处理器

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 路由
app.use("/api/documents", documentsRouter);
app.use("/api/submissions", submissionsRouter);

// 健康检查
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// 错误处理
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: "服务器内部错误" });
});

app.listen(PORT, () => {
  console.log(`服务器运行在端口 ${PORT}`);
});