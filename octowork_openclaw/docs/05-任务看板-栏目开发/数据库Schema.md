# 任务看板模块 — 数据库 Schema

> 任务看板**不使用 SQLite 数据库**，全部基于文件系统。  
> 最后更新: 2026-04-07（基于实际代码）

---

## 数据源概述

看板模块有 **三套文件数据源**，分别对应旧看板、团队流水线、个人任务：

| 数据源 | 用途 | 格式 | 位置 | 监控 |
|--------|------|------|------|------|
| task_box `.md` 文件 | 旧四列看板 + 任务卡可视化 | Markdown + YAML frontmatter | `departments/{dept}/task_box/{status}/` | `TaskBoxWatcher` chokidar |
| `pipeline_state.json` | 团队流水线 (新) | JSON | `departments/{dept}/project-workspace/Project/{YYYYMMDD}/{project_id}/00_项目任务卡/` | `TaskBoxWatcher.watchPipelineStates()` |
| `task_state.json` | 个人任务流水线 (新) | JSON | `departments/PersonalTasks/project-workspace/Task/{YYYYMMDD}/{task_id}/00_任务卡/` | 同上 (通过 team_config.json 自动识别) |

> **关键**: `BoardController._getDeptProjectConfig()` 读取 `team_config.json` 动态决定使用哪种路径和状态文件名。

---

## 一、task_box 文件 Schema（旧+兼容）

### 目录结构

```
departments/{deptId}/task_box/
├── pending/           ← 待处理
│   ├── 20260404_TokProject_02.md
│   └── TASK-20260404-A1B2-修复前端编译错误.md
├── in_progress/       ← 进行中
│   └── 20260404_TokProject_01.md
├── completed/         ← 已完成
│   └── (空)
└── accepted/          ← 已验收
    └── (空)
```

### .md 任务卡格式

```markdown
---
task_id: "20260404_TokProject_01"
project_id: "20260404_TokProject_01"
title: "KoriDerm 护肤霜短视频制作"
assigner: "management-octopus"
assignee: "TokVideoGroup"
priority: "high"
created_at: "2026-04-04T09:00:00+08:00"
deadline: "2026-04-04T18:00:00+08:00"
step_id: "step_c"
step_name: "Step-C 抽帧截图"
executor: "IMGP"
---

# KoriDerm 护肤霜短视频制作

## 基本信息

- **任务ID**：TASK-20260404-A1B2
- **分配人**：management-octopus
- **执行人**：IMGP
- **状态**：🔵 进行中
- **优先级**：🟠 HIGH
- **预计完成**：2026/4/4 18:00

## 任务要求
...

## 验收标准
- [ ] 功能完整
- [ ] 测试通过
- [ ] 文档齐全

## 进度
进度：45%

## 执行记录
- 2026/4/4 09:00 **Jason**: 任务创建

## ⚠️ 问题记录
（如有阻塞）
```

### TaskBoxWatcher 解析逻辑 (task_box_watcher.js 行 355-439)

```javascript
// 1. 从路径推断状态
//    departments/TokVideoGroup/task_box/in_progress/xxx.md
//                                       ↑ status
// 2. 提取 taskId: 文件名匹配 /^(TASK-\d{8}-[A-F0-9]+)/
// 3. 解析 Markdown:
//    - 标题: /^# (.+)$/m
//    - 基本信息块: /## 基本信息\n\n([\s\S]+?)\n\n##/m
//    - 从中提取: 任务ID, 分配人, 执行人, 创建时间, 优先级, 预计完成
//    - 进度: /进度：(\d+)%/
//    - 问题记录: /## ⚠️ 问题记录/m → hasProblems = true
```

### 健康度计算 (task_box_watcher.js 行 526-546)

