# 任务看板模块 — API 速查

> 最后更新: 2026-04-07（基于实际代码）

---

## 后端文件清单

| 文件 | 行数 | 职责 |
|------|------|------|
| `backend/src/controllers/boardController.js` | 1,068 | 看板核心控制器 (旧四列+新流水线) |
| `backend/src/routes/boardRoutes.js` | 161 | 看板路由 (新旧共存) |
| `backend/src/controllers/taskController.js` | 607 | 群聊任务确认/状态/进度 |
| `backend/src/routes/taskRoutes.js` | 63 | 任务路由 |
| `backend/src/routes/taskPipelineRoutes.js` | 221 | 个人任务流水线路由 |
| `backend/services/personalTaskPipeline.js` | 836 | 个人任务流水线服务 |
| `backend/tasks/task_box_watcher.js` | 551 | 文件监控 (task_box + pipeline_state) |
| `backend/tasks/task_detector.js` | 381 | 群聊任务意图识别 |
| `backend/tasks/task_manager.js` | 640 | 任务卡 CRUD + 文件管理 |
| `backend/services/task-monitor.js` | 246 | Bot 执行任务监控 |
| **合计** | **4,774** | |

路由注册: `backend/src/routes/index.js`
```javascript
app.use('/api/board',         setupBoardRoutes(controllers.board))      // 看板
app.use('/api',               setupTaskRoutes(controllers.task))         // 群聊任务
app.use('/api/task-pipeline', taskPipelineRoutes)                        // 个人流水线
```

---

## 一、看板 API — 流水线驱动（新，已实现）

### 1.1 部门列表（含流水线摘要）

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/board/departments` | `getDepartmentsWithPipeline` | 改造版：含当前项目+pipeline 摘要 |

**核心流程**:
```
GET /api/board/departments
│
├─ 1. _getDepartmentsList()
│   ├─ 有缓存(10min)? → 直接返回
│   └─ 无缓存 → 扫描 $OCTOWORK_WORKSPACE/departments/
│       ├─ 过滤: 只保留目录
│       ├─ 读取: agents/team_config.json → description
│       └─ 缓存 10 分钟
│
├─ 2. FOR EACH dept:
│   ├─ [旧] taskBoxWatcher.getDepartmentTasks() → health + taskCount
│   ├─ [新] _scanProjects(deptId) → 扫描 pipeline_state.json
│   │   ├─ _getDeptProjectConfig() → 读 team_config.json 确定路径
│   │   ├─ 遍历日期目录 → 遍历项目目录 → _readPipelineState()
│   │   └─ _extractPipelineSummary() → status, currentStep, progress, guardian
│   ├─ 分组: inProgress / pending / completed
│   ├─ currentProject = inProgress[0] (取第一个进行中项目)
│   ├─ 读 ai-directory.json → staffCount
│   ├─ 读 team_config.json → icon
│   └─ 读 pipeline_template.json → pipelineSteps (模板步骤数)
│
└─ 3. res.json({ success, departments: [...], total })
```

**返回格式**:
```json
{
  "success": true,
  "departments": [
    {
      "id": "TokVideoGroup",
      "name": "TokVideoGroup",
      "icon": "🎬",
      "description": "OctoVideo 视频生产部",
      "staffCount": 12,
      "pipelineSteps": 17,
      "health": "green",
      "taskCount": { "total": 3, "pending": 1, "in_progress": 1, "completed": 1, "accepted": 0, "blocked": 0 },
      "currentProject": {
        "id": "20260404_TokProject_01",
        "name": "KoriDerm 护肤霜",
        "status": "in_progress",
        "currentStep": "step_c",
        "currentStepName": "Step-C 抽帧截图",
        "executor": "IMGP",
        "progress": { "passed": 6, "total": 17 },
        "elapsedMinutes": 330,
        "guardianAlive": true
      },
      "summary": { "pending": 1, "in_progress": 1, "completed": 0 }
    }
  ],
  "total": 5
}
```

### 1.2 部门项目列表

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/board/:deptId/projects?date=YYYYMMDD` | `getProjects` | 按状态分组+历史 |

**核心流程**:
```
GET /api/board/:deptId/projects
│
├─ 验证部门存在
├─ _scanProjects(deptId, dateFilter)
│   └─ 同上: 扫描日期目录 → pipeline_state.json → 提取摘要
├─ 分组:
│   ├─ inProgress: [{id, name, pipeline, currentStep, currentStepName, executor, progress, elapsedMinutes, rejectCount, guardianAlive}]
│   ├─ pending: [{id, name}]
│   └─ completed: [{id, name, completedAt}]
├─ history: 扫描非今日日期目录(最近7天), 每天统计项目数和名称
└─ res.json({ success, deptId, date, inProgress, pending, completed, history })
```

