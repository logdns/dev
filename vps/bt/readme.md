>宝塔开心版防火墙跟统计插件
>打开目录/www/server/panel/class找到并编辑panelplugin.py文件
>使用Ctrl+F搜索并找到

```bash
softList['list'] = tmpList
```
>这段代码，在其下方添加如下代码：

```bash
softList['pro'] = 1
for soft in softList['list']:
soft['endtime'] = 0
```
>按图片这种格式！注意缩进！！！
![398433013](https://raw.githubusercontent.com/logdns/myimg/master/imgs/398433013.png)

>修改完成后重启面板，重启完成后就可以直接安装收费的插件了，Nginx防火墙也可以直接安装使用

>网站监控报表
>如果需要使用网站监控报表还需另外修改一次代码：
>安装好网站监控报表插件后打开/www/server/panel/plugin/total目录并编辑total_main.py文件
>使用Ctrl+F搜索并找到

```bash
if 'bt_total' in session: return public.returnMsg(True,'OK!');
```
>这段代码,在这段代码前加上#将其注释掉，并在其下方加入以下代码：

```bash
session['bt_total'] = True
return public.returnMsg(True,'OK!');
```
![398433013](https://raw.githubusercontent.com/logdns/myimg/master/imgs/520277831.png)

>重启面板,教程来源于互联网 亲测可用
