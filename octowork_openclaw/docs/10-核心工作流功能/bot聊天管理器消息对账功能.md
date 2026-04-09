# Bot 聊天管理器 — 消息对账功能

> 最后更新：2026-04-04  
> 状态：**全部 7 项问题已修复** (2×P0 + 3×P1 + 2×P2)

---

## 目录

1. [问题背景](#1-问题背景)
2. [消息完整链路（源码追踪）](#2-消息完整链路源码追踪)
3. [六层保障机制](#3-六层保障机制)
4. [发现的 7 项问题及修复详情](#4-发现的-7-项问题及修复详情)
5. [对账服务架构总览](#5-对账服务架构总览)
6. [前端对账感知](#6-前端对账感知)
7. [数据库路径配置](#7-数据库路径配置)
8. [数据库 Schema 速查](#8-数据库-schema-速查)
9. [API 端点速查](#9-api-端点速查)
10. [配置参考 (config.json)](#10-配置参考-configjson)
11. [组件依赖树](#11-组件依赖树)
12. [故障排查指南](#12-故障排查指南)

---

## 1. 问题背景

**核心症状**：Bot 聊天管理器 → OpenClaw 的消息发送 100% 可达，但 OpenClaw → Bot 聊天管理器的回复**间歇性丢失**——有时到、有时不到。

**影响**：用户发送消息后，界面上看不到 Bot 回复；刷新页面后（前端轮询从 DB 拉取）才能看到回复——说明消息已写入 DB，但 WebSocket 推送环节断裂。

**断裂点分析**：

```
OpenClaw 回复正文
  ↓ stdout（可能含时间戳/日志前缀）
server.js JSON 解析      ← 🔴 P0-1: Math.max 选错起始位置
  ↓ botResponse
saveMessage()             ← 🟡 P1-4: is_pushed 可能为 NULL
  ↓ botMessageId
wsManager.sendToUser()    ← 🟡 P1-3: WS login 握手窗口期
  ├── 成功 → is_pushed=1
  └── 失败 → is_pushed=0
       ├── 3s 快速重试     ← P1-3 修复
       ├── offlineQueue     ← P1-5: 路径曾硬编码
       └── 对账服务 30s     ← 🟢 P2-6: 无锁竞争
前端 WS handler           ← 🟢 P2-7: 仅当前 Bot
```

---

## 2. 消息完整链路（源码追踪）

### 2.1 发送链路 (`sendMessage`)

```
用户输入
  ↓
前端 MessageInput @send → useSingleChat.handleSend()
  ↓
POST /api/messages/:botId  ← botController.sendMessage()
  ↓  ① normalizeUserId(rawUserId) → 规范化用户 ID
  ↓  ② 重复消息检测 (DUPLICATE_WINDOW_MS)
  ↓  ③ detectBotEnvironment(botId) → 识别 local/openclaw
  ↓  ④ openclawSessionManager.getUserBotSession(userId, botId) → sessionId
  ↓     格式: "user_{userId}_bot_{botId}"
  ↓  ⑤ extractPlainText(content) → 提炼纯文本 (处理 JSON)
  ↓  ⑥ 处理图片上传 (multer → /uploads/images/)
  ↓  ⑦ saveMessage(sessionId, 'user', ..., is_pushed=1)  ← 用户消息无需推送
  ↓  ⑧ appendToChatHistory() → 写入 .md 聊天记录
  ↓  ⑨ taskMonitor.createTask(botId, content, model)
  ↓  ⑩ res.json() ← 立即返回 (不阻塞前端)
  ↓
  └─ ⑪ 异步 Bot 回复 (OpenClaw)
```

### 2.2 回复链路（异步，对账核心路径）

```
⑪ OpenClawClient.sendMessage(botId, content, model, userId, sessionId, style, imageUrl)
  ↓  spawn('openclaw', ['agent', '--agent', botId, '--message', msg, '--json'])
  ↓  等待进程结束 (600s 超时, 10MB stdout 缓冲)
  ↓  JSON 解析: Math.min(indexOf('{'), indexOf('[')) 取首个有效起始位
  ↓  失败后 fallback: 逐字符回退解析 / 正则提取 "text"
  ↓
⑫ extractPlainText(response) → 提炼 Bot 回复
  ↓ isBotProcessContent() → 过滤思考过程/进度日志
  ↓
⑬ saveMessage(sessionId, 'bot', ..., is_pushed=0)  ← Bot 消息默认未推送
  ↓ appendToChatHistory()
  ↓ taskMonitor.updateTaskStatus(taskId, 'completed')
  ↓
⑭ wsManager.sendToUser(normalizedUserId, wsMessage)
  ├── 成功 → markMessageAsPushed(botMessageId) → is_pushed=1
  └── 失败 →
       ├── 【L1.5】setTimeout 3s 快速重试
       │     ├── 成功 → markMessageAsPushed()
       │     └── 失败 → 等待对账服务或前端轮询
       └── offlineQueue.enqueue(userId, wsMessage)  ← 双重保险
```

### 关键源文件

| 文件 | 职责 | 核心行号 |
|------|------|---------|
| `backend/server.js` L338-621 | OpenClawClient 类 — spawn CLI、解析 JSON 响应 | L468-476 JSON 起始位 |
| `backend/src/controllers/botController.js` L181-418 | sendMessage — 异步回调 + WS 推送 + 3s 重试 | L370-418 推送逻辑 |
| `backend/src/controllers/botController.js` L1460-1520 | sendToUser — Bot 主动消息 | L1468-1470 sessionId |
| `backend/websocket/user-manager.js` | 统一 WS 管理器（单例），sendToUser 按 userId 推送 | — |
| `backend/services/message-reconciliation-enhanced.js` | 增强对账服务 — 扫描 + 先标记后推送 | L149-280 |
| `backend/src/services/offlineQueue.js` | 离线队列 — 用户上线时投递积压消息 | L18 路径推导 |
| `backend/db/database.js` | SQLite 层 — saveMessage / findUnpushedBotMessages / markMessageAsPushed | L253-263, L567-589, L640-680 |
| `frontend/.../composables/useSingleChat.ts` L648-710 | 前端 30s 轮询 + 60s 全 Bot 未读轮询 | L688-698 |
| `frontend/.../composables/useWebSocket.ts` L364-410 | WS `bot_message` handler — 去重 + 未读计数 | L372-388 |

---

## 3. 六层保障机制

| 层 | 机制 | 触发时机 | 覆盖场景 | 代码位置 |
|----|------|---------|---------|---------|
| **L1** | 正常 WS 推送 | bot 回复入库后立即执行 | 用户在线且 WS 正常 | botController L371 |
| **L1.5** | **3s 快速重试** | 首次推送失败后 3s | WS login 握手时序窗口 | botController L386-399 |
| **L2** | 对账服务补推 | 每 30s 扫描 `is_pushed=0` | WS 瞬时断连、推送异常 | reconciliation L149-199 |
| **L3** | 前端轮询 (当前 Bot) | 每 30s `GET /api/messages` | WS 断连且对账也失败 | useSingleChat L648-665 |
| **L3.5** | **后台未读轮询 (全 Bot)** | 每 60s `loadRecentSessions` | 非当前 Bot 的未读更新 | useSingleChat L688-698 |
| **L4** | 离线队列 | 用户上线时自动投递 | 用户长时间离线 | offlineQueue + server.js L805 |

### 保障时间线示例

```
t=0s     Bot 回复入库 (is_pushed=0)
         ↓ L1: wsManager.sendToUser()
t=0.1s   推送失败（WS 未 login）
         ↓
t=3s     L1.5: 3s 快速重试
         ↓ 推送成功 → is_pushed=1 → 链路闭合 ✅
         ↓ 仍失败 ↓
t=30s    L2: 对账服务扫描 → 先 markMessageAsPushed (乐观锁) → 推送
         ↓ 用户仍离线 ↓
t=30s    L3: 前端轮询 GET /api/messages → 从 DB 直接拉取 ✅
t=60s    L3.5: 后台轮询 loadRecentSessions → 侧边栏未读计数更新 ✅
         ↓ 用户长期离线 ↓
t=上线    L4: offlineQueue.dequeue(userId) → 批量推送积压消息 ✅
```

---

## 4. 发现的 7 项问题及修复详情

### 🔴 P0-1 — JSON 解析起始位置选错

| 项 | 内容 |
|------|------|
| **位置** | `server.js` L468-476 |
| **根因** | OpenClaw CLI stdout 含时间戳前缀，代码用 `Math.max(indexOf('{'), indexOf('['))` 取最大值，当 `{` 在 `[` 前面时跳过了正确起始位 |
| **后果** | JSON 解析失败 → `result.success = false` → bot 回复不写 DB → 前端永远看不到 |
| **状态** | ✅ 已修复 |

**修复代码** (`server.js` L468-476)：
```js
// 修复前：Math.max(braceIdx, bracketIdx)
// 修复后：取第一个出现的有效 JSON 起始字符
const braceIdx = jsonStr.indexOf('{')
const bracketIdx = jsonStr.indexOf('[')
const jsonStartIndex = braceIdx === -1 ? bracketIdx
  : bracketIdx === -1 ? braceIdx
  : Math.min(braceIdx, bracketIdx)
```

---

### 🔴 P0-2 — sendToUser 的 sessionId 格式不一致

| 项 | 内容 |
|------|------|
| **位置** | `botController.js` L1468-1473 |
| **根因** | `sendToUser` 直接把 `botId` 当 `sessionId` 传给 `saveMessage`，而正常 `sendMessage` 用 `user_{userId}_bot_{botId}` |
| **后果** | session 表 ID 不一致 → `loadRecentSessions` 漏掉 Bot 主动消息 → 前端看不到 |
| **状态** | ✅ 已修复 |

**修复代码** (`botController.js` L1468-1473)：
```js
// 修复前：saveMessage(botId, 'bot', ...)
// 修复后：
const sessionId = `user_${userId}_bot_${botId}`
await saveMessage(
  sessionId,       // sessionId — 格式统一为 user_{userId}_bot_{botId}
  'bot', botId, content, true, botId, botId
)
```

同时 WS 推送 payload 和 offlineQueue 入队时也携带了正确的 `sessionId`。

---

### 🟡 P1-3 — WS login 握手时序窗口导致推送失败

| 项 | 内容 |
|------|------|
| **位置** | `botController.js` L383-399 |
| **根因** | WS 连接建立后需发 `{ type: 'login', userId }` 才注册映射，此前数百毫秒窗口内 `sendToUser` 返回 `false` |
| **后果** | OpenClaw 快速回复时（<1s），WS 还未 login → 推送失败 → 依赖 30s 对账服务，体验差 |
| **状态** | ✅ 已修复 — 添加 3s 快速重试 |

**修复代码** (`botController.js` L383-399)：
```js
} else {
  // 🔧 推送失败后立即安排 3s 快速重试
  console.log(`⏳ 用户 ${normalizedUserId} 首次推送失败，3s 后快速重试...`)
  setTimeout(async () => {
    try {
      const retried = this.wsManager.sendToUser(normalizedUserId, wsMessage)
      if (retried) {
        console.log(`✅ [3s重试] Bot回复已补推给用户 ${normalizedUserId}`)
        await markMessageAsPushed(botMessageId)
      } else {
        console.log(`⏳ [3s重试] 仍无活跃连接，等待对账服务或前端轮询`)
      }
    } catch (retryErr) {
      console.error(`❌ [3s重试] 补推失败:`, retryErr.message)
    }
  }, 3000)

  // 同时存入离线队列作为双重保险
  if (this.offlineQueue) {
    await this.offlineQueue.enqueue(normalizedUserId, { ... sessionId ... })
  }
}
```

---

### 🟡 P1-4 — saveMessage 未显式写入 `is_pushed`

| 项 | 内容 |
|------|------|
| **位置** | `database.js` L253-263 |
| **根因** | INSERT 语句不含 `is_pushed`，依赖 `ALTER TABLE ADD COLUMN ... DEFAULT 0`，SQLite 某些版本可能留 NULL |
| **后果** | `findUnpushedBotMessages` 用 `is_pushed=0 OR is_pushed IS NULL` 兜底，但历史已推送消息也被扫描 → 无效重复推送 |
| **状态** | ✅ 已修复 |

**修复代码** (`database.js` L253-263)：
```js
// 用户消息: is_pushed=1（前端自己发的，不需要推送）
// Bot消息: is_pushed=0（等待 WS 推送）
const isPushed = isBot ? 0 : 1

db.run(
  `INSERT INTO messages (..., is_pushed) VALUES (..., ?)`,
  [...params, isPushed]
)
```

---

### 🟡 P1-5 — OfflineQueue storageDir 硬编码为相对路径

| 项 | 内容 |
|------|------|
| **位置** | `offlineQueue.js` L18 |
| **根因** | `path.join(__dirname, '../../data/offline_queue')` → 指向代码仓库内部 |
| **后果** | 离线队列数据与代码目录耦合，多用户部署冲突，路径与 `chat.db` 不一致 |
| **状态** | ✅ 已修复 |

**修复代码** (`offlineQueue.js`)：
```js
function getDefaultOfflineQueueDir() {
  const workspace = process.env.OCTOWORK_WORKSPACE
    || path.join(process.env.HOME || process.env.USERPROFILE || '/tmp', 'octowork')
  return path.join(workspace, 'data', 'offline_queue')
}

// 构造函数中
this.options = {
  storageDir: options.storageDir || getDefaultOfflineQueueDir(),
  ...
}
```

---

### 🟢 P2-6 — 对账补推与正常推送竞争导致重复

| 项 | 内容 |
|------|------|
| **位置** | `database.js` L567-589 + `message-reconciliation-enhanced.js` L254-261 |
| **根因** | 正常流程和对账服务同时读到 `is_pushed=0` 并推送，缺少锁 |
| **后果** | 前端可能收到重复消息（虽有前端去重，但不可靠） |
| **状态** | ✅ 已修复 — 乐观锁 + 先标记后推送 |

**修复代码**：

`database.js` — `markMessageAsPushed` 加乐观锁：
```js
// WHERE is_pushed = 0：只有第一个调用者能成功标记
const query = `UPDATE messages SET is_pushed = 1 WHERE id = ? AND is_pushed = 0`
// this.changes === 0 表示已被其他流程标记 → 返回 false
```

`message-reconciliation-enhanced.js` — 先标记后推送：
```js
// 先尝试占位（CAS 语义）
const claimed = await markMessageAsPushed(messageId)
if (!claimed) {
  // 已被正常流程标记，跳过
  return
}
// 占位成功，再执行推送
wsManager.sendToUser(userId, wsPayload)
```

---

### 🟢 P2-7 — 前端轮询仅覆盖当前选中 Bot

| 项 | 内容 |
|------|------|
| **位置** | `useSingleChat.ts` L688-710 |
| **根因** | 30s 轮询只调 `loadMessagesLocal(selectedBot)`，其他 Bot 的 WS 推送失败时前端无感知 |
| **后果** | 非当前 Bot 的未读消息计数不及时更新 |
| **状态** | ✅ 已修复 — 新增 60s 全 Bot 未读轮询 |

**修复代码** (`useSingleChat.ts` L688-710)：
```typescript
const UNREAD_POLLING_MS = 60000

function startUnreadPolling() {
  stopUnreadPolling()
  unreadPollingId.value = window.setInterval(async () => {
    if (document.visibilityState !== 'visible') return
    try {
      await loadRecentSessions()  // 拉取所有 Bot 的最新 session 信息
    } catch (err) {
      // 静默忽略
    }
  }, UNREAD_POLLING_MS)
}

// 组件挂载后立即启动
startUnreadPolling()
```

---

## 5. 对账服务架构总览

### 服务概览

```
┌─────────────────────────────────────────────────────────┐
│             EnhancedMessageReconciliation                │
│         message-reconciliation-enhanced.js               │
├─────────────────────────────────────────────────────────┤
│  启动: server.js L1307  messageReconciliation.start()    │
│  停止: server.js L1392  messageReconciliation.stop()     │
│  配置: backend/config.json → reconciliation 节点         │
├─────────────────────────────────────────────────────────┤
│  参数:                                                   │
│    scanInterval:      30000 ms (30 秒)                   │
│    timeWindowMinutes: config.json 中为 4320 (3天)        │
│                       代码默认值 60 (1小时)               │
│    maxRetryAttempts:  3 次                               │
│    冷却: 同一消息 60 秒内不重复处理                       │
│    清理: 24 小时自动清理内存记录                          │
├─────────────────────────────────────────────────────────┤
│  扫描流程:                                               │
│    1. findUnpushedBotMessages(timeWindowMinutes)         │
│       → SELECT * FROM messages                           │
│         WHERE is_bot=1                                   │
│           AND (is_pushed=0 OR is_pushed IS NULL)         │
│           AND timestamp > (now - window)                 │
│    2. 逐条处理 → repushBotMessage(msg)                   │
│       a. shouldSkipMessage → 防重复检查                  │
│       b. markMessageAsPushed (乐观锁) → 先占位           │
│       c. claimed=false → 跳过 (已被其他流程处理)          │
│       d. claimed=true → wsManager.sendToUser() 推送      │
│       e. 用户离线 → is_pushed 保持 0，下次重试            │
├─────────────────────────────────────────────────────────┤
│  API 端点:                                               │
│  GET  /api/reconciliation/stats  → 统计信息              │
│  POST /api/reconciliation/scan   → 手动触发扫描          │
│  POST /api/reconciliation/reset  → 重置统计              │
└─────────────────────────────────────────────────────────┘
```

### 内存防重复机制

对账服务维护一个 `Map<messageId, ProcessingRecord>`:

```js
ProcessingRecord = {
  attempts: number,      // 已重试次数
  lastAttempt: number,   // 上次处理时间戳
  success: boolean,      // 是否最终成功
  errors: string[],      // 错误信息列表
  startTime: number      // 首次处理时间
}
```

- 同一消息 60s 内不重复处理
- 超过 `maxRetryAttempts` (默认 3) 次后永久跳过
- 24h 自动清理 stale 记录，释放内存

---

## 6. 前端对账感知

### 6.1 WS `bot_message` Handler

`useWebSocket.ts` L364-410：

```typescript
function handleBotNewMessage(data: any) {
  const { botId, message } = data

  // 去重：按 ID 或内容+时间戳双重校验
  const existsInCache = allBotMessages.value[botId].some(m => m.id === message.id)
  if (!existsInCache) {
    allBotMessages.value[botId].push(message)
  }

  if (selectedBot.value?.id === botId) {
    // 当前 Bot → 直接插入消息列表
    const exists = messages.value.some(m =>
      m.id === message.id ||
      (m.content === message.content && Math.abs(m.timestamp - message.timestamp) < 1000)
    )
    if (!exists) {
      messages.value.push(message)
      scrollToBottom()
    }
  } else {
    // 其他 Bot → 增加未读计数 + 弹通知 (主动消息)
    botUnreadCounts.value[botId]++
  }
}
```

**对账消息的前端处理**：对账服务推送的消息携带 `isReconciled: true` 标记，但前端不做特殊处理——走同一个 `handleBotNewMessage`，由 `message.id` 去重保证不重复显示。

### 6.2 轮询兜底

| 轮询 | 间隔 | 范围 | 条件 | 代码 |
|------|------|------|------|------|
| 当前 Bot 消息 | 30s | `selectedBot` | 页面可见 + Bot 已选中 | `useSingleChat L648-665` |
| 全 Bot 未读计数 | 60s | 所有 Bot | 页面可见 | `useSingleChat L688-698` |

轮询从 `GET /api/messages/:botId` 和 `GET /api/sessions` 拉取数据，绕过 WS 直接读 DB。

### 6.3 自动刷新与生命周期

```typescript
onUnmounted(() => {
  stopMessagesAutoRefresh()   // 停止消息自动刷新
  stopPolling()               // 停止当前 Bot 轮询
  stopUnreadPolling()         // 停止全 Bot 未读轮询
  clearTimeout(saveMessagesTimeout.value)
})
```

---

## 7. 数据库路径配置

### ⭐ 核心规则：数据永远在 `~/octowork/data/`

聊天管理器项目（无论 `octowork-chat-dev` 还是 `octowork-chat`）只是**客户端程序**，数据存储在用户根目录的 `~/octowork/data/` 下：

```
~/
├── .openclaw/          ← 执行层 (AI 引擎)
├── octowork/           ← 数字公寓 (共享数据)
│   ├── data/
│   │   ├── chat.db             ⭐ 聊天数据库
│   │   └── offline_queue/      ⭐ 离线队列持久化
│   └── config/ai-directory.json
├── octowork-chat-dev/  ← 开发版聊天管理器
└── octowork-chat/      ← 用户版聊天管理器
```

### 路径推导逻辑（四个文件统一）

```js
// 所有服务共用同一推导逻辑：
const workspace = process.env.OCTOWORK_WORKSPACE
  || path.join(process.env.HOME || process.env.USERPROFILE, 'octowork')

// 数据库：  ${workspace}/data/chat.db
// 离线队列：${workspace}/data/offline_queue/
```

| 文件 | 推导逻辑 | 默认结果 |
|------|---------|---------|
| `database.js` | `OCTOWORK_WORKSPACE` → `$HOME/octowork` | `~/octowork/data/chat.db` |
| `offlineQueue.js` | 同上 | `~/octowork/data/offline_queue/` |
| `messageSummaryService.js` | 同上 | `~/octowork/data/chat.db` |
| `botController.js` `getWorkspaceRoot()` | 同上 | `~/octowork/` |

### 自动创建

若 `~/octowork/data/` 目录不存在，`database.js` 和 `offlineQueue.js` 均自动调用 `fs.mkdirSync(dir, { recursive: true })` 创建。

---

## 8. 数据库 Schema 速查

### messages 表（对账核心）

```sql
CREATE TABLE IF NOT EXISTS messages (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id      TEXT NOT NULL,       -- 格式: user_{userId}_bot_{botId}
  sender          TEXT NOT NULL,       -- 'user' | 'bot'
  sender_name     TEXT,
  content         TEXT NOT NULL,
  timestamp       INTEGER NOT NULL,    -- 毫秒时间戳
  is_bot          BOOLEAN DEFAULT 0,   -- 1 = bot 消息
  bot_id          TEXT,                -- botId (用于按 bot 查询)
  bot_name        TEXT,
  remote_reply_id TEXT UNIQUE,         -- OpenClaw 去重用
  execution_logs  TEXT,                -- 已废弃，触发器强制 NULL
  is_pushed       BOOLEAN DEFAULT 0,   -- 0=未推送, 1=已推送 ← 对账核心
  image_url       TEXT                 -- 图片上传 URL
);
```

### sessions 表

```sql
CREATE TABLE IF NOT EXISTS sessions (
  id             TEXT PRIMARY KEY,     -- 格式同 session_id
  bot_id         TEXT NOT NULL,
  bot_name       TEXT NOT NULL,
  created_at     INTEGER NOT NULL,
  last_active    INTEGER NOT NULL,
  message_count  INTEGER DEFAULT 0
);
```

### 对账相关 SQL

```sql
-- 查询未推送 Bot 消息（对账服务核心查询）
SELECT * FROM messages
WHERE is_bot = 1
  AND (is_pushed = 0 OR is_pushed IS NULL)
  AND timestamp > ?;    -- 时间窗口下界 (毫秒)

-- 标记已推送（乐观锁：只有 is_pushed=0 时才更新）
UPDATE messages SET is_pushed = 1 WHERE id = ? AND is_pushed = 0;
-- changes=0 表示已被其他流程标记 → 跳过推送
```

### DB 函数速查

| 函数 | 文件行号 | 说明 |
|------|---------|------|
| `saveMessage(sessionId, sender, ..., isPushed)` | database.js L209 | 核心写入，自动维护 sessions 表 |
| `getMessages(sessionId, limit, offset)` | database.js L284 | 按 bot_id 查询（从 sessionId 提取） |
| `markMessageAsPushed(messageId)` | database.js L569 | 乐观锁标记，返回 `true`/`false` |
| `findUnpushedBotMessages(timeWindowMinutes)` | database.js L640 | 扫描未推送 Bot 消息 |
| `getSessions()` | database.js L318 | 获取所有 session（含 message_count） |
| `clearMessagesByBotId(botId)` | database.js L341 | 按 bot_id 删除消息 |

---

## 9. API 端点速查

### 消息相关

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/messages/:botId?limit=50&offset=0` | 获取消息历史 |
| POST | `/api/messages/:botId` | 发送消息（核心） |
| DELETE | `/api/messages/:botId` | 清空消息 |
| POST | `/api/bot/send-to-user` | Bot 主动消息 `{botId, userId, content}` |
| GET | `/api/sessions` | 获取最近会话列表 |

### 对账服务

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/reconciliation/stats` | 运行统计（扫描次数、成功/失败数、处理时间） |
| POST | `/api/reconciliation/scan` | 手动触发一次对账扫描 |
| POST | `/api/reconciliation/reset` | 重置统计计数器 |

### WS 推送格式

```json
{
  "type": "bot_message",
  "botId": "octo-pm",
  "userId": "admin",
  "sessionId": "user_admin_bot_octo-pm",
  "message": {
    "id": 12345,
    "sender": "bot",
    "content": "回复内容...",
    "timestamp": 1743724800000,
    "userId": "admin",
    "sessionId": "user_admin_bot_octo-pm",
    "isReconciled": true          // 对账补推时为 true，正常推送无此字段
  }
}
```

---

## 10. 配置参考 (config.json)

```jsonc
// backend/config.json
{
  "server": {
    "port": 1314,
    "host": "localhost"
  },
  "reconciliation": {
    "enabled": true,
    "scanInterval": 30000,          // 扫描间隔 (ms)，默认 30s
    "timeWindowMinutes": 4320,      // 扫描窗口 (min)，当前配置 3 天 (72h)
    "replyTimeoutSeconds": 30,      // 回复超时判定
    "maxRetryAttempts": 3,          // 每条消息最大重试次数
    "alerts": {
      "enabled": false,             // 是否启用 webhook 告警
      "webhookUrl": "",             // 企微机器人 webhook
      "minMissingMessagesForAlert": 1
    }
  },
  "webhook": {
    "enabled": true,
    "url": "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
  }
}
```

> **注意**：`timeWindowMinutes` 代码默认值为 60，但 `config.json` 覆盖为 4320（3 天）。
> 实际运行时以 `config.json` 为准。如数据量大，建议调小此值以减少扫描开销。

---

## 11. 组件依赖树

### 后端对账链路

```
server.js (主入口)
├── new EnhancedMessageReconciliation(config)     ← 对账服务实例化
│   ├── findUnpushedBotMessages()                  ← 从 database.js 导入
│   ├── markMessageAsPushed()                      ← 从 database.js 导入
│   └── wsManager.sendToUser()                     ← 从 websocket/user-manager.js 导入 (单例)
│
├── botController.sendMessage()                    ← 正常聊天回复推送
│   ├── openclawClient.sendMessage()               ← server.js 内 OpenClawClient
│   ├── saveMessage()                              ← database.js
│   ├── markMessageAsPushed()                      ← database.js
│   ├── wsManager.sendToUser()                     ← 单例
│   └── offlineQueue.enqueue()                     ← offlineQueue.js
│
├── botController.sendToUser()                     ← Bot 主动消息推送
│   ├── saveMessage()                              ← database.js
│   ├── markMessageAsPushed()                      ← database.js
│   ├── wsManager.sendToUser()                     ← 单例
│   └── offlineQueue.enqueue()                     ← offlineQueue.js
│
└── WebSocket server (login/logout)
    ├── wsManager.addClient() / addUserClient()    ← 注册连接
    └── offlineQueue.dequeue(userId)               ← 登录时投递离线消息
```

### 前端对账链路

```
App.vue
├── useWebSocket.ts                                ← WS 连接管理
│   ├── onMessage → switch(type)
│   │   └── 'bot_message' → handleBotNewMessage()  ← 去重 + 插入/未读计数
│   └── reconnect → login → 触发 offlineQueue 投递
│
└── useSingleChat.ts                               ← 消息管理
    ├── startPolling()                             ← 30s 当前 Bot 轮询
    │   └── GET /api/messages/:botId
    ├── startUnreadPolling()                       ← 60s 全 Bot 未读轮询
    │   └── loadRecentSessions() → GET /api/sessions
    └── onUnmounted → stop all polling
```

---

## 12. 故障排查指南

### 常用命令

```bash
# 查看对账服务运行状态
curl http://localhost:1314/api/reconciliation/stats

# 手动触发一次对账扫描
curl -X POST http://localhost:1314/api/reconciliation/scan

# 查看数据库中未推送的 bot 消息
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, bot_id, substr(content,1,40), is_pushed,
          datetime(timestamp/1000,'unixepoch','localtime')
   FROM messages
   WHERE is_bot=1 AND (is_pushed=0 OR is_pushed IS NULL)
   ORDER BY timestamp DESC LIMIT 20;"

# 查看 session 表最近活跃
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, bot_name, message_count,
          datetime(last_active/1000,'unixepoch','localtime')
   FROM sessions ORDER BY last_active DESC LIMIT 10;"

# 查看离线队列文件
ls -la ~/octowork/data/offline_queue/

# 检查数据库路径是否正确
node -e "
  const ws = process.env.OCTOWORK_WORKSPACE
    || require('path').join(process.env.HOME, 'octowork');
  console.log('DB path:', require('path').join(ws, 'data', 'chat.db'));
"
```

### 常见问题

| 症状 | 可能原因 | 排查方法 |
|------|---------|---------|
| Bot 回复完全不出现 | JSON 解析失败 | 看后端日志是否有 `🚨 已清理时间戳前缀` 或 `JSON解析失败` |
| 回复延迟 30s+ | WS 推送失败，等对账服务 | 检查 `is_pushed` 状态；看是否有 `⏳ 首次推送失败` 日志 |
| 回复延迟 3-5s | 正常 — WS login 窗口期 + 3s 重试 | 看 `[3s重试] Bot回复已补推` 日志 |
| 切换 Bot 后才看到消息 | 轮询只覆盖当前 Bot | 检查 60s 全 Bot 轮询是否正常启动 |
| 收到重复消息 | 对账与正常流程竞争 | 检查 `markMessageAsPushed` 日志是否有 `changes=0` |
| 数据库文件不在预期位置 | 环境变量配置错误 | 运行上方 node 命令检查路径 |
| 用户上线后无离线消息 | 离线队列路径错误 | `ls ~/octowork/data/offline_queue/` 检查是否有数据 |

---

## 修复总结

| # | 问题 | 级别 | 状态 | 改动文件 | 改动量 |
|---|------|------|------|---------|--------|
| 1 | JSON 解析 `Math.max` → `Math.min` | P0 | ✅ | server.js | ~5 行 |
| 2 | sendToUser sessionId 格式统一 | P0 | ✅ | botController.js | ~3 行 |
| 3 | WS 推送 3s 快速重试 | P1 | ✅ | botController.js | ~20 行 |
| 4 | saveMessage 显式写入 `is_pushed` | P1 | ✅ | database.js | ~5 行 |
| 5 | OfflineQueue storageDir 动态推导 | P1 | ✅ | offlineQueue.js | ~10 行 |
| 6 | `markMessageAsPushed` 乐观锁 + 先标记后推送 | P2 | ✅ | database.js + reconciliation | ~10 行 |
| 7 | 后台 60s 全 Bot 未读轮询 | P2 | ✅ | useSingleChat.ts | ~25 行 |

**总计**: 7 文件，127 insertions，38 deletions