### 1.3 项目流水线详情

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/board/:deptId/projects/:projectId/pipeline` | `getPipeline` | 完整 pipeline_state.json |

**流程**: 验证部门 → `_getDeptProjectConfig()` → 遍历日期目录搜索 projectId → `_readPipelineState()` → 返回完整 JSON

**返回**: 直接展开 pipeline_state.json 内容 + `success, deptId, projectId` 包装

### 1.4 项目事件日志

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/board/:deptId/projects/:projectId/events` | `getEvents` | 事件日志 |

**返回**:
```json
{ "success": true, "deptId": "...", "projectId": "...", "events": [ {time, actor, action, step, detail} ] }
```

### 1.5 task_box 状态一览

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/board/:deptId/task-boxes` | `getTaskBoxes` | 团队+个人 Bot task_box |

**核心流程**:
```
GET /api/board/:deptId/task-boxes
│
├─ 团队 task_box:
│   ├─ 检查 departments/{deptId}/task_box/in_progress/ 是否有 .md
│   ├─ 有 → status: 'in_progress', 解析文件内容提取 projectId
│   └─ 无 → status: 'idle'
│
├─ 个人 Bot task_box:
│   ├─ 读取 agents/ai-directory.json → Bot 列表
│   └─ FOR EACH bot:
│       ├─ 检查 agents/{botId}/task_box/in_progress/
│       └─ 返回 { botId, botName, status: 'in_progress'|'idle' }
│
└─ res.json({ success, deptId, team: {status, projectId}, personal: [...] })
```

### 1.6 催促 Bot

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| POST | `/api/board/:deptId/projects/:projectId/nudge` | `nudgeBot` | 催促 Bot 汇报进度 |

**Body**: `{ step_id: "step_c", executor: "IMGP" }`

**核心流程**:
```
POST /api/board/:deptId/projects/:projectId/nudge
│
├─ 1. 验证 step_id + executor
├─ 2. 频率限制: nudgeCooldown Map, 同一步骤 5 分钟内只能催 1 次
│   └─ 超频 → 429 { error: "催促过于频繁，请 N 秒后再试" }
├─ 3. EventBus 发布 'pipeline.step.started' (type: 'nudge') → 群聊模块接收
├─ 4. 写入 pipeline_state.json 的 event_log:
│   { actor: 'Board', action: 'nudge_sent', step, detail: '看板用户催促 @IMGP...' }
├─ 5. WS 广播: { type: 'pipeline_nudge', deptId, projectId, stepId, executor }
└─ 6. res.json({ success, message: '催促消息已发送到群聊 @IMGP' })
```

---

## 二、看板 API — 旧四列看板（保留兼容）

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/board/:deptId/tasks` | `getDepartmentTasks` | 获取部门全部任务 (可选 `?status=pending`) |
| GET | `/api/board/:deptId/tasks/:taskId` | `getTaskDetail` | 获取任务详情 (含 .md 完整内容) |
| PUT | `/api/board/:deptId/tasks/:taskId/move` | `moveTask` | 移动任务状态 `{newStatus, user}` |
| GET | `/api/board/:deptId/health` | `getDepartmentHealth` | 部门健康状态 + 完成率 |

### moveTask 流程

```
PUT /api/board/:deptId/tasks/:taskId/move {newStatus}
│
├─ 验证 newStatus ∈ [pending, in_progress, completed, accepted]
├─ 验证部门存在
├─ 遍历 task_box/{status}/ 目录查找 taskId 文件
├─ fs.move(oldFilePath → newFilePath)  ← 物理移动 .md 文件
├─ eventBus.publish('TASK_STATUS_CHANGED', {...})
└─ TaskBoxWatcher 自动检测文件变化 → WS 广播
```

---

## 三、群聊任务 API (`/api/tasks/...`)

| 方法 | 路径 | 控制器方法 | 说明 |
|------|------|-----------|------|
| GET | `/api/tasks/dashboard` | `getDashboard` | 任务看板数据 (TODO) |
| GET | `/api/tasks/active` | `getActiveTasks` | 所有活跃任务 |
| GET | `/api/tasks/stats` | `getTaskStats` | 任务统计 |
| GET | `/api/tasks` | `getAllTasks` | 全部任务 |
| GET | `/api/tasks/:taskId` | `getTaskDetail` | 单个任务详情 |
| POST | `/api/tasks/confirm` | `confirmTask` | 确认创建任务 (群聊预览后) |
| PUT | `/api/tasks/:taskId/status` | `updateTaskStatus` | 更新任务状态 (拖拽卡片) |
| POST | `/api/tasks/:taskId/problems` | `addProblem` | 添加问题记录 |
| PUT | `/api/tasks/:taskId/progress` | `updateProgress` | 更新进度 |
| POST | `/api/tasks/stop` | `stopTask` | 停止任务 |
| POST | `/api/tasks/cleanup` | `cleanupTasks` | 清理任务 |
| GET | `/api/departments/:deptId/tasks` | `getDepartmentTasks` | 部门所有任务 |
| POST | `/api/timeout/register` | `registerTimeout` | 注册超时检查 |

