# AI 工作记忆 — OctoWork 聊天管理器

> **创建时间**: 2026-04-03  
> **维护者**: Claude (AI 开发助手)  
> **用途**: 断线重连后读此文件即可恢复全部上下文  
> **最后更新**: 2026-04-07 — Backlog全面审计：6项待处理事项全部确认已修复/已实施，更新项目状态

---

## 零、OctoWork 三层架构 (用户电脑根目录)

用户电脑上有 3 个核心文件夹，构成 OctoWork 的完整运行环境：

```
用户根目录 ~/
├── .openclaw/                     ← 执行层 (AI 执行引擎，配置文件)
│   └── openclaw.json                 工作路径已配置指向 ~/octowork/
│
├── octowork/                      ← 数字公寓 (数据+工作区，所有版本共享)
│   ├── data/
│   │   └── chat.db                   ⭐ 聊天数据库（聊天管理器连接此文件）
│   ├── config/ai-directory.json      公司通讯录 (62员工, 10部门, 9团队)
│   ├── departments/                  10 个部门，每个含 agents/ 和 team_config.json
│   ├── governance/                   公司治理体系
│   ├── shared/                       共享资源 (工具/模板/知识库)
│   ├── projects/                     项目管理中心
│   ├── docs/                         公司文档库
│   └── ...
│
├── octowork-chat-dev/             ← 开发版 Bot聊天管理器 (本项目)
│   ├── backend/                      Node.js + Express + SQLite
│   ├── frontend/                     Vue 3 + TypeScript
│   └── octowork/                     ← 数字公寓副本 (仅方便开发时看全局)
│
└── octowork-chat/                 ← 用户版 Bot聊天管理器 (未来发布)
    ├── backend/
    └── frontend/
```

### ⭐ 数据库路径规则（绝对不能写死）

**聊天管理器的数据库永远在 `~/octowork/data/chat.db`，不在聊天管理器项目内部。**

- 本项目 `octowork-chat-dev/` 和未来的 `octowork-chat/` 只是**客户端程序**
- 数据存储在 `~/octowork/data/` — 数字公寓目录下
- 目录不存在时自动 `mkdirSync(recursive: true)` 创建

```
数据库路径（固定，不随项目变化）：
  ~/octowork/data/chat.db          ← 聊天数据库
  ~/octowork/data/offline_queue/   ← 离线消息队列

代码中的兜底逻辑（database.js）：
  $HOME/octowork/data/chat.db
  即 /Users/jason/octowork/data/chat.db（macOS）
  即 /home/user/octowork/data/chat.db（Linux）

注：OCTOWORK_WORKSPACE 环境变量如果设了，值就是 ~/octowork/，
   等于换了一种方式指向同一个位置，不会产生新的路径层级。
```

涉及文件：`database.js`、`offlineQueue.js`、`messageSummaryService.js`、`botController.js`

### 通讯录机制
- **文件**: `octowork/config/ai-directory.json`
- **自动扫描**: 从 `departments/*/agents/*/team_config.json` 聚合，每3600秒刷新
- **前端读取**: `useDepartmentConfig.ts` composable 从此 JSON 获取部门+Bot 列表
- **后端使用**: `botController.js` / `groupController.js` 中 `detectBotEnvironment(botId)` 用于判断 Bot 类型

### 当前 10 个部门

| 部门 | 图标 | 人数 | 说明 |
|------|------|------|------|
| The-Brain (战略智囊团) | 🧠 | 9 | 章鱼帝领导，战略/决策/知识/监控/创新参谋 |
| OctoTech-Team (技术研发部) | 🐙 | 10 | 章鱼博士领导，10个工程师 |
| The-Forge (AI员工铸造厂) | 🔨 | 6 | 产品管理+市场研究+研发+合伙人+定制+测试 |
| OctoVideo (视频生产) | 🎬 | 12 | TK视频全流程 |
| OctoRed (小红书运营) | 📕 | 4 | 管理+文案+图片+发布 |
| OctoAcademy (章鱼学院) | 🎓 | 6 | 院长+内容挖掘+生产+审核+推送+数据 |
| OctoBrand (品牌管理) | 🏷️ | 5 | 品牌总监+监控+SEO+内容+平台拓展 |
| The-Arsenal (技能市场) | ⚔️ | 5 | 管理+挖掘+试毒+研发+发布 |
| OctoGuard (安全卫队) | 🛡️ | 5 | 数据安全+行为安全+技能安全+平台安全+合规审查 |
| TestDept (测试部门) | 🧪 | 0 | 测试用 |

---

## 一、项目概况

**仓库**: `octoworkai/octowork-chat-dev`  
**定位**: OctoWork 三层架构中的 **聊天层** — 用户与AI、AI与AI 的沟通交流中心  
**技术栈**: Vue 3 + TypeScript (前端) / Node.js + Express + SQLite (后端)  
**App.vue**: 3503 行 → **576 行** (瘦身 83.6%)

---

## 二、项目文件地图

### 后端核心 (`backend/`)

| 文件 | 职责 | 重要度 |
|---|---|---|
| `server.js` | 主入口，内含 **WebSocketManager** 类、**OpenClawClient** 类、WS 心跳、依赖注入 | ★★★ |
| `src/controllers/botController.js` | **单聊核心控制器** (1734行) — sendMessage、sendToUser、文件系统API、任务监控 | ★★★ |
| `src/controllers/groupController.js` | **群聊核心控制器** — sendGroupMessage、botSendToGroup、@mention 解析 | ★★★ |
| `src/services/sessionManager.js` | **用户在线状态管理器** — 跟踪 WS 连接、在线/离线事件 | ★★★ |
| `src/services/openclawSessionManager.js` | **AI 对话上下文管理器** — `user_<uid>_bot_<bid>` / `group_<gid>` session_id | ★★★ |
| `src/services/offlineQueue.js` | 离线消息队列 — 持久化到磁盘 JSON | ★★ |
| `db/database.js` | SQLite 数据层 — messages/sessions + groups/group_messages/group_members 表 | ★★★ |
| `src/routes/botRoutes.js` | 单聊路由：/messages、/bots/:botId/files、/bot/send-to-user | ★★ |
| `src/routes/groupRoutes.js` | 群聊路由：/groups CRUD、/groups/:groupId/messages、/bot/send-to-group | ★★ |
| `src/routes/taskPipelineRoutes.js` | 个人任务流水线路由：create/start/step/heartbeat/active/status/complete | ★★ |
| `services/personalTaskPipeline.js` | **个人任务流水线服务** (836行) — 创建/启动/步骤更新/心跳/Guardian守护 | ★★★ |
| `group-sync.js` | **群组自动同步** (339行) — ai-directory.json 对账/文件监听/成员增删 | ★★ |

