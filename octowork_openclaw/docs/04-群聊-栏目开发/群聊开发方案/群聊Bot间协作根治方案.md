# 群聊 Bot 间协作根治方案

> **文档类型**：技术方案（讨论稿）
> **日期**：2026-04-04
> **问题等级**：P0 架构级
> **影响范围**：所有 Bot 间群聊协作——TokVideo 8 人流水线、OctoTech 研发协作等
> **一句话总结**：Bot @Bot 在群聊里是"聋子对话"——消息送达了但对方永远不会醒来工作

---

## 一、问题全貌

### 1.1 两条路径的对比

群聊中有两种发消息的方式，它们的代码路径完全不同：

| 维度 | 用户发消息 @Bot | Bot 发消息 @Bot |
|------|----------------|----------------|
| **触发入口** | `POST /api/groups/:groupId/messages` | `POST /api/bot/send-to-group` |
| **处理函数** | `sendGroupMessage()` L202-389 | `botSendToGroup()` L564-682 |
| **保存消息** | saveGroupMessage | saveGroupMessage |
| **WS 广播** | broadcast group_message | broadcast group_message |
| **@Bot 处理** | **遍历 mentions → `openclawClient.sendMessage(botId, context)`** | **遍历 mentions → 只发 `wsManager.broadcast` 通知** |
| **OpenClaw 调用** | **有** | **没有** |
| **被@Bot 是否被唤醒** | **是** | **否** |
| **被@Bot 会回复吗** | **会（回复内容保存并广播）** | **不会（永远沉默）** |

### 1.2 代码证据

**sendGroupMessage（用户路径）——L300-383，有 OpenClaw 调用**：

```javascript
// L314-332: 遍历每个被 @的 botId
for (const botId of mentions) {
  const environment = this.detectBotEnvironment(botId)
  if (environment.type === 'local' && this.openclawClient) {
    // ✅ 调用 OpenClaw CLI，Bot 被真正唤醒
    const result = await this.openclawClient.sendMessage(
      botId, contextMessage, null, 'group', groupSessionId, style
    )
    // ✅ 保存 Bot 回复到群聊
    if (result.success && result.data?.response) {
      const botReply = await saveGroupMessage(...)
      this.wsManager.broadcast({ type: 'group_message', ... })
    }
  }
}
```

**botSendToGroup（Bot 路径）——L620-665，没有 OpenClaw 调用**：

```javascript
// L657-664: 遍历每个被 @的 mentionedId
} else {
  // @ 另一个 Bot：广播通知即可（Bot 不在 SessionManager 中）
  this.wsManager.broadcast({
    type: 'notification',    // ← 只发了一个前端通知
    userId: mentionedId,
    notification
  })
  console.log(`   📢 @${mentionedId} (Bot) 通知已广播`)
  // ← 没有调用 openclawClient.sendMessage
  // ← 被@的 Bot 永远不会被唤醒
}
```

### 1.3 同时发现的附带 Bug

**Bug A: `isMentioningUser` 判断逻辑硬编码为 `mentionedId === 'user'`**

```javascript
// L636:
const isMentioningUser = (mentionedId === 'user')
```

但系统中人类用户的 ID 是 `admin`，不是 `user`。所以当 Bot 在群聊中 `@admin` 时，这个判断会失败，走进 else 分支（当 Bot 处理），用户不会收到正确的通知，也不会被存入离线队列。

**Bug B: `isUserOnline` 传入的也是 `'user'` 而非 `'admin'`（L640 连锁错误）**

```javascript
// L640: 即使 isMentioningUser 意外为 true，这里传的也是 mentionedId='user'
if (this.sessionManager && this.sessionManager.isUserOnline(mentionedId)) {
```

`sessionManager` 中跟踪的是 `'admin'` 的在线状态，用 `'user'` 去查永远返回 false，导致所有通知都走离线队列。

**正确的判断逻辑应该是**：

```javascript
// 方案A：直接匹配已知用户ID
const isMentioningUser = (mentionedId === 'admin')

// 方案B：查通讯录判断（面向未来多用户）
const isMentioningUser = !this.isKnownBot(mentionedId)

// 方案C：保守——检查 ai-directory 中是否存在
const isMentioningUser = !aiDirectory.employees[mentionedId]
```

