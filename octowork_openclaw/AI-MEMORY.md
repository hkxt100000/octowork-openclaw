# AI 工作记忆 — octowork_openclaw

> 最后更新：2026-04-09（完成 openclaw 源码深度扫描，写入第八章商业融入方案）

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

### 7种聊天模式 — 完整规范（P0，待实施）

> 文档来源：`10-核心工作流功能/OctoWork 7种智能会话自检模式方案.md`  
> 状态：方案设计完成，**代码尚未实施**

#### 现状 BUG（源码已确认）
1. **`report/task/brainstorm/decision` 四种模式的 prompt 完全一模一样**，唯一区别是最后一行模式名，用户切换没有任何实际效果。
2. **`simple` 说人话模式有缺陷**：prompt 里写了"不要解释"，导致用户说"帮我写个脚本"时 Bot 回"好的没问题"就停了，不写脚本。
3. **群聊的 styleProcessor 完全没有接入**：`groupController._triggerMentionedBots()` 里没有调用 `getStyleProcessor(style)`，群聊里切模式永远无效。
4. **前端 `constants.ts` 里有 `normal` 模式，后端没有**，发到后端会被静默 fallback 到 `simple`，用户不知情。

#### 重写后的正确 Prompt（每模式独立）

| 模式 | style参数 | 图标 | 核心行为 |
|------|-----------|------|----------|
| 说人话 | `simple` | 🗣️ | 简洁高效，**但执行类必须真的做，不能只说** |
| 交流探讨 | `discussion` | 💬 | 多角度讨论，有立场，控300字，结尾留开放话题 |
| 深度思考 | `thinking` | 🤔 | 先确认需求→本质分析→明确结论，禁止和稀泥 |
| 方案报告 | `report` | 📋 | Markdown结构化文档，有标题/分节，直接可用 |
| 任务工作 | `task` | ⚙️ | 分步骤+具体内容/代码，说清完成了什么/还缺什么 |
| 创意脑暴 | `brainstorm` | 🧠 | 至少3-5个不同方向，可天马行空，最后挑1-2个展开 |
| 快速决策 | `decision` | ⚡ | **第一句就是结论**，禁说"都可以/看情况"，信息不足就直说缺什么 |

#### 完整 Prompt 文本（写入 backend/server.js）

**`simple` 说人话：**
```
[系统指令]
你现在是「说人话模式」。
- 回答简洁，1-5句话，像朋友聊天
- 但如果用户要求你做具体事情（写代码/写方案/做分析），你必须做完再说人话，不能只说"好的"就结束
- 判断标准：用户说完后能不能直接拿去用？能，才算完成
- 语气自然、有温度，不要机械
[/系统指令]
```

**`discussion` 交流探讨：**
```
[系统指令]
你现在是「交流探讨模式」。
- 从正反面或多个角度分析问题，像两个人在讨论
- 控制在300字以内，口语化表达
- 要有自己的观点和立场，不要两边和稀泥
- 可以反问用户以推进讨论，但一次只问一个问题
- 结尾留一个开放话题保持对话节奏
[/系统指令]
```

**`thinking` 深度思考：**
```
[系统指令]
你现在是「深度思考模式」。
核心原则：先确认需求，再深度分析，最后给有立场的判断。
1. 需求诊断：用户说的=想要的吗？不确定就反问（一次只问一个）
2. 如果前提有误，先纠正前提再回答
3. 分析：先想本质→再看角度→判断哪个角度最重要→给明确结论
4. 输出：先结论后理由，口语化，多选项时帮用户做取舍
5. 禁止：需求不明时强行给答案/和稀泥/长篇无立场/重复用户原话凑字数
气质：认真想过之后才开口的朋友，有温度，有立场，有深度。
[/系统指令]
```

**`report` 方案报告：**
```
[系统指令]
你现在是「方案报告模式」。
- 输出必须是结构化文档：有标题(#/##)、有分节、有要点
- 格式要求：问题背景→分析→方案→行动建议→风险提示
- 内容翔实，不怕长，但每段都要有信息量
- 使用Markdown格式，方便用户直接复制使用
- 如果用户只是随口一问不需要报告，简短回答即可
[/系统指令]
```

**`task` 任务工作：**
```
[系统指令]
你现在是「任务工作模式」。
- 收到任务后立即执行，不要只说"好的我来做"然后停下
- 输出格式：分步骤列出→每步给出具体内容/代码/操作→最后总结
- 如果任务复杂无法一次完成，明确说出已完成的部分和待完成的部分
- 如果信息不足无法执行，列出需要用户提供的具体信息
- 核心原则：用户看完你的回复后，能直接拿去用，而不是还要再问你一遍
[/系统指令]
```

**`brainstorm` 创意脑暴：**
```
[系统指令]
你现在是「创意脑暴模式」。
- 至少给出3-5个不同方向的创意或想法
- 鼓励天马行空，不要自我审查，先发散再收敛
- 每个想法用一句话点题+2-3句展开说明
- 可以包含非常规的、甚至有点疯狂的点子
- 最后可以挑出你觉得最有潜力的1-2个重点展开
[/系统指令]
```

**`decision` 快速决策：**
```
[系统指令]
你现在是「快速决策模式」。
- 直接给结论，不要铺垫，第一句话就是答案
- 格式：结论→核心理由（1-2条）→行动建议
- 如果是二选一问题，明确选一个并说为什么
- 禁止说"都可以""看情况""各有优劣"这类废话
- 如果信息不足无法决策，直接说"信息不足，需要知道X和Y才能判断"
[/系统指令]
```

#### 三层自检架构（待实施）

