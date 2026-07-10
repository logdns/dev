# mydiy Karing 自定义分流维护说明

## 文件

- `mydiy-karing-diversion.json`: Karing 客户端导入文件。
- `generate_mydiy_karing.py`: 从 Shadowrocket `mydiy.conf` 重新生成 Karing 导入文件。
- `mydiy-karing-unsupported.txt`: Karing 自定义分流无法表达的规则说明。

## 分组设计

导入后建议保持下面顺序，Karing 分流规则从上到下匹配：

1. `🚫 DIY-广告拦截`: 广告和追踪规则，走 `block`。
2. `🎯 DIY-域名直连`: 国内和白名单域名，走 `direct`。
3. `🧭 DIY-IP直连`: 国内和局域网 IP，走 `direct`。
4. `🌍 DIY-域名代理`: 国外或需要代理的域名，走 `currentSelected`。
5. `🌐 DIY-IP代理`: 国外或需要代理的 IP，走 `currentSelected`。

## 转换规则

- Shadowrocket `REJECT` 转为 Karing `block`。
- Shadowrocket `DIRECT` 转为 Karing `direct`。
- Shadowrocket `PROXY`/`Proxy` 转为 Karing `currentSelected`。
- Karing 不接受 `.list` 作为远程 Rule Set；已知 ACL4SSR 规则映射为 Karing 内置 `acl:*`，自定义小列表展开为普通域名/IP 规则。
- Karing 自定义分流导入不支持 `USER-AGENT`；`FINAL,PROXY` 需要在 Karing 的“分流规则”页面把 `final` 设置为当前选择或代理策略。

## 重新生成

```bash
python3 generate_mydiy_karing.py
```

如需使用本地源文件：

```bash
python3 generate_mydiy_karing.py --source /path/to/mydiy.conf
```

生成后先检查：

```bash
jq '.rules | length' mydiy-karing-diversion.json
cat mydiy-karing-unsupported.txt
```

## 导入步骤

1. Karing 打开“自定义分流组”。
2. 点右上角菜单，选择“导入”。
3. 选择 `mydiy-karing-diversion.json`。
4. 导入后到“分流规则”页面确认排序，并把 `final` 设置为当前选择或代理策略。
5. 断开并重新连接 Karing，使规则生效。

<img width="341" height="311" alt="eebcf8aa8cad498008c05ad334a85b73" src="https://github.com/user-attachments/assets/c141171e-ebf8-43eb-a918-736ffba12da2" />
<img width="409" height="602" alt="d55422654b39d3fdb3e178dbfe31c97d" src="https://github.com/user-attachments/assets/d2a36c6f-974a-4e4a-83f4-a94ab51cab87" />
<img width="400" height="724" alt="fc11bcb5244323411035aa9a013f7fde" src="https://github.com/user-attachments/assets/948e33e1-ed71-4e83-91fb-71be8d036ab6" />



