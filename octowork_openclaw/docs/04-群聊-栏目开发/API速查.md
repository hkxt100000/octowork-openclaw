# 群聊模块 — API 速查

> 后端入口: `backend/src/controllers/groupController.js` (1790行)  
> 路由注册: `backend/src/routes/groupRoutes.js` (123行)  
> 数据库层: `backend/db/database.js` (第 377-606, 732-775 行)  
> 对账同步: `backend/group-sync.js` (339行)  
> 最后更新: 2026-04-07（基于实际代码全面校验）

---

## 一、路由总览

### 1.1 群组同步 API（在 :groupId 路由之前注册）

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/groups/sync` | `syncGroupsWithDirectory` | 触发群组与通讯录对账同步 |
| GET | `/api/groups/directory-info` | `getDirectoryInfo` | 获取通讯录配置摘要（调试用） |

### 1.2 群组管理 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/groups` | `getAllGroups` | 获取所有群组 (含 member_count, message_count, last_message) |
| POST | `/api/groups` | `createGroup` | 创建群组 `{groupName, description?, members[], creator?}` |
| GET | `/api/groups/:groupId` | `getGroupDetail` | 获取群组详情 (含完整 members 数组 + member_count) |
| DELETE | `/api/groups/:groupId` | `deleteGroup` | 删除群组 (source='auto' 的群禁止手动删除) |

### 1.3 群组成员 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/groups/:groupId/members` | `getGroupMembers` | 获取成员列表 |
| POST | `/api/groups/:groupId/members` | `addMember` | 添加成员 `{botId, botName}` |
| DELETE | `/api/groups/:groupId/members/:botId` | `removeMember` | 移除成员 |

### 1.4 群组消息 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/groups/:groupId/messages?limit=50&before=` | `getGroupMessages` | 获取消息 (ASC排序, 支持分页: before=msgId) |
| POST | `/api/groups/:groupId/messages` | `sendGroupMessage` | **核心方法**: 发送消息 (含 @mention 解析 + Bot 回复 + 任务检测 + 自检) |
| DELETE | `/api/groups/:groupId/messages` | `deleteGroupMessages` | 清空该群所有消息 |
| GET | `/api/groups/:groupId/mentions?target=&limit=30&context=2` | `getGroupMentions` | 获取含 @mention 的消息 (带上下文, 支持按目标过滤) |

### 1.5 群组文件 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/groups/:groupId/files` | `uploadGroupFile` | 文件/图片上传 (multer, 10MB限制, 存 uploads/groups/:groupId/) |

### 1.6 群组聊天记录文件 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/groups/:groupId/chat-records` | `getGroupChatRecords` | 获取 chat_history 文件列表 (部门感知路径解析) |
| GET | `/api/groups/:groupId/chat-records/:fileName` | `getGroupChatRecordContent` | 读取 chat_history 文件内容 |

### 1.7 Bot 主动群聊 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/bot/send-to-group` | `botSendToGroup` | Bot 主动在群里发消息 `{botId, groupId, content, mentions[]}` |

### 1.8 部门聊天记录 API

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/departments/:departmentName/chat-records` | `getDepartmentChatRecords` | 部门聊天记录文件列表 |
| GET | `/api/departments/:departmentName/chat-records/:fileName` | `getDepartmentChatRecordContent` | 读取部门聊天记录文件内容 (含路径安全检查) |

---

## 二、核心流程详解

### 2.1 sendGroupMessage — 用户发送群聊消息

```
POST /api/groups/:groupId/messages
Body: { sender, senderName, content, style }
│
├─ 1. 参数验证 (content, sender, senderName 不能为空)
├─ 2. 重复消息检测 (5秒窗口, duplicateCache: `group_{groupId}:{sender}:{content}`)
│     └─ 重复 → { success: true, isDuplicate: true }
├─ 3. @mention 正则提取: /@([a-zA-Z0-9\-_]+)/g → mentions[]
├─ 4. await saveGroupMessage(groupId, sender, senderName, content, mentions) → message
├─ 5. res.json({ success: true, message }) ← 立即返回，不阻塞用户
│
├─ 6. [异步] WS 广播用户消息
│     wsManager.broadcast({ type: 'group_message', groupId, message })
│
├─ 7. [异步] 保存到 chat_history 文件 (appendToGroupChatHistory)
│     └─ ai-directory.json 匹配群名 → 部门ID → departments/{deptId}/chat_history/{date}.md
│
├─ 8. [异步] 任务意图检测 (taskDetector.detectTaskIntent)
│     └─ type='create' → 生成 confirmToken → WS broadcast task_preview
│
└─ 9. [异步] Bot 回复 (_triggerMentionedBots, mentions.length > 0)
      ├─ @all 展开: dbGetGroupMembers → 过滤掉人类用户+发送者
      ├─ 过滤: 去掉 senderId(防自环) + 人类用户
      ├─ 频率限制: 同一对 senderId→botId 5秒冷却 (TRIGGER_COOLDOWN_MS)
      ├─ 构建个性化上下文:
      │   ├─ getGroupMessages(groupId, 20) → 取最近20条
      │   ├─ 筛选与目标Bot相关的消息 (isFromBot / mentionsBot / 最近5条)
      │   ├─ 去重+排序 → 格式化为 [时间] 发送者: 内容
      │   └─ 注入群名、Bot身份、风格处理器
      ├─ openclawClient.sendMessage(botId, context, null, 'group', sessionId, style)
      ├─ 回复处理:
      │   ├─ _extractPlainText(response) → 提炼纯文本
      │   ├─ _isBotProcessContent() → 过滤过程内容
      │   ├─ saveGroupMessage(groupId, botId, botDisplayName, text, [])
      │   └─ wsManager.broadcast({ type: 'group_message' })
      ├─ 递归触发: Bot回复中的 @mentions → _triggerMentionedBots(depth+1)
      │   └─ MAX_TRIGGER_DEPTH=1, depth>=1时停止
      └─ 自检 (仅 depth===0):
          ├─ completionChecker.check(userMsg, botReply, style)
          └─ INCOMPLETE → selfReviewService.executeReview() → 追加补充消息
