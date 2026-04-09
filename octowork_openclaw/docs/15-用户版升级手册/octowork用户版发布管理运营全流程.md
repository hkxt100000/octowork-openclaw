# OctoWork 用户版发布管理运营全流程

> 适用对象: **本地 AI 助手**（Cursor / Claude / ChatGPT / GenSpark 等 AI 开发工具）  
> 核心目标: AI 看完本文档，就能独立完成从开发 → 打包 → 部署到用户电脑 → 用户自动更新的全链路  
> 最后更新: 2026-04-08  
> 维护者: 章鱼博士

---

## 当前项目状态（AI 必读）

| 项目 | 状态 | 说明 |
|------|------|------|
| 当前版本 | **v1.1.5** | VERSION 文件记录 |
| 开发中版本 | **v1.2.0** | 下一个功能迭代版本（CHANGELOG.md [Unreleased]） |
| 前端框架 | Vue 3 + Vite + TypeScript | 端口 5888（开发）/ 1314（生产，后端托管） |
| 后端框架 | Node.js + Express + WebSocket + SQLite | 端口 1314 |
| 通知中心 | ✅ 已完成 | NotificationPanel / UpdateBanner / UpdateDialog / releases.json / releaseNotificationService.js |
| 版本检测 | ✅ 已完成 | useVersionCheck.ts + checker.js（双平台：Gitee 优先 → GitHub 兜底）+ manifest.json |
| 构建脚本 | ✅ 已完成 | tools/build-release.sh（11 步，含自动部署到 ~/octowork-chat/） |
| 自动部署 | ✅ 已完成 | 构建完自动同步产物到本地发布仓库 ~/octowork-chat/ |
| License 系统 | ✅ 已完成 | 机器指纹 + HMAC 签名 + 有效期 |
| 双平台发布 | ✅ 已完成 | GitHub（国际）+ Gitee（国内）双仓库同步发布 |
| 用户版发布 | 🔲 待 Jason 手动 | 需上传 tar.gz 到 GitHub/Gitee Release |

---

## 全局概览：你在哪、你要做什么、结果去哪

```
                          ┌─────────────────────────┐
                          │   你在这里操作（AI）       │
                          │   octowork-chat-dev      │
                          │   (GitHub 私有仓库)       │
                          └───────────┬─────────────┘
                                      │
                    bash tools/build-release.sh X.Y.Z
                                      │
                                      ▼
                          ┌─────────────────────────┐
                          │   构建产物                │
                          │   release/octowork-chat- │
                          │   vX.Y.Z.tar.gz (~20MB) │
                          └───────────┬─────────────┘
                                      │
                          ┌───────────┴─────────────┐
                          │ [自动] Step 11           │
                          │ 构建脚本自动复制产物到   │
                          │ ~/octowork-chat/         │
                          │ + 同步 releases.json     │
                          │ + 保留 .git/license.key  │
                          │   /manifest.json         │
                          └───────────┬─────────────┘
                                      │
                    Jason 只需: cd ~/octowork-chat
                    git commit → git push → 创建 Release
                    + 推送到 Gitee 镜像
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
          ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
          │ GitHub Release│  │ Gitee Release │  │ manifest.json     │
          │ (国际用户)    │  │ (国内用户)    │  │ + releases.json   │
          └──────┬───────┘  └──────┬───────┘  │ (双平台各一份)     │
                 │                 │          └────────┬──────────┘
                 └────────────┬────┘                   │
                              ▼                        │
                    ┌─────────────────────────┐        │
                    │   用户电脑               │        │
                    │   ~/octowork-chat/      │◄───────┘
                    │   解压 → install.sh     │  checker.js 双平台拉取
                    │   → start.sh → 使用     │  先 Gitee → 再 GitHub
                    └─────────────────────────┘  检测新版本
```

### 三条铁律

1. **`octowork-chat-dev`** 是开发仓库 — 源码、构建工具、文档全在这里，你只操作这个
2. **`octowork-chat`** 是发布仓库（GitHub + Gitee 双平台）— 放编译后程序 + manifest.json + releases.json，不放源码
3. **`~/octowork/`** 是用户数据（数字公寓）— 绝不覆盖、绝不碰

### 双平台仓库地址

| 仓库 | 平台 | 地址 | 用途 |
|------|------|------|------|
| 开发仓库 | GitHub (私有) | `git@github.com:octoworkai/octowork-chat-dev.git` | AI 开发操作 |
| 发布仓库 | GitHub (公开) | `git@github.com:octoworkai/octowork-chat.git` | 国际用户下载 + 版本检测 |
| 发布仓库 | Gitee (公开) | `git@gitee.com:octowork/octowork-chat.git` | 国内用户下载 + 版本检测（优先） |

---

## 第一部分：仓库与目录结构

### 1.1 开发仓库结构（octowork-chat-dev）

