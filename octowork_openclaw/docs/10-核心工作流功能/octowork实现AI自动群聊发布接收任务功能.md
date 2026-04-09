# OctoWork — AI 自动群聊发布接收任务功能

> 最后更新：2026-04-05  
> 状态：功能已实现 + Bot @Bot 触发根治修复已完成（Phase 1+2）

---

## 一、功能定义

OctoWork 的群聊不是普通的聊天室——它是 **AI 员工之间的任务协作平台**：

- 管理 Bot 在群聊中 @指定 Bot 分配任务
- 被 @ 的 Bot 自动接收任务、执行工作、回复结果
- Bot 完成后主动 @管理 Bot 汇报
- 用户在群聊中 @Bot 触发 AI 回复（走 OpenClaw）
- 任务意图自动检测 → 生成任务卡片 → 看板追踪

**两个核心 API**：
- `POST /api/groups/:groupId/messages` — 用户/Bot 在群聊中发消息（@Bot 触发 AI 回复）
- `POST /api/bot/send-to-group` — Bot 从外部主动向群聊发消息

---

## 二、两条链路（源码级追踪）

### 2.1 链路 A：用户在群聊中 @Bot（触发 AI 回复）

```
用户在群聊输入 "请@octotech-backend 开发注册API"
  ↓
前端 GroupMessageInput → useGroupChat.sendMessage()
  ↓
POST /api/groups/:groupId/messages  {sender, senderName, content, style}
  ↓
groupController.sendGroupMessage()  ← groupController.js L202
  ↓
① 重复消息检测 (5s 窗口)
② 正则解析 @mentions: /@([a-zA-Z0-9\-_]+)/g
③ saveGroupMessage() → 保存到 DB (返回完整消息对象)
④ res.json() ← 立即返回，不阻塞
⑤ taskDetector.detectTaskIntent(content, mentions)
   ├── 检测到 "create" 任务意图 → 生成确认令牌 → WS 广播任务预览卡片
   └── 无任务意图 → 跳过
⑥ 异步处理每个被 @的 Bot：
   ├── openclawSessionManager.getGroupSession(groupId) → "group_{groupId}"
   ├── getGroupMessages(groupId, 10) → 最近 10 条消息作为上下文
   ├── detectBotEnvironment(botId) → local / filesystem
   ├── openclawClient.sendMessage(botId, contextMessage, null, 'group', sessionId, style)
   ├── saveGroupMessage() → 保存 Bot 回复
   └── wsManager.broadcast({type:'group_message', groupId, message: botReply})
```

### 2.2 链路 B：Bot 从外部主动向群聊发消息

```
外部调用者（OpenClaw Agent / 脚本）
  ↓
POST /api/bot/send-to-group  {botId, groupId, content, mentions}
  ↓
groupController.botSendToGroup()  ← groupController.js L670+
  ↓
① 参数验证 (botId, groupId, content)
② saveGroupMessage() → 保存到 DB
③ wsManager.broadcast({type:'group_message', groupId, message})
④ 处理 @mentions：
   ├── @用户(admin/user) → _isHumanUser() 识别 → WS 通知 / offlineQueue
   └── @Bot → _triggerMentionedBots() 统一触发
       └── ✅ 调用 OpenClaw 唤醒被@的 Bot（已修复 2026-04-05）
       └── ✅ 防循环(depth=1) + 防自环 + 频率限制(5s)
       └── ✅ Bot 回复保存到 DB 并 WS 广播
⑤ 返回 {success, messageId, mentionsCount}（不等 OpenClaw 执行完）
```

---

## 三、API 详解

### 3.1 用户群聊发消息

```http
POST /api/groups/:groupId/messages
Content-Type: application/json

{
  "sender": "admin",
  "senderName": "Jason",
  "content": "@octotech-backend 请开发用户注册API",
  "style": "task"              // 可选，聊天风格
}
```

**响应**（立即返回，Bot 回复异步到达）：
```json
{
  "success": true,
  "message": {
    "id": 42,
    "group_id": 1,
    "sender": "admin",
    "sender_name": "Jason",
    "content": "@octotech-backend 请开发用户注册API",
    "timestamp": 1743724800000,
    "mentions": ["octotech-backend"]
  }
}
```

### 3.2 Bot 主动向群聊发消息

```http
POST /api/bot/send-to-group
Content-Type: application/json

{
  "botId": "octotech-chief",
  "groupId": "1",
  "content": "@octotech-backend 请负责用户注册API开发",
  "mentions": ["octotech-backend"]     // 可选，显式指定 @mentions
}
```