### 1.4 TokVideo 的影响——全线瘫痪

TokVideo SOP v3.0 的完整生产流程需要 ~30+ 次 Bot→Bot @mention：

```
用户 @DISP                → [sendGroupMessage] OpenClaw ✅
DISP @ASST "立项"          → [botSendToGroup]  OpenClaw ❌ 链路断裂
ASST @INTEL "竞品采集"      → [botSendToGroup]  OpenClaw ❌
INTEL @DISP "采集完成"      → [botSendToGroup]  OpenClaw ❌
DISP @ASST "入口质检通过"   → [botSendToGroup]  OpenClaw ❌
ASST @STRAT "Step-A"       → [botSendToGroup]  OpenClaw ❌
STRAT @QC "Step-A完成"     → [botSendToGroup]  OpenClaw ❌
QC @DISP "QC-A通过"        → [botSendToGroup]  OpenClaw ❌
DISP @ASST "Step-A通过"    → [botSendToGroup]  OpenClaw ❌
ASST @STRAT "Step-B"       → [botSendToGroup]  OpenClaw ❌
... 还有 20+ 步 ...
```

**结果**：用户发出第一条消息后，DISP 能回复一次，但从 DISP @ASST 开始，整条生产线就停了。

---

## 二、根因分析

### 2.1 为什么会这样？

`botSendToGroup` 的原始设计意图是"Bot 在群聊里发消息"，当时的设计者把它理解为**广播功能**——消息存下来、推到前端显示就行。

这个理解在传统软件中是对的：人看到通知会自己去处理。但在 AI 系统中，**通知 ≠ 行动**。AI 必须被明确触发（调用 OpenClaw）才会工作。

### 2.2 为什么不能简单地"把 sendGroupMessage 的逻辑复制过来"？

看起来修复很简单——把 sendGroupMessage 中 L300-383 的 OpenClaw 调用逻辑复制到 botSendToGroup 里。但这里有几个关键差异需要处理：

| 差异点 | sendGroupMessage（用户路径） | botSendToGroup（Bot 路径） |
|--------|---------------------------|--------------------------|
| **调用者身份** | `sender` 是人类用户 | `botId` 是一个 Bot |
| **mentions 来源** | 从 `content` 正则提取 | 从请求 body 的 `mentions` 字段传入 |
| **响应时机** | 先 `res.json()` 再异步处理 Bot 回复 | 同步处理 mentions 后才返回 `res.json()` |
| **上下文构建** | 构建了 10 条历史消息的上下文 | 没有构建上下文 |
| **防止 @自己** | 不需要（用户不是 Bot） | **需要**（Bot A @Bot A 会死循环） |
| **防止乒乓** | 不需要 | **需要**（Bot A @Bot B → Bot B 回复 @Bot A → 无限循环） |

**核心区别**：Bot 路径需要**防循环**机制，这是用户路径不需要考虑的。

### 2.3 循环风险分析

如果我们天真地在 botSendToGroup 中加入 OpenClaw 调用，会产生：

```
ASST @IMGP "任务卡：Step-C"
  → OpenClaw 唤醒 IMGP
  → IMGP 回复："@product-manager-octopus 收到！"
  → IMGP 的回复是 Bot 发的消息 → 走 botSendToGroup
  → botSendToGroup 发现 @product-manager-octopus → 触发 OpenClaw 唤醒 ASST
  → ASST 回复："@image-generation-octopus 好的，等你完成"
  → ASST 的回复走 botSendToGroup → 触发 IMGP
  → IMGP 回复 → 触发 ASST → ...
  → 无限乒乓 💀
```

所以修复方案必须包含**防循环**逻辑。

---

## 三、根治方案

### 3.1 设计原则

1. **统一触发语义**：无论消息来自用户还是 Bot，@Bot 都应该触发 OpenClaw
2. **防循环**：Bot 的回复不应该再触发发送方（防乒乓）
3. **防自环**：Bot 不能 @自己
4. **深度限制**：设置触发链深度上限，防止多 Bot 间的间接循环
5. **不阻塞 API 响应**：OpenClaw 调用异步执行
6. **修复用户识别 Bug**：正确区分人类用户和 Bot

### 3.2 方案结构

