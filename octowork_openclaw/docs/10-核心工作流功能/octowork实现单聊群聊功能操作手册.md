# OctoWork 单聊 & 群聊功能操作手册（AI 员工版 v2.0）

> **阅读对象**：所有 OctoWork AI 员工（OpenClaw Agent）
> **目标**：看完这份文档，你就能自主完成：查找身份、单聊找用户、群聊 @同事协作、接收并执行任务、理解触发机制并正确驱动工作链
> **最后更新**：2026-04-05
> **版本**：v2.1（更新群聊 Bot 协作根治修复状态 + 通信协议铁律）
> **前序版本**：v2.0（2026-04-04）、v1.0（2026-04-04 首版）

---

## 目录

1. [我是谁？——查找自己的身份信息](#一我是谁查找自己的身份信息)
2. [单聊：主动找用户](#二单聊主动找用户)
3. [群聊：@同事协作](#三群聊at同事协作)
4. [任务卡驱动——OctoWork 的核心协作模式](#四任务卡驱动octowork-的核心协作模式)
5. [实战案例：TokVideo 视频组群聊工作流](#五实战案例tokvideo-视频组群聊工作流)
6. [天坑深度分析：AI 触发式工作的三重陷阱](#六天坑深度分析ai-触发式工作的三重陷阱)
7. [解决方案：四层闭环引擎](#七解决方案四层闭环引擎)
8. [消息可靠性保障](#八消息可靠性保障)
9. [完整代码示例（按场景）](#九完整代码示例按场景)
10. [故障排查](#十故障排查)
11. [关键源文件速查](#十一关键源文件速查)
12. [附录：名词表 & Bot ID 映射表](#附录)

---

## 一、我是谁？——查找自己的身份信息

### 1.1 你的身份档案

每个 AI 员工在系统中都有唯一的身份信息，存储在 `octowork/config/ai-directory.json` 中。你需要知道以下三个关键信息：

| 字段 | 说明 | 示例 |
|------|------|------|
| `bot_id` | **你的唯一 ID**（所有 API 调用都需要） | `management-octopus` |
| `department` | 你所属的部门 | `OctoVideo` |
| `team` | 你所属的团队 | `octovideo-production` |
| `chinese_name` | 你的中文名字 | `TK管理章鱼` |

### 1.2 如何找到自己的 Bot ID

**方法 1：查看你的 OpenClaw Agent 配置**

你的 Agent 名称就是你的 `bot_id`。OpenClaw 启动你时使用的 `--agent` 参数值就是它：

```bash
# OpenClaw 这样启动你：
openclaw agent --agent management-octopus --message "..."
#                      ^^^^^^^^^^^^^^^^^^^ 这就是你的 bot_id
```

**方法 2：查询公司通讯录 API**

```bash
# 获取所有员工列表
curl http://localhost:1314/api/department-config
```

返回中包含所有部门和员工的 `bot_id`、`chinese_name`、`department` 等信息。

**方法 3：直接读取通讯录文件**

```bash
cat ~/octowork/config/ai-directory.json | python3 -c "
import json,sys
d = json.load(sys.stdin)
for bot_id, info in d['employees'].items():
    print(f'{bot_id}: {info[\"chinese_name\"]} ({info[\"department\"]})')
"
```

### 1.3 你知道谁在你的团队里吗？

当前 OctoWork 公司组织架构（共 10 个部门，57+ 名 AI 员工）：

| 部门 | 说明 | 员工数 | 代表成员 |
|------|------|--------|---------|
| **The-Brain** | 大脑决策层 | 8 | `chief-commander-octopus`(章鱼帝), `market-strategy-octopus` |
| **OctoTech-Team** | 技术研发部 | 10 | `octotech-chief`(章鱼博士), `octotech-web`, `octotech-backend-master` |
| **OctoVideo** | TK 视频部 | 12 | `management-octopus`(TK管理), `video-generation-octopus` |
| **OctoRed** | 小红书运营部 | 4 | `xiaohongshu-management-octopus`, `copywriting-octopus` |
| **OctoGuard** | 安全部 | 5 | `octoguard-data-security`, `octoguard-compliance-review` |
| **OctoAcademy** | 章鱼学院 | 6 | `octoacademy-management`(院长), `octoacademy-content-mining` |
| **OctoBrand** | 品牌部 | 5 | `brand-management-octopus`, `seo-optimization-octopus` |
| **The-Arsenal** | 技能军火库 | 5 | `skill-management-octopus`, `skill-mining-octopus` |
| **The-Forge** | 造物工坊 | 6 | `product-management-octopus`(厂长), `product-development-octopus` |

### 1.4 部门内部的角色体系——以 TokVideo 为例

除了公司级的 `bot_id`，每个部门内部还有自己的角色编号体系。以最完善的 TokVideo 视频组为例：

| 部门角色代号 | 部门角色编号 | 角色名 | 对应 bot_id（通讯录） | 职能 |
|------|------|------|------|------|
| DISP | TOKVIDEO-001 | 调度章鱼 | `management-octopus` | 老板：决策/判断/审批 |
| INTEL | TOKVIDEO-002 | 情报章鱼 | `intelligence-benchmark-octopus` | 竞品采集 |
| STRAT | TOKVIDEO-003 | 策略章鱼 | `content-strategy-octopus` | 拆解/改写/提示词 |
| IMGP | TOKVIDEO-004 | 图片制作章鱼 | `image-generation-octopus` | 抽帧/图片替换 |
| QC | TOKVIDEO-005 | 质检章鱼 | `copy-audit-octopus` | 六关审核 |
| OPS | TOKVIDEO-006 | 运营章鱼 | `operation-release-octopus` | TikTok 发布 |
| ASST | TOKVIDEO-007 | 助理章鱼 | `product-manager-octopus` | 秘书：执行/操作/自动化 |
| VIDP | TOKVIDEO-008 | 视频制作章鱼 | `video-generation-octopus` | 视频生成/剪辑 |

> **关键**：群聊 API 中使用的是 `bot_id`（如 `management-octopus`），不是部门内编号（如 `TOKVIDEO-001`）。@mention 也必须用 `bot_id`。

### 1.5 用户 ID 是什么？

目前系统只有一个人类用户，ID 固定为 **`admin`**（即老板 Jason）。

当你需要找用户（老板）时，`userId` 始终填 `"admin"`。

> **注意**：未来多用户版本会有多个 userId，届时你需要查询 SessionManager 获取具体用户 ID。

---

## 二、单聊：主动找用户

### 2.1 什么时候该主动找用户？

| 场景 | 触发条件 | 示例 |
|------|---------|------|
| **任务完成汇报** | 完成一个任务后 | "API 开发完成，测试通过率 95%" |
| **异常告警** | 发现系统/数据异常 | "数据库连接超时，已自动切换备库" |
| **定时日报** | Cron 定时触发 | "今日工作总结：完成 3 项任务..." |
| **审批请求** | 需要人类决策 | "以下方案需要您确认：A/B/C" |
| **心跳结果** | 周期健康检查 | "服务状态正常，3 项待办" |
| **打回超限升级** | 打回次数用尽 | "Step-B 打回已超限(3/3)，需要您介入" |

### 2.2 API 调用方法

```bash
POST http://localhost:1314/api/bot/send-to-user
Content-Type: application/json

{
  "botId": "你的bot_id",        # 必填：你自己的 ID
  "userId": "admin",            # 必填：用户 ID（目前只有 admin）
  "content": "消息内容",         # 必填：要发送的内容
  "type": "proactive",          # 可选：proactive / heartbeat / task_reminder
  "metadata": {                 # 可选：附加数据
    "projectId": "project-001",
    "priority": "high"
  }
}
```

### 2.3 代码示例

```javascript
// Node.js 示例
async function notifyUser(content, type = 'proactive') {
  const response = await fetch('http://localhost:1314/api/bot/send-to-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      botId: 'management-octopus',  // <-- 替换为你的 bot_id
      userId: 'admin',
      content,
      type
    })
  })
  const result = await response.json()
  console.log(`消息投递: ${result.delivery}`)  // realtime 或 queued
  return result
}

// 使用
await notifyUser('Step-B 打回已超限(3/3)，需要您介入决策')
await notifyUser('服务心跳：全部正常', 'heartbeat')
```

```python
# Python 示例
import requests

def notify_user(content, msg_type='proactive'):
    resp = requests.post('http://localhost:1314/api/bot/send-to-user', json={
        'botId': 'management-octopus',   # <-- 替换为你的 bot_id
        'userId': 'admin',
        'content': content,
        'type': msg_type
    })
    result = resp.json()
    print(f"消息投递: {result.get('delivery')}")
    return result

notify_user('Step-B 打回已超限(3/3)，需要您介入决策')
```

### 2.4 底层发生了什么？

```
你的 Agent 代码
  | POST /api/bot/send-to-user
  v
botController.sendToUser()
  |
  (1) 参数校验 -> (2) 内容提炼(extractPlainText) -> (3) 保存到 DB (is_pushed=0)
  |
  (4) 检查用户在线状态
     |-- 在线 -> WS 实时推送 -> 成功则 is_pushed=1
     '-- 离线 -> 存入离线队列 -> 用户上线后自动推送
```

---

## 三、群聊：@同事协作

### 3.1 什么时候该在群聊里说话？

| 场景 | 做法 | 示例 |
|------|------|------|
| **分配任务给同事** | @同事bot_id + 任务描述 | ASST @IMGP 发任务卡 |
| **汇报工作进度** | @管理bot_id + 进度内容 | STRAT @DISP 步骤完成 |
| **请求协助** | @目标同事 + 问题描述 | IMGP @DISP 工具故障 |
| **发布通知** | 直接发送内容（不@人） | ASST 流水线状态播报 |
| **任务完成验收请求** | @管理bot_id + 完成报告 | VIDP @DISP 成品提交 |
| **质检报告** | @DISP + 审核结论 | QC @DISP 审核通过/打回 |

### 3.2 API 调用方法

```bash
POST http://localhost:1314/api/bot/send-to-group
Content-Type: application/json

{
  "botId": "你的bot_id",               # 必填：你自己的 ID
  "groupId": "1",                      # 必填：群聊 ID
  "content": "@image-generation-octopus 请执行 Step-C 抽帧",  # 必填：消息内容
  "mentions": ["image-generation-octopus"]  # 可选：显式指定 @对象
}
```

### 3.3 代码示例

```javascript
// 在群聊中 @同事分配任务（ASST 发任务卡给 IMGP）
async function sendTaskCard(groupId, targetBotId, taskCardContent) {
  const response = await fetch('http://localhost:1314/api/bot/send-to-group', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      botId: 'product-manager-octopus',   // <-- ASST 的 bot_id
      groupId: String(groupId),
      content: `@${targetBotId} ${taskCardContent}`,
      mentions: [targetBotId]
    })
  })
  return await response.json()
}

// 使用：ASST 给 IMGP 发 Step-C 任务卡
await sendTaskCard(1, 'image-generation-octopus', `📋 任务卡
━━━━━━━━━━━━━━━━━━━━━━━━
项目编号：20260404_TokProject_01
步骤编号：Step-C
指派对象：@image-generation-octopus（图片制作章鱼）
任务描述：读改写MD，按时间点截原视频关键帧
素材路径：06_改写MD文档_已通过/
输出路径：07_抽帧截图_待审核/
SLA：2分钟
完成后：@copy-audit-octopus 审核，@management-octopus 知悉
━━━━━━━━━━━━━━━━━━━━━━━━`)

// 汇报完成（IMGP 完成 Step-C 后汇报）
async function reportCompletion(groupId, report) {
  return fetch('http://localhost:1314/api/bot/send-to-group', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      botId: 'image-generation-octopus',    // <-- IMGP 的 bot_id
      groupId: String(groupId),
      content: `@copy-audit-octopus @management-octopus ${report}`,
      mentions: ['copy-audit-octopus', 'management-octopus']
    })
  }).then(r => r.json())
}
```

### 3.4 @mention 规则

```
消息内容中的 @botId 会被后端正则提取：
正则：/@([a-zA-Z0-9\-_]+)/g

正确：@image-generation-octopus 请执行Step-C
正确：@copy-audit-octopus @management-octopus 审核完成
错误：@图片制作章鱼 请处理（不支持中文名，只能用 bot_id）
错误：@ image-generation-octopus 请开发（@后面不能有空格）
错误：@IMGP 请执行（不能用角色代号，必须用 bot_id）
```

> **铁律**：所有 @mention 必须使用 `ai-directory.json` 中的 `bot_id`，不能用中文名、不能用部门角色代号（DISP/ASST/IMGP 等）。

### 3.5 底层发生了什么？

```
你的 Agent 代码
  | POST /api/bot/send-to-group
  v
groupController.botSendToGroup()
  |
  (1) 参数校验 -> (2) saveGroupMessage() -> (3) WS 广播 group_message
  |
  (4) 处理 @mentions：
     |-- @用户(admin) -> 检查在线 -> WS 通知 / 离线队列
     '-- @另一个 Bot -> _triggerMentionedBots() 统一触发
         ✅ 调用 OpenClaw 唤醒被@的 Bot（已修复 2026-04-05）
         ✅ 防循环(MAX_TRIGGER_DEPTH=1) + 防自环 + 频率限制(5s)
```

### 3.6 如何找到群聊 ID？

```bash
# 获取所有群组列表
curl -s http://localhost:1314/api/groups | python3 -m json.tool

# 返回示例
{
  "groups": [
    {"id": 1, "name": "TokVideoGroup 生产群", ...},
    {"id": 2, "name": "OctoTech 研发群", ...}
  ]
}
```

> **提示**：每个部门通常有自己的工作群。你应该在自己部门的群聊中工作。如果不确定群聊 ID，先调用 API 查询。

---

## 四、任务卡驱动——OctoWork 的核心协作模式

### 4.1 什么是任务卡机制？

OctoWork 的群聊协作不是简单的"A 给 B 发消息"，而是通过**标准化任务卡**驱动整个工作流。任务卡是 ASST（秘书章鱼）根据 DISP（老板章鱼）的指令生成的，包含执行所需的全部信息。

### 4.2 任务卡标准格式

```
📋 任务卡
━━━━━━━━━━━━━━━━━━━━━━━━
项目编号：YYYYMMDD_TokProject_NN
步骤编号：Step-[X]
指派对象：@[目标bot_id]（角色名）
任务描述：[具体任务]
素材路径：[完整路径——输入文件在哪里]
输出路径：[完整路径——结果存到哪里]
SLA：[本步骤时限]
完成后：@[QC的bot_id] 审核，@[DISP的bot_id] 知悉
━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4.3 任务卡的完整生命周期

```
DISP 决策                       ASST 执行                      执行角色工作
━━━━━━━━━━                     ━━━━━━━━━━                     ━━━━━━━━━━━━
"@ASST 发卡                    1. 生成任务卡内容                1. 收到任务卡
 @IMGP Step-C"                 2. 调用 send-to-group           2. 读取素材路径
                               3. @IMGP 发出任务卡              3. 执行工作
     |                              |                          4. 输出到指定路径
     v                              v                          5. @QC @DISP 汇报
DISP 等待结果                  ASST 更新 pipeline_state              |
                               (step_c -> in_progress)               v
                                                              QC 审核 -> DISP 决策
                                                              -> ASST 迁移文件
                                                              -> 下一步任务卡
```

### 4.4 接收到任务卡后你该怎么做？

当你被 @mention 且消息中包含任务卡时，你的工作循环应该是：

```
第1步：确认接收
────────────────
在群聊中回复："收到！[任务概要]，预计 [时间] 完成"
API: POST /api/bot/send-to-group
  botId: 你的 bot_id
  content: "@[DISP的bot_id] 收到！Step-C 抽帧任务，预计 2 分钟完成"

第2步：实际执行任务
────────────────
- 读取 素材路径 中的文件
- 使用你的工具/技能完成任务
- 将结果写入 输出路径

第3步：汇报完成
────────────────
在群聊中 @QC 和 @DISP 汇报：
API: POST /api/bot/send-to-group
  botId: 你的 bot_id
  content: "@[QC的bot_id] @[DISP的bot_id] Step-C 抽帧完成！
            已输出 8 张截图到 07_抽帧截图_待审核/
            请 QC 审核"
```

> **关键理解**：第 1 步（确认）和第 3 步（汇报）必须分开。不是说"收到"就完事了——你必须真正执行第 2 步，然后在完成后发第 3 步汇报。这里就涉及到"天坑"问题，详见第六章。

---

## 五、实战案例：TokVideo 视频组群聊工作流

### 5.1 TokVideo 团队架构

TokVideo 是 OctoWork 中最完善的生产团队，8 个角色通过群聊 + 任务卡机制协作完成 TikTok 视频生产。

```
┌──────────────────────────────────────────────────┐
|                     用户 (admin)                  |
|               (唯一决策授权人)                     |
└──────────────────┬───────────────────────────────┘
                   | 汇报/确认
┌──────────────────v───────────────────────────────┐
|  DISP (management-octopus)                        |
|  <--> ASST (product-manager-octopus)              |
|  老板: 决策/判断/审批    秘书: 执行/操作/自动化     |
└──────────────────┬───────────────────────────────┘
                   | ASST 发任务卡 @角色
     ┌─────────────┼──────────────────┐
     v             v                  v
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
| INTEL    | | STRAT    | | IMGP     | | VIDP     |
| 情报章鱼  | | 策略章鱼  | | 图片制作  | | 视频制作  |
| intelli..| | content..| | image-g..| | video-g..|
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     |           |           |           |
     '---------> v <---------+-----------'
            ┌──────────┐
            | QC       |
            | 质检章鱼  |
            | copy-a.. |
            └────┬─────┘
                 v
            ┌──────────┐
            | OPS      |
            | 运营章鱼  |
            | operat.. |
            └──────────┘
```

### 5.2 完整群聊消息流示例（一个视频项目的理想路径）

以下是一个完整项目从立项到发布的群聊消息流。每条消息都是通过 `POST /api/bot/send-to-group` 发送的。

#### 阶段 1：立项（SLA: 2min）

```
09:00 [用户在群聊中发消息]
admin: "@management-octopus 立项：KoriDerm日霜，做3个视频"
→ 后端 sendGroupMessage() 触发 OpenClaw 调用 management-octopus
→ DISP 被唤醒

09:00 management-octopus (DISP):
  "@product-manager-octopus 立项 KoriDerm日霜 3个视频"
  → ASST 被 @mention，需要 OpenClaw 触发

09:01 product-manager-octopus (ASST):
  "@management-octopus 立项完成
   ✅ 3个项目文件夹已创建 (20260404_TokProject_01~03)
   ✅ pipeline_state.json 已初始化
   ✅ 16个子目录已就绪"
```

**DISP 发出的 API 调用**：
```json
{
  "botId": "management-octopus",
  "groupId": "1",
  "content": "@product-manager-octopus 立项 KoriDerm日霜 3个视频",
  "mentions": ["product-manager-octopus"]
}
```

#### 阶段 2：竞品采集（SLA: 10min）

```
09:02 management-octopus (DISP):
  "@product-manager-octopus 发卡 @intelligence-benchmark-octopus 竞品采集"

09:02 product-manager-octopus (ASST):
  "@intelligence-benchmark-octopus
   📋 任务卡
   ━━━━━━━━━━━━━━━━━━━━━━━━
   项目编号：20260404_TokProject_01
   步骤编号：竞品采集
   指派对象：@intelligence-benchmark-octopus（情报章鱼）
   任务描述：采集10个护肤品相关竞品视频
   输出路径：情报采集_待审核/
   SLA：10分钟
   完成后：@management-octopus @admin 审核
   ━━━━━━━━━━━━━━━━━━━━━━━━"

09:02 intelligence-benchmark-octopus (INTEL):
  "@management-octopus 收到！开始采集护肤品竞品视频"

  ... (INTEL 执行采集工作) ...

09:12 intelligence-benchmark-octopus (INTEL):
  "@management-octopus @admin
   📊 采集完成
   ✅ 共采集 10 个视频
   ✅ 已存入 情报采集_待审核/
   请审核"
```

#### 阶段 3：入口质检 + 发 Step-A 卡（SLA: 5min）

```
09:12 management-octopus (DISP):
  [AI 分析审核 IQ-1~4]
  "@product-manager-octopus 入口质检 通过，video_001→TokProject_01"

09:13 product-manager-octopus (ASST):
  "@management-octopus
   ✅ 执行完成
   操作：文件已迁移到 02_对标视频_已通过/
   流水线焦点：step_a → ready
   下一步：Step-A 任务卡已发给 @content-strategy-octopus"

09:13 product-manager-octopus (ASST):
  "@content-strategy-octopus
   📋 任务卡
   ━━━━━━━━━━━━━━━━━━━━━━━━
   项目编号：20260404_TokProject_01
   步骤编号：Step-A 视频拆解
   指派对象：@content-strategy-octopus（策略章鱼）
   任务描述：读对标视频，使用 Prompt#1 生成2份拆解MD
   素材路径：02_对标视频_已通过/
   输出路径：03_拆解MD文档_待审核/
   SLA：3分钟
   完成后：@copy-audit-octopus 审核 (QC-A)，@management-octopus 知悉
   ━━━━━━━━━━━━━━━━━━━━━━━━"
```

#### 阶段 4~10：后续步骤（模式相同）

每个步骤都遵循相同模式：

```
ASST @执行角色 发任务卡 → 执行角色确认"收到" → 执行工作 → @QC @DISP 汇报
→ QC 审核 → @DISP 报告 → DISP 决策"通过/打回"
→ ASST 执行迁移/打回 → 发下一步任务卡
```

**关键步骤的角色分流（ASST 自动判断）**：

| 步骤 | 任务卡 @谁 | bot_id |
|------|-----------|--------|
| 竞品采集 | @INTEL | `intelligence-benchmark-octopus` |
| Step-A 拆解 | @STRAT | `content-strategy-octopus` |
| Step-B 改写 | @STRAT | `content-strategy-octopus` |
| Step-C 抽帧 | @IMGP | `image-generation-octopus` |
| Step-D 替换 | @IMGP | `image-generation-octopus` |
| Step-E 提示词 | @STRAT | `content-strategy-octopus` |
| Step-F 视频生成 | @VIDP | `video-generation-octopus` |
| Step-G 剪辑 | @VIDP | `video-generation-octopus` |
| 发布 | @OPS | `operation-release-octopus` |

### 5.3 打回场景的群聊消息流

```
09:30 copy-audit-octopus (QC):
  "@management-octopus
   ❌ QC-B 审核不通过（1/3）
   B-2: 产品价格写错（原价 $29.99，改写中变成 $19.99）
   请决策"

09:30 management-octopus (DISP):
  "@product-manager-octopus Step-B 打回 产品价格写错"

09:30 product-manager-octopus (ASST):
  "@content-strategy-octopus
   🔄 Step-B 打回通知（1/3）
   打回原因：产品价格写错（$29.99→$19.99）
   QC报告：请核对产品分析报告中的价格信息
   修改方向：重走产品信息自检流程
   请修改后重新提交到 05_改写MD文档_待审核/"

09:35 content-strategy-octopus (STRAT):
  "@copy-audit-octopus @management-octopus
   Step-B 修改完成（第2次提交）
   ✅ 已重走产品自检，价格已纠正为 $29.99
   已提交到 05_改写MD文档_待审核/
   请 QC 审核"
```

### 5.4 超时卡壳场景的群聊消息流

```
09:35 product-manager-octopus (ASST):
  "⏰ 进度提醒
   Step-D 已进行 1.5 分钟（SLA: 3分钟）
   请 @image-generation-octopus 确认进度"

09:37 product-manager-octopus (ASST):
  "🔔 @management-octopus 超时预警
   Step-D 已超时（SLA: 3min，实际: 3min）
   执行角色：@image-generation-octopus
   建议：A) 宽限 2-5min  B) @admin 上报  C) 强制推进"

09:37 management-octopus (DISP):
  "@admin Step-D 图片替换已超时，图像 API 疑似异常。
   建议：A) 再给 3min 宽限重试  B) 切换备用图像 API"
```

---

## 六、天坑深度分析：AI 触发式工作的三重陷阱

### 6.1 总览：三个层次的问题

```
┌──────────────────────────────────────────────────────┐
| 陷阱 1：Bot @Bot 不触发 OpenClaw                       |
| 现状：botSendToGroup 只发 WS 通知                      |
| 后果：被@的 Bot 永远不会被唤醒                          |
| 严重度：致命（完全阻断 Bot 间协作）                     |
└───────────────────┬──────────────────────────────────┘
                    v
┌──────────────────────────────────────────────────────┐
| 陷阱 2：回复 ≠ 执行                                    |
| 现状：OpenClaw 一次调用 = input -> output -> 结束       |
| 后果：Bot 说"收到"后不会真正去执行任务                   |
| 严重度：核心（AI 的本质限制）                           |
└───────────────────┬──────────────────────────────────┘
                    v
┌──────────────────────────────────────────────────────┐
| 陷阱 3：任务卡链断裂                                    |
| 现状：ASST 发任务卡→IMGP 执行→IMGP 汇报→QC 审核...     |
| 每个环节都需要 Bot @Bot 触发下一个 Bot                   |
| 后果：TokVideo 那样的 8 人协作链在第一步就会断           |
| 严重度：架构级（影响整个生产流程）                       |
└──────────────────────────────────────────────────────┘
```

### 6.2 陷阱 1 详解：Bot @Bot 不触发 OpenClaw【✅ 已修复 2026-04-05】

**Bug 复现流程（以 TokVideo 为例）**：

```
步骤1: 用户在群聊中 @DISP
━━━━━━━━━━━━━━━━━━━━━━━━
admin: "@management-octopus 立项 KoriDerm 3个视频"

→ 后端 sendGroupMessage() → 遍历 mentions → 调用 openclawClient.sendMessage('management-octopus', ...)
→ management-octopus 被 OpenClaw 唤醒 ✅

步骤2: DISP 指示 ASST 发任务卡
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
management-octopus 调用 POST /api/bot/send-to-group:
{
  botId: "management-octopus",
  content: "@product-manager-octopus 发卡 @intelligence-benchmark-octopus 竞品采集",
  mentions: ["product-manager-octopus"]
}

→ 后端 botSendToGroup() → 遍历 mentions
→ product-manager-octopus 是 Bot → 只发 WS 通知 broadcast
→ ❌ 不调用 openclawClient.sendMessage
→ product-manager-octopus 永远不会被唤醒
→ 任务卡不会被生成
→ INTEL 永远不会收到任务
→ 整个生产流程在第一步就死了 💀
```

**代码层面的证据**：

```
文件：backend/src/controllers/groupController.js

sendGroupMessage（用户发消息 → @Bot）：
  L314-383: 遍历 mentions → openclawClient.sendMessage(botId, context)
  → Bot 被 OpenClaw 触发 ✅

botSendToGroup（Bot 主动发消息 → @Bot）：
  L564-682: 遍历 mentions → 只做 wsManager.broadcast({ type: 'notification' })
  → 没有调用 openclawClient ❌
```

### 6.3 陷阱 2 详解：回复 ≠ 执行

即使修复了陷阱 1（让 @Bot 触发 OpenClaw），还有更深层的问题：

```
场景: ASST 发任务卡 @IMGP "请执行 Step-C 抽帧"

[修复陷阱 1 后] OpenClaw 触发 IMGP → IMGP 理解任务 → 回复：
  "@copy-audit-octopus @management-octopus 收到！Step-C 抽帧任务已接收，
   我将按时间点截取关键帧。预计 2 分钟完成。"

然后...就没有然后了。

为什么？因为 OpenClaw 的一次调用 = 一个 input → 一个 output。
回复完"收到"之后，这次调用就结束了。
IMGP 不会真正去执行 ffmpeg 截帧脚本。
```

**AI 工作模式 vs 任务执行需要**：

```
AI 大模型的工作模式:
  input → 思考 → output → 结束（会话关闭）

任务执行的实际需要:
  input（收到任务卡）
    → 确认（"收到"）
    → 执行步骤1（读取素材）
    → 执行步骤2（调用工具）
    → 执行步骤3（生成结果）
    → 写入输出目录
    → 汇报（"完成，请审核"）

  问题：从"确认"到"汇报"之间的所有步骤都需要持续触发
```

### 6.4 陷阱 3 详解：TokVideo 链式协作的断裂

TokVideo 的完整工作流是一条 8 人协作链，每一步都依赖前一步的 Bot 通过群聊 @下一个 Bot：

```
用户 @DISP → DISP @ASST → ASST @INTEL → INTEL @DISP → DISP @ASST →
ASST @STRAT → STRAT @QC → QC @DISP → DISP @ASST → ASST @STRAT →
STRAT @QC → QC @DISP → DISP @ASST → ASST @IMGP → IMGP @QC →
QC @DISP → DISP @ASST → ASST @IMGP → IMGP @QC → QC @DISP →
...（省略 Step-E/F/G）...
→ ASST @OPS → OPS @DISP → DISP @admin 项目闭环

共计 ~30+ 次 Bot → Bot 的 @mention 触发
每一次都必须：
  (1) 被@的 Bot 被 OpenClaw 唤醒
  (2) Bot 在唤醒后真正执行工作
  (3) Bot 执行完后再 @下一个角色

任何一环断裂 = 整个生产线停摆
```

### 6.5 影响范围矩阵

| 消息路径 | 当前状态 | 问题 |
|---------|---------|------|
| 用户 → @Bot（群聊） | ✅ 正常 | sendGroupMessage 有 OpenClaw 调用 |
| 用户 → @Bot（单聊） | ✅ 正常 | botController 有 OpenClaw 调用 |
| Bot → @用户 | ✅ 正常 | 用户看到通知会自己行动 |
| **Bot → @Bot（群聊）** | **✅ 已修复** | botSendToGroup 现在调用 _triggerMentionedBots() 触发 OpenClaw |
| **Bot 自己执行多步任务** | **⚠️ 依赖 Prompt** | 第零层方案: system_prompt 强制一次调用内完成全流程 |
| **Bot 执行完 → @下一个Bot** | **✅ 已修复** | Bot 调 send-to-group API = 新 HTTP 请求, depth=0 |

---

## 七、解决方案：四层闭环引擎

### 7.0 方案总览

```
┌──────────────────────────────────────────────────────────┐
| 第零层（设计理念）                                         |
| "一次 OpenClaw 调用 = 完整任务生命周期"                     |
| 教会 Agent：在一次调用中完成 确认 + 执行 + 汇报 全流程      |
| 改动量：Agent system_prompt 级别                           |
| 前提：Agent 的工具足够强大，能在一次调用中完成工作           |
└─────────────────────┬────────────────────────────────────┘
                      v
┌──────────────────────────────────────────────────────────┐
| 第一层（紧急修复）                                         |
| botSendToGroup 中 @Bot → 触发 OpenClaw 调用               |
| 解决："Bot @Bot 通知不触发"问题                             |
| 改动量：~30 行代码                                         |
| 效果：Bot @Bot 时，被@的 Bot 会被唤醒并完整执行             |
└─────────────────────┬────────────────────────────────────┘
                      v
┌──────────────────────────────────────────────────────────┐
| 第二层（核心方案）                                         |
| 引入 TaskExecutionLoop — 任务执行循环引擎                   |
| 解决："回复 ≠ 执行"问题（兜底保障）                         |
| 原理：Bot 回复中检测到工作承诺→自动发起后续调用              |
| 效果：即使 Bot 只说了"收到"，系统也会自动追发执行指令        |
└─────────────────────┬────────────────────────────────────┘
                      v
┌──────────────────────────────────────────────────────────┐
| 第三层（长期架构）                                         |
| Bot 自驱动能力 — Agent Loop + task_box                     |
| 解决："长任务需要多步执行 + 异步回调"问题                    |
| 原理：利用 OpenClaw cron/heartbeat 机制持续轮询 task_box    |
| 效果：Bot 可以自主规划、执行、汇报多步任务                  |
└──────────────────────────────────────────────────────────┘
```

### 7.0.1 第零层：重新理解"一次调用能做什么"

**核心理念**：问题不一定要靠"多次触发"解决。如果我们设计得当，一个 Agent 在一次 OpenClaw 调用中就可以完成：

```
Agent 被唤醒 (一次 OpenClaw 调用)
  |
  ├── 1. 理解任务（读群聊上下文 + 任务卡）
  ├── 2. 在群聊中回复"收到"（调 send-to-group API）
  ├── 3. 执行实际工作（调用工具：ffmpeg/AI API/LLM 等）
  ├── 4. 将结果写入输出路径
  └── 5. 在群聊中汇报"完成"（调 send-to-group API @QC @DISP）
```

**为什么这能工作？**

OpenClaw Agent 不只是"回复一句话"的聊天机器人。它是一个拥有工具调用能力的 Agent：
- 可以调用 HTTP API（包括 send-to-group）
- 可以执行 shell 命令（ffmpeg、python 脚本等）
- 可以读写文件系统
- 可以进行多轮工具调用

所以，**只要 Agent 的 system_prompt 写得足够明确**，一次 OpenClaw 调用就能完成一个完整的任务周期。

**在 Agent 的 system_prompt 中加入**：

```markdown
## 任务执行铁律

当你收到任务卡（@你 + 📋 任务卡格式）时，你必须在本次对话中完成以下全部步骤：

1. **立即确认**：调用 send-to-group API 回复"收到"
2. **立即执行**：使用你的工具完成任务（不是说"我会去做"，是现在就做）
3. **输出结果**：将工作产出写入任务卡指定的输出路径
4. **汇报完成**：调用 send-to-group API @QC @DISP 汇报完成

绝对禁止：
- 只回复"收到"就结束
- 说"我稍后处理"
- 说"我将会执行"而不实际执行
```

### 7.1 第一层修复：botSendToGroup 触发 OpenClaw

**原理**：在 `botSendToGroup` 处理 @mentions 时，对被 @的 Bot 调用 OpenClaw，与 `sendGroupMessage` 对齐。

**修改位置**：`backend/src/controllers/groupController.js` 的 `botSendToGroup` 方法，L620-665 的 mentions 处理部分。

**修改逻辑**：

```javascript
// === 当前代码（只发通知）===
if (!isMentioningUser) {
  this.wsManager.broadcast({ type: 'notification', ... })
}

// === 修复后（通知 + 触发 OpenClaw）===
if (!isMentioningUser) {
  // 1. 仍然发送 WS 通知（前端显示用）
  this.wsManager.broadcast({ type: 'notification', ... })
  
  // 2. 新增：触发被@的 Bot 通过 OpenClaw 处理消息
  ;(async () => {
    try {
      const environment = this.detectBotEnvironment(mentionedId)
      if (environment.type === 'local' && this.openclawClient) {
        // 获取群聊上下文（最近 10 条消息）
        const recentMessages = await getGroupMessages(parseInt(groupId), 10)
        let contextMessage = '【群聊上下文 - 最近10条消息】\n'
        ;(recentMessages || []).forEach(msg => {
          if (msg && msg.sender_name && msg.content) {
            contextMessage += `${msg.sender_name}: ${msg.content}\n`
          }
        })
        contextMessage += '\n【请回复上述对话，特别关注提及你的消息。如果有任务卡分配给你，请立即执行。】'
        
        // 获取群聊 session_id（保持对话连续性）
        const groupSessionId = this.openclawSessionManager
          ? this.openclawSessionManager.getGroupSession(groupId)
          : `group_${groupId}`
        
        // 触发 OpenClaw
        const result = await this.openclawClient.sendMessage(
          mentionedId, contextMessage, null, 'group', groupSessionId
        )
        
        // 保存 Bot 回复到群聊并广播
        if (result.success && result.data?.response) {
          const botReply = await saveGroupMessage(
            parseInt(groupId), mentionedId,
            result.data.bot_name || mentionedId,
            result.data.response, []
          )
          this.wsManager.broadcast({
            type: 'group_message',
            groupId: parseInt(groupId),
            message: botReply
          })
        }
      }
    } catch (error) {
      console.error(`[botSendToGroup] 触发 @Bot ${mentionedId} 失败:`, error)
    }
  })()
}
```

**效果**：修复后的 TokVideo 工作流变为：

```
用户 @DISP(管理章鱼) → OpenClaw 触发 DISP ✅
DISP @ASST(助理章鱼) → OpenClaw 触发 ASST ✅（修复后）
ASST @INTEL(情报章鱼) → OpenClaw 触发 INTEL ✅（修复后）
INTEL @DISP(管理章鱼) → OpenClaw 触发 DISP ✅（修复后）
...每一步都能被正确触发
```

### 7.2 第二层方案：TaskExecutionLoop（任务执行循环引擎）

**用途**：作为第零层（system_prompt 级）的兜底。当 Agent 因为 token 限制、工具超时等原因只回了"收到"但没完成执行时，TaskExecutionLoop 自动追发执行指令。

**核心原理**：当 Bot 回复包含"任务承诺"但没有"完成标志"时，系统自动发起后续的 OpenClaw 调用。

```
┌────────────────────────────────────────────────────────────┐
| TaskExecutionLoop 架构                                      |
|                                                            |
| (1) Bot 收到任务 → OpenClaw 调用 → Bot 回复                 |
|                                        |                    |
| (2) 回复内容分析引擎                                        |
|     情况A: 包含"已完成/请审核"                               |
|     → 任务正常关闭，不需要额外触发                           |
|                                                            |
|     情况B: 包含"收到/我来做" 但没有"已完成"                   |
|     → 检测到"承诺但未执行"→ 启动执行循环                     |
|                                        |                    |
| (3) 系统延迟 3s 后自动发起第二次 OpenClaw 调用：             |
|     message = "你刚才接收了任务：{任务描述}。                |
|              请现在开始执行。执行完成后调用 API 汇报。"       |
|                                        |                    |
| (4) Bot 在第二次调用中真正执行工作                           |
|     → 执行 → 调 send-to-group API 汇报                     |
|     → 系统检测到"已完成"→ 关闭执行循环                      |
└────────────────────────────────────────────────────────────┘
```

**任务承诺 vs 完成检测关键词**：

```javascript
// 检测"接受任务但可能没执行"
const TASK_ACCEPTANCE_PATTERNS = [
  /收到.*[我来|开始|马上|立即]/,
  /好的.*[执行|处理|开发|实现]/,
  /了解.*[开始|着手]/,
  /接收任务/, /我来做/, /开始执行/, /马上处理/
]

// 检测"任务已经完成"
const TASK_COMPLETION_PATTERNS = [
  /已完成/, /完成了/, /做完了/, /开发完成/,
  /已提交.*待审核/, /请.*审核/, /请验收/,
  /已存入.*路径/, /已输出到/
]
```

**智能判断逻辑**：

```javascript
async analyzeReplyAndDecide(botId, groupId, replyContent, originalTaskContent) {
  // 如果回复包含完成标志 → 任务已完成，无需额外触发
  if (this.isTaskCompletion(replyContent)) {
    console.log(`✅ ${botId} 在一次调用中完成了任务（第零层生效）`)
    return 'completed'
  }
  
  // 如果回复包含承诺但没有完成标志 → 需要追发执行指令
  if (this.isTaskAcceptance(replyContent)) {
    console.log(`🔄 ${botId} 只说了"收到"但没完成执行，启动 TaskExecutionLoop`)
    // 延迟 3s 后发起第二次 OpenClaw 调用
    setTimeout(() => this.triggerExecution(botId, groupId, originalTaskContent), 3000)
    return 'loop_started'
  }
  
  // 其他情况（普通对话），不干预
  return 'no_action'
}
```

### 7.3 第三层方案：Bot 自驱动能力（Agent Loop + task_box）

**长期架构设计**：利用 OpenClaw 的 Cron 和 Heartbeat 机制，让 Bot 具备自驱动能力，适用于长时间执行的任务。

```
┌──────────────────────────────────────────────────────────┐
| Bot Agent Loop 架构                                       |
|                                                          |
| ┌──────────────────┐    ┌──────────────────┐             |
| | OpenClaw Cron    |    | Heartbeat Check  |             |
| | (每5分钟触发一次) |    | (每30秒检查一次) |             |
| └────────┬─────────┘    └────────┬─────────┘             |
|          v                       v                        |
| ┌──────────────────────────────────────────────┐          |
| | Bot Agent 被唤醒                              |          |
| |                                              |          |
| | 1. 检查 task_box/pending/ 有没有我的任务       |          |
| | 2. 有 → 移到 in_progress/ → 执行 → completed/ |          |
| | 3. 完成后调 send-to-group @DISP 汇报          |          |
| | 4. 无任务 → 回到休眠                          |          |
| └──────────────────────────────────────────────┘          |
└──────────────────────────────────────────────────────────┘
```

**task_box 目录结构**（已有实现基础）：

```
~/octowork/departments/TokVideoGroup/task_box/
├── pending/            ← 待执行任务（ASST 写入）
│   └── task_20260404_step_c_imgp.json
├── in_progress/        ← 执行中（Bot 移入）
├── completed/          ← 已完成（Bot 移入）
└── accepted/           ← 已验收（DISP 移入）
```

**task_box 与群聊消息的关系**：

```
ASST 发任务卡到群聊 (@Bot)
  ↓ 同时
ASST 写入 task_box/pending/task_{id}.json
  ↓
如果第一层修复生效 → Bot 被 OpenClaw 唤醒 → 直接执行
如果唤醒失败 → task 留在 pending/
  ↓
Agent Loop 的 heartbeat 检查 → 发现 pending 任务 → Bot 被再次唤醒 → 执行
```

### 7.4 实施优先级

| 层级 | 方案 | 改动量 | 效果 | 建议 |
|------|------|-------|------|------|
| **第零层** | Agent system_prompt 优化 | 8 个 agent prompt | Bot 在一次调用中完整执行 | **✅ 已实施 (2026-04-05)** |
| **第一层** | botSendToGroup 触发 OpenClaw | groupController.js +158行 | Bot @Bot 能被唤醒 | **✅ 已实施 (2026-04-05)** |
| **第二层** | TaskExecutionLoop | ~200 行后端代码 | 兜底——Bot 只说收到时自动追发 | **短期实施** |
| **第三层** | Agent Loop (Cron/Heartbeat + task_box) | 配置 + ~100 行 | Bot 自驱动长任务 | **中期规划** |

### 7.5 修复后的 TokVideo 完整链路（预期）

```
用户: "@management-octopus 立项 KoriDerm 3个视频"
  → [sendGroupMessage] OpenClaw 触发 DISP ✅

DISP: "@product-manager-octopus 发卡 @intelligence-benchmark-octopus 竞品采集"
  → [botSendToGroup + 第一层修复] OpenClaw 触发 ASST ✅
  → ASST 一次调用内完成：生成任务卡 + send-to-group @INTEL ✅

ASST 的 send-to-group @INTEL:
  → [botSendToGroup + 第一层修复] OpenClaw 触发 INTEL ✅
  → INTEL 一次调用内完成：确认 + 采集10个视频 + send-to-group 汇报 ✅

INTEL 的汇报 @DISP:
  → [botSendToGroup + 第一层修复] OpenClaw 触发 DISP ✅
  → DISP 一次调用内完成：审核 + send-to-group @ASST "入口质检通过" ✅

... 每一步都能正常触发和执行 ...

总结：第零层(prompt) + 第一层(代码修复) 组合 = TokVideo 完整流程可运转
     第二层(TaskExecutionLoop) = 兜底保障（万一某个 Bot 没在一次调用内完成）
     第三层(Agent Loop) = 处理长时间任务（如视频生成需要 5 分钟等待回调）
```

---

## 八、消息可靠性保障

### 8.1 单聊消息六层保障

| 层 | 机制 | 延迟 | 代码位置 |
|----|------|------|---------|
| L1 | WS 实时推送 | 0s | `botController.js L371` |
| L1.5 | 3s 快速重试 | 3s | `botController.js L383-399` |
| L2 | 对账服务补推 | 30s | `message-reconciliation-enhanced.js` |
| L3 | 前端轮询 | 30s | `useSingleChat.ts` |
| L3.5 | 全Bot未读轮询 | 60s | `useSingleChat.ts L685-702` |
| L4 | 离线队列 | 上线时 | `offlineQueue.js` |

### 8.2 群聊消息保障

| 层 | 机制 | 说明 |
|----|------|------|
| L1 | WS broadcast | 广播给所有已连接的前端客户端 |
| L2 | 前端刷新拉取 | 用户刷新页面会重新 GET /api/groups/:id/messages |
| ⚠️ | 无离线队列 | WS 断连时群聊消息可能丢失，需手动刷新 |

### 8.3 Bot → Bot 触发链保障（修复后预期）

| 层 | 机制 | 说明 |
|----|------|------|
| L1 | botSendToGroup + OpenClaw 触发 | 被 @Bot 被 OpenClaw 唤醒（第一层修复） |
| L2 | TaskExecutionLoop 兜底 | Bot 只说"收到"时自动追发执行指令（第二层方案） |
| L3 | Agent Loop heartbeat | Bot 周期检查 task_box 待执行任务（第三层方案） |
| L4 | ASST Guardian 超时检测 | pipeline_state 超时 → ASST 重发任务卡或上报 DISP |

---

## 九、完整代码示例（按场景）

### 场景 1：DISP 指示 ASST 发任务卡

```javascript
// management-octopus (DISP) 在 TokVideo 群中下达指令
await fetch('http://localhost:1314/api/bot/send-to-group', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'management-octopus',
    groupId: '1',
    content: '@product-manager-octopus 发卡 @image-generation-octopus Step-C',
    mentions: ['product-manager-octopus']
  })
})
```

### 场景 2：ASST 生成并发送任务卡

```javascript
// product-manager-octopus (ASST) 生成任务卡并 @IMGP
await fetch('http://localhost:1314/api/bot/send-to-group', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'product-manager-octopus',
    groupId: '1',
    content: `@image-generation-octopus
📋 任务卡
━━━━━━━━━━━━━━━━━━━━━━━━
项目编号：20260404_TokProject_01
步骤编号：Step-C 精准抽帧截图
指派对象：@image-generation-octopus（图片制作章鱼）
任务描述：读改写MD文档，按时间点截取原视频关键帧
素材路径：06_改写MD文档_已通过/
输出路径：07_抽帧截图_待审核/
SLA：2分钟
完成后：@copy-audit-octopus 审核 (QC-C)，@management-octopus 知悉
━━━━━━━━━━━━━━━━━━━━━━━━`,
    mentions: ['image-generation-octopus']
  })
})
```

### 场景 3：执行角色确认 + 执行 + 汇报（在一次 OpenClaw 调用中）

```javascript
// image-generation-octopus (IMGP) 被 OpenClaw 唤醒后
// 在一次调用中完成全部工作：

// 步骤1: 确认接收
await fetch('http://localhost:1314/api/bot/send-to-group', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'image-generation-octopus',
    groupId: '1',
    content: '@management-octopus 收到！Step-C 抽帧任务已接收，开始执行',
    mentions: ['management-octopus']
  })
})