### confirmTask 核心流程

```
POST /api/tasks/confirm { confirmToken, priority?, deadline?, deptId? }
│
├─ 1. 验证 confirmToken → taskManager.verifyConfirmToken()
│   ├─ 令牌不存在或过期(5min) → 400
│   └─ 验证通过 → 获取 intent 对象 (title, assignee, assigner, priority, deadline)
├─ 2. taskManager.createTask()
│   ├─ generateTaskId() → "TASK-YYYYMMDD-XXXX"
│   ├─ saveTaskCard() → 生成 Markdown → 写入 task_box/pending/
│   └─ eventBus.emit(TASK_CREATED)
├─ 3. WS 广播: { type: 'task_created', task: {...} }
├─ 4. 通知 assignee:
│   ├─ 在线 → WS 推送 task_notification
│   └─ 离线 → offlineQueue.enqueue()
└─ 5. res.json({ success, task: {id, title, assignee, status, priority, deadline} })
```

---

## 四、个人任务流水线 API (`/api/task-pipeline/...`)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/task-pipeline/create` | 创建个人任务流水线 |
| POST | `/api/task-pipeline/:taskId/start` | 开始执行 (PENDING→IN_PROGRESS) |
| PUT | `/api/task-pipeline/:taskId/step` | 更新步骤状态 |
| POST | `/api/task-pipeline/:taskId/heartbeat` | 心跳上报 |
| GET | `/api/task-pipeline/:taskId` | 获取任务状态 |
| GET | `/api/task-pipeline/active` | 获取所有活跃任务 |
| POST | `/api/task-pipeline/:taskId/complete` | 手动完成任务 |

### create 请求体

```json
{
  "title": "撰写产品营销方案",
  "triggered_by": "Jason",
  "original_message": "帮我写一个完整的产品营销方案...",
  "steps": [
    { "name": "需求分析", "description": "分析产品特点和目标市场" },
    { "name": "竞品调研", "description": "调研竞品的营销策略" },
    { "name": "方案撰写", "description": "撰写完整营销方案" },
    { "name": "自检交付", "description": "检查质量并交付" }
  ]
}
```

**限制**: 步骤数 3-10; 每步必须有 name

### create 核心流程

```
POST /api/task-pipeline/create
│
├─ 1. 验证步骤 (3-10, 每步有 name)
├─ 2. 生成 taskId: "{YYYYMMDD}_Task_{NN}" (自动递增)
├─ 3. 创建目录结构:
│   └─ departments/PersonalTasks/project-workspace/Task/{date}/{taskId}/
│       ├─ 00_任务卡/task_state.json
│       ├─ 00_任务卡/00_任务卡.md
│       ├─ 01_需求分析/
│       ├─ 02_竞品调研/
│       └─ ...
├─ 4. 写入 task_box/pending/{taskId}-{title}.md
├─ 5. EventBus: PERSONAL_TASK_CREATED
├─ 6. WS 广播: board_update → personal_task_created
└─ 7. 返回 { success, task_id, task_state_path, task_state }
```

### updateStep 请求体

```json
{ "step_id": "step_1", "status": "completed", "detail": "分析完成" }
```

**自动前进**: 当步骤标记为 `completed` 时，自动将下一步设为 `in_progress`  
**全部完成**: 所有步骤 `completed` → 任务状态变 `completed` → 移动 task_box

### heartbeat 请求体

```json
{ "current_step": "正在执行市场调研..." }
```

> 如果任务之前是 `stalled`，心跳会恢复为 `in_progress`

---

## 五、WS 推送消息格式

### 看板文件变更 (TaskBoxWatcher)

```javascript
// task_box 文件事件
{
  type: 'board_update',
  event: 'task_created' | 'task_updated' | 'task_removed',
  data: { deptId, task: { id, deptId, status, title, ... } | taskId },
  timestamp: number
}

// pipeline_state.json 变更
{
  type: 'pipeline_update',
  deptId: string,
  projectId: string,
  currentStep: string | null,
  currentStepName: string | null,
  executor: string | null,
  progress: { passed: number, total: number },
  guardian: { last_heartbeat, stall_timeout_minutes, ... } | null,
  updatedAt: string,
  timestamp: number
}
```

### 催促事件

```javascript
{
  type: 'pipeline_nudge',
  deptId: string,
  projectId: string,
  stepId: string,
  executor: string,
  timestamp: number
}
```

### 群聊任务事件

