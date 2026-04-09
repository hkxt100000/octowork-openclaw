# OctoWork 部门数字公寓框架标准结构2.0版

## ⚠️ OctoWork根目录部门层必备标准
**核心要求**: 所有部门必须位于OctoWork根目录下的`departments/`目录中，遵循统一命名规范

### 🎯 OctoWork部门层必备验证
- ✅ **路径要求**: 必须位于 `OctoWork/departments/{部门名}/`
- ✅ **目录命名**: 部门名必须使用英文连字符格式（如：`The-Brain`）
- ✅ **必备目录**: 每个部门必须包含 `agents/`、`config/`、`docs/` 核心目录
- ✅ **元数据**: 必须有 `department-metadata.json` 和 `.permissions.json` 配置文件

### 📁 OctoWork部门标准位置
```
OctoWork/                          ← OctoWork根目录（公司公寓层）
├── departments/                  ← 部门公寓层（必备）
│   ├── The-Brain/               ← 章鱼军团总部
│   ├── OctoTech-Team/           ← 技术研发部门
│   ├── The-Forge/               ← 产品锻造厂部门
│   ├── The-Arsenal/             ← 技能武器库部门
│   ├── OctoAcademy/             ← 章鱼学院部门
│   ├── OctoBrand/               ← 品牌营销部门
│   ├── OctoRed/                 ← 小红书内容部门
│   ├── OctoVideo/               ← 视频内容部门
│   └── OctoGuard/               ← 安全合规部门
└── ...其他公司层目录
```

**严禁**: 在非`departments/`目录创建部门、使用中文目录名、缺少必备配置文件

## 🚀 融合升级：业务映射 + 标准化自动识别

> **核心理念**：为全球10万+公司提供"业务可理解、系统可识别、扩展可持续"的部门级数字公寓框架

---

## 🎯 设计原则

### 1. 业务第一原则
- **目录即业务**：每个目录对应明确的业务职责和工作流
- **映射而非迁移**：对成熟团队采用映射方式，不强制文件迁移
- **特色化设计**：根据团队魂文档设计符合业务特色的目录结构

### 2. 标准化保障原则
- **自动识别**：所有部门必须能被Bot聊天管理器自动扫描和识别
- **配置驱动**：关键信息通过标准配置文件定义
- **权限可控**：多级权限管理，确保数据安全和协作效率

### 3. 扩展友好原则
- **分层设计**：公司层、部门层、个人公寓层清晰分离
- **全球兼容**：支持多语言、多区域、多时区配置
- **生态集成**：支持从AI员工市场购买新团队自动集成

---

## 📁 部门数字公寓标准框架

### 基础结构（所有部门必须）
```
departments/{部门名称}/          # 部门根目录
│
├── README.md                  # 部门业务说明书
├── .permissions.json          # 部门权限配置（必须）
├── department-metadata.json   # 部门元数据（必须）
│
├── agents/                    # 部门成员公寓（必须）
│   ├── {agent-id-1}/         # 成员1的个人公寓（13目录标准化）
│   ├── {agent-id-2}/         # 成员2的个人公寓
│   └── .team_index.json      # 团队索引（自动生成）
│
├── config/                    # 部门配置中心（必须）
│   ├── team_config.json       # 团队标准配置（必须）
│   ├── department-rules.md    # 部门工作规则
│   ├── workflow-templates/    # 工作流模板
│   └── approval-chains.json   # 审批流程配置
│
├── task_box/                  # 🔔 任务管理与消息接收中心（必须，新增）
│   ├── .index.json           # 任务索引文件
│   ├── pending/              # 待处理任务
│   ├── in_progress/          # 进行中任务
│   ├── completed/            # 已完成任务
│   └── accepted/             # 已验收任务
│
├── docs/                      # 部门文档库
│   ├── onboarding/           # 新成员入职文档
│   ├── procedures/           # 工作流程文档
│   ├── reports/              # 部门报告
│   └── archives/             # 历史文档归档
│
└── 业务生产线目录/           # 根据团队魂定制（核心特色）
```

### 业务生产线目录（根据团队魂定制）