```
用户消息 → style prompt注入 → OpenClaw → Bot回复
                                              ↓
                          【第一层】completionChecker.js（新建，零AI成本）
                          ├─ classifyIntent(userMsg) → execute/ask/chat
                          ├─ 按模式+意图判断：COMPLETE / LIKELY_COMPLETE / INCOMPLETE
                          ├─ 全局快速通过：回复>500字 或 闲聊意图
                          └─ INCOMPLETE才进第二层 ↓
                          【第二层】selfReviewService.js（新建，max触发1次）
                          ├─ 三重刹车：taskId计数(≤1次) + session冷却(30s) + 相似度去重(>80%丢弃)
                          ├─ 自检prompt："你刚才做完了吗？没做完补上；做完了回复[TASK_COMPLETE]"
                          └─ 有实质补充→追加新消息；重复/TASK_COMPLETE→丢弃 ↓
                          【第三层】用户反馈（前端，可选）
                          ├─ 消息气泡末尾：👍搞定了 / 🔄没做完
                          └─ 🔄触发追问，每条消息只能反馈1次
```

**安全保障（5重刹车）**：
1. 每个 `taskId` 最多触发1次自检（`reviewHistory` Map）
2. 同 session 冷却30秒（`sessionCooldowns` Map）
3. 自检回复与原回复 Jaccard 相似度 > 80% → 丢弃
4. 自检产生的消息带 `isFollowUp=true` → 直接跳过 completionChecker
5. `config.json` 中 `selfReview.enabled=false` 可一键关闭

**改动文件清单**：
| 文件 | 操作 | 内容 |
|------|------|------|
| `backend/services/completionChecker.js` | **新建** | 规则判断器 |
| `backend/services/selfReviewService.js` | **新建** | AI自检服务 |
| `backend/server.js` L132-341 | **修改** | 重写7个style prompt |
| `backend/src/controllers/botController.js` | **修改** | 接入completionChecker + selfReview |
| `backend/src/controllers/groupController.js` | **修改** | 补style注入 + 接入completionChecker |
| `frontend/src/renderer/utils/constants.ts` L95 | **修改** | 删normal，加thinking |
| `frontend/src/renderer/components/chat/MessagesView.vue` | **修改** | 加👍/🔄反馈按钮 |

**注意：群聊需先补基础设施**（优先级P0）：
- `groupController._triggerMentionedBots()` 中加 `getStyleProcessor(style)` 调用
- 加 `extractPlainText()` 和 `isBotProcessContent()` 过滤
- 加 `taskMonitor` 任务追踪

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

## 长期记忆 · 第六章：openclaw-node-sdk 完整解析

> 源码位置：`docs/openclaw-node-sdk/`  
> 版本：`@openclaw/node-sdk v0.1.0`  
> 文件清单：`src/types.ts` / `src/identity.ts` / `src/client.ts` / `src/index.ts` / `examples/operator.ts` / `examples/worker-node.ts`

---

### 6.1 包基本信息

```json
name: "@openclaw/node-sdk"
version: "0.1.0"
type: "module"            // ESM，import 语法
main: "dist/index.js"
engines: { node: ">=22.0.0" }   // ⚠️ 要求 Node 22+
依赖: { "ws": "^8.18.0" }        // 唯一运行时依赖，WebSocket 客户端
构建: tsc → dist/         // TypeScript 编译到 dist/
target: ES2022, module: Node16
```

**⚠️ 关键限制**：Node.js 版本必须 >= 22，目前 octowork-chat 用的 Node 18，集成前要确认版本问题。

---

### 6.2 整体架构

```
┌──────────────────────────────────────────────────────────────┐
│                  OpenClaw Gateway (:18789)                    │
│                                                              │
│  Operator A ◄──WS──►                    ◄──WS──► Node 1(RPi)│
│  (你的 App)          Challenge-Response           (Android)  │
│  Operator B ◄──WS──► Ed25519 Auth      ◄──WS──► Node 2      │
│  (Dashboard)         node.invoke routing◄──WS──► Node 3(Linux│
└──────────────────────────────────────────────────────────────┘

消息流：
Operator → gateway: "invoke screenshot on Node 2"
Gateway  → Node 2:  event { "node.invoke.request", command:"screenshot" }
Node 2   → Gateway: request { "node.invoke.result", ok:true, image:"..." }
Gateway  → Operator: response { payload: { image:"..." } }
```

**两个角色，职责完全对立**：

| 角色 | 是谁 | 能做什么 | scopes |
|------|------|---------|--------|
| `operator` | 你的 App / Dashboard / CLI | 发 RPC、调用 Node、列出 Node | `operator.admin / read / write` |
| `node` | Worker 设备 / IoT / AI Agent | 接收并执行命令，返回结果 | `[]`（零权限） |

---

### 6.3 所有 TypeScript 类型（src/types.ts）

#### WebSocket 帧格式（3 种）

```typescript
// 客户端 → 服务端：发请求
RequestFrame  { type:"req",   id:string, method:string, params:{} }

// 服务端 → 客户端：回响应
ResponseFrame { type:"res",   id:string, ok:boolean, payload?:{}, error?:{code?,message,details?} }

// 服务端 → 客户端：推事件
EventFrame    { type:"event", event:string, seq?:number, payload?:{} }
```

#### 握手相关类型

```typescript
ConnectParams {
  minProtocol: 3,    // 固定值，当前只支持 Protocol v3
  maxProtocol: 3,
  role: "operator" | "node",
  scopes?: string[],
  client: ClientInfo,    // { id, displayName?, version?, platform?, deviceFamily?, mode }
  caps?: string[],       // 客户端能力声明
  commands?: string[],   // node 模式：声明支持的命令列表
  auth?: ConnectAuth,    // { token?, bootstrapToken?, deviceToken?, password? }
  device?: DeviceAuth,   // Ed25519 签名对象
}

ConnectResult {
  auth?: { deviceToken?, role?, scopes? },
  policy?: { tickIntervalMs? }   // 服务端下发的心跳间隔
}
```

