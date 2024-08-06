# Dockfiles


## nginx + ftp

构建内置`nginx` + `vsftp`的镜像，`ftp`服务器和`web`服务器共享相同的根目录，因此您可以通过`ftp`来管理`web`服务器的文件。

### 使用

```bash
docker run --name nginx-ftp -d \
    --restart always \
    -p 80:80  \
    -p 21:21  \
    -v /path/to/your/www:/data \
    zhangfisher/nginx-ftp    
```

### 说明

- `nginx`默认监听`80`端口
- `vsftp`默认监听`21`端口
- `ftp`服务器默认的用户名`admin`和密码`123456##**`，可以通过环境变量`FTP_ADMIN_USER`和`FTP_ADMIN_PASSWORD`来修改。
- `data`文件夹是`ftp`服务器的根目录，也是`web`根目录，因此您可以通过`ftp`来管理`web`的文件，该文件夹可以通过`-v`参数挂载到宿主机上，以便持久化数据，例如`-v /path/to/your/www:/data`。
- `data`文件夹的结构如下：

```bash
data
├── config
│   ├── vsftpd.conf
│   └── nginx.conf
├── www            # nginx和ftp的根目录
│    └── index.html
└── logs
```









