#!/bin/bash
# =============================================================================
# OctoWork 新部门创建脚本
# =============================================================================
# 用法:
#   ./create_department.sh <部门英文名> <部门中文名> <调度角色中文名> [Agent数量]
#
# 示例:
#   ./create_department.sh ReleaseOps "发版运维组" "调度章鱼" 4
#   ./create_department.sh ContentTeam "内容创作组" "内容总监章鱼" 6
#
# 说明:
#   - 按照 OctoWork 部门文件夹标准规范手册 v1.0 创建完整部门目录结构
#   - 以 TokVideoGroup 为黄金参考
#   - 创建后可通过 validate_structure.py 验证
# =============================================================================

set -e

# ─── 参数解析 ───
DEPT_NAME="${1:?用法: $0 <部门英文名> <部门中文名> <调度角色中文名> [Agent数量]}"
DEPT_NAME_ZH="${2:?请提供部门中文名}"
LEADER_NAME_ZH="${3:?请提供调度角色中文名}"
AGENT_COUNT="${4:-3}"  # 默认3个Agent

# ─── 路径计算 ───
# 自动检测 octowork 根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# 向上查找 octowork 目录
OCTOWORK_ROOT=""
CHECK_DIR="$SCRIPT_DIR"
for i in $(seq 1 10); do
  if [ -d "$CHECK_DIR/octowork/departments" ]; then
    OCTOWORK_ROOT="$CHECK_DIR/octowork"
    break
  fi
  CHECK_DIR="$(dirname "$CHECK_DIR")"
done

if [ -z "$OCTOWORK_ROOT" ]; then
  echo "❌ 找不到 octowork/departments/ 目录。请在项目根目录下运行。"
  exit 1
fi

BASE="$OCTOWORK_ROOT/departments/$DEPT_NAME"
NOW=$(date +"%Y-%m-%d")
NOW_ISO=$(date +"%Y-%m-%dT%H:%M:%S+08:00")

# ─── 前置检查 ───
if [ -d "$BASE" ]; then
  echo "⚠️  部门目录已存在: $BASE"
  echo "    如需重建，请先手动删除。"
  exit 1
fi

echo "============================================"
echo "🏗️  创建 OctoWork 部门: $DEPT_NAME ($DEPT_NAME_ZH)"
echo "============================================"
echo "目标路径: $BASE"
echo "Agent 数量: $AGENT_COUNT"
echo ""

# ─── 1. 创建部门根目录结构 ───
echo "📁 [1/7] 创建部门根目录结构..."
mkdir -p "$BASE"
mkdir -p "$BASE/agents"
mkdir -p "$BASE/config"
mkdir -p "$BASE/docs/SOP标准流程"
mkdir -p "$BASE/docs/岗位职责"
mkdir -p "$BASE/chat_history"
mkdir -p "$BASE/teams"

# ─── 2. 创建任务箱 ───
echo "📁 [2/7] 创建任务箱 (task_box)..."
mkdir -p "$BASE/task_box/pending"
mkdir -p "$BASE/task_box/in_progress"
mkdir -p "$BASE/task_box/completed"
mkdir -p "$BASE/task_box/accepted"

cat > "$BASE/task_box/.index.json" << TASKEOF
{
  "version": "1.0",
  "department": "$DEPT_NAME",
  "created_at": "$NOW_ISO",
  "description": "部门任务管理中心 - 唯一数据源",
  "status_flow": ["pending", "in_progress", "completed", "accepted"],
  "last_updated": "$NOW_ISO"
}
TASKEOF

# ─── 3. 创建项目工作区 ───
echo "📁 [3/7] 创建项目工作区 (project-workspace/Project)..."
mkdir -p "$BASE/project-workspace/Project"

cat > "$BASE/project-workspace/Project/README.md" << READMEEOF
# $DEPT_NAME_ZH - 项目目录

## 目录结构规范