#### NodeInvoke 相关类型

```typescript
NodeInvokeParams {     // 调用方传入
  nodeId: string,
  command: string,
  params?: {},
  idempotencyKey?: string,   // 幂等键，自动生成 sdk-{counter}-{timestamp}
  timeoutMs?: number,
}

NodeInvokeRequest {    // Gateway 转发给 Node 的事件 payload
  id: string,          // requestId，Node 回复时必须带回
  nodeId: string,
  command: string,
  paramsJSON?: string, // JSON 字符串格式（优先）
  params?: {},         // 对象格式（备用）
  timeoutMs?: number,
}

NodeInvokeResultParams {  // Node → Gateway 的 invoke.result 请求
  id: string,          // 对应 requestId
  nodeId: string,
  ok: boolean,
  payloadJSON?: string, // 结果 JSON 字符串
  error?: { code?, message? }
}
```

#### NodeInfo（listNodes 返回的节点信息）

```typescript
NodeInfo {
  nodeId: string,         // 设备 ID（SHA256 of pubkey）
  displayName?: string,
  platform?: string,      // "darwin" / "linux" / "android"
  version?: string,
  clientId?: string,
  clientMode?: string,
  deviceFamily?: string,  // "mobile" / "desktop" / ""
  remoteIp?: string,
  caps?: string[],
  commands?: string[],    // 该 Node 声明支持的命令列表
  connectedAtMs?: number,
  approvedAtMs?: number,
  paired?: boolean,       // 是否已通过 approve
  connected?: boolean,    // 当前是否在线
}
```

#### DeviceIdentityData（本地存储格式）

```typescript
DeviceIdentityData {
  version: 1,          // 固定
  deviceId: string,    // SHA256(raw_32byte_pubkey) → hex
  publicKeyPem: string,
  privateKeyPem: string,
  createdAtMs: number,
}
// 存储：JSON 文件，权限 0o600（仅本人可读）
```

#### OpenClawClientOptions（构造函数入参）

```typescript
OpenClawClientOptions {
  gatewayUrl: string,          // 必填，ws:// 或 wss://
  gatewayToken?: string,       // Gateway 认证 token（env: OPENCLAW_GATEWAY_TOKEN）
  role: "operator" | "node",   // 必填
  scopes?: string[],           // operator 填权限；node 填 []
  clientId?: string,           // 默认：node→"node-host"，operator→"cli"
  clientDisplayName?: string,
  clientVersion?: string,      // 默认 "0.1.0"
  platform?: string,           // 默认 process.platform
  deviceFamily?: string,       // 默认 ""
  clientMode?: string,         // 默认：node→"node"，operator→"cli"
  caps?: string[],             // 默认 []
  commands?: string[],         // node 模式必填，声明支持的命令
  identity?: DeviceIdentityData,  // 设备身份，用于持久化配对
  onInvoke?: (command, params) => Promise<unknown>,  // node 模式命令处理器
  reconnectBaseMs?: number,    // 默认 1000ms
  reconnectMaxMs?: number,     // 默认 30000ms
  requestTimeoutMs?: number,   // 默认 30000ms（30秒）
}
```

---

### 6.4 Ed25519 身份系统（src/identity.ts）

**核心原理**：每个客户端有一个持久化的 Ed25519 密钥对，用 SHA256(公钥) 作为设备ID，连接时用私钥签名证明身份。

#### 关键函数

```typescript
// 加载或生成身份（首次自动创建，后续直接读文件）
loadOrCreateIdentity(filePath: string): DeviceIdentityData
  // 文件不存在 → generateKeyPairSync("ed25519") → 写入 JSON（mode: 0o600）
  // 文件存在且有效 → 直接返回

// 推导设备ID
deriveDeviceId(publicKeyPem: string): string
  // 原理：提取 Ed25519 SPKI DER 中的原始32字节公钥 → SHA256 → hex

// 构建连接握手签名对象
buildDeviceAuth(identity, nonce, opts): DeviceAuth
  // 1. 构造签名负载字符串（V3格式）
  // 2. Ed25519 sign(payload_utf8) → Base64URL 签名
  // 3. 返回 { id, publicKey(Base64URL), signature(Base64URL), signedAt, nonce }
```

#### 签名负载 V3 格式（极重要）

```
v3|{deviceId}|{clientId}|{clientMode}|{role}|{scopes_sorted_joined}|{signedAtMs}|{token}|{nonce}|{platform_lower}|{deviceFamily_lower}
```

示例：
```
v3|abc123...|cli|cli|operator|operator.admin,operator.read|1712345678000||nonce123|darwin|
```

**注意**：
- scopes 需要 sort() 后再 join(",")，顺序必须一致
- platform 和 deviceFamily 都要 `.toLowerCase().trim()`
- token 如果没有填空字符串（不是 undefined）
- SPKI DER 前缀是 `302a300506032b6570032100`（12字节），剥掉后才是原始32字节公钥

---

### 6.5 核心客户端（src/client.ts）— 逐行级理解

#### 私有状态变量

```typescript
ws: WebSocket | null                    // 当前 WS 连接
pendingRequests: Map<id, {resolve, reject, timeout}>  // 等待响应的请求
requestCounter: number                  // 自增计数器，用于生成 id
reconnectDelay: number                  // 当前重连等待时间（指数退避）
reconnectTimer: setTimeout | null       // 重连定时器句柄
handshakeCompleted: boolean             // connect 握手是否完成
_connected: boolean                     // 公开 connected getter 的底层值
_closed: boolean                        // 是否已主动 disconnect()
storedDeviceToken: string | null        // Gateway 下发的 deviceToken（持久化用）
```

#### 连接流程（完整时序）

