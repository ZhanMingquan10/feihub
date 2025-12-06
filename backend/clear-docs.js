const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function clearDocs() {
  try {
    const result = await prisma.document.deleteMany();
    console.log(`Deleted ${result.count} documents`);

    const submissionResult = await prisma.documentSubmission.deleteMany();
    console.log(`Deleted ${submissionResult.count} submissions`);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

clearDocs();