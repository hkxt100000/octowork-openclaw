# OctoWork 全系统测试检查清单

**测试时间**: 2026-03-16  
**测试人员**: Claude AI  
**测试目标**: 站在测试角度全流程测试，确保代码无bug，避免硬编码路径

---

## 🔍 关键问题发现

### ⚠️ 问题1: 部门列表硬编码

**位置**: `backend/src/controllers/boardController.js` 第17-27行

**问题描述**:
```javascript
// ❌ 硬编码的部门列表
this.departments = [
  { id: 'OctoAcademy', name: 'OctoAcademy', description: '知识学院' },
  { id: 'OctoBrand', name: 'OctoBrand', description: '品牌部门' },
  // ... 共9个部门
]
```

**影响范围**:
- 新增部门时需要修改代码
- 无法动态获取部门列表
- API `/api/board/departments` 返回的是硬编码数据

**修复方案**: 从文件系统动态扫描部门目录

---

### ⚠️ 问题2: 工作空间路径配置不一致

**位置**: `backend/tasks/task_box_watcher.js` 第15行

**问题描述**:
```javascript
// ❌ 默认路径为 ~/.octowork/departments
this.workspaceRoot = process.env.OCTOWORK_WORKSPACE || path.join(process.env.HOME || process.env.USERPROFILE, '.octowork')
this.departmentsDir = path.join(this.workspaceRoot, 'departments')
```

**实际路径**: `/home/user/webapp/departments/`

**影响范围**:
- 如果未设置 `OCTOWORK_WORKSPACE` 环境变量，会找不到部门目录
- TaskBoxWatcher 无法监控正确的 task_box 目录

**修复方案**: 
1. 统一使用环境变量 `OCTOWORK_WORKSPACE=/home/user/webapp`
2. 或在启动脚本中显式设置

---

## ✅ 测试计划

### 阶段1: 配置修复与验证

#### 1.1 动态部门列表获取
- [ ] 修复 `boardController.js` 的硬编码部门列表
- [ ] 从文件系统动态扫描 `/home/user/webapp/departments/`
- [ ] 测试 API `/api/board/departments` 能否返回所有部门
- [ ] 测试新增部门后能否自动识别

#### 1.2 工作空间路径配置
- [ ] 确认环境变量 `OCTOWORK_WORKSPACE` 是否设置
- [ ] 验证 TaskBoxWatcher 是否监控了正确的目录
- [ ] 测试跨环境运行（本地、开发、生产）

---

### 阶段2: API功能测试

#### 2.1 Board API (画板相关)
- [ ] `GET /api/board/departments` - 获取所有部门（含健康状态）
- [ ] `GET /api/board/:deptId/tasks` - 获取部门任务列表
- [ ] `GET /api/board/:deptId/tasks/:taskId` - 获取任务详情
- [ ] `PUT /api/board/:deptId/tasks/:taskId/move` - 移动任务状态
- [ ] `GET /api/board/:deptId/health` - 获取部门健康状态

#### 2.2 Event API (事件总线)
- [ ] `GET /api/octo/events/log` - 获取事件日志
- [ ] `GET /api/octo/events/log?limit=10` - 限制日志条数
- [ ] `GET /api/octo/events/stats` - 获取事件统计
- [ ] 验证事件是否正确持久化到 `octo_events.db`

#### 2.3 Notification API (通知相关)
- [ ] `POST /api/notifications/send` - 发送单个通知
- [ ] `POST /api/notifications/broadcast` - 广播通知
- [ ] `GET /api/notifications/online-users` - 获取在线用户
- [ ] `GET /api/notifications/stats` - 获取通知统计
- [ ] `GET /api/notifications/sessions/:userId` - 获取用户会话
- [ ] `GET /api/notifications/offline/:userId` - 获取离线消息
- [ ] `POST /api/notifications/offline/:userId/pull` - 拉取离线消息

#### 2.4 System API (系统健康)
- [ ] `GET /api/health` - 系统健康检查
- [ ] 验证返回数据包含 `status`, `timestamp`, `uptime`, `version`

---

### 阶段3: 群聊任务识别测试

#### 3.1 任务创建意图识别
测试用例:
```javascript
// ✅ 应该识别为任务
"@张三 任务：完成需求文档编写，明天18:00前"
"@李四 帮我做一下代码审查，紧急"
"@王五 安排部署到测试环境，本周内"

// ❌ 不应识别为任务（无@mention）
"任务：完成需求文档"
"帮我做代码审查"
```

