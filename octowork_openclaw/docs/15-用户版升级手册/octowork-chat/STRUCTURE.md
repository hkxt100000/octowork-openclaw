# 用户版发布包结构说明

> 构建状态: **已构建** (2026-04-06)  
> 构建环境: Node.js v20.19.6 / ncc 0.38.4 / bytenode 1.5.7  
> 压缩包: `release/octowork-chat-v1.0.0-linux-x64.tar.gz` (20MB)  
> License 路径修复: 双路径兜底（开发环境 + ncc打包后均兼容）

---

## 目录树

```
octowork-chat-v1.0.0/                   ← 发布包根目录 (27MB 未压缩)
│
├── backend/                             ← 后端 (4.1MB)
│   ├── server.jsc                       ← V8 字节码 1.9MB (SHA-256: 6a344d55...)
│   ├── launcher.js                      ← 启动器（完整性校验 + bytenode 加载）
│   ├── package.json                     ← 精简依赖 (bytenode + sqlite3 + dotenv)
│   ├── .env.example                     ← 环境变量模板
│   └── build/Release/node_sqlite3.node  ← SQLite3 原生驱动
│
├── frontend/dist/                       ← 前端 (23MB)
│   ├── index.html                       ← SPA 入口
│   ├── assets/                          ← Vite 构建产物 (6.2MB)
│   │   ├── index-B_uLzX_j.js           ← 主入口 (2.8MB)
│   │   ├── App-BMGH2-fe.js             ← 应用组件 (2.0MB)
│   │   ├── helpers-rQNY3dbD.js          ← 工具库 (242KB)
│   │   ├── index-Ci5m25Hr.css           ← 样式 (350KB)
│   │   └── ...                          ← 其他 chunk
│   ├── avatars/                         ← Bot 头像 (7.2MB)
│   │   ├── 256x256/                     ← 62 张 256px 头像 (5.4MB)
│   │   ├── 64x64/                       ← 62 张 64px 头像 (604KB)
│   │   ├── bots/                        ← Bot 目录头像
│   │   └── departments/                 ← 部门头像 (808KB)
│   ├── group-avatars/                   ← 群组头像 (1.7MB, 压缩自 10MB)
│   │   ├── 128x128/                     ← 10 张
│   │   ├── 256x256/                     ← 10 张
│   │   └── 64x64/                       ← 10 张
│   ├── videos/                          ← 宣传视频 (4.6MB, 压缩自 79MB)
│   │   ├── v3-empire.mp4                ← 1.4MB (原 65MB, -98%)
│   │   ├── v4-neural-network.mp4        ← 2.7MB (原 13MB, -79%)
│   │   └── v5-deep-sea.mp4             ← 484KB (原 2.2MB, -78%)
│   ├── logo/                            ← Logo (3.1MB)
│   ├── icons/                           ← 应用图标 (456KB)
│   ├── manifest.json                    ← PWA 配置
│   └── sw.js                            ← Service Worker
│
├── start.sh                             ← 一键启动
├── install.sh                           ← 首次安装向导
├── VERSION                              ← 1.0.0
├── README.md                            ← 用户使用说明
└── license.key                          ← [用户放置] 授权文件
```

---

## 压缩效果汇总

| 资源 | 原始大小 | 压缩后 | 压缩率 | 方法 |
|------|---------|--------|--------|------|
| 视频 (3个) | 79 MB | 4.6 MB | **94%** | ffmpeg H.264 720p CRF30-32 |
| group-avatars 原图 | 9.4 MB | 0.6 MB | **94%** | ImageMagick 缩至 256x256 |
| 头像 originals | 67 MB | 删除 | **100%** | 用户版不需要原图 |
| 头像 512x512 | 19 MB | 删除 | **100%** | 256x256 足够显示 |
| **总素材** | **186 MB** | **23 MB** | **88%** | |

## 构建流程

```
开发源码 (octowork-chat-dev)             构建产物 (octowork-chat)
─────────────────────────────           ──────────────────────────
frontend/src/** (1919 modules)   Vite→   frontend/dist/assets/ (6.2MB)
frontend/public/avatars/256x256  复制→   frontend/dist/avatars/256x256
frontend/public/avatars/64x64    复制→   frontend/dist/avatars/64x64
frontend/public/videos/*       ffmpeg→   frontend/dist/videos/ (压缩)
frontend/public/group-avatars  magick→   frontend/dist/group-avatars (压缩)
backend/server.js + src/**    ncc+bc→   backend/server.jsc (V8字节码)
─                              生成→   backend/launcher.js (SHA-256)
```
