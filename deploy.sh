#!/bin/bash
# 自动部署 Hexo 到 Git (EdgeOne 会自动拉取仓库部署)

# 配置
BRANCH="dist"               # 存放静态文件的分支
REPO="git@github.com:WjzqcA/myblog.git"  # 你的仓库地址
MESSAGE="update blog"       # 默认提交信息

# 如果用户有输入提交信息，替换默认
if [ -n "$1" ]; then
  MESSAGE="$1"
fi

echo ">>> 清理旧文件"
hexo clean

echo ">>> 生成静态文件"
hexo generate

echo ">>> 进入 public 目录"
cd public || exit

# 如果还没初始化过 Git 仓库，自动配置
if [ ! -d ".git" ]; then
  echo ">>> 初始化 Git 仓库"
  git init
  git remote add origin $REPO
  git checkout -b $BRANCH
fi

echo ">>> 提交代码到 $BRANCH 分支"
git add .
git commit -m "$MESSAGE"
git push origin $BRANCH -f

echo ">>> 部署完成，EdgeOne 会自动拉取最新版本"