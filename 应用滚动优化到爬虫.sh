#!/bin/bash

# 应用滚动优化到实际爬虫代码

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：保存当前版本 ==="
if [ -f "版本管理系统.sh" ]; then
    bash 版本管理系统.sh save "应用滚动优化前" 2>/dev/null || echo "⚠️  版本管理系统未安装，跳过"
fi

echo ""
echo "=== 第二步：应用滚动优化 ==="

python3 << 'PYEOF'
import re

with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    content = f.read()

original = content

# 查找滚动相关的代码位置
# 通常是在等待内容渲染的部分

# 1. 查找 "开始滚动" 或 "滚动页面" 的位置
scroll_pattern = r'(//\s*滚动页面|//\s*开始滚动|开始滚动页面|滚动页面)'

# 如果找到了滚动代码，替换它
if re.search(scroll_pattern, content, re.IGNORECASE):
    print("✅ 找到现有滚动代码，准备替换")
    
    # 查找滚动循环的开始和结束
    # 通常是一个 for 循环，包含 window.scrollTo 或 page.evaluate
    
    # 替换策略：找到滚动循环，替换为新的滚动逻辑
    old_scroll_pattern = r'(for\s*\([^)]*\)\s*\{[^}]*window\.scrollTo[^}]*\})'
    
    new_scroll_code = '''// 优化后的滚动策略：查找真实滚动容器并滚动
      console.log('[Puppeteer] 查找真实滚动容器...');
      const scrollInfo = await page.evaluate(() => {
        const info = {
          scrollContainers: []
        };
        
        // 查找所有可能包含滚动条的元素
        const allElements = document.querySelectorAll('*');
        allElements.forEach((el) => {
          const style = window.getComputedStyle(el);
          const overflow = style.overflow + style.overflowY + style.overflowX;
          if ((overflow.includes('scroll') || overflow.includes('auto')) && el.scrollHeight > el.clientHeight) {
            info.scrollContainers.push({
              tagName: el.tagName,
              className: el.className || '',
              id: el.id || '',
              scrollHeight: el.scrollHeight,
              clientHeight: el.clientHeight
            });
          }
        });
        
        return info;
      });
      
      // 找到最大的滚动容器
      if (scrollInfo.scrollContainers.length > 0) {
        const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => 
          current.scrollHeight > max.scrollHeight ? current : max
        );
        
        console.log(`[Puppeteer] 找到滚动容器: ${mainContainer.tagName} ${(mainContainer.className || mainContainer.id || '').substring(0, 50)}, 高度: ${mainContainer.scrollHeight}px`);
        
        // 在滚动容器上滚动
        for (let i = 0; i < 50; i++) {
          const currentState = await page.evaluate((containerInfo) => {
            const elements = document.querySelectorAll(containerInfo.tagName);
            let targetElement = null;
            
            for (const el of elements) {
              if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
                  (containerInfo.id && el.id === containerInfo.id)) {
                if (el.scrollHeight > el.clientHeight) {
                  targetElement = el;
                  break;
                }
              }
            }
            
            if (targetElement) {
              const scrollAmount = targetElement.clientHeight * 0.8;
              targetElement.scrollTop += scrollAmount;
              targetElement.dispatchEvent(new Event('scroll', { bubbles: true }));
              
              return {
                scrollHeight: targetElement.scrollHeight,
                scrollTop: targetElement.scrollTop,
                clientHeight: targetElement.clientHeight,
                textLength: document.body.innerText.length
              };
            }
            
            return null;
          }, {
            tagName: mainContainer.tagName,
            className: mainContainer.className,
            id: mainContainer.id
          });
          
          if (!currentState) break;
          
          await new Promise(resolve => setTimeout(resolve, 2000));
          
          if (i % 5 === 0) {
            console.log(`[Puppeteer] 滚动第 ${i + 1} 轮: 容器高度 ${currentState.scrollHeight}px, 文本长度 ${currentState.textLength} 字符`);
          }
          
          // 如果已经滚动到底部
          if (currentState.scrollTop + currentState.clientHeight >= currentState.scrollHeight - 10) {
            console.log('[Puppeteer] 已滚动到底部');
            break;
          }
        }
      } else {
        // 如果没有找到滚动容器，使用备用方案
        console.log('[Puppeteer] 未找到滚动容器，使用备用滚动方案');
        for (let i = 0; i < 20; i++) {
          await page.evaluate(() => {
            window.scrollTo(0, document.body.scrollHeight);
          });
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }'''
    
    # 尝试替换现有的滚动代码
    # 但更安全的方法是直接插入到等待内容渲染之后
    content = re.sub(old_scroll_pattern, new_scroll_code, content, flags=re.DOTALL)
