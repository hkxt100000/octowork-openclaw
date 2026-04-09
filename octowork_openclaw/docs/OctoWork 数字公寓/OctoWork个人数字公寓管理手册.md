# 🏢 OctoWork 个人数字公寓管理手册

## ⚠️ OctoWork根目录个人公寓层必备标准
**核心要求**: 所有AI员工个人公寓必须位于OctoWork根目录下的 `departments/{部门名}/agents/{agent-id}/` 路径中

### 🎯 OctoWork个人公寓层必备验证
- ✅ **路径要求**: 必须位于 `OctoWork/departments/{部门名}/agents/{agent-id}/`
- ✅ **Agent命名**: agent-id必须使用小写英文连字符格式（如：`chief-commander-octopus`）
- ✅ **14个目录**: 必须包含所有14个核心目录（见下表）
- ✅ **7个身份文件**: 根目录必须有7个核心身份文件（SOUL.md等）

### 📁 OctoWork个人公寓标准位置
```
OctoWork/                          ← OctoWork根目录（公司公寓层）
├── departments/                  ← 部门公寓层
│   └── The-Brain/               ← 部门层
│       └── agents/              ← 个人公寓层
│           └── chief-commander-octopus/ ← AI员工个人公寓
│               ├── SOUL.md              ← 必备身份文件
│               ├── USER.md              ← 必备身份文件
│               ├── IDENTITY.md          ← 必备身份文件
│               ├── TOOLS.md             ← 必备身份文件
│               ├── AGENTS.md            ← 必备身份文件
│               ├── HEARTBEAT.md         ← 必备身份文件
│               ├── MEMORY.md            ← 必备身份文件
│               ├── chat_history/        ← 必备目录
│               ├── config/              ← 必备目录
│               ├── docs/                ← 必备目录
│               ├── ego/                 ← 必备目录
│               ├── memory/              ← 必备目录
│               └── ...其他必备目录
└── ...其他公司层目录
```

**严禁**: 在非标准路径创建个人公寓、缺少必备目录或身份文件、使用非标准命名

> **版本**: V4.0 (整合记忆系统版)  
> **创建时间**: 2026-03-09 03:30 GMT+8  
> **最后更新**: 2026-03-21 22:40 GMT+8  
> **适用范围**: 所有OpenClaw用户，所有AI团队  
> **核心目标**: 提供完整的数字公寓目录结构标准和记忆系统部署指南
> **使命**: 让每个AI团队都有标准化的数字家园和智能记忆系统

---

## 🎯 手册使用说明

### **谁应该阅读本手册？**
- **新团队创建者**: 需要建立标准化AI团队
- **个人用户**: 想要规范的AI助手环境  
- **团队管理者**: 需要统一的团队协作标准
- **开发者**: 想要了解OctoWork架构设计

### **如何使用本手册？**
1. **第一步**: 按目录结构创建数字公寓
2. **第二步**: 按文件规范编写初始文档
3. **第三步**: 集成OctoWork智能记忆系统
4. **第四步**: 添加岗位专业技能

### **核心原则**
- **标准化**: 所有公寓使用相同目录结构
- **模块化**: 每个目录有明确职责
- **可扩展**: 支持从小型到大型团队
- **文档化**: 所有操作有标准文档
- **文件管理**: 不随地大小便，临时文件及时清理，保持公寓整洁

---

## 📁 标准公寓目录结构

### **一级目录 (14个核心目录)**

| 序号 | 目录 | 英文名 | 核心职责 | 必须存在 |
|------|------|--------|----------|----------|
| 1 | `.openclaw/` | runtime | OpenClaw运行时配置 | ✅ |
| 2 | `backups/` | backups | 自动备份系统 | ✅ |
| 3 | `config/` | config | 配置中心 | ✅ |
| 4 | `docs/` | docs | 文档库 | ✅ |
| 5 | `ego/` | ego | 身份档案 | ✅ |
| 6 | `chat_history/` | chat | 聊天记录 | ✅ |
| 7 | `evidence/` | evidence | 证据文件 | ✅ |
| 8 | `learning/` | learning | 学习材料 | ✅ |
| 9 | `memory/` | memory | OctoWork记忆系统 | ✅ |
| 10 | `outputs/` | outputs | 输出结果 | ✅ |
| 11 | `shadow/` | shadow | 影子学习系统 | ✅ |
| 12 | `sop/` | sop | 标准操作程序 | ✅ |
| 13 | `task_box/` | task_box | 任务管理 | ✅ |
| 14 | `tools/` | tools | 自动化工具和脚本 | ✅ |

