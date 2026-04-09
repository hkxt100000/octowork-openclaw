#!/usr/bin/env python3
"""
OctoWork 部门目录结构验证脚本
===============================
用法:
  python validate_structure.py                    # 验证所有部门
  python validate_structure.py --dept TokVideoGroup  # 验证指定部门
  python validate_structure.py --dept ReleaseOps --fix  # 验证并尝试修复

功能:
  1. 验证部门根目录结构是否符合标准
  2. 验证 Agent 公寓是否完整
  3. 验证项目工作区路径格式
  4. 验证 pipeline_state.json 内容合规性
  5. 输出详细的检查报告

参考标准:
  - OctoWork 部门文件夹标准规范手册 v1.0
  - TokVideoGroup 黄金参考实现
"""

import json
import os
import re
import sys
import argparse
from datetime import datetime


# ──────────────────────────────────────────
# 配置常量
# ──────────────────────────────────────────

# 标准 pipeline 状态值
VALID_STATUSES = {
    "blocked", "ready", "in_progress", "pending_review",
    "passed", "completed", "rejected", "escalated"
}

# 看板识别的完成状态
DONE_STATUSES = {"passed", "completed"}

# 非标准状态值（常见错误）
INVALID_STATUSES = {"approved", "done", "finished", "success", "failed", "canceled"}

# Agent 公寓必须的目录
AGENT_REQUIRED_DIRS = [
    ".openclaw", "backups", "config", "docs", "ego",
    "evidence", "learning", "memory", "outputs",
    "shadow", "sop", "task_box", "tools"
]

# Agent 公寓必须的文件
AGENT_REQUIRED_FILES = [
    "IDENTITY.md", "SOUL.md", "README.md"
]

# 部门根目录必须的目录
DEPT_REQUIRED_DIRS = [
    "agents", "config", "docs", "task_box", "project-workspace"
]

# 部门根目录必须的文件
DEPT_REQUIRED_FILES = [
    "README.md", ".permissions.json"
]

# 日期目录格式
DATE_DIR_PATTERN = re.compile(r"^\d{8}$")

# 项目目录格式 (YYYYMMDD_xxx)
PROJECT_DIR_PATTERN = re.compile(r"^\d{8}_.+$")

# Agent v1.1 强制命名规范: {NN}_{dept}_{role}_octowork
AGENT_V11_PATTERN = re.compile(r"^\d{2}_[a-z]+_[a-z][a-z0-9_]*_octowork$")

# TokVideoGroup 旧格式（允许豁免）: {NN}_{name}-octopus
AGENT_LEGACY_PATTERN = re.compile(r"^\d{2}_.+-octopus$")

# 允许使用旧格式的豁免部门（历史原因）
LEGACY_EXEMPT_DEPTS = {"TokVideoGroup"}


# ──────────────────────────────────────────
# 验证类
# ──────────────────────────────────────────

class ValidationReport:
    """验证报告收集器"""
    
    def __init__(self):
        self.errors = []      # 致命错误（看板无法显示）
        self.warnings = []    # 警告（功能可能受限）
        self.info = []        # 信息（建议改进）
        self.passes = []      # 通过项
    
    def error(self, msg):
        self.errors.append(f"  ❌ {msg}")
    
    def warning(self, msg):
        self.warnings.append(f"  ⚠️  {msg}")
    
    def info_msg(self, msg):
        self.info.append(f"  💡 {msg}")
    
    def ok(self, msg):
        self.passes.append(f"  ✅ {msg}")
    
    def print_report(self, dept_name):
        total = len(self.errors) + len(self.warnings) + len(self.passes)
        
        print(f"\n{'='*60}")
        if self.errors:
            print(f"🔴 {dept_name}: {len(self.errors)} 错误, {len(self.warnings)} 警告")
        elif self.warnings:
            print(f"🟡 {dept_name}: 0 错误, {len(self.warnings)} 警告")
        else:
            print(f"🟢 {dept_name}: 全部通过 ✅")
        print(f"{'='*60}")
        
        if self.errors:
            print("\n🔴 致命错误（看板将无法显示）:")
            for e in self.errors:
                print(e)
        
        if self.warnings:
            print("\n🟡 警告（功能可能受限）:")
            for w in self.warnings:
                print(w)
        
        if self.info:
            print("\n💡 建议:")
            for i in self.info:
                print(i)
        
        if self.passes:
            print("\n✅ 通过项:")
            for p in self.passes:
                print(p)
        
        print("")
        return len(self.errors) == 0