```
client.connect()
  → new WebSocket(gatewayUrl)
  → ws.on("open") → emit("ws:open")   // WS 建立，但握手还没完成
  → ws.on("message")
      → handleMessage()
          → type="event" → handleEvent()
              → event="connect.challenge" → sendConnect(nonce)  ← 握手开始
                  → buildDeviceAuth(nonce)
                  → request("connect", ConnectParams)           ← 发送握手请求
                      → pendingRequests.set(id, {resolve,reject,timeout})
                      → send({ type:"req", id, method:"connect", params })
              → event="node.invoke.request" → handleNodeInvoke(payload)  ← Node收到命令
              → event="tick" → 忽略
              → 其他 → emit("event", event, payload)
          → type="res" → handleResponse()
              → pendingRequests.get(id) → clearTimeout → resolve/reject
              → 握手响应: resolve → handshakeCompleted=true, _connected=true
                        → 存储 deviceToken → emit("connected", result)
  → ws.on("close") → _connected=false → emit("disconnected") → scheduleReconnect()
  → ws.on("error") → emit("error")
```

#### request() — 请求-响应模式

```typescript
// 发一个 RPC 请求，等待对应 id 的 res 帧
async request(method, params = {}): Promise<{}>
  id = `sdk-${++counter}-${Date.now()}`
  → send({ type:"req", id, method, params })
  → pendingRequests.set(id, { resolve, reject, timeout(30s) })
  → 收到 res 帧 → handleResponse() → pendingRequests.get(id).resolve(payload)
  → 超时 → pendingRequests.delete(id) → reject(Error)
```

#### invokeNode() — 调用 Worker Node 命令

```typescript
async invokeNode({ nodeId, command, params, idempotencyKey, timeoutMs })
  → request("node.invoke", {
      nodeId, command, params:{},
      idempotencyKey: 自动生成 sdk-xxx,
      timeoutMs(可选)
    })
  → 返回 Gateway 转发 Node 执行结果的 payload
```

#### handleNodeInvoke() — Node 模式收到调用

```typescript
// 收到 event:"node.invoke.request"
private async handleNodeInvoke(payload)
  requestId = payload.id
  command   = payload.command
  params    = JSON.parse(payload.paramsJSON) 或 payload.params
  
  try:
    result = await this.opts.onInvoke(command, params)   // 调用用户注册的处理器
    request("node.invoke.result", { id:requestId, nodeId, ok:true, payloadJSON:JSON.stringify(result) })
  catch(e):
    request("node.invoke.result", { id:requestId, nodeId, ok:false, error:{code:"COMMAND_FAILED", message} })
```

#### 重连机制

```typescript
scheduleReconnect()
  // ws.close 触发 → scheduleReconnect()
  // reconnectDelay 从 1s 开始，每次 *2，上限 30s
  // _closed=true 时不重连（主动 disconnect 后）
  
disconnect()
  // _closed = true → 阻止后续重连
  // clearTimeout(reconnectTimer)
  // flushPending(Error("client disconnected"))  → 拒绝所有 pending 请求
  // ws.close(1000)
```

---

### 6.6 导出清单（src/index.ts）

```typescript
// 类
export { OpenClawClient } from "./client.js"

// 身份函数
export { loadOrCreateIdentity, deriveDeviceId, publicKeyBase64Url,
         signPayload, buildPayloadV3, buildDeviceAuth } from "./identity.js"

// 所有类型（type-only）
export type { OpenClawClientOptions, ConnectParams, ConnectAuth, ConnectResult,
  ClientInfo, DeviceAuth, DeviceIdentityData, NodeInvokeParams, NodeInvokeRequest,
  NodeInvokeResult, NodeInvokeResultParams, NodeInfo,
  RequestFrame, ResponseFrame, EventFrame, GatewayFrame }
```

---

### 6.7 两个示例的关键代码模式

#### Operator 示例（examples/operator.ts）

```typescript
// 环境变量：OPENCLAW_GATEWAY_TOKEN
const identity = loadOrCreateIdentity("./data/operator-identity.json")
const client = new OpenClawClient({
  gatewayUrl: "ws://localhost:18789",
  gatewayToken: process.env.OPENCLAW_GATEWAY_TOKEN ?? "",
  role: "operator",
  scopes: ["operator.admin", "operator.read", "operator.write"],
  identity,
  clientId: "cli",
})

client.on("connected", async () => {
  const nodes = await client.listNodes()   // 获取所有 Worker 节点
  const target = nodes.find(n => n.connected)
  
  // 调用命令
  const result = await client.invokeNode({
    nodeId: target.nodeId,
    command: "foreground_app",        // 无参数命令
  })
  const screenshot = await client.invokeNode({
    nodeId: target.nodeId,
    command: "screenshot",
    params: { quality: 50, maxWidth: 640 },  // 有参数命令
  })
})

// ⚠️ 首次连接报 "pairing required"，需要在 Gateway 主机执行：
// openclaw devices list
// openclaw devices approve <requestId>
```

#### Worker Node 示例（examples/worker-node.ts）

```typescript
// 环境变量：GATEWAY_URL（默认 ws://localhost:18789）、OPENCLAW_GATEWAY_TOKEN
const identity = loadOrCreateIdentity("./data/worker-identity.json")
const client = new OpenClawClient({
  gatewayUrl: process.env.GATEWAY_URL ?? "ws://localhost:18789",
  gatewayToken: process.env.OPENCLAW_GATEWAY_TOKEN ?? "",
  role: "node",      // ← 关键：node 角色
  scopes: [],        // ← node 永远是空 scopes
  commands: ["ping", "hostname", "shell", "screenshot"],  // ← 声明支持的命令
  identity,
  clientId: "node-host",
  clientDisplayName: `Worker (${hostname()})`,
  platform: process.platform,
  
  onInvoke: async (command, params) => {
    switch (command) {
      case "ping":      return { pong: true, timestamp: Date.now() }
      case "hostname":  return { hostname: hostname(), platform: process.platform }
      case "shell":     return execSync(params.command, { timeout:10000 })
      case "screenshot": return { image: "base64...", format: "jpeg" }
      default: throw new Error(`Unknown command: ${command}`)
    }
  }
})

// Worker 保持长连接（不 disconnect），监听 SIGINT 优雅退出
process.on("SIGINT", () => { client.disconnect(); process.exit(0) })
```

