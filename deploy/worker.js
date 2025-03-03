/**
 * Sprunki-Squidki 游戏 Worker
 * 这个Worker从R2存储桶提供游戏文件，支持不同的路径访问
 */

export default {
  async fetch(request, env, ctx) {
    // 获取请求的URL和路径
    const url = new URL(request.url);
    let path = url.pathname;
    
    // 详细日志记录
    console.log(`处理请求: ${path}`);
    console.log(`请求URL: ${request.url}`);
    console.log(`请求方法: ${request.method}`);
    console.log(`请求头: ${JSON.stringify(Object.fromEntries([...request.headers]))}`);
    
    // 检查R2存储桶中的所有对象
    try {
      console.log("列出R2存储桶中的所有对象:");
      const objects = await env.BUCKET.list();
      console.log(`找到 ${objects.objects.length} 个对象`);
      for (const object of objects.objects) {
        console.log(`- ${object.key} (${object.size} bytes)`);
      }
    } catch (error) {
      console.error(`列出R2对象时出错: ${error.message}`);
    }
    
    // 检查是否存在特定文件
    try {
      const squidkiExists = await env.BUCKET.head("sprunki-squidki.html");
      console.log(`sprunki-squidki.html 存在: ${squidkiExists !== null}`);
      
      const retakeExists = await env.BUCKET.head("sprunki-retake-new-human.html");
      console.log(`sprunki-retake-new-human.html 存在: ${retakeExists !== null}`);
      
      const notFoundExists = await env.BUCKET.head("404.html");
      console.log(`404.html 存在: ${notFoundExists !== null}`);
    } catch (error) {
      console.error(`检查文件存在性时出错: ${error.message}`);
    }
    
    // 处理不同的游戏路径
    if (path === "/sprunki-squidki.html") {
      console.log("尝试获取sprunki-squidki.html文件");
      // 直接从R2存储桶获取游戏文件
      try {
        const gameFile = await env.BUCKET.get("sprunki-squidki.html");
        if (gameFile !== null) {
          console.log("找到sprunki-squidki.html文件，返回内容");
          
          // 处理HTML内容，添加iframe检测代码
          const modifiedContent = await this.addExternalLinkIfInIframe(gameFile.body);
          
          return new Response(modifiedContent, { 
            headers: {
              "Content-Type": "text/html;charset=UTF-8"
            }
          });
        } else {
          console.error("sprunki-squidki.html文件不存在");
        }
      } catch (error) {
        console.error(`获取游戏文件时出错: ${error.message}`);
      }
    } 
    else if (path === "/sprunki-retake-new-human.html") {
      console.log("尝试获取sprunki-retake-new-human.html文件");
      // 直接从R2存储桶获取游戏文件
      try {
        const gameFile = await env.BUCKET.get("sprunki-retake-new-human.html");
        if (gameFile !== null) {
          console.log("找到sprunki-retake-new-human.html文件，返回内容");
          
          // 处理HTML内容，添加iframe检测代码
          const modifiedContent = await this.addExternalLinkIfInIframe(gameFile.body);
          
          return new Response(modifiedContent, { 
            headers: {
              "Content-Type": "text/html;charset=UTF-8"
            }
          });
        } else {
          console.error("sprunki-retake-new-human.html文件不存在");
        }
      } catch (error) {
        console.error(`获取游戏文件时出错: ${error.message}`);
      }
    }
    else if (path === "/" || path === "") {
      console.log("处理根路径请求，返回404页面");
      // 根路径返回自定义404页面
      try {
        const notFoundPage = await env.BUCKET.get("404.html");
        if (notFoundPage !== null) {
          return new Response(notFoundPage.body, { 
            status: 404,
            headers: {
              "Content-Type": "text/html;charset=UTF-8"
            }
          });
        }
      } catch (error) {
        console.error(`获取404页面时出错: ${error.message}`);
      }
      
      // 如果404页面不存在或加载失败，返回简单的404响应
      return new Response("页面未找到", { 
        status: 404,
        headers: {
          "Content-Type": "text/plain;charset=UTF-8"
        }
      });
    }
    
    // 如果不是特定的游戏路径，尝试直接从R2获取文件
    try {
      // 移除开头的斜杠
      const objectPath = path.startsWith("/") ? path.substring(1) : path;
      console.log(`尝试从R2获取文件: ${objectPath}`);
      
      // 从R2存储桶获取对象
      const object = await env.BUCKET.get(objectPath);
      
      // 如果对象不存在，返回404
      if (object === null) {
        console.log(`未找到资源: ${objectPath}`);
        
        // 尝试返回自定义404页面
        try {
          const notFoundPage = await env.BUCKET.get("404.html");
          if (notFoundPage !== null) {
            return new Response(notFoundPage.body, { 
              status: 404,
              headers: {
                "Content-Type": "text/html;charset=UTF-8"
              }
            });
          }
        } catch (error) {
          console.error(`获取404页面时出错: ${error.message}`);
        }
        
        // 如果404页面不存在或加载失败，返回简单的404响应
        return new Response(`找不到请求的资源: ${objectPath}`, { 
          status: 404,
          headers: {
            "Content-Type": "text/plain;charset=UTF-8"
          }
        });
      }
      
      // 确定内容类型
      const contentType = this.getContentType(objectPath);
      
      // 如果是HTML文件，添加iframe检测代码
      if (contentType === 'text/html;charset=UTF-8') {
        const htmlContent = await this.addExternalLinkIfInIframe(object.body);
        return new Response(htmlContent, {
          headers: {
            "Content-Type": contentType
          }
        });
      } else {
        // 返回文件内容
        return new Response(object.body, {
          headers: {
            "Content-Type": contentType
          }
        });
      }
    } catch (error) {
      console.error(`处理请求时出错: ${error.message}`);
      return new Response(`服务器错误: ${error.message}`, { 
        status: 500,
        headers: {
          "Content-Type": "text/plain;charset=UTF-8"
        }
      });
    }
  },
  
  // 根据文件扩展名获取Content-Type
  getContentType(path) {
    const extension = path.split('.').pop().toLowerCase();
    const contentTypes = {
      'html': 'text/html;charset=UTF-8',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'gif': 'image/gif',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon',
      'txt': 'text/plain;charset=UTF-8',
      'mp3': 'audio/mpeg',
      'mp4': 'video/mp4',
      'webp': 'image/webp',
      'woff': 'font/woff',
      'woff2': 'font/woff2',
      'ttf': 'font/ttf',
      'otf': 'font/otf',
      'eot': 'application/vnd.ms-fontobject'
    };
    
    return contentTypes[extension] || 'application/octet-stream';
  },
  
  // 添加外部链接检测代码到HTML内容
  async addExternalLinkIfInIframe(htmlContent) {
    // 转换为文本
    const text = await new Response(htmlContent).text();
    
    // 创建iframe检测和添加外链的JavaScript代码
    const scriptToInject = `
    <script>
      // 当页面加载完成后执行
      document.addEventListener('DOMContentLoaded', function() {
        // 检测是否在iframe中运行
        if (window.self !== window.top) {
          // 创建外链元素
          var linkElement = document.createElement('a');
          linkElement.href = 'https://sprunkr.online/';
          linkElement.textContent = 'Sprunkr.Online';
          linkElement.target = '_blank';
          
          // 设置样式
          linkElement.style.position = 'fixed';
          linkElement.style.bottom = '10px';
          linkElement.style.right = '10px';
          linkElement.style.padding = '5px 10px';
          linkElement.style.backgroundColor = '#007bff';
          linkElement.style.color = 'white';
          linkElement.style.textDecoration = 'none';
          linkElement.style.borderRadius = '5px';
          linkElement.style.fontFamily = 'Arial, sans-serif';
          linkElement.style.fontSize = '14px';
          linkElement.style.zIndex = '9999';
          
          // 添加到页面
          document.body.appendChild(linkElement);
        }
      });
    </script>
    `;
    
    // 在</head>标签前插入脚本
    if (text.includes('</head>')) {
      return text.replace('</head>', scriptToInject + '</head>');
    } 
    // 如果没有</head>标签，在<body>标签后插入
    else if (text.includes('<body>')) {
      return text.replace('<body>', '<body>' + scriptToInject);
    } 
    // 如果都没有，在开头插入
    else {
      return scriptToInject + text;
    }
  }
};