测试项:
- [ ] 验证必须有 @mention 才识别为任务创建
- [ ] 提取任务标题是否准确
- [ ] 优先级识别是否正确（紧急、高、普通、低）
- [ ] 截止时间解析是否正确（今天、明天、本周、X天）
- [ ] 执行人是否正确分配给第一个 @mention

#### 3.2 任务状态流转意图
测试用例:
```javascript
// ✅ 接收任务
"接收任务" / "我来做" / "开始任务"

// ✅ 完成验收
"请验收" / "已完成" / "做完了"

// ✅ 问题反馈
"问题：缺少数据库权限" / "卡在部署环节"

// ✅ 进度更新
"进度：50%" / "进度更新：已完成前端部分"
```

测试项:
- [ ] 验收请求不需要 @mention 也能识别
- [ ] 问题反馈能正确提取问题描述
- [ ] 进度更新能正确提取百分比和描述

---

### 阶段4: TaskBox 文件监控测试

#### 4.1 文件监控启动
- [ ] 验证 TaskBoxWatcher 正确初始化
- [ ] 验证监控目录为 `/home/user/webapp/departments/*/task_box/`
- [ ] 验证所有9个部门都被监控

#### 4.2 文件变化事件
- [ ] 新增任务文件触发 `task_created` 事件
- [ ] 修改任务文件触发 `task_updated` 事件
- [ ] 删除任务文件触发 `task_removed` 事件
- [ ] 移动任务文件（状态变更）触发正确事件

#### 4.3 任务文件解析
测试任务文件格式:
```markdown
# 完成需求文档编写

## 基本信息

**任务ID**：TASK-20260315-ABC123
**分配人**：张三
**执行人**：李四
**创建时间**：2026-03-15 10:30:00
**优先级**：🔴 紧急 urgent
**预计完成**：2026-03-16 18:00 ⏰

进度：50%

## 任务描述
...
```

测试项:
- [ ] 任务ID提取是否正确
- [ ] 分配人/执行人提取是否正确
- [ ] 优先级解析是否正确
- [ ] 截止时间解析是否正确
- [ ] 进度百分比解析是否正确
- [ ] 问题标记识别是否正确（`## ⚠️ 问题记录`）

---

### 阶段5: WebSocket 实时推送测试

#### 5.1 连接管理
- [ ] 客户端连接成功
- [ ] 心跳机制正常（30秒间隔）
- [ ] 会话超时清理（2分钟）
- [ ] 断线重连机制

#### 5.2 事件推送
- [ ] 任务创建推送到画板订阅者
- [ ] 任务状态变更推送到相关部门
- [ ] 通知推送到指定用户
- [ ] 广播消息推送到所有在线用户

#### 5.3 消息格式
验证消息格式:
```json
{
  "type": "board_update",
  "event": "task_created",
  "data": {
    "deptId": "OctoTech-Team",
    "task": { ... }
  },
  "timestamp": 1710568800000
}
```

---

### 阶段6: 端到端业务流程测试

#### 6.1 任务完整生命周期
测试场景: 从创建到验收通过

**步骤**:
1. 张三在群聊发送: "@李四 任务：修复登录bug，紧急"
2. 系统识别任务意图，生成任务预览卡
3. 李四点击"确认"，任务创建成功
4. 任务文件写入 `OctoTech-Team/task_box/pending/TASK-xxx.md`
5. TaskBoxWatcher 检测到新文件，推送到画板
6. 李四在画板拖拽任务到"进行中"
7. 任务文件移动到 `in_progress/`
8. 李四完成任务，在群聊发送"请验收"
9. 任务状态更新为"待验收"，移动到 `completed/`
10. 张三验收通过，拖拽到"已验收"
11. 任务文件移动到 `accepted/`
12. Bot 主动通知李四任务验收通过

**验收点**:
- [ ] 任务识别准确率 >95%
- [ ] 每步状态流转正确
- [ ] WebSocket 实时推送延迟 <1秒
- [ ] 事件日志完整记录
- [ ] 通知正确送达

#### 6.2 多部门并发测试
测试场景: 3个部门同时创建任务

