# 群聊 UI 重构工作清单

> **目标**：群聊模块 UI 对齐单聊模块，实现一致的四栏布局（导航栏 → Bot/群组列表 → 聊天区域 → 文件树），并完善消息通知红标、未读计数等交互逻辑。
>
> **更新日期**：2026-04-05（Phase4 输入框重构 + Phase6 缓存/轮询 + Phase7 独立页面同步）
>
> **优先级**：P0（阻塞用户体验）

---

## 一、现状分析 — 单聊 vs 群聊 差异矩阵

| 功能维度 | 单聊（已完成） | 群聊（当前状态） | 差距 |
|---------|--------------|----------------|------|
| **整体布局** | 四栏：导航 + ContentSidebar + ChatArea + WorkspacePanel | 三栏（App.vue内）/ 独立页面（GroupChatPage.vue） | 群聊缺少侧边栏群组列表 ❌ |
| **侧边栏列表** | Bot 分组列表 + 搜索 + 头像 + 未读角标 + 最近聊天预览 | 仅 ContentSidebar 中有简易群组列表（无最近消息预览、无未读角标） | 需升级群组列表 ❌ |
| **头部 Header** | ChatHeader.vue：Bot名称 + 状态灯 + 任务按钮 + 垃圾桶 + 用户头像 | GroupChatHeader.vue：仅群名 + 成员数 + 成员列表/删除按钮 | 需统一风格 ❌ |
| **消息区域** | MessagesView.vue（658行）：Bot头像 + Markdown + 复制按钮 + TODO清单 + 加载更多 + 自动滚底 | GroupMessagesView.vue（182行）：emoji头像 + 简单消息气泡 | 功能严重缺失 ❌ |
| **输入框** | MessageInput.vue（831行）：7种聊天模式 + 图片拖拽 + 文件上传 + 跳转最新 | GroupMessageInput.vue（287行）：仅@mention + 发送 | 功能差距大 ❌ |
| **文件树** | WorkspacePanel.vue：FileTreeTab + PreviewTab | GroupWorkspacePanel.vue：群聊实时记忆文件列表 | 功能已有，布局需对齐 ⚠️ |
| **未读消息** | botUnreadCounts + 侧边栏红色角标 + 导航栏红标 | 无任何未读计数逻辑 | 完全缺失 ❌ |
| **消息轮询兜底** | 30秒轮询 + WS 推送双保险 | 仅 WS 推送 | 需增加轮询兜底 ⚠️ |
| **消息缓存** | sessionStorage 缓存 + allBotMessages 内存缓存 | 无缓存机制 | 需增加 ⚠️ |
| **Bot 头像** | 真实头像 img + getFullAvatarUrl 回退机制 | 固定 emoji（👨/🤖） | 需使用真实头像 ❌ |
| **@mention 高亮** | N/A（单聊无@mention） | highlightMentions 已实现 | 保留并增强 ✅ |
| **Markdown 渲染** | parseMarkdown + 代码高亮 + 表格 | Bot消息用parseMarkdown，用户消息用highlightMentions | 基础已有 ✅ |
| **消息分页** | loadMoreMessages + 触顶加载 | 无分页，一次加载全部 | 需增加 ❌ |

---

## 二、重构方案 — 分阶段工作清单

### Phase 1：布局统一（P0 — 核心框架）

#### 1.1 群聊融入 App.vue 四栏布局
- [ ] **取消 GroupChatPage.vue 独立页面路由**
  - 当前 `/group/:groupId` 独立路由，跳出了 App.vue 的四栏框架
  - 改为在 App.vue 内 `currentView === 'groups'` 时渲染群聊
  - 保留 GroupChatPage.vue 作为备用（可能外链分享用途）
- [ ] **App.vue 群聊区域补全侧边栏**
  - 当前 `currentView === 'groups'` 时直接渲染 `GroupChatView`，缺少群组列表侧边栏
  - 需要 ContentSidebar 在群聊 Tab 时显示增强版群组列表

> **文件影响**：`App.vue` L134-157, `router.ts`, `ContentSidebar.vue`

#### 1.2 群组列表侧边栏升级（对标单聊 Bot 列表）
- [ ] **群组卡片样式对齐 Bot 卡片**
  - 当前：`list-item` 简易样式（头像 + 群名 + 成员数）
  - 目标：`bot-card` 样式（头像 + 群名 + 最近消息预览 + 时间 + 未读角标）