```
octowork-chat-dev/                    ← 你在这里操作
├── backend/
│   ├── server.js                     ← 主程序入口 (~1224 行)
│   ├── data/
│   │   └── releases.json             ← 通知数据源（发版/运营通知的唯一数据源）
│   ├── services/
│   │   └── releaseNotificationService.js  ← 通知服务（读取 releases.json）
│   ├── src/
│   │   ├── license/
│   │   │   ├── constants.js          ← LICENSE_SECRET + 双路径兜底
│   │   │   └── verifier.js           ← 启动校验逻辑
│   │   ├── updater/
│   │   │   └── checker.js            ← 版本检查（拉取远程 manifest.json）
│   │   └── utils/
│   │       └── fingerprint.js        ← 机器指纹生成
│   └── db/database.js                ← SQLite 数据库
├── frontend/
│   ├── vite.config.web.ts            ← 生产构建配置
│   ├── src/renderer/
│   │   ├── composables/
│   │   │   ├── useVersionCheck.ts    ← 版本检测 composable
│   │   │   └── useNotifications.ts   ← 通知 composable
│   │   └── components/
│   │       ├── Notification/
│   │       │   ├── NotificationPanel.vue       ← 通知面板
│   │       │   ├── NotificationDetailDialog.vue← 通知详情弹窗
│   │       │   └── UpdateBanner.vue            ← 版本更新横幅
│   │       └── Dialogs/
│   │           └── UpdateDialog.vue            ← 版本升级弹窗
│   └── public/                       ← 静态资源（已压缩，~18MB）
├── tools/
│   ├── build-release.sh              ← 构建脚本（11 步，含自动部署到 ~/octowork-chat/）
│   ├── generate-license.js           ← License 生成工具
│   ├── dev-start.sh                  ← 开发版一键启动
│   ├── start.sh                      ← 用户版启动脚本
│   └── install.sh                    ← 用户版安装脚本
├── VERSION                           ← 当前版本号（如 "1.0.0"）
├── CHANGELOG.md                      ← 更新日志
├── config.json                       ← 开发环境配置（不进入发布包）
└── docs/
    └── 15-用户版升级手册/
        └── octowork用户版发布管理运营全流程.md  ← 本文档
```

### 1.2 用户电脑最终目录

```
~/
├── .openclaw/                ← AI 执行引擎（预装，我们不碰）
├── octowork/                 ← 数字公寓（用户数据，绝不覆盖）
│   ├── config/ai-directory.json
│   ├── data/chat.db
│   └── departments/
└── octowork-chat/            ← 我们交付的程序（整包替换升级）
    ├── backend/
    │   ├── server.jsc        ← V8 字节码（核心逻辑，不可读）
    │   ├── launcher.js       ← SHA-256 校验 + bytenode 启动器
    │   ├── package.json      ← 精简依赖 (bytenode + sqlite3)
    │   ├── .env.example
    │   └── build/Release/node_sqlite3.node
    ├── frontend/dist/        ← 前端静态资源
    ├── license.key           ← 授权文件（用户保留，升级时要复制回来）
    ├── start.sh
    ├── install.sh
    ├── VERSION
    └── README.md
```

### 1.3 构建产物结构

```
release/octowork-chat-vX.Y.Z/            ← ~27MB 解压后
├── backend/                               ← ~4.1MB
│   ├── server.jsc                         ← V8 字节码 ~1.9MB
│   ├── launcher.js                        ← SHA-256 校验启动器
│   ├── package.json                       ← 精简依赖
│   ├── .env.example                       ← 空模板
│   └── build/Release/node_sqlite3.node    ← SQLite3 native 驱动
├── frontend/dist/                         ← ~23MB
│   ├── index.html
│   ├── assets/                            ← JS/CSS ~6.2MB
│   ├── avatars/                           ← Bot 头像 ~7.2MB
│   ├── group-avatars/                     ← 群组头像 ~1.7MB
│   ├── videos/                            ← 宣传视频 ~4.6MB
│   ├── logo/                              ← Logo ~3.1MB
│   └── icons/                             ← 图标 ~456KB
├── start.sh                               ← 一键启动
├── install.sh                             ← 首次安装
├── VERSION                                ← "X.Y.Z"
└── README.md                              ← 用户说明
```

---

## 第二部分：发版全流程（AI 执行 + Jason 手动）

### 场景：Jason 说"帮我发 X.Y.Z 版本"

### Step 1: 确保代码最新

```bash
cd ~/octowork-chat-dev
git checkout main && git pull
```

### Step 2: 更新版本号 + CHANGELOG

```bash
# 更新版本号
echo "X.Y.Z" > VERSION

# 更新 CHANGELOG.md —— 将 [Unreleased] 改为正式版本号 + 日期
# 例如：## [Unreleased] — v1.1.0 开发中  →  ## [1.1.0] — 2026-04-10
```

### Step 3: 更新 releases.json（通知数据源）

