#!/bin/bash
# 检查文件并修复 AI速读

cd /www/wwwroot/feihub && python3 << 'PYEOF'
import re
import os

file_path = 'src/App.tsx'
file_size = os.path.getsize(file_path)
print(f"=== 检查文件状态 ===")
print(f"文件大小: {file_size / 1024 / 1024:.2f} MB")

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"总行数: {len(lines)}")

# 查找所有包含 AI速读 的行
ai_speed_lines = []
for i, line in enumerate(lines):
    if 'AI速读' in line:
        ai_speed_lines.append(i)
        # 显示前后代码
        if len(ai_speed_lines) == 1:  # 只显示第一个
            print(f"\n找到 AI速读 在第 {i+1} 行")
            for j in range(max(0, i-5), min(i+5, len(lines))):
                print(f"{j+1:4d}: {lines[j].rstrip()[:100]}")

print(f"\n总共找到 {len(ai_speed_lines)} 个 'AI速读'")

# 如果文件太大，可能是重复了，需要清理
if len(lines) > 10000:
    print("\n⚠️ 文件行数异常，可能被重复添加")
    print("建议从 Git 恢复或手动检查")

# 只修复第一个找到的 AI速读（应该是最早的那个）
if len(ai_speed_lines) > 0:
    i = ai_speed_lines[0]
    print(f"\n修复第 {i+1} 行的 AI速读")
    
    # 向上查找包含 absolute 的行
    for j in range(i, max(0, i-10), -1):
        if 'absolute' in lines[j] and ('right' in lines[j] or 'top' in lines[j]):
            print(f"找到定位行: 第 {j+1} 行")
            print(f"原始: {lines[j].rstrip()[:150]}")
            
            # 精确替换
            original = lines[j]
            
            # 替换定位
            lines[j] = lines[j].replace('-right-14 -top-4', 'right-1 top-1 md:-right-14 md:-top-4')
            # 如果上面没匹配到，尝试其他格式
            if '-right-14 -top-4' in original:
                lines[j] = original.replace('-right-14 -top-4', 'right-1 top-1 md:-right-14 md:-top-4')
            
            # 替换字体
            if 'text-xs' in lines[j] and 'md:text-xs' not in lines[j]:
                lines[j] = lines[j].replace('text-xs font-bold', 'text-[7px] md:text-xs font-bold')
                lines[j] = lines[j].replace(' text-xs ', ' text-[7px] md:text-xs ')
            
            # 替换间距
            if 'tracking-[0.5em]' in lines[j] and 'md:tracking' not in lines[j]:
                lines[j] = lines[j].replace('tracking-[0.5em]', 'tracking-[0.05em] md:tracking-[0.5em]')
            
            print(f"修改后: {lines[j].rstrip()[:150]}")
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

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ 修复完成！")
PYEOF
npm run build 2>&1 | tail -20 && echo "✅✅✅ 构建完成！"