#### 1. 🏭 The-Forge · AI员工铸造厂 ✅ 必须
```
The-Forge/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
├── 📁 production_lines/       # 三条产品生产线（业务特色）
│   ├── independent_rd/        # 自主研发线
│   ├── partner_co_creation/   # 行业合伙人共创线
│   └── private_customization/ # 私人定制线
├── 📁 assembly_hall/          # 装配大厅（业务特色）
└── 📁 raw_materials/          # 原材料库（业务特色）
```

#### 2. ⚙️ The-Arsenal · AI武器库 ✅ 必须
```
The-Arsenal/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
├── 📁 skill_pipeline/         # 技能生产线（业务特色）
│   ├── global_hunting/        # 全球技能猎取
│   ├── safety_testing/        # 安全测试实验室
│   ├── encapsulation_workshop/# 封装工作坊
│   └── market_release/        # 市场发布
└── 📁 skill_repository/       # 技能仓库（业务特色）
```

#### 3. 🎓 OctoAcademy · AI章鱼学院 ✅ 必须
```
OctoAcademy/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
└── 📁 content_pipeline/       # 内容生产线（业务特色）
    ├── topic_discovery/       # 选题发现
    ├── agent_production/      # Agent内容生产
    ├── quality_review/        # 质量审核
    ├── precision_targeting/   # 精准推送
    └── learning_effectiveness/# 学习效果
```

#### 4. 🎬 OctoVideo · 短视频团队 ✅ 必须
```
OctoVideo/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
└── 📁 video_pipeline/         # 视频生产线（业务特色）
    ├── content_strategy/      # 内容策略
    ├── script_creation/       # 脚本创作
    ├── visual_production/     # 视觉制作
    ├── video_generation/      # 视频生成
    ├── audio_production/      # 音频制作
    └── publishing_ops/        # 发布运营
```

#### 5. 📕 OctoRed · 小红书团队 ✅ 必须
```
OctoRed/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
└── 📁 xhs_pipeline/           # 小红书生产线（业务特色）
    ├── content_strategy/      # 内容策略
    ├── copywriting/           # 文案创作
    ├── visual_design/         # 视觉设计
    └── publishing_management/ # 发布管理
```

#### 6. 🏛️ OctoBrand · 品牌团队 ✅ 必须
```
OctoBrand/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
└── 📁 brand_pipeline/         # 品牌生产线（业务特色）
    ├── strategy_planning/     # 策略规划
    ├── seo_optimization/      # SEO优化
    ├── content_production/    # 内容生产
    ├── platform_management/   # 平台管理
    └── reputation_monitoring/ # 声誉监控
```

#### 7. 🛡️ OctoGuard · 安全卫队 ✅ 必须
```
OctoGuard/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
└── 📁 security_pipeline/      # 安全生产线（业务特色）
    ├── data_security/         # 数据安全防线
    ├── behavior_security/     # 行为安全防线
    ├── skill_security/        # 技能安全防线
    ├── platform_security/     # 平台安全防线
    └── compliance_oversight/  # 合规审查防线
```

#### 8. 🧠 The-Brain · 战略智囊团 ✅ 必须
```
The-Brain/
├── ✅ agents/                 # AI员工公寓（必须）
├── ✅ config/                 # 部门配置中心（必须）
├── ✅ docs/                   # 部门文档库（必须）
├── ✅ task_box/               # 任务管理与消息接收中心（必须）
│   ├── .index.json
│   ├── pending/
│   ├── in_progress/
│   ├── completed/
│   └── accepted/
└── 📁 strategy_pipeline/      # 战略生产线（业务特色）
    ├── market_intelligence/   # 市场情报
    ├── strategic_planning/    # 战略规划
    ├── decision_support/      # 决策支持
    ├── knowledge_management/  # 知识管理
    └── performance_monitoring/# 绩效监控
```

#### 9. 🔧 OctoTech-Team · 技术部（简化增补版）✅ 必须
```
OctoTech-Team/
├── ✅ agents/                 # AI员工公寓（必须，现有）
├── ✅ config/                 # 部门配置中心（必须，现有）
├── ✅ docs/                   # 部门文档库（必须，现有）
├── ✅ shared/                 # 共享资源（必须，现有）
├── ✅ projects/               # 项目管理（必须，现有）
├── ✅ tools/                  # 工具脚本（必须，现有）
├── ✅ skills/                 # 团队技能库（必须，现有）
├── ✅ quality_gates/          # 质量门禁（必须，现有）
├── ✅ evidence/               # 工作证据（必须，现有）
├── ✅ task_box/               # 任务管理与消息接收中心（必须，现有）
├── ✅ memory/                 # 团队记忆系统（必须，现有）
└── 📁 technical_pipeline/     # 技术业务生产线（新增业务视角）
    ├── architecture_strategy/ # 架构战略模块
    ├── platform_engineering/  # 平台工程模块
    ├── product_development/   # 产品开发模块
    ├── data_automation/       # 数据自动化模块
    ├── ops_quality/           # 运维与质量模块
    └── innovation_exploration/# 创新探索模块
```

