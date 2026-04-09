# OctoWork 7种智能会话自检模式方案

> 最后更新：2026-04-06  
> 状态：方案设计完成，待实施  
> 优先级：P0（直接影响所有 Bot 对话质量）

---

## 目录

1. [问题背景](#1-问题背景)
2. [现状诊断（源码级）](#2-现状诊断源码级)
3. [架构缺陷根因分析](#3-架构缺陷根因分析)
4. [方案总览：三层自检架构](#4-方案总览三层自检架构)
5. [第一层：回复完成度规则判断器](#5-第一层回复完成度规则判断器)
6. [第二层：AI 自检追问服务](#6-第二层ai-自检追问服务)
7. [第三层：用户反馈触发](#7-第三层用户反馈触发)
8. [防循环刹车机制](#8-防循环刹车机制)
9. [7种模式 Prompt 重写规范](#9-7种模式-prompt-重写规范)
10. [单聊 vs 群聊：能否共用同一套方案](#10-单聊-vs-群聊能否共用同一套方案)
11. [前后端模式一致性修复](#11-前后端模式一致性修复)
12. [改动文件清单与实施顺序](#12-改动文件清单与实施顺序)
13. [风险评估](#13-风险评估)

---

## 1. 问题背景

### 1.1 核心症状

OctoWork Bot 聊天管理器支持 7 种聊天模式（说人话、交流探讨、深度思考、方案报告、任务工作、创意脑暴、快速决策），但存在两个致命问题：

- **"说人话"模式只说不干活** — 用户说"帮我写个脚本"，Bot 回"好的没问题"就停了，不写
- **Bot 回复后不知道自己是否完成了任务** — AI 是被动式工作的，回完一句话整条链路就断了，没有任何后续判断

### 1.2 影响范围

- 全部 58 个 AI 员工
- 全部 7 种聊天模式
- 所有用户的所有对话

### 1.3 用户反馈

> "AI 回答完之后根本不知道自己是否完成了任务，然后就停止了"  
> "人话模式经常只说不干活"

---

## 2. 现状诊断（源码级）

### 2.1 当前消息处理链路

```
用户发消息
  ↓
前端 MessageInput @send → useSingleChat.handleSend()
  ↓
POST /api/messages/:botId  { content, model, style, userId }
  ↓
botController.sendMessage()  ← backend/src/controllers/botController.js L181
  ├─ ① normalizeUserId → 用户ID规范化
  ├─ ② 重复消息检测（5秒窗口）
  ├─ ③ extractPlainText → 消息预处理
  ├─ ④ saveMessage → 用户消息入库
  ├─ ⑤ taskMonitor.createTask → 创建任务追踪
  ├─ ⑥ res.json → 立即返回HTTP响应（不阻塞前端）
  └─ ⑦ 异步处理 ↓

异步处理（IIFE）：
  ├─ getStyleProcessor(style) → 获取模式处理器
  ├─ processor(content, botId) → 注入 style prompt
  ├─ openclawClient.sendMessage() → 发给 OpenClaw CLI
  ├─ extractPlainText(response) → 提炼回复
  ├─ isBotProcessContent(response) → 过滤过程内容
  ├─ saveMessage → Bot 回复入库
  ├─ taskMonitor.updateTaskStatus('completed') → 标记完成    ← 🔴 到这就结束了
  └─ wsManager.sendToUser → WebSocket 推送给前端

                                                              ↑
                                                         没有任何后续动作
                                                         Bot 不知道自己回答得对不对
                                                         系统不知道任务是否真正完成
```

### 2.2 七种 styleProcessor 现状

| 模式 | 文件位置 | Prompt 质量 | 问题 |
|------|---------|------------|------|
| `simple` 说人话 | server.js L134 | ⚠️ 有缺陷 | "不要解释"导致不执行任务，只说话不干活 |
| `discussion` 交流探讨 | server.js L142 | ⚠️ 有缺陷 | 200字限制和"多角度分析"自相矛盾 |
| `thinking` 深度思考 | server.js L150 | ✅ 唯一完善 | 70+行 prompt 消耗 token 较多，可精简 |
| `report` 方案报告 | server.js L229 | ❌ 严重 | 和下面3个用了完全相同的"读空气"prompt |
| `task` 任务工作 | server.js L253 | ❌ 严重 | 同上，没有任何任务执行引导 |
| `brainstorm` 创意脑暴 | server.js L277 | ❌ 严重 | 同上，没有任何创意发散引导 |
| `decision` 快速决策 | server.js L301 | ❌ 严重 | 同上，没有任何决策框架引导 |

**核心问题：4个模式（report/task/brainstorm/decision）的 prompt 完全一模一样**，唯一区别是最后一行 `[当前模式：xxx模式]`。用户切换模式完全没有效果。

### 2.3 前后端模式不一致

| 位置 | 模式列表 | 问题 |
|------|---------|------|
| `frontend/src/renderer/utils/constants.ts` L95 | normal, simple, discussion, report, task, brainstorm, decision | 有 `normal`，没 `thinking` |
| `frontend/src/renderer/App.vue` L417 | simple, discussion, thinking, report, task, brainstorm, decision | 没 `normal`，有 `thinking` |
| `backend/server.js` L132 styleProcessors | simple, discussion, thinking, report, task, brainstorm, decision | 没 `normal` |
| `backend/server.js` L326 getStyleProcessor | 映射表无 `normal`，fallback 到 `simple` | `normal` 静默变成 `simple` |

**结果：** 前端 constants 里的"普通模式"发到后端会被静默降级为"说人话模式"，用户完全不知情。

### 2.4 taskMonitor 现状

```
backend/services/task-monitor.js

- 状态：pending → running → completed / failed
- 完成后 60 秒自动清理
- 失败后 120 秒自动清理
- 没有 "自检" / "追问" / "补充" 的概念
- 没有 followUp 计数器
- 标记 completed 就是终态，不可逆
```

---

## 3. 架构缺陷根因分析

### 3.1 一问一答的死架构

```
当前：
  用户问 ──→ Bot 答 ──→ 结束（Bot 下班了）

应该是：
  用户问 ──→ Bot 答 ──→ 系统判断"答得够不够" ──→ 不够就补 ──→ 够了才结束
```

**问题本质**：系统在 Bot 回复和用户看到之间，缺少一个"质检环节"。就像工厂流水线上没有质检站，产品直接出厂。

### 3.2 Prompt 和机制是两个独立问题

| 维度 | 问题 | 解法 |
|------|------|------|
| **Prompt 层** | 4个模式没有独立 prompt，说人话模式引导错误 | 重写7个 prompt |
| **机制层** | Bot 回复后没有完成度判断，没有补充机会 | 加自检回路 |

两个都要改。只改 prompt 治标不治本（AI 仍然可能遗漏）；只改机制不改 prompt（垃圾进垃圾出）。

---

## 4. 方案总览：三层自检架构

```
用户发消息
  ↓
style prompt 注入（重写后的 7 种 prompt）
  ↓
发给 OpenClaw → 拿到 Bot 回复
  ↓
┌─────────────────────────────────────────────────┐
│ 【第一层】completionChecker — 规则判断器         │
│  纯正则 + 字数 + 关键词匹配，零 AI 成本          │
│                                                  │
│  判定结果：                                       │
│  ├─ COMPLETE → 正常存库推送，流程结束              │
│  ├─ LIKELY_COMPLETE → 正常存库推送，流程结束       │
│  └─ INCOMPLETE → 进入第二层 ↓                     │
└─────────────────────────────────────────────────┘
  ↓ （仅 INCOMPLETE 才触发）
┌─────────────────────────────────────────────────┐
│ 【第二层】selfReviewService — AI 自检追问         │
│  把 {原始问题 + Bot回复} 再发一次，附带自检指令     │
│  最多触发 1 次，有冷却、去重、上限三重刹车         │
│                                                  │
│  结果处理：                                       │
│  ├─ Bot 补充了实质内容 → 追加为新消息推送          │
│  ├─ Bot 回复 [TASK_COMPLETE] → 说明原回复已够      │
│  └─ Bot 回复和原文高度重复 → 丢弃，不推送          │
└─────────────────────────────────────────────────┘
  ↓
正常存库推送，流程结束
  ↓
┌─────────────────────────────────────────────────┐
│ 【第三层】用户反馈触发（前端可选）                 │
│  消息气泡上的 👍 / 🔄 按钮                        │
│  🔄 "没做完" → 自动发追问给 Bot                   │
│  👍 "搞定了" → 标记 task 真正 completed           │
│  完全由用户主动触发，无循环风险                    │
└─────────────────────────────────────────────────┘
```

### 设计原则

1. **成本递增** — 第一层零成本，第二层一次 AI 调用，第三层用户触发
2. **逐层收窄** — 大部分回复在第一层就通过，只有"明显没做完"的才进入第二层
3. **硬性上限** — 任何情况下，一个任务最多触发 1 次自检，绝不无限循环
4. **向下兼容** — 自检机制是增量添加，不改变现有消息格式和推送协议

---

## 5. 第一层：回复完成度规则判断器

### 5.1 文件位置

```
新建：backend/services/completionChecker.js
```

### 5.2 核心接口

```javascript
/**
 * 回复完成度判断器
 * 纯规则引擎，不调用 AI，零成本
 */
class CompletionChecker {
  
  /**
   * @param {string} userMessage    - 用户原始消息
   * @param {string} botReply       - Bot 回复内容
   * @param {string} style          - 聊天模式 (simple/discussion/thinking/report/task/brainstorm/decision)
   * @returns {{ status: 'COMPLETE'|'LIKELY_COMPLETE'|'INCOMPLETE', reason: string }}
   */
  check(userMessage, botReply, style) { ... }
}
```

### 5.3 判断规则矩阵

#### 通用规则（所有模式适用）

```javascript
// 先判断用户意图类型
const intentType = this.classifyIntent(userMessage)

// 意图分类：
// - 'execute'  : 用户要求执行（写/做/改/建/创建/生成/帮我...）
// - 'ask'      : 用户提问（什么/为什么/怎么/如何/是不是...）
// - 'chat'     : 闲聊（你好/谢谢/哈哈/...）
```

```javascript
classifyIntent(message) {
  // 执行类关键词
  const executePatterns = [
    /帮我/, /请写/, /写一个/, /做一个/, /生成/, /创建/, /修改/, /改一下/,
    /实现/, /开发/, /部署/, /配置/, /搭建/, /设计一个/, /画一个/,
    /写个/, /做个/, /弄个/, /搞个/, /整个/,
    /write/, /create/, /build/, /make/, /generate/, /implement/, /fix/
  ]
  
  // 提问类关键词
  const askPatterns = [
    /^什么/, /为什么/, /怎么/, /如何/, /是不是/, /能不能/, /有没有/,
    /你觉得/, /你认为/, /分析/, /解释/, /区别/,
    /^what/i, /^why/i, /^how/i, /^is /i, /^can /i, /^should/i
  ]
  
  for (const p of executePatterns) {
    if (p.test(message)) return 'execute'
  }
  for (const p of askPatterns) {
    if (p.test(message)) return 'ask'
  }
  return 'chat'
}
```

#### 各模式专属规则

**`simple` 说人话模式：**

```javascript
checkSimple(intent, userMessage, botReply) {
  // 闲聊 / 提问 → 只要有实质回复就算完成
  if (intent === 'chat') return { status: 'COMPLETE', reason: '闲聊对话' }
  if (intent === 'ask' && botReply.length > 30) return { status: 'COMPLETE', reason: '提问已回答' }
  
  // 执行类请求 → 检查是否有实际产出
  if (intent === 'execute') {
    const hasCodeBlock = /```[\s\S]*?```/.test(botReply)
    const hasSteps = /\d+[\.\、]/.test(botReply)
    const hasOutput = botReply.length > 200
    
    // "好的"/"没问题"/"可以" 类空头回复
    const emptyPromise = /^(好的|没问题|可以|OK|好嘞|收到|明白|了解|没事).{0,20}$/i.test(botReply.trim())
    
    if (emptyPromise && !hasCodeBlock && !hasSteps) {
      return { status: 'INCOMPLETE', reason: '执行类请求但只有口头回应，没有实际产出' }
    }
    
    if (hasCodeBlock || hasSteps || hasOutput) {
      return { status: 'COMPLETE', reason: '包含代码块/步骤/充分内容' }
    }
    
    return { status: 'LIKELY_COMPLETE', reason: '回复较短但不确定是否足够' }
  }
}
```

**`task` 任务工作模式：**

```javascript
checkTask(intent, userMessage, botReply) {
  if (intent !== 'execute') {
    return { status: 'LIKELY_COMPLETE', reason: '非执行类请求' }
  }
  
  const hasCodeBlock = /```[\s\S]*?```/.test(botReply)
  const hasStepList = /(步骤|Step)\s*\d|(\d+[\.\、]).+\n/g.test(botReply)
  const hasProgressMarker = /✅|✓|完成|done|已|finished/i.test(botReply)
  const isShort = botReply.length < 100
  
  // 任务模式下的执行请求，回复太短 且 没有代码/步骤 → 未完成
  if (isShort && !hasCodeBlock && !hasStepList) {
    return { status: 'INCOMPLETE', reason: '任务模式下执行请求但缺少步骤或代码' }
  }
  
  return { status: 'COMPLETE', reason: '包含任务执行产出' }
}
```

**`report` 方案报告模式：**

```javascript
checkReport(intent, userMessage, botReply) {
  const hasHeading = /^#{1,3}\s+/m.test(botReply)
  const hasSections = (botReply.match(/^#{1,3}\s+/gm) || []).length >= 2
  const isSubstantial = botReply.length > 300
  
  if (intent === 'execute' || /方案|报告|计划|规划|总结/.test(userMessage)) {
    if (!hasSections && !isSubstantial) {
      return { status: 'INCOMPLETE', reason: '方案/报告模式但缺少结构化内容' }
    }
  }
  
  return { status: 'COMPLETE', reason: '报告内容结构充分' }
}
```

**`brainstorm` 创意脑暴模式：**

```javascript
checkBrainstorm(intent, userMessage, botReply) {
  // 统计独立想法/观点数量（通过编号、bullet、emoji 等标记）
  const ideaMarkers = botReply.match(/(\d+[\.\、\)]|[-•●]|\n\s*[🔹🔸💡✨🎯])/g) || []
  const ideaCount = ideaMarkers.length
  
  if (ideaCount < 2 && botReply.length < 200) {
    return { status: 'INCOMPLETE', reason: '创意模式但只有不到2个想法' }
  }
  
  return { status: 'COMPLETE', reason: `包含 ${ideaCount} 个创意点` }
}
```

**`decision` 快速决策模式：**

```javascript
checkDecision(intent, userMessage, botReply) {
  const hasConclusion = /建议|应该|选|推荐|结论|决定|优先|首选|最好/i.test(botReply)
  const isWishy = /都可以|各有优劣|看情况|取决于|两边都/i.test(botReply)
  
  // 决策模式应该有明确立场
  if (!hasConclusion && isWishy) {
    return { status: 'INCOMPLETE', reason: '决策模式但没有明确结论，在和稀泥' }
  }
  
  if (!hasConclusion && botReply.length < 50) {
    return { status: 'INCOMPLETE', reason: '决策模式但回复过短且无结论' }
  }
  
  return { status: 'COMPLETE', reason: '包含明确决策判断' }
}
```

**`discussion` 交流探讨模式：**

```javascript
checkDiscussion(intent, userMessage, botReply) {
  if (botReply.length < 50 && intent !== 'chat') {
    return { status: 'INCOMPLETE', reason: '交流探讨模式但回复过短，不像讨论' }
  }
  
  return { status: 'COMPLETE', reason: '讨论内容充分' }
}
```

**`thinking` 深度思考模式：**

```javascript
checkThinking(intent, userMessage, botReply) {
  if (intent === 'chat') return { status: 'COMPLETE', reason: '闲聊' }
  
  // 深度思考应该有分析过程
  const hasAnalysis = botReply.length > 150
  const hasJustDirectAnswer = botReply.length < 80 && !/因为|原因|分析|本质|角度/.test(botReply)
  
  if (hasJustDirectAnswer) {
    return { status: 'INCOMPLETE', reason: '深度思考模式但缺少分析过程' }
  }
  
  return { status: 'COMPLETE', reason: '包含分析思考内容' }
}
```

### 5.4 调用入口（总路由）

```javascript
check(userMessage, botReply, style) {
  const intent = this.classifyIntent(userMessage)
  
  // 全局快速通过：Bot 回复超过 500 字，大概率是完整的
  if (botReply.length > 500) {
    return { status: 'COMPLETE', reason: `回复 ${botReply.length} 字，内容充分` }
  }
  
  // 全局快速通过：闲聊意图
  if (intent === 'chat') {
    return { status: 'COMPLETE', reason: '闲聊对话' }
  }
  
  // 按模式分发
  switch (style) {
    case 'simple':      return this.checkSimple(intent, userMessage, botReply)
    case 'discussion':  return this.checkDiscussion(intent, userMessage, botReply)
    case 'thinking':    return this.checkThinking(intent, userMessage, botReply)
    case 'report':      return this.checkReport(intent, userMessage, botReply)
    case 'task':        return this.checkTask(intent, userMessage, botReply)
    case 'brainstorm':  return this.checkBrainstorm(intent, userMessage, botReply)
    case 'decision':    return this.checkDecision(intent, userMessage, botReply)
    default:            return { status: 'LIKELY_COMPLETE', reason: '未知模式，默认通过' }
  }
}
```

---

## 6. 第二层：AI 自检追问服务

### 6.1 文件位置

```
新建：backend/services/selfReviewService.js
```

### 6.2 核心接口

```javascript
/**
 * AI 自检追问服务
 * 仅在第一层判定 INCOMPLETE 时才触发
 * 每个 taskId 最多触发 1 次
 */
class SelfReviewService {
  
  constructor(openclawClient, taskMonitor) {
    this.openclawClient = openclawClient
    this.taskMonitor = taskMonitor
    
    // 自检追踪
    this.reviewHistory = new Map()   // taskId → { triggered: boolean, timestamp }
    this.sessionCooldowns = new Map() // sessionId → lastReviewTimestamp
    
    // 配置
    this.MAX_REVIEWS_PER_TASK = 1      // 每个任务最多自检 1 次
    this.SESSION_COOLDOWN_MS = 30000   // 同 session 冷却 30 秒
    this.SIMILARITY_THRESHOLD = 0.8    // 相似度阈值，超过则视为重复
    this.AUTO_CLEANUP_MS = 300000      // 5分钟后自动清理追踪记录
  }
  
  /**
   * 尝试触发自检
   * @returns {{ shouldReview: boolean, reason: string }}
   */
  canTriggerReview(taskId, sessionId) { ... }
  
  /**
   * 执行自检
   * @returns {{ hasSubstance: boolean, content: string|null }}
   */
  async executeReview(taskId, botId, sessionId, userMessage, botReply, style, model) { ... }
}
```

### 6.3 自检 Prompt 设计

```javascript
buildReviewPrompt(userMessage, botReply, style) {
  return `[系统自检指令]

你刚才回答了用户的一个问题。现在请自我检查：

用户原话：「${userMessage}」

你的回答：「${botReply.substring(0, 500)}」

请判断：
1. 用户要你「做」的事情，你是真的做了，还是只是「说了要做」？
2. 如果你只是口头答应但没有给出实际内容（代码/方案/步骤/文件），请现在补上。
3. 如果你确认已经完整回答了，直接回复 [TASK_COMPLETE] 四个字即可，不要说其他的。

注意：如果需要补充，直接给出补充内容，不要重复你之前说过的话。`
}
```

### 6.4 执行流程

```javascript
async executeReview(taskId, botId, sessionId, userMessage, botReply, style, model) {
  // 1. 检查是否允许触发
  const canReview = this.canTriggerReview(taskId, sessionId)
  if (!canReview.shouldReview) {
    console.log(`⏭️ [SelfReview] 跳过自检: ${canReview.reason}`)
    return { hasSubstance: false, content: null }
  }
  
  // 2. 记录触发
  this.reviewHistory.set(taskId, { triggered: true, timestamp: Date.now() })
  this.sessionCooldowns.set(sessionId, Date.now())
  console.log(`🔍 [SelfReview] 触发自检: taskId=${taskId}`)
  
  // 3. 构建自检 prompt
  const reviewPrompt = this.buildReviewPrompt(userMessage, botReply, style)
  
  // 4. 调用 OpenClaw（用同一个 session 保持上下文）
  const result = await this.openclawClient.sendMessage(botId, reviewPrompt, model, null, sessionId)
  
  if (!result.success || !result.data?.response) {
    console.warn(`⚠️ [SelfReview] 自检调用失败`)
    return { hasSubstance: false, content: null }
  }
  
  const reviewReply = result.data.response
  
  // 5. 判断自检结果
  
  // 5a. Bot 说任务已完成
  if (/\[TASK_COMPLETE\]/i.test(reviewReply)) {
    console.log(`✅ [SelfReview] Bot 确认任务已完成`)
    return { hasSubstance: false, content: null }
  }
  
  // 5b. 相似度检测 — 如果补充内容和原回复高度重复，丢弃
  const similarity = this.calculateSimilarity(botReply, reviewReply)
  if (similarity > this.SIMILARITY_THRESHOLD) {
    console.log(`🔄 [SelfReview] 补充内容与原回复重复度 ${(similarity*100).toFixed(0)}%，丢弃`)
    return { hasSubstance: false, content: null }
  }
  
  // 5c. 有实质补充
  console.log(`📝 [SelfReview] 获得实质补充，${reviewReply.length} 字`)
  return { hasSubstance: true, content: reviewReply }
}
```

### 6.5 相似度计算（轻量实现）

```javascript
/**
 * 简单关键词重合度计算
 * 不需要向量模型，纯字符串操作
 */
calculateSimilarity(text1, text2) {
  // 中文按字分割，英文按空格分割
  const tokenize = (text) => {
    const cleaned = text.replace(/[^\u4e00-\u9fff\w]/g, ' ').toLowerCase()
    return new Set(cleaned.split(/\s+/).filter(t => t.length > 1))
  }
  
  const set1 = tokenize(text1)
  const set2 = tokenize(text2)
  
  if (set1.size === 0 || set2.size === 0) return 0
  
  let intersection = 0
  for (const token of set1) {
    if (set2.has(token)) intersection++
  }
  
  // Jaccard 相似度
  const union = set1.size + set2.size - intersection
  return intersection / union
}
```

### 6.6 自动清理

```javascript
// 构造函数中启动定期清理
setInterval(() => {
  const now = Date.now()
  for (const [taskId, record] of this.reviewHistory) {
    if (now - record.timestamp > this.AUTO_CLEANUP_MS) {
      this.reviewHistory.delete(taskId)
    }
  }
  for (const [sessionId, timestamp] of this.sessionCooldowns) {
    if (now - timestamp > this.AUTO_CLEANUP_MS) {
      this.sessionCooldowns.delete(sessionId)
    }
  }
}, 60000) // 每分钟清理一次
```

---

## 7. 第三层：用户反馈触发

### 7.1 前端改动

在消息气泡组件中，Bot 消息末尾增加两个小按钮：

```vue
<template>
  <!-- Bot 消息气泡 -->
  <div class="message-bubble bot">
    <div class="message-content">{{ message.content }}</div>
    
    <!-- 自检反馈按钮（仅 Bot 消息 + 任务模式时显示） -->
    <div class="feedback-actions" v-if="message.sender === 'bot' && showFeedback">
      <button class="feedback-btn done" @click="$emit('feedback', 'complete')" title="任务已完成">
        👍 搞定了
      </button>
      <button class="feedback-btn redo" @click="$emit('feedback', 'incomplete')" title="还没做完">
        🔄 没做完
      </button>
    </div>
  </div>
</template>
```

### 7.2 后端 API

```
POST /api/messages/:botId/feedback
{
  "messageId": 12345,
  "userId": "admin",
  "feedback": "incomplete",   // "complete" | "incomplete"
  "sessionId": "user_admin_bot_xxx"
}
```

收到 `incomplete` 后，后端自动发送一条追问：

```javascript
// 用户反馈"没做完" → 发送追问
const followUpMessage = `用户反馈你的上一条回答没有完成任务。请回顾对话，把没做完的部分补上。直接输出内容，不要道歉。`

await this.openclawClient.sendMessage(botId, followUpMessage, model, userId, sessionId)
```

### 7.3 触发限制

- 每条消息只能反馈 1 次
- 点击后按钮变灰不可再点
- `incomplete` 触发的追问不再显示反馈按钮（防止循环）

---

## 8. 防循环刹车机制

这是整个方案最核心的安全设计。AI 自检最大的风险就是无限循环——Bot 一直觉得没做完，反复追问自己。

### 8.1 五重刹车

| # | 刹车名称 | 层级 | 规则 | 实现位置 |
|---|---------|------|------|---------|
| 1 | **任务次数硬上限** | 第二层 | 每个 taskId 最多 1 次自检，计数器 +1 后不再触发 | selfReviewService.reviewHistory |
| 2 | **会话冷却时间** | 第二层 | 同一个 sessionId 两次自检间隔 ≥ 30 秒 | selfReviewService.sessionCooldowns |
| 3 | **内容去重** | 第二层 | 自检回复和原回复 Jaccard 相似度 > 80% → 丢弃 | selfReviewService.calculateSimilarity |
| 4 | **跟进标记** | 全局 | 自检产生的消息带 `isFollowUp=true` 标记，直接跳过 completionChecker | botController 逻辑 |
| 5 | **全局开关** | 全局 | config.json 可配置 `selfReview.enabled = false` 一键关闭 | server.js 配置 |

### 8.2 最坏情况分析

```
场景：用户发1条消息，Bot 回复后第一层判定 INCOMPLETE

最坏路径：
  原消息 → Bot 回复 → 第一层判定 INCOMPLETE → 触发自检（第1次）
    → Bot 自检回复 → 带 isFollowUp=true → 跳过第一层 → 直接入库推送
    → 结束

最多额外调用：1 次 OpenClaw
不可能出现第 2 次自检（reviewHistory 已记录）
不可能出现循环（isFollowUp 标记直接跳过检查）
```

### 8.3 token 成本估算

```
自检 prompt 长度：~300 字（系统指令 + 用户原话 + Bot 原回复截断 500 字）
自检回复预期长度：~200-500 字

单次自检额外 token 消耗：约 800-1300 tokens
预估触发率：~15-25% 的对话（大部分在第一层就通过了）

以日均 500 条对话计：
  500 × 20% × 1000 tokens = 100K tokens/天
  ≈ 0.1 美元/天（按 GPT-4o 计价）
  实际使用 DeepSeek，成本更低
```

---

## 9. 7种模式 Prompt 重写规范

### 9.1 重写原则

1. **每个模式必须有独立的行为指导**，绝不复制粘贴
2. **区分"回答型"和"执行型"请求**，在 prompt 中明确告知 Bot
3. **Prompt 精简**，控制在 10 行以内（thinking 模式例外，但也要从 70 行压到 25 行以内）
4. **注入格式统一**，使用 `[系统指令]...[/系统指令]` 包裹，提高 LLM 遵从度

### 9.2 重写后的 7 种 Prompt

**`simple` 说人话模式**

```
[系统指令]
你现在是「说人话模式」。
- 回答简洁，1-5句话，像朋友聊天
- 但如果用户要求你做具体事情（写代码/写方案/做分析），你必须做完再说人话，不能只说"好的"就结束
- 判断标准：用户说完后能不能直接拿去用？能，才算完成
- 语气自然、有温度，不要机械
[/系统指令]
```

**`discussion` 交流探讨模式**

```
[系统指令]
你现在是「交流探讨模式」。
- 从正反面或多个角度分析问题，像两个人在讨论
- 控制在 300 字以内，口语化表达
- 要有自己的观点和立场，不要两边和稀泥
- 可以反问用户以推进讨论，但一次只问一个问题
- 结尾留一个开放话题保持对话节奏
[/系统指令]
```

**`thinking` 深度思考模式**

```
[系统指令]
你现在是「深度思考模式」。
核心原则：先确认需求，再深度分析，最后给有立场的判断。

1. 需求诊断：用户说的 = 想要的吗？不确定就反问（一次只问一个）
2. 如果前提有误，先纠正前提再回答
3. 分析：先想本质 → 再看角度 → 判断哪个角度最重要 → 给明确结论
4. 输出：先结论后理由，口语化，多选项时帮用户做取舍
5. 禁止：需求不明时强行给答案 / 和稀泥 / 长篇无立场 / 重复用户原话凑字数

气质：认真想过之后才开口的朋友，有温度，有立场，有深度。
[/系统指令]
```

**`report` 方案报告模式**

```
[系统指令]
你现在是「方案报告模式」。
- 输出必须是结构化文档：有标题(#/##)、有分节、有要点
- 格式要求：问题背景 → 分析 → 方案 → 行动建议 → 风险提示
- 内容翔实，不怕长，但每段都要有信息量
- 使用 Markdown 格式，方便用户直接复制使用
- 如果用户只是随口一问不需要报告，简短回答即可
[/系统指令]
```

**`task` 任务工作模式**

```
[系统指令]
你现在是「任务工作模式」。
- 收到任务后立即执行，不要只说"好的我来做"然后停下
- 输出格式：分步骤列出 → 每步给出具体内容/代码/操作 → 最后总结
- 如果任务复杂无法一次完成，明确说出已完成的部分和待完成的部分
- 如果信息不足无法执行，列出需要用户提供的具体信息
- 核心原则：用户看完你的回复后，能直接拿去用，而不是还要再问你一遍
[/系统指令]
```

**`brainstorm` 创意脑暴模式**

```
[系统指令]
你现在是「创意脑暴模式」。
- 至少给出 3-5 个不同方向的创意或想法
- 鼓励天马行空，不要自我审查，先发散再收敛
- 每个想法用一句话点题 + 2-3句展开说明
- 可以包含非常规的、甚至有点疯狂的点子
- 最后可以挑出你觉得最有潜力的 1-2 个重点展开
[/系统指令]
```

**`decision` 快速决策模式**

```
[系统指令]
你现在是「快速决策模式」。
- 直接给结论，不要铺垫，第一句话就是答案
- 格式：结论 → 核心理由（1-2条） → 行动建议
- 如果是二选一问题，明确选一个并说为什么
- 禁止说"都可以""看情况""各有优劣"这类废话
- 如果信息不足无法决策，直接说"信息不足，需要知道X和Y才能判断"
[/系统指令]
```

---

## 10. 单聊 vs 群聊：能否共用同一套方案

### 10.1 源码级对比

逐项对比单聊（botController）和群聊（groupController）的消息处理链路：

| 维度 | 单聊 `botController.sendMessage` | 群聊 `groupController.sendGroupMessage` |
|------|------|------|
| 文件位置 | `backend/src/controllers/botController.js` L181 | `backend/src/controllers/groupController.js` L532 |
| style 来源 | `req.body.style` ✅ | `req.body.style` ✅ |
| styleProcessor 处理 | ✅ `getStyleProcessor(style)` 注入 prompt（L297-307） | ❌ **完全没有调用 styleProcessor** |
| style 传给 OpenClaw | ✅ `openclawClient.sendMessage(..., style)` | ✅ `openclawClient.sendMessage(..., style)` |
| OpenClaw 是否用 style | ❌ CLI 参数里没有 `--style`，style 参数被忽略 | ❌ 同左 |
| Bot 回复处理 | `extractPlainText` → `isBotProcessContent` → 入库 | 直接 `saveGroupMessage` → 入库 |
| 回复质量检查 | ❌ 没有 | ❌ 没有 |
| taskMonitor 追踪 | ✅ 有 | ❌ 没有 |
| 消息推送 | WebSocket `sendToUser` 点对点 | WebSocket `broadcast` 广播 |

### 10.2 发现的关键问题

#### 🚨 P0 问题：群聊 style prompt 完全没生效

```
群聊链路：
  前端选了「任务工作模式」→ style='task' 发到后端
  → groupController.sendGroupMessage 收到 style='task'
  → 直接把原始 content 组装上下文
  → openclawClient.sendMessage(botId, contextMessage, null, 'group', groupSessionId, style)
                                                                                     ↑
                                                               style 传了但 openclaw CLI 不认这个参数
  → 结果：style 指令从头到尾没有注入到消息内容里
  → Bot 根本不知道用户选了什么模式
```

对比单聊：
```
单聊链路：
  前端选了「任务工作模式」→ style='task' 发到后端
  → botController.sendMessage 收到 style='task'
  → getStyleProcessor('task') 获取处理器
  → processor(content, botId) → 把 style prompt 注入到 content 前面     ← 群聊缺这一步
  → openclawClient.sendMessage(botId, 带prompt的content, ...)
  → Bot 看到了 [当前模式：任务工作模式] 指令
```

**结论：群聊里用户切换聊天模式是完全无效的。** 前端 UI 上有模式切换按钮，用户以为切了，但后端根本没处理。

#### ⚠️ P1 问题：群聊没有 extractPlainText / isBotProcessContent

单聊里 Bot 回复会经过两道过滤：
- `extractPlainText` — 处理 JSON 格式的回复，提炼纯文本
- `isBotProcessContent` — 过滤掉思考过程、进度日志等非最终内容

群聊的 `_triggerMentionedBots` 方法（L227-237）拿到 Bot 回复后直接存库，没有任何过滤。如果 Bot 返回了 JSON 或过程日志，会原样显示在群聊里。

#### ⚠️ P1 问题：群聊没有 taskMonitor

群聊触发 Bot 后（L223-225），没有创建任务追踪。用户无法知道 Bot 是否在处理、处理到哪了、有没有失败。

### 10.3 结论：能共用同一套方案吗

**能。而且必须共用。**

三层自检机制（completionChecker + selfReviewService + 用户反馈）是纯逻辑服务，不依赖单聊/群聊的消息格式。只需要三个输入：

```
输入：userMessage（原始消息）、botReply（Bot 回复）、style（聊天模式）
输出：{ status: 'COMPLETE' | 'INCOMPLETE', reason: string }
```

单聊和群聊都能提供这三个输入。

### 10.4 群聊需要额外补的基础设施

在接入自检方案之前，群聊需要先补上缺失的基础能力：

| # | 缺失项 | 补法 | 优先级 |
|---|--------|------|--------|
| 1 | **style prompt 注入** | `_triggerMentionedBots` 中调用 `getStyleProcessor(style)` 处理 contextMessage | P0 |
| 2 | **extractPlainText 过滤** | Bot 回复入库前加 `extractPlainText` 处理 | P1 |
| 3 | **isBotProcessContent 过滤** | Bot 回复入库前加 `isBotProcessContent` 检查 | P1 |
| 4 | **getStyleProcessor 注入** | GroupController 构造函数增加 `config` 依赖（含 getStyleProcessor） | P0 |

### 10.5 统一接入方案

```
目标架构：

                    ┌──────────────────────────┐
                    │   completionChecker.js    │  ← 共用
                    │   selfReviewService.js    │  ← 共用
                    └────────────┬─────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                                     ▼
   botController.js                      groupController.js
   sendMessage()                         _triggerMentionedBots()
      │                                     │
      ├─ getStyleProcessor ✅                ├─ getStyleProcessor ← 需要补
      ├─ openclawClient.sendMessage          ├─ openclawClient.sendMessage
      ├─ extractPlainText ✅                 ├─ extractPlainText ← 需要补
      ├─ isBotProcessContent ✅              ├─ isBotProcessContent ← 需要补
      ├─ 【completionChecker.check】         ├─ 【completionChecker.check】
      ├─ 【selfReviewService (if needed)】   ├─ 【selfReviewService (if needed)】
      ├─ saveMessage                         ├─ saveGroupMessage
      └─ wsManager.sendToUser                └─ wsManager.broadcast
```

### 10.6 群聊自检的特殊考量

群聊有一些单聊没有的场景需要额外处理：

| 场景 | 处理方式 |
|------|----------|
| @all 触发多个 Bot | 每个 Bot 的回复独立自检，互不影响 |
| Bot A 回复中 @Bot B（链式触发） | 链式触发的 Bot B 回复也需要自检，但 triggerDepth≥1 时不再自检（避免连环） |
| 多个 Bot 同时自检 | 每个 Bot 走独立的 taskId，不冲突 |
| 群聊消息更多、上下文更复杂 | 自检 prompt 中附带群聊上下文摘要（前3条相关消息） |

```javascript
// 群聊自检的触发条件增加一个限制：
// 只有 triggerDepth === 0（用户直接触发的 Bot）才做自检
// depth >= 1（Bot 触发 Bot）不做自检，避免连环自检
if (triggerDepth === 0) {
  const checkResult = completionChecker.check(messageContent, botResponse, style)
  if (checkResult.status === 'INCOMPLETE') {
    // 触发自检...
  }
}
```

---

## 11. 前后端模式一致性修复

### 11.1 统一定义为 7 种模式（去掉 normal）

```
simple      说人话     🗣️   简洁高效，该做事时做事
discussion  交流探讨   💬   多角度讨论分析
thinking    深度思考   🤔   先理解需求再深度回答
report      方案报告   📋   结构化报告文档
task        任务工作   ⚙️   分步骤执行任务
brainstorm  创意脑暴   🧠   发散创意想法
decision    快速决策   ⚡   直接给结论行动
```

### 11.2 需要同步修改的位置

| 文件 | 当前问题 | 修改内容 |
|------|---------|---------|
| `frontend/src/renderer/utils/constants.ts` L95-103 | 有 `normal` 没 `thinking` | 删除 `normal`，添加 `thinking` |
| `frontend/src/renderer/App.vue` L417-425 | 正确，但 desc 需要更新 | 更新描述文字 |
| `backend/server.js` L132-341 | 4个模式 prompt 相同 | 全部重写（见第9章） |
| `backend/server.js` L326-341 | getStyleProcessor fallback 到 simple | 保持 fallback 但去掉 normal 选项 |
| `frontend/src/renderer/App.vue` L354 | 默认 `simple` | 考虑改为 `discussion`（待讨论） |

---

## 12. 改动文件清单与实施顺序

### 12.1 实施分四个阶段

**阶段一：Prompt 重写 + 一致性修复（P0，立即做）**

| # | 文件 | 改动 | 风险 |
|---|------|------|------|
| 1 | `backend/server.js` L132-341 | 重写 7 个 styleProcessors prompt | 低（只改字符串） |
| 2 | `frontend/src/renderer/utils/constants.ts` L95-103 | 删 normal 加 thinking | 低 |
| 3 | `frontend/src/renderer/App.vue` L417-425 | 更新 desc | 低 |

**阶段二：群聊基础设施补齐（P0，和阶段一同步做）**

| # | 文件 | 改动 | 风险 |
|---|------|------|------|
| 4 | `backend/src/controllers/groupController.js` 构造函数 L30 | 增加 `config` 依赖注入（含 getStyleProcessor） | 低 |
| 5 | `backend/src/controllers/groupController.js` `_triggerMentionedBots` L210-225 | 在 contextMessage 组装后、发送前，调用 `getStyleProcessor(style)` 注入 prompt | 中（核心链路） |
| 6 | `backend/src/controllers/groupController.js` `_triggerMentionedBots` L227-237 | Bot 回复入库前增加 `extractPlainText` + `isBotProcessContent` 过滤 | 中 |
| 7 | `backend/server.js` GroupController 实例化部分 | 传入 `config`（含 getStyleProcessor）到 GroupController | 低 |

**阶段三：自检机制 — 单聊+群聊统一接入（P0，紧跟实施）**

| # | 文件 | 改动 | 风险 |
|---|------|------|------|
| 8 | 新建 `backend/services/completionChecker.js` | 第一层规则判断器（单聊群聊共用） | 低（新文件） |
| 9 | 新建 `backend/services/selfReviewService.js` | 第二层 AI 自检服务（单聊群聊共用） | 中（涉及 AI 调用） |
| 10 | `backend/src/controllers/botController.js` L312-365 | sendMessage 异步回调插入检查逻辑 | 中（核心链路） |
| 11 | `backend/src/controllers/groupController.js` `_triggerMentionedBots` L227+ | Bot 回复入库前插入检查逻辑（仅 triggerDepth===0 时） | 中 |
| 12 | `backend/services/task-monitor.js` | 增加 followUpCount 字段 | 低 |
| 13 | `backend/server.js` 依赖注入部分 | 初始化并注入新服务到两个 controller | 低 |

**阶段四：前端反馈按钮（P2，后续优化）**

| # | 文件 | 改动 | 风险 |
|---|------|------|------|
| 14 | 前端消息气泡组件（单聊+群聊） | 增加 👍🔄 反馈按钮 | 低 |
| 15 | `backend/src/routes/botRoutes.js` | 增加 feedback API | 低 |
| 16 | `backend/src/controllers/botController.js` | 增加 handleFeedback 方法 | 低 |

### 12.2 单聊 botController.js 核心改动位置

```javascript
// 改动位置：botController.js sendMessage 的异步处理部分
// 原来的流程（L312-365）：
//   Bot 回复 → extractPlainText → isBotProcessContent → saveMessage → completed → 推送

// 改为：
//   Bot 回复 → extractPlainText → isBotProcessContent
//   → 【新增】completionChecker.check(originalContent, botResponse, style)
//   →   COMPLETE → 正常存库推送
//   →   INCOMPLETE → selfReviewService.executeReview(...)
//       → 有补充 → 补充内容作为新消息存库推送
//       → 无补充 → 正常存库推送
//   → saveMessage → completed → 推送
```

### 12.3 群聊 groupController.js 核心改动位置

```javascript
// 改动位置：groupController._triggerMentionedBots L210-245
// 原来的流程：
//   组装 contextMessage → openclawClient.sendMessage → result.data.response → saveGroupMessage → broadcast

// 改为：
//   组装 contextMessage
//   → 【新增】getStyleProcessor(style) 注入 prompt 到 contextMessage
//   → openclawClient.sendMessage
//   → 【新增】extractPlainText(response)
//   → 【新增】isBotProcessContent(response) 过滤
//   → 【新增】if (triggerDepth === 0) completionChecker.check(...)
//   →   INCOMPLETE → selfReviewService.executeReview(...)
//       → 有补充 → 追加为新群消息 broadcast
//       → 无补充 → 跳过
//   → saveGroupMessage → broadcast
```

### 12.4 config.json 新增配置

```json
{
  "selfReview": {
    "enabled": true,
    "maxReviewsPerTask": 1,
    "sessionCooldownMs": 30000,
    "similarityThreshold": 0.8,
    "cleanupIntervalMs": 300000
  }
}
```

---

## 13. 风险评估

| 风险 | 等级 | 影响 | 缓解措施 |
|------|------|------|---------|
| 自检无限循环 | 严重 | Bot 不停自问自答，消耗大量 token | 五重刹车机制（见第8章） |
| 群聊 @all 多 Bot 同时自检 | 高 | N个Bot同时触发自检，N次额外AI调用 | 群聊自检只在 triggerDepth===0 时触发；@all 场景可配置并发上限 |
| 群聊链式触发+自检叠加 | 高 | Bot A 自检 → @Bot B → Bot B 又自检 | triggerDepth≥1 不做自检，切断链条 |
| 自检导致响应变慢 | 中 | 用户等待时间翻倍 | 原消息先推送，补充内容异步追加为新消息 |
| 误判 INCOMPLETE | 中 | 不需要自检的回复触发了自检 | 第一层规则保守设计，宁可漏检不要误检 |
| 自检 prompt 泄露 | 低 | 用户看到"[系统指令]"等内容 | isBotProcessContent 增加对自检指令的过滤 |
| OpenClaw 自检调用失败 | 低 | 自检没执行，回退到原始回复 | try-catch 兜底，失败不影响原回复的推送 |
| config 关闭后残留影响 | 低 | 关闭开关后自检仍触发 | 检查点在最前面，enabled=false 直接跳过整个流程 |

### 降级策略

```
如果自检服务出现任何异常：
  → 不阻塞原消息的存库和推送
  → 错误只记日志，不影响用户
  → 相当于回退到当前"没有自检"的行为
  → 即：自检是纯增量功能，关掉/崩了都不影响现有流程
```

---

> **下一步**：方案确认后，按阶段一 → 阶段二 → 阶段三顺序实施。