编辑 `backend/data/releases.json`：

```json
{
  "notifications": [
    {
      "id": "release-vX.Y.Z",
      "type": "release",
      "title": "vX.Y.Z - 版本标题",
      "date": "2026-04-10",
      "version": "X.Y.Z",
      "summary": "一句话描述本次更新核心内容",
      "content": "### 新功能\n- 功能A\n- 功能B\n\n### 修复\n- 修复C",
      "downloadUrl": "",
      "importance": "high",
      "tags": ["feature", "auto-update"]
    }
    // ... 保留旧的通知条目
  ],
  "latest_version": "X.Y.Z",      ← 改为新版本号
  "minimum_version": "1.0.0",      ← 最低兼容版本（通常不改）
  "notification_types": { ... }     ← 不改
}
```

> **重要**：`latest_version` 必须更新！前端通知系统根据这个字段检测是否有新版本。

### Step 4: 一键构建

```bash
bash tools/build-release.sh X.Y.Z
```

等待 ~30-40 秒，脚本自动完成 11 步：

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 前置检查 | node / ncc / bytenode 是否安装 |
| 2 | 硬编码门禁 | grep 扫描源码，发现硬编码路径立即中止 |
| 3 | 清理旧构建 | `rm -rf release/ build-tmp/` |
| 4 | 前端构建 | `npm ci && vite build --config vite.config.web.ts` |
| 5 | 后端打包 | `npx ncc build server.js -o build-tmp/ --minify` |
| 6 | 字节码编译 | `npx bytenode --compile` → server.jsc |
| 7 | 生成哈希 | SHA-256 防篡改校验值 |
| 8 | 生成 launcher.js | 内嵌哈希的启动器 |
| 9 | 复制脚本文件 | start.sh / install.sh / VERSION / README |
| 10 | 打包压缩 | `tar -czf octowork-chat-vX.Y.Z.tar.gz` |
| **11** | **自动部署到本地发布仓库** | **复制产物 → ~/octowork-chat/，同步 releases.json，保留 .git + license.key + manifest.json** |

### Step 5: 验证产物

```bash
# 压缩包大小应 ~20MB
ls -lh release/octowork-chat-vX.Y.Z.tar.gz

# 版本号正确
cat release/octowork-chat-vX.Y.Z/VERSION

# 字节码存在
ls -la release/octowork-chat-vX.Y.Z/backend/server.jsc

# 文件数量 ~310
tar tzf release/octowork-chat-vX.Y.Z.tar.gz | wc -l

# 关键文件全在
tar tzf release/octowork-chat-vX.Y.Z.tar.gz | grep -E "server.jsc|launcher.js|index.html|start.sh"

# 计算 SHA-256（发布时需要）
shasum -a 256 release/octowork-chat-vX.Y.Z.tar.gz
```

### Step 6: 安全检查

```bash
# config.json 不能在包里
tar tzf release/octowork-chat-vX.Y.Z.tar.gz | grep config.json
# 应无结果

# .env 不能在包里
tar tzf release/octowork-chat-vX.Y.Z.tar.gz | grep "\.env$"
# 应无结果

# 密钥不可提取
strings release/octowork-chat-vX.Y.Z/backend/server.jsc | grep "LICENSE_SECRET"
# 应无结果
```

### Step 7: 提交 + 打 Tag

```bash
git add VERSION CHANGELOG.md backend/data/releases.json
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
git push && git push --tags
```

### Step 8: 告诉 Jason（生成发布报告）

构建脚本 Step 11 已自动将产物部署到 `~/octowork-chat/`，releases.json 也已同步。Jason 只需 3 步：

```
✅ 构建完成 — OctoWork vX.Y.Z

产物:   release/octowork-chat-vX.Y.Z.tar.gz
大小:   XX MB
SHA-256: xxxxxxxx...
文件数: ~310 个

✅ 已自动部署到 ~/octowork-chat/（releases.json 已同步）

Jason 只需 3 步:
1. cd ~/octowork-chat
   编辑 manifest.json（更新版本号 + SHA-256 + 下载链接）

2. git add -A && git commit -m "release: vX.Y.Z" && git push

3. 到 GitHub/Gitee 创建 Release 并上传 tar.gz:
   - https://github.com/octoworkai/octowork-chat/releases/new
   - https://gitee.com/octoworkai/octowork-chat/releases/new
```

---

## 第三部分：部署到用户电脑（更新 ~/octowork-chat/）

### 3.1 用户首次安装

用户从 GitHub/Gitee Release 页面下载 `octowork-chat-vX.Y.Z.tar.gz`，然后：