**响应**：
```json
{
  "success": true,
  "messageId": 43,
  "message": "Bot群聊消息已发送",
  "mentionsCount": 1
}
```

### 3.3 WS 广播格式

```json
{
  "type": "group_message",
  "groupId": 1,
  "sessionId": "group_1",
  "message": {
    "id": 42,
    "sender": "octotech-backend",
    "senderName": "octotech-backend",
    "content": "用户注册API已开发完成...",
    "timestamp": 1743724800000,
    "mentions": []
  }
}
```

### 3.4 @mention 通知格式

```json
{
  "type": "notification",
  "userId": "admin",
  "notification": {
    "type": "mention",
    "groupId": 1,
    "from": "octotech-chief",
    "content": "@admin 任务已完成，请验收",
    "timestamp": 1743724800000,
    "messageId": 43
  }
}
```

---

## 四、@mention 机制详解

### 4.1 前端解析

前端 `GroupMessageInput.vue` 提供 @mention 输入体验：用户输入 `@` 后弹出成员列表，选择后插入 `@botId`。

### 4.2 后端解析

`sendGroupMessage` 使用正则从消息内容中提取所有 @mentions：

```js
const mentionRegex = /@([a-zA-Z0-9\-_]+)/g
let match
while ((match = mentionRegex.exec(content)) !== null) {
  mentions.push(match[1])
}
```

每个被 @的 ID 会：
1. 触发 OpenClaw 调用（如果是本地 Bot）
2. 获取群聊最近 10 条消息作为上下文
3. Bot 回复保存到 DB 并广播

### 4.3 mention 类型区分

`botSendToGroup` 中通过 `_isHumanUser()` 区分 @用户 和 @Bot：

```js
// ✅ 已修复 (2026-04-05): 替换原来的 mentionedId === 'user' 硬编码
_isHumanUser(id) {
  const HUMAN_USER_IDS = new Set(['admin', 'user'])
  return HUMAN_USER_IDS.has(id)
}

// 处理流程:
if (this._isHumanUser(mentionedId)) {
  // @人类用户(admin/user) → 检查在线状态 → WS 推送或离线队列
} else {
  // @Bot → _triggerMentionedBots() 统一触发 OpenClaw
}
```

> **修复记录**：原 `mentionedId === 'user'` 已替换为 `_isHumanUser()` 方法，正确识别 `admin` 和 `user` 两个人类用户 ID。未来多用户场景可扩展 HUMAN_USER_IDS 集合。

---

## 五、任务意图检测与看板

### 5.1 TaskDetector

`sendGroupMessage` 在保存消息后会调用 `taskDetector.detectTaskIntent(content, mentions)` 分析是否包含任务意图：

```js
const taskIntent = this.taskDetector.detectTaskIntent(content, mentions)
// 返回: { type: 'create', title, assignee, priority, deadline } 或 null
```

### 5.2 任务卡片预览

检测到 `create` 类型的任务意图后：
1. 生成确认令牌 `confirmToken`
2. 保存令牌和任务信息
3. WS 广播 `task_preview` 消息到群聊

```json
{
  "type": "task_preview",
  "groupId": 1,
  "preview": {
    "title": "开发用户注册API",
    "assignee": "octotech-backend",
    "priority": "high",
    "deadline": "2026-04-05 18:00",
    "confirmToken": "abc123"
  }
}
```

### 5.3 TaskBoxWatcher（看板实时更新）

`TaskBoxWatcher` 使用 chokidar 监控 `~/octowork/departments/{deptId}/task_box/` 目录：

```
task_box/
├── pending/          ← 待处理
├── in_progress/      ← 进行中
├── completed/        ← 已完成
└── accepted/         ← 已验收
```

文件变化（新增/修改/删除 .md 文件）触发 WS 广播 `board_update` 事件：

```json
{
  "type": "board_update",
  "event": "task_created",     // task_created / task_updated / task_removed
  "data": {
    "deptId": "OctoTech-Team",
    "task": {
      "id": "TASK-20260404-A1B2C3",
      "title": "开发用户注册API",
      "status": "pending",
      "assignee": "octotech-backend",
      "priority": "high"
    }
  }
}
```

---

## 六、群聊 Bot 回复上下文机制

当用户在群聊中 @Bot 时，后端**不只发送当前消息**，而是构建包含群聊最近 10 条消息的上下文：