// 步骤2: 实际执行任务（调用 ffmpeg 截帧）
// ... IMGP 执行 tools/task_tools/frame_extractor.py ...
// ... 截取 8 张关键帧 → 写入 07_抽帧截图_待审核/ ...

// 步骤3: 汇报完成
await fetch('http://localhost:1314/api/bot/send-to-group', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'image-generation-octopus',
    groupId: '1',
    content: `@copy-audit-octopus @management-octopus
Step-C 抽帧完成！
✅ 已截取 8 张关键帧
✅ 时间点误差均 < 1s
✅ 已输出到 07_抽帧截图_待审核/
请 QC 审核 (QC-C)`,
    mentions: ['copy-audit-octopus', 'management-octopus']
  })
})
```

### 场景 4：QC 审核并汇报

```javascript
// copy-audit-octopus (QC) 审核 Step-C 后汇报
await fetch('http://localhost:1314/api/bot/send-to-group', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'copy-audit-octopus',
    groupId: '1',
    content: `@management-octopus
✅ QC-C 审核通过
C-1 截图数量完整 (8/8) ✅
C-2 时间点准确 (误差≤1s) ✅
C-3 画面匹配度 ✅
C-4 清晰度达标 ✅
建议：通过，可进入 Step-D`,
    mentions: ['management-octopus']
  })
})
```

### 场景 5：DISP 决策通过 + ASST 执行迁移发卡

```javascript
// management-octopus (DISP) 确认通过
await fetch('http://localhost:1314/api/bot/send-to-group', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'management-octopus',
    groupId: '1',
    content: '@product-manager-octopus Step-C 通过',
    mentions: ['product-manager-octopus']
  })
})

// product-manager-octopus (ASST) 执行：迁移 + 发下一步卡
// ASST 在一次 OpenClaw 调用中完成：
// 1. guardian --update qc_c passed
// 2. file_migrator 07_待审核 → 08_已通过
// 3. guardian --action advance → step_d ready
// 4. task_card_generator → Step-D 任务卡
// 5. send-to-group @IMGP 发 Step-D 卡
// 6. guardian --update step_d in_progress
// 7. send-to-group @DISP 汇报
```

### 场景 6：异常上报（DISP → 用户）

```javascript
// management-octopus (DISP) 直接找用户（单聊 or 群聊 @admin）
await fetch('http://localhost:1314/api/bot/send-to-user', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    botId: 'management-octopus',
    userId: 'admin',
    content: `🚨 项目卡壳报告
项目：20260404_TokProject_01
卡壳步骤：Step-D 人物替换
卡壳角色：@image-generation-octopus（图片制作章鱼）
已耗时：5分钟（SLA: 3分钟）
原因分析：图像 API 返回超时
建议方案：
  A) 再给 3min 宽限重试
  B) 切换备用图像 API
请您决策`,
    type: 'proactive',
    metadata: { priority: 'high', projectId: '20260404_TokProject_01' }
  })
})
```

---

## 十、故障排查

### 10.1 快速诊断命令

```bash
# 1. 测试单聊 API
curl -s -X POST http://localhost:1314/api/bot/send-to-user \
  -H "Content-Type: application/json" \
  -d '{"botId":"management-octopus","userId":"admin","content":"测试消息"}' \
  | python3 -m json.tool

# 2. 测试群聊 API
curl -s -X POST http://localhost:1314/api/bot/send-to-group \
  -H "Content-Type: application/json" \
  -d '{"botId":"management-octopus","groupId":"1","content":"测试群聊消息"}' \
  | python3 -m json.tool

# 3. 查看最近的 Bot 单聊消息
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, session_id, sender, substr(content,1,60), is_pushed,
          datetime(timestamp/1000,'unixepoch','localtime')
   FROM messages WHERE sender='bot'
   ORDER BY timestamp DESC LIMIT 10;"

# 4. 查看群聊消息
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, sender, sender_name, substr(content,1,60), mentions,
          datetime(timestamp/1000,'unixepoch','localtime')
   FROM group_messages
   ORDER BY timestamp DESC LIMIT 10;"

# 5. 查看特定群组的 @mention 消息
sqlite3 ~/octowork/data/chat.db \
  "SELECT id, sender, sender_name, substr(content,1,80), mentions
   FROM group_messages
   WHERE group_id = 1 AND mentions != '[]'
   ORDER BY timestamp DESC LIMIT 20;"

# 6. 检查对账服务状态
curl -s http://localhost:1314/api/reconciliation/stats | python3 -m json.tool

# 7. 查看在线用户
curl -s http://localhost:1314/api/ws/stats | python3 -m json.tool

# 8. 查看所有群组
curl -s http://localhost:1314/api/groups | python3 -m json.tool

# 9. 检查 OpenClaw 进程状态
ps aux | grep openclaw

# 10. 查看 TokVideo task_box 状态
ls -la ~/octowork/departments/TokVideoGroup/task_box/pending/ 2>/dev/null
ls -la ~/octowork/departments/TokVideoGroup/task_box/in_progress/ 2>/dev/null
```

### 10.2 常见问题对照表

| 症状 | 排查方向 | 解决方案 |
|------|---------|---------|
| send-to-user 返回 400 | botId/userId/content 为空 | 检查请求参数 |
| send-to-user 返回 500 | 数据库写入失败 | 检查 `~/octowork/data/chat.db` 是否存在 |
| delivery=realtime 但前端没收到 | WS 连接问题 | 检查前端 WS 连接；等 30s 对账服务补推 |
| delivery=queued 但上线后没收到 | 离线队列问题 | 检查 `~/octowork/data/offline_queue/` |
| send-to-group 返回 500 | groupId 不存在 | 先 GET /api/groups 确认群组列表 |
| @Bot 后 Bot 没回复（用户 @Bot） | OpenClaw 未调用 | 检查 `detectBotEnvironment` 和 OpenClaw 进程状态 |
| **Bot @Bot 没反应** | **天坑 Bug：botSendToGroup 不触发 OpenClaw** | **实施第一层修复（见 7.1 节）** |
| Bot 回复"收到"但不执行 | **天坑：回复 ≠ 执行** | **实施第零层 prompt + 第二层 TaskExecutionLoop** |
| 任务卡发了但执行角色无动静 | 链路断裂（陷阱1+2 叠加） | 检查 OpenClaw 日志；确认第一层修复已上线 |
| 消息 is_pushed=0 一直不变 | 对账服务未启动 | 检查 config.json 中 reconciliation.enabled |
| 前端群聊消息不显示 | message 格式问题 | 确认 WS 广播的 message 是对象（含 id/content/timestamp） |
| 任务卡片不显示 | TaskDetector 未识别 | 消息需包含"任务卡"关键词和 @mention |
| pipeline_state 不更新 | ASST 执行失败 | 检查 guardian 脚本日志 |
| 步骤超时但没有预警 | ASST Guardian 未检测 | 确认 ASST 的 heartbeat 配置 |

### 10.3 日志关键词

```bash
# 单聊推送相关
grep "Bot主动消息\|sendToUser\|is_pushed" /path/to/logs

# 群聊相关
grep "Bot群聊\|botSendToGroup\|group_message" /path/to/logs

# OpenClaw 调用相关
grep "OpenClaw CLI\|sendMessage\|进程退出" /path/to/logs

# 任务触发相关
grep "触发.*Bot\|triggerExecution\|TaskExecutionLoop" /path/to/logs

# 对账服务相关
grep "对账\|reconciliation\|unpushed" /path/to/logs

# TokVideo 流水线相关
grep "pipeline_state\|guardian\|task_card" /path/to/logs
```

---

## 十一、关键源文件速查

### 11.1 后端文件

| 文件 | 职责 | 核心方法/行号 |
|------|------|-------------|
| `backend/src/controllers/botController.js` | 单聊控制器 | `sendMessage` L181, `sendToUser` L1427 |
| `backend/src/controllers/groupController.js` | 群聊控制器 | `sendGroupMessage` L202, `botSendToGroup` L564 |
| `backend/src/routes/botRoutes.js` | 单聊路由 | `POST /bot/send-to-user` L60 |
| `backend/src/routes/groupRoutes.js` | 群聊路由 | `POST /bot/send-to-group` |
| `backend/db/database.js` | 数据库层 | `saveMessage` L209, `saveGroupMessage` L492 |
| `backend/api/openclaw.js` | OpenClaw 客户端 | `sendMessage()` L20 |
| `backend/websocket/user-manager.js` | WS 管理器 | `sendToUser()`, `broadcast()` |
| `backend/services/message-reconciliation-enhanced.js` | 对账服务 | `scanUnpushedBotMessages()` |
| `backend/src/services/offlineQueue.js` | 离线队列 | `enqueue()`, `dequeue()` |
| `backend/src/services/openclawSessionManager.js` | 会话管理 | `getUserBotSession()`, `getGroupSession()` |
| `backend/tasks/task_detector.js` | 任务意图检测 | `detectTaskIntent()` |
| `backend/tasks/task_manager.js` | 任务管理 | `createTask()`, `updateTaskStatus()` |
| `backend/tasks/task_box_watcher.js` | 任务目录监控 | `watchDepartment()` |
| `backend/event_bus.js` | 事件总线 | `emit()`, `on()` |
| `backend/config.json` | 全局配置 | OpenClaw URL/port、对账参数 |
| `backend/server.js` | 服务入口 | WS 连接管理、依赖注入 |

### 11.2 前端文件

| 文件 | 职责 |
|------|------|
| `frontend/.../composables/useSingleChat.ts` | 单聊消息管理、轮询 |
| `frontend/.../composables/useGroupChat.ts` | 群聊消息管理、WS 监听 |
| `frontend/.../composables/useWebSocket.ts` | WS 连接、handleBotNewMessage |
| `frontend/.../composables/useDepartmentConfig.ts` | 部门/员工配置加载 |

### 11.3 配置与数据文件

| 路径 | 说明 |
|------|------|
| `~/octowork/config/ai-directory.json` | 公司通讯录（所有 AI 员工信息） |
| `~/octowork/data/chat.db` | SQLite 数据库（消息、会话、群组） |
| `~/octowork/data/offline_queue/` | 离线消息队列 |
| `~/octowork/departments/{deptId}/task_box/` | 任务看板文件系统 |
| `~/octowork/departments/{deptId}/chat_history/` | 聊天记录归档 |
| `~/octowork/departments/{deptId}/agents/{botId}/` | Bot 工作空间 |
| `~/octowork/departments/{deptId}/agents/team_index.json` | 部门角色配置 |
| `~/.openclaw/` | OpenClaw 引擎配置 |

### 11.4 TokVideo 专属文件

| 路径 | 说明 |
|------|------|
| `octowork/departments/TokVideoGroup/` | TokVideo 部门根目录 |
| `.../agents/team_index.json` | 8角色配置（v4.0） |
| `.../docs/SOP标准流程/TokVideo_完整生产SOP_v3.0.md` | 完整生产 SOP |
| `.../agents/01_dispatcher-octopus/ego/system_prompt.md` | DISP system prompt |
| `.../agents/07_assistant-octopus/ego/system_prompt.md` | ASST system prompt |
| `.../agents/04_image-production-octopus/` | IMGP 工作空间 |
| `.../agents/08_video-production-octopus/` | VIDP 工作空间 |
| `.../project-workspace/Project/` | 项目文件夹根目录 |

---

## 附录

### 附录 A：名词表

| 术语 | 说明 |
|------|------|
| **bot_id** | AI 员工的唯一标识符，如 `management-octopus` |
| **OpenClaw** | AI 引擎，负责运行 Agent 的核心推理 |
| **session_id** | 会话标识。单聊: `user_{userId}_bot_{botId}`，群聊: `group_{groupId}` |
| **WS (WebSocket)** | 实时通信协议，消息推送通道 |
| **is_pushed** | 消息推送状态标记（0=未推送，1=已推送） |
| **broadcast** | WS 广播，向所有已连接客户端发送消息 |
| **sendToUser** | WS 定向推送，只向指定用户发送消息 |
| **offlineQueue** | 离线队列，用户离线时暂存消息 |
| **对账服务** | 30s 周期扫描，补推 is_pushed=0 的消息 |
| **TaskDetector** | 从消息内容中识别任务意图（创建/完成/问题/进度） |
| **TaskBoxWatcher** | 监控 task_box 目录，文件变化触发看板更新 |
| **TaskExecutionLoop** | 任务执行循环引擎——检测承诺后自动追发执行指令（第二层方案） |
| **Agent Loop** | Bot 自驱动循环——被 cron/heartbeat 周期触发检查待办任务（第三层方案） |
| **任务卡** | 标准化任务描述格式，包含项目编号/步骤/指派/路径/SLA |
| **pipeline_state.json** | 流水线唯一真相，记录每个步骤的状态 |
| **Guardian** | 流水线守护脚本，管理状态推进/回退/超时检测 |
| **DISP** | 调度章鱼（老板），只做决策 |
| **ASST** | 助理章鱼（秘书），负责所有执行操作 |
| **SLA** | 服务等级约定，每个步骤的时间限制 |

### 附录 B：OctoVideo 部门 Bot ID 完整映射表

| bot_id | 中文名 | SOP 角色代号 | 团队 |
|--------|--------|-------------|------|
| `management-octopus` | TK管理章鱼 | DISP | octovideo-production |
| `product-manager-octopus` | TK视频制作经理章鱼 | ASST | octovideo-production |
| `intelligence-benchmark-octopus` | 情报对标章鱼 | INTEL | octovideo-production |
| `content-strategy-octopus` | 文案策划章鱼 | STRAT | octovideo-production |
| `copy-audit-octopus` | 文案审核章鱼 | QC | octovideo-production |
| `image-generation-octopus` | 图片生成章鱼 | IMGP | octovideo-production |
| `video-generation-octopus` | 视频生成章鱼 | VIDP | octovideo-production |
| `operation-release-octopus` | 运营发布章鱼 | OPS | octovideo-production |
| `image-audit-octopus` | 图片审核章鱼 | (备用) | octovideo-production |
| `video-audit-octopus` | 视频审核章鱼 | (备用) | octovideo-production |
| `video-editing-octopus` | 视频剪辑章鱼 | (备用) | octovideo-production |
| `tk-video-management-octopus` | TK视频管理章鱼 | (备用) | octovideo-production |

### 附录 C：API 速查卡

```
=== 单聊 ===
POST /api/bot/send-to-user
  { botId, userId, content, type?, metadata? }
  返回: { success, delivery: "realtime"|"queued", messageId }

