# OctoWork 记忆系统 — 核心问题深度分析

> 创建时间：2026-04-05
> 状态：深度分析完成，等待与老板讨论方案
> 前置文档：`octowork/docs/octowork-永不失忆/` 全5份 + `智能防卡顿引擎 v1.0`
> 作者：AI开发助手（通读全部方案文档 + 源码审计后撰写）

---

## 零、一句话概括

**OctoWork 的 AI 员工活在一个"只有短期记忆的世界"里——每次说话都像刚睡醒，不知道昨天干了什么，也不知道五分钟前同事说了什么。**

问题不是没有方案（四层蒸馏塔写得很完整），而是**第二层到第四层全部还在纸上**，已上线的代码只有第一层（token 三级内存配置文件）和一个"盲切 + 废话摘要"的会话清理器。真正和 OpenClaw 交互的代码路径里，**没有任何记忆注入机制**。

---

## 一、我读到的全部知识点（5份文档 + 1份防卡顿）

| 文档 | 核心内容 | 状态 |
|------|----------|------|
| 四大记忆蒸馏塔大纲 | 四层架构：实时记忆 → 每日聊天记录 → 记忆大师提炼 → 章鱼学院知识库 | 已定稿 |
| 第一层-实时记忆三层方案 | L0(200t) / L1(500t) / L2(2500t) + 部署脚本 + 自动化调度 | ✅ 已部署 |
| 第二层-每日实时聊天记录 | 按日期存 .md 文件到 agent 公寓 chat_history/ | ✅ 已实现（代码中有 appendToChatHistory） |
| 第三层-记忆大师提炼 | 开机触发，提取昨日精华，@成员推送 | ⏳ 占位符 |
| 第四层-章鱼学院知识库 | 本地频道 + 全文/语义搜索 | ⏳ 占位符 |
| 智能防卡顿引擎 v1.0 | Token 阈值监控 → 存档 → 清空 → 写回 5 条 + 摘要 | 有代码，未集成到主流程 |

---

## 二、源码审计：真实的记忆流是什么样的

### 2.1 单聊（用户 ↔ Bot）

```
用户消息 → botController.sendMessage()
  ├── saveMessage(sessionId, 'user', ...) → SQLite messages 表
  ├── appendToChatHistory(botId, ...) → .md 文件 ✅ 第二层已生效
  └── openclawClient.sendMessage(botId, content, model, userId, sessionId, style)
        │
        └── openclaw CLI --agent {botId} --message "{content}" --session-id {sessionId} --json
              │
              └── OpenClaw 服务端根据 session_id 拼接完整历史 → 打包发给模型 API
```

**关键发现：**
- `sessionId` 格式为 `user_{userId}_bot_{botId}`，始终一致，OpenClaw 用它维护对话历史
- **我们不发任何记忆上下文**，完全依赖 OpenClaw 内部的 session 历史
- OpenClaw 的 session 历史无限增长 → 超过 ~100k tokens 就触发压缩 → 卡顿 5-10 分钟
- 智能防卡顿引擎做的事：到阈值 → 归档 → 清空 → 写回 5 条 + 一句"历史已归档"
- **写回的 5 条是盲选（最后 5 条），摘要是废话 → AI 直接失忆**

### 2.2 群聊（用户 @Bot → Bot 回复）

```
用户发消息（含 @mentions）
  → groupController.sendGroupMessage()
     ├── saveGroupMessage() → SQLite group_messages 表
     ├── wsManager.broadcast() → 实时推送给前端
     └── _triggerMentionedBots(groupId, senderId, mentions, content, style, depth=0)
           │
           ├── 如果 mentions 包含 'all' → 查群成员 → 展开为所有 bot ID
           │
           └── 对每个 botId：
                 ├── 频率限制检查（5秒冷却）
                 ├── 构建个性化上下文（最近 20 条中取 10 条，按相关性过滤）
                 └── openclawClient.sendMessage(botId, contextMessage, null, 'group', groupSessionId, style)
```