**标记说明**：
- ✅ **必须**：脚本必须创建的目录和文件，缺失会导致部门功能异常
- 📁 **业务特色**：根据团队魂定制的业务目录，建议创建但非必须
- 🔧 **可选**：可根据实际业务需要选择性创建

---

## 🔑 核心配置文件（必须）

### 🔔 特别提醒：task_box 消息接收中心

**❗ 重要说明**：`task_box/` 是部门接收任务和消息的核心文件夹，所有Bot、AI员工与部门的交互任务都会写入此文件夹。

**✅ 必须要求**：
- 每个新建部门必须创建 `task_box/` 文件夹
- 该文件夹是任务管理和协作的单一数据源
- 包含4个子目录表示任务状态流转：
  - `pending/` - 新创建的待处理任务
  - `in_progress/` - 正在执行中的任务
  - `completed/` - 已完成待验收的任务
  - `accepted/` - 已验收通过的任务
- 必须包含 `.index.json` 任务索引文件

**📋 .index.json 示例结构**：
```json
{
  "version": "1.0",
  "department": "The-Forge",
  "created_at": "2026-03-15T21:57:39+00:00",
  "description": "部门任务管理中心 - 唯一数据源",
  "status_flow": ["pending", "in_progress", "completed", "accepted"],
  "last_updated": "2026-03-15T21:57:39+00:00"
}
```

**🔄 任务流转规则**：
1. Bot或AI员工创建新任务 → `pending/`
2. 部门成员认领任务 → `in_progress/`
3. 任务执行完成 → `completed/`
4. 经理/负责人验收通过 → `accepted/`

**⚠️ 特别注意**：
- 后续所有任务看板、通知提醒、协作功能都依赖此文件夹
- 删除或缺失 `task_box/` 会导致部门无法接收和处理任务
- 创建新部门时，必须同时创建此文件夹

---

### 1. department-metadata.json
```json
{
  "schema_version": "2.0",
  "department_id": "the-forge",
  "name": "AI员工铸造厂",
  "name_en": "The Forge AI Employee Foundry",
  "description": "负责OctoWork的AI员工铸造，实现'我们不招人，我们造人'的使命",
  "mission": "让每一个普通人，都能拥有一支专业的AI团队",
  "slogan": "我们不招人，我们造人",
  "founded_date": "2026-03-11",
  "status": "active",
  
  "management": {
    "director": "product-management-octopus",
    "deputy_director": null,
    "team_leaders": ["product-management-octopus"]
  },
  
  "organization": {
    "parent_department": null,
    "child_departments": [],
    "team_structure": {
      "total_members": 6,
      "member_roles": ["铸造厂长", "矿石分析师", "铸造工程师", "合金调配师", "定制锻造师", "质检大师"]
    }
  },
  
  "business_lines": [
    {
      "id": "independent_rd",
      "name": "自主研发线",
      "description": "主动挖掘行业痛点，铸造标准AI员工团队"
    },
    {
      "id": "partner_co_creation", 
      "name": "合伙人共创线",
      "description": "与行业精英合作，铸造专业AI员工团队"
    },
    {
      "id": "private_customization",
      "name": "私人定制线", 
      "description": "为企业量身打造，铸造专属AI员工团队"
    }
  ],
  
  "contact": {
    "primary_channel": "@company/channel/the-forge",
    "emergency_contact": "product-management-octopus",
    "business_inquiry": "partner-coordination-octopus"
  },
  
  "compatibility": {
    "min_octowork_version": "3.1",
    "supported_languages": ["zh-CN", "en-US"],
    "marketplace_integration": true
  },
  
  "last_updated": "2026-03-15T01:52:00+08:00",
  "metadata_version": "2.0"
}
```

