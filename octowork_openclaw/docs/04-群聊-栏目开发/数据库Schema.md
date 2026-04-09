# 群聊模块 — 数据库 Schema

> 文件: `backend/db/database.js`  
> 建表: 第 131-182 行 | CRUD: 第 377-606 行 | 扩展查询: 第 732-775 行  
> 最后更新: 2026-04-07（基于实际代码全面校验）

---

## 一、表结构

### 1.1 groups (群组表)

```sql
CREATE TABLE IF NOT EXISTS groups (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  description TEXT,
  creator     TEXT NOT NULL,              -- 创建者 ID (botId 或 'admin')
  created_at  INTEGER NOT NULL,           -- ms timestamp
  avatar      TEXT,                       -- 群头像路径 (可选)
  source      TEXT DEFAULT 'user'         -- 'auto' = 通讯录自动创建, 'user' = 用户手动创建
);
```

**注意**: `source` 字段通过 `ALTER TABLE` 幂等添加（忽略 duplicate column 错误），区分自动创建的群（由 `group-sync.js` 管理）与用户手动创建的群。

### 1.2 group_members (群组成员表)

```sql
CREATE TABLE IF NOT EXISTS group_members (
  group_id  INTEGER NOT NULL,
  bot_id    TEXT NOT NULL,                -- botId 或 'admin'/'user'
  joined_at INTEGER NOT NULL,            -- ms timestamp
  role      TEXT DEFAULT 'member',       -- 'admin' | 'member'
  PRIMARY KEY (group_id, bot_id),
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

### 1.3 group_messages (群组消息表)

```sql
CREATE TABLE IF NOT EXISTS group_messages (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id    INTEGER NOT NULL,
  sender      TEXT NOT NULL,              -- 'user' | 'admin' | botId
  sender_name TEXT,                       -- 中文昵称 (来自 ai-directory.json)
  content     TEXT NOT NULL,
  timestamp   INTEGER NOT NULL,           -- ms timestamp
  mentions    TEXT,                       -- JSON string 或 null, e.g. '["bot-1","all"]'
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);
```

---

## 二、DB 函数速查

### 2.1 群组管理

| 函数 | 行号 | 签名 | 返回 | 说明 |
|------|------|------|------|------|
| `createGroup` | 378 | `(name, description, creator, members[], avatar?, source?)` | `groupId: number` | db.serialize: INSERT group → 自动添加 creator 为 admin → 添加所有成员（去重） |
| `getGroups` | 427 | `()` | `rows[]` | 含子查询 `member_count` + `message_count`, ORDER BY created_at DESC |
| `getGroup` | 444 | `(groupId)` | `row \| undefined` | 含子查询 `member_count`, 单条查不到返回 undefined |
| `getGroupByName` | 732 | `(name)` | `row \| null` | 精确匹配群名, 用于重名检测 |
| `getGroupsBySource` | 746 | `(source)` | `rows[]` | 按来源筛选 ('auto'/'user'), 含 member_count |
| `updateGroupDescription` | 764 | `(groupId, description)` | `changes: number` | UPDATE SET description |
| `deleteGroup` | 580 | `(groupId)` | `void` | db.serialize: DELETE members → DELETE messages → DELETE group (非原子事务) |

### 2.2 成员管理

| 函数 | 行号 | 签名 | 返回 | 说明 |
|------|------|------|------|------|
| `addGroupMember` | 461 | `(groupId, botId, role?)` | `changes: number` | INSERT OR REPLACE, role 默认 'member' |
| `removeGroupMember` | 477 | `(groupId, botId)` | `changes: number` | DELETE 单条 |
| `getGroupMembers` | 491 | `(groupId)` | `rows[]` | ORDER BY joined_at ASC |

### 2.3 消息管理

| 函数 | 行号 | 签名 | 返回 | 说明 |
|------|------|------|------|------|
| `saveGroupMessage` | 505 | `(groupId, sender, senderName, content, mentions?)` | `{id, group_id, sender, sender_name, senderName, content, timestamp, mentions}` | ✅ 返回完整消息对象, mentions 自动 JSON.stringify 序列化 |
| `getGroupMessages` | 536 | `(groupId, limit=100)` | `rows[]` | ORDER BY timestamp ASC, LIMIT |
| `getLatestGroupMessage` | 553 | `(groupId)` | `row \| null` | ORDER BY timestamp DESC LIMIT 1, 用于群组列表展示 |
| `clearGroupMessages` | 570 | `(groupId)` | `changes: number` | DELETE 该群所有消息, 不删群本身 |

---

## 三、数据流图

```
前端 POST /api/groups/:id/messages
  ↓
groupController.sendGroupMessage()
  ↓
saveGroupMessage(groupId, sender, senderName, content, mentions)
  ├── mentions: string[] → JSON.stringify → TEXT 字段
  └── timestamp = Date.now() (ms)
  ↓
返回: { id, group_id, sender, sender_name, senderName, content, timestamp, mentions }
  ↓
wsManager.broadcast({ type: 'group_message', groupId, message })
  ↓
前端 handleGroupNewMessage(data) → push 到 groupMessages
```

---

## 四、group-sync.js 对账模块

> 文件: `backend/group-sync.js` (339行)

### 同步规则

1. **部门总群**: 每个部门 → 群名 = `{chinese_name}总群`, 成员 = 该部门所有 active 员工
2. **管理总群**: 成员 = 各部门的 is_leader=true 员工
3. **source 隔离**: 自动创建的群 `source='auto'`, 用户手动创建的群 `source='user'`
4. **对账**: 只操作 `source='auto'` 的群, 用户群完全不受影响
5. **幂等**: 多次执行结果相同

### 涉及的 DB 函数

```
loadAiDirectory()       → 读取 octowork/config/ai-directory.json
getGroupsBySource('auto') → 查当前自动群
getGroupByName(name)    → 重名检测
createGroup(name, desc, creator, members, null, 'auto')
deleteGroup(groupId)    → 删除多余的自动群
addGroupMember()        → 添加新成员
removeGroupMember()     → 移除旧成员
updateGroupDescription()→ 更新群描述
```

---

## 五、设计要点

1. **saveGroupMessage 返回完整对象**: `{id, group_id, sender, sender_name, senderName, content, timestamp, mentions}` — groupController 的 sendGroupMessage / botSendToGroup 都依赖 `.id` / `.timestamp` / `.content`

2. **mentions 存储为 JSON 字符串**: 写入时 `Array.isArray(mentions) ? JSON.stringify(mentions) : mentions`, 读取时需要在应用层 `JSON.parse`

3. **deleteGroup 非事务**: 使用 `db.serialize()` 顺序执行三个 DELETE (members→messages→group), 非原子操作, 中间失败可能留下孤立数据

4. **source 字段双重保障**: 建表 `DEFAULT 'user'` + ALTER TABLE 幂等添加, 确保旧数据库升级兼容

5. **getGroups 含统计**: 一次查询通过子查询同时返回 `member_count` 和 `message_count`, 避免 N+1

6. **createGroup 自动添加创建者**: `allMembers = [...members, creator]`, 去重后创建者 role='admin', 其余 role='member'

7. **ON DELETE CASCADE**: group_members 和 group_messages 都设置了级联删除, 但 deleteGroup 仍手动删除以确保兼容性

8. **getLatestGroupMessage**: 单独函数, 被 groupController.getAllGroups 调用为每个群附加 `last_message`, 用于侧边栏群组列表预览
