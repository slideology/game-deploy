#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 检查wrangler是否安装
if ! command -v wrangler &> /dev/null; then
    print_error "未找到wrangler命令。请先安装: npm install -g wrangler"
    exit 1
fi

# 检查是否登录
print_info "检查Cloudflare登录状态..."
if ! wrangler whoami &> /dev/null; then
    print_error "你尚未登录Cloudflare。请先运行: wrangler login"
    exit 1
fi

# 上传主文件
print_info "开始上传游戏主文件..."
wrangler r2 object put game-assets/index.html --file ../index.html

if [ $? -eq 0 ]; then
    print_success "主文件上传成功！"
else
    print_error "主文件上传失败！"
    exit 1
fi

# 上传其他资源文件（如果存在）
if [ -d "../assets" ] && [ "$(ls -A ../assets)" ]; then
    print_info "开始上传资源文件..."
    
    for file in ../assets/*; do
        filename=$(basename "$file")
        print_info "上传: $filename"
        wrangler r2 object put "game-assets/assets/$filename" --file "$file"
        
        if [ $? -eq 0 ]; then
            print_success "文件 $filename 上传成功！"
        else
            print_error "文件 $filename 上传失败！"
        fi
    done
else
    print_info "没有找到资源文件，跳过资源上传。"
fi

print_success "所有文件上传完成！"
print_info "下一步: 配置Cloudflare Pages以部署你的游戏。"
