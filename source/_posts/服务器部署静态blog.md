---
title: 服务器部署静态blog
date: 2023-07-11 13:44:26
excerpt: 记录一下，将静态博客hexo部署到服务器的过程。
tags:
  - 云服务器
categories:
  实践 
---

# 服务器部署静态博客

# 一、在工作台配置DNS解析

这里主要是将域名和IP地址构建起映射，进行让域名能够指向我们的公网ip

记录类型选择A（将域名指向一个IPV4地址），记录值写公网IP，ttl是本地缓存的DNS过期时间（如果过期了就去别的运营商的DNS服务器查找）

# 二、nginx配置

## 2.1Nginx的作用

先说一下用户访问服务器的流程：用户 → 域名解析 → 服务器80/443端口 → Nginx接收请求 → 匹配站点配置 → 处理请求（静态文件/反向代理） → 返回响应 → 用户浏览器渲染。

在这里，Nginx主要充当域名路由的作用。Nginx 接收请求后，会解析请求头中的「Host 字段」（即 blog.zjanson.top），然后遍历 /etc/nginx/sites-enabled/ 下的所有站点配置，找到 server_name 与 Host 字段匹配的配置文件。（简单来说就是让 blog.zjanson.top 映射到一个本地目录，通过 Nginx 将静态文件返回给浏览器）

**关键原理：**一台服务器可以部署多个网站（如同时部署 blog.zjanson.top 和 docs.zjanson.top），Nginx 通过 server_name 实现「基于域名的虚拟主机」，让不同域名的请求对应不同的网站目录或服务。

场景：路由分为两种场景，一个是静态资源服务，还有一个是动态资源服务。这里主要记录一下静态，Nginx的一个主要优点就是可以直接处理静态资源，它还可以根据配置通过返回特定的 HTTP 响应头，指导你的浏览器将静态资源缓存到本地。

## 2.2创建 Nginx 的站点配置文件

Nginx 的站点配置文件就是 Nginx 用来“识别并服务某个网站”的配置文件，它里面的规则用来告诉 Nginx一个网站怎么运行。（因为nginx要路由到多个网站，所以每一个网站都需要在配置文件中配置一个单独的 server 块）

为了管理清晰，Ubuntu系统把站点配置分成两个目录：

```java
/etc/nginx/sites-available/   # 放所有站点配置文件（静态，未启用）
/etc/nginx/sites-enabled/     # 这里是实际启用的网站（软链接）
#Nginx 实际只加载 sites-enabled 目录内容。
```

sites-available下存放的网点可以理解为“候选网站”，而后续会将sites-enabled/和和available下指定的网点进行软连接，也就是只有软连接的网点才会被nginx代理启用。

现在开始设置配置文件：

一般会为每一个网点单独在sites-available下创建一个配置文件

```bash
sudo nano /etc/nginx/sites-available/blog.zjanson.top
#这里用的是nano打开的文件，保存退出（Ctrl+O，Enter，Ctrl+X）
```

输入以下内容

```json
server {
    listen 80;
    server_name blog.zjanson.top;

    root /var/www/myblog;  # 博客目录，务必写绝对路径,注意不要放到root下
    index index.html;

    location / {
        try_files $uri $uri/ = 404;
    }

    location ~ /\\. {
        deny all;
    }
}
```

如果访问站点报错，可以查看nginx的log看一下什么错误（/var/log/nginx/error.log）

## 2.3启用站点

软连接：

```bash
sudo ln -s /etc/nginx/sites-available/blog.zjanson.top /etc/nginx/sites-enabled/
```

检查语法： **检查 Nginx 配置文件是否有语法错误** 的命令，当修改任何 Nginx 配置文件时都需要检查一遍配置文件是否有错误

```bash
sudo nginx -t
```

如果没问题重启Nginx：

```bash
sudo systemctl reload nginx
```

# 三、动态更新网站

现在已经将静态blog部署到了服务器，但是我们想要对我们的博客进行更新，还需要进一步的配置。

## 3.1静态博客动态更新的原理

Hexo 本质上是 **静态网站生成器**，每次写完新文章后，需要执行：

```bash
hexo clean
hexo g
```

生成新的 public/ 静态文件，然后 Nginx 才能把最新内容展示出来。

**所以动态更新其实就是：**

1. 生成新的静态文件
2. 替换 Nginx 的根目录文件
3. Nginx 自动提供最新页面（因为 Nginx 本身直接读取文件，不缓存 HTML）

可以采用Git + CI 自动部署的方式实现

## 3.2实现自动部署（git+CI）

目标：当在本地写完文章并 git push 到远程仓库后，服务器能自动更新 Hexo 生成的静态文件，并通过 Nginx 提供最新页面。

核心原理：

1. **Git 仓库**：存放 Hexo 源码（包括文章、主题、配置）。
2. **Hook**：监听 Git 仓库的 push 事件，触发自动部署脚本。
3. **部署脚本**：执行 hexo clean && hexo g 生成静态文件，然后替换 Nginx 的 root 文件。
4. **Nginx**：直接托管最新的静态文件，无需重启（只要文件被替换，访问就更新了）