def find_octowork_root():
    """查找 octowork 根目录"""
    # 从当前脚本目录向上查找
    check_dir = os.path.dirname(os.path.abspath(__file__))
    for _ in range(10):
        candidate = os.path.join(check_dir, "octowork", "departments")
        if os.path.isdir(candidate):
            return os.path.join(check_dir, "octowork")
        check_dir = os.path.dirname(check_dir)
    
    # 也试试当前工作目录
    cwd = os.getcwd()
    for _ in range(5):
        candidate = os.path.join(cwd, "octowork", "departments")
        if os.path.isdir(candidate):
            return os.path.join(cwd, "octowork")
        cwd = os.path.dirname(cwd)
    
    return None


def validate_department(dept_path, dept_name):
    """验证单个部门"""
    report = ValidationReport()
    
    # ─── 1. 部门根目录 ───
    print(f"\n📂 检查部门: {dept_name}")
    print(f"   路径: {dept_path}")
    
    # 检查必须目录
    for d in DEPT_REQUIRED_DIRS:
        full_path = os.path.join(dept_path, d)
        if os.path.isdir(full_path):
            report.ok(f"目录存在: {d}/")
        else:
            report.error(f"缺少必须目录: {d}/")
    
    # 检查必须文件
    for f in DEPT_REQUIRED_FILES:
        full_path = os.path.join(dept_path, f)
        if os.path.isfile(full_path):
            report.ok(f"文件存在: {f}")
        else:
            report.error(f"缺少必须文件: {f}")
    
    # ─── 2. team_config.json ───
    tc_path = os.path.join(dept_path, "agents", "team_config.json")
    if os.path.isfile(tc_path):
        report.ok("agents/team_config.json 存在")
        try:
            with open(tc_path, "r", encoding="utf-8") as f:
                tc = json.load(f)
            
            # 检查关键字段
            if "teams" in tc and len(tc["teams"]) > 0:
                team = tc["teams"][0]
                if "team_emoji" in team:
                    report.ok(f"团队图标: {team['team_emoji']}")
                else:
                    report.warning("team_config.json 缺少 teams[0].team_emoji")
                
                if "team_name" in team:
                    report.ok(f"团队名称: {team['team_name']}")
                else:
                    report.warning("team_config.json 缺少 teams[0].team_name")
                
                if "members" in team and len(team["members"]) > 0:
                    report.ok(f"团队成员: {len(team['members'])} 人")
                else:
                    report.warning("team_config.json 中没有成员定义")
            else:
                report.error("team_config.json 缺少 teams 数组或为空")
            
            # 检查是否有非标准自定义字段
            for bad_field in ["project_dir", "state_file", "flat_structure", "task_card_dir"]:
                if bad_field in tc:
                    report.warning(f"team_config.json 包含非标准字段 '{bad_field}'，建议删除（使用标准目录结构即可）")
        
        except json.JSONDecodeError as e:
            report.error(f"team_config.json JSON 格式错误: {e}")
    else:
        report.error("缺少 agents/team_config.json（看板无法识别此部门）")
    
    # ─── 3. task_box 检查 ───
    tb_path = os.path.join(dept_path, "task_box")
    if os.path.isdir(tb_path):
        for sub in ["pending", "in_progress", "completed", "accepted"]:
            if os.path.isdir(os.path.join(tb_path, sub)):
                report.ok(f"task_box/{sub}/ 存在")
            else:
                report.error(f"缺少 task_box/{sub}/ 目录")
        
        idx_file = os.path.join(tb_path, ".index.json")
        if os.path.isfile(idx_file):
            report.ok("task_box/.index.json 存在")
        else:
            report.warning("缺少 task_box/.index.json")
    
    # ─── 4. 项目工作区 ───
    project_base = os.path.join(dept_path, "project-workspace", "Project")
    if os.path.isdir(project_base):
        report.ok("project-workspace/Project/ 目录存在")
        
        # 扫描项目
        projects_found = 0
        for date_dir in sorted(os.listdir(project_base)):
            date_path = os.path.join(project_base, date_dir)
            if not os.path.isdir(date_path):
                continue
            
            # 检查日期目录格式
            if date_dir in ("README.md", "YYYYMMDD"):
                continue  # 跳过模板和 README
            
            if not DATE_DIR_PATTERN.match(date_dir):
                report.error(f"日期目录格式错误: Project/{date_dir}/ (应为 YYYYMMDD)")
                continue
            
            report.ok(f"日期目录格式正确: Project/{date_dir}/")
            
            # 检查项目目录
            for proj_dir in sorted(os.listdir(date_path)):
                proj_path = os.path.join(date_path, proj_dir)
                if not os.path.isdir(proj_path):
                    continue
                
                if proj_dir.startswith("YYYYMMDD"):
                    continue  # 跳过模板
                
                if not PROJECT_DIR_PATTERN.match(proj_dir):
                    report.warning(f"项目目录命名建议: {proj_dir} (推荐 YYYYMMDD_xxx 格式)")
                
                # 检查 00_项目任务卡
                task_card_dir = os.path.join(proj_path, "00_项目任务卡")
                if os.path.isdir(task_card_dir):
                    report.ok(f"任务卡目录存在: {proj_dir}/00_项目任务卡/")
                    
                    # 检查 pipeline_state.json
                    pipeline_file = os.path.join(task_card_dir, "pipeline_state.json")
                    if os.path.isfile(pipeline_file):
                        report.ok(f"状态文件存在: {proj_dir}/.../pipeline_state.json")
                        projects_found += 1
                        
                        # 验证 pipeline_state.json 内容
                        validate_pipeline_state(pipeline_file, proj_dir, report)
                    else:
                        report.error(f"缺少状态文件: {proj_dir}/00_项目任务卡/pipeline_state.json")
                        
                        # 检查是否有错误命名的文件
                        for f in os.listdir(task_card_dir):
                            if f.endswith("_state.json") and f != "pipeline_state.json":
                                report.error(f"发现非标准状态文件: {f} (应为 pipeline_state.json)")
                else:
                    report.error(f"缺少任务卡目录: {proj_dir}/00_项目任务卡/")
                    
                    # 检查常见错误
                    for wrong_name in ["task-cards", "task_cards", "00_任务卡", "任务卡"]:
                        if os.path.isdir(os.path.join(proj_path, wrong_name)):
                            report.error(f"发现非标准目录: {wrong_name}/ (应为 00_项目任务卡/)")
        
        if projects_found == 0:
            report.info_msg("Project/ 下暂无有效项目（可使用 create_project.sh 创建）")
        else:
            report.ok(f"共发现 {projects_found} 个有效项目")
    
    else:
        # 检查常见错误命名
        pw_path = os.path.join(dept_path, "project-workspace")
        if os.path.isdir(pw_path):
            for wrong_name in os.listdir(pw_path):
                if wrong_name != "Project" and os.path.isdir(os.path.join(pw_path, wrong_name)):
                    if wrong_name not in ("情报采集_待审核",):  # 排除合法的其他目录
                        report.error(f"发现非标准项目目录: project-workspace/{wrong_name}/ (应为 Project/)")
        
        report.error("缺少 project-workspace/Project/ 目录（看板将无法扫描项目）")
    
    # ─── 5. Agent 公寓检查 ───
    agents_dir = os.path.join(dept_path, "agents")
    if os.path.isdir(agents_dir):
        agent_count = 0
        for item in sorted(os.listdir(agents_dir)):
            agent_path = os.path.join(agents_dir, item)
            if os.path.isdir(agent_path) and re.match(r"^\d{2}_", item):
                agent_count += 1
                validate_agent_apartment(agent_path, item, report)
                validate_agent_naming(item, dept_name, report)
        
        if agent_count == 0:
            report.warning("agents/ 下没有 Agent 公寓")
        else:
            report.ok(f"共 {agent_count} 个 Agent 公寓")
    
    return report