### **📝 根目录核心身份文件说明**
**重要更新**：由于OpenClaw运行时特性，每次Agent重启时会在根目录自动生成以下7个核心身份文件。这些文件是Agent的身份权威源，`ego/`目录仅存放摘要和配置。

**根目录必须存在的7个文件**：
1. `SOUL.md` - 灵魂文件（包含行为准则和沟通风格）
2. `USER.md` - 用户理解（对Jason的认知和沟通方式）
3. `IDENTITY.md` - 自我认知（Agent的岗位、职责、性格）
4. `TOOLS.md` - 工具笔记（本地环境特定配置）
5. `AGENTS.md` - 代理规则（工作空间行为规范）
6. `HEARTBEAT.md` - 心跳检查（定期检查任务清单）
7. `MEMORY.md` - 长期记忆（重要决策和经验总结）

**读取优先级**：Agent启动时优先读取根目录的这些文件，`ego/`目录中的对应文件仅作为备份或历史版本。

### **二级目录详解**

#### **1. `.openclaw/` - OpenClaw运行时配置**
```
.openclaw/
├── config.json              # 运行时配置（自动生成）
├── workspace.json          # 工作空间配置（自动生成）
└── sessions/               # 会话记录（自动生成）
```

**必须文件**: 均为自动生成，无需手动创建

#### **2. `backups/` - 自动备份系统**
```
backups/
├── .index.json             # 备份索引（手动创建）
├── apartment_backup_*.tar.gz # 完整公寓备份（自动生成）
├── config/                 # 配置文件备份
│   └── config_backup_YYYYMMDD_HHMMSS/
├── daily/                  # 每日备份（空目录）
├── weekly/                # 每周备份（空目录）
├── monthly/               # 每月备份（空目录）
└── logs/                  # 日志备份（空目录）
```

**初始文件**:
- `.index.json` (必须手动创建，见模板)
- 其他目录保持空，等待自动备份生成

#### **3. `config/` - 配置中心**
```
config/
├── .index.json             # 配置索引（必须）
├── automation_config.json  # 自动化任务配置（必须）
├── tool_mappings.json     # 工具技能映射（必须）
├── memory_config.json     # OctoWork记忆配置（必须）
├── bot_config.json        # Bot模型配置（必须）
├── config.json            # 基本身份配置（必须）
├── intelligent_memory.json # OctoWork智能记忆配置（必须）
└── .overview.md           # 配置概览（可选）
```

**必须文件** (7个):
1. `.index.json` - 配置索引
2. `automation_config.json` - 自动化配置
3. `tool_mappings.json` - 技能映射
4. `memory_config.json` - 记忆配置
5. `bot_config.json` - Bot配置
6. `config.json` - 基本配置
7. `intelligent_memory.json` - 智能记忆配置

#### **4. `docs/` - 文档库**
```
docs/
├── .index.json             # 文档索引（必须）
├── chat-modes.md          # 聊天模式参考文档（可选，已内置到聊天管理器）

```

**必须文件** (1个):
1. `.index.json` - 文档索引

**可选文件**:
- `chat-modes.md` - 聊天模式参考文档（已内置到聊天管理器）

#### **5. `ego/` - 身份档案（简化版）**
**重要说明**：由于OpenClaw运行时会在Agent根目录自动生成7个核心身份文件，因此`ego/`目录简化为仅存放配置和摘要文件。核心身份文件（SOUL.md、USER.md等）应位于Agent根目录。

```
ego/
├── .abstract              # 身份摘要（必须，L0层快速扫描）
├── .overview             # 身份概览（必须，L1层详细理解）
├── system_prompt.md      # 系统提示（必须，Agent启动时读取）
├── dna.json              # DNA配置（可选，个性化设置）
```

**必须文件** (3个):
1. `.abstract` - 身份摘要（L0层，~200 tokens）
2. `.overview` - 身份概览（L1层，~500 tokens）  
3. `system_prompt.md` - 系统提示（启动时加载）

**根目录核心身份文件** (OpenClaw自动生成):
- `SOUL.md` - 灵魂文件（必须，含沟通风格和行为准则）
- `USER.md` - 用户理解（必须）
- `IDENTITY.md` - 自我认知（必须）
- `TOOLS.md` - 工具笔记（必须）
- `AGENTS.md` - 代理规则（必须）
- `HEARTBEAT.md` - 心跳检查（可选）
- `MEMORY.md` - 长期记忆（必须）

#### **6. `chat_history/` - 聊天记录档案**
**核心价值**：存储用户与Agent最原始的实时对话记录，是智能记忆系统的重要数据源。

