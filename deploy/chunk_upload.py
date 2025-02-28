#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
大文件分块上传工具

这个脚本用于将大文件分块上传到Cloudflare R2对象存储。
它会从.env文件读取API密钥和其他配置信息。
"""

import os
import sys
import json
import requests
import hashlib
import time
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm

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

def load_config():
    """加载配置信息"""
    # 加载.env文件
    env_path = os.path.join(os.path.dirname(__file__), '.env')
    if not os.path.exists(env_path):
        print_error(f".env文件不存在: {env_path}")
        print_info("请创建.env文件并设置以下变量:")
        print_info("CLOUDFLARE_API_KEY=你的API密钥")
        print_info("CLOUDFLARE_ACCOUNT_ID=你的账户ID")
        print_info("CLOUDFLARE_BUCKET_NAME=你的存储桶名称")
        sys.exit(1)
    
    load_dotenv(env_path)
    
    # 获取必要的环境变量
    api_key = os.getenv('CLOUDFLARE_API_KEY')
    account_id = os.getenv('CLOUDFLARE_ACCOUNT_ID')
    bucket_name = os.getenv('CLOUDFLARE_BUCKET_NAME', 'game-assets')
    
    if not api_key:
        print_error("未设置CLOUDFLARE_API_KEY环境变量")
        sys.exit(1)
    
    if not account_id or account_id == "你的账户ID":
        print_error("未设置CLOUDFLARE_ACCOUNT_ID环境变量，这是必需的")
        print_info("请在.env文件中设置CLOUDFLARE_ACCOUNT_ID")
        sys.exit(1)
    
    return {
        'api_key': api_key,
        'account_id': account_id,
        'bucket_name': bucket_name
    }

def get_content_type(file_path):
    """根据文件扩展名获取内容类型"""
    ext = os.path.splitext(file_path)[1].lower()
    content_types = {
        '.html': 'text/html',
        '.htm': 'text/html',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon',
        '.txt': 'text/plain',
        '.pdf': 'application/pdf',
        '.zip': 'application/zip',
        '.mp3': 'audio/mpeg',
        '.mp4': 'video/mp4',
        '.webm': 'video/webm',
        '.woff': 'font/woff',
        '.woff2': 'font/woff2',
        '.ttf': 'font/ttf',
        '.otf': 'font/otf',
        '.eot': 'application/vnd.ms-fontobject'
    }
    return content_types.get(ext, 'application/octet-stream')

def create_direct_upload_url(config, file_name, content_type):
    """创建直接上传URL"""
    api_key = config['api_key']
    account_id = config['account_id']
    bucket_name = config['bucket_name']
    
    url = f"https://api.cloudflare.com/client/v4/accounts/{account_id}/r2/buckets/{bucket_name}/direct_upload"
    
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    data = {
        'name': file_name,
        'metadata': {},
        'contentType': content_type
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        return response.json()['result']
    else:
        print_error(f"创建上传URL失败: {response.text}")
        return None

def upload_file_direct(config, file_path, destination):
    """直接上传文件到R2存储桶"""
    if not os.path.exists(file_path):
        print_error(f"文件不存在: {file_path}")
        return False
    
    print_info(f"上传文件: {os.path.basename(file_path)} -> {destination}")
    
    # 获取文件大小
    file_size = os.path.getsize(file_path)
    print_info(f"文件大小: {file_size / 1024 / 1024:.2f} MB")
    
    # 获取内容类型
    content_type = get_content_type(file_path)
    
    # 创建直接上传URL
    upload_info = create_direct_upload_url(config, destination, content_type)
    if not upload_info:
        return False
    
    # 上传文件
    upload_url = upload_info['uploadURL']
    
    try:
        with open(file_path, 'rb') as f:
            file_data = f.read()
            
            headers = {
                'Content-Type': content_type
            }
            
            response = requests.put(upload_url, headers=headers, data=file_data)
            
            if response.status_code == 200:
                print_success(f"文件 {os.path.basename(file_path)} 上传成功!")
                return True
            else:
                print_error(f"上传失败: {response.text}")
                return False
                
    except Exception as e:
        print_error(f"上传过程中出错: {e}")
        return False

def main():
    """主函数"""
    print_info("大文件上传工具启动...")
    
    # 加载配置
    config = load_config()
    
    # 获取项目根目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    
    # 上传主文件
    main_file = os.path.join(project_dir, 'index.html')
    if not upload_file_direct(config, main_file, 'index.html'):
        print_error("主文件上传失败，终止上传过程")
        sys.exit(1)
    
    # 上传资源文件
    assets_dir = os.path.join(project_dir, 'assets')
    if os.path.exists(assets_dir) and os.path.isdir(assets_dir):
        print_info("开始上传资源文件...")
        
        success_count = 0
        fail_count = 0
        
        for root, _, files in os.walk(assets_dir):
            for file in files:
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, project_dir)
                
                if upload_file_direct(config, file_path, rel_path):
                    success_count += 1
                else:
                    fail_count += 1
        
        print_info(f"资源文件上传完成: 成功 {success_count}, 失败 {fail_count}")
    else:
        print_info("未找到资源目录，跳过资源上传")
    
    print_success("所有文件上传完成！")
    print_info("下一步: 配置Cloudflare Pages以部署你的游戏")

if __name__ == "__main__":
    main()
