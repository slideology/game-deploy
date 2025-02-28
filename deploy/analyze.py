#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
游戏文件分析工具

这个脚本用于分析HTML游戏文件，提取嵌入的资源，并生成优化建议。
"""

import os
import sys
import re
import json
import base64
from bs4 import BeautifulSoup
import hashlib
from urllib.parse import urljoin
import mimetypes

# 颜色定义
class Colors:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_info(message):
    """打印信息"""
    print(f"{Colors.BLUE}[信息]{Colors.ENDC} {message}")

def print_success(message):
    """打印成功信息"""
    print(f"{Colors.GREEN}[成功]{Colors.ENDC} {message}")

def print_warning(message):
    """打印警告信息"""
    print(f"{Colors.YELLOW}[警告]{Colors.ENDC} {message}")

def print_error(message):
    """打印错误信息"""
    print(f"{Colors.RED}[错误]{Colors.ENDC} {message}")

def get_file_size(file_path):
    """获取文件大小并格式化"""
    size_bytes = os.path.getsize(file_path)
    
    # 转换为人类可读格式
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0 or unit == 'GB':
            break
        size_bytes /= 1024.0
    
    return f"{size_bytes:.2f} {unit}"

def extract_base64_resources(html_content, output_dir):
    """提取Base64编码的资源"""
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # 查找所有可能包含base64数据的标签
    img_tags = soup.find_all('img')
    style_tags = soup.find_all('style')
    script_tags = soup.find_all('script')
    
    resources = []
    total_size = 0
    
    # 处理img标签
    for img in img_tags:
        if img.get('src') and 'base64,' in img['src']:
            try:
                # 提取MIME类型和base64数据
                mime_type = img['src'].split('data:')[1].split(';base64,')[0]
                base64_data = img['src'].split(';base64,')[1]
                
                # 生成文件名
                ext = mimetypes.guess_extension(mime_type) or '.bin'
                file_hash = hashlib.md5(base64_data.encode()).hexdigest()[:8]
                filename = f"img_{file_hash}{ext}"
                
                # 保存文件
                file_path = os.path.join(output_dir, filename)
                with open(file_path, 'wb') as f:
                    f.write(base64.b64decode(base64_data))
                
                # 计算大小
                size = os.path.getsize(file_path)
                total_size += size
                
                resources.append({
                    'type': 'image',
                    'mime': mime_type,
                    'filename': filename,
                    'size': size,
                    'original_tag': 'img'
                })
                
            except Exception as e:
                print_error(f"处理图片资源时出错: {e}")
    
    # 处理样式中的base64
    for style in style_tags:
        if style.string:
            # 查找所有url(data:...base64,...)模式
            pattern = r'url\([\'\"]?data:([^;]+);base64,([^\'\"\)]+)'
            matches = re.findall(pattern, style.string)
            
            for mime_type, base64_data in matches:
                try:
                    # 生成文件名
                    ext = mimetypes.guess_extension(mime_type) or '.bin'
                    file_hash = hashlib.md5(base64_data.encode()).hexdigest()[:8]
                    filename = f"style_{file_hash}{ext}"
                    
                    # 保存文件
                    file_path = os.path.join(output_dir, filename)
                    with open(file_path, 'wb') as f:
                        f.write(base64.b64decode(base64_data))
                    
                    # 计算大小
                    size = os.path.getsize(file_path)
                    total_size += size
                    
                    resources.append({
                        'type': 'style-resource',
                        'mime': mime_type,
                        'filename': filename,
                        'size': size,
                        'original_tag': 'style'
                    })
                    
                except Exception as e:
                    print_error(f"处理样式资源时出错: {e}")
    
    return resources, total_size

def analyze_html_file(file_path):
    """分析HTML游戏文件"""
    if not os.path.exists(file_path):
        print_error(f"文件不存在: {file_path}")
        return
    
    print_info(f"开始分析文件: {file_path}")
    print_info(f"文件大小: {get_file_size(file_path)}")
    
    # 创建资源输出目录
    parent_dir = os.path.dirname(file_path)
    assets_dir = os.path.join(parent_dir, "assets")
    os.makedirs(assets_dir, exist_ok=True)
    
    # 读取HTML内容
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        html_content = f.read()
    
    # 解析HTML
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # 提取标题
    title = soup.title.string if soup.title else "未知游戏"
    print_info(f"游戏标题: {title}")
    
    # 统计脚本数量
    scripts = soup.find_all('script')
    print_info(f"脚本数量: {len(scripts)}")
    
    # 统计样式数量
    styles = soup.find_all('style')
    print_info(f"样式数量: {len(styles)}")
    
    # 提取base64资源
    print_info("提取Base64编码的资源...")
    resources, total_size = extract_base64_resources(html_content, assets_dir)
    print_success(f"共提取了 {len(resources)} 个资源，总大小: {total_size/1024/1024:.2f} MB")
    
    # 生成报告
    report = {
        'file_name': os.path.basename(file_path),
        'file_size': get_file_size(file_path),
        'title': title,
        'scripts_count': len(scripts),
        'styles_count': len(styles),
        'resources': resources,
        'resources_count': len(resources),
        'resources_size': f"{total_size/1024/1024:.2f} MB",
        'analysis_time': import_time.strftime("%Y-%m-%d %H:%M:%S")
    }
    
    # 保存报告
    report_path = os.path.join(parent_dir, "analysis_report.json")
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print_success(f"分析报告已保存到: {report_path}")
    
    # 提供优化建议
    print_info("\n优化建议:")
    
    if total_size > 10 * 1024 * 1024:  # 如果资源总大小超过10MB
        print_warning("- 资源总大小较大，建议将大型资源分离存储在对象存储中")
        print_warning("- 考虑使用延迟加载策略，先加载核心游戏逻辑，再加载资源")
    
    if len(scripts) > 5:
        print_warning("- 脚本数量较多，建议合并脚本以减少HTTP请求")
    
    if len(styles) > 3:
        print_warning("- 样式数量较多，建议合并样式表以提高加载速度")
    
    print_success("- 使用Cloudflare的自动压缩功能可以减少传输大小")
    print_success("- 配置适当的缓存策略可以提高重复访问的速度")
    print_success("- 启用HTTP/3和0-RTT可以进一步提升性能")
    
    return report

if __name__ == "__main__":
    import time as import_time
    
    if len(sys.argv) < 2:
        print_error("使用方法: python analyze.py <HTML游戏文件路径>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    analyze_html_file(file_path)
