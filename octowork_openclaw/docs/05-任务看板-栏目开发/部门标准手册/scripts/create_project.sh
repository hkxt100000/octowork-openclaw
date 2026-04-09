#!/bin/bash
# =============================================================================
# OctoWork 新项目创建脚本
# =============================================================================
# 用法:
#   ./create_project.sh <部门名> <项目标识> [立项日期] [步骤定义文件]
#
# 示例:
#   ./create_project.sh TokVideoGroup TokProject_01
#   ./create_project.sh ReleaseOps Release_v0.6.0 20260410
#   ./create_project.sh ContentTeam ContentProject_01 20260412 steps.json
#
# 步骤定义文件格式 (JSON):
#   [
#     {"id": "step_a", "name": "步骤A描述", "executor": "EXEC", "dir": "01_步骤A", "has_qc": true},
#     {"id": "step_b", "name": "步骤B描述", "executor": "EXEC", "dir": "02_步骤B_待审核", "approved_dir": "03_步骤B_已通过", "has_qc": true}
#   ]
#
# 如不提供步骤定义文件，将创建基础3步流水线模板。
# =============================================================================

set -e

# ─── 参数解析 ───
DEPT_NAME="${1:?用法: $0 <部门名> <项目标识> [立项日期] [步骤定义文件]}"
PROJECT_IDENT="${2:?请提供项目标识 (如 TokProject_01, Release_v0.6.0)}"
DATE="${3:-$(date +%Y%m%d)}"  # 默认今天
STEPS_FILE="${4:-}"

# ─── 路径计算 ───
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
  echo "❌ 找不到 octowork/departments/ 目录"
  exit 1
fi

DEPT_BASE="$OCTOWORK_ROOT/departments/$DEPT_NAME"
PROJECT_BASE="$DEPT_BASE/project-workspace/Project"
PROJECT_ID="${DATE}_${PROJECT_IDENT}"
PROJECT_DIR="$PROJECT_BASE/$DATE/$PROJECT_ID"

NOW_ISO=$(date +"%Y-%m-%dT%H:%M:%S+08:00")

# ─── 前置检查 ───
if [ ! -d "$DEPT_BASE" ]; then
  echo "❌ 部门不存在: $DEPT_BASE"
  echo "   请先运行 create_department.sh 创建部门"
  exit 1
fi

if [ ! -d "$PROJECT_BASE" ]; then
  echo "❌ 项目工作区不存在: $PROJECT_BASE"
  echo "   请确认部门目录结构正确"
  exit 1
fi

if [ -d "$PROJECT_DIR" ]; then
  echo "⚠️  项目目录已存在: $PROJECT_DIR"
  exit 1
fi

echo "============================================"
echo "🚀 创建 OctoWork 项目: $PROJECT_ID"
echo "============================================"
echo "部门: $DEPT_NAME"
echo "日期: $DATE"
echo "路径: $PROJECT_DIR"
echo ""

# ─── 1. 创建日期目录和项目目录 ───
echo "📁 [1/4] 创建项目目录结构..."
mkdir -p "$PROJECT_DIR"

# ─── 2. 创建 00_项目任务卡 (必须) ───
echo "📁 [2/4] 创建任务卡目录..."
mkdir -p "$PROJECT_DIR/00_项目任务卡"

# 创建任务卡 Markdown
cat > "$PROJECT_DIR/00_项目任务卡/00_项目任务卡.md" << CARDEOF
# 项目任务卡

## 基本信息
| 项目 | 值 |
|------|-----|
| 项目编号 | $PROJECT_ID |
| 所属部门 | $DEPT_NAME |
| 立项日期 | $DATE |
| 当前状态 | 进行中 |

## 项目描述
(待填写)

## 流水线步骤
参见 pipeline_state.json

## 关键资产
(待填写)
CARDEOF

# ─── 3. 创建业务步骤目录 ───
echo "📁 [3/4] 创建业务步骤目录..."

if [ -n "$STEPS_FILE" ] && [ -f "$STEPS_FILE" ]; then
  # 使用自定义步骤定义文件
  echo "  使用自定义步骤定义: $STEPS_FILE"
  
  # 用 Python 解析 JSON 并创建目录
  python3 << PYEOF
import json, os

with open("$STEPS_FILE", "r") as f:
    steps = json.load(f)

