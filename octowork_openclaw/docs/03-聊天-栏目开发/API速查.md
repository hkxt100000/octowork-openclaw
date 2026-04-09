# 聊天模块 — API 速查

> 后端入口: `backend/server.js` (路由注册在 `backend/src/routes/index.js`)  
> 控制器: `backend/src/controllers/botController.js` + `groupController.js`  
> 路由文件: `backend/src/routes/botRoutes.js` + `groupRoutes.js`  
> 数据库层: `backend/db/database.js`  
> 最后更新: 2026-04-07

---

## 一、路由注册总览

```javascript
// backend/src/routes/index.js
app.use('/api/auth', authRoutes)        // 认证 (无需 token)
app.use('/api', botRoutes)              // Bot 单聊
app.use('/api', groupRoutes)            // 群聊
app.use('/api', taskRoutes)             // 任务
app.use('/api', eventRoutes)            // 事件
app.use('/api', notifyRoutes)           // 通知推送
app.use('/api', systemRoutes)           // 系统
app.use('/api/board', boardRoutes)      // 看板
app.use('/api/notifications', notificationRoutes)  // 通知中心
app.use('/api/update', updateRoutes)    // 更新
app.use('/api/task-pipeline', taskPipelineRoutes)  // 任务流水线
```

server.js 中额外注册的路由:
- `GET /api/sessions` — 会话列表
- `GET /api/system/*` — 系统信息/通知/版本检测
- `GET /api/model-capabilities` — 模型能力查询
- 静态文件: `/api/avatar`, `/avatars`, `/uploads`

---

## 二、单聊 API (botRoutes.js → BotController)

### 2.1 消息管理

| 方法 | 路径 | 控制器方法 | 请求体/参数 | 说明 |
|------|------|-----------|------------|------|
| GET | `/api/messages/:botId` | `getMessages` | `?limit=50&offset=0&userId=admin` | 获取消息历史，DESC排序，前端需 reverse |
| POST | `/api/messages/:botId` | `sendMessage` | `{content, style, userId, model}` 或 FormData(含 image) | **核心方法**: 发送消息，支持 multer 图片上传(10MB限制) |
| DELETE | `/api/messages/:botId` | `deleteMessages` | 无 | 清空消息 (按 botId 删除) |

### 2.2 Bot 主动消息

| 方法 | 路径 | 控制器方法 | 请求体 | 说明 |
|------|------|-----------|--------|------|
| POST | `/api/bot/send-to-user` | `sendToUser` | `{botId, userId, content, channel}` | Bot 主动给用户发消息 |

### 2.3 会话管理

| 方法 | 路径 | 位置 | 说明 |
|------|------|------|------|
| GET | `/api/sessions` | server.js | 最近会话列表 (含 message_count, last_active, bot头像/昵称) |

### 2.4 Bot 电池状态

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/bots/:botId/battery` | `getBatteryStatus` | 查询Bot电池状态 (token使用量) |
| POST | `/api/bots/:botId/charge` | `triggerCharge` | 手动触发充电 (自我摘要+清空+写回) |

### 2.5 Bot 文件系统

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/bots/:botId/files` | `getFiles` | 获取文件列表 |
| GET | `/api/bots/:botId/files/today` | `getTodayFiles` | 获取今日文件 |
| GET | `/api/bots/:botId/files/yesterday` | `getYesterdayFiles` | 获取昨日文件 |
| GET | `/api/bots/:botId/files/week` | `getWeekFiles` | 获取本周文件 |
| GET | `/api/bots/:botId/file-tree` | `getFileTree` | 获取文件树 (递归构建) |
| GET | `/api/bots/:botId/files/:filePath(*)` | `readFile` | 读取文件内容 |
| PUT | `/api/bots/:botId/files/:filePath(*)` | `updateFile` | 更新文件内容 |
| DELETE | `/api/bots/:botId/files/:filePath(*)` | `deleteFile` | 删除文件 |

### 2.6 Bot 模型与任务

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/bots/:botId/models` | `getModels` | 获取Bot可用模型列表 |
| GET | `/api/bots/:botId/tasks` | `getBotTasks` | 获取Bot的任务列表 |
| GET | `/api/bots/:botId/chat-records` | `getChatRecords` | 获取Bot聊天记录 (.md文件) |

### 2.7 Bot 环境变量

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/bot-env/:botId` | `getBotEnv` | 获取Bot环境变量 |
| POST | `/api/bot-env/:botId/start-script` | `getStartScript` | 获取启动脚本 |
| GET | `/api/bot-env/:botId/download-script` | `downloadScript` | 下载启动脚本 |
| POST | `/api/bot-env/:botId/regenerate-token` | `regenerateToken` | 重新生成Token |
| GET | `/api/bot-env/tokens/status` | `getTokenStatus` | 获取所有Token状态 |