### 前端核心 (`frontend/src/renderer/`)

#### Composables (业务逻辑层)

| 文件 | 行数 | 职责 |
|---|---|---|
| `composables/useSingleChat.ts` | 760 | **单聊全部逻辑** — 消息加载/发送/缓存/滚动/文件上传/轮询兜底 |
| `composables/useWebSocket.ts` | 582 | **WS 全套** — 连接/心跳/重连/消息分发/12个handler |
| `composables/useGroupChat.ts` | 850 | **群聊全部逻辑** — 消息/发送/@mention(昵称↔ID双向转换)/成员管理/WS自注册 |
| `composables/useMessages.ts` | 505 | 消息状态管理 (单聊+群聊共享状态) |
| `composables/useTasks.ts` | 395 | 任务监控 — 任务列表/状态/弹窗/格式化 |
| `composables/useBots.ts` | 300 | Bot 管理 — 列表/选择/模型切换/能力查询 |
| `composables/useTeams.ts` | 291 | 团队列表 — 目录扫描/分组/定时刷新 |
| `composables/useLazyLoad.ts` | 227 | 懒加载 |
| `composables/useDepartmentConfig.ts` | 191 | 部门配置 — 从 ai-directory.json 动态获取 |
| `composables/useAppInit.ts` | 121 | 应用初始化 |
| `composables/useFiles.ts` | 61 | 文件管理 |

#### 组件

| 文件 | 行数 | 职责 |
|---|---|---|
| `components/chat/MessageInput.vue` | 831 | 单聊输入框 (7种聊天模式+图片上传+拖拽) |
| `components/chat/MessagesView.vue` | 658 | 单聊消息列表 (Markdown渲染+TODO清单+复制) |
| `components/chat/ChatArea.vue` | 537 | 聊天区域容器 (Dashboard+Bot工作区+聊天/文件/任务Tab) |
| `components/TasksView.vue` | 321 | 任务视图 |
| `components/chat/GroupMessageInput.vue` | 945 | 群聊输入框 + @mention(渐变色 fallback + 完整ID显示) |
| `components/chat/ChatHeader.vue` | 571 | 单聊/群聊头部 + 群聊使用说明弹窗 |
| `components/chat/GroupMessagesView.vue` | 606 | 群聊消息列表 (32px圆形头像+渐变色fallback) |
| `components/chat/GroupChatView.vue` | 184 | 群聊容器壳 (组合3个子组件) |
| `components/Dialogs/MembersDialog.vue` | 221 | 群组成员弹窗(显示群ID+禁止删除) |
| `components/FilesView.vue` | 122 | 文件视图 |

---

## 三、架构设计

### 双 SessionManager

```
┌──────────────────────────────────────────────────────┐
│                    server.js (主入口)                   │
│                                                        │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────┐ │
│  │ SessionMgr   │  │ OpenClawSessionMgr│  │ WS Mgr   │ │
│  │ (用户在线)    │  │ (AI对话上下文)    │  │ (广播)    │ │
│  │ userId→ws    │  │ user_<uid>_bot_<b>│  │broadcast()│ │
│  │ isUserOnline │  │ group_<gid>       │  │sendToUser│ │
│  └──────────────┘  └──────────────────┘  └──────────┘ │
│      └── 注入 BotController + GroupController ──┘       │
└──────────────────────────────────────────────────────┘
```

- **SessionManager**: 跟踪**人类用户** WS 连接和在线状态
- **OpenClawSessionManager**: 管理**对话 session_id**，传给 OpenClaw CLI 维持 AI 多轮上下文
- **WebSocketManager** (server.js 内联版): 实际广播器。注意 `websocket/manager.js` 是旧版不使用

---

## 四、已完成工作

### 4.1 群聊 Bug 修复 (2026-04-03) ✅ 全部完成

| # | Bug | 严重度 | 修复 |
|---|-----|--------|------|
| 1 | `saveGroupMessage` 缺 `await` | 🔴 | 加 await |
| 2 | `getGroupMessages` 缺 `await` | 🔴 | 加 await |
| 3 | `fs.promises` 混用 `statSync` | 🔴 | → `await fs.stat()` |
| 4 | `botSendToGroup` 缺 `await` | 🟡 | 加 await |
| 5 | mentions 用 userId 查 bot 在线 | 🟡 | 区分 bot/user mention |
| 6 | `getGroupMentions` 空壳 | 🟢 | 实现查询逻辑 |

### 4.2 群聊独立重构 (Batch 1-6) ✅ 全部完成

| Batch | 内容 | Commit |
|-------|------|--------|
| 1 | 四栏布局 + GroupWorkspacePanel | `cfaa73c` |
| 2 | GroupChatHeader + GroupMessagesView | `93a1961` |
| 3 | GroupMessageInput，GroupChatView 瘦为壳 | `0c23c11` |
| 4 | useGroupChat.ts composable (509行) | `17d19a8` |
| 5 | WS 自注册 + @mention 通知迁入 composable | `015c1d7` |
| 6 | 独立路由 /group/:groupId + GroupChatPage.vue | `85aa09f` |

### 4.3 App.vue 瘦身 ✅ 已达标 (576 行)

