const { generateAIContentFromHTML } = require('./dist/lib/ai');

async function testAI() {
  console.log('开始测试AI功能...');

  // 测试用的HTML内容
  const htmlContent = `
    <html>
      <head>
        <title>251205-如何把自己活好，让优势和项目自然涌现？​</title>
      </head>
      <body>
        <div class="wiki-title">251205-如何把自己活好，让优势和项目自然涌现？​</div>
        <div class="date">2025-12-06</div>
        <div class="content">
          我感觉有启发、有道理。<br>
          不过，我找到优势和项目的方式和他的不太一样，我想把我的方式说一下，对这个主题也贡献一份视角。<br>
          <br>
          一、我们思路的差异<br>
          条形马老师的思路是...
        </div>
      </body>
    </html>
  `;

  const textContent = `
    251205-如何把自己活好，让优势和项目自然涌现？​
    2025-12-06
    我感觉有启发、有道理。
    不过，我找到优势和项目的方式和他的不太一样，我想把我的方式说一下，对这个主题也贡献一份视角。

    一、我们思路的差异
    条形马老师的思路是先找到自己的优势，然后围绕优势去寻找项目。这种方式很适合那些有明显专长的人。
  `;

  try {
    console.log('调用AI生成内容...');
    const result = await generateAIContentFromHTML(htmlContent, textContent);

    console.log('\n=== AI生成结果 ===');
    console.log('标签:', result.tags);
    console.log('角度1:', result.angle1);
    console.log('总结1:', result.summary1);
    console.log('角度2:', result.angle2);
    console.log('总结2:', result.summary2);
    console.log('识别标题:', result.identifiedTitle);
    console.log('识别日期:', result.identifiedDate);
    console.log('\n==================\n');
  } catch (error) {
    console.error('AI测试失败:', error);
  }
}

testAI();