```
┌────────────────────────────────────────────────────────────────┐
|  改动 1：botSendToGroup 增加 OpenClaw 触发（核心修复）           |
|  位置：groupController.js botSendToGroup() L657-664            |
|  改动量：~50 行                                                 |
|  效果：Bot @Bot → 被@的 Bot 被 OpenClaw 唤醒并回复              |
├────────────────────────────────────────────────────────────────┤
|  改动 2：防循环机制                                              |
|  位置：groupController.js 新增 _triggerMentionedBots() 方法     |
|  改动量：~80 行                                                 |
|  效果：防止 A↔B 乒乓 和 A→B→C→A 间接循环                       |
├────────────────────────────────────────────────────────────────┤
|  改动 3：修复用户识别 Bug                                        |
|  位置：groupController.js L636                                  |
|  改动量：~5 行                                                  |
|  效果：@admin 正确识别为人类用户                                 |
├────────────────────────────────────────────────────────────────┤
|  改动 4：sendGroupMessage 复用统一触发方法                       |
|  位置：groupController.js sendGroupMessage() L300-383           |
|  改动量：~20 行（重构，不改行为）                                |
|  效果：两条路径使用同一个 Bot 触发逻辑，减少代码重复              |
└────────────────────────────────────────────────────────────────┘
总改动量：~155 行（含注释）
```

### 3.3 详细设计

#### 改动 1+2+4：统一的 Bot 触发方法 `_triggerMentionedBots()`

**设计思路**：把"遍历 mentions → 调用 OpenClaw → 保存回复 → 广播"这个逻辑抽成一个私有方法，让 `sendGroupMessage` 和 `botSendToGroup` 共用。在这个方法中内置防循环逻辑。