**原 3503 行 → 576 行 (减 83.6%)**

| 阶段 | 内容 | 减少 | Commit |
|------|------|------|--------|
| A | 内联页面搬走 (Equipment/Stats) + 残余样式 | ~127 行 | `c969721` |
| B | WebSocket → `useWebSocket.ts` (582行) | ~555 行 | `c969721` |
| 硬编码 | 部门配置 → `useDepartmentConfig.ts` (191行) | ~90 行 | `3796ec4` |
| M | Markdown → `utils/markdown.ts` (189行) | ~163 行 | `72e9e2e` |
| D1 | 团队 → `useTeams.ts` (291行) | ~191 行 | `18265ad` |
| D2+E1+F1 | Bot模型+任务+Dashboard 批量迁移 | ~380 行 | `fb10217` |
| C | 单聊消息 → `useSingleChat.ts` (760行) | ~470 行 | `cd8f5d0` |
| P0+P1 | 最终清理: 重复声明/废弃代码/模板简化 | ~662 行 | `ed65f61` |

### 4.4 文档重构 (2026-04-04) ✅

- 群聊文档: 删除旧子目录，新建 API速查/数据库Schema/前端组件树
- 聊天文档: 删除旧文档+历史资料，新建 API速查/数据库Schema/前端组件树

---

## 五、待处理事项 (Backlog)

### ✅ 已解决（2026-04-07 审计确认）

| # | 原始问题 | 状态 | 解决方案 |
|---|---------|------|---------|
| 1 | 🔴 **P0: Bot @Bot 不触发 OpenClaw** | ✅ 已修复 | 新增 `_triggerMentionedBots()` 统一触发方法，`botSendToGroup` 和 `sendGroupMessage` 共用；内置 `MAX_TRIGGER_DEPTH=1` 防循环 + 5s 冷却 |
| 2 | 🔴 **P0: 用户识别 Bug** | ✅ 已修复 | 新增 `_isHumanUser(id)` 方法，兼容 `'admin'` 和 `'user'` 两种 ID；`botSendToGroup` 中 @用户通知使用 `actualUserId` 映射 |
| 3 | 🟡 **任务看板重构为流水线驱动** | ✅ 已实施 | `personalTaskPipeline.js`(836行) + `taskPipelineRoutes.js`(221行) — 7个API端点：create/start/step/heartbeat/active/status/complete |
| 4 | 🟡 **两套 WebSocketManager 共存** | ✅ 已解决 | `websocket/manager.js` 已标记为 `.deprecated`，全代码库零引用；`server.js` 内联版为唯一 WebSocketManager |
| 5 | 🟢 **群组成员与 Bot 目录不同步** | ✅ 已解决 | `group-sync.js`(339行) 实现自动对账：启动时同步 + 文件/目录监听 + source='auto' 隔离 |
| 6 | 🟢 **Bot 回复缺乏重试机制** | ⚠️ 部分完成 | 单聊 `botController.js` 已有 3s 快速重试；群聊 `groupController.js` 尚无重试（低优先级，群聊有 WS 广播兜底） |
| 7 | 🟡 **@mention 只匹配 shortId** | ✅ 已解决 | 前端双向映射（中文昵称↔botId），后端正则 `/@([a-zA-Z0-9\-_]+)/g` 匹配完整 botId |
| 8 | 🟡 **任务意图检测未集成到群聊** | ✅ 已修复 | `sendGroupMessage` 中已调用 `taskDetector.detectTaskIntent()`（groupController.js L737） |

### 🔮 可选优化 (非阻塞)

- **App.vue 进一步瘦身** (当前 576 行已达标 ≤ 800):
  - G1: onMounted 拆分 — 各模块初始化分散到 composable 的 `init()`
  - G3: 剩余 ref/watch 整理 — 归类到对应 composable
  - G4: Bot 工作区包装为 `BotChatView.vue` — 模板再精简
- **群聊 Bot 回复重试**: 参照单聊 3s 重试逻辑，在 `_triggerMentionedBots` 中添加失败重试

---

## 六、文件定位速查

