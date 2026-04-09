# OctoWork 聊天管理器 v1.0.0

> AI 团队协作的核心交互界面  
> 平台: macOS / Linux | 要求: Node.js >= 18.0.0

---

## 快速开始

### 1. 解压安装

```bash
tar -xzf octowork-chat-v1.0.0.tar.gz -C ~/
cd ~/octowork-chat
./install.sh
```

### 2. 首次激活

首次启动时程序会显示 **机器指纹**，将指纹发给管理员获取 `license.key`：

```bash
# 放到发布包根目录
cp license.key ~/octowork-chat/license.key
```

### 3. 启动

```bash
cd ~/octowork-chat
./start.sh
```

浏览器访问: **http://127.0.0.1:1314**

### 4. 停止

终端按 `Ctrl+C`

---

## 前置条件

| 依赖 | 要求 | 安装 |
|------|------|------|
| Node.js | 18.x 或 20.x LTS | `brew install node` 或 https://nodejs.org/ |
| 数字公寓 | `~/octowork/` 目录 | 需预先安装 OctoWork 数字公寓 |

---

## 目录结构

```
octowork-chat/
├── backend/
│   ├── server.jsc              V8 字节码（后端核心，不可读）
│   ├── launcher.js             启动器
│   ├── package.json            依赖声明
│   ├── build/Release/          sqlite3 原生模块
│   └── .env.example            环境变量模板
├── frontend/dist/              前端构建产物
│   ├── index.html              入口页面
│   ├── assets/                 JS/CSS（压缩）
│   ├── avatars/                AI Bot 头像（316张）
│   ├── group-avatars/          群组头像（42张）
│   ├── logo/                   Logo 资源
│   ├── icons/                  图标
│   └── videos/                 宣传视频（可选）
├── license.key                 授权文件（管理员提供）
├── start.sh                    一键启动
├── install.sh                  安装向导
├── VERSION                     版本号
└── README.md                   本文件
```

---

## 升级

```bash
# 1. Ctrl+C 停止
# 2. 备份
mv ~/octowork-chat ~/octowork-chat-backup-$(date +%Y%m%d)
# 3. 解压新版本
tar -xzf octowork-chat-v1.1.0.tar.gz -C ~/
# 4. 恢复授权
cp ~/octowork-chat-backup-*/license.key ~/octowork-chat/
# 5. 安装 + 启动
cd ~/octowork-chat && ./install.sh && ./start.sh
```

> 升级不影响 `~/octowork/` 数字公寓中的任何数据。

---

## 常见问题

| 问题 | 解决 |
|------|------|
| 端口被占用 | `lsof -i :1314` 查看并 `kill <PID>` |
| 数字公寓不存在 | 确认 `~/octowork/` 或设置 `export OCTOWORK_WORKSPACE=/your/path` |
| 查看版本 | `cat VERSION` 或 `curl http://127.0.0.1:1314/api/system/version` |
| 授权过期 | 联系管理员获取新 `license.key`，替换后重启 |

---

*OctoWork AI Team — 让团队协作更智能*