```javascript
/**
 * 统一处理 @Bot 触发逻辑（sendGroupMessage 和 botSendToGroup 共用）
 * 
 * @param {Object} params
 * @param {number} params.groupId       - 群组ID
 * @param {string} params.senderId      - 发送者ID（用于防循环：不触发发送者自己）
 * @param {string[]} params.mentions    - 被@的 ID 列表
 * @param {string} params.messageContent - 原始消息内容（用于构建上下文）
 * @param {string} [params.style]       - 聊天风格
 * @param {number} [params.triggerDepth=0] - 当前触发深度（防止间接循环）
 */
async _triggerMentionedBots({ groupId, senderId, mentions, messageContent, style, triggerDepth = 0 }) {
  // ========== 防循环守卫 ==========
  
  const MAX_TRIGGER_DEPTH = 1
  // 深度含义：
  //   depth=0: 原始消息（用户或Bot）@了某个Bot → 触发 ✅
  //   depth=1: 被触发的 Bot 回复中又 @了别人 → 不再触发 ❌
  //
  // 为什么 MAX_TRIGGER_DEPTH = 1？
  // 因为我们期望 Bot 在一次 OpenClaw 调用中完成全部工作（第零层方案）。
  // Bot 的回复中如果又 @了别人，那是"汇报"消息（如 @DISP 任务完成），
  // 不需要立即自动触发。由 DISP 所在的下一轮人类/Bot 操作来驱动。
  //
  // 如果未来需要更长的自动链路，可以调大，但风险是失控的乒乓循环。
  
  if (triggerDepth >= MAX_TRIGGER_DEPTH) {
    console.log(`⛔ [触发深度] depth=${triggerDepth} >= MAX=${MAX_TRIGGER_DEPTH}，停止自动触发`)
    return
  }
  
  // ========== 过滤 mentions ==========
  
  // 去掉发送者自己（防自环）
  const botsToTrigger = mentions.filter(id => {
    if (id === senderId) {
      console.log(`   ⛔ 跳过自环: ${id} 是发送者自己`)
      return false
    }
    // 判断是否为人类用户（不需要 OpenClaw 触发）
    if (this._isHumanUser(id)) {
      console.log(`   👤 ${id} 是人类用户，走通知逻辑，不触发 OpenClaw`)
      return false
    }
    return true
  })
  
  if (botsToTrigger.length === 0) {
    return
  }
  
  console.log(`🚀 [Bot触发] 准备触发 ${botsToTrigger.length} 个 Bot: [${botsToTrigger.join(', ')}] (depth=${triggerDepth})`)
  
  // ========== 构建上下文 ==========
  
  const recentMessages = await getGroupMessages(parseInt(groupId), 10)
  let contextMessage = '【群聊上下文 - 最近10条消息】\n'
  ;(recentMessages || []).forEach(msg => {
    if (msg && msg.sender_name && msg.content) {
      contextMessage += `${msg.sender_name}: ${msg.content}\n`
    }
  })
  contextMessage += '\n【请回复上述对话，特别关注提及你的消息。如果有任务卡分配给你，请立即执行任务并在完成后汇报。】'
  
  const groupSessionId = this.openclawSessionManager
    ? this.openclawSessionManager.getGroupSession(groupId)
    : `group_${groupId}`
  
  // ========== 逐个触发 ==========
  
  for (const botId of botsToTrigger) {
    try {
      const environment = this.detectBotEnvironment(botId)
      
      if (environment.type === 'local' && this.openclawClient) {
        console.log(`🚀 [Bot触发] 正在调用 ${botId}，上下文(${(recentMessages || []).length}条消息)，depth=${triggerDepth}`)
        
        const result = await this.openclawClient.sendMessage(
          botId, contextMessage, null, 'group', groupSessionId, style
        )
        
        if (result.success && result.data?.response) {
          console.log(`✅ [Bot触发] ${botId} 回复成功`)
          
          // 保存 Bot 回复到群聊
          const botReply = await saveGroupMessage(
            parseInt(groupId),
            botId,
            result.data.bot_name || botId,
            result.data.response,
            []  // Bot 回复的 mentions 解析出来但不在这里处理触发
          )
          
          // WS 广播 Bot 回复
          this.wsManager.broadcast({
            type: 'group_message',
            groupId: parseInt(groupId),
            sessionId: groupSessionId,
            message: botReply
          })
          
          // ========== 处理 Bot 回复中的 @mentions ==========
          // Bot 的回复可能又 @了其他 Bot（如 IMGP 完成后 @QC @DISP）
          // 这里通过 triggerDepth + 1 递归调用，但受 MAX_TRIGGER_DEPTH 限制
          
          const replyMentions = []
          const mentionRegex = /@([a-zA-Z0-9\-_]+)/g
          let match
          while ((match = mentionRegex.exec(result.data.response)) !== null) {
            replyMentions.push(match[1])
          }
          
          if (replyMentions.length > 0) {
            console.log(`📢 [Bot触发] ${botId} 的回复中 @了: [${replyMentions.join(', ')}]`)
            // 递归触发，深度+1（会被 MAX_TRIGGER_DEPTH 挡住）
            await this._triggerMentionedBots({
              groupId,
              senderId: botId,          // 这次的发送者是当前 Bot
              mentions: replyMentions,
              messageContent: result.data.response,
              style,
              triggerDepth: triggerDepth + 1
            })
          }
        } else {
          console.warn(`⚠️ [Bot触发] ${botId} 调用失败或无回复`)
        }
      } else if (environment.type === 'filesystem') {
        console.log(`💻 [Bot触发] 远程Bot ${botId}，写入文件系统消息队列...`)
        // TODO: 实现远程 Bot 触发
      } else {
        console.warn(`⚠️ [Bot触发] ${botId} 环境未知或不可用`)
      }
    } catch (error) {
      console.error(`❌ [Bot触发] 调用 Bot ${botId} 失败:`, error)
    }
  }
}
```

#### 改动 3：人类用户识别方法 `_isHumanUser()`

```javascript
/**
 * 判断一个 ID 是否为人类用户（而非 Bot）
 * 
 * 当前实现：硬编码 admin（唯一人类用户）
 * 未来：查 ai-directory.json，如果不在 employees 中则为人类
 * 
 * @param {string} id - 被 @的 ID
 * @returns {boolean}
 */
_isHumanUser(id) {
  // 当前系统只有一个人类用户 admin
  // 'user' 是前端某些旧逻辑中使用的 sender ID，也算人类
  const HUMAN_USER_IDS = new Set(['admin', 'user'])
  return HUMAN_USER_IDS.has(id)
}
```

#### 改造后的 botSendToGroup