```
# 后端核心
backend/server.js                              ← WebSocketManager + OpenClawClient + 依赖注入
backend/src/controllers/botController.js       ← 单聊控制器 (1734行)
backend/src/controllers/groupController.js     ← 群聊控制器
backend/src/routes/botRoutes.js                ← 单聊路由
backend/src/routes/groupRoutes.js              ← 群聊路由
backend/db/database.js                         ← 数据库层
backend/src/services/sessionManager.js         ← 用户在线管理
backend/src/services/openclawSessionManager.js ← AI 会话管理
backend/src/routes/taskPipelineRoutes.js       ← 个人任务流水线路由 (7个API)
backend/services/personalTaskPipeline.js       ← 个人任务流水线服务 (836行)
backend/group-sync.js                          ← 群组自动同步 (339行, 对账+监听)

# 前端入口
frontend/src/renderer/App.vue                  ← 576 行，路由壳 + 导航 + 视图分发

# 前端 Composables (业务逻辑)
frontend/src/renderer/composables/useSingleChat.ts    ← 单聊全部逻辑 (760行)
frontend/src/renderer/composables/useWebSocket.ts     ← WS 全套 (582行)
frontend/src/renderer/composables/useGroupChat.ts     ← 群聊全部逻辑 (509行)
frontend/src/renderer/composables/useMessages.ts      ← 消息状态管理 (505行)
frontend/src/renderer/composables/useTasks.ts         ← 任务监控 (395行)
frontend/src/renderer/composables/useBots.ts          ← Bot 管理 (300行)
frontend/src/renderer/composables/useTeams.ts         ← 团队列表 (291行)
frontend/src/renderer/composables/useDepartmentConfig.ts ← 部门配置 (191行)

# 前端单聊组件
frontend/src/renderer/components/chat/ChatArea.vue       ← 聊天区域容器 (537行)
frontend/src/renderer/components/chat/ChatHeader.vue     ← 单聊头部 (266行)
frontend/src/renderer/components/chat/MessagesView.vue   ← 单聊消息列表 (658行)
frontend/src/renderer/components/chat/MessageInput.vue   ← 单聊输入框 (831行)

# 前端群聊组件
frontend/src/renderer/components/chat/GroupChatView.vue       ← 容器壳 (184行)
frontend/src/renderer/components/chat/GroupMessagesView.vue   ← 群聊消息列表 (606行)
frontend/src/renderer/components/chat/GroupMessageInput.vue   ← 群聊输入框 (945行)
frontend/src/renderer/components/Dialogs/MembersDialog.vue   ← 群组成员弹窗 (221行)
frontend/src/renderer/views/GroupChatPage.vue                 ← 独立路由页面

# 工具
frontend/src/renderer/utils/markdown.ts       ← Markdown + TODO 解析
frontend/src/renderer/utils/helpers.ts        ← createAvatarResolver + resolveStaticUrl + 状态辅助
frontend/src/renderer/utils/apiBase.ts        ← API_BASE 共享常量

# 栏目文档索引
docs/AI工作记忆.md                              ← 本文件 — 恢复上下文的唯一入口
docs/02-首页-栏目开发/API速查.md                ← 认证API + 登录流程 + 路由定义 + 视频配置 + 全局导航标识
docs/02-首页-栏目开发/前端组件树.md             ← 四列布局 + Login.vue + DashboardView + MainLayout + ContentSidebar
docs/03-聊天-栏目开发/API速查.md                ← 单聊 API 路由 + sendMessage 流程 + WS 消息格式
docs/03-聊天-栏目开发/数据库Schema.md           ← messages + sessions 表 + DB 函数速查
docs/03-聊天-栏目开发/前端组件树.md             ← 组件依赖 + useSingleChat 入参/返回值 + 7种聊天模式
docs/04-群聊-栏目开发/API速查.md                ← 群聊 API 路由 + sendGroupMessage 流程 + WS 消息格式
docs/04-群聊-栏目开发/数据库Schema.md           ← groups + group_members + group_messages 表
docs/04-群聊-栏目开发/前端组件树.md             ← 组件依赖 + useGroupChat 入参/返回值 + @mention 流程
docs/04-群聊-栏目开发/群聊Bot间协作根治方案.md    ← P0架构级：BotSendToGroup 触发缺陷根因+统一触发方案+防循环机制+实施计划
docs/05-任务看板-栏目开发/任务看板重构方案-流水线驱动.md ← 架构重构：砍四列看板→pipeline_state.json流水线视图+Octopus排程+Guardian融合+跨部门工厂标准
docs/05-任务看板-栏目开发/API速查.md                          ← 看板 API 路由 + 旧API + 新流水线 API + WS 推送格式 + EventBus 事件
docs/05-任务看板-栏目开发/前端组件树.md                      ← 旧组件盘点(3800行) + 新组件设计(~1300行) + usePipeline composable + 路由配置
docs/05-任务看板-栏目开发/数据库Schema.md                    ← task_box .md 格式 + pipeline_state.json 完整 schema + 模板 + 归档日志
docs/05-任务看板-栏目开发/开发方案.md                        ← 两阶段交付: 阶段一静态页面验收 → 阶段二完整实现 + Mock数据 + 验收标准
docs/14-设计规范标准/octowork-设计规范手册.md           ← 统一设计规范: 色彩/字体/间距/圆角/阴影/按钮/卡片/动效/布局 (Apple+GenSpark基准)
docs/10-核心工作流功能/bot聊天管理器消息对账功能.md              ← 消息丢失根因分析 + 对账服务架构 + 7项问题修复 + 六层保障
docs/10-核心工作流功能/octowork实现AI智能化主动找用户的功能.md   ← Bot sendToUser 完整链路 + 三种触发维度 + 投递保障
docs/10-核心工作流功能/octowork实现AI自动群聊发布接收任务功能.md ← botSendToGroup + @mention + 任务意图检测 + TaskBoxWatcher
docs/10-核心工作流功能/octowork实现单聊群聊功能操作手册.md       ← AI员工操作手册 v2.0 + TokVideo实战案例 + 天坑四层分析 + 任务卡驱动闭环
docs/10-核心工作流功能/04-员工配置管理.md                       ← 员工配置管理
```

---

## 七、修改日志

### 2026-04-07 — Backlog 全面审计（6项待处理事项确认已修复）

审计 AI工作记忆.md 中 8 项 Backlog，逐一在最新代码中验证修复状态。

| # | 事项 | 结论 | 验证依据 |
|---|------|------|---------|
| 1 | 🔴 Bot @Bot 不触发 OpenClaw | ✅ 已修复 | `_triggerMentionedBots()` 统一方法 + `botSendToGroup` L1331 异步调用 |
| 2 | 🔴 用户识别 Bug (`'user'` vs `'admin'`) | ✅ 已修复 | `_isHumanUser()` L128 兼容两种ID + L1311 `actualUserId` 映射 |
| 3 | 🟡 任务看板→流水线驱动 | ✅ 后端已实施 | `personalTaskPipeline.js`(836行) + `taskPipelineRoutes.js`(7个API) |
| 4 | 🟡 两套 WebSocketManager | ✅ 已解决 | `manager.js.deprecated` + 全代码库零引用旧文件 |
| 5 | 🟢 群组成员目录不同步 | ✅ 已解决 | `group-sync.js`(339行) 自动对账 + 文件/目录监听 |
| 6 | 🟢 Bot 回复无重试 | ⚠️ 部分 | 单聊有3s重试，群聊暂无（低优先级） |
| 7 | 🟡 @mention shortId | ✅ 已解决 | 前端双向映射 + 后端完整botId正则 |
| 8 | 🟡 任务意图检测未集成群聊 | ✅ 已修复 | `sendGroupMessage` L737 调用 `taskDetector` |

**Backlog 状态**: 8项中 7项已完全修复，1项部分完成（群聊重试为低优先级）。