- [ ] **群组头像升级**
  - 当前：使用 `getGroupAvatar()` 返回静态图片
  - 目标：保持现有头像 + 添加在线状态指示器（可选）
- [ ] **最近消息预览**
  - 在群组卡片下方显示最近一条消息的发送者+内容摘要
  - 新增 `groupLastMessages: Record<groupId, { sender, content, timestamp }>` 状态
- [ ] **未读消息角标**
  - 新增 `groupUnreadCounts: Record<groupId, number>` 状态
  - 在群组卡片头像右上角显示红色未读数
  - WS `group_message` 事件 → 如果不是当前选中群组 → unreadCount++
  - 选中群组时 → unreadCount = 0

> **文件影响**：`ContentSidebar.vue` L238-273, `useGroupChat.ts`（新增 unread 逻辑）

#### 1.3 WorkspacePanel 位置统一
- [ ] **确认 GroupWorkspacePanel 在四栏布局中的第四列位置**
  - 当前 App.vue L171-178 已实现，确认无误
  - 确保宽度、滚动行为与单聊 WorkspacePanel 一致

> **文件影响**：`App.vue` L171-178, CSS 样式

---

### Phase 2：聊天头部重构（P0 — 视觉统一）

#### 2.1 复用 ChatHeader.vue 替换 GroupChatHeader.vue
- [ ] **ChatHeader.vue 已支持 `type='group'`**
  - 当前 ChatHeader.vue L6-8 / L61-64 已有 group 类型分支
  - 目标：在 GroupChatView.vue 中改用 `ChatHeader type="group"` 替换 `GroupChatHeader`
- [ ] **头部功能对齐**
  - 左侧：群名 + 成员数 badge
  - 右侧：成员列表按钮 + 清空消息 + 用户头像下拉 + ~~删除群组~~（移到设置弹窗中）
- [ ] **删除 GroupChatHeader.vue（68行）**
  - 所有功能迁移到 ChatHeader.vue 的 group 分支
  - 减少组件碎片

> **文件影响**：`GroupChatView.vue`, `ChatHeader.vue`, 删除 `GroupChatHeader.vue`

---

### Phase 3：消息区域重构（P0 — 核心体验）

#### 3.1 GroupMessagesView 对齐 MessagesView 功能
- [x] **Bot 真实头像替换 emoji** :white_check_mark: Phase2+3 已完成
  - 使用 `getFullAvatarUrl(bot.avatar, bot.id)` + `avatar-fallback` 回退
  - `bots: Bot[]` prop 已从 App.vue -> GroupChatView -> GroupMessagesView 透传
- [x] **用户消息头像** :white_check_mark: 已对齐单聊（右对齐，不显示头像）
- [x] **消息复制按钮** :white_check_mark: 已实现（hover 显示右上角复制按钮）
- [x] **加载更多历史消息** :white_check_mark: 已实现（加载更多/已加载全部 提示）
- [x] **滚动行为优化** :white_check_mark: 已实现（isUserNearBottom + 自动滚底 + 初始加载滚底）
- [x] **@mention 高亮增强** :white_check_mark: Phase3 已完成
  - `highlightMentions` 生成 `<span class="mention" data-mention="xxx">` 蓝色可点击链接
  - CSS `.mention` 样式: 蓝色背景 + hover 下划线 + 指针光标
- [x] **消息气泡样式对齐** :white_check_mark: 已对齐单聊（相同 padding/border-radius/阴影/间距）

> **文件影响**：`GroupMessagesView.vue`（大幅重写）, `useGroupChat.ts` :white_check_mark: 已完成

#### 3.2 TODO 清单 / 工作清单展示
- [x] **群聊消息中如果包含 TODO 格式，展示工作清单面板** :white_check_mark: Phase3 已完成
  - 复用 `hasTodoList` / `parseTodoList` / `getTodoStats`
  - 包含工作清单头部、状态图标、优先级标记 + 暗色模式

---

### Phase 4：输入框重构（P1 — 功能增强）

#### 4.1 GroupMessageInput 对齐 MessageInput 核心功能
- [x] **聊天风格 Tabs** :white_check_mark: 群聊统一使用 simple 模式，不显示 Tab
- [x] **文件/图片上传** :white_check_mark: Phase4 已完成
  - 支持图片拖拽上传、粘贴上传、文件选择器
  - 图片预览卡片（文件名 + 大小 + 移除按钮）
  - 10MB 限制，仅支持图片格式
- [x] **"跳转到最新消息" 按钮** :white_check_mark: Phase4 已完成
  - 用户滚动查看历史时，输入框上方显示"最新消息"浮动按钮
  - 点击后自动滚到底部
