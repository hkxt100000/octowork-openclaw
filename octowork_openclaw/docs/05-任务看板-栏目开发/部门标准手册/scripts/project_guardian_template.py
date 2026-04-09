#!/usr/bin/env python3
"""
项目守护脚本模板 (Project Guardian Template)
===============================================
此模板供新团队创建守护脚本时使用。

使用方法:
  1. 复制本文件到团队调度角色的工具目录:
     agents/01_dispatcher-octopus/tools/process_tools/project_guardian.py
  2. 修改 MIGRATION_MAP 为团队实际的目录迁移映射
  3. 保留所有核心函数不变（load_state, save_state, update_step_status 等）

运行方式:
  python project_guardian.py --project-dir <项目目录> --action status
  python project_guardian.py --project-dir <项目目录> --action recover
  python project_guardian.py --project-dir <项目目录> --action advance
  python project_guardian.py --project-dir <项目目录> --action next
  python project_guardian.py --project-dir <项目目录> --action update --step X --new-status Y

标准参考: OctoWork 部门文件夹标准规范手册 v1.0
"""

import json
import os
import sys
import argparse
from datetime import datetime, timezone, timedelta

TZ = timezone(timedelta(hours=8))

# ═══════════════════════════════════════════
# ★ 团队自定义区域 ★
# 修改此处的映射表以匹配你的团队流水线步骤
# ═══════════════════════════════════════════

# 步骤通过后的文件迁移映射
# key = 触发迁移的 step_id (通常是 qc 步骤)
# from = 待审核目录
# to = 已通过目录
MIGRATION_MAP = {
    # 示例 (请替换为实际步骤):
    # "qc_a": {"from": "01_步骤一_待审核", "to": "02_步骤一_已通过"},
    # "qc_b": {"from": "03_步骤二_待审核", "to": "04_步骤二_已通过"},
    # "qc_c": {"from": "05_步骤三_待审核", "to": "06_步骤三_已通过"},
}

# 团队名称 (用于恢复上下文的提示)
TEAM_NAME = "团队名称"
LEADER_CODE = "DISP"     # 调度者代号
ASSISTANT_CODE = "ASST"  # 助理代号

# ═══════════════════════════════════════════
# 以下核心逻辑不要修改
# ═══════════════════════════════════════════


# ─────────────────────────────────────────────
# 1. 读写 pipeline_state.json
# ─────────────────────────────────────────────

def load_state(project_dir):
    """加载 pipeline_state.json (固定路径: 00_项目任务卡/pipeline_state.json)"""
    path = os.path.join(project_dir, "00_项目任务卡", "pipeline_state.json")
    if not os.path.exists(path):
        print(f"❌ 找不到 pipeline_state.json: {path}")
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f), path


