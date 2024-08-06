# Dockfiles


## nginx + ftp

构建内置`nginx` + `vsftp`的镜像，`ftp`服务器和`web`服务器共享相同的根目录，因此您可以通过`ftp`来管理`web`服务器的文件。

### 使用

```bash
docker run --name nginx-ftp -d \
    --restart always \
    -p 80:80  \
    -p 21:21  \
    v /path/to/your/www:/data \
    zhangfisher/nginx-ftp
```







- `nginx`默认监听`80`端口
- `vsftp`默认监听`21`端口
- `ftp`服务器默认的用户名`admin`和密码`123456##**`