```javascript
botSendToGroup = async (req, res) => {
  try {
    const { botId, groupId, content, mentions = [] } = req.body
    
    // 1. 参数验证（不变）
    if (!botId) return res.status(400).json({ success: false, error: 'botId 不能为空' })
    if (!groupId) return res.status(400).json({ success: false, error: 'groupId 不能为空' })
    if (!content || content.trim() === '') return res.status(400).json({ success: false, error: '消息内容不能为空' })
    
    console.log(`📨 [Bot群聊] ${botId} → 群组 ${groupId}: ${content.substring(0, 50)}...`)
    
    // 2. 保存消息（不变）
    const message = await saveGroupMessage(
      parseInt(groupId), botId, botId, content.trim(), mentions
    )
    
    // 3. WS 广播（不变）
    this.wsManager.broadcast({
      type: 'group_message',
      groupId: parseInt(groupId),
      message: { id: message.id, sender: botId, senderName: botId,
                 content: content.trim(), timestamp: message.timestamp, mentions }
    })
    
    // 4. 处理 @mentions（改造重点）
    if (mentions.length > 0) {
      // 处理人类用户的通知（@admin）
      for (const mentionedId of mentions) {
        if (this._isHumanUser(mentionedId)) {
          // 人类用户走通知逻辑（检查在线/离线队列）
          const notification = {
            type: 'mention', groupId: parseInt(groupId), from: botId,
            content: content.trim(), timestamp: message.timestamp, messageId: message.id
          }
          const actualUserId = mentionedId === 'user' ? 'admin' : mentionedId
          if (this.sessionManager && this.sessionManager.isUserOnline(actualUserId)) {
            this.wsManager.broadcast({ type: 'notification', userId: actualUserId, notification })
          } else if (this.offlineQueue) {
            await this.offlineQueue.enqueue(actualUserId, { type: 'notification', userId: actualUserId, notification })
          }
        }
      }
      
      // 异步触发被 @的 Bot（不阻塞 API 响应）
      ;(async () => {
        await this._triggerMentionedBots({
          groupId: parseInt(groupId),
          senderId: botId,            // 防自环：不触发发送者
          mentions,
          messageContent: content.trim(),
          triggerDepth: 0
        })
      })()
    }
    
    // 5. 立即返回（不等 OpenClaw 执行完）
    return res.json({
      success: true, messageId: message.id,
      message: 'Bot群聊消息已发送', mentionsCount: mentions.length
    })
  } catch (error) {
    console.error('❌ [Bot群聊] 发送失败:', error)
    return res.status(500).json({ success: false, error: error.message || 'Bot群聊消息发送失败' })
  }
}
```

#### 改造后的 sendGroupMessage（复用 _triggerMentionedBots）

```javascript
// sendGroupMessage 的 L290-383 异步处理 Bot 回复部分替换为：
if (mentions.length > 0) {
  console.log(`📢 [Groups] 检测到@mention:`, mentions)
  ;(async () => {
    await this._triggerMentionedBots({
      groupId: parseInt(groupId),
      senderId: sender,            // 用户ID（如 admin）
      mentions,
      messageContent: content,
      style,
      triggerDepth: 0
    })
  })()
}
```

这样两条路径统一了触发逻辑，代码重复减少，防循环机制一处维护。

---

## 四、防循环机制详解

### 4.1 为什么 MAX_TRIGGER_DEPTH = 1？

这是整个方案中最关键的设计决策。让我用 TokVideo 的实际流程解释：

```
用户: "@management-octopus 立项 KoriDerm 3个视频"
  → sendGroupMessage → _triggerMentionedBots(depth=0)
  → OpenClaw 触发 management-octopus (DISP)

DISP 被唤醒后，在一次 OpenClaw 调用中完成：
  1. 理解任务
  2. 调用 send-to-group API "@product-manager-octopus 立项 KoriDerm 3个视频"
     → botSendToGroup → _triggerMentionedBots(depth=0)
     → OpenClaw 触发 product-manager-octopus (ASST)

ASST 被唤醒后，在一次 OpenClaw 调用中完成：
  1. 创建项目文件夹
  2. 初始化 pipeline_state
  3. 调用 send-to-group API "@management-octopus 立项完成 ✅"
     → botSendToGroup → _triggerMentionedBots(depth=0)
     → OpenClaw 触发 management-octopus (DISP)
  4. 调用 send-to-group API "@intelligence-benchmark-octopus 📋 任务卡 竞品采集"
     → botSendToGroup → _triggerMentionedBots(depth=0)
     → OpenClaw 触发 intelligence-benchmark-octopus (INTEL)
```