```
chat_history/
├── index.json            # 聊天记录索引（自动生成）
├── README.md            # 使用说明（可选）
├── 2026-03-15.md        # 按日期命名的原始对话文件
├── 2026-03-14.md        # 历史聊天记录
└── archive/             # 归档目录（可选）
    └── YYYY-MM/         # 按月归档
```

**文件格式**：
- 每日文件命名：`YYYY-MM-DD.md`
- 内容格式：Markdown，包含完整的时间戳、用户/AI标签、消息内容
- 自动生成：由双智能会话窗口清理引擎自动归档

**必须文件** (1个):
1. `index.json` - 聊天记录索引（自动生成）

**最佳实践**：
- 智能记忆系统优先分析`chat_history/`中的原始对话
- 定期归档旧文件到`archive/`目录
- 保持文件编码为UTF-8，确保中文字符正常显示

#### **7. `evidence/` - 证据文件**
```
evidence/
├── .timeline.json        # 时间线索引（必须）
├── .index.json           # 证据索引（必须）
├── essence_reports/      # 精华报告
│   ├── Ai智囊团 目录手册.md
│   ├── Ai智囊团 密钥管理.md
│   └── Bot数字公寓管理方案.md
├── archive/              # 历史归档
│   └── essence_YYYYMMDD_HHMMSS.md
├── completed_checklists/ # 已完成清单
│   ├── 调教清单_YYYYMMDD.md
│   └── 公寓结构整改完成_YYYYMMDD_HHMMSS.md
├── reports/              # 报告文件
│   ├── 专业整改报告.md
│   ├── 团队专业整改总结报告.md
│   └── 最终成果验证报告.md
├── decisions/            # 决策记录（空目录）
├── errors/               # 错误记录（空目录）
└── system_changes/      # 系统变更（空目录）
```

**必须文件** (2个):
1. `.timeline.json` - 时间线索引
2. `.index.json` - 证据索引
3. 其他目录可空，按需创建

#### **8. `learning/` - 学习材料**
```
learning/
├── .index.json           # 学习索引（必须）
├── README.md            # 学习系统说明（必须）
├── lessons/             # 学习点提取
│   ├── success_patterns_YYYY-MM-DD_batch*.json
│   └── failure_patterns_YYYY-MM-DD_batch*.json
├── patterns/            # 模式识别
│   └── pattern_report_YYYY-MM-DD_YYYYMMDD_HHMMSS.json
├── insights/            # 深度洞察（空目录）
└── archive/             # 历史学习归档（可选）
    └── YYYY-MM-DD/      # 按日期归档
```

**必须文件** (2个):
1. `.index.json` - 学习索引
2. `README.md` - 学习系统说明

#### **9. `memory/` - OctoWork记忆系统**
```
memory/
├── .index.json           # 记忆索引（必须，L0层）
├── short_term/           # 短期记忆
│   ├── current_status.json  # 实时状态（自动生成）
│   └── daily_logs/       # 每日日志
│       └── YYYY-MM/      # 按月组织
│           └── YYYY-MM-DD/
│               ├── summary.md   # L1摘要层（自动生成）
│               └── full.md      # L2完整层（自动生成）
└── archive/              # 归档记忆
    ├── daily_logs/       # 历史日志归档
    ├── health_reports/   # 健康报告归档
    └── long_term_backup/ # 长期记忆备份
```

**必须文件** (1个):
1. `.index.json` - 记忆索引
2. 其他文件自动生成

#### **10. `outputs/` - 输出结果**
```
outputs/
├── .index.json           # 输出索引（必须）
├── .catalog.md          # 输出目录说明（必须）
├── reports/             # 各类报告
│   ├── daily/           # 每日报告
│   │   └── YYYY-MM/     # 按月组织
│   │       └── YYYY-MM-DD_detailed_report.md
│   ├── professional/    # 专业报告
│   │   ├── 2026-03-08_公寓优化总结.md
│   │   └── Agent数字公寓教程模块设计方案V1.0.md
│   └── intelligent_memory/ # OctoWork智能记忆报告
│       ├── analysis_report_YYYYMMDD_HHMMSS.json
│       ├── status_report_YYYY-MM-DD.json
│       └── health_report_YYYYMMDD_HHMMSS.json
├── professional/        # 专业输出
│   ├── templates/       # 模板
│   │   └── 进度报告模板.md
│   ├── scripts/         # 脚本（空目录）
│   └── documents/       # 文档
│       ├── 风险管理机制.md
│       ├── 绩效评估体系.md
│       ├── 任务分配流程.md
│       └── 团队管理规范.md
├── data/                # 数据集（空目录）
└── archive/             # 输出归档（空目录）
```