- [x] **Shift+Enter 换行** :white_check_mark: 已在 useGroupChat 中实现
- [ ] **输入状态 "正在输入..."**（P2 可选）
  - 可选功能：当用户正在输入时，通过 WS 广播给群内其他在线用户
  - 显示 "XXX 正在输入..." 状态

> **文件影响**：`GroupMessageInput.vue`（扩展功能）

---

### Phase 5：未读消息 & 通知红标系统（P0 — 核心交互）

#### 5.1 群聊未读计数体系
- [x] **新增 `groupUnreadCounts` 状态** :white_check_mark: Phase1 已完成
- [x] **WS 群聊消息 → 未读计数 +1** :white_check_mark: Phase1 已完成
- [x] **选中群组 → 清零未读** :white_check_mark: Phase1 已完成
- [x] **切换到群聊 Tab → 当前群组清零** :white_check_mark: Phase1 已完成

#### 5.2 侧边栏群组列表红标
- [x] **群组卡片头像右上角未读角标** :white_check_mark: Phase1 已完成（99+ 上限显示）

#### 5.3 全局导航栏群聊红标
- [x] **MainLayout.vue 群聊导航项红标** :white_check_mark: Phase1 已完成
- [x] **红标数字显示规则** :white_check_mark: 0=不显示 / 1-99=数字 / 99+=上限

#### 5.4 @mention 通知增强
- [x] **ElNotification 通知** :white_check_mark: 已有 WS notification 处理
- [ ] **桌面系统通知**（P2 可选）
  - 当用户被 @mention 时触发 `Notification API`
- [ ] **@mention 消息列表**（P2 可选）
  - 侧边栏或弹窗中显示所有 @mention 记录

> **文件影响**：`useGroupChat.ts`, `ContentSidebar.vue`, `MainLayout.vue`, `App.vue`

---

### BugFix：WS 双系统消息转发修复（P0 — 已完成 2026-04-05）

> **根因分析**：项目中存在两套独立的 WebSocket 系统：
> 1. `useWebSocket.ts` composable — 直接 `new WebSocket(wsUrl)` 建立连接，在 `handleWebSocketMessage` 中通过 switch 路由消息
> 2. `services/websocket.ts` 的 `WebSocketService` — 提供 `on(type, handler)` 事件注册机制，但**从未建立自己的连接**
>
> `useGroupChat.ts` 通过 `ws.on('group_message', handler)` 在 WebSocketService 上注册监听，但 WebSocketService 没有活跃连接，导致 handler 永远不会被调用。
> 而 `useWebSocket.ts` 的 switch 中缺少 `group_message` 分支，消息被丢弃。
>
> **用户表现**：OpenClaw 回复了多条群聊消息，但前端只显示了用户发送后 API 返回的那一条（本地渲染），Bot 的 WS 推送消息全部丢失。

- [x] **useWebSocket.ts 新增 `group_message` / `notification` case** :white_check_mark:
  - 在 `handleWebSocketMessage` switch 中新增两个 case
  - 调用 `getWebSocketService().dispatch(data.type, data)` 转发给 WebSocketService 事件总线
- [x] **WebSocketService 新增 `dispatch(type, data)` 方法** :white_check_mark:
  - 手动触发已注册的 handler，绕过 WebSocketService 自身没有连接的问题
  - 与 `handleMessage` 保持一致的 handler 调用签名
- [x] **WebSocketService.handleMessage 统一传递完整消息对象** :white_check_mark:
  - 原代码 `handler(message.data)` → 后端发送 `{ type, groupId, message }` 无 `data` 字段
  - 修复为 `handler(message)` 传递完整对象，与 `dispatch()` 一致
  - `handleGroupNewMessage(data)` 中 `const { groupId, message } = data` 可正确解构

> **文件影响**：`composables/useWebSocket.ts` (+11 lines), `services/websocket.ts` (+19 lines)

---

### Phase 6：消息缓存 & 轮询兜底（P1 — 可靠性）

#### 6.1 群聊消息缓存
- [x] **sessionStorage 缓存群聊消息** :white_check_mark: Phase6 已完成
  - key: `group_messages_cache`，结构: `{ messages: { [groupId]: GroupMessage[] }, _timestamp }`
  - 30 分钟过期自动清除
  - 切换群组时优先从缓存加载，避免白屏