注意关键点：**每次 Bot 调用 `send-to-group` API 都是一次新的 HTTP 请求**，triggerDepth 每次都从 0 开始。所以链路不会断！

那 `MAX_TRIGGER_DEPTH = 1` 是防什么？防的是**同一次请求内的间接循环**：

```
Bot A 发消息 @Bot B       → botSendToGroup(depth=0) → 触发 Bot B ✅
Bot B 回复包含 @Bot C     → _triggerMentionedBots(depth=1) → 停止 ⛔
                            因为 depth=1 >= MAX=1
```

Bot B 的回复中 @Bot C **不会被自动触发**。但如果 Bot B 在它的 OpenClaw 执行过程中**主动调用了 `send-to-group` API @Bot C**，那是一次新的 HTTP 请求，depth 重新从 0 开始，Bot C 会被触发。

**这就是"第零层方案"配合"第一层修复"的精髓**：

- Agent 在一次 OpenClaw 调用中主动调用 `send-to-group` API → 新的 HTTP 请求 → 新的 depth=0 → 可以触发下一个 Bot
- Bot 回复文本中被动包含的 @mention → 同一请求内解析的 → depth+1 → 被挡住

这就**完美区分了"主动协作"和"被动提及"**：

| 行为 | 机制 | 是否触发 |
|------|------|---------|
| ASST 主动调 API @INTEL | 新 HTTP 请求, depth=0 | ✅ 触发 |
| IMGP 回复文本中 @DISP @QC | 同请求内解析, depth=1 | ❌ 不触发 |

### 4.2 为什么不用"最近 N 秒内 A→B→A 不重复触发"的方式？

时间窗口方案看似简单，但有两个严重问题：

1. **正常流程会被误杀**：TokVideo 中 DISP↔ASST 之间的通信非常频繁（DISP 每个决策都 @ASST），如果用时间窗口，正常的指令链会被当作"循环"挡掉。

2. **时间窗口选多大？** 太小防不住循环，太大会阻碍正常协作。没有一个"刚好"的值。

depth 方案没有这个问题——它区分的不是时间，而是**同一请求内 vs 新请求**。

### 4.3 极端场景验证

**场景 1：正常 TokVideo 流程**

```
用户 @DISP → [请求1, depth=0] → 触发 DISP ✅
DISP 回复中 @ASST → [请求1, depth=1] → 不触发 ⛔ (没关系，因为↓)
DISP 的 OpenClaw 调用中主动调 API @ASST → [请求2, depth=0] → 触发 ASST ✅
ASST 的 OpenClaw 调用中主动调 API @INTEL → [请求3, depth=0] → 触发 INTEL ✅
INTEL 的 OpenClaw 调用中主动调 API @DISP → [请求4, depth=0] → 触发 DISP ✅
... 整条流水线正常运转 ✅
```

**场景 2：Bot 忘了调 API，只在回复文本中 @了人**

```
ASST 被触发，回复："@intelligence-benchmark-octopus 📋 任务卡..."
  → [请求1 内部, depth=1] → 不触发 INTEL ⛔
  → INTEL 不会被唤醒
```

这种情况**需要第零层方案**来保证——ASST 的 system_prompt 必须写明：
"不要只在回复中 @人，必须主动调用 `send-to-group` API 发送任务卡"

**场景 3：Bot 恶意循环（A @B → B @A → A @B ...）**

```
Bot A 调 API @Bot B → [请求1, depth=0] → 触发 Bot B ✅
Bot B 回复中 @Bot A → [请求1, depth=1] → 不触发 ⛔ 循环被切断 ✅

但如果 Bot B 的 OpenClaw 调用中主动调 API @Bot A →
  → [请求2, depth=0] → 触发 Bot A ✅
  → Bot A 的 OpenClaw 调用中又调 API @Bot B →
  → [请求3, depth=0] → 触发 Bot B ✅
  → ...无限循环 💀
```

这种情况靠 depth 挡不住。需要**额外保护**——见 4.4。

### 4.4 补充保护：请求频率限制

对于 4.3 场景 3 那种"两个 Bot 通过 API 互相 @"的极端情况，加一个简单的**频率限制**：

```javascript
// 在 botSendToGroup 入口处加：
const TRIGGER_COOLDOWN_MS = 5000  // 同一对 Bot A→Bot B 的触发冷却 5 秒
const triggerCooldownCache = new Map()  // key: "botA→botB", value: lastTriggerTime

function shouldThrottle(senderId, targetId) {
  const key = `${senderId}→${targetId}`
  const lastTime = triggerCooldownCache.get(key)
  const now = Date.now()
  if (lastTime && now - lastTime < TRIGGER_COOLDOWN_MS) {
    console.log(`⛔ [频率限制] ${key} 冷却中 (${now - lastTime}ms < ${TRIGGER_COOLDOWN_MS}ms)`)
    return true
  }
  triggerCooldownCache.set(key, now)
  return false
}
```

在 `_triggerMentionedBots` 的 for 循环中，调用 OpenClaw 之前检查：

```javascript
if (shouldThrottle(senderId, botId)) {
  console.log(`⛔ [频率限制] 跳过触发 ${botId}`)
  continue
}
```

这样即使两个 Bot 互相 @ 调 API，也会因为 5 秒冷却而被减速。加上 OpenClaw 调用本身就需要几秒到几十秒，实际上很难形成高频循环。

---

## 五、修改清单（逐文件）

### 5.1 `backend/src/controllers/groupController.js`

| 行号区间 | 操作 | 描述 |
|---------|------|------|
| L1-38 | 不变 | imports + constructor |
| L38 后 | **新增** | `_isHumanUser()` 私有方法（~10 行） |
| L38 后 | **新增** | `_triggerMentionedBots()` 私有方法（~100 行） |
| L290-383 | **替换** | sendGroupMessage 的异步 Bot 回复部分 → 调用 `_triggerMentionedBots()` (~15 行) |
| L564-682 | **改造** | botSendToGroup 整体改造 → 人类通知 + 调用 `_triggerMentionedBots()` (~60 行) |

### 5.2 不需要改动的文件

| 文件 | 原因 |
|------|------|
| `groupRoutes.js` | 路由不变，API 接口签名不变 |
| `database.js` | 数据库操作不变 |
| `openclaw.js` | OpenClaw 客户端不变 |
| `openclawSessionManager.js` | 会话管理不变 |
| `event_bus.js` | 事件总线不变 |
| 前端所有文件 | 前端不需要感知后端的触发逻辑变化 |

### 5.3 注意事项：`detectBotEnvironment` 当前实现

当前 `backend/src/utils/helpers.js` 中的 `detectBotEnvironment()` **硬编码返回 `type: 'local'`**：

```javascript
function detectBotEnvironment(botId) {
  return { name: 'local', type: 'local', description: '本地开发环境' }
}
```

这意味着：
- 所有 Bot 都被视为本地 Bot，全部走 OpenClaw 调用路径
- `environment.type === 'filesystem'` 分支目前**永远不会进入**
- 这在当前阶段（所有 Bot 都在本地运行）是正确的行为
- 未来如果有远程 Bot，需要扩展此函数（查 `ai-directory.json` 判断）

---

## 六、实施计划

### Phase 1：立即修复（预计 30 分钟）

1. 在 `groupController.js` 中新增 `_isHumanUser()` 和 `_triggerMentionedBots()` 方法
2. 改造 `botSendToGroup` 调用新方法
3. 改造 `sendGroupMessage` 调用新方法
4. 本地测试：curl 模拟 Bot @Bot 场景，确认 OpenClaw 被调用

### Phase 2：Agent Prompt 优化（配合实施）

更新 TokVideo 各角色的 system_prompt，增加"任务执行铁律"：

```markdown
## 任务执行铁律

当你收到任务卡时，你必须在本次调用中完成以下全部步骤：
1. 通过 send-to-group API 回复"收到"
2. 使用工具完成任务
3. 将结果写入指定输出路径
4. 通过 send-to-group API 汇报完成

关键：汇报和通知必须通过调用 POST /api/bot/send-to-group API 发送，
     不是写在你的回复文本里。只有调 API 才能触发下一个角色。
```

### Phase 3：验证 TokVideo 完整链路（预计 1-2 小时）

