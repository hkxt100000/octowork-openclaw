# 聊天模块 — 数据库 Schema

> 文件: `backend/db/database.js` (777行)  
> 引擎: SQLite3 (`sqlite3` npm 包)  
> 数据库路径: `~/octowork/data/chat.db` (由环境变量 `OCTOWORK_WORKSPACE` 或 `$HOME/octowork` 推导)  
> 最后更新: 2026-04-07

---

## 一、表结构总览

共 **5 张表**：messages, sessions, groups, group_members, group_messages

### 1.1 messages — 单聊消息表

```sql
CREATE TABLE messages (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id       TEXT NOT NULL,        -- 格式: "user_{userId}_bot_{botId}"
  sender           TEXT NOT NULL,        -- 'user' | 'bot'
  sender_name      TEXT,                 -- 发送者显示名
  content          TEXT NOT NULL,        -- 消息正文
  timestamp        INTEGER NOT NULL,     -- ms 时间戳
  is_bot           BOOLEAN DEFAULT 0,    -- 0=用户消息, 1=Bot消息
  bot_id           TEXT,                 -- botId (主查询字段)
  bot_name         TEXT,                 -- Bot显示名
  remote_reply_id  TEXT UNIQUE,          -- OpenClaw 回复 ID (去重)
  execution_logs   TEXT,                 -- ⚠️ 已废弃, saveMessage 强制设 NULL
  is_pushed        BOOLEAN DEFAULT 0,    -- WS 推送标记 (0=未推, 1=已推, 对账服务用)
  image_url        TEXT                  -- 图片上传 URL
);
```

**关键设计要点**:
- `session_id` 格式为 `user_{userId}_bot_{botId}`，写入时使用
- `bot_id` 为实际查询字段（`getMessages()` 从 `session_id` 中提取 `bot_id` 查询）
- `remote_reply_id` 设 UNIQUE 约束，用于防止 OpenClaw 重复回复
- `execution_logs` 已废弃 — `saveMessage()` 内部强制设为 `null`，无论传入何值
- `is_pushed` 配合对账服务使用：用户消息写入时设为 1，Bot消息设为 0，WS 推送成功后由 `markMessageAsPushed()` 更新为 1

### 1.2 sessions — 会话表

```sql
CREATE TABLE sessions (
  id             TEXT PRIMARY KEY,      -- 格式同 session_id: "user_{userId}_bot_{botId}"
  bot_id         TEXT NOT NULL,
  bot_name       TEXT NOT NULL,
  created_at     INTEGER NOT NULL,      -- ms 时间戳
  last_active    INTEGER NOT NULL,      -- ms 时间戳 (每次 saveMessage 自动更新)
  message_count  INTEGER DEFAULT 0      -- 累计消息数 (每次 saveMessage 自动+1)
);
```

**自动维护**: `saveMessage()` 内部执行 `INSERT OR REPLACE INTO sessions`，每次保存消息自动更新 `last_active` 和 `message_count`。

### 1.3 groups — 群组表

```sql
CREATE TABLE groups (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  name         TEXT NOT NULL,           -- 群组名称
  description  TEXT,                    -- 群组描述
  creator      TEXT NOT NULL,           -- 创建者 botId 或 'admin'
  created_at   INTEGER NOT NULL,        -- ms 时间戳
  avatar       TEXT,                    -- 群头像 URL
  source       TEXT DEFAULT 'user'      -- 来源: 'user'=手动创建, 'auto'=通讯录自动创建
);
```

**source 字段**: GroupSync 自动建群时写入 `'auto'`，用户手动创建写入 `'user'`，可通过 `getGroupsBySource(source)` 按来源筛选。

### 1.4 group_members — 群组成员表

