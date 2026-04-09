# 🔄 Bot Chat Manager 消息与任务流程逻辑报告

**日期**: 2026-03-16  
**项目**: Bot Chat Manager  
**文档**: 消息发送与任务分配完整流程

---

## 📋 目录

1. [Bot自动发送消息逻辑](#1-bot自动发送消息逻辑)
2. [群聊@mention任务分配与完成流程](#2-群聊mention任务分配与完成流程)
3. [任务状态流转](#3-任务状态流转)
4. [完整工作流程图](#4-完整工作流程图)

---

## 1. Bot自动发送消息逻辑

### 📍 核心位置
```
backend/src/controllers/botController.js
方法: sendMessage() (第 54-164 行)
```

### 🔄 消息发送流程

#### 步骤1: 用户发送消息
```
前端 → POST /api/bots/:botId/send
```

**请求参数**:
```javascript
{
  botId: string,      // Bot ID
  content: string,    // 消息内容
  model: string,      // 可选：指定模型
  style: string       // 可选：聊天风格
}
```

#### 步骤2: 后端处理流程

```javascript
// 1️⃣ 重复消息检测 (5秒窗口)
const cacheKey = `${botId}:${content}`
if (duplicateCache.has(cacheKey)) {
  return // 跳过重复消息
}

// 2️⃣ 识别Bot环境
const environment = detectBotEnvironment(botId)
// 返回: { type: 'local'|'openclaw'|'remote', name: string }

// 3️⃣ 保存用户消息到数据库
const userMessageId = await saveMessage(
  botId,
  'user',         // 发送者类型
  'Jason',        // 发送者名称
  content,        // 消息内容
  false,          // 是否分组
  botId,          // 接收者ID
  '老板'          // 发送者标签
)

// 4️⃣ 创建任务监控
const taskId = taskMonitor.createTask(botId, content, model)

// 5️⃣ 立即返回HTTP响应 (不阻塞前端)
res.json({
  success: true,
  userMessage: { id: userMessageId, sender: 'user', content, timestamp: now },
  taskId,
  message: '消息已发送，Bot正在处理中...'
})
```

#### 步骤3: 异步调用OpenClaw (不阻塞)

```javascript
// 🔧 异步处理，不阻塞HTTP响应
(async () => {
  try {
    // 1️⃣ 更新任务状态
    taskMonitor.updateTaskStatus(taskId, 'running', {
      currentStep: '正在发送到OpenClaw...'
    })
    
    // 2️⃣ 调用OpenClaw API
    const apiUrl = config?.openclaw?.api_url || 'http://localhost:18789'
    const result = await openclawClient.sendMessage(botId, content, model)
    
    // 3️⃣ 处理Bot回复
    if (result.success && result.data?.response) {
      // 保存Bot回复到数据库
      const botMessageId = await saveMessage(
        botId,
        'bot',                          // 发送者类型
        result.data.bot_name || botId,  // Bot名称
        result.data.response,           // 回复内容
        false,
        botId,
        botId
      )
      
      // 更新任务状态为完成
      taskMonitor.updateTaskStatus(taskId, 'completed', {
        currentStep: '完成',
        progress: 100
      })
      
      // 4️⃣ WebSocket实时推送到前端 ⚡
      wsManager.broadcast({
        type: 'message',
        botId,
        message: {
          id: botMessageId,
          sender: 'bot',
          content: result.data.response,
          timestamp: Date.now()
        }
      })
      
      console.log(`✅ Bot回复已发送`)
    }
  } catch (error) {
    // 错误处理
    taskMonitor.updateTaskStatus(taskId, 'failed', {
      error: error.message
    })
  }
})()
```

### 📬 消息发送到哪里？

| 发送者 | 目标位置 | 推送方式 | 说明 |
|--------|---------|---------|------|
| 用户 → Bot | 1. 数据库 `messages` 表 | HTTP POST | 持久化存储 |
| | 2. OpenClaw API | HTTP POST | 实时处理 |
| Bot → 用户 | 1. 数据库 `messages` 表 | 异步保存 | 持久化存储 |
| | 2. 前端WebSocket | 实时推送 | **用户接收位置** ⚡ |

### 🎯 关键点

1. **双向保存**: 用户消息和Bot回复都保存到数据库 `messages` 表
2. **异步处理**: OpenClaw调用不阻塞HTTP响应,用户体验流畅
3. **实时推送**: 通过WebSocket将Bot回复推送到前端
4. **任务监控**: 创建taskId跟踪消息处理进度
5. **重复检测**: 5秒窗口内相同消息会被跳过

---

## 2. 群聊@mention任务分配与完成流程

### 📍 核心位置
```
backend/src/controllers/groupController.js
方法: sendGroupMessage() (第 198-360 行)

backend/tasks/task_detector.js
类: TaskDetector
方法: detectTaskIntent()

backend/tasks/task_manager.js
类: TaskManager
方法: createTask(), updateStatus(), verifyComplete()
```

### 🔄 完整工作流程

#### 场景: 部门群聊中负责人安排任务

```
假设群组: "技术研发部"
负责人: tech-lead
成员: developer-1, developer-2
```

---

### 步骤1: 负责人 @成员 分配任务

#### 1.1 负责人发送消息
```
前端 → POST /api/groups/:groupId/send
```

**消息示例**:
```
负责人(tech-lead)发送:
"@developer-1 任务：完成用户登录模块，优先级：高，截止时间：明天"
```

#### 1.2 后端解析消息

```javascript
// 📍 位置: groupController.js sendGroupMessage()

// 1️⃣ 解析 @mention
const mentions = []
const mentionRegex = /@([a-zA-Z0-9\-_]+)/g
let match
while ((match = mentionRegex.exec(content)) !== null) {
  mentions.push(match[1])  // ['developer-1']
}

// 2️⃣ 保存消息到数据库
const message = saveGroupMessage(
  groupId,           // 群组ID
  'tech-lead',       // 发送者ID
  '技术负责人',       // 发送者名称
  content,           // 消息内容
  mentions           // @提及列表: ['developer-1']
)

// 3️⃣ 立即返回 (不阻塞用户)
res.json({ success: true, message })
```

#### 1.3 任务意图检测

```javascript
// 📍 位置: task_detector.js detectTaskIntent()

const taskIntent = taskDetector.detectTaskIntent(content, mentions)

// 检测结果:
{
  type: 'create',                    // 任务类型：创建
  raw: "原始消息内容",
  mentions: ['developer-1'],         // @提及
  title: "完成用户登录模块",        // 任务标题
  assignee: 'developer-1',           // 执行人
  priority: 'high',                  // 优先级: 高
  deadline: '2026-03-17T23:59:59',   // 截止时间: 明天
  description: "完成用户登录模块",
  timestamp: '2026-03-16T...'
}
```

**任务检测关键词**:
```javascript
create: ['任务：', '任务:', '帮我做', '请处理', '安排', '分配给']
complete: ['请验收', '已完成', '完成了', '做完了', '提交验收']
problem: ['问题：', '问题:', '卡在', '需要帮助', '阻塞']
accept: ['接收任务', '我来做', '开始做']
update: ['进度更新', '进度：', '进度:']
```

#### 1.4 生成任务预览卡片

```javascript
// 📍 位置: groupController.js (第 258-282 行)

if (taskIntent && taskIntent.type === 'create') {
  // 1️⃣ 生成确认令牌 (防误触发)
  const confirmToken = taskManager.generateConfirmToken()
  
  // 2️⃣ 缓存任务意图 (5分钟有效)
  taskManager.saveConfirmToken(confirmToken, {
    ...taskIntent,
    groupId,
    messageId: message.id,
    assigner: '技术负责人'
  })
  
  // 3️⃣ 推送任务预览卡片到前端 ⚡
  wsManager.broadcast({
    type: 'task_preview',
    groupId,
    preview: {
      title: "完成用户登录模块",
      assignee: 'developer-1',
      priority: 'high',
      deadline: '2026-03-17T23:59:59',
      confirmToken           // 前端确认用
    }
  })
  
  console.log(`📋 [Tasks] 任务预览已发送，等待确认`)
}
```

#### 1.5 @mention自动通知

```javascript
// 📍 位置: groupController.js (第 286-350 行)

// 异步处理Bot回复
if (mentions.length > 0) {
  (async () => {
    // 1️⃣ 获取群聊上下文 (最近10条消息)
    const recentMessages = getGroupMessages(groupId, 10)
    
    // 2️⃣ 构建上下文消息
    let contextMessage = '【群聊上下文 - 最近10条消息】\n'
    recentMessages.forEach(msg => {
      contextMessage += `${msg.sender_name}: ${msg.content}\n`
    })
    contextMessage += '\n【请回复上述对话，特别关注提及你的消息】'
    
    // 3️⃣ 循环处理每个@mention的Bot
    for (const botId of mentions) {  // ['developer-1']
      // 识别Bot环境
      const environment = detectBotEnvironment(botId)
      
      if (environment.type === 'local' && openclawClient) {
        // 调用OpenClaw API发送上下文
        const result = await openclawClient.sendMessage(
          botId,              // 'developer-1'
          contextMessage      // 带上下文的消息
        )
        
        // 保存Bot回复
        if (result.success && result.data?.response) {
          const botReply = await saveGroupMessage(
            groupId,
            botId,                           // 'developer-1'
            result.data.bot_name,
            result.data.response,            // "收到！我会完成用户登录模块..."
            []
          )
          
          // 🆕 推送Bot回复到前端 ⚡
          wsManager.broadcast({
            type: 'group_message',
            groupId,
            message: botReply
          })
        }
      }
    }
  })()
}
```

**结果**: 
- ✅ `developer-1` 收到通知(通过OpenClaw)
- ✅ `developer-1` 自动回复确认消息
- ✅ 群聊中所有人看到Bot回复

---

### 步骤2: 成员接收任务

#### 2.1 成员回复"接收任务"

```
developer-1 发送:
"@tech-lead 接收任务，我来做"
```

#### 2.2 检测接收意图

```javascript
// 📍 位置: task_detector.js

const intent = taskDetector.detectTaskIntent(content, mentions)

// 检测结果:
{
  type: 'accept',              // 任务类型：接收
  mentions: ['tech-lead'],     // @提及负责人
  raw: "原始消息",
  timestamp: '...'
}
```

#### 2.3 更新任务状态

```javascript
// 📍 位置: task_manager.js

// 任务状态: pending → in_progress
taskManager.updateTaskStatus(taskId, 'in_progress', {
  acceptedBy: 'developer-1',
  acceptedAt: Date.now()
})

// 发布事件
eventBus.publish(EVENTS.TASK_ACCEPTED, {
  taskId,
  assignee: 'developer-1',
  timestamp: Date.now()
})

// 📍 保存任务文件
// 文件路径: /home/user/.octowork/departments/OctoTech-Team/task_box/in_progress/TASK-20260316-A1B2.md
```

**任务状态流转规则**:
```javascript
pending → in_progress → completed → accepted
  ↑          ↓
  └──────────┘ (可以退回)
```

---

### 步骤3: 成员完成任务并@负责人

#### 3.1 成员提交任务

```
developer-1 发送:
"@tech-lead 已完成，请验收！用户登录模块已开发完成，单元测试通过。"
```

#### 3.2 检测完成意图

```javascript
// 📍 位置: task_detector.js

const intent = taskDetector.detectTaskIntent(content, mentions)

// 检测结果:
{
  type: 'complete',                    // 任务类型：完成
  mentions: ['tech-lead'],             // @提及负责人
  raw: "原始消息",
  completionNote: "用户登录模块已开发完成，单元测试通过",
  timestamp: '...'
}
```

#### 3.3 更新任务状态

```javascript
// 📍 位置: task_manager.js

// 任务状态: in_progress → completed (待验收)
taskManager.updateTaskStatus(taskId, 'completed', {
  completedBy: 'developer-1',
  completedAt: Date.now(),
  completionNote: "用户登录模块已开发完成，单元测试通过"
})

// 发布事件
eventBus.publish(EVENTS.TASK_COMPLETED, {
  taskId,
  assignee: 'developer-1',
  completionNote: "...",
  timestamp: Date.now()
})

// 📍 移动任务文件
// 从: /departments/OctoTech-Team/task_box/in_progress/TASK-20260316-A1B2.md
// 到: /departments/OctoTech-Team/task_box/completed/TASK-20260316-A1B2.md
```

#### 3.4 通知负责人验收

```javascript
// 📍 位置: groupController.js

// @tech-lead 会收到OpenClaw通知
// 群聊消息会推送给所有在线成员

// 1️⃣ @tech-lead 自动回复
"收到！我会尽快验收..."

// 2️⃣ 推送验收提醒卡片
wsManager.broadcast({
  type: 'task_review_request',
  groupId,
  task: {
    id: taskId,
    title: "完成用户登录模块",
    assignee: 'developer-1',
    status: 'completed',
    completionNote: "...",
    reviewer: 'tech-lead'
  }
})
```

---

### 步骤4: 负责人验收

#### 4.1 负责人验收通过

```
tech-lead 回复:
"@developer-1 验收通过！代码质量很好👍"
```

#### 4.2 检测验收意图

```javascript
// 📍 位置: task_detector.js

// 关键词检测: "验收通过"、"已验收"、"accept"
const intent = {
  type: 'accept_review',
  mentions: ['developer-1'],
  reviewResult: 'approved',
  feedback: "代码质量很好👍"
}
```

#### 4.3 完成任务

```javascript
// 📍 位置: task_manager.js

// 任务状态: completed → accepted (终态)
taskManager.updateTaskStatus(taskId, 'accepted', {
  reviewedBy: 'tech-lead',
  reviewedAt: Date.now(),
  reviewFeedback: "代码质量很好👍"
})

// 发布事件
eventBus.publish(EVENTS.TASK_ACCEPTED_REVIEW, {
  taskId,
  reviewer: 'tech-lead',
  assignee: 'developer-1',
  feedback: "代码质量很好👍",
  timestamp: Date.now()
})

// 📍 移动任务文件到已验收目录
// 从: /departments/OctoTech-Team/task_box/completed/TASK-20260316-A1B2.md
// 到: /departments/OctoTech-Team/task_box/accepted/TASK-20260316-A1B2.md
```

#### 4.4 通知所有相关人员

```javascript
// 推送任务完成通知
wsManager.broadcast({
  type: 'task_accepted',
  groupId,
  task: {
    id: taskId,
    title: "完成用户登录模块",
    assignee: 'developer-1',
    reviewer: 'tech-lead',
    status: 'accepted',
    completedAt: Date.now(),
    reviewFeedback: "代码质量很好👍"
  }
})
```

---

## 3. 任务状态流转

### 📊 状态机

```
┌─────────────────────────────────────────────────────┐
│                  任务生命周期                        │
└─────────────────────────────────────────────────────┘

1. 创建阶段
   ┌───────────┐
   │  pending  │  待接收
   └───────────┘
        │
        │ 成员回复 "接收任务"
        ↓
2. 执行阶段
   ┌─────────────┐
   │ in_progress │  进行中
   └─────────────┘
        │
        │ 成员回复 "已完成"
        ↓
3. 验收阶段
   ┌───────────┐
   │ completed │  待验收
   └───────────┘
        │
        │ 负责人回复 "验收通过"
        ↓
4. 完成阶段
   ┌───────────┐
   │ accepted  │  已验收 (终态)
   └───────────┘
```

### 🔄 状态流转规则

```javascript
// 📍 位置: task_manager.js TASK_STATUS & STATUS_TRANSITIONS

const TASK_STATUS = {
    PENDING: 'pending',           // 待接收
    IN_PROGRESS: 'in_progress',   // 进行中
    COMPLETED: 'completed',       // 待验收
    ACCEPTED: 'accepted'          // 已验收
}

const STATUS_TRANSITIONS = {
    'pending': ['in_progress'],                // 只能开始
    'in_progress': ['completed', 'pending'],   // 可以完成或退回
    'completed': ['accepted', 'in_progress'],  // 可以验收或退回
    'accepted': []                             // 终态，不可更改
}
```

### 📂 任务文件存储

```
工作空间: /home/user/.octowork/departments/

示例: 技术研发部的任务
/home/user/.octowork/departments/OctoTech-Team/
├── task_box/
│   ├── pending/              ← 待接收任务
│   │   └── TASK-20260316-A1B2.md
│   ├── in_progress/          ← 进行中任务
│   │   └── TASK-20260316-C3D4.md
│   ├── completed/            ← 待验收任务
│   │   └── TASK-20260316-E5F6.md
│   └── accepted/             ← 已验收任务
│       └── TASK-20260316-G7H8.md
└── agents/
    └── team_config.json
```

### 📝 任务文件格式

```markdown
# TASK-20260316-A1B2

## 基本信息
- **任务ID**: TASK-20260316-A1B2
- **标题**: 完成用户登录模块
- **创建时间**: 2026-03-16 10:00:00
- **分配人**: tech-lead (技术负责人)
- **执行人**: developer-1
- **优先级**: 🔴 高
- **截止时间**: 2026-03-17 23:59:59
- **状态**: accepted

## 任务描述
完成用户登录模块，包含密码登录和第三方登录功能。

## 进度记录
- **2026-03-16 10:00:00** - 任务创建 (pending)
- **2026-03-16 10:05:00** - 任务接收 (in_progress) by developer-1
- **2026-03-16 18:30:00** - 任务完成 (completed) by developer-1
  - 完成说明: 用户登录模块已开发完成，单元测试通过
- **2026-03-16 19:00:00** - 验收通过 (accepted) by tech-lead
  - 验收反馈: 代码质量很好👍

## 相关消息
- 群聊ID: 123
- 消息ID: 456, 457, 458
```

---

## 4. 完整工作流程图

### 🎯 端到端流程

```
┌──────────────────────────────────────────────────────────────┐
│                  完整工作流程                                 │
└──────────────────────────────────────────────────────────────┘

1️⃣ 任务创建
   负责人 → "@developer-1 任务：完成登录模块"
        ↓
   groupController.sendGroupMessage()
        ↓
   taskDetector.detectTaskIntent() → type: 'create'
        ↓
   taskManager.generateConfirmToken()
        ↓
   WebSocket推送 → 前端显示任务预览卡片
        ↓
   OpenClaw通知 → @developer-1 收到消息

2️⃣ 任务接收
   成员 → "@tech-lead 接收任务，我来做"
        ↓
   taskDetector.detectTaskIntent() → type: 'accept'
        ↓
   taskManager.updateStatus('pending' → 'in_progress')
        ↓
   eventBus.publish(TASK_ACCEPTED)
        ↓
   移动文件: pending/ → in_progress/
        ↓
   WebSocket推送 → 前端更新任务状态

3️⃣ 任务完成
   成员 → "@tech-lead 已完成，请验收"
        ↓
   taskDetector.detectTaskIntent() → type: 'complete'
        ↓
   taskManager.updateStatus('in_progress' → 'completed')
        ↓
   eventBus.publish(TASK_COMPLETED)
        ↓
   移动文件: in_progress/ → completed/
        ↓
   WebSocket推送 → 负责人收到验收请求

4️⃣ 任务验收
   负责人 → "@developer-1 验收通过！"
        ↓
   taskDetector.detectTaskIntent() → type: 'accept_review'
        ↓
   taskManager.updateStatus('completed' → 'accepted')
        ↓
   eventBus.publish(TASK_ACCEPTED_REVIEW)
        ↓
   移动文件: completed/ → accepted/
        ↓
   WebSocket推送 → 所有人收到完成通知
```

### 🔌 关键组件交互

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   前端UI    │────▶│ groupController│────▶│  数据库     │
└─────────────┘     └──────────────┘     └─────────────┘
       ▲                    │                     ▲
       │                    ↓                     │
       │            ┌──────────────┐             │
       │            │ taskDetector │             │
       │            └──────────────┘             │
       │                    │                     │
       │                    ↓                     │
       │            ┌──────────────┐             │
       │            │ taskManager  │─────────────┘
       │            └──────────────┘
       │                    │
       │                    ↓
       │            ┌──────────────┐
       └────────────│  eventBus    │
                    └──────────────┘
                           │
                           ↓
                    ┌──────────────┐     ┌─────────────┐
                    │  wsManager   │────▶│ OpenClaw    │
                    └──────────────┘     └─────────────┘
```

---

## 📊 核心数据流

### 消息数据流

```
用户消息:
  前端 → HTTP POST → botController → 数据库(messages表) → OpenClaw
                                   ↓
                            taskMonitor创建任务
                                   ↓
Bot回复:
  OpenClaw → botController → 数据库(messages表)
                          ↓
                    WebSocket推送 → 前端显示
```

### 群聊任务数据流

```
任务创建:
  负责人@成员 → groupController → taskDetector识别 → taskManager创建
                                                    ↓
                                         生成confirmToken(5分钟有效)
                                                    ↓
                                        WebSocket推送任务预览卡片
                                                    ↓
                                        OpenClaw通知@mention的Bot

任务状态:
  成员操作 → groupController → taskDetector识别 → taskManager更新状态
                                                    ↓
                                        移动任务文件到对应目录
                                                    ↓
                                        eventBus发布事件
                                                    ↓
                                        WebSocket推送状态更新
```

---

## 🔑 关键技术点

### 1️⃣ 消息去重
```javascript
// 5秒窗口内相同消息跳过
const cacheKey = `${botId}:${content}`
const lastTime = duplicateCache.get(cacheKey)
if (lastTime && now - lastTime < 5000) {
  return // 跳过重复
}
```

### 2️⃣ 异步处理
```javascript
// HTTP立即返回，不阻塞用户
res.json({ success: true, taskId })

// 异步调用OpenClaw
(async () => {
  await openclawClient.sendMessage(...)
  wsManager.broadcast(...)  // 推送结果
})()
```

### 3️⃣ WebSocket实时推送
```javascript
// 消息类型
wsManager.broadcast({
  type: 'message' | 'group_message' | 'task_preview' | 'task_accepted',
  ...data
})
```

### 4️⃣ 任务意图识别
```javascript
// 关键词匹配
TASK_KEYWORDS = {
  create: ['任务：', '任务:', '帮我做', '安排'],
  complete: ['已完成', '请验收'],
  accept: ['接收任务', '我来做']
}
```

### 5️⃣ 确认令牌机制
```javascript
// 防止误触发，5分钟有效
const token = generateConfirmToken()
saveConfirmToken(token, taskIntent)
// 前端点击确认后验证token
```

---

## 📝 总结

### Bot自动发送消息

**目标位置**:
1. 数据库 `messages` 表 (持久化)
2. 前端WebSocket (实时推送) ⚡

**流程**: 用户→HTTP→数据库→OpenClaw→Bot回复→数据库→WebSocket→前端

### 群聊任务流程

**完整链路**:
1. 负责人@成员分配任务 → 任务检测 → 生成预览 → 通知成员
2. 成员接收任务 → 状态更新(pending→in_progress) → 移动文件
3. 成员完成任务 → @负责人 → 状态更新(in_progress→completed)
4. 负责人验收 → 状态更新(completed→accepted) → 任务结束

**关键机制**:
- @mention自动识别和通知
- 任务意图智能检测(关键词匹配)
- 任务状态流转(状态机)
- WebSocket实时推送
- 文件系统存储任务卡

---

**报告完成时间**: 2026-03-16  
**文档版本**: v1.0  
**状态**: ✅ 完整
