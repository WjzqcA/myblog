---
title: git
date: 2023-03-09 21:11:04
excerpt: Git 是一个分布式版本控制系统，最初由 Linux 之父 Linus Torvalds 编写，用于管理 Linux 内核代码。它现在广泛用于软件开发，用来跟踪文件的更改、协作开发代码等。
tags:
  工具
categories:
  技术
---

# git

## 一、基本架构

![](/image/git/img1.png)

### 1. **工作区（Working Directory）**

你当前看到的、编辑的文件夹内容。

### 2. **暂存区（Staging Area / Index）**

你已经准备提交的文件。

### 3. **本地仓库（Repository）**

保存提交历史的地方。

### 4. **远程仓库（Remote）**

例如 GitHub、GitLab 上的仓库，便于多人协作。

## 二、常见工作流程

![](/image/git/img2.png)

```Sheel
# 初始化本地仓库（如果是新项目）
git init

# 克隆远程仓库（如果已有项目）第一次获取项目代码，把整个远程仓库下载到本地
git clone <远程地址>

# 查看当前状态
git status

# 添加文件到暂存区
git add <文件名>
git add .           # 添加所有变更

# 提交到本地仓库
git commit -m "提交信息"

# 查看提交记录
git log

# 推送到远程仓库
git push origin main

# 从远程拉取代码 更新已有的本地仓库，拉取远程的最新代码并合并到当前分支
# 从名为 origin 的远程仓库中，拉取 main 分支的最新代码，并合并到我当前所在的分支上
git pull origin main
```

## 三、分支

在 Git 中，**分支就是对代码版本的一种并行开发线**。可以在分支上写新功能、修复 bug、做实验，不影响主分支。

✅ **本质：分支就是指向某一次提交（commit）的指针。**当你创建新分支时，Git 并不会复制整个项目，而是建立一个新的指针，让你从某个提交点开始独立开发

```Sheel
# 查看所有分支
git branch

# 创建新分支
git branch dev

# 切换分支
git checkout dev

# 创建并切换
git checkout -b dev

# 合并分支 
git checkout main
git merge dev#把 dev 分支的内容合并到当前分支

# 删除分支
git branch -d dev
git branch -D dev(强制删除)
```

⚔️ 如果在合并分支时文件内容出现冲突怎么办？

如果两边对同一个文件的同一位置都做了不同修改，Git 会在bash中提示**冲突**，需要自己手动解决

```shell
<<<<<<< HEAD

这是当前分支的内容
=======

这是 dev 分支的内容

>>>>>>> dev
```

手动修改后提交：

```
git add 冲突的文件
git commit -m "解决合并冲突"
```

## 四、与远程仓库（gitHub）交互

远程仓库与本地仓库连接：https://blog.51cto.com/u_16213588/9890428

- 查看远程仓库：git remote

- 与远程仓库链接：git remote add origin https://github.com/WjzqcA/pytorch.git

- 推送到远程仓库（先创建自己的远程仓库）：

​	git push <远程仓库名> <本地分支名>:<远程分支名>，如果本地分支名和远程分支名相同可以省略远程分支名。

​	如果远程仓库中还没有 `feature-x` 分支，执行以上命令会自动在远程创建该分支。

- 建立本地分支和远程分支的映射：

​	第一次推送一个新分支时，可以用git push -u origin feature-x，参数 `-u` 或 `--set-upstream` 会设置本地 `feature-x` 分支与远程 	origin/feature-x 分支关联起来。这样就可以直接使用git push推送到对应分支

- 查看远程仓库与本地仓库分支的对应关系：git branch -vv

## 五、Idea使用git

创建本地仓库：vcs→create git respository，选择项目的根目录

![](/image/git/img3.png)

提交文件代码到本地仓库：点击绿色对号提交所选择的文件

关联远程仓库：在平台创建远程仓库获得链接，idea中点击绿色箭头push进行关联

![](/image/git/img4.png)