def save_state(state, path):
    """保存 pipeline_state.json 并更新时间戳"""
    state["updated_at"] = now_str()
    with open(path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def now_str():
    return datetime.now(TZ).strftime("%Y-%m-%dT%H:%M:%S+08:00")


# ─────────────────────────────────────────────
# 2. 状态机核心逻辑
# ─────────────────────────────────────────────

# 标准状态值 (不要修改！看板只认这些值)
VALID_STATUSES = {
    "blocked", "ready", "in_progress", "pending_review",
    "passed", "completed", "rejected", "escalated"
}


def get_step(state, step_id):
    """按 step_id 查找步骤"""
    for s in state["pipeline"]:
        if s["step_id"] == step_id:
            return s
    return None


def check_dependencies_met(state, step):
    """检查前置依赖是否全部 passed/completed"""
    for dep_id in step.get("depends_on", []):
        dep = get_step(state, dep_id)
        if dep is None or dep["status"] not in ("passed", "completed"):
            return False
    return True


def compute_ready_steps(state):
    """计算所有应该从 blocked 变为 ready 的步骤"""
    changed = []
    for step in state["pipeline"]:
        if step["status"] == "blocked" and check_dependencies_met(state, step):
            step["status"] = "ready"
            changed.append(step["step_id"])
    return changed


def find_current_step(state):
    """找到当前流水线焦点"""
    priority = ["in_progress", "pending_review", "ready", "rejected", "escalated"]
    for target_status in priority:
        for step in state["pipeline"]:
            if step["status"] == target_status:
                return step
    return None


def find_stalled_step(state, timeout_minutes=15):
    """检测是否有步骤超时卡住"""
    now = datetime.now(TZ)
    for step in state["pipeline"]:
        if step["status"] in ("in_progress", "pending_review"):
            started = step.get("started_at")
            if started:
                try:
                    start_time = datetime.fromisoformat(started)
                    if (now - start_time).total_seconds() > timeout_minutes * 60:
                        return step, (now - start_time).total_seconds() / 60
                except (ValueError, TypeError):
                    pass
    return None, 0


def find_escalated_steps(state):
    """找到所有需要上报用户的步骤"""
    return [s for s in state["pipeline"] if s["status"] == "escalated"]


def compute_progress(state):
    """计算完成百分比 (只认 passed 和 completed)"""
    total = len(state["pipeline"])
    done = sum(1 for s in state["pipeline"] if s["status"] in ("passed", "completed"))
    return round(done / total * 100) if total > 0 else 0


# ─────────────────────────────────────────────
# 3. 动作：状态摘要
# ─────────────────────────────────────────────

def action_status(state):
    """输出流水线状态摘要"""
    current = find_current_step(state)
    timeout = state.get("guardian", {}).get("stall_timeout_minutes", 15)
    stalled, stall_minutes = find_stalled_step(state, timeout)
    escalated = find_escalated_steps(state)
    progress = compute_progress(state)

    lines = []
    lines.append(f"📋 项目: {state.get('project_id', '未知')}")
    done_count = sum(1 for s in state["pipeline"] if s["status"] in ("passed", "completed"))
    lines.append(f"📊 进度: {progress}% ({done_count}/{len(state['pipeline'])} 步骤完成)")
    lines.append(f"🔍 审核模式: {state.get('review_policy', {}).get('mode', '未设置')}")
    lines.append("")

    status_icons = {
        "passed": "✅", "completed": "✅", "ready": "🟢", "in_progress": "🔄",
        "pending_review": "⏳", "blocked": "⬜", "rejected": "❌", "escalated": "🚨"
    }
    lines.append("流水线:")
    for s in state["pipeline"]:
        icon = status_icons.get(s["status"], "?")
        reject_info = f" (打回{s['reject_count']}次)" if s.get("reject_count", 0) > 0 else ""
        lines.append(f"  {icon} {s['step_id']}: {s['name']} [{s['executor']}]{reject_info}")

    lines.append("")

    if stalled:
        lines.append(f"⚠️ 卡点: {stalled['step_id']} 已卡 {stall_minutes:.0f} 分钟")
    if escalated:
        for e in escalated:
            lines.append(f"🚨 需{LEADER_CODE}上报用户: {e['step_id']} 打回已超限")

    if current:
        lines.append(f"👉 焦点: {current['step_id']} ({current['name']}) → @{current['executor']} → {current['status']}")
    elif progress == 100:
        lines.append("🎉 所有步骤已完成！")
    else:
        lines.append("⚠️ 无可执行步骤，请检查卡点")

    return "\n".join(lines)


# ─────────────────────────────────────────────
# 4. 动作：恢复上下文
# ─────────────────────────────────────────────

def action_recover(state):
    """失忆恢复：生成最小决策上下文（≤500字）"""
    current = find_current_step(state)
    progress = compute_progress(state)
    escalated = find_escalated_steps(state)

    lines = []
    lines.append("=" * 40)
    lines.append(f"🧠 老板，这是你的状态恢复")
    lines.append("=" * 40)
    lines.append(f"你是{TEAM_NAME}的{LEADER_CODE}（老板）。我是你的秘书{ASSISTANT_CODE}。")
    lines.append(f"项目: {state.get('project_id', '未知')}")
    lines.append(f"进度: {progress}%")
    lines.append(f"审核模式: {state.get('review_policy', {}).get('mode', '未设置')}")
    lines.append("")

    passed = [s for s in state["pipeline"] if s["status"] in ("passed", "completed")]
    if passed:
        lines.append(f"已完成: {' → '.join(s['step_id'] for s in passed)}")

    if escalated:
        lines.append("")
        for e in escalated:
            lines.append(f"🚨 {e['step_id']} 打回超限，需要你 @用户 上报")

    if current:
        lines.append("")
        lines.append(f"【你现在需要决策】")
        lines.append(f"步骤: {current['step_id']} ({current['name']})")
        lines.append(f"执行者: @{current['executor']}")
        lines.append(f"状态: {current['status']}")

        if current.get("reject_count", 0) > 0:
            lines.append(f"已打回: {current['reject_count']}/{current.get('max_rejects', 3)}次")

        lines.append("")
        if current["status"] == "ready":
            lines.append(f"→ 告诉我: @{ASSISTANT_CODE} 发卡 @{current['executor']} {current['name']}")
        elif current["status"] == "in_progress":
            lines.append(f"→ 等 @{current['executor']} 做完汇报你")
        elif current["status"] == "pending_review":
            lines.append(f"→ 看结果，告诉我: @{ASSISTANT_CODE} {current['name']} 通过 或 打回 [原因]")
        elif current["status"] == "rejected":
            lines.append(f"→ @{current['executor']} 正在重做，等汇报")
        elif current["status"] == "escalated":
            lines.append(f"→ 你需要亲自 @用户 上报异常")
    elif progress == 100:
        lines.append("\n🎉 项目已完成！")
    else:
        lines.append(f"\n⚠️ 流水线卡住了，告诉我: @{ASSISTANT_CODE} 推进")

    lines.append("=" * 40)

    if "guardian" in state:
        state["guardian"]["total_memory_recoveries"] = state["guardian"].get("total_memory_recoveries", 0) + 1

    return "\n".join(lines)


# ─────────────────────────────────────────────
# 5. 动作：推进流水线
# ─────────────────────────────────────────────

def action_advance(state, state_path):
    """推进流水线: 解锁 blocked→ready, 检测超时, 检测打回超限"""
    actions_taken = []

    unlocked = compute_ready_steps(state)
    for step_id in unlocked:
        log_event(state, ASSISTANT_CODE, "step_unlocked", step_id, f"{step_id} 从 blocked → ready")
        actions_taken.append(f"🔓 {step_id} → ready")

    timeout = state.get("guardian", {}).get("stall_timeout_minutes", 15)
    stalled, minutes = find_stalled_step(state, timeout)
    if stalled:
        log_event(state, ASSISTANT_CODE, "stall_detected", stalled["step_id"],
                  f"{stalled['step_id']} 已卡 {minutes:.0f} 分钟")
        actions_taken.append(f"⚠️ {stalled['step_id']} 卡住 {minutes:.0f}分钟")

    for step in state["pipeline"]:
        if step["status"] == "rejected" and step.get("reject_count", 0) >= step.get("max_rejects", 3):
            step["status"] = "escalated"
            log_event(state, ASSISTANT_CODE, "escalated", step["step_id"],
                      f"{step['step_id']} 打回超限")
            actions_taken.append(f"🚨 {step['step_id']} → escalated")

    state.setdefault("guardian", {})["last_heartbeat"] = now_str()
    save_state(state, state_path)

    return "推进结果:\n" + "\n".join(actions_taken) if actions_taken else "流水线状态正常，无需干预。"


# ─────────────────────────────────────────────
# 6. 动作：下一步任务卡
# ─────────────────────────────────────────────

def action_next_task(state):
    """生成下一步的任务卡"""
    compute_ready_steps(state)
    current = find_current_step(state)

    if not current:
        return "✅ 所有步骤已完成" if compute_progress(state) == 100 else "⚠️ 无可执行步骤"

    if current["status"] != "ready":
        status_msg = {
            "in_progress": f"⏳ {current['step_id']} 正在执行",
            "pending_review": f"⏳ {current['step_id']} 等{LEADER_CODE}审核",
            "rejected": f"❌ {current['step_id']} 被打回",
            "escalated": f"🚨 {current['step_id']} 需{LEADER_CODE}上报",
        }
        return status_msg.get(current["status"], f"当前状态: {current['status']}")

    lines = []
    lines.append(f"📋 任务卡（由{LEADER_CODE}下达，{ASSISTANT_CODE}转发）")
    lines.append("━" * 30)
    lines.append(f"项目编号: {state.get('project_id', '未知')}")
    lines.append(f"指派对象: @{current['executor']}")
    lines.append(f"任务描述: {current['name']}")
    if current.get("input_dir"):
        lines.append(f"素材路径: {current['input_dir']}")
    if current.get("output_dir"):
        lines.append(f"输出路径: {current['output_dir']}")
    lines.append(f"完成后: 在群里 @{LEADER_CODE} + @用户 汇报")
    lines.append("━" * 30)

    return "\n".join(lines)


# ─────────────────────────────────────────────
# 7. 工具函数
# ─────────────────────────────────────────────

def log_event(state, actor, action, step_id=None, detail=""):
    """向 event_log 追加一条记录"""
    event = {"time": now_str(), "actor": actor, "action": action}
    if step_id:
        event["step"] = step_id
    if detail:
        event["detail"] = detail
    state.setdefault("event_log", []).append(event)


def update_step_status(state, state_path, step_id, new_status, actor=None, detail=""):
    """更新步骤状态（含门禁检查）"""
    if actor is None:
        actor = ASSISTANT_CODE
    
    step = get_step(state, step_id)
    if not step:
        return f"❌ 找不到步骤: {step_id}"

    old_status = step["status"]

    # 门禁: 合法跳转规则
    legal_transitions = {
        "blocked": {"ready"},
        "ready": {"in_progress"},
        "in_progress": {"pending_review"},
        "pending_review": {"passed", "completed", "rejected"},
        "rejected": {"in_progress", "escalated"},
        "escalated": {"in_progress"},
        "passed": set(),
        "completed": set(),
    }

    allowed = legal_transitions.get(old_status, set())
    if new_status not in allowed:
        return f"❌ 非法跳转: {step_id} {old_status} → {new_status} (允许: {allowed})"

    if old_status == "blocked" and new_status == "ready":
        if not check_dependencies_met(state, step):
            return f"❌ 前置条件未满足"

    # 执行更新
    step["status"] = new_status
    ts = now_str()
    result_extras = []

    if new_status == "in_progress":
        step["started_at"] = ts
    elif new_status == "pending_review":
        step["completed_at"] = ts
    elif new_status in ("passed", "completed"):
        step["passed_at"] = ts
        unlocked = compute_ready_steps(state)
        if unlocked:
            result_extras.append(f"  🔓 自动解锁: {', '.join(unlocked)}")
        if step_id in MIGRATION_MAP:
            m = MIGRATION_MAP[step_id]
            result_extras.append(f"  📦 请执行迁移: {m['from']} → {m['to']}")
    elif new_status == "rejected":
        step["reject_count"] = step.get("reject_count", 0) + 1
        if step["reject_count"] >= step.get("max_rejects", 3):
            step["status"] = "escalated"
            new_status = "escalated"
            result_extras.append(f"  🚨 超限升级！需{LEADER_CODE}亲自@用户")

    log_event(state, actor, f"status_changed:{new_status}", step_id, detail or f"{old_status} → {new_status}")
    save_state(state, state_path)

    result = f"✅ {step_id}: {old_status} → {new_status}"
    if result_extras:
        result += "\n" + "\n".join(result_extras)
    return result


# ─────────────────────────────────────────────
# 8. 主入口
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description=f"项目守护脚本 — {LEADER_CODE}的心脏起搏器")
    parser.add_argument("--project-dir", required=True, help="项目目录路径")
    parser.add_argument("--action", default="status",
                        choices=["status", "recover", "advance", "next", "update"],
                        help="执行动作")
    parser.add_argument("--step", help="步骤ID (update用)")
    parser.add_argument("--new-status", help="新状态 (update用)")
    parser.add_argument("--actor", default=ASSISTANT_CODE, help="操作者")
    parser.add_argument("--detail", default="", help="备注")

    args = parser.parse_args()
    state, state_path = load_state(args.project_dir)

    if args.action == "status":
        print(action_status(state))
    elif args.action == "recover":
        result = action_recover(state)
        save_state(state, state_path)
        print(result)
    elif args.action == "advance":
        print(action_advance(state, state_path))
    elif args.action == "next":
        print(action_next_task(state))
    elif args.action == "update":
        if not args.step or not args.new_status:
            print("❌ update 需要 --step 和 --new-status")
            sys.exit(1)
        print(update_step_status(state, state_path, args.step, args.new_status, args.actor, args.detail))


if __name__ == "__main__":
    main()