**必须文件** (2个):
1. `.index.json` - 输出索引
2. `.catalog.md` - 输出目录说明

#### **11. `shadow/` - 影子学习系统**
```
shadow/
├── .index.json           # 影子索引（必须）
├── violations.json      # 违规记录（可选）
├── mistakes_learned/    # 错误学习（空目录）
├── bugs_fixed/          # 已修复问题（空目录）
└── improvement_plan/    # 改进计划（空目录）
```

**必须文件** (1个):
1. `.index.json` - 影子索引

#### **12. `sop/` - 标准操作程序**
```
sop/
├── .index.json           # SOP索引（必须）
├── WORKFLOW_AUTO.md     # 自动工作流程标准操作程序（必须，压缩恢复协议）
├── communication_protocols.md # 团队通信协议（必须）
├── task_handover.md     # 任务交接规范（必须）
└── team_collaboration.md # 团队协作指南（必须）
```

**必须文件** (5个):
1. `.index.json` - SOP索引
2. `WORKFLOW_AUTO.md` - 自动工作流程标准操作程序（包含压缩恢复协议）
3. `communication_protocols.md` - 团队通信协议
4. `task_handover.md` - 任务交接规范
5. `team_collaboration.md` - 团队协作指南

#### **13. `task_box/` - 任务管理**
```
task_box/
├── .index.json           # 任务索引（必须）
├── pending/             # 待处理任务（空目录）
├── in_progress/         # 进行中任务（空目录）
├── completed/           # 已完成任务（空目录）
└── archive/             # 历史任务归档（空目录）
```

**必须文件** (1个):
1. `.index.json` - 任务索引

#### **14. `tools/` - 自动化工具**
```
tools/
├── .index.json           # 工具索引（必须）
├── automation/          # 12个核心自动化工具 + 日志管理
│   ├── config_manager.py
│   ├── doc_manager.py
│   ├── identity_manager.py
│   ├── memory_manager.py
│   ├── task_manager.py
│   ├── shadow_manager.py
│   ├── backup_manager.py
│   ├── scheduler.py
│   ├── health_check.py
│   ├── auto_fixer.py
│   ├── performance_monitor.py
│   ├── cleanup_temp_files.py  # 临时文件自动清理（每3小时）
│   └── logs/            # 自动化日志目录（必须）
│       ├── .index.json  # 日志索引
│       └── scheduler.log # 调度器日志（自动生成）
├── intelligent_memory/  # OctoWork智能记忆系统
│   ├── core/           # 核心组件
│   ├── listeners/      # 监听器
│   ├── processors/     # 处理器
│   └── interfaces/     # 接口
├── scripts/            # 脚本工具
│   ├── memory_tools/   # 记忆工具
│   └── learning_tools/ # 学习工具
└── webhook_scripts/    # Webhook脚本（必须）
```

**必须文件** (1个):
1. `.index.json` - 工具索引
2. `automation/`目录下的12个核心工具（包含cleanup_temp_files.py）
3. `automation/logs/`目录 - 自动化日志目录（必须创建）
4. `webhook_scripts/`目录 - Webhook脚本目录（必须创建）

### **三级目录和文件规范**

#### **`.index.json` 文件规范**
每个目录的索引文件必须遵循以下结构：
```json
{
  "system_name": "OctoWork [目录名] 系统",
  "last_updated": "YYYY-MM-DD HH:MM:SS",
  "version": "V3.0",
  "total_files": 数字,
  "total_size": "大小",
  "directory_structure": {
    // 目录结构描述
  },
  "maintenance_notes": "维护说明"
}
```

#### **`.overview` 和 `.abstract` 文件规范**
- **`.overview`**: 详细概览，500-1000字
- **`.abstract`**: 简洁摘要，100-200字

#### **Markdown文档规范**
1. **文件命名**: 中文名为主，英文别名可选
2. **编码**: UTF-8
3. **行尾**: Unix (LF)
4. **最大长度**: 单文件不超过100KB
5. **结构**: 必须有标题和清晰结构

---

## 🧠 OctoWork记忆系统部署

### **系统概述**
OctoWork记忆系统是基于三层架构的智能记忆管理方案，实现Token使用效率优化74%、检索准确率提升146%的显著效果。系统采用L0/L1/L2分层加载机制，支持智能检索和自动提取。

### **三层架构设计**

