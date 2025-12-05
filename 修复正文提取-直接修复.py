#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复正文提取问题 - 直接修复脚本
在服务器上执行：python3 修复正文提取-直接修复.py
"""

import os
import re
import glob

def fix_content_extraction(file_path):
    """修复文件中的内容提取逻辑"""
    print(f"\n处理文件: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    modified = False
    
    # 修复1: 在提取文本后添加过滤
    # 查找模式：const text = ... innerText/textContent ...
    pattern1 = r'(const\s+(?:text|bodyText|cleanText)\s*=\s*(?:cloned|element|body)\.(?:innerText|textContent)\s*\|\|\s*[^;]+;)'
    
    def add_filter_after_extract(match):
        extract_line = match.group(1)
        return extract_line + '''
            
            // 过滤导航栏和帮助中心内容
            if (text && (
                text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('Token Limit') ||
                text.includes('快捷键') ||
                text.trim().split(/\\s+/).length < 10 ||
                (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)
            )) {
              continue; // 跳过这个元素
            }'''
    
    new_content = re.sub(pattern1, add_filter_after_extract, content)
    if new_content != content:
        content = new_content
        modified = True
        print("  ✅ 已添加文本过滤逻辑")
    
    # 修复2: 在返回前添加最终过滤
    # 查找 return text.trim() 或类似模式
    pattern2 = r'(return\s+(?:text|bodyText|cleanText|content)\.trim\(\);)'
    
    def add_final_filter(match):
        return_stmt = match.group(1)
        var_name = re.search(r'return\s+(\w+)', return_stmt).group(1) if re.search(r'return\s+(\w+)', return_stmt) else 'text'
        return f'''// 最终过滤：排除导航栏内容
            let finalText = {var_name}.trim();
            if (finalText && (
                finalText.includes('Help Center') || 
                finalText.includes('Keyboard Shortcuts') ||
                finalText.includes('Token Limit') ||
                finalText.includes('快捷键') ||
                (!/[\\u4e00-\\u9fa5]/.test(finalText) && finalText.length < 200)
            )) {
              finalText = ''; // 清空无效内容
            }
            return finalText;'''
    
    new_content = re.sub(pattern2, add_final_filter, content)
    if new_content != content:
        content = new_content
        modified = True
        print("  ✅ 已添加返回前过滤")
    
    # 修复3: 在 body 提取时添加文本清理
    pattern3 = r'(let\s+bodyText\s*=\s*\(body\.(?:innerText|textContent)[^;]+;)'
    
    def add_body_filter(match):
        body_extract = match.group(1)
        return body_extract + '''
        
        // 移除常见的导航文本
        bodyText = bodyText
            .replace(/Help Center[^\\n]*/gi, '')
            .replace(/Keyboard Shortcuts[^\\n]*/gi, '')
            .replace(/Token Limit[^\\n]*/gi, '')
            .replace(/快捷键[^\\n]*/gi, '')
            .replace(/\\s+/g, ' ')
            .trim();
        
        // 如果过滤后内容无效，返回空
        if (bodyText.length < 100 || (!/[\\u4e00-\\u9fa5]/.test(bodyText) && bodyText.length < 200)) {
            bodyText = '';
        }'''
    
    new_content = re.sub(pattern3, add_body_filter, content)
    if new_content != content:
        content = new_content
        modified = True
        print("  ✅ 已添加 body 文本过滤")
    
    if modified:
        # 备份原文件
        backup_path = file_path + '.bak'
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original_content)
        print(f"  📦 已备份到: {backup_path}")
        
        # 写入修改后的内容
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ 已修改: {file_path}")
        return True
    else:
        print(f"  ⚠️  未找到需要修改的代码模式")
        return False

if __name__ == '__main__':
    # 切换到脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(script_dir, 'backend', 'src', 'lib')
    
    if not os.path.exists(lib_dir):
        # 如果在项目根目录运行
        lib_dir = os.path.join(script_dir, 'src', 'lib')
    
    if not os.path.exists(lib_dir):
        print("❌ 找不到 lib 目录，请确保在项目根目录运行此脚本")
        exit(1)
    
    os.chdir(lib_dir)
    print(f"工作目录: {os.getcwd()}")
    
    # 查找所有 feishu*.ts 文件
    files = glob.glob('feishu*.ts')
    
    if not files:
        print("❌ 未找到 feishu*.ts 文件")
        exit(1)
    
    print(f"找到 {len(files)} 个文件:")
    for f in files:
        print(f"  - {f}")
    
    # 修复每个文件
    fixed_count = 0
    for file_path in files:
        if fix_content_extraction(file_path):
            fixed_count += 1
    
    print(f"\n=== 修复完成 ===")
    print(f"共修复 {fixed_count} 个文件")
    
    if fixed_count > 0:
        print("\n下一步：")
        print("1. cd /www/wwwroot/feihub/backend")
        print("2. npm run build")
        print("3. pm2 restart feihub-backend")