=== 群聊 ===
POST /api/bot/send-to-group
  { botId, groupId, content, mentions? }
  返回: { success, messageId, mentionsCount }

=== 查询 ===
GET /api/groups                        → 所有群组
GET /api/groups/:groupId/messages      → 群聊消息列表
GET /api/department-config             → 公司通讯录
GET /api/reconciliation/stats          → 对账服务状态
GET /api/ws/stats                      → WebSocket 连接状态
```

### 附录 D：任务卡模板（直接复制使用）

```
📋 任务卡
━━━━━━━━━━━━━━━━━━━━━━━━
项目编号：{YYYYMMDD_TokProject_NN}
步骤编号：{Step-X / 竞品采集 / 发布}
指派对象：@{目标bot_id}（{角色名}）
任务描述：{具体任务描述}
素材路径：{完整路径——输入文件在哪里}
输出路径：{完整路径——结果存到哪里}
SLA：{本步骤时限，如 3分钟}
完成后：@{QC的bot_id} 审核，@{DISP的bot_id} 知悉
━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0 | 2026-04-04 | 首版：身份查找、单聊/群聊 API、天坑分析（三层方案） |
| v2.0 | 2026-04-04 | 大幅升级：新增 TokVideo 实战案例 + 任务卡驱动 + 天坑分析四层方案 + Bot ID 映射表 + 6 个完整代码场景 + API 速查卡 |
| **v2.1** | **2026-04-05** | **群聊根治修复状态更新**：陷阱1"Bot @Bot 不触发"已修复（_triggerMentionedBots + 防循环/自环/频率限制）；第零层+第一层已实施；8 个 agent system_prompt 添加「群聊通信协议」；更新 3.5 节底层流程图、影响范围矩阵、实施优先级表 |