- [x] **内存缓存 allGroupMessages** :white_check_mark: Phase6 已完成
  - 类型: `Ref<Record<string, GroupMessage[]>>`
  - WS 新消息自动写入内存+sessionStorage 缓存

#### 6.2 消息轮询兜底
- [x] **30秒轮询机制** :white_check_mark: Phase6 已完成
  - 当页面可见且有选中群组时，每 30 秒从 API 拉取最新消息
  - 与 WS 推送互为补充
  - 对比最后一条消息 ID，仅在有新消息时更新
  - 组件卸载时自动停止轮询

> **文件影响**：`useGroupChat.ts`

---

### Phase 7：响应式 & 暗色模式（P2 — 适配）

#### 7.1 响应式布局
- [ ] **小屏幕适配（< 768px）**
  - 隐藏文件树面板
  - 群组列表改为抽屉模式
  - 导航栏缩小
- [ ] **中等屏幕适配（768px - 1200px）**
  - 聊天区域自适应宽度
  - 文件树面板可折叠

#### 7.2 暗色模式完善
- [ ] **所有新增/修改组件添加 `:global(.dark-mode)` 样式**
  - GroupMessagesView 消息气泡暗色
  - GroupMessageInput 输入框暗色
  - 未读角标在暗色模式下的对比度
  - 群组卡片暗色样式

> **文件影响**：各组件 `<style>` 块

---

## 三、组件改动清单（文件级）

| 操作 | 文件路径（相对 frontend/src/renderer/） | 状态 | 说明 |
|------|---------------------------------------|------|------|
| **修改** | `App.vue` | :white_check_mark: Phase1+3 | 群聊区域布局 + bots/getFullAvatarUrl 透传 + unread props |
| **修改** | `components/Sidebar/ContentSidebar.vue` | :white_check_mark: Phase1 | 群组列表卡片升级 + 未读角标 |
| **修改** | `layouts/MainLayout.vue` | :white_check_mark: Phase1 | 群聊未读红标 |
| **重写** | `components/chat/GroupMessagesView.vue` | :white_check_mark: Phase3 | 真实头像 + 复制 + 滚动 + TODO清单 + 暗色模式 |
| **修改** | `components/chat/GroupMessageInput.vue` | :white_check_mark: Phase4 | 图片上传（拖拽/粘贴/选择）+ 跳转最新消息按钮 |
| **修改** | `components/chat/GroupChatView.vue` | :white_check_mark: Phase2 | ChatHeader type="group" + bots透传 |
| **删除** | `components/chat/GroupChatHeader.vue` | :white_check_mark: Phase3 已删除 | 功能合并到 ChatHeader.vue |
| **修改** | `components/chat/ChatHeader.vue` | :white_check_mark: Phase3 | group分支: 成员+清空+删除+头像+暗色模式 |
| **修改** | `composables/useGroupChat.ts` | :white_check_mark: Phase1+3 | 未读计数 + highlightMentions增强 + clearGroupMessages |
| **修改** | `composables/useWebSocket.ts` | :white_check_mark: WS修复 | 新增 group_message/notification case 转发到 WebSocketService |
| **修改** | `services/websocket.ts` | :white_check_mark: WS修复 | 新增 dispatch() 方法 + handleMessage 传递完整对象 |
| **修改** | `utils/markdown.ts` | :white_check_mark: Phase3 | DOMPurify 允许 data-mention + mention增强 |
| **修改** | `views/GroupChatPage.vue` | :white_check_mark: Phase7 | bots/getFullAvatarUrl 透传 + clearMessages 事件 |

---

## 四、后端 API 配合需求

| API | 状态 | 需求 |
|-----|------|------|
| `GET /api/groups/:groupId/messages` | 已有 ✅ | 需增加 `?before=<timestamp>&limit=50` 分页参数 |
| `GET /api/groups` | 已有 ✅ | 需增加 `last_message` 字段（最近一条消息摘要） |
| `GET /api/groups/:groupId/unread` | 缺失 ❌ | 返回该群组的未读消息数（可选，前端也可纯本地计算） |
| `POST /api/groups/:groupId/messages/read` | 缺失 ❌ | 标记已读（可选，多端同步时需要） |
| `POST /api/groups/:groupId/files` | 缺失 ❌ | 群聊文件上传 API（Phase 4 需要） |

---

## 五、数据流架构（重构后）