```sql
CREATE TABLE group_members (
  group_id   INTEGER NOT NULL,          -- 关联 groups.id
  bot_id     TEXT NOT NULL,             -- Bot ID
  joined_at  INTEGER NOT NULL,          -- ms 时间戳
  role       TEXT DEFAULT 'member',     -- 'admin' | 'member'
  PRIMARY KEY (group_id, bot_id),
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

### 1.5 group_messages — 群组消息表

```sql
CREATE TABLE group_messages (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id     INTEGER NOT NULL,        -- 关联 groups.id
  sender       TEXT NOT NULL,           -- botId 或 'user' 或 'admin'
  sender_name  TEXT,                    -- 发送者显示名
  content      TEXT NOT NULL,           -- 消息正文
  timestamp    INTEGER NOT NULL,        -- ms 时间戳
  mentions     TEXT,                    -- JSON 数组字符串: ["botId1", "botId2"]
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

**mentions 存储**: 数组格式 JSON 字符串，`saveGroupMessage()` 自动序列化。

---

## 二、DB 函数速查

### 2.1 单聊消息函数

| 函数 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `saveMessage(sessionId, sender, senderName, content, isBot, botId, botName, remoteReplyId, executionLogs, imageUrl)` | 10个参数 | `Promise<lastID>` | 核心写入，自动维护 sessions 表，executionLogs 强制为 null，is_pushed 由 isBot 决定(Bot→0, 用户→1) |
| `getMessages(sessionId, limit=50, offset=0)` | sessionId + 分页 | `Promise<rows[]>` | **按 bot_id 查询**(从 sessionId 提取)，DESC 排序 |
| `getMessageByRemoteReplyId(remoteReplyId)` | remoteReplyId | `Promise<row\|null>` | 用于去重检测 |
| `getSessions()` | 无 | `Promise<rows[]>` | 含 message_count，按 last_active DESC |
| `clearMessages(sessionId)` | sessionId | `Promise<changes>` | 按 session_id 删除 |
| `clearMessagesByBotId(botId)` | botId | `Promise<changes>` | 按 bot_id 删除 (**推荐**) |

### 2.2 对账服务函数

| 函数 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `markMessageAsPushed(messageId)` | messageId | `Promise<boolean>` | 乐观锁(WHERE is_pushed=0)防止重复推送竞争，返回 true=成功标记, false=已被标记 |
| `findUnpushedBotMessages(windowMinutes=1440)` | 时间窗口(分钟) | `Promise<rows[]>` | 查找 is_bot=1 AND (is_pushed=0 OR NULL) 的消息 |
| `findMissingBotReplies(windowMinutes=5, replyTimeoutSeconds=30)` | 时间窗口+超时 | `Promise<rows[]>` | 查找用户消息在指定时间内无Bot回复的记录 |

### 2.3 群组管理函数

| 函数 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `createGroup(name, desc, creator, members=[], avatar, source='user')` | 6个参数 | `Promise<groupId>` | 创建群组 + 自动添加成员(创建者为admin) |
| `getGroups()` | 无 | `Promise<rows[]>` | 含 member_count, message_count，按 created_at DESC |
| `getGroup(groupId)` | groupId | `Promise<row\|null>` | 单个群组详情含 member_count |
| `getGroupByName(name)` | name | `Promise<row\|null>` | 按名称查找(GroupSync用) |
| `getGroupsBySource(source)` | 'auto'\|'user' | `Promise<rows[]>` | 按来源筛选群组 |
| `updateGroupDescription(groupId, description)` | groupId, description | `Promise<changes>` | 更新群描述 |
| `deleteGroup(groupId)` | groupId | `Promise<void>` | 级联删除: 成员→消息→群组 |

### 2.4 群组成员函数

| 函数 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `addGroupMember(groupId, botId, role='member')` | 3个参数 | `Promise<changes>` | INSERT OR REPLACE (幂等) |
| `removeGroupMember(groupId, botId)` | 2个参数 | `Promise<changes>` | 删除成员 |
| `getGroupMembers(groupId)` | groupId | `Promise<rows[]>` | 按 joined_at ASC |

### 2.5 群组消息函数

| 函数 | 参数 | 返回 | 说明 |
|------|------|------|------|
| `saveGroupMessage(groupId, sender, senderName, content, mentions)` | 5个参数 | `Promise<{id, group_id, sender, sender_name, content, timestamp, mentions}>` | 返回完整消息对象(非仅 lastID) |
| `getGroupMessages(groupId, limit=100)` | groupId + limit | `Promise<rows[]>` | ASC 排序（最旧在前） |
| `getLatestGroupMessage(groupId)` | groupId | `Promise<row\|null>` | 最新一条(列表展示用) |
| `clearGroupMessages(groupId)` | groupId | `Promise<changes>` | 清空群消息(保留群组) |

---

## 三、数据库路径推导规则

```
优先级:
  1. 环境变量 OCTOWORK_WORKSPACE → 使用该值 + /data/chat.db
  2. 未设置 → $HOME/octowork/data/chat.db (Unix) 或 %USERPROFILE%/octowork/data/chat.db (Windows)

目录不存在时自动创建 (fs.mkdirSync recursive)
```

---

## 四、已知设计注意事项

1. **session_id 与 bot_id 双轨查询**: `saveMessage` 用 `session_id` 写入，但 `getMessages` 实际按 `bot_id` 查询（从 sessionId 中提取 `_bot_` 后的部分）。历史遗留设计，功能正常。

2. **saveMessage 返回 lastID vs saveGroupMessage 返回完整对象**: 单聊仅返回数字 ID，控制器自行构造 message 对象；群聊已优化为返回完整 `{id, group_id, sender, sender_name, content, timestamp, mentions}` 对象。

3. **execution_logs 已废弃**: `saveMessage()` 内部强制 `logsJson = null`，但函数签名保留 10 个参数位（向后兼容）。触发器代码已注释（SQLite 语法兼容问题），改用应用层控制。

4. **clearMessages vs clearMessagesByBotId**: 两套删除逻辑并存。`clearMessages(sessionId)` 按 session_id 删除，`clearMessagesByBotId(botId)` 按 bot_id 删除。控制器优先使用后者，因为一个 Bot 可能对应多个 session_id。

5. **is_pushed 对账机制**: ✅ 已完善 — `EnhancedMessageReconciliation` 服务每 30s 扫描 `is_pushed=0` 的 Bot 消息并补推。`markMessageAsPushed()` 使用乐观锁 `WHERE is_pushed = 0` 防止竞争条件。详见 `docs/10-核心工作流功能/bot聊天管理器消息对账功能.md`。

6. **群组级联删除**: `deleteGroup()` 手动按顺序删除(成员→消息→群组)，而非依赖 SQLite FOREIGN KEY CASCADE（需要 PRAGMA foreign_keys=ON 才生效）。

7. **getGroupMessages 排序**: 群消息 ASC 排序(旧→新)，前端直接渲染；单聊消息 DESC 排序(新→旧)，前端需要 reverse。
