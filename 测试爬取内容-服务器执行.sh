#!/bin/bash

# 测试爬取内容 - 查看实际提取的数据

cd /www/wwwroot/feihub/backend

echo "=== 创建测试脚本 ==="

cat > test_extract.js << 'JSEOF'
const { fetchFeishuDocument } = require('./dist/lib/feishu');

const link = 'https://ai.feishu.cn/docx/VGoXdFXmooasHUxsZ0icAD2WnGe';

console.log('=== 开始测试爬取 ===');
console.log('链接:', link);
console.log('');

fetchFeishuDocument(link)
  .then(result => {
    console.log('=== 爬取结果 ===');
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
    console.log('内容前500字符 (content.substring(0, 500)):');
    console.log(result.content.substring(0, 500));
    console.log('');
    console.log('内容完整内容 (content):');
    console.log('---开始---');
    console.log(result.content);
    console.log('---结束---');
    console.log('');
    console.log('=== 测试完成 ===');
    process.exit(0);
  })
  .catch(error => {
    console.error('=== 爬取失败 ===');
    console.error('错误:', error.message);
    console.error('堆栈:', error.stack);
    process.exit(1);
  });
JSEOF

echo "✅ 测试脚本已创建"
echo ""
echo "=== 执行测试 ==="
echo ""

node test_extract.js

echo ""
echo "=== 清理测试文件 ==="
rm -f test_extract.js

echo ""
echo "✅ 测试完成"