```bash
# 1. 解压
tar -xzf octowork-chat-vX.Y.Z.tar.gz -C ~/
mv ~/octowork-chat-vX.Y.Z ~/octowork-chat

# 2. 安装依赖
cd ~/octowork-chat
./install.sh
#   → [1/4] 检查 Node.js (需 18.x 或 20.x LTS)
#   → [2/4] 检查 ~/octowork/ 数字公寓
#   → [3/4] npm install --production
#   → [4/4] 安装完成

# 3. 首次启动 → 显示机器指纹
./start.sh
#   → "您的机器指纹: 0e2d03f5eb955c61c4bb3a0895ccbe38"
#   → 把指纹发给管理员

# 4. 收到 license.key → 放到根目录 → 重启
cp license.key ~/octowork-chat/
./start.sh
#   → "🔑 授权校验通过"
#   → 浏览器打开 http://127.0.0.1:1314
```

### 3.2 用户版本升级（手动方式 — 当前 v1.0）

```bash
# 1. 停止服务 (Ctrl+C)

# 2. 备份旧版本（保留 license.key）
cp ~/octowork-chat/license.key ~/license.key.backup
mv ~/octowork-chat ~/octowork-chat-backup-$(date +%Y%m%d)

# 3. 下载并解压新版本
tar -xzf octowork-chat-vX.Y.Z.tar.gz -C ~/
mv ~/octowork-chat-vX.Y.Z ~/octowork-chat

# 4. 恢复 license
cp ~/license.key.backup ~/octowork-chat/license.key

# 5. 安装依赖 + 启动
cd ~/octowork-chat
./install.sh && ./start.sh
```

> **关键点**：`~/octowork/`（数字公寓）里的聊天记录、配置、数据库完全不受影响。
> 升级只替换 `~/octowork-chat/`（程序本身），仅需保留 `license.key`。

### 3.3 自动更新检测机制（已内置 · 双平台 v2.0）

用户版已内置版本检测，支持**双平台检测**（Gitee 优先 → GitHub 兜底），无需用户操作即可发现新版本：

```
后端启动 → 延迟 10s → checker.js 双平台拉取 manifest.json
         │            ├── 先尝试 Gitee（国内快，8s 超时）
         │            └── 失败再尝试 GitHub（国际兜底，15s 超时）
         → 每 6h 自动轮询
         → API: GET /api/system/check-update
         → 返回格式: { success: true, data: { hasUpdate, current, latest, ... } }

前端打开 → 延迟 15s → useVersionCheck 调用 check-update API
         → 解析 response.data.data（嵌套 data 字段）
         → useNotifications 拉取 releases.json 通知列表
         → 发现新版本 → ChatHeader 顶部显示 UpdateBanner
         → 驾驶舱铃铛显示未读红标
         → 每 6h 自动轮询检查
```

**数据流（双平台）**：
```
┌─────────────────────────┐     ┌─────────────────────────┐
│ Gitee 发布仓库（国内优先） │     │ GitHub 发布仓库（国际兜底）│
│ manifest.json            │     │ manifest.json            │
│ releases.json            │     │ releases.json            │
└───────────┬─────────────┘     └───────────┬─────────────┘
            │                               │
            └───────────┬───────────────────┘
                        ▼
              checker.js（先 Gitee → 失败再 GitHub）
              releaseNotificationService.js（同上）
                        │
                        ▼
              用户后端 API
              ├── /api/system/version         → { success, version, node, platform }
              ├── /api/system/check-update    → { success, data: { hasUpdate, current, latest, ... } }
              ├── /api/system/notifications    → 通知列表
              └── /api/system/notifications/unread-count → 未读计数
                        │
                        ▼
              用户前端 UI
              ├── UpdateBanner（顶部横幅："检测到新版本 vX.Y.Z - 一键升级"）
              ├── NotificationPanel（铃铛面板：版本更新 + 公告 + 技巧等）
              └── UpdateDialog（弹窗：changelog + 下载按钮）
```

**关键代码文件**：

| 文件 | 作用 |
|------|------|
| `backend/src/updater/checker.js` | 双平台拉取 manifest.json（Gitee 8s → GitHub 15s） |
| `backend/services/releaseNotificationService.js` | 双平台拉取 releases.json（Gitee → GitHub） |
| `frontend/src/renderer/composables/useVersionCheck.ts` | 前端版本检测（15s 延迟 + 6h 轮询） |
| `frontend/src/renderer/components/Notification/UpdateBanner.vue` | 顶部更新横幅 |
| `frontend/src/renderer/components/Dialogs/UpdateDialog.vue` | 版本升级弹窗 |

### 3.4 让用户实现自动更新的完整链路

要让用户能自动接收更新提醒并一键升级，AI 发版时需要确保以下三个文件同步更新：

| 文件 | 位置 | 更新内容 | 作用 |
|------|------|---------|------|
| `releases.json` | 开发仓库 `backend/data/` + 发布仓库根目录 | 添加 release 通知条目 + 更新 `latest_version` | 前端通知面板展示更新内容 |
| `manifest.json` | 发布仓库 `octowork-chat` 根目录 | 更新版本号 + 下载链接 + SHA-256 | 后端版本检测 + 下载地址 |
| `VERSION` | 开发仓库根目录 | 更新版本号 | 构建脚本读取 |

