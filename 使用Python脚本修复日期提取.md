# 使用 Python 脚本修复日期提取

## 🚀 在服务器上执行

在宝塔终端执行：

```bash
cd /www/wwwroot/feihub/backend/src/lib

# 创建 Python 脚本
cat > /tmp/fix_date.py << 'PYTHON_EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import re

file_path = '/www/wwwroot/feihub/backend/src/lib/feishu-puppeteer.ts'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

original_content = content

# 修复1: 在 timeSelectors 数组最前面添加 .doc-info-time-item
content = re.sub(
    r'(const timeSelectors = \[)',
    r'\1\n        ".doc-info-time-item",  // 优先查找飞书文档的修改时间元素',
    content
)

# 修复2: 在页面加载后，添加等待日期元素的代码
content = re.sub(
    r'(额外等待3秒，确保内容完全渲染\.\.\.\s*\n\s*await new Promise\(resolve => setTimeout\(resolve, 3000\)\);)',
    r'''额外等待3秒，确保内容完全渲染...
    await new Promise(resolve => setTimeout(resolve, 3000));

    // 额外等待，确保日期元素也加载完成（飞书的日期元素可能需要更长时间）
    console.log(`[Puppeteer] 额外等待，确保日期元素加载完成...`);
    
    // 等待日期元素出现（最多等待10秒）
    try {
      await page.waitForSelector('.doc-info-time-item', { timeout: 10000 });
      console.log(`[Puppeteer] ✅ 找到日期元素 .doc-info-time-item`);
      
      // 立即提取日期元素的内容，用于调试
      const dateElementText = await page.evaluate(() => {
        const el = document.querySelector('.doc-info-time-item');
        if (el) {
          return (el.innerText || el.textContent || '').trim();
        }
        return null;
      });
      console.log(`[Puppeteer] 📅 日期元素内容: "${dateElementText}"`);
    } catch (e) {
      console.warn(`[Puppeteer] ⚠️ 未找到日期元素 .doc-info-time-item，继续提取...`);
    }
    
    // 再等待3秒，确保所有内容完全渲染
    await new Promise(resolve => setTimeout(resolve, 3000));''',
    content,
    flags=re.MULTILINE
)

# 修复3: 在 pageData 提取的日期部分，优先查找 .doc-info-time-item
content = re.sub(
    r'(// 3\. 提取日期 - 查找更新时间\s*\n\s*// 方法1: 查找时间相关的元素\(优先\)\s*\n\s*const timeSelectors)',
    r'''// 3. 提取日期 - 查找更新时间
      // 优先查找 .doc-info-time-item（飞书文档的修改时间）
      const docInfoTimeEl = document.querySelector('.doc-info-time-item') as HTMLElement | null;
      if (docInfoTimeEl) {
        const timeText = (docInfoTimeEl.innerText || docInfoTimeEl.textContent || '').trim();
        if (timeText && timeText.length > 3) {
          result.date = timeText;
          console.log(`[Puppeteer] ✅ 找到日期来源: .doc-info-time-item, 内容: "${timeText}"`);
        }
      }
      
      // 如果还没找到，继续使用其他选择器
      // 方法1: 查找时间相关的元素（优先）
      const timeSelectors''',
    content,
    flags=re.MULTILINE
)

# 修复4: 在 pageData 提取后，添加详细日志
content = re.sub(
    r'(let dateText = pageData\.date \|\| "";)',
    r'''console.log(`[Puppeteer] 🔍 pageData 提取结果（详细）:`);
    console.log(`[Puppeteer] - 标题: "${pageData.title}"`);
    console.log(`[Puppeteer] - 作者: "${pageData.author}"`);
    console.log(`[Puppeteer] - 日期（原始，从 pageData）: "${pageData.date}"`);
    
    let dateText = pageData.date || "";''',
    content
)

# 修复5: 改进日期解析日志
content = re.sub(
    r'(dateText = parseChineseDate\(dateText\);)',
    r'''console.log(`[Puppeteer] 准备解析日期: "${dateText}"`);
      dateText = parseChineseDate(dateText);
      console.log(`[Puppeteer] 解析后的日期: "${dateText}"`);''',
    content
)

# 备份并保存
if content != original_content:
    backup_path = file_path + '.backup'
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(original_content)
    print(f"✅ 已备份原文件到: {backup_path}")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ 已修复文件: {file_path}")
else:
    print("⚠️ 没有找到需要修改的内容")
PYTHON_EOF

# 执行脚本
python3 /tmp/fix_date.py
```

---

## ✅ 修复完成后，重新构建和部署

```bash
cd /www/wwwroot/feihub/backend

# 重新构建
npm run build

# 完全重启 PM2
pm2 stop feihub-backend
pm2 delete feihub-backend
pm2 start npm --name feihub-backend -- run start

# 等待启动
sleep 5

# 查看启动日志
pm2 logs feihub-backend --lines 30 --nostream | grep -E "(启动|CHROME_PATH)" | tail -10
```

---

## 🧪 测试

提交测试文档后，应该能看到：
- `[Puppeteer] 额外等待，确保日期元素加载完成...`
- `[Puppeteer] ✅ 找到日期元素 .doc-info-time-item`
- `[Puppeteer] 📅 日期元素内容: "2024年1月9日修改"`
- `[Puppeteer] 🔍 pageData 提取结果（详细）:`