def validate_pipeline_state(filepath, proj_dir, report):
    """验证 pipeline_state.json 内容"""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        report.error(f"[{proj_dir}] pipeline_state.json JSON格式错误: {e}")
        return
    
    # 检查 project_id
    if "project_id" in data:
        report.ok(f"[{proj_dir}] project_id: {data['project_id']}")
    elif "release_id" in data:
        report.error(f"[{proj_dir}] 使用了 release_id (应为 project_id)")
    elif "task_id" in data:
        report.info_msg(f"[{proj_dir}] 使用了 task_id（个人任务模式）")
    else:
        report.error(f"[{proj_dir}] 缺少 project_id 字段")
    
    # 检查 pipeline 数组
    pipeline = data.get("pipeline", [])
    if not pipeline:
        report.error(f"[{proj_dir}] pipeline 数组为空或不存在")
        return
    
    report.ok(f"[{proj_dir}] pipeline 包含 {len(pipeline)} 个步骤")
    
    # 检查每个步骤的 status
    invalid_found = []
    for step in pipeline:
        status = step.get("status", "")
        if status not in VALID_STATUSES:
            invalid_found.append(f"{step.get('step_id', '?')}={status}")
        
        if status in INVALID_STATUSES:
            report.error(f"[{proj_dir}] 步骤 {step.get('step_id')} 使用非标准状态: '{status}' "
                        f"(应使用 passed/completed)")
    
    if invalid_found:
        report.error(f"[{proj_dir}] 发现非标准状态值: {', '.join(invalid_found)}")
    else:
        # 计算进度
        done_count = sum(1 for s in pipeline if s.get("status") in DONE_STATUSES)
        report.ok(f"[{proj_dir}] 所有状态值合规, 进度: {done_count}/{len(pipeline)}")
    
    # 检查 schema_version
    if data.get("schema_version") != "1.0":
        report.warning(f"[{proj_dir}] schema_version 不是 '1.0': {data.get('schema_version')}")
    
    # 检查 guardian
    if "guardian" in data:
        report.ok(f"[{proj_dir}] guardian 配置存在")
    else:
        report.info_msg(f"[{proj_dir}] 建议添加 guardian 配置（守护程序支持）")


