#!/bin/bash

# Sprunki游戏自动上传脚本
# 这个脚本用于上传两个游戏到R2存储桶，并自动部署Worker

# 设置颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 打印带颜色的消息
print_green() {
  echo -e "${GREEN}$1${NC}"
}

print_blue() {
  echo -e "${BLUE}$1${NC}"
}

print_red() {
  echo -e "${RED}$1${NC}"
}

# 设置变量
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WRANGLER_PATH="$PROJECT_ROOT/node_modules/.bin/wrangler"
BUCKET_NAME="game-assets"
TEMP_DIR="$PROJECT_ROOT/temp"

# 游戏文件路径
SPRUNKI_RETAKE_PATH="/Users/dahuang/Downloads/sprunki游戏/Sprunki Retake New Human With New Bonus (Not Mine 18+).html"
SQUIDKI_ORIGINAL_PATH="/Users/dahuang/Downloads/sprunki游戏/Squidki original (reuploaded).html"
ERROR_PAGE_PATH="$PROJECT_ROOT/404.html"

# 目标前缀
SPRUNKI_RETAKE_PREFIX="sprunki-retake-new-human"
SQUIDKI_PREFIX="sprunki-squidki"

# 检查wrangler是否存在
if [ ! -f "$WRANGLER_PATH" ]; then
  print_red "[错误] Wrangler未安装，正在尝试安装..."
  cd "$PROJECT_ROOT"
  npm install wrangler
  if [ ! -f "$WRANGLER_PATH" ]; then
    print_red "[错误] Wrangler安装失败，请手动运行 'npm install wrangler'"
    exit 1
  fi
  print_green "[成功] Wrangler已安装"
fi

# 检查环境变量
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
fi

if [ -z "$CLOUDFLARE_API_KEY" ]; then
  print_red "[错误] 未设置CLOUDFLARE_API_KEY环境变量"
  exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
  print_red "[错误] 未设置CLOUDFLARE_ACCOUNT_ID环境变量"
  exit 1
fi

if [ -n "$CLOUDFLARE_BUCKET_NAME" ]; then
  BUCKET_NAME="$CLOUDFLARE_BUCKET_NAME"
fi

# 设置环境变量
export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_KEY"

# 显示信息
print_blue "[信息] 使用wrangler路径: $WRANGLER_PATH"
print_blue "[信息] 使用R2存储桶: $BUCKET_NAME"
print_blue "[信息] 开始处理游戏文件..."

# 创建临时目录
mkdir -p "$TEMP_DIR/$SPRUNKI_RETAKE_PREFIX"
mkdir -p "$TEMP_DIR/$SQUIDKI_PREFIX"

# 上传404页面
print_blue "[信息] 上传404页面..."
if [ -f "$ERROR_PAGE_PATH" ]; then
  "$WRANGLER_PATH" r2 object put "$BUCKET_NAME/404.html" --file "$ERROR_PAGE_PATH" --content-type "text/html;charset=UTF-8"
  
  if [ $? -eq 0 ]; then
    print_green "[成功] 404页面上传成功"
  else
    print_red "[错误] 404页面上传失败"
  fi
else
  print_red "[错误] 找不到404页面: $ERROR_PAGE_PATH"
fi

# 处理Sprunki Retake游戏
print_blue "[信息] 处理Sprunki Retake游戏..."
if [ -f "$SPRUNKI_RETAKE_PATH" ]; then
  # 复制HTML文件
  cp "$SPRUNKI_RETAKE_PATH" "$TEMP_DIR/$SPRUNKI_RETAKE_PREFIX/index.html"
  
  # 上传HTML文件
  print_blue "[信息] 上传Sprunki Retake游戏HTML文件..."
  "$WRANGLER_PATH" r2 object put "$BUCKET_NAME/$SPRUNKI_RETAKE_PREFIX/index.html" --file "$TEMP_DIR/$SPRUNKI_RETAKE_PREFIX/index.html" --content-type "text/html;charset=UTF-8"
  
  if [ $? -eq 0 ]; then
    print_green "[成功] Sprunki Retake游戏HTML文件上传成功"
  else
    print_red "[错误] Sprunki Retake游戏HTML文件上传失败"
  fi
else
  print_red "[错误] 找不到Sprunki Retake游戏文件: $SPRUNKI_RETAKE_PATH"
fi

# 处理Squidki Original游戏
print_blue "[信息] 处理Squidki Original游戏..."
if [ -f "$SQUIDKI_ORIGINAL_PATH" ]; then
  # 复制HTML文件
  cp "$SQUIDKI_ORIGINAL_PATH" "$TEMP_DIR/$SQUIDKI_PREFIX/index.html"
  
  # 上传HTML文件
  print_blue "[信息] 上传Squidki Original游戏HTML文件..."
  "$WRANGLER_PATH" r2 object put "$BUCKET_NAME/$SQUIDKI_PREFIX/index.html" --file "$TEMP_DIR/$SQUIDKI_PREFIX/index.html" --content-type "text/html;charset=UTF-8"
  
  if [ $? -eq 0 ]; then
    print_green "[成功] Squidki Original游戏HTML文件上传成功"
  else
    print_red "[错误] Squidki Original游戏HTML文件上传失败"
  fi
else
  print_red "[错误] 找不到Squidki Original游戏文件: $SQUIDKI_ORIGINAL_PATH"
fi

# 清理临时文件
print_blue "[信息] 清理临时文件..."
rm -rf "$TEMP_DIR"

# 自动部署Worker
print_blue "[信息] 自动部署Worker..."
cd "$PROJECT_ROOT"
./deploy/deploy_worker.sh

# 显示结果
print_green "======================================"
print_green "  上传和部署完成"
print_green "======================================"
print_blue "游戏现在可以通过以下URL访问:"
print_blue "1. Sprunki Retake: https://game.sprunkr.online/sprunki-retake-new-human/"
print_blue "2. Squidki Original: https://game.sprunkr.online/sprunki-squidki/"
print_blue ""
print_blue "注意: 根路径 https://game.sprunkr.online/ 将返回404页面"
print_blue ""
print_blue "如果游戏无法访问，请确保:"
print_blue "1. Worker已成功部署"
print_blue "2. DNS记录已正确设置"
print_blue "3. API令牌具有足够的权限"
