addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

function handleRequest(request) {
  const html = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Base64 编码/解码</title>
    <style>
        body {
            font-family: 'Microsoft YaHei', Arial, sans-serif;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background-color: #f0f0f0;
            padding: 20px;
            box-sizing: border-box;
        }
        .container {
            background-color: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            max-width: 800px;
            width: 100%;
        }
        h1 {
            text-align: center;
            color: #333;
        }
        textarea {
            width: 100%;
            height: 150px;
            margin-bottom: 1rem;
            padding: 0.5rem;
            border: 1px solid #ccc;
            border-radius: 4px;
            resize: vertical;
            font-family: 'Courier New', monospace;
        }
        .buttons {
            display: flex;
            justify-content: space-between;
            margin-bottom: 1rem;
        }
        button {
            background-color: #4CAF50;
            border: none;
            color: white;
            padding: 10px 20px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 16px;
            cursor: pointer;
            border-radius: 4px;
            transition: background-color 0.3s;
            flex: 1;
            margin: 0 5px;
        }
        button:hover {
            background-color: #45a049;
        }
        .result {
            margin-top: 1rem;
            padding: 1rem;
            background-color: #e9e9e9;
            border-radius: 4px;
            word-break: break-all;
            white-space: pre-wrap;
            font-family: 'Courier New', monospace;
            max-height: 300px;
            overflow-y: auto;
        }
        .copy-btn {
            background-color: #008CBA;
            margin-top: 1rem;
        }
        .copy-btn:hover {
            background-color: #007B9A;
        }
        footer {
            margin-top: 20px;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
        footer a {
            color: #008CBA;
            text-decoration: none;
        }
        footer a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Base64 编码/解码</h1>
        <textarea id="input" placeholder="输入要编码或解码的文本"></textarea>
        <div class="buttons">
            <button onclick="encode()">编码</button>
            <button onclick="decode()">解码</button>
        </div>
        <div class="result" id="result"></div>
        <button class="copy-btn" onclick="copyResult()">复制结果</button>
    </div>
    <footer>
        <p>由 <a href="https://xinai.de" target="_blank">小沨</a> 提供支持 | <a href="https://github.com/logdns/dev/blob/master/Ai%20code/cf%20works/base64.js" target="_blank">GitHub 源码</a></p>
    </footer>

    <script>
        function encode() {
            var input = document.getElementById('input').value;
            var encoded = btoa(unescape(encodeURIComponent(input)));
            document.getElementById('result').textContent = encoded;
        }

        function decode() {
            var input = document.getElementById('input').value;
            try {
                var decoded = decodeURIComponent(escape(atob(input)));
                document.getElementById('result').textContent = decoded;
            } catch (e) {
                document.getElementById('result').textContent = '无效的 Base64 输入';
            }
        }

        function copyResult() {
            var result = document.getElementById('result');
            var range = document.createRange();
            range.selectNode(result);
            window.getSelection().removeAllRanges();
            window.getSelection().addRange(range);
            document.execCommand('copy');
            window.getSelection().removeAllRanges();
            alert('已复制到剪贴板！');
        }
    </script>
</body>
</html>
  `

  return new Response(html, {
    headers: { 'content-type': 'text/html; charset=utf-8' },
  })
}