### 3.2.1本地初始化git并提交

```bash
cd study/myblog
git init       # 如果本地还没 git
git add .      #把博客文件（源码、文章、主题等）添加到 Git 暂存区
git commit -m "init"  #提交到本地 Git 仓库
git remote add origin git@github.com:yourusername/yourblog.git  #绑定远程仓库地址(未绑定时执行)
git push origin main  #将本地的提交推送到origin(远程)的main分支
```

### 3.2.2对服务器上进行git配置，拉取仓库

1. 在home下创建blog_ci目录用来存放git仓库

然后把git仓库克隆到这个位置

```bash
git clone git@github.com:WjzqcA/myblog.git
```

首次链接会有安全提示，直接yes

但是随后会提示链接不上，这是因为云服务器没有 GitHub 的 SSH key

2. **配置SSH key：**

在服务器上运行

```bash
ssh-keygen -t ed25519 -C "1207447957@qq.com"
```

然后一路回车，文件路径默认：/root/.ssh/id_ed25519，passphrase（密码）随便留空

3. **将公钥配置到GitHub：**

```bash
cat ~/.ssh/id_ed25519.pub
```

会显示出完整的公钥，复制下来添加到github上。

找到设置，ssh and GPG keys，点击new ssh key后添加进去就行了。

4. 测试

回到服务器上

```bash
ssh -T git@github.com
```

如果显示hi！则配置成功

然后接着在设定的仓库目录执行clone命令

### 3.2.3创建自动部署脚本

在服务器的仓库目录home/blog_ci里创建 deploy.sh

```bash
nano deploy.sh
```

写入以下内容：

```bash
#!/bin/bash
set -e

# 进入仓库目录
cd /home/blog_ci/myblog

# 强制同步远程 dist 分支
git fetch origin
git reset --hard origin/dist

# 直接同步 public 文件（这里 dist 分支本身就是静态文件）
rsync -av --delete ./ /var/www/myblog/

echo "博客更新完成：$(date)"
```

设置可执行权限：

```bash
chmod +x deploy.sh
```

### 3.2.4通过 Git webhook 自动触发

webhook是一种**自动化通知机制**（也叫回调函数），让一个系统（如 GitHub）在发生特定事件时，主动向另一个系统（如你的服务器）发送 HTTP 请求，服务器的 webhook 接收器收到请求后执行 deploy.sh。

当GitHub仓库发生指定事件（如代码推送、创建 Issue、合并 PR 等）时，GitHub 会自动向配置的服务器 URL 发送请求，你的服务器接收到请求后，可执行预设的操作

1. 在 GitHub（或其他 Git 仓库）中设置 **Webhook（在仓库下的settings中）**

- Payload URL：服务器地址 + 接收端口，例如 http://server_ip:5000/webhook
- Content type：application/json
- Trigger：Push events

1. 在服务器上部署一个简单的 webhook 接收器

- 创建webhook目录

```bash
mkdir -p /home/webhook
cd /home/webhook
```

- 创建webhook server文件

```bash
nano webhook.js
const express = require('express');
const { exec } = require('child_process');
const bodyParser = require('body-parser');

const app = express();

// 让 Express 能解析 JSON
app.use(bodyParser.json());

// GitHub Webhook 回调地址
app.post('/webhook', (req, res) => {
    console.log("收到 GitHub 推送事件");

    // 这里可以校验 secret（可选）
    // 如果你设置了 secret，这里要对 req.headers['x-hub-signature-256'] 校验

    // 执行你的自动部署脚本
    exec('/home/blog_ci/deploy.sh', (error, stdout, stderr) => {
        if (error) {
            console.error(`执行失败: ${stderr}`);
            return res.status(500).send('部署失败');
        }
        console.log(stdout);
        res.send('部署成功');
    });
});

// 监听端口（例如 6000）
app.listen(6000, () => {
    console.log('Webhook 服务器已启动，端口：6000');
});
```

**注意这里需要到服务器控制台去配置安全组，放行6000端口**

- 启动webhook服务

在webhook下安装express（Node.js 的一个 Web 框架）：

```bash
npm install express body-parser
```

启动：

```bash
node /home/webhook/webhook.js
```

会看到：

```bash
Webhook 服务器已启动，端口：6000
```

- 让webhook永远运行

否则 SSH 断开就停止

使用 **pm2** （是一个 **Node.js 进程管理工具**）管理：

如果直接运行node webhook.js（启动webhook监听），只要 SSH 会话断开，程序就会停止，如果程序崩溃，也不会自动重启。

```bash
npm install -g pm2
pm2 start /home/webhook/webhook.js
pm2 save
pm2 startup
```

这样 webhook 永远运行、自动重启、断线不影响。

现在就可以在本地修改博客后提交到git上，然后会直接同步到服务器中。
