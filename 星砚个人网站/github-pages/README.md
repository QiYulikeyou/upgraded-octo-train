# 星砚 · 可交互个人简历

一个纯静态的可交互个人简历站点，构建产物直接托管在 GitHub Pages。

## 在线访问

**https://qiyulikeyou.github.io/improved-meme/**

> 仓库为子路径部署（仓库名 `improved-meme`）。站点资源引用为绝对路径 `/improved-meme/assets/...`，
> 是构建时按 `CLIENT_BASE_PATH=/improved-meme/` 生成的，**不要改仓库名、也不要迁移到根路径**，否则资源会 404。

## 内容

- **个人档案**：星砚 · 男 · 设计助理方向
- **个人优势**：AI辅助设计 / AI获客 / 网站制作 / 智能客服搭建 / Photoshop / AutoCAD / codex / comfyui
- **作品展示**、**教育经历**、**证书**、**技能**等区块
- **留言板**：可提交留言（需后端，静态托管下该功能不可用）
- **主题切换**：极光流金 / 暖调精致 / 暖调深夜
- **智能客服挂件**：右下角气泡，接入 AI 客服

## 技术栈

React 19 + Vite 8（rolldown）+ Tailwind CSS 4 + react-router 7，构建产物为纯静态文件。

## 目录结构

```
index.html          入口页
404.html            SPA 路由回退（GitHub Pages 无服务端路由，直接复用入口页）
assets/             构建产物（JS / CSS / 图片）
favicon.svg         站点图标
routes.json         路由清单
.nojekyll           关闭 Jekyll 处理
```

## 本地预览

```bash
python -m http.server 8000
# 打开 http://127.0.0.1:8000/
```

## 说明

- 站点资源引用为**绝对路径**（`/assets/...`）。若部署在子路径下，需要以对应 base 重新构建，
  不能直接沿用根路径产物。
- 留言板与智能客服依赖后端服务；仅浏览静态内容时不受影响。