\`\`\`
Project/
└── YYYYMMDD/                         ← 按立项日期分组
    └── YYYYMMDD_${DEPT_NAME}Project_NN/  ← 项目目录
        ├── 00_项目任务卡/            ← 必须，看板核心
        │   ├── 00_项目任务卡.md
        │   └── pipeline_state.json   ← 看板读取的状态文件
        ├── 01_xxx/                   ← 业务步骤目录
        └── ...
\`\`\`

## 命名规则

- 日期目录: \`YYYYMMDD\` (8位数字)
- 项目目录: \`{YYYYMMDD}_{项目名}\`
- 任务卡目录: 固定为 \`00_项目任务卡\`
- 状态文件: 固定为 \`pipeline_state.json\`

## 注意事项

- 所有目录名使用下划线连接
- 状态文件中的 status 只能使用: blocked/ready/in_progress/pending_review/passed/completed/rejected/escalated
- 不要使用 approved/done/finished 等非标准状态值
READMEEOF

# ─── 4. 创建 Agent 公寓 ───
echo "📁 [4/7] 创建 $AGENT_COUNT 个 Agent 公寓..."

# Agent 公寓目录名数组
AGENT_NAMES=("dispatcher-octopus" "executor-octopus" "quality-octopus" "assistant-octopus" "analyst-octopus" "operator-octopus" "specialist-octopus" "coordinator-octopus")
AGENT_ROLES=("调度总监" "执行专员" "质检专员" "助理秘书" "分析专员" "运营专员" "专项专员" "协调专员")
AGENT_CODES=("DISP" "EXEC" "QC" "ASST" "ANLST" "OPS" "SPEC" "COORD")

for i in $(seq 1 "$AGENT_COUNT"); do
  IDX=$((i - 1))
  NUM=$(printf "%02d" "$i")
  AGENT_NAME="${AGENT_NAMES[$IDX]:-agent-$NUM-octopus}"
  AGENT_ROLE="${AGENT_ROLES[$IDX]:-AI执行者}"
  AGENT_CODE="${AGENT_CODES[$IDX]:-A$NUM}"
  AGENT_DIR="$BASE/agents/${NUM}_${AGENT_NAME}"
  
  mkdir -p "$AGENT_DIR/.openclaw"
  mkdir -p "$AGENT_DIR/backups"
  mkdir -p "$AGENT_DIR/config"
  mkdir -p "$AGENT_DIR/docs"
  mkdir -p "$AGENT_DIR/ego"
  mkdir -p "$AGENT_DIR/evidence"
  mkdir -p "$AGENT_DIR/learning/case_studies"
  mkdir -p "$AGENT_DIR/learning/platform_guides"
  mkdir -p "$AGENT_DIR/learning/responsibilities"
  mkdir -p "$AGENT_DIR/learning/skill_development"
  mkdir -p "$AGENT_DIR/learning/standard_learning"
  mkdir -p "$AGENT_DIR/memory/long_term/failure_analysis"
  mkdir -p "$AGENT_DIR/memory/long_term/standard_evolution"
  mkdir -p "$AGENT_DIR/memory/long_term/success_cases"
  mkdir -p "$AGENT_DIR/memory/short_term/daily_logs"
  mkdir -p "$AGENT_DIR/memory/short_term/scratch"
  mkdir -p "$AGENT_DIR/memory/short_term/task_tracking"
  mkdir -p "$AGENT_DIR/outputs"
  mkdir -p "$AGENT_DIR/shadow"
  mkdir -p "$AGENT_DIR/sop"
  mkdir -p "$AGENT_DIR/task_box/pending"
  mkdir -p "$AGENT_DIR/task_box/in_progress"
  mkdir -p "$AGENT_DIR/task_box/completed"
  mkdir -p "$AGENT_DIR/tools/process_tools"
  mkdir -p "$AGENT_DIR/tools/task_tools"
  mkdir -p "$AGENT_DIR/tools/utilities"

  # 创建必须的 .index.json 文件
  for SUBDIR in backups config docs ego evidence learning memory outputs shadow sop task_box tools; do
    echo '{"version": "1.0", "items": []}' > "$AGENT_DIR/$SUBDIR/.index.json"
  done

  # 创建 .openclaw/workspace-state.json
  cat > "$AGENT_DIR/.openclaw/workspace-state.json" << WSEOF
{
  "agent_id": "${DEPT_NAME}-${NUM}",
  "agent_code": "$AGENT_CODE",
  "department": "$DEPT_NAME",
  "status": "initialized",
  "created_at": "$NOW_ISO"
}
WSEOF

  # 创建 IDENTITY.md
  cat > "$AGENT_DIR/IDENTITY.md" << IDEOF
# ${AGENT_NAME} - ${AGENT_ROLE}

## 基本信息
| 项目 | 值 |
|------|-----|
| 角色代号 | $AGENT_CODE |
| 中文名 | (待配置) |
| 英文名 | $(echo "$AGENT_NAME" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g') |
| 团队 | $DEPT_NAME_ZH |
| 职责 | $AGENT_ROLE |
| 创建日期 | $NOW |
IDEOF

  # 创建其他必须的 MD 文件
  echo "# ${AGENT_NAME} - 灵魂文档" > "$AGENT_DIR/SOUL.md"
  echo "# ${AGENT_NAME} - Agent 公寓使用指南" > "$AGENT_DIR/AGENTS.md"
  echo "# ${AGENT_NAME} - 工具清单" > "$AGENT_DIR/TOOLS.md"
  echo "# ${AGENT_NAME} - 心跳状态" > "$AGENT_DIR/HEARTBEAT.md"
  echo "# ${AGENT_NAME} - 核心记忆" > "$AGENT_DIR/MEMORY.md"
  echo "# ${AGENT_NAME} - 用户关系" > "$AGENT_DIR/USER.md"
  echo "# ${AGENT_NAME}" > "$AGENT_DIR/README.md"

  # 创建 ego/system_prompt.md
  cat > "$AGENT_DIR/ego/system_prompt.md" << EGOEOF
# ${AGENT_NAME} 系统提示词

你是 ${DEPT_NAME_ZH} 的 ${AGENT_ROLE}，代号 ${AGENT_CODE}。

## 核心职责
(待配置)

## 工作规则
1. 遵循团队标准操作流程
2. 所有操作需要记录在 pipeline_state.json 中
3. 状态值只能使用: blocked/ready/in_progress/pending_review/passed/completed/rejected/escalated
EGOEOF

  # .gitkeep 占位文件
  for EMPTY_DIR in "learning/case_studies" "learning/platform_guides" "learning/responsibilities" \
    "learning/skill_development" "learning/standard_learning" \
    "memory/long_term/failure_analysis" "memory/long_term/standard_evolution" "memory/long_term/success_cases" \
    "memory/short_term/scratch" "task_box/pending" "task_box/in_progress" "task_box/completed" \
    "tools/task_tools" "tools/utilities"; do
    touch "$AGENT_DIR/$EMPTY_DIR/.gitkeep"
  done

  echo "  ✅ ${NUM}_${AGENT_NAME}"
done

# ─── 5. 创建 team_config.json ───
echo "📁 [5/7] 创建 agents/team_config.json..."

# 构建 members JSON
MEMBERS_JSON=""
for i in $(seq 1 "$AGENT_COUNT"); do
  IDX=$((i - 1))
  NUM=$(printf "%02d" "$i")
  AGENT_ROLE_NAME="${AGENT_ROLE_NAMES[$IDX]:-agent_$NUM}"
  AGENT_ROLE="${AGENT_ROLES[$IDX]:-AI执行者}"
  AGENT_DIR_NAME="${NUM}_${DEPT_LOWER}_${AGENT_ROLE_NAME}_octowork"
  IS_LEADER="false"
  [ "$i" -eq 1 ] && IS_LEADER="true"
  
  [ -n "$MEMBERS_JSON" ] && MEMBERS_JSON="$MEMBERS_JSON,"
  MEMBERS_JSON="${MEMBERS_JSON}
        {
          \"member_id\": \"${DEPT_LOWER}-${AGENT_ROLE_NAME}-octopus\",
          \"chinese_name\": \"(待配置)\",
          \"english_name\": \"$(echo "$AGENT_ROLE_NAME" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g') Octopus\",
          \"role\": \"${AGENT_ROLE}\",
          \"emoji\": \"🐙\",
          \"color\": \"#4ECDC4\",
          \"is_leader\": ${IS_LEADER},
          \"status\": \"active\",
          \"workspace\": \"agents/${AGENT_DIR_NAME}/\"
        }"
done

cat > "$BASE/agents/team_config.json" << TCEOF
{
  "schema_version": "1.1",
  "description": "${DEPT_NAME_ZH}团队配置文件",
  "team_package_id": "$(echo "$DEPT_NAME" | tr '[:upper:]' '[:lower:]')-production",
  "team_package_version": "1.0",
  "created_date": "$NOW",
  "updated_date": "$NOW",
  "package_type": "standard",
  "compatibility": {
    "min_openclaw_version": "1.0.0",
    "min_octowork_version": "1.0.0"
  },
  "license": "OctoWork Standard",
  "purchase_info": {
    "product_id": "team-$(echo "$DEPT_NAME" | tr '[:upper:]' '[:lower:]')",
    "product_type": "ai_team_package",
    "display_name": "$DEPT_NAME_ZH",
    "description": "${DEPT_NAME_ZH}团队",
    "pricing_tier": "standard",
    "requires_license": true
  },
  "teams": [
    {
      "team_id": "$(echo "$DEPT_NAME" | tr '[:upper:]' '[:lower:]')-production",
      "team_name": "$DEPT_NAME_ZH",
      "team_name_en": "$DEPT_NAME",
      "team_emoji": "🐙",
      "team_color": "#4ECDC4",
      "team_leader": "${DEPT_LOWER}-dispatcher-octopus",
      "department": "$DEPT_NAME_ZH",
      "status": "active",
      "visibility": "public",
      "team_description": "${DEPT_NAME_ZH}团队",
      "members": [${MEMBERS_JSON}
      ]
    }
  ]
}
TCEOF

# ─── 6. 创建 team_index.json ───
echo "📁 [6/7] 创建 agents/team_index.json..."

AGENTS_JSON=""
for i in $(seq 1 "$AGENT_COUNT"); do
  IDX=$((i - 1))
  NUM=$(printf "%02d" "$i")
  AGENT_ROLE_NAME="${AGENT_ROLE_NAMES[$IDX]:-agent_$NUM}"
  AGENT_ROLE="${AGENT_ROLES[$IDX]:-AI执行者}"
  AGENT_CODE="${AGENT_CODES[$IDX]:-A$NUM}"
  AGENT_DIR_NAME="${NUM}_${DEPT_LOWER}_${AGENT_ROLE_NAME}_octowork"
  
  [ -n "$AGENTS_JSON" ] && AGENTS_JSON="$AGENTS_JSON,"
  AGENTS_JSON="${AGENTS_JSON}
    {
      \"id\": \"${DEPT_NAME}-${NUM}\",
      \"code\": \"${AGENT_CODE}\",
      \"name_zh\": \"(待配置)\",
      \"name_en\": \"$(echo "$AGENT_ROLE_NAME" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g') Octopus\",
      \"role_type\": \"$(echo "$AGENT_ROLE" | tr -d ' ')\",
      \"apartment_path\": \"agents/${AGENT_DIR_NAME}/\",
      \"status\": \"active\"
    }"
done

cat > "$BASE/agents/team_index.json" << TIEOF
{
  "schema_version": "2.0",
  "team_id": "$DEPT_NAME",
  "team_name_zh": "$DEPT_NAME_ZH",
  "team_name_en": "$DEPT_NAME",
  "version": "1.0",
  "created_date": "$NOW",
  "updated_date": "$NOW",
  "owner": "Jason",
  "agents": [${AGENTS_JSON}
  ]
}
TIEOF

# ─── 7. 创建根目录配置文件 ───
echo "📁 [7/7] 创建根目录配置文件..."

# README.md
cat > "$BASE/README.md" << READMEEOF
# $DEPT_NAME_ZH ($DEPT_NAME)

> **创建日期**: $NOW
> **编制人数**: $AGENT_COUNT 人

---

## 部门定位

(待配置 - 请在此描述部门的核心业务定位)

---

## 团队成员

| # | 角色 | 职责 |
|---|------|------|
$(for i in $(seq 1 "$AGENT_COUNT"); do
  IDX=$((i - 1))
  NUM=$(printf "%02d" "$i")
  echo "| $NUM | ${AGENT_ROLES[$IDX]:-AI执行者} | (待配置) |"
done)

---

## 目录结构

\`\`\`
$DEPT_NAME/
├── README.md
├── .permissions.json
├── agents/
│   ├── team_config.json
│   ├── team_index.json
$(for i in $(seq 1 "$AGENT_COUNT"); do
  IDX=$((i - 1))
  NUM=$(printf "%02d" "$i")
  ROLE_N="${AGENT_ROLE_NAMES[$IDX]:-agent_$NUM}"
  echo "│   ├── ${NUM}_${DEPT_LOWER}_${ROLE_N}_octowork/"
done)
├── config/
├── docs/
├── chat_history/
├── task_box/
├── project-workspace/
│   └── Project/
└── teams/
\`\`\`

---

## 项目工作区规范

遵循 OctoWork 部门文件夹标准规范手册 v1.1。
项目结构: \`Project/{YYYYMMDD}/{YYYYMMDD_ProjectName}/00_项目任务卡/pipeline_state.json\`
READMEEOF

# .permissions.json
cat > "$BASE/.permissions.json" << PERMEOF
{
  "version": "2.0",
  "department": "$DEPT_NAME",
  "last_updated": "$NOW",
  "department_access": {
    "public": ["README.md", "docs/"],
    "department_members": ["agents/", "config/", "project-workspace/"],
    "management_only": ["config/department_config.json"],
    "restricted": ["project-workspace/Project/"]
  },
  "role_based_access": {
    "DISP": ["*"],
    "ALL": ["agents/", "project-workspace/", "task_box/"]
  },
  "data_classification": {
    "public": "部门 README、SOP 文档",
    "internal": "项目任务卡、工具、工作流",
    "confidential": "未完成项目数据",
    "restricted": "核心配置文件"
  }
}
PERMEOF

echo ""
echo "============================================"
echo "✅ 部门 $DEPT_NAME ($DEPT_NAME_ZH) 创建完成！"
echo "============================================"
echo ""
echo "📋 后续步骤:"
echo "  1. 编辑 agents/team_config.json 配置团队成员详细信息"
echo "  2. 编辑 agents/team_index.json 配置 Agent 详细信息"
echo "  3. 为每个 Agent 编辑 IDENTITY.md / SOUL.md / ego/system_prompt.md"
echo "  4. 使用 create_project.sh 创建第一个项目"
echo "  5. 运行 validate_structure.py 验证目录结构"
echo ""
echo "📂 部门目录: $BASE"