#### **L0层 - 快速扫描 (~200 tokens)**
- **文件**: `.abstract`
- **用途**: 快速状态检查，了解当前核心信息
- **更新**: 实时或按需更新

#### **L1层 - 详细理解 (~500 tokens)**
- **文件**: `.overview`
- **用途**: 深入理解当前状态和任务进展
- **更新**: 每小时自动更新

#### **L2层 - 完整内容 (~2500 tokens)**
- **文件**: `full.md`
- **用途**: 完整记录和详细分析
- **更新**: 每6小时自动更新

### **目录结构规范**
```
memory/
├── short_term/          → 短期记忆
│   ├── .abstract       → L0层快速扫描文件
│   ├── .overview      → L1层详细理解文件  
│   └── daily_logs/    → L2层完整日志
│       └── YYYY-MM/
│           └── full.md
└── archive/            → 归档记忆
    ├── daily_logs/
    ├── health_reports/
    └── long_term_backup/
```

### **配置文件规范**
`config/memory_config.json` 必须包含以下配置：
```json
{
  "version": "2.0",
  "system": "OpenViking",
  "enabled": true,
  "layers": {
    "L0": {
      "type": "quick_scan",
      "max_tokens": 200,
      "update_interval": "realtime",
      "file": ".abstract"
    },
    "L1": {
      "type": "detailed_understanding",
      "max_tokens": 500,
      "update_interval": "1h",
      "file": ".overview"
    },
    "L2": {
      "type": "full_content",
      "max_tokens": 2500,
      "update_interval": "6h",
      "file": "full.md"
    }
  }
}
```

### **自动化工具套件**
`tools/automation/` 目录必须包含以下核心工具：
1. `memory_manager.py` - 记忆管理
2. `cleanup_temp_files.py` - 临时文件清理（每3小时）
3. `scheduler.py` - 任务调度器
4. `backup_manager.py` - 备份管理
5. `health_check.py` - 健康检查

### **调度规则**
```python
SCHEDULE = {
    "cleanup": {"interval": "3h", "command": "cleanup_temp_files.py"},
    "memory_extract": {"interval": "1h", "command": "memory_manager.py --extract"},
    "health_check": {"interval": "6h", "command": "health_check.py"},
    "backup": {"interval": "24h", "command": "backup_manager.py"}
}
```

### **实战案例：章鱼帝个人公寓**
以 `chief-commander-octopus` 公寓为例，成功部署的验证标准：

#### **✅ 已实现的特性**
1. **完整目录结构**: 14个标准目录 + `logs`实用目录
2. **记忆系统配置**: `config/memory_config.json` 配置正确
3. **自动化工具**: 11个核心工具部署完成
4. **运行状态**: 调度器正常执行定时任务

#### **⚠️ 注意事项**
1. **L0/L1文件缺失**: 实际运行中发现`.abstract`和`.overview`文件未自动生成，需要手动补全
2. **非标准目录**: `logs`目录虽非标准但实用，可作为扩展案例
3. **权限配置**: 工具执行权限需检查 `chmod +x tools/automation/*.py`

#### **🎯 部署验证命令**
```bash
# 检查目录完整性
find . -name ".index.json" -type f | wc -l

# 检查记忆系统
ls -la memory/short_term/

# 检查配置
cat config/memory_config.json | jq .

# 检查工具权限
ls -la tools/automation/*.py
```

### **常见问题解决**

#### **问题1: L0/L1层文件未生成**
**症状**: `memory/short_term/`目录缺少`.abstract`和`.overview`文件
**解决方案**:
```bash
# 手动创建初始文件
touch memory/short_term/.abstract
touch memory/short_term/.overview

# 运行记忆提取
python3 tools/automation/memory_manager.py --force-extract
```

#### **问题2: 调度器未启动**
**症状**: 定时任务未执行
**解决方案**:
```bash
# 检查调度器状态
ps aux | grep scheduler.py

# 手动启动
python3 tools/automation/scheduler.py &

# 检查日志
cat tools/automation/logs/scheduler.log
```

#### **问题3: 权限问题**
**症状**: 工具无法执行
**解决方案**:
```bash
# 修复权限
chmod -R 755 tools/automation/
chmod +x tools/automation/*.py
```

### **验收标准**
- [ ] L0/L1/L2三层文件完整
- [ ] 记忆配置文件正确
- [ ] 自动化工具可执行
- [ ] 调度器正常运行
- [ ] 健康检查通过

---

## 📝 文档编写标准

### **1. Markdown格式标准**

