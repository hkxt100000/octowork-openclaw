# 首页模块 — API 速查

> 后端入口: `backend/src/controllers/authController.js` (387行)  
> 路由注册: `backend/src/routes/authRoutes.js`  
> 用户数据: 文件存储 `backend/data/user.json` (非数据库)

---

## 认证接口 (已实现)

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/auth/login` | `login` | **本地登录** `{username, password, remember}` — 首次使用自动创建用户 |
| GET | `/api/auth/me` | `getCurrentUser` | 获取当前用户信息 (Header: `Authorization: Bearer <token>`) |
| PUT | `/api/auth/update` | `updateUser` | 更新用户信息 `{nickname, email, avatar, settings}` |
| POST | `/api/auth/change-password` | `changePassword` | 修改密码 `{oldPassword, newPassword}` |
| POST | `/api/auth/cloud-login` | `cloudLogin` | 云端登录 (**预留**, 返回 501) |

## Dashboard 数据接口 (已实现)

| 方法 | 路径 | 位置 | 说明 |
|------|------|------|------|
| GET | `/api/bots` | `server.js` via OpenClaw | Bot 列表 (DashboardView + ContentSidebar 共用) |
| GET | `/api/sessions` | `server.js` | 最近会话列表 (含 message_count, last_active) |

> **注意**: `/api/dashboard/stats`、`/api/dashboard/activities`、`/api/dashboard/bot-status` **均未实现**，DashboardView 中使用 mock 数据。

---

## login 核心流程

```
POST /api/auth/login {username, password, remember}
│
├─ 1. 参数验证 (username + password 非空)
├─ 2. readUserConfig() → 读取 backend/data/user.json
│     ├─ 文件不存在 → 首次使用:
│     │   createDefaultUser(username, password)
│     │   → saveUserConfig() → 返回 {isFirstLogin:true, user, token}
│     └─ 文件存在 → 继续验证
├─ 3. 验证用户名 (===)
├─ 4. hashPassword(password) SHA256 → 比对 stored password
├─ 5. 更新 last_login → saveUserConfig()
├─ 6. generateToken(userId) → Base64 编码 {userId, timestamp, random}
└─ 7. 返回 {success:true, user:{userId,username,nickname,avatar,email,workspace_code}, token}
```

## 前端认证流程

```
用户点击"登录" → Login.vue showLoginModal=true
→ 提交表单 → authService.login(username, password, remember)
  → POST /api/auth/login
  → 成功: localStorage 存 auth_token + current_user → axios 设置 Authorization Header
  → router.push('/') → 进入 App.vue (主界面)

路由守卫 (router.ts):
  每次导航 → authService.isAuthenticated() → 检查 token + currentUser 是否存在
  → 需要认证且未登录 → 重定向 /login
  → 已登录访问 /login → 重定向 /
```

## 用户数据结构 (user.json)

```javascript
{
  userId: "user_1711792800000_abc123def",
  username: "admin",
  password: "sha256_hash",           // SHA256 哈希
  nickname: "Jason",
  avatar: "/default-avatar.png",
  workspace_code: "local-dev",
  email: "",
  phone: "",
  role: "admin",
  created_at: "2026-03-30T00:00:00Z",
  last_login: "2026-04-04T12:00:00Z",
  settings: {
    auto_login: false,
    remember_password: false,
    theme: "light",
    language: "zh-CN",
    notification: { desktop: true, sound: true }
  },
  cloud_sync: { enabled: false, last_sync: null, token: null }
}
```

## 全局导航视图标识 (MainLayout.vue)

MainLayout 通过 `currentView` 字符串驱动所有导航:

| currentView | 导航文字 | 图标 | 说明 |
|-------------|---------|------|------|
| `dashboard` | 驾驶舱 | 🏠 | DashboardView 全屏展示 |
| `chats` | 聊天 | 💬 | 单聊列表 + 聊天区域 (有未读红标) |
| `groups` | 群聊 | 👥 | 群聊列表 + 群聊区域 |
| `tasks` | 任务 | ✅ | 任务中心 |
| `crm` | 企微 | 👤+ | 企微 CRM |
| `market` | 数字人 | 🏪 | 数字人市场 / AI 员工 |
| `stats` | 学院 | 📊 | 章鱼学院 |
| `equipment` | 装备库 | ⚔️ | 技能市场 |
| `settings` | 设置 | ⚙️ | 设置面板 (下拉菜单触发) |

## 路由定义 (router.ts)

| 路径 | 名称 | 组件 | 需要认证 |
|------|------|------|---------|
| `/login` | Login | `views/Login.vue` | ❌ |
| `/` | Home | `App.vue` | ✅ |
| `/group/:groupId` | GroupChat | `views/GroupChatPage.vue` | ✅ |
| `/board` | Board | `components/TaskBoard/BoardPage.vue` | ✅ |
| `/board/:deptId` | KanbanView | `components/TaskBoard/KanbanView.vue` | ✅ |

## 视频配置 (videoConfig.ts)

```typescript
const BASE_URL = '/videos'  // 生产环境换为 CDN URL

VIDEO_LIST: VideoItem[] = [
  { id:1, src:'v1-octopus-awakening.mp4', slogan:'OctoWork，陪你一起打天下', prompt:'...' },
  { id:2, src:'v2-star-conquest.mp4',     slogan:'征服星辰，从这里启航',     prompt:'...' },
  { id:3, src:'v3-empire.mp4',            slogan:'AI没你想的那么聪明',       prompt:'...' },
  // id:4, id:5 已注释，预留
]
VIDEO_DURATION = 10000   // 自动切换间隔 ms
VIDEO_TRANSITION = 800   // 切换过渡时长 ms
```