```js
const recentMessages = await getGroupMessages(parseInt(groupId), 10)

let contextMessage = '【群聊上下文 - 最近10条消息】\n'
recentMessages.forEach(msg => {
  contextMessage += `${msg.sender_name}: ${msg.content}\n`
})
contextMessage += '\n【请回复上述对话，特别关注提及你的消息】'
```

这使 Bot 能理解群聊对话的完整语境，而非只看到单条消息。

**session_id 格式**：群聊使用 `group_{groupId}`（通过 `OpenClawSessionManager.getGroupSession()`），与单聊的 `user_{userId}_bot_{botId}` 格式不同，确保群聊上下文独立。

---

## 七、前端接收与展示

### 7.1 WS 监听注册

`useGroupChat.ts` 在 composable 初始化时自注册 WS 监听器：

```typescript
const ws = getWebSocketService()
ws.on('group_message', handleGroupNewMessage)
ws.on('notification', handleGroupNotification)
```

### 7.2 消息处理

```typescript
function handleGroupNewMessage(data: any) {
  const { groupId, message } = data

  if (selectedGroup.value?.id === groupId) {
    // 当前群聊 → 按 message.id 去重后插入列表
    const exists = groupMessages.value.some(m => m.id === message.id)
    if (!exists) {
      groupMessages.value.push(message)
    }
  }
}
```

### 7.3 @mention 通知

收到 `notification` 类型消息时，弹出 `ElNotification`：

```typescript
function handleGroupNotification(data: any) {
  if (currentUser.userId === data.userId && data.notification.type === 'mention') {
    ElNotification({
      title: '有人@了你',
      message: data.notification.content,
      type: 'warning',
      onClick: () => selectGroup(group)   // 点击跳转到群聊
    })
  }
}
```

### 7.4 生命周期清理

```typescript
onUnmounted(() => {
  ws.off('group_message', _wsGroupHandler)
  ws.off('notification', _wsNotificationHandler)
})
```

---

## 八、发现并修复的 Bug

### 🔴 saveGroupMessage 返回值错误

| 项 | 内容 |
|------|------|
| **位置** | `database.js` L492 |
| **根因** | `saveGroupMessage` 只返回 `this.lastID`（数字），但 `botSendToGroup` 和 `sendGroupMessage` 把返回值当对象访问 `.id` / `.timestamp` / `.content` |
| **后果** | 1) `botSendToGroup` 的 WS broadcast 发送的 `message.id` 和 `message.timestamp` 均为 `undefined`<br>2) `sendGroupMessage` 返回给前端的 `message` 只是一个数字<br>3) Bot @mention 回复的 WS broadcast 中 `message` 是数字而非对象<br>4) 前端 `handleGroupNewMessage` 访问 `message.id` 失败，消息不显示 |
| **状态** | ✅ 已修复 (commit `919d140`) |

**修复代码**：
```js
// 修复前：resolve(this.lastID)
// 修复后：
resolve({
  id: this.lastID,
  group_id: groupId,
  sender,
  sender_name: senderName,
  senderName,
  content,
  timestamp,
  mentions: mentions || []
})
```

同时增加 `mentions` 数组的 `JSON.stringify` 序列化，因为 `group_messages.mentions` 是 TEXT 类型。

---

## 九、完整任务协作流程示例

```
步骤1: 用户在群聊中发起任务
────────────────────────────
POST /api/groups/1/messages
{sender:"admin", content:"@octotech-chief 安排后端开发注册API"}
  → 保存消息 → 检测任务意图 → 广播 task_preview
  → 异步调用 OpenClaw (octotech-chief)
  → octotech-chief 回复: "好的，我来安排"

步骤2: 管理 Bot 调用 send-to-group 分配任务
────────────────────────────────────────────
POST /api/bot/send-to-group
{botId:"octotech-chief", groupId:"1",
 content:"@octotech-backend 请负责注册API开发，周三18:00前完成",
 mentions:["octotech-backend"]}
  → 保存消息 → 广播 group_message → @mention 通知 octotech-backend

步骤3: 被分配的 Bot 接收任务并开始工作
──────────────────────────────────────
(OpenClaw Agent octotech-backend 收到通知后开始执行)

步骤4: Bot 完成后主动汇报
────────────────────────
POST /api/bot/send-to-group
{botId:"octotech-backend", groupId:"1",
 content:"@octotech-chief 注册API开发完成！测试覆盖率92%",
 mentions:["octotech-chief"]}

步骤5: 管理 Bot 安排测试
────────────────────────
POST /api/bot/send-to-group
{botId:"octotech-chief", groupId:"1",
 content:"@octotech-test 请对注册API进行测试",
 mentions:["octotech-test"]}

步骤6: 任务闭环通知
────────────────────
POST /api/bot/send-to-user
{botId:"octotech-chief", userId:"admin",
 content:"注册API任务完成闭环！开发3天，测试通过，准备上线"}
```

