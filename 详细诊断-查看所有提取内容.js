// 详细诊断 - 查看所有提取到的内容
const { fetchFeishuDocument } = require('./dist/lib/feishu');

const link = 'https://ai.feishu.cn/docx/VGoXdFXmooasHUxsZ0icAD2WnGe';

console.log('=== 开始详细诊断 ===');
console.log('链接:', link);
console.log('');

fetchFeishuDocument(link)
  .then(result => {
    console.log('=== 最终提取结果 ===');
    console.log('');
    console.log('标题 (title):');
    console.log(result.title);
    console.log('');
    console.log('作者 (author):');
    console.log(result.author);
    console.log('');
    console.log('日期 (date):');
    console.log(result.date);
    console.log('');
    console.log('内容长度 (content.length):');
    console.log(result.content.length);
    console.log('');
    console.log('内容完整内容:');
    console.log('---开始---');
    console.log(result.content);
    console.log('---结束---');
    console.log('');
    console.log('=== 诊断完成 ===');
    process.exit(0);
  })
  .catch(error => {
    console.error('=== 爬取失败 ===');
    console.error('错误:', error.message);
    console.error('堆栈:', error.stack);
    process.exit(1);
  });