**发版后用户端自动触发流程**：

```
1. 用户打开 OctoWork（或后端 10s 启动检查 / 6h 定时轮询）
2. checker.js 双平台拉取 manifest.json:
   ├── 先 Gitee: https://gitee.com/octowork/octowork-chat/raw/main/manifest.json
   └── 失败再 GitHub: https://raw.githubusercontent.com/octoworkai/octowork-chat/main/manifest.json
3. 比较 manifest.latest > 本地 VERSION → 有新版
4. 后端 API 返回: { success: true, data: { hasUpdate: true, current, latest, ... } }
5. 前端 useVersionCheck 解析 response.data.data → 设置 versionInfo
6. 前端展示：
   - ChatHeader 顶部出现蓝色横幅："检测到新版本 vX.Y.Z - 一键升级"
   - 驾驶舱铃铛出现红标数字
   - 用户点击 → 显示 UpdateDialog（更新日志 + 下载按钮）
7. 用户下载 tar.gz → 按 3.2 节步骤升级
```

> **未来规划（P2）**：`updater.js` 全自动升级 — 后端直接下载 tar.gz、解压替换、重启。
> 当前为半自动模式（自动检测 + 提示 + 手动下载替换）。

---

## 第四部分：日常运营（不发版也能推送通知）

### 4.1 releases.json 是唯一的运营数据源

不需要发新版本也能给所有用户推送通知！只需编辑 `releases.json` 并推送到发布仓库。

### 4.2 添加运营通知（8 种类型）

编辑 `backend/data/releases.json` 的 `notifications` 数组，添加一条新通知：

```json
{
  "id": "unique-id-yyyymmdd",
  "type": "announcement",
  "title": "通知标题",
  "date": "2026-04-10",
  "summary": "一句话摘要",
  "content": "### 详细内容\n支持 Markdown 格式\n- 列表\n- **加粗**\n- `代码`",
  "importance": "medium",
  "tags": ["标签1", "标签2"]
}
```

### 4.3 通知类型速查

| type | 图标 | 用途 | 示例 |
|------|------|------|------|
| `release` | 🚀 | 版本更新 | "v1.1.0 - 通知中心上线" |
| `announcement` | 📢 | 官方公告 | "企微 CRM 集成开发中" |
| `feature` | ✨ | 功能预告 | "AI 技能市场新技能预告" |
| `tip` | 💡 | 使用技巧 | "Alt+1~7 切换聊天模式" |
| `maintenance` | 🔧 | 维护通知 | "4/10 凌晨系统维护" |
| `promotion` | 🎁 | 活动推广 | "新用户体验活动" |
| `academy` | 📚 | 学院动态 | "章鱼学院即将上线" |
| `skill` | 🧩 | 技能上新 | "SEO 分析技能上线" |

### 4.4 运营通知推送流程（不发版）

```bash
# 1. 编辑开发仓库的 releases.json
cd ~/octowork-chat-dev
# 在 backend/data/releases.json 的 notifications 数组顶部添加新通知

# 2. 提交到开发仓库
git add backend/data/releases.json
git commit -m "notify: 添加XX公告"
git push

# 3. 复制到发布仓库（让用户能拉到）
# 把 releases.json 推送到 octowork-chat 仓库根目录
# Jason 手动操作 或 用 gh CLI
#
# 注意：如果是正式发版（使用 build-release.sh），Step 11 会自动
# 将 releases.json 同步到 ~/octowork-chat/，无需手动复制
```

### 4.5 importance 字段说明

| 值 | 效果 |
|------|------|
| `high` | 通知面板置顶 + 铃铛强提醒 |
| `medium` | 正常显示 |
| `low` | 低优先级，列表靠后 |

### 4.6 release 类型的特殊字段

`type: "release"` 的通知需要额外字段：

```json
{
  "type": "release",
  "version": "X.Y.Z",           ← 必须，前端用来匹配版本
  "downloadUrl": "https://...",  ← 可选，升级按钮的下载地址
  // ...其他通用字段
}
```

---

## 第五部分：License 管理

### 5.1 生成 License

```bash
cd ~/octowork-chat-dev

node tools/generate-license.js \
  --fingerprint=0e2d03f5eb955c61c4bb3a0895ccbe38 \
  --customer=张三 \
  --company=某某公司 \
  --expire=2027-12-31 \
  --plan=standard \
  --output=license.key
```

### 5.2 参数速查

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `--fingerprint` | **是** | — | 客户机器指纹（启动时显示的 32 位 hex） |
| `--customer` | **是** | — | 客户姓名 |
| `--company` | 否 | 空 | 公司名称 |
| `--expire` | 否 | 6 个月后 | 过期日期 YYYY-MM-DD |
| `--plan` | 否 | test | test / standard / enterprise |
| `--max-devices` | 否 | 1 | 最大设备数 |
| `--output` | 否 | ./license.key | 输出路径 |