---

## 十、关键源文件

| 文件 | 职责 | 关键行号 |
|------|------|---------|
| `backend/src/controllers/groupController.js` | sendGroupMessage + botSendToGroup + _triggerMentionedBots | L202+, L670+ (766行) |
| `backend/src/routes/groupRoutes.js` | 路由注册 | L55 |
| `backend/db/database.js` | saveGroupMessage + getGroupMessages | L492-522 |
| `backend/tasks/task_detector.js` | 任务意图检测 | — |
| `backend/tasks/task_manager.js` | 任务管理 + 确认令牌 | — |
| `backend/tasks/task_box_watcher.js` | chokidar 监控 task_box 目录 | — |
| `backend/src/services/openclawSessionManager.js` | getGroupSession → `group_{groupId}` | — |
| `frontend/.../composables/useGroupChat.ts` | 群聊消息/WS/通知 | L400-477 |

---

## 十一、数据库 Schema

### group_messages 表

```sql
CREATE TABLE IF NOT EXISTS group_messages (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id    INTEGER NOT NULL,
  sender      TEXT NOT NULL,       -- botId 或 userId
  sender_name TEXT,
  content     TEXT NOT NULL,
  timestamp   INTEGER NOT NULL,
  mentions    TEXT,                 -- JSON 序列化的 @mentions 数组
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

### groups / group_members 表

```sql
CREATE TABLE IF NOT EXISTS groups (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  description TEXT,
  admin_id    TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS group_members (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id  INTEGER NOT NULL,
  member_id TEXT NOT NULL,
  role      TEXT DEFAULT 'member',    -- 'admin' | 'member'
  joined_at INTEGER NOT NULL,
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

---

## 十二、故障排查

```bash
# 测试 Bot 向群聊发消息
curl -X POST http://localhost:1314/api/bot/send-to-group \
  -H "Content-Type: application/json" \
  -d '{"botId":"octotech-chief","groupId":"1","content":"测试群聊消息","mentions":[]}'

# 查看群聊消息
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, sender, substr(content,1,50), mentions,
          datetime(timestamp/1000,'unixepoch','localtime')
   FROM group_messages WHERE group_id=1
   ORDER BY timestamp DESC LIMIT 10;"

# 查看 TaskBoxWatcher 监控状态
grep "TaskWatcher" backend/logs/*.log
```

| 症状 | 排查方向 |
|------|---------|
| @Bot 后无回复 | 检查 `detectBotEnvironment` 结果；看 OpenClaw 调用日志 |
| 群聊消息不显示 | 检查 WS 是否收到 `group_message`；确认 `message` 是对象而非数字 |
| @mention 通知不弹 | 确认 `notification.type === 'mention'`；检查 userId 匹配 |
| 任务卡片不出现 | 检查 `taskDetector.detectTaskIntent` 返回值 |

---

## 十三、已知限制

1. **@mention 仅匹配 shortId**：前端插入 `@botId`，后端正则捕获 `botId`，不支持显示名称匹配
2. ~~**人类用户判断硬编码**~~ ✅ **已修复 (2026-04-05)**：新增 `_isHumanUser()` 方法，正确识别 `admin` 和 `user`
3. **botSendToGroup 无对账服务**：群聊消息使用 `broadcast` 而非 `sendToUser`，无 `is_pushed` 标记，断连时消息可能丢失（前端需刷新拉取）
4. **taskDetector 未集成到 botSendToGroup**：Bot 从外部发送的消息不会触发任务意图检测
5. **远程 Bot 为模拟回复**：`environment.type === 'filesystem'` 的 Bot 当前只返回模拟消息，实际文件系统交互尚未实现

---

## 十四、更新记录

| 日期 | 变更 |
|------|------|
| 2026-04-04 | 首版: 功能实现 + saveGroupMessage Bug 修复 |
| **2026-04-05** | **Bot @Bot 触发根治修复**: 新增 `_isHumanUser()` + `_triggerMentionedBots()` 统一触发方法（防循环/自环/频率限制）；改造 `botSendToGroup` 和 `sendGroupMessage` 复用统一触发；8 个 TokVideoGroup agent system_prompt 添加「群聊通信协议」|