def validate_agent_apartment(agent_path, agent_name, report):
    """验证单个 Agent 公寓"""
    missing_dirs = []
    for d in AGENT_REQUIRED_DIRS:
        if not os.path.isdir(os.path.join(agent_path, d)):
            missing_dirs.append(d)
    
    missing_files = []
    for f in AGENT_REQUIRED_FILES:
        if not os.path.isfile(os.path.join(agent_path, f)):
            missing_files.append(f)
    
    if missing_dirs:
        report.warning(f"[{agent_name}] 缺少目录: {', '.join(missing_dirs)}")
    
    if missing_files:
        report.warning(f"[{agent_name}] 缺少文件: {', '.join(missing_files)}")
    
    if not missing_dirs and not missing_files:
        report.ok(f"[{agent_name}] 公寓结构完整")


def validate_agent_naming(agent_dir_name, dept_name, report):
    """
    验证 Agent 目录命名是否符合 v1.1 强制规范
    格式: {NN}_{dept}_{role}_octowork
    
    历史团队 (TokVideoGroup) 允许使用旧格式 {NN}_{name}-octopus
    """
    # 检查是否符合新规范
    if AGENT_V11_PATTERN.match(agent_dir_name):
        # 符合新规范，进一步检查部门名是否包含在目录名中
        parts = agent_dir_name.split("_")
        # parts: ["01", "dept", ... "role", "octowork"]
        # dept 是第二部分
        agent_dept = parts[1] if len(parts) >= 4 else ""
        dept_lower = dept_name.lower().replace("-", "")
        
        if agent_dept == dept_lower or dept_lower.startswith(agent_dept) or agent_dept.startswith(dept_lower[:6]):
            report.ok(f"[{agent_dir_name}] 命名符合 v1.1 规范 ✅")
        else:
            report.warning(
                f"[{agent_dir_name}] 部门缩写 '{agent_dept}' 与部门名 '{dept_name}' 可能不匹配"
            )
        return
    
    # 检查是否是历史豁免部门的旧格式
    if dept_name in LEGACY_EXEMPT_DEPTS:
        if AGENT_LEGACY_PATTERN.match(agent_dir_name):
            report.info_msg(
                f"[{agent_dir_name}] 使用旧格式（{dept_name} 历史豁免）"
                f" — 建议后续迁移为: {{NN}}_{{dept}}_{{role}}_octowork"
            )
            return
    
    # 其他情况——既不符合新规范，也不在豁免名单中
    report.error(
        f"[{agent_dir_name}] 命名不符合 v1.1 规范！"
        f" 应为: {{NN}}_{{dept}}_{{role}}_octowork"
        f"（例: 01_{dept_name.lower().replace('-', '')}_dispatcher_octowork）"
    )