### 5.3 License 校验链

```
launcher.js
  │ 1. 读取 server.jsc → SHA-256 校验 → 不匹配则拒绝启动
  │ 2. require('bytenode') + require('./server.jsc')
  ▼
server.jsc (verifier.js)
  │ 3. 读取 license.key → Base64 解码 → JSON 解析
  │ 4. HMAC-SHA256 验签 → 防伪造
  │ 5. 比对机器指纹 → 防复制
  │ 6. 检查过期时间 → 到期提醒/拒绝
  ▼
  校验通过 → 启动 Express → 托管前端 → 监听 1314 端口
```

---

## 第六部分：配置安全保障

### 6.1 什么会进入发布包，什么不会

| 文件 | 是否进入发布包 | 原因 |
|------|--------------|------|
| `config.json` | **❌ 不会** | `readFileSync` 运行时读取，ncc 不内联 |
| `backend/.env` | **❌ 不会** | .gitignore 排除 + build 脚本不复制 |
| `.env.example` | **✅ 会（安全）** | 空模板，只有注释 |
| `tools/generate-license.js` | **❌ 不会** | 含 LICENSE_SECRET，不交付给用户 |
| `backend/src/` 源码 | **❌ 不会** | 用户只拿 server.jsc 字节码 |
| `node_modules/` | **❌ 不会** | 用户端 npm install 重新安装 |
| `.git/` | **❌ 不会** | 版本历史不交付 |

### 6.2 三层代码保护

```
第一层: Vite + esbuild          → 前端 JS 压缩混淆
第二层: ncc + bytenode          → 后端编译为 V8 字节码，不可反编译
第三层: SHA-256 + License       → 改一个字节启动失败 + 机器指纹绑定
```

---

## 第七部分：构建环境准备（一次性）

### Mac 上安装构建工具

```bash
# Node.js（需 18.x 或 20.x LTS）
brew install node

# 全局构建工具
npm install -g @vercel/ncc     # 后端合并单文件
npm install -g bytenode        # V8 字节码编译

# 可选（GitHub CLI，用于命令行创建 Release）
brew install gh
```

### 构建失败排查

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `❌ 未安装 @vercel/ncc` | 缺少全局工具 | `npm install -g @vercel/ncc` |
| `❌ 未安装 bytenode` | 缺少全局工具 | `npm install -g bytenode` |
| `❌ 发现硬编码路径` | 源码里有 `/Users/jason` | 修复源码中的硬编码路径 |
| Vite build OOM | 内存不足 | 在 Mac 上构建不会有此问题 |
| `npm ci` 失败 | 依赖问题 | `rm -rf node_modules && npm install` |

---

## 第八部分：素材管理

### 普通代码更新不需要处理素材

PR #25 已经把所有素材压缩好放在 `frontend/public/` 里：

| 素材 | 原始大小 | 当前大小 | 状态 |
|------|---------|---------|------|
| 视频 (3个) | 79 MB | 4.6 MB | 已压缩替换 |
| 群组头像 (42张) | 10 MB | 1.7 MB | 已压缩替换 |
| 整个 public/ | 186 MB | 18 MB | **-90%** |

### 如果新增素材

```bash
# 视频压缩
ffmpeg -i input.mp4 -vf "scale=-2:720" \
  -c:v libx264 -crf 30 -preset slow \
  -c:a aac -b:a 128k \
  frontend/public/videos/output.mp4

# 图片压缩
convert input.png -resize 256x -quality 85 frontend/public/group-avatars/output.png

# 新头像需要两个尺寸
convert original.png -resize 256x256 frontend/public/avatars/256x256/name.png
convert original.png -resize 64x64   frontend/public/avatars/64x64/name.png
```

---

## 第九部分：版本更新系统 — 后端 API 一览

### 系统 API

| 端点 | 说明 |
|------|------|
| `GET /api/system/version` | 返回当前版本 + Node 版本 + 平台 |
| `GET /api/system/check-update` | 双平台拉取 manifest.json，返回 `{ success, data: { hasUpdate, current, latest, source, ... } }` |
| `GET /api/system/license-status` | 授权状态（客户名/过期时间） |

### 通知 API

| 端点 | 说明 |
|------|------|
| `GET /api/system/notifications` | 通知列表（支持 type 过滤 + 分页） |
| `GET /api/system/notifications/unread-count` | 未读计数 |
| `POST /api/system/notifications/mark-read` | 标记指定通知已读 |
| `POST /api/system/notifications/mark-all-read` | 标记全部已读 |
| `GET /api/system/notification-types` | 获取通知类型定义 |

### 前端 Composables

