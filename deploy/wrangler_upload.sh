#!/bin/bash

# 颜色定义
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 读取环境变量
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/.env"

# 检查环境变量
if [ -z "$CLOUDFLARE_API_KEY" ]; then
    echo -e "${RED}[错误]${NC} 未设置CLOUDFLARE_API_KEY环境变量"
    exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo -e "${RED}[错误]${NC} 未设置CLOUDFLARE_ACCOUNT_ID环境变量"
    exit 1
fi

if [ -z "$CLOUDFLARE_BUCKET_NAME" ]; then
    echo -e "${YELLOW}[警告]${NC} 未设置CLOUDFLARE_BUCKET_NAME环境变量，使用默认值: game-assets"
    CLOUDFLARE_BUCKET_NAME="game-assets"
fi

# 设置Cloudflare环境变量
export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_KEY"
export CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID"

# 检查wrangler是否安装
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WRANGLER_PATH="$PROJECT_DIR/node_modules/.bin/wrangler"
if [ ! -f "$WRANGLER_PATH" ]; then
    echo -e "${YELLOW}[警告]${NC} 未找到本地wrangler，尝试使用全局wrangler"
    WRANGLER_PATH="$(which wrangler 2>/dev/null)"
    if [ -z "$WRANGLER_PATH" ]; then
        echo -e "${RED}[错误]${NC} 未找到wrangler，请先安装: npm install wrangler --save-dev"
        exit 1
    fi
fi

echo -e "${BLUE}[信息]${NC} 使用wrangler路径: $WRANGLER_PATH"

# 创建R2存储桶（如果不存在）
echo -e "${BLUE}[信息]${NC} 检查R2存储桶是否存在: $CLOUDFLARE_BUCKET_NAME"
"$WRANGLER_PATH" r2 bucket list | grep -q "$CLOUDFLARE_BUCKET_NAME"
if [ $? -ne 0 ]; then
    echo -e "${BLUE}[信息]${NC} 创建R2存储桶: $CLOUDFLARE_BUCKET_NAME"
    "$WRANGLER_PATH" r2 bucket create "$CLOUDFLARE_BUCKET_NAME"
    if [ $? -ne 0 ]; then
        echo -e "${RED}[错误]${NC} 创建R2存储桶失败"
        exit 1
    fi
fi

# 上传主文件
MAIN_FILE="$PROJECT_DIR/index.html"

if [ ! -f "$MAIN_FILE" ]; then
    echo -e "${RED}[错误]${NC} 主文件不存在: $MAIN_FILE"
    exit 1
fi

echo -e "${BLUE}[信息]${NC} 上传主文件: index.html"
"$WRANGLER_PATH" r2 object put "$CLOUDFLARE_BUCKET_NAME/index.html" --file "$MAIN_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}[错误]${NC} 上传主文件失败"
    exit 1
fi

# 上传资源文件
ASSETS_DIR="$PROJECT_DIR/assets"
if [ -d "$ASSETS_DIR" ]; then
    echo -e "${BLUE}[信息]${NC} 开始上传资源文件..."
    
    SUCCESS_COUNT=0
    FAIL_COUNT=0
    
    find "$ASSETS_DIR" -type f | while read -r FILE; do
        REL_PATH="${FILE#$PROJECT_DIR/}"
        echo -e "${BLUE}[信息]${NC} 上传文件: $REL_PATH"
        
        "$WRANGLER_PATH" r2 object put "$CLOUDFLARE_BUCKET_NAME/$REL_PATH" --file "$FILE"
        if [ $? -eq 0 ]; then
            ((SUCCESS_COUNT++))
            echo -e "${GREEN}[成功]${NC} 文件上传成功: $REL_PATH"
        else
            ((FAIL_COUNT++))
            echo -e "${RED}[错误]${NC} 文件上传失败: $REL_PATH"
        fi
    done
    
    echo -e "${BLUE}[信息]${NC} 资源文件上传完成: 成功 $SUCCESS_COUNT, 失败 $FAIL_COUNT"
else
    echo -e "${BLUE}[信息]${NC} 未找到资源目录，跳过资源上传"
fi

echo -e "${GREEN}[成功]${NC} 所有文件上传完成！"
echo -e "${BLUE}[信息]${NC} 下一步: 配置Cloudflare Pages以部署你的游戏"

# 创建公共URL
echo -e "${BLUE}[信息]${NC} 创建公共访问URL..."
"$WRANGLER_PATH" r2 bucket dev-url enable "$CLOUDFLARE_BUCKET_NAME"

# 显示访问URL
echo -e "${GREEN}[成功]${NC} 游戏已部署！"
echo -e "${BLUE}[信息]${NC} 访问URL: https://pub-${CLOUDFLARE_BUCKET_NAME}.r2.dev/index.html"