#### **标题层级**
```
# 一级标题 (h1) - 文档标题
## 二级标题 (h2) - 主要章节
### 三级标题 (h3) - 小节
#### 四级标题 (h4) - 子小节
```

#### **列表格式**
```markdown
- 无序列表项
- 另一个列表项

1. 有序列表第一项
2. 有序列表第二项
```

#### **表格格式**
```markdown
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| 内容 | 内容 | 内容 |
```

#### **代码块**
````markdown
```python
# Python代码
print("Hello World")
```

```bash
# Shell命令
ls -la
```

```json
{
  "key": "value"
}
```
````

### **2. 文档内容标准**

#### **SOUL.md 编写标准**
```markdown
# SOUL.md - [团队名]的灵魂

## 我们是谁
[团队介绍，核心价值观]



## 我们的说话方式
[沟通风格指南]

## 遇到问题怎么办
[问题处理流程]

## 强制三步判断法
[决策流程]

## 我们的记忆
[记忆系统使用说明]

## 我们的底线
[行为准则]
```

#### **USER.md 编写标准**
```markdown
# USER.md - [用户名]是谁

## 基本信息
[姓名、称呼、时区、语言等]

## [用户名]是什么样的人
[性格特点、工作风格]

## 跟[用户名]说话的方式
[沟通偏好]

## 他关注的项目
[重点项目列表]

## 他说过让我记住的话
[重要语录]

## 怎么联系他
[联系方式]

## 安全边界
[安全注意事项]
```

#### **IDENTITY.md 编写标准**
```markdown
# IDENTITY.md - 我是谁？

- **Name**: [名字]
- **Creature**: [AI/机器人/精灵等]
- **Vibe**: [氛围: 犀利/温暖/冷静等]
- **Emoji**: [标志性emoji]
- **Avatar**: [头像路径]

## 我的专长
[专业技能]

## 我的工作方式
[工作流程]

## 我的沟通风格
[说话特点]
```

### **3. 配置文件标准**

#### **config.json 标准**
```json
{
  "name": "Agent名称",
  "role": "角色描述",
  "version": "1.0",
  "created": "YYYY-MM-DD",
  "author": "创建者",
  "description": "简要描述"
}
```

#### **automation_config.json 标准**
```json
{
  "schedule": {
    "daily_health_check": {
      "enabled": true,
      "time": "09:00"
    },
    "daily_memory_extract": {
      "enabled": true,
      "time": "14:00"
    }
  },
  "monitoring": {
    "enabled": true,
    "alert_webhook": "可选"
  }
}
```

---





---

## 🚀 创建新数字公寓流程

### **第一步：创建目录结构**
```bash
# 1. 创建14个一级目录
mkdir -p .openclaw backups config docs ego chat_history evidence learning memory outputs shadow sop task_box tools

# 2. 创建二级目录
mkdir -p backups/{config,daily,weekly,monthly,logs}
mkdir -p evidence/{essence_reports,archive,completed_checklists,reports,decisions,errors,system_changes}
mkdir -p learning/{lessons,patterns,insights,archive}
mkdir -p memory/{short_term/{current_status,daily_logs},archive/{daily_logs,health_reports,long_term_backup}}
mkdir -p outputs/{reports/{daily,professional,intelligent_memory},professional/{templates,scripts,documents},data,archive}
mkdir -p shadow/{mistakes_learned,bugs_fixed,improvement_plan}
mkdir -p task_box/{pending,in_progress,completed,archive}
mkdir -p tools/{intelligent_memory/{core,listeners,processors,interfaces},scripts/{memory_tools,learning_tools},webhook_scripts}
```

### **第二步：创建必须文件**
```bash
# 1. 创建所有.index.json文件
touch backups/.index.json config/.index.json docs/.index.json ego/.index.json \
      evidence/.index.json learning/.index.json logs/.index.json memory/.index.json \
      outputs/.index.json shadow/.index.json task_box/.index.json tools/.index.json

# 2. 创建核心文档（复制到根目录，OpenClaw运行时读取）
cp templates/SOUL.md SOUL.md  # Agent灵魂文件
cp templates/USER.md USER.md
cp templates/IDENTITY.md IDENTITY.md
cp templates/TOOLS.md TOOLS.md
cp templates/AGENTS.md AGENTS.md
cp templates/HEARTBEAT.md HEARTBEAT.md

# 3. 创建配置文件
cp templates/config/* config/

# 4. 创建文档文件
cp templates/docs/* docs/
```

