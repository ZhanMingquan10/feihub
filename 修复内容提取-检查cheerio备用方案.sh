#!/bin/bash

# 修复内容提取 - 检查 cheerio 备用方案

cd /www/wwwroot/feihub/backend/src/lib

echo "=== 第一步：查看 cheerio 备用方案的代码 ==="
grep -n "cheerio 备用方案\|使用 cheerio" feishu-puppeteer.ts | head -5

echo ""
echo "=== 第二步：查看 cheerio 提取的完整逻辑 ==="
grep -A 50 "cheerio 备用方案" feishu-puppeteer.ts | head -60

echo ""
echo "=== 第三步：查看 page.evaluate 提取的完整逻辑 ==="
grep -B 5 -A 100 "从页面直接提取内容" feishu-puppeteer.ts | head -120

echo ""
echo "=== 第四步：修复 cheerio 备用方案 ==="

python3 << 'PYEOF'
with open('feishu-puppeteer.ts', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找 cheerio 备用方案的代码
cheerio_start = None
for i, line in enumerate(lines):
    if 'cheerio 备用方案' in line or '使用 cheerio 备用方案' in line:
        cheerio_start = i
        print(f"找到 cheerio 备用方案在第 {i+1} 行")
        break

if cheerio_start:
    # 查找 cheerio 提取内容的部分
    for i in range(cheerio_start, min(cheerio_start + 100, len(lines))):
        if 'content =' in lines[i] and 'cheerio' in '\n'.join(lines[max(0, i-5):i+1]).lower():
            # 在 cheerio 提取后添加过滤
            indent = len(lines[i]) - len(lines[i].lstrip())
            indent_str = ' ' * indent
            
            # 查找下一个非空行
            j = i + 1
            while j < len(lines) and (not lines[j].strip() or lines[j].strip().startswith('//')):
                j += 1
            
            # 检查是否已经有过滤
            has_filter = False
            for k in range(i+1, min(i+20, len(lines))):
                if 'Help Center' in lines[k]:
                    has_filter = True
                    break
            
            if not has_filter:
                # 插入过滤代码
                lines.insert(j, f"{indent_str}\n")
                lines.insert(j+1, f"{indent_str}// 过滤导航栏内容\n")
                lines.insert(j+2, f"{indent_str}if (content && (content.includes('Help Center') || content.includes('Keyboard Shortcuts') || content.includes('Token Limit'))) {{\n")
                lines.insert(j+3, f"{indent_str}  content = ''; // 清空无效内容\n")
                lines.insert(j+4, f"{indent_str}}}\n")
                print(f"✅ 在第 {i+1} 行后添加 cheerio 过滤（插入到第 {j+1} 行）")
            break

# 同时改进 page.evaluate 的选择器，优先选择包含中文的区域
# 查找 selectors 数组
for i, line in enumerate(lines):
    if 'const selectors = [' in line:
        # 查看选择器数组
        print(f"找到选择器数组在第 {i+1} 行")
        # 可以在这里改进选择器，但先看看 cheerio 的修复是否足够
        break

with open('feishu-puppeteer.ts.bak15', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
with open('feishu-puppeteer.ts', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ 修复完成")
PYEOF

echo ""
echo "=== 第五步：重新构建 ==="
cd /www/wwwroot/feihub/backend
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 构建成功！"
    echo ""
    echo "=== 重启服务 ==="
    pm2 restart feihub-backend
    echo ""
    echo "✅✅✅ 修复完成！"
else
    echo ""
    echo "❌ 构建失败，请检查错误信息"
fi