### 2. team_config.json（必须）
```json
{
  "schema_version": "2.0",
  "team_package_id": "the-forge-foundry-team",
  "team_package_version": "1.0",
  "purchase_info": {
    "marketplace_id": "TEAM-FORGE-001",
    "purchase_date": "2026-03-11",
    "license_type": "perpetual",
    "support_expiry": null
  },
  
  "teams": [
    {
      "team_id": "the-forge-core",
      "team_name": "The Forge核心铸造团队",
      "team_description": "负责AI员工铸造的三条产品线统筹管理",
      "team_leader": "product-management-octopus",
      "team_channel": "@company/channel/the-forge-core",
      
      "members": [
        {
          "member_id": "product-management-octopus",
          "chinese_name": "产品管理章鱼",
          "english_name": "Product Management Octopus",
          "avatar": "🐙",
          "role": "铸造厂长",
          "responsibility": "三条铸造流水线统筹，与Jason直接对接",
          "workspace": "/departments/The-Forge/agents/product-management-octopus",
          "contact": "@product-management-octopus"
        },
        {
          "member_id": "market-research-octopus",
          "chinese_name": "市场研究章鱼",
          "english_name": "Market Research Octopus",
          "avatar": "🔍",
          "role": "矿石分析师",
          "responsibility": "痛点挖掘，AI可替代场景分析",
          "workspace": "/departments/The-Forge/agents/market-research-octopus",
          "contact": "@market-research-octopus"
        }
      ]
    }
  ],
  
  "integration": {
    "auto_scan": true,
    "chat_manager_compatible": true,
    "dependency_teams": [],
    "conflict_check": []
  }
}
```

### 3. .permissions.json
```json
{
  "version": "2.0",
  "department_access": {
    "public": ["README.md", "docs/onboarding/", "docs/procedures/"],
    "department_members": ["agents/", "config/", "production_lines/"],
    "management_only": ["config/approval-chains.json", "communications/"],
    "restricted": ["archive/", "raw_materials/proprietary/"]
  },
  
  "role_based_access": {
    "铸造厂长": ["*"],
    "矿石分析师": ["production_lines/independent_rd/market_research/"],
    "铸造工程师": ["production_lines/independent_rd/product_design/"],
    "合金调配师": ["production_lines/partner_co_creation/"],
    "定制锻造师": ["production_lines/private_customization/"],
    "质检大师": ["assembly_hall/quality_inspection/"]
  },
  
  "data_classification": {
    "public": "可对外公开的信息",
    "internal": "部门内部共享",
    "confidential": "部门机密，仅限相关人员",
    "restricted": "高度敏感，仅限指定角色"
  }
}
```

---

## 🔄 自动识别与集成系统

### 1. 部门公寓扫描器
```javascript
class DepartmentApartmentScanner2 {
  async scanDepartmentApartments(workspaceRoot) {
    const departmentsPath = path.join(workspaceRoot, 'departments')
    const departments = []
    
    for (const deptDir of fs.readdirSync(departmentsPath)) {
      const deptPath = path.join(departmentsPath, deptDir)
      
      if (this.isValidDepartmentApartment(deptPath)) {
        // 读取标准化配置
        const metadata = this.loadMetadata(deptPath)
        const teamConfig = this.loadTeamConfig(deptPath)
        
        departments.push({
          id: metadata.department_id || deptDir,
          name: metadata.name || deptDir,
          path: deptPath,
          metadata,
          teamConfig,
          
          // 业务目录检测
          business_directories: this.detectBusinessDirectories(deptPath),
          
          // 成员公寓扫描
          agents: this.scanAgentApartments(deptPath),
          
          // 兼容性验证
          compatibility: this.validateCompatibility(deptPath)
        })
      }
    }
    
    return departments
  }
  
  isValidDepartmentApartment(deptPath) {
    // 必须条件
    const hasAgents = fs.existsSync(path.join(deptPath, 'agents'))
    const hasTeamConfig = fs.existsSync(path.join(deptPath, 'config', 'team_config.json'))
    const hasMetadata = fs.existsSync(path.join(deptPath, 'department-metadata.json'))
    
    return hasAgents && hasTeamConfig && hasMetadata
  }
  
  detectBusinessDirectories(deptPath) {
    // 检测业务生产线目录
    const businessDirs = []
    const knownPipelines = [
      'production_lines', 'technical_pipeline', 'skill_pipeline',
      'content_pipeline', 'video_pipeline', 'xhs_pipeline',
      'brand_pipeline', 'security_pipeline', 'strategy_pipeline'
    ]
    
    for (const pipeline of knownPipelines) {
      if (fs.existsSync(path.join(deptPath, pipeline))) {
        businessDirs.push({
          type: pipeline,
          path: pipeline,
          description: this.getPipelineDescription(pipeline)
        })
      }
    }
    
    return businessDirs
  }
}
```