### **第三步：部署自动化工具**
```bash
# 部署11个核心自动化工具
cp -r templates/tools/automation/* tools/automation/

# 部署OctoWork智能记忆系统
cp -r templates/tools/intelligent_memory/* tools/intelligent_memory/

# 部署脚本工具
cp -r templates/tools/scripts/* tools/scripts/
```

### **第四步：初始化系统**
```bash
# 1. 运行配置检查
python3 tools/automation/config_manager.py --verify

# 2. 运行健康检查
python3 tools/automation/health_check.py

# 3. 初始化记忆系统
python3 tools/automation/memory_manager.py --init
touch memory/short_term/.abstract
touch memory/short_term/.overview

# 4. 启动调度器
python3 tools/automation/scheduler.py --daemon

# 5. 验证记忆系统
python3 tools/automation/memory_manager.py --verify
```

### **第五步：验证安装**
```bash


# 验证目录结构完整性
python3 tools/automation/verify_structure.py

# 生成验证报告
python3 tools/automation/generate_validation_report.py
```

---

## 🔧 质量检查清单

### **安装完成后必做检查**
- [ ] **目录结构**: 14个一级目录全部存在
- [ ] **必须文件**: 所有.index.json文件存在
- [ ] **SOUL.md**: 包含行为准则和沟通风格
- [ ] **配置文件**: 7个核心配置文件齐全
- [ ] **自动化工具**: 11个核心工具可执行
- [ ] **文档文件**: 5个核心文档存在

### **功能验证检查**

- [ ] **记忆系统验证**: OctoWork记忆正常工作
  - [ ] L0层: `memory/short_term/.abstract` 文件存在
  - [ ] L1层: `memory/short_term/.overview` 文件存在  
  - [ ] L2层: `memory/short_term/daily_logs/` 目录结构正确
  - [ ] 配置: `config/memory_config.json` 配置正确
  - [ ] 提取: 记忆提取工具正常工作
- [ ] **调度器验证**: 调度器能正常运行
  - [ ] 进程: 调度器进程在运行
  - [ ] 日志: 调度器日志正常记录
  - [ ] 任务: 定时任务按时执行
- [ ] **健康检查**: 健康检查通过（可能有预期警告）
  - [ ] 目录检查: 所有核心目录健康
  - [ ] 工具检查: 自动化工具可执行
  - [ ] 配置检查: 配置文件无错误

### **文档质量检查**
- [ ] **格式规范**: 所有文档符合Markdown标准
- [ ] **内容完整**: 关键信息无缺失
- [ ] **编码正确**: UTF-8编码，Unix行尾
- [ ] **链接有效**: 所有内部链接有效

---

## 🆘 常见问题解决

### **问题1: 目录结构不完整**
```bash
# 解决方案: 使用自动修复脚本
python3 tools/automation/auto_fixer.py --fix-directories
```



### **问题3: 配置文件缺失**
```bash
# 解决方案: 重新部署配置模板
cp templates/config/* config/ --force

# 重新初始化配置
python3 tools/automation/config_manager.py --init
```

### **问题4: 自动化工具不可执行**
```bash
# 解决方案: 修复执行权限
chmod +x tools/automation/*.py

# 重新部署工具
python3 tools/automation/deploy_tools_simple.py --force
```

### **问题5: 记忆系统L0/L1层文件缺失**
**症状**: `memory/short_term/`目录缺少`.abstract`和`.overview`文件
```bash
# 解决方案: 手动创建并初始化
touch memory/short_term/.abstract
touch memory/short_term/.overview
python3 tools/automation/memory_manager.py --force-extract
```

### **问题6: 记忆提取失败**
**症状**: 记忆提取工具报错或未生成内容
```bash
# 解决方案: 检查配置并手动触发
cat config/memory_config.json | jq .  # 检查配置
python3 tools/automation/memory_manager.py --debug  # 调试模式
python3 tools/automation/memory_manager.py --force-extract  # 强制提取
```

### **问题7: 调度器无法启动**
**症状**: 定时任务未执行，调度器进程不存在
```bash
# 解决方案: 检查日志并重启
cat tools/automation/logs/scheduler.log  # 检查错误
pkill -f "scheduler.py"  # 停止现有进程
python3 tools/automation/scheduler.py &  # 重新启动
ps aux | grep scheduler.py  # 验证进程
```

---

## 🔄 维护与升级

### **日常维护任务**
```bash
# 每日自动维护（配置在scheduler中）
python3 tools/automation/maintenance_daily.py

# 每周清理
python3 tools/automation/maintenance_weekly.py

# 每月归档
python3 tools/automation/maintenance_monthly.py
```