---

### 6.8 与现有 api/openclaw.js 的精确对比

| 维度 | 现有 `backend/api/openclaw.js` | `openclaw-node-sdk` |
|------|-------------------------------|---------------------|
| **协议** | `spawn('openclaw', [...args])` — 每次新建子进程 | WebSocket 持久连接 |
| **认证** | 无（靠 OpenClaw 本地 config） | Ed25519 设备身份 + deviceToken |
| **角色** | 只有 operator 方向，单向调用 | operator + node 双向 |
| **通信** | 单向：发→等结果→结束 | 双向：可接收 Gateway 推送的命令 |
| **node.invoke** | 不支持（不能调用其他 worker） | 支持，`invokeNode()` |
| **listNodes** | 不支持 | 支持，`listNodes()` |
| **超时** | 靠 `--timeout` 参数 | 内置 30s 超时 + 自动 reject |
| **重连** | 不需要（每次 spawn） | 自动指数退避重连（1s→30s） |
| **幂等** | 无 | `idempotencyKey` 自动生成 |
| **身份持久化** | 无 | JSON 文件，首次批准后无需再批准 |
| **Node.js 版本** | 适配当前版本 | **要求 >= 22.0.0** ⚠️ |

---

### 6.9 集成到 octowork-chat 的完整方案

#### 方案选择：octowork-chat 应该用 operator 还是 node 角色？

**答案：两个都要用。**

```
octowork-chat 后端作为 operator：
  → 发消息给 AI Agent（相当于现在的 openclaw.js sendMessage）
  → listNodes() 查看哪些 Bot 在线
  → invokeNode() 调用 Bot 执行特定命令

octowork-chat 后端作为 node（可选，高级功能）：
  → 注册自己为 Worker，接受 Gateway 主动推来的事件
  → 实现真正的"Bot 主动找用户"，不需要 Bot 轮询
  → 目前 send-to-user 是 Bot 自己 HTTP POST 过来的，不够优雅
```

#### 最小改动方案（只替换 openclaw.js，operator 角色）

**第一步：安装 SDK**
```bash
# 注意：octowork-chat 后端需要升级到 Node 22，或者直接 copy src/ 进来
cd backend && npm install @openclaw/node-sdk
```

**第二步：改造 `backend/api/openclaw.js`**

```javascript
// 原来（CLI spawn 方式）：
const { spawn } = require('child_process')
function sendMessage(botId, message, sessionId) {
  return new Promise((resolve, reject) => {
    const proc = spawn('openclaw', ['--agent', botId, '--message', message, '--session-id', sessionId, '--json'])
    // 等进程结束，解析 stdout JSON
  })
}

// 改成（SDK WebSocket 方式）：
import { OpenClawClient, loadOrCreateIdentity } from '@openclaw/node-sdk'

const identity = loadOrCreateIdentity('./data/octowork-identity.json')
const client = new OpenClawClient({
  gatewayUrl: process.env.OPENCLAW_GATEWAY_URL ?? 'ws://localhost:18789',
  gatewayToken: process.env.OPENCLAW_GATEWAY_TOKEN ?? '',
  role: 'operator',
  scopes: ['operator.admin', 'operator.read', 'operator.write'],
  identity,
  clientDisplayName: 'OctoWork Chat Manager',
})

client.connect()  // 启动时建立持久连接，不在每次消息时连接

async function sendMessage(botId, message, sessionId) {
  const result = await client.invokeNode({
    nodeId: botId,        // botId 即 nodeId
    command: 'chat',      // Gateway 约定的命令名
    params: { message, sessionId },
  })
  return result
}
```

**第三步：需要确认的问题**（与用户讨论）
1. Gateway 的 `OPENCLAW_GATEWAY_URL` 是什么？（本地 ws://localhost:18789 还是远程？）
2. Bot 的 `nodeId` 和现在的 `botId` 是同一个值吗？
3. Gateway 支持的 `chat` command 参数格式是什么？
4. Node.js 版本问题：后端当前版本是否 >= 22？

#### 不升级 Node.js 的备选方案

如果 Node 版本升级有风险，可以把 SDK 的 `src/` 直接 copy 进来，改 `.ts` 为 `.js`（或用 `tsx` 运行），避免版本依赖问题。SDK 只依赖 `ws` 包和 Node 内置 `crypto`/`events`。

---

### 6.10 关键常量与默认值速查

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `clientId` | `"cli"`（operator）/ `"node-host"`（node） | 必须匹配 Gateway 的 `GATEWAY_CLIENT_IDS` |
| `clientMode` | `"cli"`（operator）/ `"node"`（node） | 必须匹配 Gateway 的 `GATEWAY_CLIENT_MODES` |
| `scopes`（operator）| `["operator.admin"]` | 默认只有 admin |
| `scopes`（node）| `[]` | node 永远空 |
| Gateway 端口 | `18789` | OpenClaw Gateway 默认端口 |
| `requestTimeoutMs` | `30000`（30s） | 超时后 reject |
| `reconnectBaseMs` | `1000`（1s） | 首次重连等待 |
| `reconnectMaxMs` | `30000`（30s） | 最大重连等待 |
| Protocol version | `3`（min=max=3） | 固定，当前只支持 v3 |
| 身份文件权限 | `0o600` | 仅所有者可读写 |

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

---