---

## 三、群聊 API (groupRoutes.js → GroupController)

### 3.1 群组同步 (必须在 :groupId 路由之前)

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/groups/sync` | `syncGroupsWithDirectory` | 触发群组与通讯录同步(对账) |
| GET | `/api/groups/directory-info` | `getDirectoryInfo` | 获取通讯录配置信息 |

### 3.2 群组管理

| 方法 | 路径 | 控制器方法 | 请求体 | 说明 |
|------|------|-----------|--------|------|
| GET | `/api/groups` | `getAllGroups` | 无 | 获取所有群组(含 member_count, last_message) |
| POST | `/api/groups` | `createGroup` | `{name, description, members[]}` | 创建群组 |
| GET | `/api/groups/:groupId` | `getGroupDetail` | 无 | 获取群组详情 |
| DELETE | `/api/groups/:groupId` | `deleteGroup` | 无 | 删除群组(级联删除成员+消息) |

### 3.3 群组成员管理

| 方法 | 路径 | 控制器方法 | 请求体 | 说明 |
|------|------|-----------|--------|------|
| GET | `/api/groups/:groupId/members` | `getGroupMembers` | 无 | 获取成员列表 |
| POST | `/api/groups/:groupId/members` | `addMember` | `{botId}` | 添加成员 |
| DELETE | `/api/groups/:groupId/members/:botId` | `removeMember` | 无 | 移除成员 |

### 3.4 群组消息

| 方法 | 路径 | 控制器方法 | 请求体/参数 | 说明 |
|------|------|-----------|------------|------|
| GET | `/api/groups/:groupId/messages` | `getGroupMessages` | `?limit=100&offset=0` | 获取群消息(ASC排序) |
| POST | `/api/groups/:groupId/messages` | `sendGroupMessage` | `{content, mentions[], style, userId}` | 发送群消息(含@检测+任务意图检测) |
| DELETE | `/api/groups/:groupId/messages` | `deleteGroupMessages` | 无 | 清空群消息 |
| GET | `/api/groups/:groupId/mentions` | `getGroupMentions` | 无 | 获取@提及记录 |

### 3.5 群组文件与聊天记录

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/groups/:groupId/files` | `uploadGroupFile` | 文件上传(multer, 10MB, 支持图片+文档) |
| GET | `/api/groups/:groupId/chat-records` | `getGroupChatRecords` | 获取群聊 chat_history 文件列表 |
| GET | `/api/groups/:groupId/chat-records/:fileName` | `getGroupChatRecordContent` | 读取聊天记录文件内容 |

### 3.6 Bot 主动群聊消息

| 方法 | 路径 | 控制器方法 | 请求体 | 说明 |
|------|------|-----------|--------|------|
| POST | `/api/bot/send-to-group` | `botSendToGroup` | `{botId, groupId, content, mentions[]}` | Bot主动在群聊发消息 + 触发@Bot链 |

### 3.7 部门聊天记录

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/departments/:departmentName/chat-records` | `getDepartmentChatRecords` | 部门聊天记录文件列表 |
| GET | `/api/departments/:departmentName/chat-records/:fileName` | `getDepartmentChatRecordContent` | 部门聊天记录内容 |

---

## 四、系统 API (server.js 直接注册)

### 4.1 系统信息

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/system/license-status` | 许可证状态 |
| GET | `/api/system/version` | 当前版本信息 |
| GET | `/api/system/check-update` | 检查更新 |
| GET | `/api/system/check-update-enhanced` | 增强版更新检测(含7种会话模式) |
| GET | `/api/model-capabilities` | 模型能力查询 |