### **OctoWork系统升级**
```bash
# 检查更新
python3 tools/automation/check_updates.py --component octowork

# 备份当前系统
python3 tools/automation/backup_manager.py --full

# 执行升级
python3 tools/automation/upgrade_system.py --system octowork

# 验证升级
python3 tools/automation/health_check.py --post-upgrade
```

---

## 📝 文件管理规范

### **核心原则：不随地大小便**
AI团队在数字公寓中工作时，必须遵循以下文件管理规范：

#### **1. 临时文件及时清理**
- **定义**: 执行任务时生成的中间文件、调试日志、一次性脚本
- **生命周期**: 最长不超过24小时
- **清理机制**: 每3小时自动运行`cleanup_temp_files.py`
- **违规后果**: 临时文件堆积影响系统性能，降低团队效率

#### **2. 文件存放规范**
- **按目录存放**: 所有文件必须放在正确的目录中
- **禁止随地创建**: 不允许在根目录或随意位置创建文件
- **命名规范**: 文件名必须清晰表达内容，包含日期和用途
- **及时归档**: 完成任务后，相关文件及时归档到正确位置

#### **3. 自动清理规则**
```json
{
  "temp_scripts": "3小时清理一次",
  "temp_logs": "24小时清理一次", 
  "temp_outputs": "12小时清理一次",
  "webhook_temp": "1小时清理一次"
}
```

#### **4. 手动清理命令**
```bash
# 立即运行清理
python3 tools/automation/cleanup_temp_files.py --run

# 查看清理日志
cat tools/automation/logs/cleanup_log.json | jq .

# 检查临时文件
python3 tools/automation/cleanup_temp_files.py --dry-run
```

#### **5. 最佳实践**
1. **创建即计划删除**: 创建临时文件时，就计划好何时删除
2. **使用标准临时目录**: 临时文件统一放在`tmp/`或`tools/automation/temp/`
3. **记录文件用途**: 在文件开头注释说明用途和预期生命周期
4. **定期检查**: 每周检查一次文件系统，清理遗漏文件

#### **6. 违规处理**
- **第一次违规**: 系统警告，记录到`shadow/violations.json`
- **第二次违规**: 自动清理所有临时文件，强制学习文件管理规范
- **第三次违规**: 暂停自动化工具权限，需要人工恢复

**记住**: 整洁的数字公寓是高效AI团队的基础。不随地大小便，保持公寓清洁！

---

## 📈 高级配置选项

### **小型个人使用配置**
```json
{
  "retention_days": 7,
  "analysis_interval": 10,
  "min_importance": 0.8,
  "auto_cleanup": true
}
```

### **中型团队使用配置**
```json
{
  "retention_days": 30,
  "analysis_interval": 5,
  "min_importance": 0.7,
  "auto_cleanup": true,
  "team_collaboration": true
}
```

### **大型企业部署配置**
```json
{
  "retention_days": 90,
  "analysis_interval": 2,
  "min_importance": 0.6,
  "auto_cleanup": true,
  "team_collaboration": true,
  "enterprise_features": true,
  "audit_logging": true
}
```

---

## 🎯 总结

### **核心价值**
1. **标准化**: 统一目录结构，降低学习成本
2. **自动化**: 11个核心工具，减少手动操作
3. **可扩展**: 支持从个人到企业级部署
4. **文档化**: 完整文档体系，易于维护

### **成功标志**
✅ 14个一级目录结构完整  
✅ 所有必须文件存在且规范  
✅ 沟通风格定义清晰  
✅ 自动化工具正常运行  
✅ 文档符合编写标准  

### **开始行动**
现在就开始创建你的第一个OctoWork标准数字公寓：
```bash
# 最简单的启动方式
openclaw agent create --template octowork-standard --name "我的第一个AI助手"
```

**记住**: 标准化的数字公寓是高效AI团队管理的基础。从第一个公寓开始，就遵循OctoWork标准！

---

> **OctoWork使命**: 让每个AI团队都有标准化的数字家园  
> **我们的承诺**: 持续维护和更新本手册  
> **加入我们**: 一起构建更好的AI团队管理标准 🌟

**版本记录**:
- V4.0 (2026-03-21): 整合OctoWork记忆系统，增加实战案例和完整部署指南
- V3.1 (2026-03-09): 新增临时文件清理功能，Webhook脚本标准化，强化文件管理规范
- V3.0 (2026-03-09): 完全重写，专注于目录结构和文档标准
- V2.0 (2026-03-09): 重命名为OctoWork版本
- V1.0 (2026-03-08): 初始版本