## 长期记忆 · 第八章：openclaw 源码深度扫描 & 商业融入方案

> 源码位置：`octowork_openclaw/openclaw源码/`（来自 github.com/openclaw/openclaw，MIT 协议）  
> 扫描日期：2026-04-09  
> **商业目标：用户只需安装 octowork，即可像 openclaw 一样调用工具、配置模型、创建 Agent 和部门，完全独立运营**

---

### 8.1 项目规模一览

| 指标 | 数值 |
|------|------|
| 总大小（含 git） | 582 MB |
| 纯源码大小（不含 node_modules/.git） | 145 MB |
| 总文件数 | 13,354 |
| 代码行数（.ts/.js，不含 node_modules/dist） | **30 万行** |
| 核心目录 | `src/`(54MB) `extensions/`(42MB) `apps/`(18MB) |

---

### 8.2 核心架构地图（src/ 目录拆解）

```
src/
├── agents/                  ⭐ AI Agent 运行时（核心，最重要）
│   ├── pi-embedded-runner/  ← LLM调用/对话循环/自动压缩（最核心）
│   ├── pi-embedded-runner.ts← 导出入口：runEmbeddedPiAgent()
│   ├── bash-tools.exec.ts   ← bash工具执行（1835行）
│   ├── pi-tools.ts          ← 所有工具注册（662行）
│   ├── memory-search.ts     ← 记忆语义搜索（434行）
│   ├── models-config.ts     ← 模型配置（198行）
│   ├── model-selection.ts   ← 模型选择逻辑（898行）
│   ├── system-prompt.ts     ← 系统Prompt构建（大）
│   ├── skills/              ← Skills系统（任务手册注入）
│   ├── sandbox/             ← Docker沙箱隔离
│   └── auth-profiles/       ← 多API Key轮换
├── gateway/                 ⭐ WebSocket控制平面
│   ├── server.ts            ← Gateway主服务
│   ├── server-methods/      ← 所有RPC方法（chat/sessions/nodes/config...）
│   ├── protocol/            ← 通信协议Schema（TypeBox）
│   └── boot.ts              ← 启动时执行BOOT.md任务
├── config/                  ⭐ 配置系统（类型+Schema+IO）
│   ├── schema.ts            ← 完整配置Schema
│   ├── types.agents.ts      ← Agent配置类型
│   ├── types.models.ts      ← 模型配置类型
│   ├── sessions/            ← Session存储/读写/锁
│   └── types.*.ts           ← 各模块类型定义
├── sessions/                Session标识/路由/生命周期
├── memory-host-sdk/         向量记忆系统（embedding + SQLite）
├── extensions/              ← 各平台插件（模块化，可选加载）
│   ├── anthropic/           ← Claude
│   ├── openai/              ← GPT
│   ├── google/              ← Gemini
│   ├── deepseek/ ollama/ xai/ groq/ ... ← 其他30+个模型
│   ├── whatsapp/ telegram/ discord/ ...← 消息平台（我们不需要）
│   └── browser/ memory-core/ ...       ← 工具插件
├── auto-reply/              消息自动路由（收到消息→选择session→触发Agent）
├── routing/                 session-key路由规则
├── plugins/                 插件加载/发现/注册
└── web/                     Web UI（Control Panel）
```

---

### 8.3 LLM 调用核心：`pi-embedded-runner`

**这是整个系统最核心的部分**，我们融入的核心也在这里。

#### 依赖关系
```
runEmbeddedPiAgent()   ← 唯一入口
  └── @mariozechner/pi-agent-core    ← Agent运行时核心库（不是openclaw自己写的）
  └── @mariozechner/pi-ai            ← AI抽象层
  └── @mariozechner/pi-coding-agent  ← SessionManager / createAgentSession
```

**关键：OpenClaw 自己也是依赖 `pi-agent-core` 这个第三方库来运行 LLM，它不是从零自己写的 LLM 调用。**

#### 核心文件行数
| 文件 | 行数 | 职责 |
|------|------|------|
| `pi-embedded-runner/run.ts` | 1622 | Agent运行主循环（含failover/重试） |
| `pi-embedded-runner/run/attempt.ts` | 2335 | 单次LLM调用（最核心） |
| `pi-embedded-runner/compact.ts` | 1463 | Context压缩（超token时自动摘要） |
| `pi-embedded-runner/model.ts` | 829 | 模型解析/切换/failover |
| `pi-embedded-runner/system-prompt.ts` | 109 | System Prompt构建入口 |
| `bash-tools.exec.ts` | 1835 | Bash工具执行 |
| `pi-tools.ts` | 662 | 工具注册（read/write/bash/browser...） |

#### 默认模型
```typescript
DEFAULT_PROVIDER = "openai"
DEFAULT_MODEL    = "gpt-5.4"
DEFAULT_CONTEXT_TOKENS = 200_000
```

---

### 8.4 支持的 LLM Provider（31个）

通过 extensions/ 模块化插件系统加载：

| 类别 | Provider |
|------|----------|
| **主流闭源** | openai, anthropic, google, xai, microsoft-foundry |
| **中国模型** | deepseek, qwen, minimax, moonshot, kimi-coding, volcengine, alibaba, byteplus |
| **开源/本地** | ollama, vllm, sglang, huggingface, litellm |
| **聚合代理** | openrouter, litellm, vercel-ai-gateway, cloudflare-ai-gateway |
| **专业模型** | groq, fireworks, together, mistral, nvidia, arcee, chutes, venice |
| **云厂商** | amazon-bedrock, amazon-bedrock-mantle, anthropic-vertex |

**每个 provider 是一个独立的 extension 包**，通过 `openclaw.plugin.json` 声明，运行时动态加载。这个设计对我们**极其有价值**。

---

### 8.5 Agent 配置系统