### 2026-04-07 — 近期已合并的重要功能（从 git log 补录）

| Commit | 功能 | 详情 |
|--------|------|------|
| `04d0a0a` | **GroupSync 自动建群集成** | group-sync.js(339行)：启动时自动对账 + 文件/目录监听 + 字段兼容 |
| `c8a9d8b` | **PersonalTasks 流水线系统** | personalTaskPipeline.js(836行)：7个API + Guardian守护 + 心跳检测 |
| `44769ef` | **getSessions 修复** | botMap 构建兼容 id/bot_id/key 三种格式，修复最近聊天头像/昵称不显示 |
| `1b29846` | **更新功能增强** | 系统组件增强 + 会话清理保护 |
| `618f6ae` | **数据库触发器修复** | 触发器语法错误修复 + 自动更新功能增强 |
| `d66afc4` | **ReleaseOps 用户版运营团队** | 5人岗位职责 + SOP + v0.5.9发布流水线模拟 |
| `6bc8788` | **版本号弹窗** | 点击版本号显示当前版本功能详情 |

### 2026-04-05 — 群聊 @mention 深度修复（使用说明AI视角 + @mention浮层 + 严格群过滤 + @全体成员）

4 个文件修改，+327 / -145 行。

| # | 修改 | 文件 | 详情 |
|---|------|------|------|
| 1 | **使用说明弹窗改为AI视角** | `ChatHeader.vue` | 标题改为"AI团队群组配置信息"；内容按AI需要的格式重写：群昵称、群ID、群成员ID列表、@全体成员方法(`@all`)、@用户方法(`@user`)、@其它成员方法(逐个列出`@botId → 中文名`)、使用技巧；一键复制输出AI友好纯文本格式 |
| 2 | **@mention 下拉列表脱离输入框裁剪** | `GroupMessageInput.vue` | 将 `.mention-suggestions` 从 `.input-card` 内部移到 `.group-input-container` 顶层，使用 `position: absolute; bottom: 100%` 浮于输入卡片上方，不再被 `overflow: hidden` 裁剪 |
| 3 | **严格按当前群成员过滤@列表** | `useGroupChat.ts` | 移除 `sourceBots = bots.value` 的全局回退逻辑；若 `selectedGroup.members` 为空则不显示建议，杜绝跨群成员泄漏 |
| 4 | **新增 @全体成员 快捷选项** | `useGroupChat.ts` + `GroupMessageInput.vue` | @列表顶部新增"📢 全体成员"选项（搜索关键词匹配"全体成员"或"all"）；`selectMention` 插入 `@全体成员`，发送时转为 `@all`；`highlightMentions` 识别 `@all` 渲染为橙色高亮 |
| 5 | **@all 消息渲染橙色高亮** | `GroupMessagesView.vue` | 新增 `.mention-all` CSS 类：橙色(#FF9500) + 橙色半透背景 |

**关键架构决策：**
- 使用说明弹窗从"用户教程"改为"AI配置信息"视角：内容供人类复制给各AI团队成员
- @mention 浮层使用 `.mention-suggestions-overlay` 中间层做绝对定位，`pointer-events: none/auto` 保证点击穿透
- @全体成员使用 `@all` 作为特殊ID，和 `@user` 一样作为保留关键字
- 群成员过滤不再回退到全局 bots 列表，严格只显示当前群组的 members

### 2026-04-05 — 群聊 UI 七项优化（@mention 显示 + 成员弹窗 + 使用说明 + 昵称转换 + 头像统一）

8 个文件修改，+448 / -54 行。Commit: `b1b7dc0`。

| # | 修改 | 文件 | 详情 |
|---|------|------|------|
| 1 | **修复 @mention 弹窗样式** | `GroupMessageInput.vue` | 完整显示 bot ID（等宽字体）、渐变色首字母 fallback、max-width 防截断 |
| 2 | **禁止删除群成员** | `MembersDialog.vue` | 移除所有“移除”按钮（自动创建群不允许删除成员） |
| 3 | **成员弹窗显示群 ID** | `MembersDialog.vue` | header 新增蓝色「群ID: xxx」 badge，接收 `groupId` prop |
| 4 | **新增使用说明图标+弹窗** | `ChatHeader.vue` | 群聊头部新增 ❓ 图标，点击弹出弹窗包含：群ID、成员列表+ID、@用法、使用技巧、一键复制 |
| 5 | **输入框 @botId 自动转中文昵称** | `useGroupChat.ts` | `selectMention()` 插入中文昵称，`resolveDisplayNamesToIds()` 发送前转回 ID，`mentionDisplayMap` 双向记录 |
| 6 | **消息中 @mention 显示中文昵称** | `useGroupChat.ts` | `highlightMentions()` 从 bots 数组查找中文名替换 bot ID |
| 7 | **头像统一 32px 圆形+阴影+渐变 fallback** | 多文件 | 8 种渐变色按 botId hash 分配，头像缺失时显示首字母 |

**关键架构决策：**
- 头像从 `ai-directory.json` 动态获取，不写死路径（`createAvatarResolver(bots)` 在 `helpers.ts`）
- @mention 显示中文昵称但发送 bot ID（前端双向映射，后端无感知）
- 自动创建群不允许删除成员（UI 层隐藏按钮）

### 2026-04-05 — 聊天 UI 三项优化（中文部门 + 行距 + @mention 颜色）

3 个文件修改，+26 / -15 行。Commit: `d01d2a2`。

| # | 修改 | 详情 |
|---|------|------|
| 1 | 聊天头部英文部门名→中文 | `App.vue` 优先使用 `bot.department_path`（如 "The-Brain"）匹配 department-config，显示“章鱼帝 (总指挥官) - 🧠 战略智囊团” |
| 2 | 消息气泡行距/段距优化 | `MessagesView.vue` + `GroupMessagesView.vue`：line-height 1.65, `p { margin: 0 }`, `br { height: 0 }` |
| 3 | 绿色气泡 @mention 可读性 | `.message-user .mention` 颜色改为白色 + 半透明背景 |

### 2026-04-05 — 头像动态解析重构（去除硬编码映射）

7 个文件修改，+91 / -54 行。Commit: `25c1124`。

| 修改 | 详情 |
|------|------|
| 新增 `createAvatarResolver(botsRef)` | `helpers.ts` 中工厂函数，从 bots 数组动态查找头像，不依赖 avatarHelper.js 硬编码映射 |
| App.vue + GroupChatPage.vue | 改用 `createAvatarResolver(bots)` |
| useSingleChat.ts + useTeams.ts | 移除 avatarHelper 导入 |
| GroupMessageInput/GroupMessagesView | 响应式 avatarErrors 追踪 + fallback |

### 2026-04-04 — 设计规范手册 v1.1（Dashboard 驾驶舱 + 完整组件体系）

- **升级** `octowork-设计规范手册.md` v1.0 → v1.1（14.5k → 30.6k 字符，14 章 → 17 章 + 2 附录）
- **新增内容**：
  - §1.3/1.4 Apple + GenSpark 设计参考要点表（明确两个参考系的每条原则如何落地）
  - §2.3 数据可视化色板（Dashboard 4 色 + glow 发光 + 品牌渐变 cyan→purple）
  - §2.5 暗色模式 Apple 暗色变体（亮→暗色对照完整表，含 `#007AFF→#0A84FF` 等 4 个语义色暗色版）
  - §3.4 特殊文字效果（渐变文字、tabular-nums、text-shadow 发光）
  - §8.2 Dashboard 统计卡片（`translateY(-4px)` 大浮起 + 顶部色条渐显）
  - §8.3 Dashboard 状态栏卡片规范
  - §9 表单系统（输入框 focus ring `box-shadow: 0 0 0 3px rgba(0,122,255,0.1)`、表单布局、选择列表）
  - §10 对话框系统（遮罩层 blur(4px)、slideUp 动画、用户侧栏滑入、悬浮详情面板）
  - §12 图标系统（线性 stroke-width:2、尺寸 20/24px、不透明度 0.6→1.0）
  - §13.4 响应式断点（1400/1200/900/768/375 五档）
  - §14.6 进度条 / Track-Fill 组件
  - 附录A 快速复制代码片段（4 个常用组件 CSS 模板）
  - 附录B 变更日志
  - 开发检查清单从 10 条 → 15 条（增加图标/表单/响应式/Apple一致性/GenSpark一致性）
- **数据来源**：完整分析了 DashboardView.vue + StatsOverview.vue + BotCardGrid.vue + dialogs.css + responsive.css 等 Dashboard 驾驶舱实际代码

### 2026-04-04 — 设计规范手册创建 + 技术团队目录重组

- **删除** `docs/14-技术团队标准/` 全部 16 份旧文档 (~6,197 行)：团队魂文档、技术架构白皮书、协作规范、质量保障等过时内容
- **重命名** 目录为 `docs/14-设计规范标准/`
- **新建** `octowork-设计规范手册.md` v1.0 (14.5k 字符，14 章)：
  - 基于实际 CSS 代码分析 (25 个模块化 CSS 文件) 提取所有设计 token
  - 色彩系统: 品牌色 + 语义色 + 灰度色阶 + 流水线状态色 + 暗色模式
  - 字体系统: 8 级字号 + 5 级字重 + 系统字体栈
  - 间距/圆角/阴影: 各 6 级变量体系，全部从 global.css 提取
  - 按钮 6 种类型 + 卡片系统 + 动效系统 + 布局 4 种模式
  - 开发检查清单 10 条
  - 设计基准: Apple HIG + GenSpark Design System

### 2026-04-04 — 任务看板开发文档体系建立 + 开发方案

- 新建 4 份看板栏目速查文档（对齐聊天/群聊栏目的文档结构）：
  1. `API速查.md` — 旧 API (5 条路由) + 新流水线 API (6 条) + WS 推送格式 + EventBus 事件
  2. `前端组件树.md` — 旧组件盘点 (9个, 3800行) + 新组件设计 (7个, ~1300行) + usePipeline composable
  3. `数据库Schema.md` — task_box .md 文件格式 + pipeline_state.json 完整 schema + 模板 + 归档日志
  4. `开发方案.md` — 两阶段交付策略: 阶段一静态 Mock 页面验收 → 阶段二接入真实数据
- 开发方案要点：
  - 阶段一 (~2h): 用硬编码 Mock 数据做 3 个静态页面 (BoardPage改造 + ProjectListView + PipelineView)
  - 阶段二 (~5h): 接 API + WS + 催促功能 + 清理旧代码 + 联动验证
  - Mock 数据严格按 pipeline_state.json schema 编写，降低阶段二对接成本
- 目录从 1 个文件 → 5 个文件，与 03/04 栏目文档结构对齐

### 2026-04-04 — 任务看板重构方案 v1.2（落实 5 项用户确认决策）

- 升级 v1.1 → v1.2，落实全部 5 项用户确认决策：
  1. **Octopus 排程**：全自动（cron + 品牌资产入库触发 + 自动产量判断），用户可随时覆盖
  2. **部门 QC**：每个部门独立 QC，绝对不硬编码部门/员工，动态扫描 departments/
  3. **工序卡格式**：`.md` + YAML frontmatter（人可读 + 机可读）两者兼顾
  4. **看板快捷操作**：加手动催促按钮（§8.0 详细设计）+ 跳转群聊按钮
  5. **历史归档**：保留 7 天，7 天后自动归档到 `archive/` 目录（新增第十五章完整设计）
- 附录 C 从"待讨论"更新为"全部已确认"结论表格
- 新增第十五章：7 天归档策略（归档流程、目录结构、恢复机制）

### 2026-04-04 — 任务看板重构方案 v1.1（流水线驱动 + Octopus 排程 + Guardian 融合）

- 大幅升级 `docs/05-任务看板-栏目开发/任务看板重构方案-流水线驱动.md` 从 v1.0 到 v1.1（22k 到 35k 字符）
- **核心决策**：砍掉旧"四列拖拽看板"，改为以 `pipeline_state.json` 为唯一真相源的项目流水线进度视图
- **三套系统合一**：useTasks/TasksView + BoardController/TaskBoxWatcher + pipeline_state.json/Guardian 统一为 pipeline 驱动
- **垂直流水线**："空或1"原则——团队 task_box in_progress 最多 1 个项目，个人 task_box in_progress 最多 1 个工序
- **新增章节**：Octopus 排程系统（第四章）、Project Guardian 融合（第五章）、跨部门统一标准（第九章）
- **前端三级路由**：/board（部门总览）到 /board/:deptId（项目列表）到 /board/:deptId/:projectId（流水线详情）
- **新增 8 个组件**：ProjectListView, PipelineView, PipelineBar, StepNode, EventLog, GuardianStatus, TaskBoxStatus, usePipeline
- **删除旧组件**：KanbanView(740行), TasksView(322行), useTasks(395行)
- **文档清理**：删除 4 份旧看板文档 + 开发指南目录（共约 3504 行过时文档）
- **五阶段实施**：Phase 0 清理 到 Phase 1 后端 API 到 Phase 2 前端 到 Phase 3 改造 到 Phase 4 联动 到 Phase 5 跨部门
- **5 个讨论要点**：Octopus 触发方式、跨部门验收角色、工序卡格式、看板快捷操作、历史归档策略

### 2026-04-04 — 群聊 Bot 间协作根治方案（P0 架构级讨论稿）

- 新建 `docs/04-群聊-栏目开发/群聊Bot间协作根治方案.md`（讨论稿，待确认后实施）
- **核心问题**：`botSendToGroup` (L564-682) 中 @Bot 只发 WS 通知不触发 OpenClaw，而 `sendGroupMessage` (L202-389) 会触发
- **根治方案 4 项改动（~155行）**：
  1. 新增 `_triggerMentionedBots()` 统一触发方法（内置 `MAX_TRIGGER_DEPTH=1` 防循环）
  2. 新增 `_isHumanUser()` 修复 L636 `mentionedId==='user'` Bug（应为 `'admin'`）
  3. 改造 `botSendToGroup` 调用新方法（Bot @Bot 触发 OpenClaw）
  4. 改造 `sendGroupMessage` 复用同一触发逻辑（减少重复）
- **防循环精髓**：depth 区分“主动调 API”（新 HTTP 请求 depth=0）vs“回复文本中被动 @”（同请求内 depth=1 被挡）
- **附带发现**：L640 `isUserOnline(mentionedId)` 连锁 Bug；`detectBotEnvironment()` 硬编码返回 local
- **实施计划**：Phase 1 代码修复(30min) → Phase 2 Agent Prompt优化 → Phase 3 TokVideo链路验证 → Phase 4 TaskExecutionLoop兆底
- **8 项成功标准**：覆盖用户@Bot、Bot@Bot、防乒乓、防自环、@admin通知、链式触发、频率限制、TokVideo全流程

### 2026-04-04 — 单聊群聊操作手册 v2.0（TokVideo 实战案例 + 四层闭环）

- **大幅升级** `octowork实现单聊群聊功能操作手册.md` 从 v1.0 → v2.0（27k → 43k 字符）
- 新增 **TokVideo 实战案例**（第五章）：完整 8 人协作群聊消息流（立项→采集→质检→拆解→...→发布）
  - 每条消息对应精确的 `POST /api/bot/send-to-group` 调用
  - 包含打回场景、超时卡壳场景的消息流示例
- 新增 **任务卡驱动章节**（第四章）：标准任务卡格式 + 生命周期 + 接收后执行流程
- 新增 **OctoVideo Bot ID 完整映射表**：8 个 SOP 角色代号 ↔ ai-directory bot_id 对照
- 天坑分析从三层扩展为**四层**：
  - 第零层（新增）：Agent system_prompt 级——教会 Bot 在一次调用中完成 确认+执行+汇报
  - 第一层：botSendToGroup 中 @Bot → 触发 OpenClaw（~30行代码）
  - 第二层：TaskExecutionLoop 兜底（检测承诺但未完成→自动追发）
  - 第三层：Agent Loop + task_box（长期自驱动）
- **关键发现**：TokVideo 完整工作流涉及 ~30+ 次 Bot→Bot @mention 触发，任何一环断裂=整条生产线停摆
- 新增 6 个完整代码场景 + API 速查卡 + 任务卡模板

### 2026-04-04 — 单聊群聊操作手册 v1.0（首版天坑分析）

- 新建 `octowork实现单聊群聊功能操作手册.md`（面向 AI 员工的完整操作指南）
- 内容包括：身份查找（bot_id/department/team）、单聊 API、群聊 API、@mention 规则
- **天坑深度分析**：发现 `botSendToGroup` 中 @Bot 只发 WS 通知不触发 OpenClaw 的致命缺陷
  - 根因：`botSendToGroup` L564-682 遍历 mentions 只做 `wsManager.broadcast`，不调用 `openclawClient.sendMessage`
  - 对比：`sendGroupMessage` L314-383 会为每个被 @的 Bot 调用 OpenClaw
  - 影响：Bot @Bot 分配任务后，被@的 Bot 永远不会被唤醒执行
- **更深层问题**：即使修复触发，AI 的"回复≠执行"——单次 OpenClaw 调用结束后任务链中断
- **三层解决方案**：
  1. 紧急修复：`botSendToGroup` 中 @Bot → 触发 OpenClaw（~30行代码）
  2. 核心方案：TaskExecutionLoop 任务执行循环引擎（检测工作承诺→自动后续触发）
  3. 长期架构：Bot Agent Loop（利用 OpenClaw cron/heartbeat 实现自驱动）

### 2026-04-04 — Bot 主动消息文档拆分 + 群聊 Bug 修复

- 删除旧文档 `Bot主动消息工作流.md`（572行，V1.0 初稿，含大量伪代码示例）
- 新建两份基于实际代码追踪的文档：
  - `octowork实现AI智能化主动找用户的功能.md` — sendToUser 完整链路 + 六层投递保障 + 三种触发维度
  - `octowork实现AI自动群聊发布接收任务功能.md` — botSendToGroup + @mention + 任务意图检测 + TaskBoxWatcher
- 修复群聊关键 Bug：`saveGroupMessage()` 只返回 `lastID`(数字)，导致 `botSendToGroup` 和 `sendGroupMessage` 的 WS 广播发送 `undefined`。修复为返回完整消息对象 + mentions JSON 序列化

### 2026-04-04 — 数据库路径统一（清除硬编码）

- 清除 database.js、messageSummaryService.js 中 `/Users/jason/` 硬编码（6处）
- 统一所有服务的路径推导逻辑：`OCTOWORK_WORKSPACE` → `$HOME/octowork/`
- 涉及4个文件：database.js、offlineQueue.js、messageSummaryService.js、botController.js
- 更新 AI工作记忆 三层架构说明，明确数据库在 `~/octowork/data/` 而非项目内部

### 2026-04-04 — 消息对账7项问题修复

- 修复全部7项问题（2×P0 + 3×P1 + 2×P2），详见 `docs/10-核心工作流功能/bot聊天管理器消息对账功能.md`
- P0: JSON解析 Math.max→Math.min、sendToUser sessionId格式统一
- P1: WS推送3s快速重试、saveMessage显式写入is_pushed、OfflineQueue路径动态化
- P2: 对账补推乐观锁、前端60s全Bot未读轮询

### 2026-04-04 — 消息对账功能文档（新建）

- 新建 `docs/10-核心工作流功能/bot聊天管理器消息对账功能.md`
- 完整追踪 OpenClaw→Bot聊天管理器 消息链路（6层保障机制）

### 2026-04-04 — 首页栏目文档重构

- 新建 2 份速查文档: `API速查.md` (认证API+登录流程+路由+视频配置), `前端组件树.md` (四列布局+Login+Dashboard+9子组件)
- 删除 11 份旧文档: 首页模块.md、左侧固定导航条模块.md、登录注册模块.md、代码大纲.md、分析报告.md、API文档/、常见问题/、开发指南/、测试用例/、设计文档/、部署配置/ (共约 4,260 行)

### 2026-04-04 — 聊天栏目文档重构 + 记忆迁移

- 迁移 AI工作记忆.md 从 `docs/04-群聊-栏目开发/` 至 `docs/` 根目录，覆盖全栏目
- 新建聊天栏目 3 份速查文档: `API速查.md`, `数据库Schema.md`, `前端组件树.md`
- 删除旧聊天文档: `个人聊天模块.md`, `7种聊天模式开发方案.md`, `chat-modes/`, `历史资料/`
- 删除群聊目录中的旧 AI工作记忆.md (已迁移)

### 2026-04-04 — 群聊文档重构

- 删除旧子目录: `API文档/`, `设计文档/`, `开发指南/` (内容过时/角色扮演产物)
- 新建 3 份面向 AI 开发的速查文档

### 2026-04-04 — App.vue 瘦身完成 (3503→576)

- 阶段 C→P1 全部完成，消息丢失根治，章鱼学院 Vue 组件化，团队图标哈希分配

### 2026-04-05 — 群聊六项深度修复

**修改文件 (7 文件)**:
- `frontend/src/renderer/composables/useGroupChat.ts` — `getTotalUnreadGroupCount` 改为 computed ref `totalUnreadGroupCount`，网络错误降级处理
- `frontend/src/renderer/App.vue` — 导航栏绑定改用响应式 `totalUnreadGroupCount`，初始化各步骤独立 catch 避免级联失败
- `frontend/src/renderer/components/Sidebar/ContentSidebar.vue` — 新增 `resolveGroupSenderName()` 从 bots 数组解析中文昵称
- `frontend/src/renderer/composables/useWebSocket.ts` — WS 连接失败降级为 warn，不弹错误弹窗
- `frontend/src/renderer/composables/useSingleChat.ts` — 网络错误静默处理（ERR_NETWORK）
- `backend/src/controllers/groupController.js` — 新增 `_resolveBotDisplayName()`，botSendToGroup 使用中文昵称；`getGroupMentions` 增强支持 target/context/timestamps；`getGroupChatRecords`/`getGroupChatRecordContent` 部门感知路径解析

**具体修复**:
1. **群聊红标 + 导航栏红标**: `getTotalUnreadGroupCount()` 是函数不是 computed → 模板绑定不会响应式更新。改为 `totalUnreadGroupCount = computed(...)` + 兼容旧函数
2. **成员昵称统一**: 后端 `botSendToGroup` 的 senderName 从 botId 改为通讯录中文昵称；侧边栏 `resolveGroupSenderName()` 从 bots 数组查找中文名
3. **@mention 记录增强**: 后端 `getGroupMentions` 新增 `?target=user` 过滤被@用户、`?context=2` 附带上下文、返回 `time_formatted` + `mentions_display` + `context_before/after`
4. **文件树路径修复**: 群名如 "OctoTech-Team总群" → 从 ai-directory.json 反查部门ID "OctoTech-Team" → 优先查 `departments/OctoTech-Team/chat_history/`
5. **连接错误降级**: WS/API 的 ERR_NETWORK 改为 console.warn 不弹 ElMessage.error；App.vue 初始化各步独立 catch
6. **WS 广播消息字段修复**: botSendToGroup 广播的 message 对象补充 `sender_name` 字段（原来只有 `senderName`）

### 2026-04-03 — 群聊底层审计 + 6 Bug 修复 + 独立重构

- 修复 groupController.js 6 个 Bug
- 完成群聊独立重构 Batch 1-6
- 硬编码清理、Markdown/团队/WebSocket 迁移
