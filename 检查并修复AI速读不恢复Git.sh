#!/bin/bash
# 检查文件并修复 AI速读（不从 Git 恢复）

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re

file_path = 'src/App.tsx'

print("=== 检查文件并修复 AI速读 ===")

# 读取文件，只读取前2000行（正常文件应该在这个范围内）
with open(file_path, 'r', encoding='utf-8') as f:
    lines = []
    for i, line in enumerate(f):
        if i >= 2000:  # 只读取前2000行
            break
        lines.append(line)

print(f"读取了前 {len(lines)} 行")

# 查找 AI速读
ai_speed_idx = -1
for i, line in enumerate(lines):
    if 'AI速读' in line:
        ai_speed_idx = i
        print(f"\n找到 AI速读 在第 {i+1} 行")
        # 显示前后代码
        for j in range(max(0, i-3), min(i+3, len(lines))):
            print(f"{j+1:4d}: {lines[j].rstrip()[:100]}")
        break

if ai_speed_idx >= 0:
    # 向上查找包含 absolute 的行
    for j in range(ai_speed_idx, max(0, ai_speed_idx-10), -1):
        if 'absolute' in lines[j] and ('right' in lines[j] or 'top' in lines[j]):
            print(f"\n找到定位行: 第 {j+1} 行")
            print(f"原始: {lines[j].rstrip()[:150]}")
            
            # 保存原始行
            original_line = lines[j]
            
            # 精确替换
            # 1. 替换定位
            if '-right-14 -top-4' in lines[j]:
                lines[j] = lines[j].replace('-right-14 -top-4', 'right-1 top-1 md:-right-14 md:-top-4')
            elif '-right-14' in lines[j] and '-top-4' in lines[j]:
                lines[j] = lines[j].replace('-right-14', 'right-1 md:-right-14')
                lines[j] = lines[j].replace('-top-4', 'top-1 md:-top-4')
            
            # 2. 替换字体
            if 'text-xs' in lines[j] and 'md:text-xs' not in lines[j]:
                lines[j] = lines[j].replace('text-xs font-bold', 'text-[7px] md:text-xs font-bold')
                lines[j] = lines[j].replace(' text-xs ', ' text-[7px] md:text-xs ')
            
            # 3. 替换间距
            if 'tracking-[0.5em]' in lines[j] and 'md:tracking' not in lines[j]:
                lines[j] = lines[j].replace('tracking-[0.5em]', 'tracking-[0.05em] md:tracking-[0.5em]')
            
            print(f"修改后: {lines[j].rstrip()[:150]}")
            
            # 如果修改了，需要写回文件
            if lines[j] != original_line:
                # 读取完整文件
                with open(file_path, 'r', encoding='utf-8') as f:
                    all_lines = f.readlines()
                
                # 只修改对应的行
                if j < len(all_lines):
                    all_lines[j] = lines[j]
                    
                    # 写回文件
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.writelines(all_lines)
                    
                    print(f"\n✅ 已修复第 {j+1} 行")
            break
    
    # 验证
    content = ''.join(lines)
    print("\n=== 验证 ===")
    if 'right-1 top-1 md:-right-14' in content:
        print("✅ AI速读 位置已修复")
    else:
        print("❌ AI速读 位置未修复")
    
    if 'text-[7px] md:text-xs' in content:
        print("✅ 移动端字体已调整")
    else:
        print("❌ 移动端字体未调整")
else:
    print("\n❌ 未找到 AI速读")

print("\n✅ 处理完成！")
PYEOF
npm run build 2>&1 | tail -20 && echo "✅✅✅ 构建完成！"