```javascript
{ type: 'task_created', task: { id, title, assignee, status, priority, deadline } }
{ type: 'task_updated', task: { id, status, updatedAt } }
{ type: 'task_blocked', task: { id, problems: [...] } }
{ type: 'task_progress_updated', task: { id, progress, updatedAt } }
{ type: 'task_notification', userId, notification: { type, taskId, title, message, ... } }
```

### 个人任务流水线事件

```javascript
{ type: 'board_update', event: 'personal_task_created', data: { deptId, taskId, title, triggered_by, steps, status } }
{ type: 'board_update', event: 'personal_task_started', data: { deptId, taskId, title, currentStep } }
{ type: 'board_update', event: 'personal_task_step_update', data: { deptId, taskId, stepId, stepName, oldStatus, newStatus, progress } }
{ type: 'board_update', event: 'personal_task_completed', data: { deptId, taskId, title, steps, forced? } }
{ type: 'board_update', event: 'personal_task_stall_alert', data: { deptId, taskId, title, severity: 'warning'|'critical', message } }
```

---

## 六、EventBus 事件

### 已实现

```javascript
// 旧看板
'task.status.changed'           // moveTask 触发
'task.box.update'                // TaskBoxWatcher 文件变化

// 群聊任务
'task.created'                   // confirmTask
'task.updated'                   // updateTaskStatus
'task.blocked'                   // addProblem

// 流水线
PIPELINE_STEP_STARTED            // pipeline_state.json 步骤开始
PIPELINE_PROJECT_COMPLETED       // 所有步骤通过
BOARD_UPDATE                     // 一般看板更新

// 个人任务
PERSONAL_TASK_CREATED            // 创建
PERSONAL_TASK_STARTED            // 开始执行
PERSONAL_TASK_STEP_UPDATE        // 步骤状态变更
PERSONAL_TASK_COMPLETED          // 完成
```

---

## 七、BoardController 依赖注入

```javascript
constructor(dependencies) {
  this.taskBoxWatcher  // TaskBoxWatcher 实例 → getDepartmentTasks, calculateHealthStatus
  this.eventBus        // EventBus → 发布催促事件
  this.wsManager       // WS 管理器 → 广播催促
}
```

### 私有辅助方法

| 方法 | 行号 | 说明 |
|------|------|------|
| `_getDepartmentsList()` | 38 | 扫描 departments/ 目录 (10min 缓存) |
| `_getWorkspaceRoot()` | 428 | 获取工作区根路径 |
| `_readPipelineState(filePath)` | 439 | 读取 pipeline_state.json |
| `_extractPipelineSummary(data)` | 455 | 从 pipeline 提取摘要 (status, currentStep, progress, guardian) |
| `_getDeptProjectConfig(deptId)` | 518 | 读 team_config.json 获取路径配置 |
| `_scanProjects(deptId, dateFilter?)` | 552 | 扫描部门所有项目 |

---

## 八、任务意图检测 (TaskDetector)

### 关键词定义

```javascript
TASK_KEYWORDS = {
  create:   ['任务：', '任务:', '帮我做', '请处理', '安排', '分配给'],
  complete: ['请验收', '已完成', '完成了', '做完了', '提交验收'],
  problem:  ['问题：', '问题:', '卡在', '需要帮助', '阻塞', '遇到困难'],
  cancel:   ['取消任务', '撤回任务', '不做了'],
  accept:   ['接收任务', '我来做', '开始做'],
  update:   ['进度更新', '进度：', '进度:', '完成进度']
}
```

### 优先级推断

```javascript
urgent: ['紧急', '加急', '火急', '马上', '立即']
high:   ['重要', '优先', '尽快']
normal: ['正常', '一般']
low:    ['不急', '有空', '低优先级']
```

### 截止时间推断

```javascript
'今天'/'today'   → 当日 23:59
'明天'           → 次日 23:59
'本周'           → 周日 23:59
'3小时'          → now + 3h
'2天'            → now + 2d
默认              → 当日 18:00 (已过则次日 18:00)
```

---

## 九、关键设计决策

1. **新旧共存**: boardRoutes 中 `/departments` 已改为 `getDepartmentsWithPipeline`，旧 `/tasks` 等路由保留兼容
2. **零数据库**: 全部基于文件系统，方便 Bot 和人工直接编辑
3. **动态部门发现**: 不硬编码部门列表，扫描 `departments/` 目录 + 10min 缓存
4. **催促频率限制**: 5 分钟冷却，防止用户连续催促
5. **双完成状态**: `_extractPipelineSummary()` 同时接受 `passed` (团队QC通过) 和 `completed` (个人任务) 作为完成
6. **Guardian 守护**: 个人任务 60s 检查一次心跳，超时标记 stalled，最多 3 次恢复后自动暂停
7. **催促链路**: 看板 POST nudge → EventBus → 群聊发消息 → WS 广播
8. **历史记录**: getProjects 自动扫描非今日目录（最近 7 天），按天分组返回