project_dir = "$PROJECT_DIR"

for step in steps:
    dir_name = step.get("dir", "")
    if dir_name:
        os.makedirs(os.path.join(project_dir, dir_name), exist_ok=True)
        # 创建 .gitkeep 占位
        open(os.path.join(project_dir, dir_name, ".gitkeep"), "w").close()
        print(f"  ✅ {dir_name}/")
    
    approved_dir = step.get("approved_dir", "")
    if approved_dir:
        os.makedirs(os.path.join(project_dir, approved_dir), exist_ok=True)
        open(os.path.join(project_dir, approved_dir, ".gitkeep"), "w").close()
        print(f"  ✅ {approved_dir}/")
PYEOF

else
  # 默认创建3步基础流水线目录
  echo "  使用默认3步模板..."
  
  DEFAULT_DIRS=(
    "01_步骤一_待审核"
    "02_步骤一_已通过"
    "03_步骤二_待审核"
    "04_步骤二_已通过"
    "05_步骤三_待审核"
    "06_步骤三_已通过"
    "07_成品输出"
  )
  
  for DIR in "${DEFAULT_DIRS[@]}"; do
    mkdir -p "$PROJECT_DIR/$DIR"
    touch "$PROJECT_DIR/$DIR/.gitkeep"
    echo "  ✅ $DIR/"
  done
fi

# ─── 4. 创建 pipeline_state.json ───
echo "📁 [4/4] 创建 pipeline_state.json..."

if [ -n "$STEPS_FILE" ] && [ -f "$STEPS_FILE" ]; then
  # 使用自定义步骤定义生成 pipeline
  python3 << PYEOF
import json

with open("$STEPS_FILE", "r") as f:
    steps_def = json.load(f)

pipeline = []
prev_ids = []
for i, step in enumerate(steps_def):
    step_entry = {
        "step_id": step["id"],
        "name": step["name"],
        "executor": step.get("executor", "EXEC"),
        "depends_on": prev_ids.copy() if i > 0 else [],
        "status": "blocked" if i > 0 else "ready",
        "reject_count": 0,
        "max_rejects": step.get("max_rejects", 3),
        "input_dir": step.get("input_dir"),
        "output_dir": step.get("dir", ""),
        "started_at": None,
        "completed_at": None,
        "passed_at": None
    }
    pipeline.append(step_entry)
    
    # 如果有QC步骤
    if step.get("has_qc"):
        qc_id = f"qc_{step['id'].replace('step_', '')}"
        qc_entry = {
            "step_id": qc_id,
            "name": f"QC-{step['id'].replace('step_', '').upper()} 质检",
            "executor": "QC",
            "depends_on": [step["id"]],
            "status": "blocked",
            "reject_count": 0,
            "max_rejects": 3,
            "input_dir": step.get("dir"),
            "output_dir": None,
            "started_at": None,
            "completed_at": None,
            "passed_at": None
        }
        pipeline.append(qc_entry)
        prev_ids = [qc_id]
    else:
        prev_ids = [step["id"]]

state = {
    "schema_version": "1.0",
    "project_id": "$PROJECT_ID",
    "created_at": "$NOW_ISO",
    "updated_at": "$NOW_ISO",
    "review_policy": {
        "mode": "supervised",
        "modes_explained": {
            "supervised": "所有QC步骤必须人类确认",
            "assisted": "AI先出结论，人类一键确认",
            "autonomous": "AI自主审核"
        },
        "human_required_steps": [s["step_id"] for s in pipeline if s["executor"] == "QC" or s["executor"] == "DISP"],
        "auto_approved_steps": [],
        "confidence_threshold": 0.95,
        "transition_rules": {
            "after_consecutive_passes": 5,
            "require_user_unlock": True
        }
    },
    "assets": {},
    "pipeline": pipeline,
    "event_log": [
        {
            "time": "$NOW_ISO",
            "actor": "DISP",
            "action": "project_created",
            "detail": "项目立项完成"
        }
    ],
    "guardian": {
        "last_heartbeat": "$NOW_ISO",
        "stall_timeout_minutes": 15,
        "total_stall_recoveries": 0,
        "total_memory_recoveries": 0
    }
}

output_path = "$PROJECT_DIR/00_项目任务卡/pipeline_state.json"
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(state, f, ensure_ascii=False, indent=2)

