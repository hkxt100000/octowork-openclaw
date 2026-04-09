# OctoWork 部门文件夹标准规范手册 v1.1

> **文档性质**: 权威标准文档 — 所有 AI Agent 创建新团队、新项目时必须遵循本手册  
> **适用范围**: OctoWork 全平台所有部门  
> **黄金参考**: `TokVideoGroup`（Tok视频组）为当前唯一标准实现  
> **版本**: 1.1  
> **日期**: 2026-04-08  
> **维护者**: OctoWork 平台团队

---

## 目录

1. [核心原则](#1-核心原则)
2. [部门根目录标准](#2-部门根目录标准)
3. [项目工作区标准（任务看板关键）](#3-项目工作区标准任务看板关键)
4. [pipeline_state.json 状态文件标准](#4-pipeline_statejson-状态文件标准)
5. [team_config.json 团队配置标准](#5-team_configjson-团队配置标准)
6. [AI Agent 公寓标准（13目录体系）](#6-ai-agent-公寓标准13目录体系)
7. [Agent 命名规范（强制）](#7-agent-命名规范强制)
8. [任务看板自动识别机制](#8-任务看板自动识别机制)
9. [项目守护程序标准](#9-项目守护程序标准)
10. [自动化脚本](#10-自动化脚本)
11. [检查清单与验证](#11-检查清单与验证)
12. [常见错误案例](#12-常见错误案例)

---

## 1. 核心原则

### 1.1 团队适应标准，标准不迁就团队

> **铁律**: 任务看板的扫描逻辑是统一的、不可修改的。所有新团队必须按照标准格式创建目录和文件，而不是让系统去适配每个团队的特殊格式。

**原因**:
- 后续会有几十个部门，每个部门都自定义格式将导致系统无法维护
- 任务看板的 `boardController.js` 只有一套扫描逻辑
- AI Agent 独立创建项目时，必须有明确、唯一的标准可以遵循

### 1.2 目录即协议

每个目录名、文件名都是系统识别的"协议"。**命名不对 = 系统不认 = 看板不显示**。

### 1.3 黄金参考

当本文档与实际代码有任何歧义时，以 `TokVideoGroup` 的实际目录结构为准：
```
octowork/departments/TokVideoGroup/
```

---

## 2. 部门根目录标准

### 2.1 部门位置（必须）

```
octowork/departments/{DepartmentName}/
```

| 规则 | 说明 | 示例 |
|------|------|------|
| 路径 | 必须位于 `octowork/departments/` 下 | `octowork/departments/TokVideoGroup/` |
| 命名 | 英文，PascalCase 或连字符格式 | `TokVideoGroup`, `ReleaseOps`, `The-Brain` |
| 禁止 | 中文目录名、空格、特殊字符 | ~~`Tok视频组/`~~, ~~`release ops/`~~ |

### 2.2 部门根目录结构（必须）

```
{DepartmentName}/
├── README.md                    # [必须] 部门业务说明书
├── .permissions.json            # [必须] 部门权限配置
│
├── agents/                      # [必须] AI员工公寓目录
│   ├── team_config.json         # [必须] 团队配置（看板扫描入口）
│   ├── team_index.json          # [必须] 团队索引（机器可读）
│   ├── 01_{dept}_dispatcher_octowork/  # Agent公寓（见第6+7章，v1.1命名规范）
│   ├── 02_{dept}_assistant_octowork/
│   └── ...
│
├── config/                      # [必须] 部门配置中心
│   ├── department_config.json   # 部门总配置
│   └── ...自定义配置文件
│
├── docs/                        # [必须] 部门文档库
│   ├── SOP标准流程/
│   ├── 岗位职责/
│   ├── 内部通信指南.md
│   └── ...
│
├── chat_history/                # [必须] 群聊记录存储
│
├── task_box/                    # [必须] 部门任务箱
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
│
├── project-workspace/           # [必须] 项目工作区（看板核心）
│   └── Project/                 # [必须] 固定名称 "Project"
│       └── ...                  # 见第3章详细规范
│
└── teams/                       # [可选] 子团队配置
```

### 2.3 关键约束

| 项目 | 约束 | 说明 |
|------|------|------|
| `agents/team_config.json` | **必须存在** | 看板通过此文件识别部门配置 |
| `project-workspace/Project/` | **目录名必须是 `Project`** | 看板硬编码扫描此目录名（默认值） |
| `task_box/` | **必须有4个子目录** | 任务流转的标准状态 |
| `.permissions.json` | **必须存在** | 权限控制依据 |

---

## 3. 项目工作区标准（任务看板关键）

> **这是最关键的部分。看板能不能显示你的项目，100%取决于这里的目录结构是否正确。**

### 3.1 标准路径公式

```
project-workspace/Project/{YYYYMMDD}/{YYYYMMDD_ProjectName_NN}/00_项目任务卡/pipeline_state.json
```

**层级分解**:

| 层级 | 名称 | 格式要求 | 示例 |
|------|------|---------|------|
| L1 | project-workspace | 固定 | `project-workspace/` |
| L2 | Project | 固定名称 | `Project/` |
| L3 | 日期目录 | `YYYYMMDD` (8位数字) | `20260402/` |
| L4 | 项目目录 | `{YYYYMMDD}_{项目标识}` | `20260402_TokProject_01/` |
| L5 | 任务卡目录 | 固定 `00_项目任务卡` | `00_项目任务卡/` |
| L6 | 状态文件 | 固定 `pipeline_state.json` | `pipeline_state.json` |

### 3.2 完整目录结构示例（黄金参考）

以 TokVideoGroup 为标准：

```
project-workspace/
└── Project/                               # L2: 固定名称
    ├── README.md                          # 项目目录使用说明
    └── 20260402/                          # L3: 立项日期 (YYYYMMDD)
        └── 20260402_TokProject_01/        # L4: 项目目录
            ├── 00_项目任务卡/             # L5: 任务卡目录（看板核心）
            │   ├── 00_项目任务卡.md       #     项目任务总卡（Markdown）
            │   └── pipeline_state.json    # L6: 流水线状态（看板读取）
            ├── 01_产品分析报告/            # 业务步骤输出目录
            ├── 02_对标视频_已通过/
            ├── 03_拆解MD文档_待审核/
            ├── 04_拆解MD文档_已通过/
            ├── 05_改写MD文档_待审核/
            ├── 06_改写MD文档_已通过/
            ├── ...                        # 按团队流水线步骤定义
            └── 15_成品视频/
```

### 3.3 命名规则详解

#### 日期目录 (L3)
```
格式: YYYYMMDD
示例: 20260402, 20260408
说明: 使用项目立项日期，同一天多个项目放在同一个日期目录下
```

#### 项目目录 (L4)
```
格式: {YYYYMMDD}_{团队项目前缀}_{序号}
示例: 
  - 20260402_TokProject_01     (Tok视频组第1个项目)
  - 20260408_Release_v0.5.9    (发版团队v0.5.9版本项目)
  - 20260410_ContentProject_01  (内容团队第1个项目)

规则:
  - 必须以日期开头
  - 下划线分隔
  - 序号可以是数字(01, 02)或版本号(v0.5.9)
  - 不允许使用中文
```

#### 业务步骤目录
```
格式: {NN}_{步骤描述}/  或  {NN}_{步骤描述}_{状态后缀}/
示例:
  - 00_项目任务卡/         (必须，看板入口)
  - 01_产品分析报告/       (无状态后缀)
  - 03_拆解MD文档_待审核/  (待审核后缀)
  - 04_拆解MD文档_已通过/  (已通过后缀)

规则:
  - 两位数字编号开头 (00-99)
  - 00 号必须是项目任务卡目录
  - "_待审核" / "_已通过" 后缀用于QC流转
```

### 3.4 不同团队的项目目录示例

每个团队的业务步骤不同，但**框架结构完全一致**：

**视频团队 (TokVideoGroup)**:
```
20260402_TokProject_01/
├── 00_项目任务卡/           ← 必须
├── 01_产品分析报告/
├── 02_对标视频_已通过/
├── ...（视频生产流水线步骤）
└── 15_成品视频/
```

**发版团队 (ReleaseOps)**:
```
20260408_Release_v0.5.9/
├── 00_项目任务卡/           ← 必须
├── 01_版本构建/
├── 02_安全质检/
├── 03_发布推送/
└── 04_发布闭环/
```

**内容团队（假设）**:
```
20260410_ContentProject_01/
├── 00_项目任务卡/           ← 必须
├── 01_选题分析/
├── 02_内容撰写_待审核/
├── 03_内容撰写_已通过/
├── 04_视觉设计_待审核/
├── 05_视觉设计_已通过/
└── 06_发布推送/
```

### 3.5 看板扫描算法（boardController 行为说明）

```
扫描路径: departments/{deptId}/project-workspace/Project/

算法:
1. 列出 Project/ 下的所有子目录 → 这些是日期目录 (YYYYMMDD)
2. 对每个日期目录，列出子目录 → 这些是项目目录
3. 对每个项目目录，查找: {项目目录}/00_项目任务卡/pipeline_state.json
4. 如果找到 pipeline_state.json → 解析并显示在看板上
5. 如果没找到 → 项目显示为"pending"状态（无流水线数据）

关键路径:
  ✅ Project/20260402/20260402_TokProject_01/00_项目任务卡/pipeline_state.json
  ❌ Release/v0.5.9/release_state.json              (目录名不对)
  ❌ Project/v0.5.9/release_state.json              (无日期层+文件名不对)
  ❌ Project/20260402/xxx/task-cards/pipeline.json   (任务卡目录名不对)
```

---

## 4. pipeline_state.json 状态文件标准

### 4.1 文件位置（唯一）

```
{项目目录}/00_项目任务卡/pipeline_state.json
```

### 4.2 完整 Schema

```json
{
  "schema_version": "1.0",
  "project_id": "20260402_TokProject_01",
  "created_at": "2026-04-02T10:00:00+08:00",
  "updated_at": "2026-04-02T15:30:00+08:00",

  "review_policy": {
    "mode": "supervised",
    "modes_explained": {
      "supervised": "所有QC步骤必须人类在群里确认才能通过",
      "assisted": "AI先出审核结论，人类一键确认或否决",
      "autonomous": "AI自主审核，仅异常时@用户"
    },
    "human_required_steps": ["entry_qc", "QC-A", "QC-B", "exit_qc"],
    "auto_approved_steps": [],
    "confidence_threshold": 0.95,
    "transition_rules": {
      "after_consecutive_passes": 5,
      "require_user_unlock": true
    }
  },

  "assets": {
    "product_id": "PROD_XXX_v1",
    "product_image": "./01_产品分析报告/images/xxx.jpg",
    "character_id": "CHAR_XXX_v1",
    "character_path": "octowork/projects/OctoWork_VisualFactory/02_核心资产库/人物资产/CHAR_XXX_v1/"
  },

  "pipeline": [
    {
      "step_id": "step_a",
      "name": "Step-A 步骤描述",
      "executor": "ROLE_CODE",
      "depends_on": [],
      "status": "passed",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": "02_对标视频_已通过/",
      "output_dir": "03_拆解MD文档_待审核/",
      "approved_dir": "04_拆解MD文档_已通过/",
      "started_at": "2026-04-02T11:00:00+08:00",
      "completed_at": "2026-04-02T12:00:00+08:00",
      "passed_at": "2026-04-02T12:20:00+08:00"
    }
  ],

  "event_log": [
    {
      "time": "2026-04-02T10:00:00+08:00",
      "actor": "DISP",
      "action": "project_created",
      "detail": "项目立项完成"
    }
  ],

  "guardian": {
    "last_heartbeat": "2026-04-02T15:30:00+08:00",
    "stall_timeout_minutes": 15,
    "total_stall_recoveries": 0,
    "total_memory_recoveries": 0
  }
}
```

### 4.3 字段详细说明

#### 必须字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `schema_version` | string | 固定 `"1.0"` |
| `project_id` | string | **必须**，看板使用此字段作为项目唯一标识。格式与项目目录名一致 |
| `created_at` | ISO8601 | 项目创建时间 |
| `updated_at` | ISO8601 | 最后更新时间 |
| `pipeline` | array | 流水线步骤数组（看板核心数据源） |

#### pipeline 步骤字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `step_id` | string | 步骤唯一ID，如 `step_a`, `qc_b`, `exit_qc` |
| `name` | string | 步骤显示名称 |
| `executor` | string | 执行者角色代码（如 `DISP`, `STRAT`, `QC`）|
| `depends_on` | array | 前置依赖的 step_id 列表 |
| `status` | string | **状态值必须是以下之一**（见下表）|
| `reject_count` | number | 累计打回次数 |
| `max_rejects` | number | 最大打回次数上限 |

#### 状态值标准（铁律）

| status 值 | 含义 | 看板显示 |
|-----------|------|---------|
| `blocked` | 前置步骤未完成，不可执行 | 灰色/锁定 |
| `ready` | 前置条件满足，可以开始 | 绿色/就绪 |
| `in_progress` | 正在执行中 | 蓝色/进行中 |
| `pending_review` | 已完成，等待审核 | 黄色/待审核 |
| `passed` | **审核通过** | 绿色勾 ✅ |
| `completed` | **执行完成**（等价于 passed） | 绿色勾 ✅ |
| `rejected` | 被打回，需重做 | 红色 ❌ |
| `escalated` | 超限上报，需人工介入 | 红色警告 🚨 |

> **注意**: 看板计算完成进度时，只认 `passed` 和 `completed` 两个状态。不要使用 `approved`、`done`、`finished` 等自定义状态值！

### 4.4 禁止事项

| 禁止 | 原因 |
|------|------|
| 使用 `release_state.json` 作为文件名 | 看板只扫描 `pipeline_state.json` |
| 使用 `release_id` 替代 `project_id` | 看板用 `project_id` 做主键 |
| 使用 `approved` 作为 status | 看板不认该状态值（仅认 passed/completed） |
| 把状态文件放在项目根目录 | 必须放在 `00_项目任务卡/` 下 |

---

## 5. team_config.json 团队配置标准

### 5.1 文件位置（唯一）

```
agents/team_config.json
```

> 注意：是在 `agents/` 目录下，不是 `config/` 目录下。看板代码 `boardController.js` 从这个路径读取。

### 5.2 标准格式

```json
{
  "schema_version": "1.1",
  "description": "团队描述",
  "team_package_id": "department-id",
  "team_package_version": "1.0",
  "created_date": "2026-04-08",
  "updated_date": "2026-04-08",
  "package_type": "standard",
  "compatibility": {
    "min_openclaw_version": "1.0.0",
    "min_octowork_version": "1.0.0"
  },
  "license": "OctoWork Standard",
  "purchase_info": {
    "product_id": "team-xxx",
    "product_type": "ai_team_package",
    "display_name": "团队显示名",
    "description": "团队一句话描述",
    "pricing_tier": "standard",
    "requires_license": true
  },
  "teams": [
    {
      "team_id": "xxx-production",
      "team_name": "团队中文名",
      "team_name_en": "TeamEnglishName",
      "team_emoji": "🎬",
      "team_color": "#FF6B35",
      "team_leader": "dispatcher-octopus",
      "department": "部门中文名",
      "status": "active",
      "visibility": "public",
      "team_description": "团队详细描述",
      "members": [
        {
          "member_id": "dispatcher-octopus",
          "chinese_name": "调度章鱼",
          "english_name": "Dispatcher Octopus",
          "role": "调度总监",
          "emoji": "📚",
          "color": "#FF6B35",
          "is_leader": true,
          "status": "active",
          "workspace": "/path/to/agents/01_dispatcher-octopus/"
        }
      ]
    }
  ]
}
```

### 5.3 看板读取的关键字段

看板从 `team_config.json` 中读取以下信息：

| 字段路径 | 用途 |
|---------|------|
| `teams[0].team_emoji` | 部门在看板中的图标 |
| `teams[0].team_name` | 部门显示名称 |
| `teams[0].members` | 团队成员列表（头像、角色信息） |

### 5.4 不需要额外自定义字段

> **重要**: 不要在 team_config.json 中添加 `project_dir`、`state_file`、`flat_structure` 等自定义字段。系统使用默认值：`Project` + `pipeline_state.json` + `00_项目任务卡`。团队只需要按标准创建目录结构即可。

---

## 6. AI Agent 公寓标准（13目录体系）

每个 AI Agent 的"数字公寓"遵循统一的13目录结构：

### 6.1 公寓目录结构

```
agents/{NN}_{dept}_{role}_octowork/      ← v1.1 强制命名规范（见第7章）
├── .openclaw/                    # OpenClaw 工作区状态
│   └── workspace-state.json
│
├── SOUL.md                       # 灵魂: 性格/使命/沟通风格
├── IDENTITY.md                   # 身份: 职责/权限/工作流位置
├── AGENTS.md                     # 公寓使用指南: 记忆体系/安全边界
├── TOOLS.md                      # 工具库: 工具清单/调用方式
├── HEARTBEAT.md                  # 心跳: 当前状态/项目进度
├── MEMORY.md                     # 核心记忆: 关键知识/经验积累
├── USER.md                       # 用户关系: 汇报规则/协作协议
├── README.md                     # Agent 概述
├── team_config.json              # 个人配置（机器可读）
│
├── backups/                      # 备份目录
│   └── .index.json
├── config/                       # 个人配置
│   ├── .index.json
│   ├── .overview.md
│   ├── automation_config.json
│   ├── bot_config.json
│   ├── config.json
│   ├── intelligent_memory.json
│   ├── memory_config.json
│   └── tool_mappings.json
├── docs/                         # 个人文档
│   └── .index.json
├── ego/                          # 自我意识/系统提示
│   ├── .abstract
│   ├── .index.json
│   ├── .overview
│   └── system_prompt.md          # AI 系统加载用的提示词
├── evidence/                     # 工作证据
│   ├── .index.json
│   └── .timeline.json
├── learning/                     # 学习资料
│   ├── .index.json
│   ├── README.md
│   ├── case_studies/
│   ├── platform_guides/
│   ├── responsibilities/
│   ├── skill_development/
│   └── standard_learning/
├── memory/                       # 记忆系统
│   ├── .index.json
│   ├── long_term/
│   │   ├── failure_analysis/
│   │   ├── standard_evolution/
│   │   └── success_cases/
│   └── short_term/
│       ├── daily_logs/
│       ├── scratch/
│       └── task_tracking/
├── outputs/                      # 输出产物
│   ├── .catalog.md
│   └── .index.json
├── shadow/                       # 影子（内部状态）
│   └── .index.json
├── sop/                          # 标准操作流程
│   ├── .index.json
│   ├── WORKFLOW_AUTO.md
│   ├── communication_protocols.md
│   ├── task_handover.md
│   └── team_collaboration.md
├── task_box/                     # 个人任务箱
│   ├── .index.json
│   ├── completed/
│   ├── in_progress/
│   └── pending/
└── tools/                        # 工具脚本
    ├── .index.json
    ├── process_tools/
    │   └── project_guardian.py   # 项目守护脚本（调度角色必须）
    ├── task_tools/
    └── utilities/
```

### 6.2 Agent 公寓目录命名（旧格式，仅 TokVideoGroup 沿用）

TokVideoGroup 作为第一个创建的团队，使用了早期命名格式：
```
格式: {NN}_{功能名}-octopus
示例: 01_dispatcher-octopus, 02_intelligence-octopus
```
> **注意**: 此格式仅保留给 TokVideoGroup 历史兼容。**所有新创建的团队必须遵循第7章的强制命名规范**。

---

## 7. Agent 命名规范（强制）

> **⚠️ 本章为强制规范，所有新创建的团队和 Agent 必须严格遵守。**
> **违反此规范将导致 Agent 目录冲突、任务派发错误、看板显示异常。**

### 7.1 命名公式（铁律）

```
{NN}_{dept}_{role}_octowork
```

| 组成部分 | 格式要求 | 说明 |
|---------|---------|------|
| `{NN}` | 两位数字 `01`-`99` | 角色序号，全局唯一（同一团队内不重复） |
| `{dept}` | 部门英文缩写，全小写 | 部门标识符，确保跨团队唯一性 |
| `{role}` | 岗位英文名，全小写，下划线连接 | 描述该 Agent 的核心职能 |
| `octowork` | 固定后缀 | OctoWork 平台标识，区分其他系统的命名 |

### 7.2 编号分配规则

```
01 = 调度/总监 (dispatcher)    ← 团队 leader，必须是 01
02 = 助理/秘书 (assistant)     ← 团队 secretary
03-06 = 核心业务执行角色
07-08 = 质检/运营等支持角色
09+ = 扩展角色
```

### 7.3 标准命名示例

#### ReleaseOps（发版运维组）— 已执行新规范 ✅
```
01_releaseops_dispatcher_octowork    → 调度章鱼
02_releaseops_assistant_octowork     → 助理章鱼
03_releaseops_builder_octowork       → 构建章鱼
04_releaseops_quality_octowork       → 质检章鱼
05_releaseops_ops_octowork           → 运维章鱼
```

#### 假设新建：ContentTeam（内容创作组）
```
01_contentteam_dispatcher_octowork   → 调度章鱼
02_contentteam_assistant_octowork    → 助理章鱼
03_contentteam_writer_octowork       → 写作章鱼
04_contentteam_editor_octowork       → 编辑章鱼
05_contentteam_quality_octowork      → 质检章鱼
06_contentteam_publisher_octowork    → 发布章鱼
```

#### 假设新建：OctoMarketing（市场营销组）
```
01_octomarketing_dispatcher_octowork   → 调度章鱼
02_octomarketing_assistant_octowork    → 助理章鱼
03_octomarketing_strategist_octowork   → 策略章鱼
04_octomarketing_creative_octowork     → 创意章鱼
05_octomarketing_analyst_octowork      → 分析章鱼
```

### 7.4 为什么必须包含部门名（血的教训）

> **核心问题**: 如果不在 Agent 目录名中加入部门标识，不同团队的同名岗位会在系统层面产生冲突。

**真实案例 — OPS 命名冲突**：

| 团队 | Agent 目录名（旧格式） | 冲突点 |
|------|----------------------|--------|
| TokVideoGroup | `06_operation-octopus` | `operation` |
| ReleaseOps | `05_ops-octopus` (如果不加前缀) | `ops` |
| OctoTech-Team | `octotech-ops` | `ops` |

上述三个 Agent 都是"运营/运维"角色，如果不加部门前缀：
- 任务派发系统可能把 TokVideoGroup 的运营任务派给 ReleaseOps 的运维
- 群聊中 @ops 无法确定是哪个团队的 ops
- `team_config.json` 中 member_id 重复导致看板渲染异常

**正确的区分方式**：
```
TokVideoGroup:   06_tokvideo_operation_octowork     ← 明确是视频组的运营
ReleaseOps:      05_releaseops_ops_octowork          ← 明确是发版组的运维
OctoTech-Team:   07_octotech_ops_octowork            ← 明确是技术组的运维
```

### 7.5 命名约束（不可违反）

| 规则 | 要求 | 示例 |
|------|------|------|
| 全小写 | 目录名全部小写字母 | ✅ `01_releaseops_dispatcher_octowork` |
| 下划线分隔 | 四个部分用下划线连接 | ❌ `01-releaseops-dispatcher-octowork` |
| 无中文 | 目录名不允许中文字符 | ❌ `01_发版组_调度_octowork` |
| 无空格 | 不允许空格 | ❌ `01_releaseops_dispatcher octowork` |
| dept 缩写 | 必须能唯一识别部门（建议≤15字符） | `releaseops`, `tokvideo`, `contentteam` |
| octowork 后缀 | 必须以 `_octowork` 结尾 | ❌ `01_releaseops_dispatcher` |
| 01 必须是 leader | 01号 Agent 必须是调度/总监角色 | ✅ `01_xxx_dispatcher_octowork` |

### 7.6 部门缩写对照表

| 部门全称 | 建议缩写 | 说明 |
|---------|---------|------|
| TokVideoGroup | `tokvideo` | 历史团队，沿用旧命名 |
| ReleaseOps | `releaseops` | ✅ 已采用新规范 |
| OctoAcademy | `octoacademy` | 待迁移 |
| OctoBrand | `octobrand` | 待迁移 |
| OctoGuard | `octoguard` | 待迁移 |
| OctoRed | `octored` | 待迁移 |
| OctoTech-Team | `octotech` | 待迁移 |
| OctoVideo | `octovideo` | 待迁移 |
| The-Arsenal | `arsenal` | 待迁移 |
| The-Brain | `brain` | 待迁移 |
| The-Forge | `forge` | 待迁移 |
| skill-market-team | `skillmarket` | 待迁移 |

### 7.7 team_config.json 中的 member_id 关联

`team_config.json` 中的 `member_id` 必须与 Agent 目录名中的 `{role}` 部分对应，并加上 `{dept}-` 前缀以保持唯一：

```json
{
  "member_id": "releaseops-dispatcher-octopus",
  "workspace": "agents/01_releaseops_dispatcher_octowork/"
}
```

### 7.8 AI Agent 自动创建时的命名流程

```
AI 收到创建新团队指令
    ↓
1. 确定部门英文名 → 生成 dept 缩写（全小写，去除连字符）
2. 确定各岗位角色 → 生成 role 名称（全小写，下划线连接）
3. 按编号规则分配 NN（01=leader, 02=assistant, 03+=业务角色）
4. 组合: {NN}_{dept}_{role}_octowork
5. 验证: 全局搜索是否有同名 Agent → 无冲突才可创建
6. 写入 team_config.json 和 team_index.json
```

### 7.9 旧团队迁移策略

对于 TokVideoGroup 等已有团队，可以选择：
- **方案A（推荐暂不迁移）**: 保持现有命名，但在 `team_config.json` 的 `member_id` 中加上部门前缀避免冲突
- **方案B（完整迁移）**: 将 Agent 目录重命名为新格式，同时更新所有引用路径

> 迁移时必须同步更新: `team_config.json`、`team_index.json`、`.permissions.json`、所有 Agent 的 `IDENTITY.md` 和 `ego/system_prompt.md`。

---

## 8. 任务看板自动识别机制

### 7.1 识别流程

```
boardController 启动
    ↓
扫描 octowork/departments/ 下所有目录
    ↓
对每个部门，检查: agents/team_config.json 是否存在
    ↓ (存在)
读取 team_config.json → 获取团队信息(名称/图标/成员)
    ↓
扫描: project-workspace/Project/ 目录
    ↓
遍历日期目录(YYYYMMDD) → 遍历项目目录 → 查找 00_项目任务卡/pipeline_state.json
    ↓
解析 pipeline_state.json → 提取进度/状态 → 显示在看板
```

### 7.2 一个项目在看板上显示的必要条件

必须同时满足以下所有条件：

- [ ] 1. 部门目录存在: `octowork/departments/{DeptName}/`
- [ ] 2. 团队配置存在: `agents/team_config.json`
- [ ] 3. 项目工作区存在: `project-workspace/Project/`
- [ ] 4. 日期目录格式正确: `Project/{YYYYMMDD}/`
- [ ] 5. 项目目录是合法目录（非文件）
- [ ] 6. 任务卡目录存在: `{项目目录}/00_项目任务卡/`
- [ ] 7. 状态文件存在: `00_项目任务卡/pipeline_state.json`
- [ ] 8. JSON 格式有效，包含 `project_id` 字段
- [ ] 9. `pipeline` 数组存在
- [ ] 10. 步骤 status 使用标准值 (`passed`/`completed`/`in_progress`...)

**缺少任何一项 → 看板不显示该项目。**

---

## 9. 项目守护程序标准

### 8.1 项目守护脚本 (project_guardian.py)

每个团队的调度角色(01_dispatcher-octopus)必须配备项目守护脚本。

**存放位置**:
```
agents/01_dispatcher-octopus/tools/process_tools/project_guardian.py
```

**核心功能**:

| 命令 | 功能 | 调用者 |
|------|------|--------|
| `--action status` | 输出流水线状态摘要 | DISP/ASST |
| `--action recover` | 失忆恢复（≤500字上下文） | ASST |
| `--action advance` | 推进流水线（解锁/检测超时） | ASST |
| `--action next` | 生成下一步任务卡 | ASST |
| `--action update --step X --new-status Y` | 更新步骤状态 | ASST |

**调用方式**:
```bash
python project_guardian.py --project-dir <项目完整路径> --action status
```

### 8.2 状态机规则

合法的状态跳转（门禁规则）：

```
blocked → ready            (前置条件满足时自动跳转)
ready → in_progress        (Agent领取任务开始执行)
in_progress → pending_review  (执行完成提交审核)
pending_review → passed    (审核通过)
pending_review → rejected  (审核打回)
rejected → in_progress     (重新执行)
rejected → escalated       (打回超限，自动升级)
escalated → in_progress    (人工干预后重新执行)
passed → (终态)            (不可逆)
```

### 8.3 各团队自定义守护脚本的要求

| 必须保留 | 可以自定义 |
|---------|-----------|
| `load_state()` 从 `00_项目任务卡/pipeline_state.json` 读取 | `MIGRATION_MAP` 按团队步骤自定义 |
| `VALID_STATUSES` 使用标准状态值 | `action_next_task()` 中的任务卡格式 |
| `update_step_status()` 的门禁逻辑 | 超时阈值 `stall_timeout_minutes` |
| `compute_ready_steps()` 依赖检查 | 恢复上下文的文案内容 |
| `action_advance()` 的推进逻辑 | 事件日志的 detail 描述 |

---

## 10. 自动化脚本

### 10.1 新部门创建脚本

下面的脚本放置在 `docs/05-任务看板-栏目开发/部门标准手册/scripts/` 目录下：

> 参见同目录下的 `create_department.sh` 脚本

### 10.2 新项目创建脚本

> 参见同目录下的 `create_project.sh` 脚本

### 10.3 目录结构验证脚本

> 参见同目录下的 `validate_structure.py` 脚本

---

## 11. 检查清单与验证

### 11.1 新部门上线前检查清单

```
[部门根目录]
□ octowork/departments/{DeptName}/ 存在
□ README.md 存在
□ .permissions.json 存在且格式正确

[Agent 配置]
□ agents/team_config.json 存在且格式正确
□ agents/team_index.json 存在
□ 至少有1个 Agent 公寓
□ Agent 公寓命名符合规范: {NN}_{dept}_{role}_octowork（见第7章）
□ 每个 Agent 公寓包含标准13目录结构

[项目工作区]
□ project-workspace/Project/ 目录存在
□ Project/ 下有模板目录 YYYYMMDD/YYYYMMDD_ProjectName_NN/

[任务箱]
□ task_box/ 目录存在
□ task_box/.index.json 存在
□ task_box/pending/ 存在
□ task_box/in_progress/ 存在
□ task_box/completed/ 存在
□ task_box/accepted/ 存在

[配置中心]
□ config/ 目录存在
□ docs/ 目录存在
```

### 11.2 新项目上线前检查清单

```
[目录结构]
□ Project/{YYYYMMDD}/ 日期目录已创建 (8位数字)
□ {YYYYMMDD}_{ProjectName}/ 项目目录已创建
□ 00_项目任务卡/ 目录存在
□ 所有业务步骤目录已创建

[状态文件]
□ 00_项目任务卡/pipeline_state.json 存在
□ JSON 格式有效
□ 包含 project_id 字段
□ project_id 与项目目录名一致
□ pipeline 数组存在且非空
□ 所有 status 使用标准值 (blocked/ready/in_progress/pending_review/passed/completed/rejected/escalated)
□ 不包含 approved/done/finished 等非标准状态值

[守护程序]
□ project_guardian.py 存在
□ MIGRATION_MAP 已按团队步骤配置
□ 可以正常运行 --action status
```

---

## 12. 常见错误案例

### 案例1: ReleaseOps 看板不显示

**问题**: ReleaseOps 团队创建的项目在看板中不显示。

**根因分析**:

| 错误项 | 错误值 | 正确值 |
|--------|--------|--------|
| 顶层目录名 | `Release/` | `Project/` |
| 无日期层目录 | 直接 `v0.5.9/` | `20260406/20260406_Release_v0.5.9/` |
| 任务卡目录 | `task-cards/` | `00_项目任务卡/` |
| 状态文件名 | `release_state.json` | `pipeline_state.json` |
| 主键字段 | `release_id` | `project_id` |
| 完成状态值 | `approved` | `passed` 或 `completed` |

**修复**: 按照标准重建目录结构，不修改看板代码。

### 案例2: 其他常见创建错误

```
❌ project-workspace/项目/          (中文目录名)
❌ project-workspace/Projects/      (多了个s)
❌ project-workspace/Project/v1.0/  (不是YYYYMMDD格式)
❌ 00_任务卡/pipeline.json          (文件名不对)
❌ pipeline_state.json 放在项目根目录  (应在00_项目任务卡/下)
❌ status: "approved"               (应为 passed 或 completed)
❌ status: "done"                   (非标准值)
```

### 案例3: Agent 命名冲突（ops 团队名称碰撞）

**问题**: 多个团队都有"运营/运维"角色，使用旧格式（不含部门名）导致系统无法区分。

**冲突现场**:

| 团队 | Agent 目录名（旧格式） | member_id |
|------|----------------------|----------|
| TokVideoGroup | `06_operation-octopus` | `operation-octopus` |
| ReleaseOps（如用旧格式）| `05_ops-octopus` | `ops-octopus` |
| OctoTech-Team | `noctotech-ops` | `ops` |

**故障表现**:
1. 群聊中 @运营章鱼 → 系统不知道调用哪个团队的运营
2. 任务派发 API 用 member_id 匹配 → 错误地把视频运营任务派给了发版运维
3. 看板 `team_config.json` 成员去重逻辑按 member_id → 只显示了一个运营角色

**根因**: Agent 目录名和 member_id 中没有包含部门标识，导致全局不唯一。

**修复**: 采用 v1.1 强制命名规范（第7章）：

```diff
- 06_operation-octopus          (TokVideoGroup 旧格式)
+ 06_tokvideo_operation_octowork  (如果迁移到新格式)

- 05_ops-octopus                (ReleaseOps 旧格式，已修复)
+ 05_releaseops_ops_octowork     ✅ (已执行新规范)

- noctotech-ops                 (OctoTech 旧格式)
+ 07_octotech_ops_octowork       (如果迁移到新格式)
```

### 案例4: 常见 Agent 命名错误

```
❌ 01-releaseops-dispatcher-octowork    (用了连字符而非下划线)
❌ 01_ReleaseOps_Dispatcher_octowork    (大小写不规范)
❌ 01_releaseops_dispatcher             (缺少 _octowork 后缀)
❌ 01_dispatcher_octowork               (缺少部门名)
❌ releaseops_01_dispatcher_octowork    (编号不在最前面)
❌ 01_发版组_调度_octowork               (包含中文)

✅ 01_releaseops_dispatcher_octowork    (正确格式)
```

---

## 附录A: 快速参考卡

### 创建新团队的最小步骤

```bash
# 1. 创建部门目录
DEPT="NewTeamName"
BASE="octowork/departments/$DEPT"

# 2. 创建必须目录
mkdir -p $BASE/{agents,config,docs,chat_history,teams}
mkdir -p $BASE/task_box/{pending,in_progress,completed,accepted}
mkdir -p $BASE/project-workspace/Project

# 3. 创建必须文件
# → agents/team_config.json (见第5章)
# → agents/team_index.json
# → .permissions.json
# → README.md
# → task_box/.index.json

# 4. 创建至少1个Agent公寓 (见第6+7章)
# → agents/01_{dept}_dispatcher_octowork/... (v1.1命名规范+13目录体系)
```

### 创建新项目的最小步骤

```bash
# 1. 确定日期和项目名
DATE="20260408"
PROJECT="${DATE}_ProjectName_01"
DEPT="TeamName"
BASE="octowork/departments/$DEPT/project-workspace/Project"

# 2. 创建标准目录
mkdir -p "$BASE/$DATE/$PROJECT/00_项目任务卡"

# 3. 创建 pipeline_state.json (见第4章)
# 必须包含: project_id, pipeline 数组, 标准 status 值

# 4. 创建业务步骤目录 (按团队流水线定义)
mkdir -p "$BASE/$DATE/$PROJECT/01_步骤一"
mkdir -p "$BASE/$DATE/$PROJECT/02_步骤二_待审核"
# ...
```

---

## 附录B: 看板代码关键路径速查

| 功能 | 文件 | 方法 |
|------|------|------|
| 部门列表 | `boardController.js` | `getAllDepartments()` |
| 项目扫描 | `boardController.js` | `_scanProjects()` |
| 状态解析 | `boardController.js` | `_extractPipelineSummary()` |
| 配置读取 | `boardController.js` | `_getDeptProjectConfig()` |
| 流水线详情 | `boardController.js` | `getPipeline()` |

---

> **本文档是 OctoWork 部门创建的权威标准。任何 AI Agent 在创建新团队或新项目时，必须严格遵循本手册的规范。如有疑问，以 TokVideoGroup 的实际目录结构为最终参考。**