```
┌───────────────────────────────────────────────────────────────────┐
│ App.vue 四栏布局                                                   │
│                                                                    │
│ ┌──────────┐ ┌──────────────┐ ┌─────────────────┐ ┌────────────┐ │
│ │MainLayout│ │ContentSidebar│ │   ChatArea       │ │Workspace   │ │
│ │          │ │              │ │                  │ │Panel       │ │
│ │ 驾驶舱   │ │ [群聊Tab]     │ │ ChatHeader       │ │            │ │
│ │ 聊天     │ │ 搜索框        │ │ type="group"     │ │ 群聊文件树  │ │
│ │ ★群聊   │ │ ┌──────────┐ │ │                  │ │            │ │
│ │ 任务     │ │ │ 群组卡片  │ │ │ GroupMessages    │ │ 预览       │ │
│ │ 企微     │ │ │ 🔴 未读3 │ │ │ View.vue         │ │            │ │
│ │ AI员工   │ │ │ 最近消息  │ │ │ (真实头像+复制   │ │            │ │
│ │ 学院     │ │ │ 预览文本  │ │ │  +加载更多)      │ │            │ │
│ │          │ │ ├──────────┤ │ │                  │ │            │ │
│ │ 🔴 5    │ │ │ 群组卡片  │ │ │ GroupMessage     │ │            │ │
│ │ (未读总数)│ │ │ 🔴 未读2 │ │ │ Input.vue        │ │            │ │
│ │          │ │ │ ...       │ │ │ (文件上传+跳转)  │ │            │ │
│ └──────────┘ └──────────────┘ └─────────────────┘ └────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

---

## 六、未读消息数据流

```
WS: group_message 事件到达
  │
  ├─ 是当前选中群组？
  │   ├─ YES → groupMessages.push(msg) → 自动滚底 → 不增加未读
  │   └─ NO  → groupUnreadCounts[groupId]++ → 侧边栏角标更新
  │            └─ 是否在群聊 Tab？
  │                ├─ YES → 侧边栏红标可见
  │                └─ NO  → MainLayout 导航红标 +1
  │
  ├─ 同时更新 groupLastMessages[groupId]
  │   → 侧边栏卡片预览文本刷新
  │
  └─ 是 @mention 当前用户？
      └─ YES → ElNotification + 桌面通知 + 强调角标
```

---

## 七、执行计划 & 排期建议

| 阶段 | 内容 | 预估工时 | 依赖 |
|------|------|---------|------|
| **Phase 1** | 布局统一 + 群组列表升级 | 4h | 无 |
| **Phase 2** | 聊天头部重构 | 1h | Phase 1 |
| **Phase 3** | 消息区域重构 | 6h | Phase 1 |
| **Phase 4** | 输入框重构 | 3h | Phase 1 |
| **Phase 5** | 未读消息 & 红标系统 | 4h | Phase 1 + 3 |
| **Phase 6** | 消息缓存 & 轮询 | 2h | Phase 3 |
| **Phase 7** | 响应式 & 暗色模式 | 2h | 全部 |
| | **总计** | **~22h** | |

**建议执行顺序**：Phase 1 → Phase 5 → Phase 2 → Phase 3 → Phase 4 → Phase 6 → Phase 7

先完成布局 + 红标（让用户立刻感受到变化），再逐步打磨消息区域和输入框。

---

## 八、验收标准

### 视觉验收
- [ ] 群聊四栏布局与单聊完全一致（导航 + 侧边栏 + 聊天 + 文件树）
- [ ] 群组列表卡片样式与 Bot 列表卡片样式统一
- [ ] 群聊消息气泡样式与单聊一致
- [ ] Bot 头像使用真实头像而非 emoji
- [ ] 暗色模式下所有组件正常显示

### 交互验收
- [ ] 切换群组时消息正确加载、侧边栏高亮切换
- [ ] 新消息到达时自动滚底（用户未查看历史时）
- [ ] 触顶滚动加载更多历史消息
- [ ] @mention 输入流畅、高亮显示、键盘导航正常
- [ ] 消息复制功能正常

### 通知验收
- [ ] 非当前群组收到消息时，侧边栏群组卡片显示红色未读角标
- [ ] 非群聊 Tab 收到消息时，导航栏群聊图标显示红色角标
- [ ] 选中群组后未读计数清零
- [ ] @mention 当前用户时弹出 ElNotification 通知
- [ ] 未读角标数字显示正确（1-99 / 99+）

### 性能验收
- [ ] 100条消息页面流畅滚动
- [ ] 切换群组响应时间 < 300ms
- [ ] WS 断线后轮询兜底正常工作
- [ ] sessionStorage 缓存命中率 > 80%（30分钟内）
