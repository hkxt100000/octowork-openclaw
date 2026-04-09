# AI 工作记忆 — octowork_openclaw

> 最后更新：2026-04-09（全文档通读完成）

---

## 核心目标

**将 openclaw 的功能直接融合进 octowork-chat，最终只保留一个产品：octowork-chat。**

openclaw 不作为独立产品存在，它的能力成为 octowork-chat 的一部分。

---

## 阅读进度

- [x] 01-项目概要（9个文件）✅
- [x] 02-首页-栏目开发（登录/Dashboard/MainLayout）✅
- [x] 03-聊天-栏目开发 ✅
- [x] 04-群聊-栏目开发 ✅
- [x] 05-任务看板-栏目开发（API速查 + 前端组件树 + DB Schema）✅
- [x] 06-09 企微/AI员工/章鱼学院/技能市场（全部为空占位符）✅
- [x] 10-核心工作流功能（记忆系统 + 7种自检模式 + 群聊任务 + 主动找用户）✅
- [x] 11-数字公寓配置管理（配置项模块）✅
- [x] 14-设计规范标准（Apple+GenSpark 设计规范）✅
- [x] 15-用户版升级手册（打包/发布/升级流程）✅
- [x] openclaw-node-sdk 源码（client.ts / types.ts / identity.ts / examples）✅
- [x] docs/AI工作记忆.md（了解项目历史状态）✅

---

## 长期记忆 · 第一章：octowork-chat 系统全景

### 产品定位
- **名称**：OctoWork 聊天管理器（开发代号 `octowork-chat-dev`）
- **本质**：OpenClaw 用户的可视化管理驾驶舱，管理自己的 AI 员工团队
- **服务对象**：OpenClaw 用户 → 通过 octowork-chat 管理"数字公寓"
- **两个版本**：`~/octowork-chat-dev/`（开发版）和 `~/octowork-chat/`（用户版）

### 技术栈
| 端 | 技术 | 端口 |
|----|------|------|
| 前端 | Vue 3 + TypeScript + Vite | 5888 |
| 后端 | Node.js + Express + SQLite | 1314 |
| 实时通信 | WebSocket（与 HTTP 共享端口） | 1314 |
| 数据库 | SQLite，路径固定为 `~/octowork/data/chat.db` | — |

### 三层架构（用户电脑根目录）
```
~/
├── .openclaw/          ← 执行层（OpenClaw AI 引擎 + config）
├── octowork/           ← 数字公寓（所有数据+工作区，多版本共享）
│   ├── data/chat.db        ⭐ 聊天数据库
│   ├── config/ai-directory.json  通讯录（62员工，10部门）
│   └── departments/        10 个部门，每个含 agents/ 和 team_config.json
└── octowork-chat-dev/  ← 聊天管理器开发版（本项目）
```

---

## 长期记忆 · 第二章：前端代码地图

### 路由与布局
- `router.ts`：2条路由 `/login` → `Login.vue`（1078行）；`/` → `App.vue`（768行）
- `App.vue`（768行）：四列布局主控，`onMounted` 执行 15 步初始化
- **四列**：MainLayout（导航80px）→ ContentSidebar（200px）→ 主内容区（动态）→ WorkspacePanel/GroupWorkspacePanel

### 主要视图组件（行数基于 2026-04-07 快照）
| 组件 | 行数 | 职责 |
|------|------|------|
| `Login.vue` | 1078 | 视频背景轮播 + 旋转字幕 + 登录弹窗 |
| `DashboardView.vue` | 1216 | 系统状态 + BotCardGrid + LiveLogStream + Stats |
| `ChatArea.vue` | 537 | 单聊区（Header + Messages + Input）|
| `ChatHeader.vue` | 1448 | 聊天头部（最大，含模式选择/文件树/任务） |
| `MessagesView.vue` | 658 | 消息列表 |
| `MessageInput.vue` | 831 | 消息输入框 |
| `GroupChatView.vue` | 193 | 群聊视图 |
| `GroupMessagesView.vue` | 617 | 群聊消息列表 |
| `GroupMessageInput.vue` | 980 | 群聊输入（支持@mention） |
| `TaskBoardContainer.vue` | 66 | 任务看板路由壳 |
| `BoardPage.vue` | 684 | 部门总览 |
| `ProjectListView.vue` | 735 | 项目列表 |
| `PipelineView.vue` | 1209 | 流水线详情（核心页面） |
| `MainLayout.vue` | 341 | 全局导航条（9个导航项） |
| `ContentSidebar.vue` | 1570 | Bot/群组列表侧边栏 |

