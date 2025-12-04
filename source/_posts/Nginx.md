---
title: Nginx
date: 2023-04-19 12:11:40
excerpt: Nginx 是一个高性能的开源 Web 服务器软件，也可以用作反向代理、负载均衡器和 HTTP 缓存。它以高效、轻量级和高并发处理能力著称，广泛用于互联网应用中。
tags:
  中间件
categories:
  - 技术
---

# Nginx

Nginx 是一个高性能的开源 Web 服务器软件，也可以用作反向代理、负载均衡器和 HTTP 缓存。它以高效、轻量级和高并发处理能力著称，广泛用于互联网应用中。（**客户端请求发送到 Nginx，Nginx 根据配置将动态请求转发到 Tomcat 处理，Tomcat 返回结果后，Nginx 再将响应返回给客户端**）

Nginx 的主要功能包括：

- **Web 服务器**：处理 HTTP/HTTPS 请求，服务静态文件（如 HTML、CSS、JavaScript、图片等）。
- **反向代理**：将客户端请求转发到后端服务器（如应用服务器或 API）。
- **负载均衡**：将流量分发到多个后端服务器，提高系统可用性和性能。
- **HTTP 缓存**：缓存动态或静态内容，减少后端服务器压力。
- **邮件代理**：支持 IMAP/POP3/SMTP 协议的代理。
- **其他功能**：支持 WebSocket、HTTP/2、gRPC 等现代协议，以及模块化扩展。

# 重要功能

## 一、反向代理

正向代理（VPN），**代理客户端，**将客户端的请求发送到代理服务器，正向代理服务器代替客户端向目标服务器发起请求后将响应返回给客户端。客户端明确知道自己通过代理访问目标服务器。

![image.png](/image/nginx/img1.png)

反向代理是位于客户端和后端服务器之间的代理服务器，代表后端服务器接收客户端请求并决定将请求分发到哪个后端服务器。客户端通常不知道后端服务器的存在。

![image.png](/image/nginx/img1.png)

## 二、负载均衡

负载均衡（Load Balancing）是一种将客户端请求分发到多个后端服务器的技术，旨在提高系统的性能、可靠性和可扩展性。

Nginx 负载均衡的基本工作流程如下：

1. 客户端发送请求到 Nginx（反向代理服务器）。
2. Nginx 根据配置的负载均衡策略（轮询、加权轮询、最少连接、IP 哈希等），选择一个后端服务器。
3. Nginx 将请求转发到选定的后端服务器。
4. 后端服务器处理请求并返回响应给 Nginx。
5. Nginx 将响应返回给客户端。

![image.png](/image/nginx/img1.png)

## 三、动静分离

动静分离是 Nginx 常用的一种优化策略，指将静态资源（如 HTML、CSS、JavaScript、图片、视频等）和动态资源（如通过后端服务器生成的 PHP、Java、Python 页面或 API 响应）的处理分开，由 Nginx 直接处理静态资源请求，而将动态请求转发到后端服务器（如 Tomcat、Node.js、Django）。这种方式可以显著提高 Web 应用的性能和效率

在 Web 应用中，客户端请求可以分为两类：

- **静态资源**：内容固定、不需要服务器端计算的文件（如图片、CSS、JS、HTML），存储在服务器文件系统或 CDN 上。
- **动态资源**：需要后端服务器处理后生成的内容（如数据库查询结果、动态渲染的页面）。

动静分离的核心思想是：

- **Nginx 直接处理静态资源**：Nginx 作为高性能 Web 服务器，擅长处理静态文件请求，响应速度快，资源占用低。
- **动态请求转发到后端**：将需要计算或数据库操作的请求通过反向代理转发给后端应用服务器（如 Tomcat、Gunicorn）。
- **分离处理**：通过 Nginx 的 location 配置规则，将请求按类型分发到不同的处理路径。

### **工作流程**

1. 客户端发送请求到 Nginx。
2. Nginx 根据请求的 URL 路径或文件扩展名判断是静态资源还是动态请求：
   - 如果是静态资源（如 .jpg、.css），Nginx 直接从本地文件系统读取并返回。
   - 如果是动态请求（如 /api、.php），Nginx 通过 proxy_pass 转发到后端服务器。
3. 后端服务器处理动态请求并返回结果，Nginx 将响应传递给客户端。

- **静态资源**：客户端 （静态资源请求）→ Nginx → 直接读取文件 → 客户端。
- **动态资源**：客户端 （动态资源请求）→ Nginx → 转发到 Tomcat → Tomcat 处理 → Nginx → 客户端。

# 常用命令

nginx-1.28.0\conf 下的 nginx.conf 是配置文件，修改后需要重新加载才能生效

## Linux

```bash
sudo systemctl start nginx #启动或 sudo nginx
sudo systemctl stop nginx #立即终止 sudo nginx -s stop
sudo nginx -s quit #安全停止 等待当前连接处理完成后停止
sudo systemctl reload nginx #重新加载配置文件 sudo nginx -s reload
ps aux | grep nginx #输出示例：显示主进程（master）和工作进程（worker）
sudo nginx -t #检查配置文件语法是否正确
```

## Windows

```bash
nginx #启动或 start nginx
nginx -s stop #立即终止
nginx -s quit #安全停止
nginx -s reload #重新加载配置文件
tasklist | findstr nginx #输出示例：显示 nginx.exe 的进程 ID（PID）
nginx -t #检查配置文件语法是否正确。
```