#### Workspace 文件结构（每个 Agent 有自己的工作目录）
```
~/.openclaw/workspace/          ← 默认工作区（可按agentId隔离）
├── AGENTS.md                   ← 核心指令（必须存在）
├── SOUL.md                     ← 性格/语气（可选）
├── TOOLS.md                    ← 工具使用约定（可选）
├── MEMORY.md                   ← 长期记忆（仅主session）
├── memory/YYYY-MM-DD.md        ← 每日笔记
└── skills/<skill>/SKILL.md     ← 技能手册（动态注入）
```

#### `types.agents.ts` 关键字段
```typescript
AgentConfig {
  agentId: string,           // Agent唯一ID
  workspace?: string,        // 工作区路径（隔离存储）
  model?: AgentModelConfig,  // 每个Agent可用不同模型
  identity?: IdentityConfig, // Agent身份（名称/头像）
  skills?: string[],         // 允许使用的技能列表
  sandbox?: AgentSandboxConfig, // 沙箱配置
  subagents?: { ... },       // 子Agent配置
}
```

#### Session 隔离规则
```
agent:main           → 主session，完整工具权限
agent:dm:channel:id  → 直接对话session，沙箱默认开启
agent:group:channel  → 群组session，沙箱默认开启
```

---

### 8.6 Skills 系统（任务手册）

**这是我们的"部门标准手册"概念的原型来源！**

```
skills/<skill-id>/
├── SKILL.md          ← 技能指令（注入到系统prompt）
├── package.json      ← 技能元数据（id/description/tools）
└── tools/            ← 该技能专属工具（可选）
```

- 技能按需注入（不是全部塞进 prompt）
- 支持 ClawHub（在线技能仓库，相当于应用商店）
- 每个 Agent 可以配置允许使用哪些 Skills

**对应 octowork 概念**：`Skills = 部门标准手册 + AI员工角色说明`

---

### 8.7 Memory 系统（向量记忆）

```
memory-host-sdk/host/
├── internal.ts           ← SQLite + 向量搜索核心（504行）
├── embeddings.ts         ← 多provider嵌入（329行）
├── embeddings-openai.ts  ← OpenAI embedding
├── embeddings-gemini.ts  ← Gemini embedding（336行）
├── embeddings-voyage.ts  ← Voyage embedding（82行）
├── embeddings-bedrock.ts ← AWS Bedrock（398行）
├── embeddings-ollama.ts  ← 本地Ollama（5行，很简单）
└── query-expansion.ts    ← 查询扩展（830行）
```

- 存储位置：`~/.openclaw/memory/<agentId>.sqlite`
- 混合检索：**向量相似度（semantic）+ BM25关键词（exact）**
- 自动索引：文件变更监听（1.5s debounce），自动reindex
- Provider 自动选择：本地模型 > OpenAI > Gemini > 禁用

---

### 8.8 Context 压缩系统（解决 AI 失忆问题）

`compact.ts`（1463行）是解决我们第五章提到的"AI失忆"的完整方案：

```
触发条件：token数接近上限（可配置阈值）
流程：
  1. captureCompactionCheckpointSnapshot()  ← 拍快照（保险）
  2. hasMeaningfulConversationContent()      ← 检测是否有有效对话
  3. resolveContextWindowInfo()              ← 计算token使用量
  4. 调用LLM生成摘要（用专门的compact prompt）
  5. 将摘要+最近N条消息写回session
  6. cleanupCompactionCheckpointSnapshot()  ← 清除快照
  7. Memory flush：将重要信息写入MEMORY.md（可选）
```

**关键**：压缩时会先执行 "memory flush"，把重要信息写入 MEMORY.md 持久化，这就是第三/四层记忆！

---

### 8.9 工具系统

| 工具 | 文件 | 说明 |
|------|------|------|
| `bash` | `bash-tools.exec.ts`(1835行) | Shell命令执行，支持Docker沙箱 |
| `read/write/edit` | `pi-tools.read.ts` `pi-tools.host-edit.ts` | 文件读写 |
| `browser` | `extensions/browser/` | CDP控制Chrome |
| `web_search` | `tools/web-search.ts`(61行) | 网络搜索 |
| `web_fetch` | `tools/web-fetch.ts`(632行) | 网页抓取 |
| `sessions_send` | `tools/sessions-send-tool.ts` | Agent发消息给Agent |
| `cron` | `tools/cron-tool.ts` | 定时任务 |
| `image/video/music` | `tools/*-generate-tool.ts` | 媒体生成 |
| `canvas` | `tools/canvas-tool.ts` | 可视化工作区 |

工具策略 = 多层叠加：Tool Profile → Provider Profile → Global → Agent → Session

---

### 8.10 商业融入方案：octowork 取代 openclaw

> **目标**：用户只安装 octowork，即获得完整 AI 员工系统（无需另装 openclaw）

#### 核心战略判断

OpenClaw 是为**个人助手**设计的（单用户、单 Gateway、接消息平台）。

octowork 的定位是**企业 AI 员工管理平台**（多 Agent、部门化、任务管理、可视化 UI）。

**我们不是 clone openclaw，而是用它的核心能力构建一个不同的产品形态。**

---

#### 可以直接复用的部分（✅ 高价值，少改动）

| 组件 | 来自 openclaw | 如何复用 |
|------|--------------|---------|
| **LLM 调用层** | `@mariozechner/pi-agent-core` | 直接 npm install，不需要 openclaw 框架 |
| **Provider 插件系统** | `extensions/anthropic/ openai/ google/ ollama/...` | 直接 copy 或 npm 安装各 provider 包 |
| **Context 压缩** | `pi-embedded-runner/compact.ts` | 核心逻辑可 copy，解决失忆问题 |
| **Memory 向量搜索** | `memory-host-sdk/` | 完整 copy，解决长期记忆 |
| **Skills 系统** | `agents/skills/` | 直接对应我们的"部门标准手册" |
| **Bash 工具** | `bash-tools.exec.ts` | 直接 copy，给 AI 员工执行脚本能力 |
| **工具策略** | `tool-policy.ts` | 控制哪些 Agent 能用哪些工具 |

