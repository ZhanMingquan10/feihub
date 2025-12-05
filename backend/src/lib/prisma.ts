import { PrismaClient } from '@prisma/client';

// 导出 Prisma 客户端实例
export const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});

// 处理进程退出时断开连接
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});

process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});