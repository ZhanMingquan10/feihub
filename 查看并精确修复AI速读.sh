#!/bin/bash
# 查看并精确修复 AI速读

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

with open('src/App.tsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print("=== 查看并精确修复 AI速读 ===")

# 查找 AI速读 的实际代码
for i, line in enumerate(lines):
    if 'AI速读' in line:
        print(f"\n找到 AI速读 在第 {i+1} 行")
        # 显示前后代码
        for j in range(max(0, i-3), min(i+3, len(lines))):
            print(f"{j+1:4d}: {lines[j].rstrip()}")
        
        # 向上查找包含 absolute 的行
        for j in range(i, max(0, i-5), -1):
            if 'absolute' in lines[j] and 'right' in lines[j]:
                print(f"\n找到定位行: 第 {j+1} 行")
                print(f"原始代码: {lines[j].rstrip()}")
                
                # 精确替换
                # 将 -right-14 -top-4 改为 right-1 top-1 md:-right-14 md:-top-4
                lines[j] = lines[j].replace('-right-14 -top-4', 'right-1 top-1 md:-right-14 md:-top-4')
                
                # 将 text-xs 改为 text-[7px] md:text-xs
                if 'text-xs' in lines[j] and 'md:text-xs' not in lines[j]:
                    lines[j] = lines[j].replace(' text-xs ', ' text-[7px] md:text-xs ')
                    lines[j] = lines[j].replace('text-xs font-bold', 'text-[7px] md:text-xs font-bold')
                
                # 将 tracking-[0.5em] 改为 tracking-[0.05em] md:tracking-[0.5em]
                if 'tracking-[0.5em]' in lines[j] and 'md:tracking' not in lines[j]:
                    lines[j] = lines[j].replace('tracking-[0.5em]', 'tracking-[0.05em] md:tracking-[0.5em]')
                
                print(f"修改后: {lines[j].rstrip()}")
                break
        break

content = '\n'.join(lines)

# 验证
print("\n=== 验证 ===")
if 'right-1 top-1 md:-right-14' in content:
    print("✅ AI速读 位置已修复")
else:
    print("❌ AI速读 位置未修复")

if 'text-[7px] md:text-xs' in content:
    print("✅ 移动端字体已调整")
else:
    print("❌ 移动端字体未调整")
    # 显示实际代码
    idx = content.find('AI速读')
    if idx > 0:
        print(f"\nAI速读附近代码:\n{content[max(0, idx-300):idx+100]}")

with open('src/App.tsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 修复完成！")
PYEOF
npm run build && echo "✅✅✅ 构建完成！"