**关键发现：**
- 群聊用的 `groupSessionId` = `group_{groupId}`，全群共享一个 session
- 但群聊的 `contextMessage` 是我们手动拼的最近消息，不是 OpenClaw session 里的历史
- **矛盾**：我们传了 `--session-id group_X`，OpenClaw 会在它的 session 里叠加这些手动上下文 → 重复 + 混乱
- 最近 10 条中"最近 5 条总是包含"的逻辑看起来合理，但如果群里 10 分钟没人说话然后突然 @bot，这 5 条可能是昨天的无关话题
- **没有任何任务状态、角色定位、长期记忆注入**

### 2.3 OpenClaw Session Manager（`openclawSessionManager.js`）

**实际功能：** 只是一个内存 Map，记录 sessionId → 元数据（创建时间、最后活跃时间）

**关键发现：**
- **不控制 OpenClaw 的任何行为**
- 不做 token 计数
- 不做压缩触发
- 不做记忆注入
- `resetSession()` 只删除 Map 条目，不清空 OpenClaw 服务端 session
- 注释明确写了：*"session_id 通过 --session-id 参数传入 openclaw CLI，OpenClaw 自己在服务端维护对话上下文"*

### 2.4 OpenClaw CLI 客户端（`openclaw.js`）

**实际功能：** 纯粹的 CLI 包装器，`spawn('openclaw', args)` → 等输出 → 解析 JSON

**关键发现：**
- 只传 `--message`, `--agent`, `--session-id`, `--timeout`, `--json`
- **没有 `--context`、`--memory`、`--system-prompt` 等参数**
- 不注入任何额外上下文
- 不查询本地记忆文件
- 不读 agent 公寓的 memory/ 或 chat_history/

---

## 三、核心问题清单（按严重程度排序）

### 🔴 P0：单聊 "清空后失忆" — 最致命

| 维度 | 现状 |
|------|------|
| **触发场景** | token 累积超 60k → 防卡顿引擎触发 → 清空 + 写回 5 条 |
| **失忆表现** | AI 回复"您好，请问有什么可以帮您？" |
| **根因** | 写回的 5 条盲选 + 摘要无内容 |
| **影响面** | 所有单聊 Bot，每天可能触发多次 |
| **方案文档有吗** | 有（防卡顿 v1.0 + 蒸馏塔第三层），但第三层只是占位符 |

### 🔴 P0：群聊 "每次@都像刚进群" — 第二致命

| 维度 | 现状 |
|------|------|
| **触发场景** | 用户 @bot 或 @all |
| **失忆表现** | Bot 回复完全不考虑之前的讨论、不知道自己负责什么 |
| **根因** | 只给最近 10 条（其中 5 条盲选），无任务上下文/角色定位 |
| **影响面** | 所有群聊 Bot |
| **方案文档有吗** | 无专门方案 |

### 🟡 P1：群聊 session 与手动上下文重复

| 维度 | 现状 |
|------|------|
| **问题** | `_triggerMentionedBots` 手动拼上下文发给 OpenClaw，同时传了 `--session-id group_X` |
| **后果** | OpenClaw session 里已有群聊历史，又叠加了我们手动拼的上下文 → 信息重复 → token 浪费 |
| **修复方向** | 要么不传 session-id（每次新会话），要么不手动拼上下文 |

### 🟡 P1：记忆层已部署但未接入对话流

| 维度 | 现状 |
|------|------|
| **已有** | `memory/` 目录（L0/L1/L2 文件）、`chat_history/` 日志、`memory_config.json` |
| **问题** | `sendMessage` 和 `_triggerMentionedBots` 完全不读这些文件 |
| **后果** | 记忆系统是"摆设"——文件在那里，但 AI 看不到 |

### 🟢 P2：蒸馏塔第三层（记忆大师提炼）/ 第四层（章鱼学院）未实现

这两层是方案文档里规划好的，目前只有占位符 `*具体实现方案开发中...*`。

---

## 四、流转全图 — 记忆从哪来、到哪去、在哪断了

