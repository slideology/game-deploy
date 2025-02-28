#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${BLUE}[信息]${NC} 加载环境变量..."
    source "$SCRIPT_DIR/.env"
    
    # 兼容性处理：如果存在CLOUDFLARE_API_KEY但不存在CLOUDFLARE_API_TOKEN，则使用CLOUDFLARE_API_KEY
    if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -n "$CLOUDFLARE_API_KEY" ]; then
        CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_KEY
        echo -e "${BLUE}[信息]${NC} 使用CLOUDFLARE_API_KEY作为API令牌"
    fi
else
    echo -e "${RED}[错误]${NC} .env文件不存在。请创建$SCRIPT_DIR/.env文件并设置必要的环境变量。"
    exit 1
fi

# 检查必要的环境变量
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    echo -e "${RED}[错误]${NC} 缺少必要的环境变量。请确保在.env文件中设置了CLOUDFLARE_API_TOKEN和CLOUDFLARE_ACCOUNT_ID。"
    exit 1
fi

# 设置默认值
BUCKET_NAME=${CLOUDFLARE_BUCKET_NAME:-"game-assets"}
WRANGLER_PATH="./node_modules/.bin/wrangler"

# 检查wrangler是否存在
if [ ! -f "$WRANGLER_PATH" ]; then
    echo -e "${YELLOW}[警告]${NC} wrangler未找到，尝试安装..."
    cd "$PROJECT_ROOT" && npm install wrangler
    if [ $? -ne 0 ]; then
        echo -e "${RED}[错误]${NC} 安装wrangler失败。请手动安装: npm install wrangler"
        exit 1
    fi
fi

# 上传文件函数
upload_file() {
    local file_path="$1"
    local destination="$2"
    
    echo -e "${BLUE}[信息]${NC} 上传文件: $file_path 到 $destination"
    echo -e "${BLUE}[调试]${NC} 使用的API令牌: ${CLOUDFLARE_API_TOKEN:0:5}...${CLOUDFLARE_API_TOKEN: -5}"
    echo -e "${BLUE}[调试]${NC} 使用的账户ID: $CLOUDFLARE_ACCOUNT_ID"
    echo -e "${BLUE}[调试]${NC} 使用的存储桶名称: $BUCKET_NAME"
    
    # 创建wrangler.toml配置文件
    cat > "$PROJECT_ROOT/wrangler.toml" <<EOL
name = "game-deploy"
main = "deploy/worker.js"
compatibility_date = "2023-12-01"

account_id = "$CLOUDFLARE_ACCOUNT_ID"

[[r2_buckets]]
binding = 'BUCKET'
bucket_name = '$BUCKET_NAME'
EOL
    
    # 使用wrangler上传文件到R2存储桶
    cd "$PROJECT_ROOT" && \
    CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN \
    "$WRANGLER_PATH" r2 object put "$BUCKET_NAME/$destination" \
    --file="$file_path" \
    --content-type="text/html"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[成功]${NC} 文件上传成功: $destination"
        return 0
    else
        echo -e "${RED}[错误]${NC} 文件上传失败: $destination"
        return 1
    fi
}

# 上传游戏文件
echo -e "${BLUE}[信息]${NC} 开始上传游戏文件..."

# 上传第一个游戏文件
SQUIDKI_GAME_PATH="/Users/dahuang/Downloads/sprunki游戏/Squidki original (reuploaded).html"
if [ -f "$SQUIDKI_GAME_PATH" ]; then
    upload_file "$SQUIDKI_GAME_PATH" "sprunki-squidki.html"
    if [ $? -ne 0 ]; then
        echo -e "${RED}[错误]${NC} 上传Squidki游戏文件失败"
        exit 1
    fi
else
    echo -e "${RED}[错误]${NC} Squidki游戏文件不存在: $SQUIDKI_GAME_PATH"
    exit 1
fi

# 上传第二个游戏文件
RETAKE_GAME_PATH="/Users/dahuang/Downloads/sprunki游戏/Sprunki Retake New Human With New Bonus (Not Mine 18+).html"
if [ -f "$RETAKE_GAME_PATH" ]; then
    upload_file "$RETAKE_GAME_PATH" "sprunki-retake-new-human.html"
    if [ $? -ne 0 ]; then
        echo -e "${RED}[错误]${NC} 上传Retake游戏文件失败"
        exit 1
    fi
else
    echo -e "${RED}[错误]${NC} Retake游戏文件不存在: $RETAKE_GAME_PATH"
    exit 1
fi

# 上传404页面
if [ -f "$PROJECT_ROOT/404.html" ]; then
    upload_file "$PROJECT_ROOT/404.html" "404.html"
    if [ $? -ne 0 ]; then
        echo -e "${RED}[错误]${NC} 上传404页面失败"
        exit 1
    fi
else
    echo -e "${YELLOW}[警告]${NC} 404页面文件不存在: $PROJECT_ROOT/404.html"
    echo -e "${YELLOW}[警告]${NC} 将使用默认404响应"
fi

echo -e "${GREEN}[成功]${NC} 所有文件上传完成"

# 自动部署Worker
echo -e "${BLUE}[信息]${NC} 开始部署Worker..."
bash "$SCRIPT_DIR/deploy_worker.sh"

echo -e "${GREEN}[完成]${NC} 游戏文件上传和Worker部署完成"
echo -e "${BLUE}[信息]${NC} 你的游戏现在可以通过以下URL访问:"
echo -e "- https://game.sprunkr.online/sprunki-squidki.html"
echo -e "- https://game.sprunkr.online/sprunki-retake-new-human.html"
echo -e "${YELLOW}[提示]${NC} 确保在Cloudflare控制台中为域名sprunkr.online设置了正确的DNS记录"