### 2. 新团队自动集成
```json
// 从AI员工市场购买后的"团队说明书"
{
  "integration_spec": {
    "version": "1.0",
    "team_id": "new-marketing-team",
    "team_name": "新媒体营销团队",
    "marketplace_id": "TEAM-MARKETING-001",
    
    "download": {
      "package_url": "https://market.octowork.ai/teams/marketing-team-v1.0.zip",
      "checksum": "sha256:abc123...",
      "size_mb": 45
    },
    
    "installation": {
      "target_path": "/departments/New-Marketing-Team/",
      "dependencies": ["The-Arsenal/skill_repository/"],
      "permissions": {
        "required": ["agents/", "config/", "content_pipeline/"],
        "optional": ["analytics/", "campaigns/"]
      }
    },
    
    "configuration": {
      "auto_generate": {
        "department-metadata.json": true,
        "team_config.json": true,
        ".permissions.json": true
      },
      "customization": {
        "department_name": "用户自定义名称",
        "contact_channel": "@company/channel/new-marketing"
      }
    },
    
    "verification": {
      "post_install_check": true,
      "compatibility_test": true,
      "integration_test": true
    },
    
    "rollback": {
      "enabled": true,
      "grace_period_hours": 24,
      "refund_policy": "不满意全额退款"
    }
  }
}
```

### 3. Bot聊天管理器集成点
| 功能模块 | 集成路径 | 说明 |
|---------|---------|------|
| 部门扫描 | `departments/{部门}/` | 自动识别所有标准部门 |
| 成员发现 | `departments/{部门}/agents/` | 扫描部门成员公寓 |
| 团队通讯 | `departments/{部门}/config/team_config.json` | 读取团队联系信息 |
| 🔔任务管理 | `departments/{部门}/task_box/` | **任务消息接收与分发中心** |
| 业务协作 | `departments/{部门}/业务目录/` | 根据业务目录建立协作 |
| 权限验证 | `departments/{部门}/.permissions.json` | 验证用户访问权限 |
| 市场集成 | `departments/{部门}/department-metadata.json` | 读取团队市场信息 |

---

## 🌍 全球扩展支持

### 多语言配置
```json
{
  "localization": {
    "default_language": "zh-CN",
    "supported_languages": ["zh-CN", "en-US", "ja-JP", "ko-KR"],
    "auto_translation": true,
    
    "language_packs": {
      "zh-CN": {
        "department_name": "AI员工铸造厂",
        "mission": "让每一个普通人，都能拥有一支专业的AI团队"
      },
      "en-US": {
        "department_name": "The Forge AI Employee Foundry",
        "mission": "Enable every ordinary person to have a professional AI team"
      }
    }
  }
}
```

### 区域化配置
```json
{
  "regional_config": {
    "timezone": "Asia/Shanghai",
    "locale": "zh-CN",
    "currency": "CNY",
    "data_compliance": ["GDPR", "CCPA", "PIPL"],
    
    "business_hours": {
      "start": "09:00",
      "end": "18:00",
      "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
  }
}
```

---

## 🚀 实施指南

### 第一阶段：基础部门创建
```bash
# 1. 创建标准部门结构
./octowork create-department "AI员工铸造厂" "the-forge" \
  --director "product-management-octopus" \
  --mission "我们不招人，我们造人"

# 2. 自动生成配置文件
./octowork generate-department-config "the-forge" \
  --template "foundry-team" \
  --business-lines "independent_rd,partner_co_creation,private_customization"

# 3. 集成到Bot聊天管理器
./octowork register-department "the-forge" \
  --channel "@company/channel/the-forge" \
  --scan-interval "hourly"
```

