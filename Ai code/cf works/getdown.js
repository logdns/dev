addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  let targetUrl = new URL(request.url).pathname.slice(1);

  if (!targetUrl) {
    return new Response(
      `<!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>下载工具使用指南</title>
        <style>
          body {
            margin: 0;
            font-family: 'Segoe UI', Arial, sans-serif;
            background: linear-gradient(45deg, #6a11cb 0%, #2575fc 100%);
            animation: Gradient 15s ease infinite;
            color: #fff;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            overflow: hidden;
          }

          @keyframes Gradient {
            0% {
              background-position: 0% 50%;
            }
            50% {
              background-position: 100% 50%;
            }
            100% {
              background-position: 0% 50%;
            }
          }
          
          .container {
            max-width: 600px;
            padding: 40px;
            background: rgba(0, 0, 0, 0.5);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.7);
            border-radius: 10px;
          }

          h1, p, a {
            text-align: center;
          }

          h1 {
            font-size: 24px;
            margin-bottom: 20px;
          }

          p {
            font-size: 16px;
            line-height: 1.5;
          }

          a {
            display: inline-block;
            margin-top: 20px;
            padding: 10px 20px;
            background: #0D47A1;
            color: white;
            text-decoration: none;
            border-radius: 5px;
          }

          a:hover {
            background: #1565C0;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>文件下载工具</h1>
          <p>此工具能帮助您安全快速地下载文件。只需将文件链接追加到本站的URL后面。</p>
          <p>示例:<br>
            假设您需要下载：<code>http://example.com/file.txt</code><br>
            您可以通过：<a href="#">https://your-domain.com/http://example.com/file.txt</a>
          </p>
        </div>
      </body>
      </html>`,
      { headers: { 'Content-Type': 'text/html; charset=utf-8' } }
    );
  }

  if (!/^https?:\/\//i.test(targetUrl)) {
    targetUrl = 'http://' + targetUrl;
  }
  try {
    const response = await fetch(targetUrl, { headers: request.headers });
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    const downloadResponse = new Response(response.body, response);
    downloadResponse.headers.set('Content-Disposition', 'attachment');
    return downloadResponse;
  } catch (error) {
    return new Response(`Request to ${targetUrl} failed: ${error.message}`, { status: 502 });
  }
}
