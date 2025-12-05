#!/usr/bin/env python3
"""
将本地 App.tsx 编码为 base64，方便传输到服务器
使用方法：
1. 在本地执行: python encode_app_tsx.py
2. 复制输出的 base64 字符串
3. 在服务器上执行 decode_app_tsx.sh（会自动创建）
"""

import base64
import os

def encode_file(file_path):
    """将文件编码为 base64"""
    if not os.path.exists(file_path):
        print(f"❌ 文件不存在: {file_path}")
        return None
    
    with open(file_path, 'rb') as f:
        content = f.read()
    
    encoded = base64.b64encode(content).decode('utf-8')
    return encoded

def main():
    app_tsx_path = 'src/App.tsx'
    highlight_path = 'src/utils/highlightKeyword.ts'
    
    print("=== 编码文件以便传输到服务器 ===\n")
    
    # 编码 App.tsx
    if os.path.exists(app_tsx_path):
        print(f"📄 正在编码: {app_tsx_path}")
        app_encoded = encode_file(app_tsx_path)
        if app_encoded:
            print(f"✅ App.tsx 编码完成，长度: {len(app_encoded)} 字符\n")
            
            # 创建服务器端解码脚本
            decode_script = f'''#!/bin/bash
cd /www/wwwroot/feihub

echo "=== 恢复 App.tsx ==="

# 解码并写入文件
echo "{app_encoded}" | base64 -d > src/App.tsx

if [ $? -eq 0 ]; then
    echo "✅ App.tsx 已恢复"
    echo "文件大小: $(wc -c < src/App.tsx) 字节"
    echo "文件行数: $(wc -l < src/App.tsx) 行"
    
    # 验证关键内容
    if grep -q "isScrolled" src/App.tsx; then
        echo "✅ 包含滚动折叠功能"
    fi
    
    if grep -q "right-1 top-1 md:-right-14" src/App.tsx; then
        echo "✅ 包含 AI速读 位置优化"
    fi
else
    echo "❌ 解码失败"
    exit 1
fi
'''
            
            with open('decode_app_tsx.sh', 'w', encoding='utf-8') as f:
                f.write(decode_script)
            
            print("✅ 已创建 decode_app_tsx.sh")
            print("\n📋 使用方法：")
            print("1. 将 decode_app_tsx.sh 上传到服务器")
            print("2. 在服务器上执行: bash decode_app_tsx.sh")
            print("   或者直接复制脚本内容到服务器执行")
    else:
        print(f"❌ 文件不存在: {app_tsx_path}")
    
    # 编码 highlightKeyword.ts
    if os.path.exists(highlight_path):
        print(f"\n📄 正在编码: {highlight_path}")
        highlight_encoded = encode_file(highlight_path)
        if highlight_encoded:
            print(f"✅ highlightKeyword.ts 编码完成，长度: {len(highlight_encoded)} 字符\n")
            
            # 创建服务器端解码脚本
            decode_highlight_script = f'''#!/bin/bash
cd /www/wwwroot/feihub

echo "=== 恢复 highlightKeyword.ts ==="

mkdir -p src/utils

# 解码并写入文件
echo "{highlight_encoded}" | base64 -d > src/utils/highlightKeyword.ts

if [ $? -eq 0 ]; then
    echo "✅ highlightKeyword.ts 已恢复"
else
    echo "❌ 解码失败"
    exit 1
fi
'''
            
            with open('decode_highlight.sh', 'w', encoding='utf-8') as f:
                f.write(decode_highlight_script)
            
            print("✅ 已创建 decode_highlight.sh")
    else:
        print(f"⚠️  文件不存在: {highlight_path}（可选）")
    
    print("\n✅✅✅ 完成！")

if __name__ == '__main__':
    main()

