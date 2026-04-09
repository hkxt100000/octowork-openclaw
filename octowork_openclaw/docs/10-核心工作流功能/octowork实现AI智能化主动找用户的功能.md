# OctoWork — AI 智能化主动找用户的功能

> 最后更新：2026-04-04  
> 状态：功能已实现，全链路验证通过

---

## 一、功能定义

传统 AI 助手是"被动应答"——用户不问，AI 不说。OctoWork 让 AI 员工具备**主动联系用户**的能力：

- Bot 完成任务后主动汇报结果
- Bot 发现异常后主动告警
- Bot 按计划发送定时提醒
- Bot 心跳检查后主动通知状态

**核心 API**：`POST /api/bot/send-to-user`

---

## 二、完整链路（源码级追踪）

### 2.1 链路概览

```
外部调用者（OpenClaw Agent / 定时任务 / 心跳脚本）
  ↓
POST /api/bot/send-to-user  {botId, userId, content, type, metadata}
  ↓
botController.sendToUser()  ← backend/src/controllers/botController.js L1427
  ↓
┌─ ① 参数验证（botId, userId, content 不能为空）
├─ ② extractPlainText(content) → 处理 JSON 格式消息
├─ ③ cleanMessageMetadata(metadata) → 清理 metadata 防止过大
├─ ④ 构造 sessionId = "user_{userId}_bot_{botId}"
├─ ⑤ saveMessage(sessionId, 'bot', ..., is_pushed=0) → 写入 DB
├─ ⑥ appendToChatHistory() → 写入 .md 聊天记录
├─ ⑦ 检查用户在线状态
│   ├── 在线 → wsManager.sendToUser() → WS 实时推送
│   │   ├── 成功 → markMessageAsPushed() → is_pushed=1
│   │   └── 失败 → 不标记，留待对账服务
│   └── 离线 → offlineQueue.enqueue() → 用户上线后投递
└─ ⑧ 返回 JSON 响应
```

### 2.2 请求格式

```http
POST http://localhost:1314/api/bot/send-to-user
Content-Type: application/json

{
  "botId": "octotech-chief",          // 发送者 Bot ID (必填)
  "userId": "admin",                   // 接收者用户 ID (必填)
  "content": "项目进度已更新，请查看",    // 消息内容 (必填)
  "type": "proactive",                 // 消息类型 (可选，默认 proactive)
  "metadata": {                        // 元数据 (可选)
    "projectId": "project-001"
  }
}
```

### 2.3 响应格式

**用户在线 — 实时推送成功**：
```json
{
  "success": true,
  "messageId": 6388,
  "delivery": "realtime",
  "pushed": true,
  "message": "Bot消息已实时推送"
}
```

**用户在线 — WS 推送失败**（对账服务后续补推）：
```json
{
  "success": true,
  "messageId": 6388,
  "delivery": "realtime",
  "pushed": false,
  "message": "Bot消息推送失败，已存入数据库"
}
```

**用户离线 — 存入离线队列**：
```json
{
  "success": true,
  "messageId": 6388,
  "delivery": "queued",
  "message": "Bot消息已存入离线队列，用户上线后推送"
}
```

---

## 三、消息投递保障（六层机制）

sendToUser 的消息投递与 sendMessage 共享同一套六层保障：

| 层 | 机制 | 触发条件 |
|----|------|---------|
| L1 | WS 实时推送 | 用户在线，`sendToUser` 立即推送 |
| L1.5 | _(sendToUser 无 3s 重试)_ | 仅 sendMessage 异步回调中有 |
| L2 | 对账服务 30s 补推 | `is_pushed=0` 的 Bot 消息被扫描并补推 |
| L3 | 前端 30s 轮询 | 当前 Bot 的 `GET /api/messages` |
| L3.5 | 后台 60s 全 Bot 未读轮询 | `loadRecentSessions()` |
| L4 | 离线队列 | 用户上线时 `offlineQueue.dequeue()` |

> 注意：sendToUser 在推送失败时**没有**像 sendMessage 那样做 3s 快速重试（L1.5），因为 sendToUser 在 HTTP 请求中同步判断在线状态，不存在"Bot回复速度快于WS登录"的时序问题。如果判断为在线但推送失败（刚离线），对账服务 L2 会在 30s 内补推。

---

## 四、前端接收处理

### 4.1 WS Handler

前端通过 `useWebSocket.ts` 的 `handleBotNewMessage` 统一处理所有 `type: 'bot_message'` 消息，不区分是正常回复还是 Bot 主动消息：

```typescript
// useWebSocket.ts L364
function handleBotNewMessage(data: any) {
  const { botId, message } = data

  // 按 message.id 去重
  const existsInCache = allBotMessages.value[botId].some(m => m.id === message.id)
  if (!existsInCache) {
    allBotMessages.value[botId].push(message)
  }

  if (selectedBot.value?.id === botId) {
    // 当前 Bot → 插入消息列表 + 滚到底部
    // 双重去重：ID + 内容+时间戳
  } else {
    // 其他 Bot → 增加未读计数
    botUnreadCounts.value[botId]++
    // 主动消息弹通知
    if (message.type === 'proactive' || message.type === 'heartbeat' || message.type === 'task_reminder') {
      ElNotification({ title: `${getBotName(botId)} 发来消息`, ... })
    }
  }
}
```

### 4.2 主动消息弹窗通知

当 Bot 主动发送的消息到达时，如果用户不在该 Bot 的聊天页面，前端会弹出 `ElNotification` 通知，点击可跳转到对应 Bot 聊天。

