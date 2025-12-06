import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function cleanDatabase() {
  try {
    console.log('开始清空数据库中的测试数据...');

    // 删除所有文档
    const deleteResult = await prisma.document.deleteMany({});
    console.log(`成功删除 ${deleteResult.count} 条文档记录`);

    // 删除所有提交记录
    const submissionResult = await prisma.submission.deleteMany({});
    console.log(`成功删除 ${submissionResult.count} 条提交记录`);

    console.log('数据库清空完成！');
  } catch (error) {
    console.error('清空数据库时出错:', error);
  } finally {
    await prisma.$disconnect();
  }
}

cleanDatabase();