```javascript
calculateHealthStatus(tasks) {
  if (tasks.length === 0) return 'green'
  const accepted = tasks.filter(t => t.status === 'accepted').length
  const blocked = tasks.filter(t => t.hasProblems).length
  const completionRate = accepted / tasks.length

  if (completionRate < 0.3 || blocked >= 2) return 'red'      // 红
  if (completionRate < 0.6 || blocked >= 1) return 'yellow'    // 黄
  return 'green'                                                // 绿
}
```

---

## 二、pipeline_state.json Schema（团队流水线）

### 文件位置

```
departments/{deptId}/project-workspace/Project/{YYYYMMDD}/{project_id}/
└── 00_项目任务卡/
    └── pipeline_state.json    ← 每个项目一份
```

### 完整 Schema

```json
{
  "schema_version": "1.0",
  "project_id": "20260404_TokProject_01",
  "created_at": "2026-04-04T09:00:00+08:00",
  "updated_at": "2026-04-04T14:30:00+08:00",

  "review_policy": {
    "mode": "supervised"
  },

  "assets": {
    "product_id": "PROD_KORIDERM_v1",
    "product_name": "KoriDerm 护肤霜",
    "brand": "KoriDerm",
    "category": "护肤品"
  },

  "pipeline": [
    {
      "step_id": "intel",
      "name": "竞品采集",
      "executor": "INTEL",
      "status": "passed",
      "started_at": "2026-04-04T09:05:00+08:00",
      "completed_at": "2026-04-04T09:35:00+08:00",
      "passed_at": "2026-04-04T09:40:00+08:00",
      "reject_count": 0,
      "max_rejects": 3
    }
  ],

  "event_log": [
    {
      "time": "2026-04-04T09:00:00+08:00",
      "actor": "DISP",
      "action": "project_created",
      "step": null,
      "detail": "项目立项完成"
    }
  ],

  "guardian": {
    "last_heartbeat": "2026-04-04T14:25:00+08:00",
    "stall_timeout_minutes": 15,
    "total_stall_recoveries": 0,
    "total_memory_recoveries": 2
  }
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `schema_version` | string | Y | 固定 `"1.0"` |
| `project_id` | string | Y | `{YYYYMMDD}_{DeptPrefix}Project_{NN}` |
| `created_at` | ISO8601 | Y | 项目创建时间 |
| `updated_at` | ISO8601 | Y | 最后更新时间 |
| `review_policy.mode` | string | N | 审核策略 (`supervised`/`autonomous`) |
| `assets` | object | N | 项目资产: `product_name, brand, category` 等 |
| `pipeline[]` | array | Y | 步骤数组 |
| `pipeline[].step_id` | string | Y | 步骤唯一标识 |
| `pipeline[].name` | string | Y | 步骤名称 |
| `pipeline[].executor` | string | Y | 执行者角色代号 |
| `pipeline[].status` | enum | Y | `blocked/ready/in_progress/completed/passed/rejected/failed` |
| `pipeline[].started_at` | ISO8601? | N | 开始时间 |
| `pipeline[].completed_at` | ISO8601? | N | 完成时间 |
| `pipeline[].passed_at` | ISO8601? | N | 通过时间 |
| `pipeline[].reject_count` | number | N | 已打回次数 |
| `pipeline[].max_rejects` | number | N | 最大打回次数 |
| `event_log[]` | array | Y | 事件日志数组 |
| `event_log[].time` | ISO8601 | Y | 事件时间 |
| `event_log[].actor` | string | Y | 执行者 |
| `event_log[].action` | string | Y | 事件类型 |
| `event_log[].step` | string? | N | 相关步骤 |
| `event_log[].detail` | string | Y | 事件描述 |
| `guardian.last_heartbeat` | ISO8601 | Y | 最后心跳时间 |
| `guardian.stall_timeout_minutes` | number | Y | 卡壳超时分钟数 |
| `guardian.total_stall_recoveries` | number | Y | 卡壳恢复次数 |
| `guardian.total_memory_recoveries` | number | Y | 失忆恢复次数 |

### 步骤状态机

```
blocked  ──(前置步骤passed)──→  ready
ready    ──(Bot开始执行)──→      in_progress
in_progress ──(Bot完成)──→      completed
completed ──(QC通过)──→         passed
completed ──(QC打回)──→         rejected
rejected  ──(Bot重做完成)──→    completed  (循环)
任何状态  ──(失败)──→           failed     (需人工介入)
```

---

## 三、task_state.json Schema（个人任务流水线）

### 文件位置

```
departments/PersonalTasks/project-workspace/Task/{YYYYMMDD}/{task_id}/
├── 00_任务卡/
│   ├── task_state.json      ← 状态文件
│   └── 00_任务卡.md          ← 可读 Markdown 版
├── 01_需求分析/              ← 步骤输出目录
├── 02_竞品调研/
├── 03_方案撰写/
└── 04_自检交付/
```

### 完整 Schema

```json
{
  "schema_version": "1.0",
  "task_id": "20260406_Task_01",
  "title": "撰写产品营销方案",
  "mode": "personal",
  "executor": "AI",
  "triggered_by": "Jason",
  "created_at": "2026-04-06T10:00:00+08:00",
  "updated_at": "2026-04-06T10:15:00+08:00",
  "status": "in_progress",
  "original_message": "帮我写一个完整的产品营销方案...",

  "review_policy": {
    "mode": "autonomous",
    "checkpoint_after_each_step": true,
    "stall_timeout_minutes": 5
  },

  "pipeline": [
    {
      "step_id": "step_1",
      "name": "需求分析",
      "description": "分析产品特点和目标市场",
      "status": "completed",
      "output_dir": "01_需求分析/",
      "started_at": "2026-04-06T10:01:00+08:00",
      "completed_at": "2026-04-06T10:05:00+08:00"
    },
    {
      "step_id": "step_2",
      "name": "竞品调研",
      "description": "调研竞品的营销策略",
      "status": "in_progress",
      "output_dir": "02_竞品调研/",
      "started_at": "2026-04-06T10:05:00+08:00",
      "completed_at": null
    }
  ],

  "event_log": [
    {
      "time": "2026-04-06T10:00:00+08:00",
      "actor": "Jason",
      "action": "task_created",
      "detail": "任务创建: 撰写产品营销方案 (4 个步骤)"
    }
  ],

  "guardian": {
    "last_heartbeat": "2026-04-06T10:15:00+08:00",
    "stall_timeout_minutes": 5,
    "total_stall_recoveries": 0
  }
}
```

### 与 pipeline_state.json 的区别

| 对比 | pipeline_state.json (团队) | task_state.json (个人) |
|------|---------------------------|----------------------|
| 目录前缀 | `Project/` | `Task/` |
| 任务卡目录 | `00_项目任务卡/` | `00_任务卡/` |
| 状态文件名 | `pipeline_state.json` | `task_state.json` |
| 配置来源 | `team_config.json` (`project_dir`, `state_file`) | `pipeline_type: 'task'` |
| 完成状态 | `passed` (QC 通过) | `completed` (无 QC) |
| 执行者 | 多 Bot 协作 | AI 单独执行 |
| review_policy | `supervised` | `autonomous` |
| 步骤字段 | 有 `passed_at`, `reject_count`, `max_rejects` | 有 `description`, `output_dir` |
| pipeline ID | `project_id` | `task_id` |

---

## 四、pipeline 模板 Schema

### 文件位置

```
departments/{deptId}/templates/pipeline_template.json
```

### 模板格式

```json
{
  "schema_version": "1.0",
  "department": "TokVideoGroup",
  "pipeline_name": "TikTok 短视频生产流水线",
  "total_steps": 17,
  "pipeline": [
    { "step_id": "intel",    "name": "竞品采集",      "executor": "INTEL", "max_rejects": 3 },
    { "step_id": "entry_qc", "name": "入口质检",      "executor": "DISP",  "max_rejects": 3 }
  ]
}
```

> Octopus 创建项目时读取模板，填入项目信息，所有 `status` 初始化为 `blocked`（第一步为 `ready`），写入 `pipeline_state.json`。

---

## 五、归档数据 Schema

### 归档日志文件

```
archive/{deptId}/archive_log.json
```

```json
[
  {
    "project_id": "20260325_TokProject_01",
    "archived_at": "2026-04-02T02:00:00+08:00",
    "original_completed_at": "2026-03-25T17:30:00+08:00",
    "archive_path": "archive/TokVideoGroup/2026-03/20260325_TokProject_01.tar.gz",
    "size_bytes": 2048576
  }
]
```

---

## 六、team_config.json 关键字段

`BoardController._getDeptProjectConfig()` 从此文件动态读取部门项目配置：

```json
{
  "description": "OctoVideo 视频生产部",
  "team_name": "TokVideoGroup",
  "icon": "🎬",
  "emoji": "🎬",
  "project_dir": "Project",
  "state_file": "pipeline_state.json",
  "pipeline_type": "project"
}
```

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `project_dir` | `"Project"` | 项目工作区子目录名，个人任务为 `"Task"` |
| `state_file` | `"pipeline_state.json"` | 状态文件名，个人任务为 `"task_state.json"` |
| `pipeline_type` | `"project"` | 如果为 `"task"` → 任务卡目录使用 `00_任务卡` |
| `description` | `"{deptId} 部门"` | 部门描述 |
| `icon` / `emoji` | `"📁"` | 部门图标 |

---

## 七、文件监控机制 (TaskBoxWatcher)

### task_box 监控

```javascript
chokidar.watch(`departments/{dept}/task_box/`, {
  depth: 2,
  awaitWriteFinish: { stabilityThreshold: 100 }
})
// → add/change(.md) → parseTaskFromFile() → broadcastBoardUpdate('task_created'|'task_updated')
// → unlink(.md) → broadcastBoardUpdate('task_removed')
```

### pipeline_state.json 监控 (Phase 2)

```javascript
// 从 team_config.json 读取 project_dir 和 state_file
chokidar.watch(`departments/{dept}/project-workspace/{projectDir}/**/{stateFile}`, {
  depth: 5,
  awaitWriteFinish: { stabilityThreshold: 300 }  // 300ms 防抖
})
// → add/change → handlePipelineChange() (再 300ms 防抖)
//   → 解析 JSON → 计算 passed/total → WS 广播 pipeline_update
//   → EventBus 发布 (PIPELINE_PROJECT_COMPLETED 或 PIPELINE_STEP_STARTED)
```

### 广播格式

```javascript
// task_box 事件
{ type: 'board_update', event: 'task_created'|'task_updated'|'task_removed', data: {deptId, task}, timestamp }

// pipeline 事件
{ type: 'pipeline_update', deptId, projectId, currentStep, currentStepName, executor, progress: {passed, total}, guardian, updatedAt, timestamp }
```

---

## 八、设计要点

1. **零数据库依赖**: 所有数据存储在文件系统，可以用 `cat`/`jq` 直接查看和调试
2. **双路径兼容**: `BoardController._getDeptProjectConfig()` 通过 `team_config.json` 自动识别团队项目 vs 个人任务
3. **完成状态兼容**: `_extractPipelineSummary()` 同时接受 `passed` 和 `completed` 作为完成状态
4. **三级缓存**: 部门列表 10 分钟缓存; TaskBoxWatcher 的内存 Map; 前端 usePipeline reactive state
5. **防抖广播**: pipeline_state.json 变更使用 300ms 防抖，避免多次写入触发过量 WS 推送
6. **Guardian 守护**: 个人任务有 60s 间隔的 stall 检查，最多 3 次恢复后自动暂停
7. **task_box 双写**: 个人任务同时写入 task_state.json 和 task_box/{status}/xxx.md，保证旧看板兼容