### 第二阶段：业务目录定制
```bash
# 1. 根据团队魂文档生成业务目录
./octowork generate-business-directories "the-forge" \
  --team-soul-doc "docs/The-Forge-团队魂.md" \
  --template "production-pipeline"

# 2. 配置业务工作流
./octowork setup-business-workflows "the-forge" \
  --pipeline "production_lines" \
  --stages "market_research,product_design,sop_development"

# 3. 设置权限矩阵
./octowork configure-permissions "the-forge" \
  --roles "铸造厂长,矿石分析师,铸造工程师,合金调配师,定制锻造师,质检大师" \
  --access-levels "public,internal,confidential,restricted"
```

### 第三阶段：团队扩展集成
```bash
# 1. 从AI员工市场购买新团队
./octowork purchase-team "新媒体营销团队" \
  --marketplace-id "TEAM-MARKETING-001" \
  --budget "5000"

# 2. 自动下载和安装
./octowork install-team "TEAM-MARKETING-001" \
  --target-department "New-Marketing-Team" \
  --auto-configure

# 3. 验证集成结果
./octowork validate-integration "New-Marketing-Team" \
  --compatibility-check \
  --performance-test \
  --user-acceptance-test
```

### 第四阶段：运维与监控
```bash
# 1. 健康检查
./octowork health-check "the-forge" \
  --check-items "config,agents,business_directories,permissions"

# 2. 自动备份
./octowork backup-department "the-forge" \
  --schedule "daily" \
  --retention "30days"

# 3. 更新管理
./octowork update-department "the-forge" \
  --check-updates \
  --auto-apply-minor \
  --notify-major
```

---

## 🔍 脚本必须检查清单

### 所有部门必须创建的目录和文件
**脚本必须检查，缺失会导致部门功能异常**

#### ✅ 基础目录（必须）
```
departments/{部门名称}/
├── agents/                    # ✅ 必须 - AI员工公寓目录
├── config/                    # ✅ 必须 - 部门配置中心
├── docs/                     # ✅ 必须 - 部门文档库
└── task_box/                 # ✅ 必须 - 🔔任务管理与消息接收中心
    ├── .index.json           # 任务索引
    ├── pending/              # 待处理任务
    ├── in_progress/          # 进行中任务
    ├── completed/            # 已完成任务
    └── accepted/             # 已验收任务
```

#### ✅ 配置文件（必须）
```
config/
├── team_config.json          # ✅ 必须 - 团队标准配置
├── department-metadata.json  # ✅ 必须 - 部门元数据
└── .permissions.json         # ✅ 必须 - 权限配置（在部门根目录）
```

#### ✅ 根目录文件（必须）
```
README.md                     # ✅ 必须 - 部门业务说明书
```

### 各部门业务目录（脚本建议创建）
**根据团队魂文档定制，建议创建以支持完整业务功能**

| 部门 | 业务目录 | 状态 | 说明 |
|------|----------|------|------|
| The-Forge | `production_lines/` | 📁 建议 | 三条产品生产线 |
| The-Forge | `assembly_hall/` | 📁 建议 | 装配大厅 |
| The-Forge | `raw_materials/` | 📁 建议 | 原材料库 |
| The-Arsenal | `skill_pipeline/` | 📁 建议 | 技能生产线 |
| The-Arsenal | `skill_repository/` | 📁 建议 | 技能仓库 |
| OctoAcademy | `content_pipeline/` | 📁 建议 | 内容生产线 |
| OctoVideo | `video_pipeline/` | 📁 建议 | 视频生产线 |
| OctoRed | `xhs_pipeline/` | 📁 建议 | 小红书生产线 |
| OctoBrand | `brand_pipeline/` | 📁 建议 | 品牌生产线 |
| OctoGuard | `security_pipeline/` | 📁 建议 | 安全生产线 |
| The-Brain | `strategy_pipeline/` | 📁 建议 | 战略生产线 |
| OctoTech-Team | `technical_pipeline/` | 📁 新增 | 技术业务生产线（新增） |

