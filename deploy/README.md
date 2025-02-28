# 部署指南

本文档详细说明如何将游戏部署到Cloudflare上。

## 前提条件

1. 拥有一个域名
2. 注册Cloudflare账号
3. 安装Node.js和npm

## 详细步骤

### 1. 注册Cloudflare账号

1. 访问 [cloudflare.com](https://cloudflare.com)
2. 点击"Sign Up"注册账号
3. 选择免费计划

### 2. 添加域名到Cloudflare

1. 登录后点击"Add a Site"
2. 输入你的域名（例如：yourgame.com）
3. 选择免费计划
4. 按照指示更改你的域名DNS服务器

### 3. 创建R2存储桶

1. 在Cloudflare控制台选择"R2"
2. 点击"Create bucket"
3. 名称填写：`game-assets`
4. 选择离你最近的地区

### 4. 获取API密钥

1. 在Cloudflare控制台找到"API Tokens"
2. 创建一个新的token，确保有R2的读写权限

### 5. 安装Wrangler工具

```bash
npm install -g wrangler
wrangler login
```

### 6. 上传文件到R2

运行以下命令上传文件：

```bash
./upload.sh
```

### 7. 配置Cloudflare Pages

1. 进入Cloudflare Pages
2. 点击"Create a project"
3. 选择"Direct Upload"
4. 上传项目文件
5. 配置自定义域名

### 8. 设置缓存规则

在Cloudflare控制台添加页面规则：
- URL: yourgame.com/*
- 设置：Cache Everything
- Edge Cache TTL: 1 month
- Browser Cache TTL: 4 hours

### 9. 测试部署

访问你的域名，确认游戏加载正常。

## 维护建议

1. 定期检查访问统计
2. 监控带宽使用
3. 检查错误日志
4. 根据需要更新游戏文件