### 可组合函数（composables）
| 文件 | 行数 | 职责 |
|------|------|------|
| `useSingleChat.ts` | 802 | 单聊消息缓存/加载/发送/轮询 |
| `useGroupChat.ts` | 920 | 群聊消息/@mention/未读计数 |
| `useWebSocket.ts` | 637 | WS统一管理+重连 |
| `useBots.ts` | 300 | Bot列表 |
| `useMessages.ts` | 505 | 消息状态 |
| `useTasks.ts` | 395 | 任务状态 |
| `usePipeline.ts` | 383 | 任务看板 API + WS |

### CSS 体系
25个模块化 CSS 文件（global.css / layout.css / chat.css / darkmode.css 等），全部使用 CSS 变量，不硬编码颜色值，支持深色模式。

---

## 长期记忆 · 第三章：后端代码地图

### 关键文件清单
| 文件 | 行数 | 职责 |
|------|------|------|
| `backend/server.js` | ~3000 | 主入口，所有路由注册 |
| `backend/db/database.js` | 777 | SQLite helper（5张表） |
| `backend/src/controllers/botController.js` | 大 | 单聊核心控制器 |
| `backend/src/controllers/groupController.js` | 大 | 群聊核心控制器 |
| `backend/src/controllers/boardController.js` | 1068 | 任务看板控制器 |
| `backend/src/controllers/taskController.js` | 607 | 群聊任务控制器 |
| `backend/src/controllers/authController.js` | 387 | 登录/用户管理 |
| `backend/api/openclaw.js` | 中 | ⭐ OpenClaw 网关桥接（CLI包装器） |
| `backend/services/personalTaskPipeline.js` | 836 | 个人任务流水线服务 |
| `backend/tasks/task_box_watcher.js` | 551 | 文件变化监控→WS广播 |
| `backend/tasks/task_detector.js` | 381 | 群聊任务意图识别 |
| `backend/services/message-reconciliation-enhanced.js` | 中 | 消息保底对账 |
| `backend/services/messageSummaryService.js` | 中 | 消息摘要服务 |

### 路由总览
```
/api/auth/*              认证相关（login/me/update/change-password）
/api/messages/:botId/*   单聊消息（发送/获取/删除/文件树/env）
/api/bot/send-to-user    Bot主动找用户（已实现）
/api/bot/send-to-group   Bot外部发群聊（已实现）
/api/groups/*            群聊管理（CRUD+消息+文件）
/api/board/*             任务看板（部门/项目/流水线/催促）
/api/tasks/*             群聊任务（确认/状态/进度/统计）
/api/task-pipeline/*     个人任务流水线（create/start/step/heartbeat）
/api/system/*            系统（license/version/更新检查）
/api/notifications/*     通知（列表/未读/标记已读）
```

### SQLite 数据库（5张表）
| 表名 | 关键字段 | 说明 |
|------|----------|------|
| `messages` | session_id, bot_id, sender, content, remote_reply_id, is_pushed | 单聊消息 |
| `sessions` | id(=session_id), bot_id, message_count | 会话记录 |
| `groups` | id, name, source('user'/'auto') | 群组 |
| `group_members` | group_id, bot_id, role | 群成员 |
| `group_messages` | group_id, sender, content, mentions(JSON) | 群聊消息 |

- **session_id 格式**：`user_{userId}_bot_{botId}`
- **群聊 sessionId**：`group_{groupId}`（全群共享一个 OpenClaw session）

---

## 长期记忆 · 第四章：任务看板（Pipeline系统）

### 核心设计：零数据库，全文件系统
- 旧看板：`departments/{dept}/task_box/{status}/*.md`（Markdown任务卡）
- 新看板（团队流水线）：`departments/{dept}/project-workspace/Project/{YYYYMMDD}/{projectId}/00_项目任务卡/pipeline_state.json`
- 个人任务：`departments/PersonalTasks/project-workspace/Task/{YYYYMMDD}/{taskId}/00_任务卡/task_state.json`

### 步骤状态机
```
blocked → ready → in_progress → completed → passed（QC通过）
                                         ↘ rejected → completed（重做循环）
任何状态 → failed（需人工介入）
```

### 关键 API
- `GET /api/board/departments` — 部门列表（含流水线摘要）
- `GET /api/board/:deptId/projects` — 项目列表
- `GET /api/board/:deptId/projects/:projectId/pipeline` — 流水线详情
- `POST /api/board/:deptId/projects/:projectId/nudge` — 催促Bot（5分钟冷却）
- `POST /api/task-pipeline/create` — 创建个人任务（3-10步）

