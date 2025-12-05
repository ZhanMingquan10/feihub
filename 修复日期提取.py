#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
修复 feishu-puppeteer.ts 的日期提取问题
"""

import re
import sys

def fix_feishu_puppeteer(file_path):
    """修复日期提取逻辑"""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # 修复1: 在 timeSelectors 数组最前面添加 .doc-info-time-item
    pattern1 = r"(const timeSelectors = \[)"
    replacement1 = r'\1\n        ".doc-info-time-item",  // 优先查找飞书文档的修改时间元素'
    content = re.sub(pattern1, replacement1, content)
    
    # 修复2: 在页面加载后，添加等待日期元素的代码
    # 找到 "额外等待3秒" 之后的位置
    pattern2 = r"(额外等待3秒，确保内容完全渲染\.\.\.\s*\n\s*await new Promise\(resolve => setTimeout\(resolve, 3000\)\);)"
    replacement2 = r'''额外等待3秒，确保内容完全渲染...
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
    await new Promise(resolve => setTimeout(resolve, 3000));'''
    content = re.sub(pattern2, replacement2, content, flags=re.MULTILINE)
    
    # 修复3: 在 pageData 提取的日期部分，优先查找 .doc-info-time-item
    pattern3 = r"(// 3\. 提取日期 - 查找更新时间\s*\n\s*// 方法1: 查找时间相关的元素\(优先\)\s*\n\s*const timeSelectors)"
    replacement3 = r'''// 3. 提取日期 - 查找更新时间
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
      const timeSelectors'''
    content = re.sub(pattern3, replacement3, content, flags=re.MULTILINE)
    
    # 修复4: 在 pageData 提取后，添加详细日志
    pattern4 = r"(const pageData = await page\.evaluate\(\(\) => \{)"
    replacement4 = r'''const pageData = await page.evaluate(() => {
      console.log(`[Puppeteer] 🔍 开始提取 pageData...`);'''
    content = re.sub(pattern4, replacement4, content)
    
    # 在 pageData 返回后添加日志
    pattern5 = r"(let dateText = pageData\.date \|\| "";)"
    replacement5 = r'''console.log(`[Puppeteer] 🔍 pageData 提取结果（详细）:`);
    console.log(`[Puppeteer] - 标题: "${pageData.title}"`);
    console.log(`[Puppeteer] - 作者: "${pageData.author}"`);
    console.log(`[Puppeteer] - 日期（原始，从 pageData）: "${pageData.date}"`);
    
    let dateText = pageData.date || "";'''
    content = re.sub(pattern5, replacement5, content)
    
    # 修复5: 改进日期解析日志
    pattern6 = r"(dateText = parseChineseDate\(dateText\);)"
    replacement6 = r'''console.log(`[Puppeteer] 准备解析日期: "${dateText}"`);
      dateText = parseChineseDate(dateText);
      console.log(`[Puppeteer] 解析后的日期: "${dateText}"`);'''
    content = re.sub(pattern6, replacement6, content)
    
    # 检查是否有修改
    if content != original_content:
        # 备份原文件
        backup_path = file_path + '.backup'
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original_content)
        print(f"✅ 已备份原文件到: {backup_path}")
        
        # 写入修改后的内容
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ 已修复文件: {file_path}")
        return True
    else:
        print("⚠️ 没有找到需要修改的内容")
        return False

if __name__ == '__main__':
    file_path = '/www/wwwroot/feihub/backend/src/lib/feishu-puppeteer.ts'
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    
    try:
        fix_feishu_puppeteer(file_path)
    except Exception as e:
        print(f"❌ 错误: {e}")
        sys.exit(1)

