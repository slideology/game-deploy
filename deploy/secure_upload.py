#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
安全的游戏文件上传工具

这个脚本用于安全地将游戏文件上传到Cloudflare R2对象存储。
它会从.env文件读取API密钥和其他配置信息。
"""

import os
import sys
import json
import subprocess
import time
from dotenv import load_dotenv

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
        print_warning("未设置CLOUDFLARE_ACCOUNT_ID环境变量，将使用默认值")
        account_id = None
    
    # 设置Cloudflare环境变量 - 这是关键修改
    os.environ['CLOUDFLARE_API_TOKEN'] = api_key
    if account_id:
        os.environ['CLOUDFLARE_ACCOUNT_ID'] = account_id
    
    return {
        'api_key': api_key,
        'account_id': account_id,
        'bucket_name': bucket_name
    }

def check_wrangler():
    """检查wrangler是否安装"""
    # 首先检查本地安装的wrangler
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    local_wrangler = os.path.join(project_dir, 'node_modules', '.bin', 'wrangler')
    
    if os.path.exists(local_wrangler):
        print_info("使用本地安装的wrangler")
        return local_wrangler
    
    # 然后检查全局安装的wrangler
    try:
        subprocess.run(['wrangler', '--version'], 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE, 
                      check=True)
        print_info("使用全局安装的wrangler")
        return 'wrangler'
    except (subprocess.SubprocessError, FileNotFoundError):
        print_error("未找到wrangler。请确保已安装: npm install wrangler --save-dev")
        return None

def login_wrangler(wrangler_path, api_key):
    """使用API密钥登录wrangler"""
    print_info("正在使用API密钥登录Cloudflare...")
    
    # 我们不再需要创建配置文件，因为我们使用环境变量
    print_success("API密钥已通过环境变量配置")
    return True

def upload_file(wrangler_path, file_path, destination, bucket_name):
    """上传文件到R2存储桶"""
    if not os.path.exists(file_path):
        print_error(f"文件不存在: {file_path}")
        return False
    
    print_info(f"上传文件: {os.path.basename(file_path)} -> {destination}")
    
    try:
        cmd = [wrangler_path, 'r2', 'object', 'put', 
               f"{bucket_name}/{destination}", 
               '--file', file_path]
        
        # 打印完整命令以便调试
        print_info(f"执行命令: {' '.join(cmd)}")
        
        result = subprocess.run(cmd, 
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.PIPE, 
                              text=True,
                              env=os.environ)  # 确保传递环境变量
        
        if result.returncode == 0:
            print_success(f"文件 {os.path.basename(file_path)} 上传成功!")
            return True
        else:
            print_error(f"上传失败: {result.stderr}")
            # 打印更多调试信息
            print_info("命令输出:")
            print(result.stdout)
            return False
            
    except Exception as e:
        print_error(f"上传过程中出错: {e}")
        return False

def main():
    """主函数"""
    print_info("游戏文件上传工具启动...")
    
    # 加载配置
    config = load_config()
    api_key = config['api_key']
    bucket_name = config['bucket_name']
    
    # 检查wrangler
    wrangler_path = check_wrangler()
    if not wrangler_path:
        print_error("未找到wrangler命令。请先安装: npm install wrangler --save-dev")
        print_info("安装命令: npm install wrangler --save-dev")
        sys.exit(1)
    
    # 登录wrangler
    if not login_wrangler(wrangler_path, api_key):
        print_error("登录Cloudflare失败")
        sys.exit(1)
    
    # 获取项目根目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    
    # 上传主文件
    main_file = os.path.join(project_dir, 'index.html')
    if not upload_file(wrangler_path, main_file, 'index.html', bucket_name):
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
                
                if upload_file(wrangler_path, file_path, rel_path, bucket_name):
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