### 前端组件
- `BoardPage.vue`（684行）— 部门总览卡片网格
- `ProjectListView.vue`（735行）— 项目列表（进行中/排队/完成/历史）
- `PipelineView.vue`（1209行）— 流水线详情（步骤节点图+事件日志+Guardian状态）
- `PipelineBar.vue`（92行）— 流水线横条（7种颜色）
- `usePipeline.ts`（383行）— API调用+WS监听+状态管理

### Guardian 守护机制
- 个人任务：60秒检查心跳，超时标记 stalled，最多3次恢复，之后自动暂停
- 通过 `POST /api/task-pipeline/:taskId/heartbeat` 保活

---

## 长期记忆 · 第五章：核心工作流 & 记忆系统

### 关键问题：AI 记忆现状（文档 OctoWork记忆系统核心问题深度分析.md）
1. **底层**：发消息时调用 `openclaw CLI --session-id`，OpenClaw 服务端维护对话历史
2. **问题**：token无限增长 → 超~100k tokens触发压缩 → 卡顿5-10分钟
3. **防卡顿引擎**（已有但未集成）：到阈值→归档→清空→写回最后5条+废话摘要 = **AI直接失忆**
4. **已实现**：
   - L1 实时记忆配置（token三级内存）
   - 聊天记录写入 `.md` 文件（`appendToChatHistory`）
5. **未实现**（纸上规划）：
   - 记忆大师提炼（第三层）
   - 章鱼学院知识库（第四层）
   - 任何有效的记忆注入机制

### 7种聊天模式（重要特性）
| 模式 | style参数 | 特点 |
|------|-----------|------|
| 说人话 | simple | 核心问题：只说不干活 |
| 交流探讨 | discussion | — |
| 深度思考 | thinking | — |
| 方案报告 | report | — |
| 任务工作 | task | — |
| 创意脑暴 | brainstorm | — |
| 快速决策 | decision | — |

**待解决的根本问题**：Bot回复完成后，无任何后续判断机制（是否完成任务）。已设计三层自检方案，待实施。

### Bot主动找用户
- API：`POST /api/bot/send-to-user {botId, userId, content, type, metadata}`
- **已实现**：✅ 全链路验证通过
- 在线→WebSocket推送；离线→offlineQueue队列，上线后投递

### Bot@Bot群聊任务协作
- 两条链路：用户@Bot（Link A）、Bot从外部发群聊（Link B）
- **防循环**：`depth=0/1`（最大触发深度1），`5秒冷却`，`防自环`
- **任务意图检测**：`TaskDetector` 识别关键词→生成`confirmToken`→WS推送预览卡→用户确认→创建task_box文件
- **已修复（2026-04-05）**：Bot@Bot触发链路

---

## 长期记忆 · 第六章：openclaw-node-sdk 解析

### SDK 架构
```
Operator App ←──WS──→ OpenClaw Gateway(:18789) ←──WS──→ Worker Node
```
- **两个角色**：
  - `operator`：主控方（Dashboard/CLI），可 list nodes、invoke commands
  - `node`：工作节点，声明自己支持哪些 commands，接收并执行

### 核心类 `OpenClawClient extends EventEmitter`
- **连接方式**：WebSocket（ws:// 或 wss://）
- **认证**：Ed25519 Challenge-Response 握手（`identity.ts`）
  - 设备ID = SHA256(raw_32byte_pubkey) → hex
  - 签名负载：`v3|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce|platform|deviceFamily`
- **关键方法**：
  - `connect()` / `disconnect()`
  - `request(method, params)` → Promise（带30秒超时）
  - `invokeNode({nodeId, command, params})` → 调用远端节点命令
  - `listNodes()` → 获取已连接节点列表
  - `send(msg)` → 发送原始JSON消息
- **事件**：`connected` / `disconnected` / `error` / `event` / `message`
- **自动重连**：断开后指数退避（1s→30s）

### 握手协议（Protocol v3）
```
Server → Client: {type:"event", event:"connect.challenge", payload:{nonce}}
Client → Server: {type:"req", method:"connect", params:{role, scopes, client, auth, device, ...}}
Server → Client: {type:"res", ok:true, payload:{auth:{deviceToken, role, scopes}}}
```

### Node模式（Node role）
```typescript
// Worker节点声明命令
commands: ["ping", "screenshot", "shell"]

// 收到调用时
onInvoke: async (command, params) => {
  // 执行并返回结果
  return { result: "..." }
}
```