```

### 2.2 botSendToGroup — Bot 主动发群聊消息

```
POST /api/bot/send-to-group
Body: { botId, groupId, content, mentions[] }
│
├─ 1. 参数验证 (botId, groupId, content)
├─ 2. _resolveBotDisplayName(botId) → 中文昵称 (从 ai-directory.json)
├─ 3. await saveGroupMessage(groupId, botId, displayName, content, mentions)
├─ 4. wsManager.broadcast({ type: 'group_message', groupId, message })
├─ 5. res.json({ success: true, messageId, mentionsCount }) ← 立即返回
│
├─ 6. [异步] 人类用户通知处理:
│     └─ for each mention:
│         ├─ _isHumanUser(mentionedId)? (admin, user)
│         │   ├─ 在线 → wsManager.broadcast({ type: 'notification', userId, notification })
│         │   └─ 离线 → offlineQueue.enqueue(userId, notification)
│         └─ Bot → 由 _triggerMentionedBots 处理
│
├─ 7. [异步] _triggerMentionedBots({ groupId, senderId: botId, mentions, content, depth: 0 })
│     └─ (同 sendGroupMessage 流程 9)
│
└─ 8. [异步] appendToGroupChatHistory (保存到 chat_history 文件)
```

### 2.3 getGroupMentions — @mention 查询

```
GET /api/groups/:groupId/mentions?target=user&limit=30&context=2
│
├─ 1. 加载最多500条消息 getGroupMessages(groupId, 500)
├─ 2. 过滤含 @mention 的消息:
│     ├─ 解析 mentions 字段 (JSON.parse)
│     ├─ target='user'/'admin' → 匹配 'user'/'admin'/'all'
│     └─ target=botId → 匹配该 botId 或 'all'
├─ 3. 为每条 @mention 消息构建上下文:
│     ├─ context_before: 前 N 条消息摘要
│     ├─ context_after: 后 N 条消息摘要
│     ├─ sender_display: 从 ai-directory.json 解析中文昵称
│     ├─ mentions_display: [{id, name}]
│     └─ time_formatted: 完整时间字符串
└─ 4. 返回 { mentions[], total, filtered_by }
```

### 2.4 getAllGroups — 群组列表

```
GET /api/groups
│
├─ dbGetAllGroups() → groups[] (含 member_count, message_count)
├─ for each group:
│   └─ getLatestGroupMessage(group.id) → last_message?
│       └─ { sender, sender_name, content, timestamp }
└─ 返回 { success: true, groups: groupsWithLastMessage }
```

### 2.5 createGroup — 创建群组

```
POST /api/groups
Body: { groupName, description?, members[], creator? }
│
├─ 参数校验:
│   ├─ groupName 非空, 长度 ≤ 50
│   ├─ description 长度 ≤ 500
│   └─ members.length ≤ 200 (MAX_MEMBERS)
├─ 重名检测: dbGetGroupByName(groupName) → 存在则 409
├─ creator: req.body.creator || req.headers['x-user-id'] || 'admin'
├─ dbCreateGroup(name, desc, creator, members, null, 'user')
├─ dbGetGroupById(groupId) → 返回完整群信息（减少前端二次请求）
└─ { success: true, groupId, group }
```

### 2.6 deleteGroup — 删除群组

```
DELETE /api/groups/:groupId
│
├─ dbGetGroupById(groupId) → 不存在则 404
├─ group.source === 'auto' → 403 (自动创建的群禁止手动删除)
├─ dbDeleteGroup(groupId) → 依次 DELETE members→messages→group
└─ { success: true, message: '群组已删除' }
```

---

## 三、GroupController 依赖注入

```javascript
class GroupController {
  constructor(dependencies) {
    this.wsManager              // WebSocket 广播管理器
    this.sessionManager         // 用户在线状态管理
    this.openclawSessionManager // OpenClaw 会话管理 (getGroupSession)
    this.offlineQueue           // 离线消息队列
    this.eventBus               // 事件总线
    this.taskDetector           // 任务意图检测器
    this.taskManager            // 任务管理器 (confirmToken)
    this.openclawClient         // OpenClaw API 客户端 (sendMessage)
    this.detectBotEnvironment   // Bot 环境检测 (local/filesystem)
    this.config                 // 配置对象 (含 getStyleProcessor)
    this.completionChecker      // 第一层: 回复完成度规则判断
    this.selfReviewService      // 第二层: AI 自检追问
  }
}