**步骤**:
1. OctoTech-Team 创建任务A
2. OctoAcademy 创建任务B
3. OctoBrand 创建任务C
4. 同时移动3个任务状态
5. 验证事件隔离和推送准确性

**验收点**:
- [ ] 任务不会混淆到其他部门
- [ ] 推送只发送到订阅该部门的客户端
- [ ] 并发写入无文件冲突

---

### 阶段7: 异常场景测试

#### 7.1 错误输入处理
- [ ] 无效部门ID: `GET /api/board/invalid-dept/tasks` → 404
- [ ] 无效任务ID: `GET /api/board/:deptId/tasks/invalid-task` → 404
- [ ] 无效状态: `PUT .../move` body `{newStatus: 'invalid'}` → 400
- [ ] 缺少必需参数: `PUT .../move` body `{}` → 400

#### 7.2 文件系统异常
- [ ] task_box 目录不存在时自动创建
- [ ] 任务文件损坏时不影响其他任务
- [ ] 文件读取失败时返回友好错误

#### 7.3 并发冲突
- [ ] 同时移动同一任务到不同状态
- [ ] 同时修改同一任务文件
- [ ] 大量任务创建时的性能

---

### 阶段8: 性能与压力测试

#### 8.1 API 响应时间
目标: 所有 API 响应时间 <500ms

- [ ] `/api/health` <100ms
- [ ] `/api/board/departments` <200ms
- [ ] `/api/board/:deptId/tasks` <300ms
- [ ] `/api/board/:deptId/tasks/:taskId/move` <500ms

#### 8.2 并发性能
- [ ] 20 并发用户访问画板
- [ ] 100 并发任务创建
- [ ] 200 并发 WebSocket 连接
- [ ] 吞吐量 >10 req/s

#### 8.3 大数据量测试
- [ ] 每个部门 100+ 任务卡时的渲染性能
- [ ] 事件日志 10000+ 条时的查询性能
- [ ] 长时间运行的内存占用

---

## 🐛 已知Bug列表

| 编号 | 严重性 | 问题描述 | 位置 | 状态 |
|------|--------|----------|------|------|
| BUG-001 | 🔴 高 | 部门列表硬编码，无法动态获取 | boardController.js:17 | 待修复 |
| BUG-002 | 🟠 中 | 工作空间路径默认值不正确 | task_box_watcher.js:15 | 待修复 |
| BUG-003 | 🟡 低 | 未设置环境变量时找不到部门目录 | 全局配置 | 待修复 |

---

## 📝 修复行动计划

### 优先级1: 必须立即修复
1. **动态部门列表获取**
   - 修改 `boardController.js`
   - 添加 `getDepartmentsFromFilesystem()` 方法
   - 扫描 `/home/user/webapp/departments/` 获取所有部门

2. **工作空间路径配置**
   - 在启动脚本设置 `OCTOWORK_WORKSPACE=/home/user/webapp`
   - 更新文档说明环境变量要求

### 优先级2: 建议修复
3. **添加配置校验**
   - 启动时检查 `departments/` 目录是否存在
   - 检查每个部门的 `task_box/` 结构是否完整

4. **改进错误提示**
   - 部门不存在时返回清晰的错误信息
   - 配置错误时给出修复建议

---

## ✅ 测试通过标准

### 功能完整性
- [ ] 所有 API 端点正常工作
- [ ] 任务识别准确率 >95%
- [ ] 状态流转 100% 正确
- [ ] 事件日志 100% 完整

### 性能指标
- [ ] API 响应时间 <500ms
- [ ] WebSocket 推送延迟 <1s
- [ ] 支持 20+ 并发用户
- [ ] FPS ≥55（画板渲染）

### 稳定性
- [ ] 24小时连续运行无崩溃
- [ ] 错误率 <1%
- [ ] 无内存泄漏
- [ ] 异常自动恢复

### 可维护性
- [ ] 无硬编码路径
- [ ] 配置外部化
- [ ] 错误信息清晰
- [ ] 日志完整可追溯

---

## 📊 测试结果总结

**测试时间**: 待执行  
**通过率**: 0%（未开始）  
**发现bug数**: 3个  
**修复bug数**: 0个  

**下一步行动**:
1. 修复 BUG-001: 动态部门列表获取
2. 修复 BUG-002: 工作空间路径配置
3. 运行完整测试套件
4. 更新测试结果