### 与现有 openclaw.js 的关键区别
| 对比 | 现有 api/openclaw.js | openclaw-node-sdk |
|------|---------------------|-------------------|
| 协议 | CLI 进程包装（spawn） | WebSocket 直连 Gateway |
| 认证 | 无（只传 agent/session 参数） | Ed25519 设备身份认证 |
| 角色 | 单一（调用 OpenClaw Agent） | operator + node 双角色 |
| 能力 | 发消息/获取回复 | 发消息 + 调用任意 Node 命令 |
| 节点控制 | 无 | `listNodes()`, `invokeNode()` |
| 连接 | 进程级（spawn每次新建） | 持久 WebSocket 连接 |

---

## 长期记忆 · 第七章：设计规范 & 部署

### 设计规范（Apple + GenSpark 双标准）
- **颜色**：`#007AFF`（主色/Apple蓝）、`#34C759`（成功绿）、`#FF3B30`（危险红）、`#FF9500`（橙）
- **字体**：`-apple-system` 系统字体栈
- **圆角**：所有容器/卡片/按钮必须有圆角
- **过渡**：所有交互状态变化必须有 0.2s 过渡
- **层次**：5级阴影系统，hover 时 `translateY(-2px)` 暗示可交互
- **CSS变量**：25个模块化CSS文件，全部通过变量引用，支持深色模式

### 用户版发布流程
1. 开发版验证通过 → `rsync` 到用户版目录
2. `backend/server.js` → 编译为 V8 字节码 `server.jsc`（保护源码）
3. 生成机器指纹 → 用户提供指纹给管理员 → 管理员颁发 `license.key`
4. 用户版端口同开发版：后端 1314，前端构建为静态文件

### 10个部门（数字公寓）
| 部门 | 图标 | 人数 |
|------|------|------|
| The-Brain（战略智囊团）| 🧠 | 9 |
| OctoTech-Team（技术研发部）| 🐙 | 10 |
| The-Forge（AI员工铸造厂）| 🔨 | 6 |
| OctoVideo（视频生产）| 🎬 | 12 |
| OctoRed（小红书运营）| 📕 | 4 |
| OctoAcademy（章鱼学院）| 🎓 | 6 |
| OctoBrand（品牌管理）| 🏷️ | 5 |
| The-Arsenal（技能市场）| ⚔️ | 5 |
| OctoGuard（安全卫队）| 🛡️ | 5 |
| TestDept（测试部门）| 🧪 | 0 |

---

## 融合方案草稿（openclaw-node-sdk → octowork-chat）

### 现状问题
1. `api/openclaw.js` 是 CLI 进程包装器 → 每次 `spawn('openclaw', args)` → 性能低、无持久连接
2. 没有实际的 memory/context 注入（完全依赖 OpenClaw 服务端维护 session）
3. Bot 之间的协作靠「群聊转发消息」，不是真正的 node-to-node 调用

### 融合方向
1. **替换 `api/openclaw.js`**：用 `OpenClawClient`（WebSocket）替代 CLI 进程调用
   - 保持 `operatorrole`，通过 gateway `invokeNode` 调用 AI Agent
   - 持久连接，避免每次 spawn 进程
2. **新增 `node` 角色能力**：octowork-chat 后端同时作为 Node 注册到 Gateway
   - 接收来自 Gateway 的命令（如：AI主动找用户、推送通知）
   - 实现真正的双向通信
3. **记忆注入**：在调用 `invokeNode` 前，先读取 `agent公寓/memory/` 和 `chat_history/`，注入上下文

### 关键文件修改点
| 文件 | 修改内容 |
|------|----------|
| `backend/api/openclaw.js` | 用 `OpenClawClient` WebSocket 替代 CLI spawn |
| `backend/server.js` | 启动时建立持久 WS 连接到 Gateway |
| `backend/src/controllers/botController.js` | 发消息时注入 memory 上下文 |
| `backend/src/controllers/groupController.js` | 群聊消息注入上下文 |

---

## 待讨论

1. **openclaw-node-sdk 的 gatewayUrl 是什么**？本地 `ws://localhost:18789` 还是远程服务器？
2. **Ed25519 身份文件放哪里**？每个 Bot 一个身份，还是整个 octowork-chat 共用一个？
3. **记忆注入优先级**：从文件系统注入 vs. 依赖 OpenClaw session（哪种方式改动更小）？
4. **`api/openclaw-fixed.js`** 是什么？（docs 中提到，但未读到）
5. **企微/AI员工/章鱼学院/技能市场（06-09章）**：文档全部为空，功能还没开始建，融合时暂不考虑。