```
                         ┌────────────────────────┐
                         │  用户发消息（单聊/群聊）  │
                         └──────────┬─────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
            ┌──────────────┐                ┌──────────────┐
            │  单聊流程     │                │  群聊流程     │
            └──────┬───────┘                └──────┬───────┘
                   │                               │
          ┌────────┴────────┐             ┌────────┴────────┐
          ▼                 ▼             ▼                 ▼
    ┌──────────┐   ┌──────────────┐  ┌──────────┐   ┌──────────────┐
    │ SQLite   │   │ chat_history │  │ SQLite   │   │ 手动拼上下文  │
    │ messages │   │ .md 文件     │  │ group_   │   │ (最近10条)   │
    │          │   │ ✅ 写入生效   │  │ messages │   │ ✅ 已优化     │
    └────┬─────┘   └──────────────┘  └────┬─────┘   └──────┬───────┘
         │                                │                 │
         │  ❌ 没人读这些记忆               │                 │
         ▼                                ▼                 ▼
    ┌──────────────────────────────────────────────────────────────┐
    │  OpenClaw CLI                                                │
    │  --message "{内容}"                                          │
    │  --session-id "{sessionId}"                                  │
    │  --agent "{botId}"                                           │
    │                                                              │
    │  ❌ 不注入 memory/ 目录内容                                    │
    │  ❌ 不注入 chat_history/ 摘要                                  │
    │  ❌ 不注入角色定位/任务状态                                      │
    │  ❌ 不注入长期记忆                                             │
    └──────────────────────────────────────────────────────────────┘
         │
         ▼
    ┌──────────────────────────────┐
    │  OpenClaw 服务端              │
    │  用 session_id 拼完整历史     │
    │  → 无限增长 → 压缩 → 卡顿    │
    │  ← 我们无法控制 →             │
    └──────────────────────────────┘
```

**断点总结：**
1. `memory/` 文件有写入，没有读取
2. `chat_history/` 有写入（第二层已实现），没有读取
3. OpenClaw session 是黑箱，我们只能传 session-id，不能注入/读取/修改其内容
4. 清空 session 后写回的内容太粗糙
5. 群聊上下文缺乏长期记忆支撑

---

## 五、我的核心思想：记忆不是"存"的问题，是"用"的问题

### 5.1 存储已经做得不错

- 第一层记忆配置文件已部署（L0/L1/L2 token 预算）
- 第二层 chat_history 每日 .md 已在写入
- SQLite messages / group_messages 表完整保存
- Agent 公寓目录结构规范

**存了但没用 = 白存。**

### 5.2 真正缺的是"记忆注入管道"

目前从 OctoWork 到 OpenClaw 的调用链上，**没有任何环节读取本地记忆并拼接到 message 中**。

这就像一个人每天写日记但从来不翻看 —— 记忆存在文件系统里，但不在 AI 的"工作记忆"里。

### 5.3 OpenClaw 是黑箱，我们必须在"入口"做手术

```
我们能控制的唯一入口：
  openclawClient.sendMessage(botId, MESSAGE, model, userId, sessionId, style)
                                    ^^^^^^^^
                          这个 MESSAGE 是我们唯一能塞东西的地方
```

OpenClaw CLI 没有 `--context` 或 `--system-prompt` 参数。所以我们只能把"记忆注入"拼接到 `message` 参数里。这意味着：

- **单聊清空后**：新的第一条 message 必须包含智能摘要（任务状态、关键决策、待办项）
- **群聊 @bot**：contextMessage 必须包含该 Bot 的角色定位 + 近期任务状态 + 相关群聊摘要
- **每日开机**：第一条消息应该包含昨日记忆精华（第三层做的事，但要在第一条消息里注入）

### 5.4 "充电"概念的技术翻译

基于对所有文档的理解，我认为老板的"充电"概念可以这样翻译：

```
旧思路（断电重启）：
  Token 满了 → 清空 → 写回5条 → AI失忆 → 等用户重新解释

新思路（充电）：
  Token 接近阈值 → 暂停当前对话
  → 让 AI 自己（或记忆大师Bot）生成结构化摘要
  → 清空 session
  → 将摘要作为"充满电的记忆"注入新 session 的第一条
  → AI 继续工作，完全不失忆，用户无感知
  
  类比：
  ✖ 手机没电了 → 关机 → 开机 → 所有应用重新打开（现在）
  ✔ 手机电量低 → 快速换电池 → 所有应用仍在运行（充电方案）
```

