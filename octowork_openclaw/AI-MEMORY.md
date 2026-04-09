# AI 工作记忆 — octowork_openclaw

> 最后更新：2026-04-09

---

## 核心目标

**将 openclaw 的功能直接融合进 octowork-chat，最终只保留一个产品：octowork-chat。**

openclaw 不作为独立产品存在，它的能力成为 octowork-chat 的一部分。

---

## 阅读进度

- [x] 01-项目概要（9个文件）✅
- [ ] 02-首页-栏目开发
- [ ] 03-聊天-栏目开发
- [ ] 04-群聊-栏目开发
- [ ] 05-任务看板-栏目开发
- [ ] 10-核心工作流功能
- [ ] 11-数字公寓配置管理 + 14-设计规范标准
- [ ] 15-用户版升级手册
- [ ] openclaw-node-sdk 源码

---

## 长期记忆 · 第一章：octowork-chat 系统全景

### 产品定位
- **名称**：OctoWork 聊天管理器（开发代号 `bot-chat-manager` / `octowork-chat-dev`）
- **本质**：OpenClaw 用户的可视化管理驾驶舱，让用户管理自己的 AI 员工团队
- **服务对象**：OpenClaw 用户 → 通过 octowork-chat 管理"数字公寓"

### 技术栈
| 端 | 技术 | 端口 |
|----|------|------|
| 前端 | Vue 3 + TypeScript + Vite | 5888 |
| 后端 | Node.js + Express + SQLite | 1314 |
| 实时通信 | WebSocket（与 HTTP 共享端口） | 1314 |

### 前端架构
- **核心问题**：主文件 `App.vue` 有 5870 行，正在持续拆分中
- **四列布局**：
  1. `MainLayout.vue` — 全局导航条
  2. `ContentSidebar.vue` — Bot/群组列表
  3. 主内容区 — 聊天/群聊/任务/Dashboard（动态切换）
  4. `WorkspacePanel.vue` — 文件树工作台（有 Bot 选中时出现）
- **组合式函数（composables）**：
  - `useBots.ts` — Bot 列表与状态
  - `useMessages.ts` — 消息收发（587行，较完善）
  - `useTasks.ts` — 任务状态
  - `useFiles.ts` — 文件操作
- **服务层**：`websocket.ts`、`auth.ts`、`notificationService.js`

### 后端架构
- **核心文件**：`backend/server.js`（所有路由入口，约 3000 行）
- **关键模块**：
  - `api/openclaw.js` — **OpenClaw 网关 API 调用**（这是连接 openclaw 的关键桥接）
  - `services/message-reconciliation-enhanced.js` — 消息保底机制
  - `services/messageSummaryService.js` — 消息总结
  - `db/database.js` — SQLite，含 messages/bots/groups/tasks 表
  - `websocket/manager.js` — 实时消息推送

### 功能模块清单
| 模块 | 状态 | 备注 |
|------|------|------|
| 聊天（1对1） | ✅ 核心完成 | 支持 7 种聊天模式 |
| 群聊 | 🔄 部分完成 | 文件树 API 完成，消息收发待实现 |
| 任务看板 | ✅ 前端较完善 | 后端 API 待补全 |
| Dashboard | ✅ 较完善 | Bot 状态、实时日志、语音播报 |
| 登录 | ✅ 基础完成 | 权限系统待完善 |
| AI员工市场 | 📝 框架规划中 | 未来连接 octowork.ai |
| 章鱼学院 | 📝 框架规划中 | — |
| 技能市场 | 📝 框架规划中 | — |
| 企微 | 📝 框架规划中 | 企微 CRM 集成 |

### 7种聊天模式（重要特性）
1. 说人话模式（simple）
2. 交流探讨模式（discussion）
3. 深度思考模式（thinking）
4. 方案报告模式（report）
5. 任务工作模式（task）
6. 创意脑暴模式（brainstorm）
7. 快速决策模式（decision）

### 关键发现：openclaw 连接点
- 后端已有 `backend/api/openclaw.js`，负责调用 OpenClaw 网关
- 消息发送流程：前端 → `POST /api/bots/:id/messages` → `api/openclaw.js` → OpenClaw → Bot 回复 → WebSocket 推送前端
- **融合方向**：`openclaw-node-sdk` 应替换或增强 `api/openclaw.js` 的能力

### 群聊目录体系（已部署 18 个）
已部署标准目录结构的群聊包括：技术部总群、产品设计群、技术开发群、AI智囊团等 18 个

### 任务存储格式
任务以 Markdown 文件形式存储在 `task_box/` 目录，按状态分 pending / in_progress / completed / accepted 子目录管理。

---

## 待探讨

- openclaw-node-sdk 具体提供哪些能力？（待读 SDK 源码后补充）
- `api/openclaw.js` 现在是直接 HTTP 调用还是用了 SDK？
- 融合后，身份认证（identity）如何处理？
- 前端是否需要新增页面/组件来展示 openclaw 特有功能？

---

## 备注

文档存放于 `docs/`，后续分析基于此展开。
