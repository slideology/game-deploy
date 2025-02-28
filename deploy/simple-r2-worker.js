/**
 * 简单的R2访问Worker
 * 这个Worker直接从R2存储桶提供内容，不需要Pages
 */

export default {
  async fetch(request, env, ctx) {
    // 获取请求的URL和路径
    const url = new URL(request.url);
    let path = url.pathname.substring(1);
    
    // 如果路径为空，默认为index.html
    if (path === "" || path.endsWith("/")) {
      path += "index.html";
    }
    
    // 从R2存储桶获取对象
    const object = await env.BUCKET.get(path);
    
    // 如果对象不存在，返回404
    if (object === null) {
      return new Response("找不到请求的资源", { status: 404 });
    }
    
    // 设置正确的Content-Type
    const headers = new Headers();
    const contentType = getContentType(path);
    headers.set("Content-Type", contentType);
    headers.set("Cache-Control", "public, max-age=86400");
    
    // 返回对象内容
    return new Response(object.body, {
      headers
    });
  }
};

/**
 * 根据文件扩展名获取Content-Type
 */
function getContentType(path) {
  const extension = path.split('.').pop().toLowerCase();
  const contentTypes = {
    'html': 'text/html',
    'css': 'text/css',
    'js': 'application/javascript',
    'json': 'application/json',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'svg': 'image/svg+xml',
    'ico': 'image/x-icon',
    'txt': 'text/plain',
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
}