else:
    print("⚠️  未找到现有滚动代码，准备插入新代码")
    
    # 查找 "等待内容渲染" 或类似的位置
    wait_pattern = r'(等待内容渲染|额外等待|确保内容完全渲染)'
    
    if re.search(wait_pattern, content):
        # 在等待之后插入滚动代码
        insert_point = re.search(wait_pattern, content)
        if insert_point:
            # 找到下一个分号或大括号
            end_pos = content.find(';', insert_point.end())
            if end_pos == -1:
                end_pos = content.find('\n', insert_point.end())
            
            if end_pos > 0:
                indent = '      '  # 6个空格
                new_code = f'''\n{indent}// 优化后的滚动策略：查找真实滚动容器并滚动
{indent}console.log('[Puppeteer] 查找真实滚动容器...');
{indent}const scrollInfo = await page.evaluate(() => {{
{indent}  const info = {{
{indent}    scrollContainers: []
{indent}  }};
{indent}  
{indent}  const allElements = document.querySelectorAll('*');
{indent}  allElements.forEach((el) => {{
{indent}    const style = window.getComputedStyle(el);
{indent}    const overflow = style.overflow + style.overflowY + style.overflowX;
{indent}    if ((overflow.includes('scroll') || overflow.includes('auto')) && el.scrollHeight > el.clientHeight) {{
{indent}      info.scrollContainers.push({{
{indent}        tagName: el.tagName,
{indent}        className: el.className || '',
{indent}        id: el.id || '',
{indent}        scrollHeight: el.scrollHeight,
{indent}        clientHeight: el.clientHeight
{indent}      }});
{indent}    }}
{indent}  }});
{indent}  
{indent}  return info;
{indent}}});
{indent}
{indent}if (scrollInfo.scrollContainers.length > 0) {{
{indent}  const mainContainer = scrollInfo.scrollContainers.reduce((max, current) => 
{indent}    current.scrollHeight > max.scrollHeight ? current : max
{indent}  );
{indent}  
{indent}  console.log(`[Puppeteer] 找到滚动容器: ${{mainContainer.tagName}} ${{(mainContainer.className || mainContainer.id || '').substring(0, 50)}}, 高度: ${{mainContainer.scrollHeight}}px`);
{indent}  
{indent}  for (let i = 0; i < 50; i++) {{
{indent}    const currentState = await page.evaluate((containerInfo) => {{
{indent}      const elements = document.querySelectorAll(containerInfo.tagName);
{indent}      let targetElement = null;
{indent}      
{indent}      for (const el of elements) {{
{indent}        if ((containerInfo.className && el.className.includes(containerInfo.className.split(' ')[0])) ||
{indent}            (containerInfo.id && el.id === containerInfo.id)) {{
{indent}          if (el.scrollHeight > el.clientHeight) {{
{indent}            targetElement = el;
{indent}            break;
{indent}          }}
{indent}        }}
{indent}      }}
{indent}      
{indent}      if (targetElement) {{
{indent}        const scrollAmount = targetElement.clientHeight * 0.8;
{indent}        targetElement.scrollTop += scrollAmount;
{indent}        targetElement.dispatchEvent(new Event('scroll', {{ bubbles: true }}));
{indent}        
{indent}        return {{
{indent}          scrollHeight: targetElement.scrollHeight,
{indent}          scrollTop: targetElement.scrollTop,
{indent}          clientHeight: targetElement.clientHeight,
{indent}          textLength: document.body.innerText.length
{indent}        }};
{indent}      }}
{indent}      
{indent}      return null;
{indent}    }}, {{
{indent}      tagName: mainContainer.tagName,
{indent}      className: mainContainer.className,
{indent}      id: mainContainer.id
{indent}    }});
{indent}    
{indent}    if (!currentState) break;
{indent}    
{indent}    await new Promise(resolve => setTimeout(resolve, 2000));
{indent}    
{indent}    if (i % 5 === 0) {{
{indent}      console.log(`[Puppeteer] 滚动第 ${{i + 1}} 轮: 容器高度 ${{currentState.scrollHeight}}px, 文本长度 ${{currentState.textLength}} 字符`);
{indent}    }}
{indent}    
{indent}    if (currentState.scrollTop + currentState.clientHeight >= currentState.scrollHeight - 10) {{
{indent}      console.log('[Puppeteer] 已滚动到底部');
{indent}      break;
{indent}    }}
{indent}  }}
{indent}}} else {{
{indent}  console.log('[Puppeteer] 未找到滚动容器，使用备用滚动方案');
{indent}  for (let i = 0; i < 20; i++) {{
{indent}    await page.evaluate(() => {{
{indent}      window.scrollTo(0, document.body.scrollHeight);
{indent}    }});
{indent}    await new Promise(resolve => setTimeout(resolve, 2000));
{indent}  }}
{indent}}}
'''
                content = content[:end_pos+1] + new_code + content[end_pos+1:]
                print(f"✅ 在位置 {end_pos} 插入滚动代码")
            else:
                print("⚠️  无法确定插入位置")
    else:
        print("⚠️  未找到合适的插入位置")

# 保存备份
with open('feishu-puppeteer.ts.bak_scroll_optimize', 'w', encoding='utf-8') as f:
    f.write(original)

# 保存修改后的文件
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ 滚动优化已应用")
PYEOF

echo ""
echo "=== 第三步：验证修改 ==="
grep -A 3 "查找真实滚动容器" feishu-puppeteer.ts | head -10

echo ""
echo "=== 第四步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 滚动优化已应用到爬虫！"
    echo ""
    echo "现在爬虫会："
    echo "1. 自动查找真实的滚动容器（如 bear-web-x-container）"
    echo "2. 在正确的容器上滚动"
    echo "3. 等待内容加载完成"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
    echo "如果构建失败，可以恢复："
    echo "  cd /www/wwwroot/feihub/backend/src/lib"
    echo "  cp feishu-puppeteer.ts.bak_scroll_optimize feishu-puppeteer.ts"
fi

