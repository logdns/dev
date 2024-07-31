addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
  })
  
  async function handleRequest(request) {
    const url = new URL(request.url)
    const path = url.pathname
  
    if (request.method === 'POST' && path === '/upload') {
      return handleUpload(request)
    }
  
    if (path === '/' || path === '/index.html') {
      return new Response(HTML_CONTENT, {
        headers: { 'Content-Type': 'text/html' }
      })
    }
  
    if (path.startsWith('/file/')) {
      return handleTelegraphFile(request)
    }
  
    return new Response('Not Found', { status: 404 })
  }
  
  async function handleUpload(request) {
    try {
      const formData = await request.formData();
      const file = formData.get('file');
      
      if (!file) {
        return new Response('No file uploaded', { status: 400 });
      }
  
      // 读取文件内容
      const fileContent = await file.arrayBuffer();
      const fileBlob = new Blob([fileContent], { type: file.type });
  
      // 创建一个新的 FormData 对象用于 Telegraph 上传
      const telegraphFormData = new FormData();
      telegraphFormData.append('file', fileBlob, file.name);
  
      // 发送请求到 Telegraph
      const telegraphResponse = await fetch('https://telegra.ph/upload', {
        method: 'POST',
        body: telegraphFormData
      });
  
      if (!telegraphResponse.ok) {
        throw new Error('Telegraph upload failed');
      }
  
      const telegraphResult = await telegraphResponse.json();
      
      if (!telegraphResult || !telegraphResult[0] || !telegraphResult[0].src) {
        throw new Error('Invalid response from Telegraph');
      }
  
      const uploadedPath = telegraphResult[0].src;
      const telegraphUrl = 'https://telegra.ph' + uploadedPath;
      const customDomainUrl = 'https://file.xinai.de' + uploadedPath;
      const workersUrl = 'https://' + new URL(request.url).hostname + uploadedPath;
  
      return new Response(JSON.stringify({
        src: uploadedPath,
        telegraphUrl,
        customDomainUrl,
        workersUrl
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Upload error:', error);
      return new Response('Upload failed: ' + error.message, { status: 500 });
    }
  }
  
  async function handleTelegraphFile(request) {
    const telegraphUrl = 'https://telegra.ph' + new URL(request.url).pathname;
    const response = await fetch(telegraphUrl);
    
    if (!response.ok) {
      return new Response('File not found', { status: 404 });
    }
    
    const headers = new Headers(response.headers);
    headers.set('Access-Control-Allow-Origin', '*');
    
    return new Response(response.body, {
      status: response.status,
      headers: headers
    });
  }
  
  const HTML_CONTENT = `
  <!DOCTYPE html>
  <html lang="zh-CN">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>沨哥临时文件系统</title>
      <meta name="description" content="沨哥临时文件系统">
      <meta name="keywords" content="沨哥临时文件系统">
      <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;700&display=swap" rel="stylesheet">
      <style>
          :root {
              --primary-color: #4a90e2;
              --secondary-color: #f39c12;
              --background-color: #f0f4f8;
              --text-color: #333;
          }
  
          body {
              font-family: 'Roboto', sans-serif;
              background-color: var(--background-color);
              color: var(--text-color);
              line-height: 1.6;
              margin: 0;
              padding: 0;
          }
  
          .container {
              max-width: 800px;
              margin: 2rem auto;
              padding: 2rem;
              background-color: white;
              border-radius: 10px;
              box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          }
  
          h1 {
              text-align: center;
              color: var(--primary-color);
              margin-bottom: 2rem;
          }
  
          #uploadForm {
              display: flex;
              justify-content: center;
              align-items: center;
              gap: 10px;
          }
  
          .file-input-wrapper {
              position: relative;
              overflow: hidden;
              display: inline-block;
          }
  
          .file-input-wrapper input[type=file] {
              font-size: 100px;
              position: absolute;
              left: 0;
              top: 0;
              opacity: 0;
              cursor: pointer;
          }
  
          .btn {
              background-color: var(--primary-color);
              color: white;
              padding: 10px 20px;
              border: none;
              border-radius: 5px;
              cursor: pointer;
              transition: background-color 0.3s ease;
          }
  
          .btn:hover {
              background-color: #3a7bd5;
          }
  
          .max-size-info {
              text-align: center;
              color: #777;
              margin-top: 1rem;
          }
  
          .progress-bar {
              height: 5px;
              background-color: #e0e0e0;
              margin-top: 1rem;
              border-radius: 5px;
              overflow: hidden;
          }
  
          .progress {
              width: 0;
              height: 100%;
              background-color: var(--secondary-color);
              transition: width 0.3s ease;
          }
  
          #result {
              margin-top: 2rem;
          }
  
          .link-group {
              background-color: #f9f9f9;
              padding: 1rem;
              border-radius: 5px;
              margin-top: 1rem;
          }
  
          .code-block {
              background-color: #f0f0f0;
              padding: 10px;
              border-radius: 4px;
              margin-top: 10px;
              font-family: monospace;
              white-space: pre-wrap;
              word-break: break-all;
              position: relative;
          }
  
          .copy-btn {
              position: absolute;
              top: 5px;
              right: 5px;
              background-color: var(--primary-color);
              color: white;
              border: none;
              border-radius: 3px;
              padding: 5px 10px;
              cursor: pointer;
              font-size: 12px;
              transition: background-color 0.3s ease;
          }
  
          .copy-btn:hover {
              background-color: #3a7bd5;
          }
  
          .toast {
              position: fixed;
              top: 20px;
              right: 20px;
              background-color: #2ecc71;
              color: white;
              padding: 10px 20px;
              border-radius: 4px;
              display: none;
              opacity: 0;
              transition: opacity 0.3s ease;
          }
  
          @keyframes fadeIn {
              from { opacity: 0; transform: translateY(-20px); }
              to { opacity: 1; transform: translateY(0); }
          }
  
          .fade-in {
              animation: fadeIn 0.5s ease forwards;
          }
  
          footer {
              text-align: center;
              margin-top: 2rem;
              color: #777;
              font-size: 0.9rem;
          }
  
          footer a {
              color: var(--primary-color);
              text-decoration: none;
          }
  
          footer a:hover {
              text-decoration: underline;
          }
      </style>
  </head>
  <body>
      <div class="container">
          <h1>沨哥临时文件系统</h1>
          <form id="uploadForm">
              <div class="file-input-wrapper">
                  <button class="btn" type="button">选择文件</button>
                  <input type="file" id="fileInput" accept="image/*,video/mp4,.pdf,.doc,.docx,.txt" required>
              </div>
              <button type="submit" class="btn">上传</button>
          </form>
          <p class="max-size-info">最大上传文件大小：5MB</p>
          <div class="progress-bar">
              <div class="progress" id="progressBar"></div>
          </div>
          <div id="result"></div>
      </div>
      <div id="toast" class="toast">复制成功！</div>
  
      <footer>
          <p>鸣谢: <a href="https://workers.cloudflare.com/" target="_blank">Cloudflare Workers</a> | <a href="https://telegra.ph/" target="_blank">Telegraph</a></p>
          <p>源码: <a href="https://github.com/logdns/dev/tree/master/Ai%20code/cf%20works" target="_blank">GitHub</a></p>
      </footer>
  
      <script>
          document.addEventListener('DOMContentLoaded', function() {
              const form = document.getElementById('uploadForm');
              const fileInput = document.getElementById('fileInput');
              const resultDiv = document.getElementById('result');
              const progressBar = document.getElementById('progressBar');
              const fileButton = document.querySelector('.file-input-wrapper .btn');
  
              fileInput.addEventListener('change', function(e){
                  let fileName = e.target.files[0].name;
                  fileButton.textContent = fileName.length > 20 ? fileName.substring(0, 17) + '...' : fileName;
              });
  
              form.addEventListener('submit', async (e) => {
                  e.preventDefault();
                  resultDiv.textContent = '';
                  progressBar.style.width = '0%';
  
                  if (!fileInput.files.length) {
                      showResult('请选择一个文件');
                      return;
                  }
  
                  const file = fileInput.files[0];
                  if (file.size > 5 * 1024 * 1024) {
                      showResult('文件大小超过5MB限制');
                      return;
                  }
  
                  const formData = new FormData();
                  formData.append('file', file);
  
                  try {
                      simulateProgress();
                      const response = await fetch('/upload', {
                          method: 'POST',
                          body: formData
                      });
  
                      if (!response.ok) {
                          throw new Error('上传失败');
                      }
  
                      const result = await response.json();
                      const { customDomainUrl, telegraphUrl, workersUrl } = result;
  
                      showResult(\`
                          <h3>上传成功！</h3>
                          <div class="link-group fade-in">
                              <strong>URL:</strong>
                              <div class="code-block" id="url-block">\${customDomainUrl}<button class="copy-btn" data-clipboard-text="\${customDomainUrl}">复制</button></div>
                              
                              <strong>HTML:</strong>
                              <div class="code-block" id="html-block">&lt;img src="\${customDomainUrl}" alt="image" /&gt;<button class="copy-btn" data-clipboard-text="<img src='\${customDomainUrl}' alt='image' />">复制</button></div>
                              
                              <strong>BBCode:</strong>
                              <div class="code-block" id="bbcode-block">[img]\${customDomainUrl}[/img]<button class="copy-btn" data-clipboard-text="[img]\${customDomainUrl}[/img]">复制</button></div>
                              
                              <strong>Markdown:</strong>
                              <div class="code-block" id="markdown-block">![](\${customDomainUrl})<button class="copy-btn" data-clipboard-text="![](\${customDomainUrl})">复制</button></div>
                              
                              <strong>其他链接:</strong>
                              <a href="\${telegraphUrl}" target="_blank">Telegraph 链接</a>
                              <a href="\${workersUrl}" target="_blank">Workers 链接</a>
                          </div>
                      \`);
  
                      document.querySelectorAll('.copy-btn').forEach(btn => {
                          btn.addEventListener('click', function() {
                              const textToCopy = this.getAttribute('data-clipboard-text');
  
                              navigator.clipboard.writeText(textToCopy).then(() => {
                                  showToast();
                              }).catch(err => {
                                  console.error('无法复制文本: ', err);
                              });
                          });
                      });
  
                  } catch (error) {
                      showResult('上传失败: ' + error.message);
                  }
              });
  
              function showResult(message) {
                  resultDiv.innerHTML = message;
                  resultDiv.style.display = 'block';
              }
  
              function simulateProgress() {
                  let progress = 0;
                  const interval = setInterval(() => {
                      progress += Math.random() * 10;
                      if (progress > 100) progress = 100;
                      progressBar.style.width = progress + '%';
                      if (progress === 100) clearInterval(interval);
                  }, 200);
              }
  
              function showToast() {
                  const toast = document.getElementById('toast');
                  toast.style.display = 'block';
                  toast.style.opacity = '1';
                  setTimeout(() => {
                      toast.style.opacity = '0';
                      setTimeout(() => {
                          toast.style.display = 'none';
                      }, 300);
                  }, 2000);
              }
          });
      </script>
  </body>
  </html>
  `;
  