print(f"  ✅ pipeline_state.json (共 {len(pipeline)} 个步骤)")
PYEOF

else
  # 默认3步 pipeline
  cat > "$PROJECT_DIR/00_项目任务卡/pipeline_state.json" << PIPEEOF
{
  "schema_version": "1.0",
  "project_id": "$PROJECT_ID",
  "created_at": "$NOW_ISO",
  "updated_at": "$NOW_ISO",
  "review_policy": {
    "mode": "supervised",
    "modes_explained": {
      "supervised": "所有QC步骤必须人类确认",
      "assisted": "AI先出结论，人类一键确认",
      "autonomous": "AI自主审核"
    },
    "human_required_steps": ["qc_a", "qc_b", "qc_c"],
    "auto_approved_steps": [],
    "confidence_threshold": 0.95,
    "transition_rules": {
      "after_consecutive_passes": 5,
      "require_user_unlock": true
    }
  },
  "assets": {},
  "pipeline": [
    {
      "step_id": "step_a",
      "name": "步骤一",
      "executor": "EXEC",
      "depends_on": [],
      "status": "ready",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": null,
      "output_dir": "01_步骤一_待审核/",
      "approved_dir": "02_步骤一_已通过/",
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    },
    {
      "step_id": "qc_a",
      "name": "QC-A 质检",
      "executor": "QC",
      "depends_on": ["step_a"],
      "status": "blocked",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": "01_步骤一_待审核/",
      "output_dir": null,
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    },
    {
      "step_id": "step_b",
      "name": "步骤二",
      "executor": "EXEC",
      "depends_on": ["qc_a"],
      "status": "blocked",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": "02_步骤一_已通过/",
      "output_dir": "03_步骤二_待审核/",
      "approved_dir": "04_步骤二_已通过/",
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    },
    {
      "step_id": "qc_b",
      "name": "QC-B 质检",
      "executor": "QC",
      "depends_on": ["step_b"],
      "status": "blocked",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": "03_步骤二_待审核/",
      "output_dir": null,
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    },
    {
      "step_id": "step_c",
      "name": "步骤三",
      "executor": "EXEC",
      "depends_on": ["qc_b"],
      "status": "blocked",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": "04_步骤二_已通过/",
      "output_dir": "05_步骤三_待审核/",
      "approved_dir": "06_步骤三_已通过/",
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    },
    {
      "step_id": "qc_c",
      "name": "QC-C 质检",
      "executor": "QC",
      "depends_on": ["step_c"],
      "status": "blocked",
      "reject_count": 0,
      "max_rejects": 3,
      "input_dir": "05_步骤三_待审核/",
      "output_dir": null,
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    },
    {
      "step_id": "output",
      "name": "成品输出",
      "executor": "EXEC",
      "depends_on": ["qc_c"],
      "status": "blocked",
      "reject_count": 0,
      "max_rejects": 0,
      "input_dir": "06_步骤三_已通过/",
      "output_dir": "07_成品输出/",
      "started_at": null,
      "completed_at": null,
      "passed_at": null
    }
  ],
  "event_log": [
    {
      "time": "$NOW_ISO",
      "actor": "DISP",
      "action": "project_created",
      "detail": "项目立项完成"
    }
  ],
  "guardian": {
    "last_heartbeat": "$NOW_ISO",
    "stall_timeout_minutes": 15,
    "total_stall_recoveries": 0,
    "total_memory_recoveries": 0
  }
}
PIPEEOF
  echo "  ✅ pipeline_state.json (默认 7 步模板)"
fi

echo ""
echo "============================================"
echo "✅ 项目 $PROJECT_ID 创建完成！"
echo "============================================"
echo ""
echo "📂 项目路径: $PROJECT_DIR"
echo "📋 状态文件: $PROJECT_DIR/00_项目任务卡/pipeline_state.json"
echo ""
echo "📋 后续步骤:"
echo "  1. 编辑 pipeline_state.json 配置实际流水线步骤"
echo "  2. 配置 assets 字段（如有产品/人物/场景资产）"
echo "  3. 在任务看板中确认项目已显示"
echo "  4. 使用 project_guardian.py --action status 检查状态"
echo ""
echo "🔍 验证命令:"
echo "  python validate_structure.py --dept $DEPT_NAME"
