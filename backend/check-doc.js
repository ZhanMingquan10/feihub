const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkLatestDoc() {
  try {
    const doc = await prisma.document.findFirst({
      orderBy: { createdAt: 'desc' }
    });

    if (doc) {
      console.log('Title:', doc.title);
      console.log('Content length:', doc.content.length);
      console.log('First 300 chars:');
      console.log(doc.content.substring(0, 300));
      console.log('---');
      console.log('Tags:', doc.tags);
      console.log('Date:', doc.date);
    } else {
      console.log('No documents found');
    }
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkLatestDoc();