# 🔍 OctoWork 功能验证检查清单

**执行时间**: 2026-03-16  
**执行人**: AI开发团队  
**目标**: 全流程功能验证，排查硬编码和Bug

---

## 📋 检查清单总览

### 关键检查点
- ✅ 动态数据获取（不能写死路径）
- ✅ 成员/群组自动发现
- ✅ 数据库路径配置
- ✅ 文件路径动态生成
- ✅ 错误处理完整性
- ✅ API端点功能完整性
- ✅ WebSocket实时推送
- ✅ 跨平台兼容性

---

## 🎯 Phase 1: 配置与环境检查

### 1.1 配置文件检查
- [ ] 检查是否有硬编码的文件路径
- [ ] 检查数据库路径是否可配置
- [ ] 检查环境变量使用情况
- [ ] 检查端口配置

### 1.2 目录结构检查
- [ ] departments目录是否动态扫描
- [ ] task_box路径是否动态生成
- [ ] 数据文件路径是否可配置

**检查脚本**:
```bash
# 搜索硬编码路径
grep -r "\/home\/user" backend/src --exclude-dir=node_modules
grep -r "C:\\\\" backend/src --exclude-dir=node_modules
grep -r "departments\/" backend/src --exclude-dir=node_modules | grep -v "path.join"
```

---

## 🔧 Phase 2: 后端核心功能检查

### 2.1 部门自动发现
**功能**: 自动扫描departments目录，获取所有部门

**检查点**:
- [ ] 是否动态读取departments目录
- [ ] 是否硬编码部门名称
- [ ] 新增部门是否自动识别

**测试方法**:
```bash
# 测试1: 检查当前部门列表
curl http://localhost:6726/api/board/departments

# 测试2: 创建新部门测试
mkdir -p departments/TestDept/task_box/{pending,in_progress,completed,accepted}
echo '{"tasks":[]}' > departments/TestDept/task_box/.index.json

# 测试3: 重启服务后检查是否识别新部门
curl http://localhost:6726/api/board/departments | jq '.departments | length'
```

### 2.2 任务文件监控
**功能**: Chokidar监控task_box变化

**检查点**:
- [ ] 是否监控所有部门的task_box
- [ ] 监控路径是否动态生成
- [ ] 文件变化是否实时推送

**测试方法**:
```bash
# 创建测试任务
echo "# Test Task" > departments/OctoAcademy/task_box/pending/test-task.md

# 检查是否触发事件
# 查看WebSocket是否推送
```

### 2.3 事件总线
**功能**: 事件发布订阅系统

**检查点**:
- [ ] 事件日志路径是否可配置
- [ ] 事件持久化是否正常
- [ ] 事件查询API是否正常

**测试方法**:
```bash
# 查询事件日志
curl http://localhost:6726/api/octo/events/log?limit=10

# 查询事件统计
curl http://localhost:6726/api/octo/events/stats

# 查询事件类型
curl http://localhost:6726/api/octo/events/types
```

### 2.4 通知系统
**功能**: 在线/离线通知管理

**检查点**:
- [ ] 离线队列路径是否可配置
- [ ] 会话管理是否正常
- [ ] 通知推送是否正常

**测试方法**:
```bash
# 获取在线用户
curl http://localhost:6726/api/notifications/online-users

# 获取通知统计
curl http://localhost:6726/api/notifications/stats

# 发送测试通知
curl -X POST http://localhost:6726/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{"userId":"test-user","message":"Test notification","priority":"normal"}'
```

### 2.5 数据库服务
**功能**: SQLite数据持久化

**检查点**:
- [ ] 数据库路径是否可配置
- [ ] 数据库是否自动创建
- [ ] 表结构是否正确初始化

**测试方法**:
```bash
# 检查数据库文件
ls -lh backend/data/chat.db

# 检查数据库表
sqlite3 backend/data/chat.db ".tables"
```

---

## 🎨 Phase 3: 前端功能检查

### 3.1 部门列表页
**功能**: 显示所有部门及健康状态

**检查点**:
- [ ] 部门列表是否从API动态获取
- [ ] 是否硬编码部门数量
- [ ] 健康状态是否实时更新

**测试方法**:
1. 打开 `/board` 路由
2. 检查是否显示所有部门
3. 检查健康状态颜色
4. 添加新部门后刷新页面

### 3.2 看板页面
**功能**: 4列看板显示任务

**检查点**:
- [ ] 任务列表是否从API动态获取
- [ ] 拖拽是否触发API更新
- [ ] WebSocket推送是否实时更新界面

**测试方法**:
1. 打开部门看板页
2. 拖动任务卡片到不同列
3. 在另一浏览器窗口查看是否同步
4. 检查控制台是否有错误

### 3.3 任务详情弹窗
**功能**: 显示和编辑任务详情

**检查点**:
- [ ] 任务数据是否完整加载
- [ ] 编辑是否触发API更新
- [ ] 评论功能是否正常

**测试方法**:
1. 点击任务卡片
2. 检查详情是否完整
3. 编辑任务信息
4. 添加评论

### 3.4 通知组件
**功能**: 显示实时通知

**检查点**:
- [ ] WebSocket连接是否正常
- [ ] 通知是否实时显示
- [ ] 离线通知是否在上线后推送

**测试方法**:
1. 打开页面建立WebSocket连接
2. 后台发送测试通知
3. 检查是否弹出通知
4. 断开网络后重连测试

---

## 🔗 Phase 4: API端点全面测试

### 4.1 系统API
```bash
# 健康检查
curl http://localhost:6726/api/health

# 系统配置
curl http://localhost:6726/api/system/config

# WebSocket统计
curl http://localhost:6726/api/system/ws-stats
```

### 4.2 Board API
```bash
# 部门列表
curl http://localhost:6726/api/board/departments

# 部门健康状态
curl http://localhost:6726/api/board/octo/OctoAcademy/health

# 部门任务列表
curl http://localhost:6726/api/board/octo/OctoAcademy/tasks
```

### 4.3 Event API
```bash
# 事件日志
curl http://localhost:6726/api/octo/events/log?limit=10

# 事件统计
curl http://localhost:6726/api/octo/events/stats

# 事件类型
curl http://localhost:6726/api/octo/events/types
```

### 4.4 Notification API
```bash
# 在线用户
curl http://localhost:6726/api/notifications/online-users

# 通知统计
curl http://localhost:6726/api/notifications/stats

# 发送通知
curl -X POST http://localhost:6726/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","message":"test","priority":"normal"}'
```

---

## 🐛 Phase 5: 常见Bug检查

### 5.1 路径硬编码问题
**问题**: 文件路径写死导致跨平台不兼容

**检查方法**:
```bash
# 搜索可能的硬编码路径
grep -r "\"\/home" backend/src
grep -r "\"C:\\\\" backend/src
grep -r "\"departments\/" backend/src | grep -v "path.join"
```

**修复标准**: 所有路径应使用`path.join()`或`path.resolve()`

### 5.2 数据源硬编码问题
**问题**: 成员列表、群组列表写死

**检查方法**:
```bash
# 搜索数组字面量
grep -r "\[\"OctoAcademy\"" backend/src
grep -r "const departments = \[" backend/src
grep -r "const members = \[" backend/src
```

**修复标准**: 应从文件系统或数据库动态读取

### 5.3 配置硬编码问题
**问题**: 端口、数据库路径等配置写死

**检查方法**:
```bash
# 搜索端口配置
grep -r "6726" backend/src | grep -v "comment"

# 搜索数据库路径
grep -r "chat.db" backend/src | grep -v "comment"
```

**修复标准**: 应从环境变量或配置文件读取

### 5.4 错误处理缺失
**问题**: 缺少try-catch或错误回调

**检查方法**:
```bash
# 搜索没有错误处理的异步代码
grep -A5 "async function" backend/src | grep -v "try"
grep -r "\.then(" backend/src | grep -v "catch"
```

**修复标准**: 所有异步操作应有错误处理

### 5.5 资源泄漏问题
**问题**: 文件句柄、数据库连接未关闭

**检查方法**:
```bash
# 搜索文件操作
grep -r "fs\.createReadStream" backend/src
grep -r "fs\.open" backend/src

# 检查是否有对应的close操作
```

**修复标准**: 应使用finally或close回调

---

## ⚡ Phase 6: 性能检查

### 6.1 内存泄漏检查
```bash
# 启动服务并监控内存
node --inspect server.js

# 压力测试
ab -n 1000 -c 10 http://localhost:6726/api/health
```

### 6.2 数据库性能
```bash
# 检查慢查询
sqlite3 backend/data/chat.db "EXPLAIN QUERY PLAN SELECT * FROM tasks"
```

### 6.3 文件监控性能
```bash
# 检查监控的文件数量
lsof -p $(pgrep -f "node server.js") | wc -l
```

---

## 🔐 Phase 7: 安全检查

### 7.1 输入验证
- [ ] API参数是否验证
- [ ] 文件路径是否防止遍历攻击
- [ ] SQL注入防护

### 7.2 权限控制
- [ ] WebSocket连接是否需要认证
- [ ] API是否有权限控制
- [ ] 文件操作是否限制范围

### 7.3 敏感信息
- [ ] 日志是否包含敏感信息
- [ ] 错误消息是否泄露内部信息
- [ ] 配置文件是否加密

---

## 📊 Phase 8: 数据完整性检查

### 8.1 任务数据
```bash
# 检查所有部门的.index.json
find departments -name ".index.json" -exec echo "Checking: {}" \; -exec cat {} \; -exec echo "" \;
```

### 8.2 事件日志
```bash
# 检查事件日志格式
tail -n 100 backend/data/events/events.jsonl | jq '.'
```

### 8.3 离线队列
```bash
# 检查离线队列
cat backend/data/offline_queue/offline_queue.json | jq '.'
```

---

## ✅ Phase 9: 验收标准

### 9.1 功能完整性
- [ ] 所有API端点返回正确数据
- [ ] 所有前端页面正常显示
- [ ] 所有交互功能正常工作

### 9.2 动态性
- [ ] 新增部门自动识别
- [ ] 新增成员自动识别
- [ ] 配置变更无需修改代码

### 9.3 稳定性
- [ ] 长时间运行无内存泄漏
- [ ] 异常情况自动恢复
- [ ] 错误日志完整

### 9.4 性能
- [ ] API响应 < 500ms
- [ ] WebSocket延迟 < 100ms
- [ ] 文件监控响应 < 1s

---

## 🔧 自动化检查脚本

```bash
#!/bin/bash
# functional-check.sh

echo "=== OctoWork 功能验证检查 ==="
echo ""

# 1. 检查硬编码路径
echo "1. 检查硬编码路径..."
HARDCODED=$(grep -r "\/home\/user\|C:\\\\" backend/src --exclude-dir=node_modules 2>/dev/null | wc -l)
if [ $HARDCODED -gt 0 ]; then
    echo "⚠️  发现 $HARDCODED 处硬编码路径"
    grep -r "\/home\/user\|C:\\\\" backend/src --exclude-dir=node_modules
else
    echo "✅ 无硬编码路径"
fi
echo ""

# 2. 检查部门动态加载
echo "2. 检查部门列表..."
RESPONSE=$(curl -s http://localhost:6726/api/board/departments)
DEPT_COUNT=$(echo $RESPONSE | jq '.departments | length')
echo "📊 当前部门数: $DEPT_COUNT"
echo ""

# 3. 检查所有API端点
echo "3. 检查API端点..."
ENDPOINTS=(
    "/api/health"
    "/api/board/departments"
    "/api/octo/events/log?limit=5"
    "/api/notifications/stats"
    "/api/system/config"
)

for endpoint in "${ENDPOINTS[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:6726$endpoint")
    if [ $STATUS -eq 200 ]; then
        echo "✅ $endpoint - $STATUS"
    else
        echo "❌ $endpoint - $STATUS"
    fi
done
echo ""

# 4. 检查数据库
echo "4. 检查数据库..."
if [ -f "backend/data/chat.db" ]; then
    SIZE=$(du -h backend/data/chat.db | cut -f1)
    echo "✅ 数据库存在 (大小: $SIZE)"
else
    echo "❌ 数据库不存在"
fi
echo ""

# 5. 检查事件日志
echo "5. 检查事件日志..."
if [ -f "backend/data/events/events.jsonl" ]; then
    EVENTS=$(wc -l < backend/data/events/events.jsonl)
    echo "✅ 事件日志存在 ($EVENTS 条记录)"
else
    echo "❌ 事件日志不存在"
fi
echo ""

echo "=== 检查完成 ==="
```

---

## 📝 检查记录表

| 检查项 | 状态 | 发现问题 | 修复方案 | 验证人 |
|--------|------|----------|----------|--------|
| 配置硬编码 | ⬜ | | | |
| 路径硬编码 | ⬜ | | | |
| 部门动态获取 | ⬜ | | | |
| 成员动态获取 | ⬜ | | | |
| API功能完整性 | ⬜ | | | |
| WebSocket推送 | ⬜ | | | |
| 错误处理 | ⬜ | | | |
| 性能指标 | ⬜ | | | |
| 安全检查 | ⬜ | | | |
| 数据完整性 | ⬜ | | | |

---

*检查清单版本: v1.0*  
*创建时间: 2026-03-16*  
*最后更新: 2026-03-16*