# ──────────────────────────────────────────
# 主入口
# ──────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="OctoWork 部门目录结构验证工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python validate_structure.py                      # 验证所有部门
  python validate_structure.py --dept TokVideoGroup  # 验证指定部门
  python validate_structure.py --dept ReleaseOps     # 验证 ReleaseOps
        """
    )
    parser.add_argument("--dept", help="指定部门名称（不指定则验证全部）")
    parser.add_argument("--fix", action="store_true", help="尝试自动修复缺失的目录")
    args = parser.parse_args()
    
    # 查找 octowork 根目录
    octowork_root = find_octowork_root()
    if not octowork_root:
        print("❌ 找不到 octowork/ 根目录")
        print("   请在项目根目录下运行此脚本")
        sys.exit(1)
    
    departments_dir = os.path.join(octowork_root, "departments")
    print(f"🔍 OctoWork 根目录: {octowork_root}")
    print(f"📂 部门目录: {departments_dir}")
    
    # 确定要验证的部门
    if args.dept:
        dept_path = os.path.join(departments_dir, args.dept)
        if not os.path.isdir(dept_path):
            print(f"❌ 部门不存在: {args.dept}")
            sys.exit(1)
        depts = [(args.dept, dept_path)]
    else:
        depts = []
        for d in sorted(os.listdir(departments_dir)):
            dp = os.path.join(departments_dir, d)
            if os.path.isdir(dp) and not d.startswith("."):
                depts.append((d, dp))
    
    if not depts:
        print("❌ 没有找到任何部门")
        sys.exit(1)
    
    print(f"📋 将验证 {len(depts)} 个部门: {', '.join(d[0] for d in depts)}")
    
    # 执行验证
    all_pass = True
    for dept_name, dept_path in depts:
        report = validate_department(dept_path, dept_name)
        passed = report.print_report(dept_name)
        if not passed:
            all_pass = False
    
    # 总结
    print("\n" + "=" * 60)
    if all_pass:
        print("🎉 所有部门验证通过！")
    else:
        print("⚠️  部分部门存在问题，请按照 OctoWork 部门文件夹标准规范手册修复")
    print("=" * 60)
    
    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