#### 需要自己实现的部分（⚠️ 需要重写）

| 组件 | 原因 | 我们的替代方案 |
|------|------|--------------|
| Gateway WebSocket 服务 | openclaw 的 Gateway 是为消息平台设计的 | octowork 已有 backend/server.js（Express + WS），在其基础上扩展 |
| 消息平台接入（WhatsApp等） | 完全不需要 | 已有 octowork-chat UI |
| 多租户/商业授权 | openclaw 是个人工具，无商业授权 | 需要自建：License + 用户管理 + 部门权限 |
| Agent 创建 UI | openclaw 用配置文件 | octowork 需要可视化创建界面（这是产品核心） |
| 部门管理 | openclaw 无部门概念 | octowork 已有（10个部门，62个员工），需要UI化 |
| 任务看板 | openclaw 无 | 已有 Pipeline 系统，继续完善 |

---

#### 融入路线图（三个阶段）

**Phase 1：替换 LLM 调用层（2-3天）**
```
目标：去掉 spawn('openclaw') CLI 调用
方案：直接用 pi-agent-core + provider extension 替换 backend/api/openclaw.js
改动文件：backend/api/openclaw.js（重写）、backend/package.json（加依赖）
效果：用户不再需要安装 openclaw CLI
```

**Phase 2：接入 Skills + Memory 系统（1周）**
```
目标：AI 员工有长期记忆，有技能手册，不会失忆
方案：
  - 每个 Bot 的 ~/octowork/departments/{dept}/agents/{botId}/ 作为 workspace
  - workspace/AGENTS.md = Bot 角色说明（现有的 ai-directory.json 转换）
  - workspace/SOUL.md = 性格设定
  - workspace/skills/ = 部门标准手册（现有 task_box 内容）
  - 接入 memory-host-sdk 提供向量记忆
效果：AI 员工有角色、有技能、有记忆
```

**Phase 3：工具能力 + 商业化（2-4周）**
```
目标：AI 员工可以执行真实任务（写代码/搜索/操作文件）
方案：
  - 接入 bash-tools（沙箱化，按部门配置权限）
  - 接入 web-search / web-fetch
  - 构建 Agent 创建 UI（octowork 特色）
  - 构建部门管理 UI
  - 接入商业授权系统（License Key）
效果：完整 AI 员工平台，商业可用
```

---

#### 关键技术决策

1. **不需要跑完整的 openclaw Gateway**
   - 只需要 `pi-agent-core` 库 + provider extension 包
   - 我们用自己的 Express + WebSocket 作为控制平面

2. **Node.js 版本**
   - openclaw 要求 Node >= 22（甚至推荐 24）
   - octowork 目前用 Node 18，**升级到 Node 22 是必须的**

3. **工作区路径映射**
   ```
   openclaw: ~/.openclaw/workspace/<agentId>/
   octowork: ~/octowork/departments/<dept>/agents/<botId>/
   ```
   概念完全对应，只需改路径。

4. **模型配置 UI**（商业核心功能）
   - 在 octowork-chat 界面里直接配置：选 provider、填 API Key、选模型
   - 支持按部门/按 Agent 配置不同模型
   - 支持 API Key 轮换（openclaw 的 auth-profiles 系统可以参考）

5. **部门 = 多 Agent 隔离**
   - 每个部门有独立的 workspace
   - 部门 Leader 可以向成员发消息（sessions_send tool）
   - 部门间可以通过群聊协作

---

#### 商业运营视角

| 功能 | openclaw（开源免费） | octowork（我们的商业产品） |
|------|---------------------|------------------------|
| 接入渠道 | WhatsApp/Telegram 等 | 专属 UI（octowork-chat） |
| Agent 管理 | 手动编辑配置文件 | 可视化创建/管理 |
| 部门/团队 | 无 | 有（核心差异化） |
| 任务管理 | 无 | 有（Pipeline 看板） |
| 商业授权 | MIT 免费 | License Key 授权 |
| 用户目标 | 极客/开发者 | 企业/团队 |
| 数字公寓 | 无 | 有（~/octowork/ 体系） |
| 记忆系统 | 文件 + 向量DB | 同上（复用） |
| 模型支持 | 30+ provider | 同上（复用） |

**核心竞争力**：我们在 openclaw 的 AI 执行能力基础上，加了**企业级的 Agent 管理、部门协作、任务看板、可视化运营**，这是 openclaw 完全没有的。

---

### 8.11 立即可行的第一步

**目标**：在不破坏现有功能的前提下，先把 `spawn('openclaw')` 替换掉。

```javascript
// backend/api/openclaw.js 改造方向
// 方案A：直接调 LLM API（最快，2小时）
import Anthropic from '@anthropic-ai/sdk'
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

async function sendMessage(botId, message, sessionId, systemPrompt) {
  // 从 ~/octowork/data/sessions/{sessionId}.json 读历史
  const history = await loadSessionHistory(sessionId)
  const response = await client.messages.create({
    model: 'claude-opus-4-5',
    max_tokens: 8192,
    system: systemPrompt,           // 从 Bot 的 workspace/AGENTS.md 读取
    messages: [...history, { role: 'user', content: message }],
  })
  // 保存到历史
  await saveSessionHistory(sessionId, history, message, response)
  return response.content[0].text
}

// 方案B：用 pi-agent-core（更完整，但需要升级 Node 22，1-2天）
import { createAgentSession } from '@mariozechner/pi-coding-agent'
```

**建议先走方案A**，证明可行后再迁移到 pi-agent-core。