---

## 六、要和老板讨论的关键问题

1. **"充电"摘要谁来生成？**
   - 选项A：被清理的 Bot 自己总结（省一次 API 调用，但 Bot 可能不够客观）
   - 选项B：记忆大师 Bot 总结（独立视角，但多一次 API 调用 + 等待时间）
   - 选项C：用轻量模型（如 GPT-4o-mini）快速摘要（成本低、速度快）

2. **摘要的结构是什么？**
   - 纯文本段落？
   - 结构化 JSON（当前任务、进度、待办、关键决策）？
   - 混合格式（system prompt 用结构化，user message 用自然语言）？

3. **群聊的记忆单位是什么？**
   - 按群？（所有 Bot 共享一份群记忆）
   - 按 Bot？（每个 Bot 有自己对群的理解）
   - 按话题/任务？（更精准但实现复杂）

4. **充电时机？**
   - Token 接近阈值时实时触发？（会有短暂延迟）
   - 定时后台跑？（可能错过峰值）
   - 两者结合？（阈值触发 + 定时补充）

5. **chat_history 和 memory 怎么在对话中被"读回来"？**
   - 每次对话前都读一次 memory 文件拼到 message 里？
   - 只在清空后的第一条消息里注入？
   - 用 RAG（检索增强生成）从 chat_history 中找相关片段？

6. **第三层和第四层的优先级？**
   - 先做"记忆大师每日提炼"更紧急？（解决"隔天失忆"问题）
   - 还是先做"章鱼学院知识库"？（解决跨 Bot 知识共享）

---

## 七、附录：关键代码位置索引

| 功能 | 文件 | 关键行 |
|------|------|--------|
| 单聊发消息 | `backend/src/controllers/botController.js` | `sendMessage()` L181 |
| 群聊 @Bot 触发 | `backend/src/controllers/groupController.js` | `_triggerMentionedBots()` L61 |
| 群聊上下文构建 | `backend/src/controllers/groupController.js` | L145-218 |
| OpenClaw CLI 调用 | `backend/api/openclaw.js` | `sendMessage()` L20 |
| Session ID 生成 | `backend/src/services/openclawSessionManager.js` | `getUserBotSession()` / `getGroupSession()` |
| 聊天记录写入 | `backend/src/controllers/botController.js` | `appendToChatHistory()` L260 |
| 记忆配置文件 | `octowork/departments/*/agents/*/config/memory_config.json` | L0/L1/L2 token 预算 |
| Agent 公寓记忆 | `octowork/departments/*/agents/*/memory/*.md` | 每日工作日志 |
| 防卡顿方案 | `octowork/docs/OctoWork功能模块/双会话窗口 智能防卡顿/` | 完整 Python 实现 |
| 智能清理器 | `backend/tools/openclaw_intelligent_cleaner.py` | 四重检测引擎 |

---

## 八、我的判断：下一步应该做什么

**最高优先级（能立即提升体验的）：**

1. **在 `openclawClient.sendMessage` 入口增加"记忆注入层"** — 读取 agent 的 `memory/` 最新文件 + `chat_history/` 今日摘要，拼接到 message 开头。这一步改动最小（只改 openclaw.js 或 botController），效果最明显。

2. **改造防卡顿清理的"写回摘要"** — 清空前让 AI 自己用一条消息总结当前任务状态，而不是写一句废话。这一步需要在清理流程中额外调用一次 OpenClaw。

3. **群聊上下文增加"角色定位注入"** — 在 `_triggerMentionedBots` 构建 `contextMessage` 时，读取该 Bot 的 `memory/` 最新条目，拼接角色/职责/近期任务。

**等讨论后再定的：**

4. 第三层"记忆大师"的触发机制和摘要格式
5. 第四层"章鱼学院"的搜索和存储架构
6. 完整的"充电"流程设计

---

*老板，以上是我通读所有文档 + 审计全部相关源码后的核心思想。随时可以讨论"充电"概念的具体方案。*