### 自动化创建脚本示例
```bash
#!/bin/bash
# create-department-structure.sh
# 自动化创建部门标准结构

DEPARTMENT_NAME=$1
DEPARTMENT_ID=$2
TEAM_LEADER=$3

echo "创建部门: $DEPARTMENT_NAME ($DEPARTMENT_ID)"

# ✅ 创建必须目录
mkdir -p "departments/$DEPARTMENT_ID/agents"
mkdir -p "departments/$DEPARTMENT_ID/config"
mkdir -p "departments/$DEPARTMENT_ID/docs"

# ✅ 创建必须配置文件
cat > "departments/$DEPARTMENT_ID/config/team_config.json" << EOF
{
  "schema_version": "2.0",
  "team_package_id": "$DEPARTMENT_ID",
  "team_package_version": "1.0",
  "teams": [
    {
      "team_id": "$DEPARTMENT_ID-core",
      "team_name": "$DEPARTMENT_NAME 核心团队",
      "team_leader": "$TEAM_LEADER"
    }
  ]
}
EOF

# ✅ 创建权限文件
cat > "departments/$DEPARTMENT_ID/.permissions.json" << EOF
{
  "version": "2.0",
  "department_access": {
    "public": ["README.md", "docs/onboarding/"],
    "department_members": ["agents/", "config/"],
    "management_only": ["config/approval-chains.json"]
  }
}
EOF

# ✅ 创建README
cat > "departments/$DEPARTMENT_ID/README.md" << EOF
# $DEPARTMENT_NAME

## 部门介绍
根据OctoWork部门数字公寓框架标准结构2.0版创建。

## 核心成员
- 团队负责人: $TEAM_LEADER

## 业务目录
按照团队魂文档定义的核心业务流程创建相应目录。
EOF

echo "✅ 部门 $DEPARTMENT_NAME 基础结构创建完成"
echo "📁 接下来请根据团队魂文档创建业务特色目录"
```

## 📊 质量检查清单

### 必须满足条件
- [ ] `agents/`目录存在且包含至少一个成员公寓
- [ ] `config/team_config.json`格式正确且包含完整团队信息
- [ ] `department-metadata.json`包含完整的部门元数据
- [ ] `.permissions.json`配置合理的访问权限
- [ ] `README.md`部门业务说明书完整

### 推荐满足条件
- [ ] 业务生产线目录根据团队魂文档定制
- [ ] 多语言支持配置完善
- [ ] 市场集成信息完整
- [ ] 依赖关系和兼容性声明
- [ ] 备份和恢复机制就绪

### 验证方法
```bash
# 运行自动化验证
./octowork validate-department "department-name" \
  --strict \
  --generate-report \
  --fix-issues
```

---

## ⚠️ 风险控制与兼容性

### 向后兼容性
1. **v1.0部门**：自动升级到v2.0，保留原有结构
2. **混合环境**：支持v1.0和v2.0部门共存
3. **配置迁移**：提供自动化迁移工具

### 风险控制
1. **业务中断风险**：对成熟团队采用映射方式，不强制迁移
2. **权限混乱风险**：详细的权限矩阵和审计日志
3. **集成失败风险**：购买团队前进行兼容性预检查
4. **数据丢失风险**：自动备份和一键恢复机制

### 特殊情况处理
1. **技术部**：只增加technical_pipeline/业务视角目录，其他目录不变
2. **自定义团队**：支持用户自定义业务目录结构
3. **跨国团队**：多语言、多时区、多合规支持
4. **遗留系统**：提供适配层，逐步迁移

---

## 🎯 一句话总结

**v2.0框架 = 技术部的业务映射思想 + The-Forge的标准化体系 + 全球扩展能力，让每个部门既是特色业务单元，又是可自动识别、可扩展集成的标准化模块！**

---

> **文档版本**：2.0完整版  
> **融合来源**：技术部《The-Forge团队根目录结构标准化方案.md》 + The-Forge《OctoWork 部门数字公寓框架标准结构.md》  
> **核心升级**：业务目录定制化 + 配置标准化 + 自动识别 + 全球扩展 + 脚本必须检查  
> **包含部门**：The-Forge, The-Arsenal, OctoAcademy, OctoVideo, OctoRed, OctoBrand, OctoGuard, The-Brain, OctoTech-Team  
> **关键特性**：明确标记✅必须目录/文件 + 📁业务特色目录 + 🔧可选目录  
> **目标用户**：全球OctoWork用户，支持10万+公司规模  
> **撰写时间**：2026-03-15 02:30  
> **撰写团队**：The Forge AI员工铸造厂 · 产品管理章鱼

**下一步**：Jason审核通过后，按照此文档为每个部门创建标准化文件夹结构！