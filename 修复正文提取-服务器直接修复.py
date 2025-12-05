#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复正文提取问题 - 服务器直接修复脚本
在服务器上执行：python3 修复正文提取-服务器直接修复.py
"""

import os
import re
import glob

def fix_file(file_path):
    """修复单个文件"""
    print(f"\n处理文件: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    modified = False
    
    # 修复1: 在提取文本后、返回前添加过滤
    # 查找模式：在循环中检查文本长度后返回的地方
    pattern1 = r'(if\s*\([^)]*text[^)]*length[^)]*>\s*\d+[^)]*\)\s*\{[^}]*return\s+[^;]+;)'
    
    def add_filter_before_return(match):
        return_stmt = match.group(1)
        # 在 return 前添加过滤检查
        return '''// 过滤导航栏和帮助中心内容
            if (text && (
                text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('Token Limit') ||
                text.includes('快捷键') ||
                text.trim().split(/\\s+/).length < 10 ||
                (!/[\\u4e00-\\u9fa5]/.test(text) && text.length < 200)
            )) {
              continue; // 跳过无效内容
            }
            ''' + return_stmt
    
    new_content = re.sub(pattern1, add_filter_before_return, content, flags=re.MULTILINE)
    if new_content != content:
        content = new_content
        modified = True
        print("  ✅ 已添加循环中的过滤逻辑")
    
    # 修复2: 在 bodyText 提取后添加清理
    if 'bodyText' in content:
        # 查找 bodyText = ... trim() 的模式
        pattern2 = r'(let\s+bodyText\s*=\s*\(body\.(?:innerText|textContent)[^;]+\.trim\(\);)'
        
        def add_body_cleanup(match):
            extract_line = match.group(1)
            return extract_line + '''
        
        // 移除导航栏和帮助中心文本
        bodyText = bodyText
            .replace(/Help Center[^\\n]*/gi, '')
            .replace(/Keyboard Shortcuts[^\\n]*/gi, '')
            .replace(/Token Limit[^\\n]*/gi, '')
            .replace(/快捷键[^\\n]*/gi, '')
            .replace(/\\s+/g, ' ')
            .trim();
        
        // 验证内容有效性：必须包含中文或足够长
        if (bodyText.length < 100 || (!/[\\u4e00-\\u9fa5]/.test(bodyText) && bodyText.length < 200)) {
            bodyText = '';
        }'''
        
        new_content = re.sub(pattern2, add_body_cleanup, content)
        if new_content != content:
            content = new_content
            modified = True
            print("  ✅ 已添加 bodyText 清理逻辑")
    
    # 修复3: 在返回 bodyText 前添加最终检查
    pattern3 = r'(return\s+bodyText;)'
    
    def add_final_check(match):
        return '''// 最终检查：确保不是导航栏内容
        if (bodyText && (
            bodyText.includes('Help Center') || 
            bodyText.includes('Keyboard Shortcuts') ||
            bodyText.includes('Token Limit')
        )) {
            bodyText = ''; // 清空无效内容
        }
        return bodyText;'''
    
    new_content = re.sub(pattern3, add_final_check, content)
    if new_content != content:
        content = new_content
        modified = True
        print("  ✅ 已添加返回前最终检查")
    
    # 修复4: 在文本提取后立即添加过滤（更早的位置）
    # 查找 const text = ... innerText/textContent 的模式
    pattern4 = r'(const\s+text\s*=\s*(?:cloned|element)\.(?:innerText|textContent)\s*\|\|\s*[^;]+;\s*)(?=\s*const\s+cleanText|if\s*\(cleanText)'
    
    def add_early_filter(match):
        extract_line = match.group(1)
        return extract_line + '''
            // 早期过滤：排除导航栏内容
            if (text && (
                text.includes('Help Center') || 
                text.includes('Keyboard Shortcuts') ||
                text.includes('Token Limit') ||
                text.includes('快捷键')
            )) {
              continue; // 跳过这个元素
            }
            '''
    
    new_content = re.sub(pattern4, add_early_filter, content, flags=re.MULTILINE)
    if new_content != content:
        content = new_content
        modified = True
        print("  ✅ 已添加早期过滤逻辑")
    
    if modified:
        # 备份
        backup_path = file_path + '.bak'
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(original)
        print(f"  📦 已备份到: {backup_path}")
        
        # 保存修改
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ 已修复: {file_path}")
        return True
    else:
        print(f"  ⚠️  未找到需要修改的代码模式")
        # 显示文件的关键部分，帮助诊断
        if 'querySelector' in original:
            print("  文件包含 querySelector，但未匹配到修复模式")
            print("  请检查文件内容提取的具体实现")
        return False

if __name__ == '__main__':
    # 切换到 lib 目录
    lib_dir = '/www/wwwroot/feihub/backend/src/lib'
    
    if not os.path.exists(lib_dir):
        print(f"❌ 找不到目录: {lib_dir}")
        print("请确保在服务器上运行此脚本")
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
        if fix_file(file_path):
            fixed_count += 1
    
    print(f"\n{'='*50}")
    print(f"修复完成！共修复 {fixed_count} 个文件")
    print(f"{'='*50}")
    
    if fixed_count > 0:
        print("\n下一步操作：")
        print("1. cd /www/wwwroot/feihub/backend")
        print("2. npm run build")
        print("3. pm2 restart feihub-backend")
        print("\n然后重新测试文档提取功能")

