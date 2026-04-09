# 🔍 自动功能匹配验证清单

**验证时间：** 2026-03-16  
**验证目标：** 确认今天开发的模块是否与自动获取功能匹配

---

## ✅ 已确认的自动功能

### 1️⃣ 个人列表自动获取（单聊）
- **数据源**: `/home/user/webapp/config/ai-directory.json`
- **生成工具**: `tools/aggregate_ai_directory.py`
- **API 端点**: `GET /api/scan-bots`
- **实现位置**: `backend/src/controllers/systemController.js` 行 102-177
- **状态**: ✅ 已实现并测试通过

### 2️⃣ 群列表自动创建（群聊）
- **数据源**: `departments/*/agents/team_config.json`
- **处理脚本**: `backend/auto-create-groups.js`
- **路径解析**: `../../../departments → /home/user/webapp/departments/`
- **状态**: ✅ 路径正确，逻辑正确

---

## 🔍 需要检查的关键模块

### A. SystemController 模块

#### ✅ scanBots() - 已匹配
- **位置**: `systemController.js` 行 102-177
- **功能**: 读取 `config/ai-directory.json` 返回 Bot 列表
- **匹配度**: 🟢 100% 匹配自动获取逻辑
- **验证结果**: 返回 58 个 Bot，9 个部门

#### ⚠️ getSessions() - 需要补充
- **位置**: `systemController.js` 行 54-68
- **当前状态**: TODO，返回空数组
- **期望行为**: 应该从数据库读取用户的所有会话（单聊+群聊）
- **匹配度**: ❌ 未实现，需要补充

**问题点**:
```javascript
getSessions = async (req, res) => {
  try {
    // TODO: 实现会话列表查询
    const sessions = []  // ❌ 应该查询数据库
    
    res.json({ 
      success: true, 
      count: sessions.length,
      sessions 
    })
  }
}
```

**应该改为**:
- 查询 `messages` 表获取用户的所有对话
- 包括单聊（来自 scanBots）和群聊（来自 auto-create-groups）
- 返回格式化的会话列表

#### ⚠️ getTeams() - 需要补充
- **位置**: `systemController.js` 行 76-90
- **当前状态**: TODO，返回空数组
- **期望行为**: 应该返回从 `departments/*/agents/team_config.json` 读取的团队列表
- **匹配度**: ❌ 未实现，需要补充

**问题点**:
```javascript
getTeams = async (req, res) => {
  try {
    // TODO: 实现团队列表查询
    const teams = []  // ❌ 应该读取 team_config.json
    
    res.json({ 
      success: true, 
      count: teams.length,
      teams 
    })
  }
}
```

**应该改为**:
- 扫描 `departments/*/agents/team_config.json`
- 提取所有 `teams` 数组
- 返回团队列表（与 auto-create-groups.js 逻辑一致）

#### ✅ getBots() - 重复功能
- **位置**: `systemController.js` 行 178-186
- **当前状态**: TODO，返回空数组
- **问题**: 与 `scanBots()` 功能重复
- **建议**: 应该调用 `scanBots()` 或删除此接口

---

### B. BoardController 模块

#### ⚠️ 硬编码部门列表 - BUG-002
- **位置**: `boardController.js` 行 17-27
- **问题**: 硬编码了 9 个部门
- **匹配度**: ⚠️ 部分匹配，应该动态扫描

**当前代码**:
```javascript
this.departments = [
  { id: 'OctoAcademy', name: 'OctoAcademy', description: '知识学院' },
  { id: 'OctoBrand', name: 'OctoBrand', description: '品牌部门' },
  // ... 硬编码 9 个部门
]
```

**应该改为**:
- 动态扫描 `departments/` 目录
- 读取每个部门的 `team_config.json`
- 自动生成部门列表

---

### C. Constants 模块

#### ⚠️ 硬编码扫描路径 - BUG-003
- **位置**: `src/config/constants.js` 行 87-90（待确认）
- **问题**: 硬编码了 Bot 扫描目录
- **建议**: 使用 `OCTOWORK_WORKSPACE` 环境变量

---

### D. GroupController 模块

#### ✅ getGroups() - 需要验证
- **位置**: 待查看
- **期望行为**: 应该从数据库读取由 `auto-create-groups.js` 创建的群组
- **验证**: 需要确认是否返回正确的群组列表

---

## 📋 修复优先级

### 🔴 P0 - 紧急（影响核心功能）

1. **systemController.getSessions()**
   - 当前返回空数组
   - 导致前端无法显示会话列表
   - 修复时间：≈30 分钟

2. **systemController.getTeams()**
   - 当前返回空数组
   - 导致前端无法显示团队列表
   - 修复时间：≈20 分钟

### 🟡 P1 - 重要（影响用户体验）

3. **boardController 动态扫描部门**（BUG-002）
   - 当前硬编码 9 个部门
   - 无法自适应新增部门
   - 修复时间：≈30 分钟

### 🟢 P2 - 一般（代码质量）

4. **constants.js 动态路径**（BUG-003）
   - 当前硬编码扫描路径
   - 影响可移植性
   - 修复时间：≈15 分钟

5. **删除冗余 getBots()**
   - 与 scanBots() 功能重复
   - 修复时间：≈5 分钟

---

## 🎯 推荐修复顺序

```
1. systemController.getSessions()    [P0] 30 min
2. systemController.getTeams()       [P0] 20 min
3. boardController 动态部门扫描      [P1] 30 min
4. constants.js 动态路径             [P2] 15 min
5. 删除冗余 getBots()                [P2] 5 min
─────────────────────────────────────────────
总计                                       100 min (≈1.7 小时)
```

---

## 📊 匹配度总结

| 模块 | 功能 | 匹配度 | 状态 |
|------|------|--------|------|
| scanBots() | 个人列表自动获取 | 🟢 100% | ✅ 完美 |
| auto-create-groups.js | 群列表自动创建 | 🟢 100% | ✅ 完美 |
| getSessions() | 会话列表 | 🔴 0% | ❌ 待实现 |
| getTeams() | 团队列表 | 🔴 0% | ❌ 待实现 |
| boardController | 部门列表 | 🟡 70% | ⚠️ 硬编码 |
| constants.js | 路径配置 | 🟡 80% | ⚠️ 硬编码 |

**总体匹配度**: 🟡 **70%** （2/6 完美，2/6 待实现，2/6 需优化）

---

## ✅ 下一步行动

### 立即修复（今天完成）
1. 实现 `getSessions()` - 从数据库查询会话
2. 实现 `getTeams()` - 读取 team_config.json

### 短期优化（本周完成）
3. 修复 boardController 硬编码部门
4. 修复 constants.js 硬编码路径

### 长期改进（可选）
5. 添加缓存机制（减少文件读取）
6. 添加文件监控（自动刷新）
7. 添加集成测试

---

**生成时间**: 2026-03-16  
**验证状态**: ⚠️ 发现 4 个待修复问题  
**预计修复时间**: 1.7 小时