| 文件 | 功能 |
|------|------|
| `useVersionCheck.ts` | 启动 15s 静默检查 + 每 6h 轮询 + 手动触发（解析 `data.data` 嵌套结构） |
| `useNotifications.ts` | 30s 首次拉取 + 10min 轮询 + 未读计数 + 标记已读 |

---

## 第十部分：完整发版操作流程图

```
Jason 说: "帮我发 X.Y.Z"
│
├── AI 执行 ──────────────────────────────────────────────────
│   │
│   ├── 1. git checkout main && git pull
│   ├── 2. echo "X.Y.Z" > VERSION
│   ├── 3. 更新 CHANGELOG.md（Unreleased → 正式版本 + 日期）
│   ├── 4. 更新 releases.json（添加 release 通知 + latest_version）
│   ├── 5. bash tools/build-release.sh X.Y.Z           ← 核心命令（含 11 步）
│   ├── 6. 验证产物（大小 / 版本 / server.jsc / 安全检查）
│   ├── 7. shasum -a 256 release/*.tar.gz
│   ├── 8. git add . && git commit -m "release: vX.Y.Z"
│   ├── 9. git tag vX.Y.Z && git push --tags
│   └── 10. 输出发布报告（产物已自动部署到 ~/octowork-chat/）
│
│       ⚡ build-release.sh Step 11 自动完成：
│       → 复制构建产物到 ~/octowork-chat/
│       → 同步 releases.json
│       → 保留 .git / license.key / manifest.json
│       → git add -A（已暂存，等待 Jason commit）
│
├── Jason 手动（仅 3 步！）──────────────────────────────────
│   │
│   ├── 11. cd ~/octowork-chat && 编辑 manifest.json（版本号 + SHA-256）
│   ├── 12. git commit -m "release: vX.Y.Z" && git push
│   └── 13. 到 GitHub/Gitee 创建 Release 并上传 tar.gz
│
└── 用户端（自动） ───────────────────────────────────────────
    │
    ├── 14. 后端 checker.js 拉取 manifest.json → 发现新版本
    ├── 15. 前端 UpdateBanner 显示："有新版本 vX.Y.Z"
    ├── 16. 铃铛红标提醒未读通知
    ├── 17. 用户点击 → UpdateDialog 显示更新日志 + 下载链接
    ├── 18. 用户下载 tar.gz → 解压替换 ~/octowork-chat/
    ├── 19. 恢复 license.key → ./install.sh → ./start.sh
    └── 20. 用户看到新版本正常运行
```

---

## 第十一部分：AI 能做什么 / 不能做什么

### AI 可以做的

| 任务 | 命令/操作 |
|------|----------|
| 代码开发 | 直接编辑源码 |
| 运行构建 | `bash tools/build-release.sh X.Y.Z` |
| 生成 License | `node tools/generate-license.js --fingerprint=xxx --customer=xxx` |
| 更新版本号 | 编辑 `VERSION` 文件 |
| 更新通知 | 编辑 `backend/data/releases.json` |
| 更新日志 | 编辑 `CHANGELOG.md` |
| 验证产物 | 检查压缩包大小/版本号/安全性 |
| 生成 manifest.json 内容 | 输出给 Jason 填入发布仓库 |
| 压缩新素材 | ffmpeg / ImageMagick |
| 安全检查 | grep 硬编码路径、检查密钥 |
| 自动部署到本地发布仓库 | 构建脚本 Step 11 自动完成，无需手动复制 |

### AI 不能做的（需要 Jason 手动）

| 任务 | 原因 |
|------|------|
| 上传到 GitHub Release | 需要 GitHub 认证 |
| 上传到 Gitee Release | 需要 Gitee 认证 |
| 编辑 manifest.json | 需要填入 SHA-256 和下载链接 |
| git push 发布仓库 | 构建脚本已自动同步内容到 ~/octowork-chat/，Jason 只需 commit + push |
| 发送 license.key 给客户 | 需要微信/邮件 |

---

## 第十二部分：速查命令表

```bash
# ===== 发版 =====
cd ~/octowork-chat-dev
echo "X.Y.Z" > VERSION
bash tools/build-release.sh X.Y.Z

# ===== License =====
node tools/generate-license.js \
  --fingerprint=xxx --customer=张三 \
  --expire=2027-12-31 --plan=standard

# ===== 验证产物 =====
ls -lh release/*.tar.gz                        # 包大小 (~20MB)
shasum -a 256 release/*.tar.gz                  # 包哈希
tar tzf release/*.tar.gz | wc -l                # 文件数 (~310)
cat release/octowork-chat-v*/VERSION            # 版本号

# ===== 安全检查 =====
tar tzf release/*.tar.gz | grep config.json     # 应无结果
tar tzf release/*.tar.gz | grep "\.env$"        # 应无结果
strings release/*/backend/server.jsc | grep LICENSE_SECRET  # 应无结果

# ===== 开发调试 =====
bash tools/dev-start.sh                         # 一键启动开发版
# 前端: http://localhost:5888
# 后端: http://localhost:1314/api

# ===== 用户端 =====
./install.sh                                    # 首次安装
./start.sh                                      # 启动服务
# 浏览器 → http://127.0.0.1:1314
```