// 静态属性
GroupController.TRIGGER_COOLDOWN_MS = 5000    // 同一对 Bot 5秒冷却
GroupController._triggerCooldown = new Map()  // 冷却计时缓存
```

---

## 四、私有方法

| 方法 | 说明 |
|------|------|
| `_extractPlainText(content)` | 提取纯文本: 处理 JSON 格式 (payloads/response/message/text/content), 与 BotController 对齐 |
| `_isBotProcessContent(content)` | 检测过程内容: [thinking]/[progress]/[tool_call] 等模式, 与 BotController 对齐 |
| `_resolveBotDisplayName(botId)` | 从 ai-directory.json 解析中文昵称 (chinese_name → name → botId) |
| `_isHumanUser(id)` | 判断人类用户: `new Set(['admin', 'user'])` |
| `_triggerMentionedBots(params)` | **核心**: @Bot 统一触发逻辑, 含 @all展开/防循环/频率限制/上下文构建/自检 |
| `appendToGroupChatHistory(...)` | 写入 chat_history 文件: 部门感知路径 + 日期文件 + 倒序插入 + 消息计数 |

---

## 五、WS 推送消息格式

```javascript
// 群聊新消息
{
  type: 'group_message',
  groupId: number,
  message: {
    id: number,
    group_id: number,
    sender: string,         // 'user' | botId
    sender_name: string,    // 中文昵称
    senderName: string,     // 兼容字段
    content: string,
    timestamp: number,
    mentions: string[]      // botId[] 或 ['all']
  },
  sessionId?: string,       // OpenClaw session ID (Bot 回复时)
  isFollowUp?: boolean      // 自检补充消息标记
}

// @mention 通知 (发给人类用户)
{
  type: 'notification',
  userId: string,           // 'admin' (已修复 'user'→'admin' 映射)
  notification: {
    type: 'mention',
    groupId: number,
    from: string,           // 发送者 botId
    content: string,
    timestamp: number,
    messageId: number
  }
}

// 任务预览卡片
{
  type: 'task_preview',
  groupId: number,
  preview: {
    title: string,
    assignee: string,
    priority: string,
    deadline: string,
    confirmToken: string
  }
}
```

---

## 六、文件上传配置

```javascript
// groupRoutes.js — multer 配置
const groupFileUpload = multer({
  storage: multer.diskStorage({
    destination: 'uploads/groups/{groupId}/',    // 按群组ID分目录
    filename: '{timestamp}-{random}{ext}'        // 避免重名
  }),
  limits: { fileSize: 10 * 1024 * 1024 },       // 10MB
  fileFilter: /jpeg|jpg|png|gif|webp|pdf|doc|docx|xls|xlsx|txt|md|json/
})
```

---

## 七、后端文件地图

```
backend/
├── src/
│   ├── controllers/
│   │   └── groupController.js  (1790行) — 群聊所有业务逻辑
│   ├── routes/
│   │   └── groupRoutes.js      (123行)  — 路由注册 + multer配置
│   ├── utils/
│   │   ├── helpers.js          — duplicateCache
│   │   └── constants.js        — DUPLICATE_WINDOW_MS
│   └── services/
│       └── openclawSessionManager.js — getGroupSession(groupId)
├── db/
│   └── database.js             — 群聊相关建表 + 15个CRUD函数
└── group-sync.js               (339行) — 通讯录对账: 自动建群/同步成员/删多余群
```

---

## 八、关键设计决策

1. **立即返回 + 异步处理**: sendGroupMessage 和 botSendToGroup 都在保存消息后立即 res.json(), Bot 回复在 IIFE 中异步执行, 不阻塞用户

2. **防循环机制**: `_triggerMentionedBots` 使用 `triggerDepth` 参数, MAX_TRIGGER_DEPTH=1, 用户消息→Bot回复→Bot回复中的@不再触发

3. **频率冷却**: 同一对 senderId→botId 5秒内不重复触发 (TRIGGER_COOLDOWN_MS=5000, Map缓存)

4. **@all 展开**: `mentions.includes('all')` → dbGetGroupMembers → 过滤掉人类用户和发送者 → 合并去重

5. **自检追问**: 仅在 triggerDepth===0 (用户直接触发) 时执行 completionChecker + selfReviewService, 避免链式自检

6. **source 隔离**: 自动创建的群 (source='auto') 不允许手动删除, 由对账逻辑管理

7. **部门感知路径**: chat_history 文件路径通过 ai-directory.json 匹配群名→部门ID→departments/{deptId}/chat_history/, 多级回退确保找到目录

8. **人类用户ID映射**: `_isHumanUser()` 兼容 'admin' 和 'user' 两种历史 ID