用 curl 模拟 TokVideo 的一个完整项目流程：
1. 用户 @DISP 立项 → 验证 DISP 被唤醒
2. DISP 调 API @ASST → 验证 ASST 被唤醒
3. ASST 调 API @INTEL → 验证 INTEL 被唤醒
4. 逐步验证到发布环节

### Phase 4：TaskExecutionLoop 兜底（可选，中期）

如果 Phase 2 的 prompt 优化不够稳定（Bot 偶尔还是只说"收到"不执行），再实现 TaskExecutionLoop 作为兜底。

---

## 七、风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| Bot 循环调用导致资源耗尽 | 低 | 高 | MAX_TRIGGER_DEPTH=1 + 频率限制 + OpenClaw 自身超时 |
| OpenClaw 调用延迟导致群聊消息顺序混乱 | 中 | 低 | 异步处理不阻塞 API，前端按 timestamp 排序 |
| Bot 回复中被动 @mention 不被触发（第零层失效） | 中 | 中 | 确保 Agent prompt 强调"主动调 API"而非"写在回复里" |
| sendGroupMessage 重构后行为变化 | 低 | 高 | 复用 _triggerMentionedBots 时保留原有日志，充分测试 |
| 远程 Bot（filesystem 类型）不支持 | 确定 | 低 | 当前只有模拟回复，后续再处理 |

---

## 八、成功标准

修复完成后，以下场景必须全部通过：

| # | 测试场景 | 预期行为 |
|---|---------|---------|
| 1 | 用户在群聊 @Bot A | Bot A 被 OpenClaw 唤醒，回复出现在群聊中 |
| 2 | Bot A 调 send-to-group @Bot B | Bot B 被 OpenClaw 唤醒，回复出现在群聊中 |
| 3 | Bot A 调 send-to-group @Bot B，Bot B 回复中 @Bot A | Bot A **不被**自动触发（depth 限制） |
| 4 | Bot A 调 send-to-group @admin | admin 收到通知（在线WS推送/离线队列） |
| 5 | Bot A 调 send-to-group @自己 | 不触发自己（防自环） |
| 6 | Bot A 调 send-to-group @Bot B，Bot B 的 OpenClaw 中调 API @Bot C | Bot C 被触发（新 HTTP 请求，depth=0） |
| 7 | 快速连续 Bot A @Bot B 两次（间隔 <5s） | 第二次被频率限制跳过 |
| 8 | TokVideo: 用户 @DISP → DISP @ASST → ASST @INTEL → INTEL @DISP | 每一步都正常触发和回复 |

---

## 附录 A：与现有文档的关系

| 文档 | 关系 |
|------|------|
| `docs/10-核心工作流功能/octowork实现单聊群聊功能操作手册.md` | 本方案是手册中"第零层+第一层方案"的具体实施设计 |
| `docs/10-核心工作流功能/octowork实现AI自动群聊发布接收任务功能.md` | 本方案修复该文档中记录的"已知限制"第 1-4 条 |
| `docs/04-群聊-栏目开发/API速查.md` | API 接口不变，无需更新 |

## 附录 B：完整修改后的 groupController.js 伪代码结构

```
class GroupController {
  constructor(dependencies) { ... }
  
  // --- 新增私有方法 ---
  _isHumanUser(id) { ... }              // 5 行
  _triggerMentionedBots({ ... }) { ... } // 100 行
  
  // --- 群组管理 API（不变）---
  getAllGroups = async (req, res) => { ... }
  getGroupDetail = async (req, res) => { ... }
  createGroup = async (req, res) => { ... }
  deleteGroup = async (req, res) => { ... }
  getGroupMembers = async (req, res) => { ... }
  addMember = async (req, res) => { ... }
  removeMember = async (req, res) => { ... }
  
  // --- 群组消息 API ---
  getGroupMessages = async (req, res) => { ... }       // 不变
  sendGroupMessage = async (req, res) => { ... }        // 改造：Bot触发部分调用 _triggerMentionedBots
  deleteGroupMessages = async (req, res) => { ... }     // 不变
  getGroupMentions = async (req, res) => { ... }        // 不变
  
  // --- Bot 主动群聊消息 ---
  getDepartmentChatRecords = async (req, res) => { ... }       // 不变
  getDepartmentChatRecordContent = async (req, res) => { ... } // 不变
  botSendToGroup = async (req, res) => { ... }                 // 改造：增加 OpenClaw 触发
}
```