WS 推送 payload 中的 `message.type` 字段区分消息类型：
- `proactive` — 主动汇报
- `heartbeat` — 心跳检查结果
- `task_reminder` — 任务提醒

---

## 五、三种触发维度

Bot 主动找用户的触发方式，取决于 OpenClaw Agent 的配置：

### 5.1 定时任务 (Cron)

通过 OpenClaw 的 cron 系统配置：

```json
{
  "name": "daily-work-report",
  "schedule": { "kind": "cron", "expr": "0 9 * * *", "tz": "Asia/Shanghai" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "发送今日工作日报给 admin"
  },
  "delivery": { "mode": "announce" }
}
```

Agent 收到 cron 触发后，调用 `POST /api/bot/send-to-user` 发送消息。

### 5.2 心跳检查 (Heartbeat)

Agent 的 `HEARTBEAT.md` 定义周期性检查任务：
- 服务健康检查
- 项目进度检查
- 任务超期检测

检查发现问题时调用 `send-to-user` 主动通知用户。

### 5.3 事件驱动 (Event)

Agent 监听文件系统/代码仓库/监控系统事件，触发后主动通知：
- 文件创建 → 通知审阅
- 代码提交 → 通知测试
- 系统告警 → 通知运维

---

## 六、数据流向

```
┌──────────────────────────────────────────────────────────────┐
│  OpenClaw Agent (AI 员工)                                     │
│  触发: cron / heartbeat / event                               │
│  调用: POST /api/bot/send-to-user {botId, userId, content}   │
└───────────────────────┬──────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│  botController.sendToUser()                                   │
│  ① extractPlainText → ② saveMessage(is_pushed=0)             │
│  ③ appendToChatHistory                                        │
│  ④ wsManager.isUserOnline(userId)?                            │
│     ├── YES → sendToUser → markMessageAsPushed                │
│     └── NO  → offlineQueue.enqueue                            │
└───────────────────────┬──────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│  数据存储                                                     │
│  ~/octowork/data/chat.db → messages 表 (is_pushed=0/1)       │
│  ~/octowork/data/offline_queue/ → 离线队列 JSON               │
│  ~/octowork/departments/{botId}/ → .md 聊天记录               │
└───────────────────────┬──────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│  投递到前端                                                    │
│  L1: WS bot_message 实时推送                                  │
│  L2: 对账服务 30s 补推                                         │
│  L3: 前端 30s/60s 轮询                                        │
│  L4: 离线队列上线投递                                          │
└───────────────────────┬──────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│  前端展示                                                      │
│  handleBotNewMessage → 插入消息列表 / 更新未读计数             │
│  主动消息 → ElNotification 弹窗通知                            │
└──────────────────────────────────────────────────────────────┘
```

---

## 七、关键源文件

| 文件 | 职责 | 关键行号 |
|------|------|---------|
| `backend/src/controllers/botController.js` | sendToUser 控制器 | L1427-1574 |
| `backend/src/routes/botRoutes.js` | 路由注册 `POST /bot/send-to-user` | L60 |
| `backend/db/database.js` | saveMessage + markMessageAsPushed | L209, L569 |
| `backend/src/services/offlineQueue.js` | 离线队列持久化 | — |
| `backend/websocket/user-manager.js` | WS 单例管理器 sendToUser | — |
| `backend/services/message-reconciliation-enhanced.js` | 对账服务 30s 补推 | — |
| `frontend/.../composables/useWebSocket.ts` | handleBotNewMessage + 弹窗 | L364-410 |
| `frontend/.../composables/useSingleChat.ts` | 轮询兜底 | L648-710 |

---

## 八、消息类型模板

| 类型 | type 字段 | 内容模板 | 触发条件 |
|------|----------|---------|---------|
| 进度汇报 | `proactive` | `项目『{名称}』已完成{进度}%，{里程碑}` | 项目进度变化 |
| 异常告警 | `proactive` | `{系统名}出现{异常类型}，{影响范围}` | 监控告警 |
| 任务提醒 | `task_reminder` | `任务『{名称}』将在{时间}到期` | 定时检查 |
| 心跳结果 | `heartbeat` | `服务健康检查完成，{N}项异常` | 心跳周期 |
| 每日汇报 | `proactive` | `今日工作总结：{摘要}` | Cron 触发 |

---

## 九、故障排查

```bash
# 测试 sendToUser API
curl -X POST http://localhost:1314/api/bot/send-to-user \
  -H "Content-Type: application/json" \
  -d '{"botId":"octotech-chief","userId":"admin","content":"测试主动消息"}'

# 查看 Bot 主动消息日志
grep "Bot主动消息" backend/logs/*.log

# 查看数据库中 Bot 主动消息
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, session_id, substr(content,1,50), is_pushed, datetime(timestamp/1000,'unixepoch','localtime')
   FROM messages WHERE sender='bot' AND bot_id='octotech-chief'
   ORDER BY timestamp DESC LIMIT 10;"

# 检查离线队列
ls -la ~/octowork/data/offline_queue/
```

| 症状 | 排查方向 |
|------|---------|
| API 返回 400 | 检查 botId/userId/content 是否为空 |
| delivery=realtime 但前端没收到 | 检查 WS 连接状态；对账服务 30s 后补推 |
| delivery=queued 但上线后没收到 | 检查 offlineQueue 路径是否正确 (`~/octowork/data/offline_queue/`) |
| 前端弹窗没出现 | 确认 `message.type` 是 `proactive`/`heartbeat`/`task_reminder` |
