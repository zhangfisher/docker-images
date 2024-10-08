# Dockfiles


## nginx + ftp

构建内置`nginx` + `vsftp`的镜像，`ftp`服务器和`web`服务器共享相同的根目录，因此您可以通过`ftp`来管理`web`服务器的文件。

### 使用

```bash
docker run --name your-name -d \
    --restart always \
    -p 80:80  \
    -p 21:21  \
    -p 22:22 \
    -v /path/to/your/www:/data \
    zhangfisher/nginx-ftp    
```
也可以自行构建镜像：

```bash
git clone https://github.com/zhangfisher/dockerfiles.git
cd dockerfiles/nginx-ftp
docker build -t nginx-ftp .
```

### 特性

#### 共享目录

内置的`nginx`和`ftp`服务器共享相同的根目录,使用`FTP`登录`ftp`服务器，进入的就是`Web`服务器的根目录,因此可以管理`web`服务器的文件。

- `nginx`默认监听`80`端口
- `vsftp`默认监听`21`端口
- `ftp`服务器默认的用户名`admin`和密码`123456##**`,可以通过环境变量`ADMIN_USER`和`ADMIN_PASSWORD`来修改。

#### SSH

内置`openssh-server`，可以通过`ssh`登录容器.

- 默认的用户名和密码与`ftp`一样，可以通过环境变量`ADMIN_USER`和`ADMIN_PASSWORD`来修改。
- 默认监听`22`端口

#### 数据目录

容器内的`/data`文件夹是`ftp`服务器的根目录，也是`web`根目录，可以通过`-v`参数挂载到宿主机上，以便持久化数据，例如`-v /path/to/your/www:/data`。`/data`文件夹的结构如下：

```bash
data
├── config          # nginx和ftp的配置文件
│   ├── vsftpd.conf
│   └── nginx.conf
├── www            # nginx和ftp的根目录
│    └── index.html
└── logs           # nginx和ftp的日志文件    
```

您可以直接在宿主机上修改`/path/to/your/www`下的配置文件。

#### 自动生成索引

容器运行时会启动`watch.sh`会监视`www`文件夹下的所有子文件夹内的`index.html`文件和`readme.md`文件变化,提取文件的`title`和`description`和文件夹名称,生成`index.json`文件。

提取文件的`title`和`description`的规则如下：

- **提取`index.html`文件的`title`和`description`**

```html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>标题</title>
    <meta name="description" content="描述">  
  </head>
  <body> 
  </body>
</html>
```

- **提取`readme.md`文件的第一行`#标题`的后续行作为`description`**

```markdown
# 这里是标题

这里是描述

## ...

```

如下面的目录结构：

```bash
data
├── config          
├── www            
│    ├── index.html
│    ├── A
│    │   └─ readme.md
│    ├── B
│    │   └─ readme.md
│    ├── C
│    │   └─ index.html
```

生成如下的`index.json`:

```json
[
    {
        "name":"A",
        "title": "A-Title",
        "description": "A的描述"
    },
    {
        "name":"B",
        "title": "B-Title",
        "description": "B的描述"
    },
    {
        "name":"C",
        "title": "C-Title",
        "description": "C的描述"
    }
]
```