### 4.2 通知中心

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/system/notifications` | 获取通知列表 |
| GET | `/api/system/notifications/unread-count` | 未读通知数 |
| POST | `/api/system/notifications/mark-read` | 标记已读 `{userId, notificationIds[]}` |
| POST | `/api/system/notifications/mark-all-read` | 全部标记已读 |
| GET | `/api/system/notification-types` | 通知类型列表 |

### 4.3 任务流水线 API

| 方法 | 路径 | 说明 |
|------|------|------|
| 详见 | `/api/task-pipeline/*` | 7个 API 端点, 定义在 taskPipelineRoutes.js (221行) |

---

## 五、核心流程详解

### 5.1 sendMessage 核心流程 (POST /api/messages/:botId)

```
请求: {content, style, userId, model} 或 FormData(含 image 字段)
│
├─ 1. normalizeUserId(rawUserId) → 规范化用户ID
├─ 2. 重复消息检测 (5秒窗口, duplicateCache)
├─ 3. detectBotEnvironment(botId) → 识别 local/openclaw
├─ 4. openclawSessionManager.getUserBotSession(userId, botId) → sessionId
│     格式: "user_{userId}_bot_{botId}"
├─ 5. extractPlainText(content) → 提炼纯文本 (处理JSON/OpenClaw格式)
├─ 6. 处理图片上传 (multer → /uploads/images/)
├─ 7. saveMessage(sessionId, 'user', ...) → 保存用户消息 (is_pushed=1)
├─ 8. appendToChatHistory() → 写入 .md 聊天记录文件
├─ 9. taskMonitor.createTask(botId, content, model) → 创建任务
├─ 10. res.json({success, taskId}) ← 立即返回 (不阻塞前端)
│
└─ 11. 异步 Bot 回复 (OpenClaw)
    ├─ openclawClient.sendMessage(botId, content, model, userId, sessionId, style, imageUrl)
    ├─ extractPlainText(response) → 提炼Bot回复
    ├─ isBotProcessContent() → 过滤思考过程/进度日志
    ├─ completionChecker → 第一层: 回复完成度规则判断
    ├─ selfReviewService → 第二层: AI 自检追问
    ├─ saveMessage(sessionId, 'bot', ...) → 保存Bot回复 (is_pushed=0)
    ├─ appendToChatHistory() → 写入 .md 聊天记录
    ├─ taskMonitor.updateTaskStatus(taskId, 'completed')
    └─ wsManager.sendToUser(userId, {type:'bot_message', ...})
        ├─ 推送成功 → markMessageAsPushed(messageId)
        ├─ 推送失败 → 3秒快速重试
        └─ 仍失败 → offlineQueue.enqueue() (离线队列)
```

### 5.2 sendToUser 核心流程 (POST /api/bot/send-to-user)

```
请求: {botId, userId, content, channel}
│
├─ 1. 参数验证
├─ 2. extractPlainText(content) → 提炼纯文本
├─ 3. 构造 sessionId = "user_{userId}_bot_{botId}"
├─ 4. saveMessage(sessionId, 'bot', ...) → 保存消息
├─ 5. appendToChatHistory() → 写入 .md 聊天记录
└─ 6. wsManager.sendToUser(userId, {type:'bot_message', ...})
    ├─ 在线 → 即时推送
    └─ 离线 → offlineQueue.enqueue()
```

### 5.3 sendGroupMessage 核心流程 (POST /api/groups/:groupId/messages)

```
请求: {content, mentions[], style, userId}
│
├─ 1. 验证群组存在
├─ 2. _isHumanUser(sender) → 判断 admin/user (修复P0)
├─ 3. saveGroupMessage(groupId, sender, ...) → 保存用户消息
├─ 4. 广播 WS {type:'group_message'} 给在线用户
├─ 5. extractPlainText + 任务意图检测(集成)
├─ 6. _triggerMentionedBots(content, groupId, ...) → 触发被@的Bot回复
│     ├─ 解析 /@([a-zA-Z0-9\-_]+)/g 提取 @botId
│     ├─ 支持 @all → 展开为全体成员
│     ├─ 冷却检测 (5秒, MENTION_COOLDOWN_MS)
│     ├─ 深度限制 (MAX_TRIGGER_DEPTH=1, 防止Bot间无限循环)
│     ├─ 构建上下文 (最近5条消息 + 聊天风格)
│     ├─ openclawClient.sendMessage() → 获取Bot回复
│     ├─ selfReviewService → 自检追问
│     └─ botSendToGroup() → 保存回复 + 广播 + 递归触发下一层@
│
└─ 7. res.json({success, messageId})
```

### 5.4 botSendToGroup 核心流程 (POST /api/bot/send-to-group)

```
请求: {botId, groupId, content, mentions[]}
│
├─ 1. 验证群组存在 + Bot是成员
├─ 2. 获取Bot显示名 (_getBotDisplayName)
├─ 3. extractPlainText(content)
├─ 4. saveGroupMessage(groupId, botId, ...) → 保存Bot消息
├─ 5. appendToGroupChatHistory() → 写入群聊 .md 记录
├─ 6. wsManager 广播 {type:'group_message'} 给在线用户
└─ 7. _triggerMentionedBots() → 如果Bot消息中@了其他Bot，递归触发
```

---

## 六、WebSocket 推送消息格式

```javascript
// Bot 回复消息 (单聊)
{
  type: 'bot_message',
  botId: string,
  userId: string,
  sessionId: string,
  message: { id, sender: 'bot', content, timestamp, userId, sessionId }
}

// 群聊消息
{
  type: 'group_message',
  groupId: number,
  message: { id, group_id, sender, sender_name, content, timestamp, mentions }
}

// 任务状态更新
{ type: 'task_status', botId, taskId, status, data }
{ type: 'task_progress', botId, taskId, progress, currentStep }
{ type: 'task_completed', botId, taskId, result }
{ type: 'task_failed', botId, taskId, error }
{ type: 'task_notification', botId, taskId, message }

// Bot 状态
{ type: 'bot_status', botId, status: 'online'|'offline'|'working' }
{ type: 'bot_log', botId, log: string }
{ type: 'bot_progress', botId, progress: number, currentStep: string }

// 文件变化
{ type: 'file_changed', botId, filePath, changeType: 'create'|'modify'|'delete' }

// 电池更新
{ type: 'battery_update', botId, battery: { level, percentage, isCharging } }

// 系统
{ type: 'notification', data: {...} }
{ type: 'session_created', sessionId }
{ type: 'pong', timestamp }
{ type: 'heartbeat', timestamp }
```

---

## 七、7 种聊天模式

前端通过 `style` 参数传递给后端，后端映射到不同的系统指令前缀发送给 OpenClaw：

| 模式ID | 名称 | 快捷键 | 说明 |
|--------|------|--------|------|
| `simple` | 🗣️ 说人话 | Alt+1 | 简洁高效，直接结论 |
| `discussion` | 💬 交流探讨 | Alt+2 | 多角度分析，200字以内 |
| `thinking` | 🤔 深度思考 | Alt+3 | 先理解再回答 |
| `report` | 📋 方案报告 | Alt+4 | 结构化报告 |
| `task` | ⚙️ 任务工作 | Alt+5 | 步骤拆解+进度 |
| `brainstorm` | 🧠 创意脑暴 | Alt+6 | 发散思维 |
| `decision` | ⚡ 快速决策 | Alt+7 | 直接结论行动 |

---

## 八、后端文件地图

### 控制器 (backend/src/controllers/)

| 文件 | 说明 |
|------|------|
| `botController.js` | 单聊核心: 消息收发, 文件系统, 模型管理, 环境变量, 电池状态 |
| `groupController.js` | 群聊核心: 群管理, 成员, 消息, @Bot触发, GroupSync, 聊天记录 |
| `taskController.js` | 任务看板: Dashboard, CRUD |
| `authController.js` | 认证: 登录/登出/用户管理 |
| `notificationController.js` | 通知中心: 列表/已读/类型 |
| `systemController.js` | 系统信息: 版本/许可 |
| `boardController.js` | 看板: 数据聚合 |

### 路由 (backend/src/routes/)

| 文件 | 挂载点 | 说明 |
|------|--------|------|
| `botRoutes.js` | `/api` | 单聊相关路由 |
| `groupRoutes.js` | `/api` | 群聊相关路由 |
| `taskRoutes.js` | `/api` | 任务路由 |
| `taskPipelineRoutes.js` | `/api/task-pipeline` | 流水线API (7个端点, 221行) |
| `authRoutes.js` | `/api/auth` | 认证路由(无需token) |
| `notificationRoutes.js` | `/api/notifications` | 通知路由 |
| `updateRoutes.js` | `/api/update` | 更新路由 |
| `systemRoutes.js` | `/api` | 系统路由 |
| `eventRoutes.js` | `/api` | 事件路由 |
| `notifyRoutes.js` | `/api` | 推送通知路由 |
| `boardRoutes.js` | `/api/board` | 看板路由 |

### 服务层 (backend/src/services/)

| 文件 | 说明 |
|------|------|
| `sessionManager.js` | 用户在线状态管理 |
| `openclawSessionManager.js` | OpenClaw 会话管理 (userId+botId → sessionId) |
| `offlineQueue.js` | 离线消息队列 |
| `dbService.js` | 数据库服务封装 |
| `updater.js` | 更新服务 |

### 其他关键后端文件

| 文件 | 说明 |
|------|------|
| `backend/server.js` | Express 主入口, WS服务器, 系统API |
| `backend/db/database.js` | SQLite3 数据层 (5张表, 全部CRUD) |
| `backend/group-sync.js` | GroupSync: 通讯录自动建群+成员同步+文件监听 |
| `backend/services/personalTaskPipeline.js` | PersonalTasks 流水线 (836行) |
| `backend/websocket/user-manager.js` | WS用户管理 |
| `backend/websocket/manager.js.deprecated` | 旧WS管理器(已废弃) |