---

## 第十三部分：重要提醒

1. **不要** 把 `config.json` 复制到发布包里
2. **不要** 把 `.env` 复制到发布包里
3. **不要** 把 `tools/generate-license.js` 给用户（里面有 LICENSE_SECRET）
4. **不要** 把 `backend/src/` 源码给用户
5. **构建完删临时文件**: `build-release.sh` 会自动 `rm -rf build-tmp/`
6. **上传到 GitHub/Gitee 是 Jason 手动操作**
7. **发版后必须同步更新 releases.json + manifest.json 到发布仓库（GitHub + Gitee 都要推）**，否则用户无法收到更新通知（releases.json 由 Step 11 自动同步到 ~/octowork-chat/，manifest.json 需 Jason 手动编辑）
8. **`latest_version` 是触发前端更新横幅的关键字段**，忘记更新就白发版了
9. **Gitee 仓库 org 名是 `octowork`**（不是 `octoworkai`），URL: `gitee.com/octowork/octowork-chat`
10. **后端 API `/api/system/check-update` 返回 `{ success, data: {...} }`**，前端 `useVersionCheck.ts` 解析 `response.data.data`，两边格式必须一致

---

## 附录 A：manifest.json 模板（双平台）

> **位置**：发布仓库 `octowork-chat` 根目录（GitHub + Gitee 各一份，内容一致）  
> **作用**：`checker.js` 双平台拉取此文件检测版本更新  
> **拉取地址**：  
> - Gitee（优先）：`https://gitee.com/octowork/octowork-chat/raw/main/manifest.json`  
> - GitHub（兜底）：`https://raw.githubusercontent.com/octoworkai/octowork-chat/main/manifest.json`

```json
{
  "latest": "X.Y.Z",
  "minimum": "1.0.0",
  "releaseDate": "2026-04-10",
  "changelog": "简要更新说明",
  "downloads": {
    "darwin-arm64": "https://github.com/octoworkai/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz",
    "darwin-x64": "https://github.com/octoworkai/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz",
    "linux-x64": "https://github.com/octoworkai/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz"
  },
  "downloads_gitee": {
    "darwin-arm64": "https://gitee.com/octowork/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz",
    "darwin-x64": "https://gitee.com/octowork/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz",
    "linux-x64": "https://gitee.com/octowork/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz"
  },
  "sha256": {
    "octowork-chat-vX.Y.Z.tar.gz": "SHA-256哈希值"
  },
  "note": "下载链接在打包后由 Jason 手动填入"
}
```

> **注意**：Gitee 仓库 org 名为 `octowork`（非 octoworkai），URL 为 `gitee.com/octowork/octowork-chat`

## 附录 B：releases.json 中添加 release 通知的模板

```json
{
  "id": "release-vX.Y.Z",
  "type": "release",
  "title": "vX.Y.Z - 版本标题",
  "date": "YYYY-MM-DD",
  "version": "X.Y.Z",
  "summary": "一句话描述本次更新核心内容",
  "content": "### 新功能\n- 功能A: 描述\n- 功能B: 描述\n\n### 修复\n- 修复C: 描述\n\n### 改进\n- 改进D: 描述",
  "downloadUrl": "https://github.com/octoworkai/octowork-chat/releases/download/vX.Y.Z/octowork-chat-vX.Y.Z.tar.gz",
  "importance": "high",
  "tags": ["major-release"]
}
```

## 附录 C：版本号规范

遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)：

| 版本变化 | 场景 | 示例 |
|---------|------|------|
| MAJOR (X) | 不兼容的 API 变更 | 1.0.0 → 2.0.0 |
| MINOR (Y) | 向下兼容的新功能 | 1.0.0 → 1.1.0 |
| PATCH (Z) | 向下兼容的 bug 修复 | 1.0.0 → 1.0.1 |

---

> **更新记录**  
> - v1.2 (2026-04-08): **双平台版本检测**：checker.js 改为 Gitee 优先 → GitHub 兜底；releaseNotificationService.js 同步双平台拉取 releases.json；修复后端 API 返回格式（`{ success, data: {...} }`）与前端 `useVersionCheck.ts` 对齐；新增双平台仓库地址表；更新 manifest.json 模板含 Gitee 下载链接；更新版本状态至 v1.1.5；新增关键代码文件索引
> - v1.1 (2026-04-06): 新增 Step 11 自动部署到本地发布仓库 ~/octowork-chat/，新增「当前项目状态」段落，Jason 手动步骤从 4 步降至 3 步
> - v1.0 (2026-04-06): 从 "AI专用打包用户版教程.md" 重写为全流程运营手册，整合发版、部署、更新、运营通知完整链路
