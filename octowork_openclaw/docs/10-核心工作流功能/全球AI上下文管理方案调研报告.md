# 全球 AI 上下文管理方案调研报告

> 创建时间：2026-04-05
> 调研范围：消费级产品（ChatGPT/Claude/Gemini/Copilot）+ 开源框架（MemGPT/Mem0/LangChain）+ 学术方案
> 目的：为 OctoWork 记忆系统改造提供参考
> 作者：AI开发助手

---

## 零、核心结论先放前面

调研完全球主流方案后，行业在 2025-2026 年已经收敛到一个共识：

> **滑动窗口 + 摘要压缩 + 外部记忆检索** 三者混合，是当前的主流最优解。

没有任何一家只用单一策略。区别只在于**混合比例和实现精度**。

OctoWork 目前做的"清空 + 保留5条"，相当于只做了滑动窗口的最粗暴版本，缺了摘要压缩和外部记忆检索这两条腿。

---

## 一、先搞清楚：所有方案都在解决同一个物理限制

```
┌──────────────────────────────────────────────────────────┐
│                    模型的 Context Window                   │
│                                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ System   │ │ 历史对话  │ │ 检索注入  │ │ 当前消息  │    │
│  │ Prompt   │ │          │ │          │ │          │    │
│  │ ~2K      │ │ 越来越大→ │ │ 按需注入  │ │ ~1K      │    │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘    │
│                                                          │
│  总计不能超过 128K / 200K / 1M tokens（取决于模型）         │
└──────────────────────────────────────────────────────────┘

核心矛盾：历史对话无限增长 vs 窗口容量有限
所有方案的本质：管理"历史对话"这块空间
```

---

## 二、消费级产品方案详解

### 2.1 OpenAI ChatGPT — 四层记忆架构

**逆向工程揭示的真实架构（2025年12月）：**

ChatGPT 没有用复杂的 RAG 系统，而是用了四层简洁架构：

| 层级 | 内容 | 持久性 | 优先级 |
|------|------|--------|--------|
| 第1层：会话元数据 | 设备、位置、时区、使用习惯 | 会话级（关掉就没了） | 低 |
| 第2层：用户记忆 | 用户明确要求记住的事实（约30-50条） | 永久（跨所有会话） | 最高 |
| 第3层：近期对话摘要 | 最近约15个对话的简短摘要（只记用户说了什么） | 持久（自动更新） | 高 |
| 第4层：当前会话消息 | 本次对话的完整消息 | 会话级 | 当空间不够时最先被裁剪 |

**关键设计决策：**
- 用户记忆是**显式的**（用户说"记住XX"或AI检测到重要信息后确认），不是暗中推断
- 近期摘要**只摘要用户说的**，不摘要AI回复（节省token）
- 当token不够时，**裁剪当前会话**而不是裁剪永久记忆
- 没有用 RAG/向量搜索——用预计算的摘要直接注入，换取速度

**优点：**
- 简单高效，延迟极低
- 用户控制强（可手动删除记忆）
- 永久记忆不受会话清理影响

**缺点：**
- 记忆深度浅（只有30-50个事实）
- 近期摘要只覆盖约15个对话
- 不适合需要回忆几个月前细节的场景

**对 OctoWork 的启示：** ChatGPT 的"用户记忆"层 ≈ OctoWork Agent 公寓的 `memory/` 目录，但 ChatGPT 每次调用都会注入这些记忆，而 OctoWork 只是写在文件里没人读。

---

### 2.2 Anthropic Claude — 自动压缩 + 记忆工具

**Claude 的策略（2025-2026）：**

| 机制 | 说明 |
|------|------|
| 自动压缩（Compaction） | 接近窗口上限时自动摘要对话，用压缩后的内容替换原始历史 |
| Context Editing API | 允许开发者选择性清除对话中的特定内容 |
| Memory Tool | 类似 ChatGPT 的持久记忆，AI可以主动存取跨会话的记忆条目 |
| Projects 知识库 | 项目级别的文档集合，每次对话自动注入相关知识 |

**关键设计决策：**
- 压缩是**自动触发**的，用户不用操心
- Context Editing 让开发者有精细控制权（不是全删或全留，可以选择性删除）
- Memory 存储用的是简单的 key-value 结构，不是向量数据库
- Projects 机制本质上是一个简化版 RAG（文档集 → 自动检索 → 注入上下文）

**优点：**
- 自动压缩对用户透明，体验最好
- Context Editing API 给开发者最大灵活性
- 支持项目级知识（适合企业场景）

**缺点：**
- 压缩仍可能丢失重要细节
- Memory 工具功能相对简单
- 自动压缩时有短暂延迟

**对 OctoWork 的启示：** Claude 的 Context Editing（选择性清除）思路值得借鉴——OctoWork 清理时不应该盲选5条，而应该按内容价值选择性保留。Claude 的 Projects 机制 ≈ OctoWork 设想的"章鱼学院"。

---

### 2.3 Google Gemini — 超大窗口 + Context Caching

**Gemini 的策略：**

| 机制 | 说明 |
|------|------|
| 超大 Context Window | Gemini 2.5 Pro 支持 1M tokens，Gemini 3 系列扩展到 2M+ |
| 显式缓存（Explicit Caching） | 开发者可以把重复使用的内容缓存到服务端，后续请求直接引用 |
| 隐式缓存（Implicit Caching） | Gemini 2.5+ 自动检测重复内容并缓存，无需开发者配置 |

**关键设计决策：**
- Google 的哲学是"窗口够大就不用管理"——直接把窗口做到 1M-2M tokens
- Context Caching 解决的是**成本问题**而非容量问题（缓存的token打折计费）
- 没有复杂的记忆管理机制，依赖大窗口暴力解决

**优点：**
- 最简单粗暴——窗口大到绝大多数场景用不完
- 缓存机制降低成本
- 开发者不用实现复杂的上下文管理

**缺点：**
- 窗口再大也有极限（百万级会话最终还是会满）
- 大窗口下模型对"中间位置"信息的注意力衰减（Lost in the Middle 问题）
- 成本高（1M tokens 的输入费用远高于精简后的 10K tokens）
- 不解决跨会话记忆问题

**对 OctoWork 的启示：** OctoWork 用的是 OpenClaw 调用各种模型，不能选择只用 Gemini 的大窗口。而且即使用了大窗口，群聊场景下多个 Bot 的历史叠加也很快会触顶。大窗口是"缓解"不是"解决"。

---

### 2.4 Microsoft Copilot — 企业级记忆 + Microsoft Graph

**Copilot 的策略：**

| 机制 | 说明 |
|------|------|
| Copilot Memory | 跨会话持久记忆，存储用户偏好和工作习惯 |
| Microsoft Graph 检索 | 从 Outlook/Teams/SharePoint/OneDrive 检索相关文档（企业级RAG） |
| Grounding | 每次调用前从 Graph 检索最相关内容注入上下文 |

**关键设计决策：**
- 记忆不只是对话历史——整个企业的文档、邮件、日程都是"记忆源"
- 每次对话前做一次 Grounding（检索 + 注入），而不是依赖 session 历史
- 管理员可以控制哪些数据可以被 Copilot 访问

**优点：**
- 企业场景下最强——能调用整个组织的知识
- 用户不需要重复提供背景信息
- 数据安全控制完善

**缺点：**
- 重度依赖 Microsoft 生态
- Grounding 检索质量取决于数据组织方式
- 非 Microsoft 数据源的支持有限

**对 OctoWork 的启示：** OctoWork 的 Agent 公寓目录（memory/、chat_history/、SOP/、tools/）就是自己的"Microsoft Graph"。关键是在每次对话前从这些目录检索相关内容注入。

---

## 三、开源框架/学术方案详解

### 3.1 MemGPT / Letta — 操作系统式分层记忆（最接近OctoWork设想）

**核心思想：** 把 LLM 的上下文管理类比为操作系统的内存管理。

```
┌────────────────────────────────────┐
│  Main Context（主内存）              │  ← 容量有限，相当于 RAM
│  = 模型的 Context Window            │
│  存放：System Prompt + 当前对话     │
└──────────────┬─────────────────────┘
               │  page in / page out（换页）
┌──────────────▼─────────────────────┐
│  External Storage（外部存储）        │  ← 容量无限，相当于硬盘
│  = 向量数据库 / 文件系统             │
│  存放：完整历史、知识库、长期记忆    │
└────────────────────────────────────┘

AI 自己决定什么时候 page in（把外部记忆调入上下文）
AI 自己决定什么时候 page out（把不需要的内容移出上下文）
```

**Letta (MemGPT的商业化产品) 2026年实测：**
- 在 LoCoMo 基准测试中，仅用文件系统存储聊天记录就达到了 74% 的记忆召回率
- 击败了多个专门的记忆系统
- 证明了"简单的文件存储 + 好的检索策略"比复杂架构更实用

**优点：**
- 理论上可以实现"无限记忆"
- AI自主管理，不需要外部调度
- 分层架构直觉清晰

**缺点：**
- 换页操作本身消耗 token（AI要决定换什么）
- 实现复杂度高
- AI 的自主换页决策可能不准确

**对 OctoWork 的启示：** ⭐ 这是和 OctoWork 四层蒸馏塔最相似的方案。OctoWork 的 L0/L1/L2 记忆层就是 MemGPT 的"主内存"分级，Agent 公寓就是"外部存储"。差的只是**换页机制**——谁来决定什么时候把外部记忆调入上下文。

---

### 3.2 Mem0 — 图结构持久记忆

**核心思想：** 用知识图谱存储实体和关系，而非简单的 key-value。

```
存储示例：
  (用户) --[偏好]--> (Python)
  (用户) --[正在做]--> (竞品分析报告)
  (竞品分析报告) --[截止时间]--> (明天)
  (竞品分析报告) --[重点]--> (价格对比)
```

**2026年状态：**
- 在 LoCoMo 基准测试中排名领先
- 支持多种后端（向量数据库、图数据库、简单文件）
- 21+ 集成（LangChain、CrewAI、AutoGen 等）

**优点：**
- 结构化记忆，检索精准
- 支持复杂关系推理（"用户上次提到的那个项目的截止时间是什么？"）
- 记忆自动去重和更新

**缺点：**
- 需要额外的提取步骤（每次对话后提取实体/关系）
- 图结构维护成本高
- 对中文支持不如英文

**对 OctoWork 的启示：** OctoWork 的任务系统（task_box）天然适合图结构——任务 → 负责人 → 截止日期 → 依赖关系。但短期内用文件系统+检索更实际。

---

### 3.3 LangChain Memory — 五种记忆类型

LangChain 提供了最完整的记忆类型分类：

| 类型 | 机制 | 适用场景 |
|------|------|----------|
| **ConversationBufferMemory** | 保存完整对话历史，不做任何处理 | 短对话 |
| **ConversationSummaryMemory** | 定期用 AI 摘要历史对话 | 长对话 |
| **ConversationSummaryBufferMemory** | 混合：最近的保留原文，老的摘要 | 中长对话（最常用） |
| **ConversationEntityMemory** | 提取实体和属性，结构化存储 | 需要记住大量人名/项目等 |
| **ConversationKnowledgeGraphMemory** | 构建知识图谱 | 复杂关系场景 |

**对 OctoWork 的启示：** ⭐ `ConversationSummaryBufferMemory` 就是 OctoWork 最应该采用的模式——最近的对话保留原文（保持上下文连贯），老的对话摘要后存档（节省token）。这正是"充电"的技术实现。

---

### 3.4 LLMLingua — 上下文压缩（不改语义，只砍token）

**核心思想：** 用小模型判断每个 token 的重要性，删掉不重要的 token，保留语义。

```
原文（50 tokens）：
  "我想请你帮我分析一下我们竞品公司最近发布的那个新产品的主要功能特点和定价策略"

压缩后（25 tokens）：
  "帮我分析竞品新产品功能和定价"

语义不变，token 减半。
```

**实测数据（微软研究院）：**
- 可以将 prompt 压缩到原来的 20-50%
- 在大多数任务上性能损失 < 5%
- 特别适合 RAG 场景（检索出的文档往往有大量冗余）

**优点：**
- 不改变语义，只减少冗余
- 和其他方法可以叠加使用
- 压缩比可调

**缺点：**
- 需要额外的推理步骤（小模型跑一遍判断重要性）
- 中文场景的效果不如英文
- 过度压缩可能丢失细微语义

**对 OctoWork 的启示：** 可以作为优化手段——在给 OpenClaw 发消息前，先用 LLMLingua 压缩群聊上下文，同样的 token 预算可以塞入更多有效信息。

---

### 3.5 Google Multi-Agent Framework — 滑动窗口 + 摘要混合

**Google 2025年12月发布的企业级多 Agent 框架方案：**

```
事件流（持续产生）
    │
    ▼
┌───────────────┐
│ 滑动窗口      │  ← 最近 N 条事件保留原文
│ (Recent)      │
└───────┬───────┘
        │ 窗口外的事件 →
        ▼
┌───────────────┐
│ 压缩摘要      │  ← 用 LLM 摘要窗口外的事件
│ (Compacted)   │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ 注入上下文    │  ← 摘要 + 最近原文 → 发给模型
│ (Combined)    │
└───────────────┘
```

**对 OctoWork 的启示：** ⭐⭐ 这就是 OctoWork 群聊应该用的模式——最近几条群消息保留原文，之前的消息摘要后注入。

---

## 四、综合对比矩阵

| 方案 | 核心策略 | 复杂度 | 记忆深度 | 实时性 | 适合OctoWork？ |
|------|----------|--------|----------|--------|----------------|
| ChatGPT 四层 | 显式记忆 + 摘要 + 全文 | ⭐⭐ | 浅 | 高 | ✅ 用户记忆层可借鉴 |
| Claude 自动压缩 | 自动压缩 + Context Editing | ⭐⭐⭐ | 中 | 高 | ✅ 选择性清除思路可借鉴 |
| Gemini 大窗口 | 暴力大窗口 + 缓存 | ⭐ | 高（但有衰减） | 高 | ⚠️ 不能依赖单一模型 |
| Copilot Graph | 企业知识图谱 + Grounding | ⭐⭐⭐⭐ | 极深 | 中 | ⚠️ 过重，但思路可借鉴 |
| MemGPT/Letta | OS式分层 + 自主换页 | ⭐⭐⭐⭐ | 理论无限 | 中 | ✅ 架构最接近蒸馏塔 |
| Mem0 | 图结构持久记忆 | ⭐⭐⭐ | 深 | 中 | ⚠️ 短期太重 |
| LangChain SummaryBuffer | 摘要+缓冲混合 | ⭐⭐ | 中 | 高 | ⭐⭐⭐ 最佳起步方案 |
| LLMLingua | Token级压缩 | ⭐⭐ | 不变 | 高 | ✅ 可叠加优化 |
| Google 滑动+摘要 | 滑动窗口+摘要混合 | ⭐⭐ | 中 | 高 | ⭐⭐⭐ 群聊最佳方案 |

---

## 五、行业趋势总结（2025-2026）

### 趋势1：滑动窗口 + 摘要混合已成主流共识

> "The field has converged on sliding window plus summarisation hybrids as the dominant approach: keep recent turns in full detail, compress older turns into summaries."
> — State of Context Engineering in 2026, Medium

**所有主流产品都在做同一件事：** 近期保留原文，远期压缩摘要。区别只是压缩的精细程度。

### 趋势2：外部记忆从"可选"变成"必须"

2025年以前，外部记忆（持久存储）被视为高级特性。2026年，ChatGPT Memory、Claude Memory、Copilot Memory 全部上线，**持久记忆已成标配**。

### 趋势3：简单方案打败复杂方案

Letta/MemGPT 的基准测试证明：**纯文件系统存储 + 简单检索**在记忆召回上击败了多个专门的向量数据库方案。过度工程化不如把简单的事做好。

### 趋势4：AI 自主管理记忆

越来越多的系统让 AI 自己决定"记什么、忘什么、什么时候回忆"。人工规则（如固定保留5条）正在被 AI 驱动的记忆管理取代。

### 趋势5：多 Agent 场景的记忆共享成为新焦点

单 Agent 记忆已经有成熟方案。2026年的新课题是：多个 Agent 之间如何共享和协调记忆。这正是 OctoWork 群聊面对的问题。

---

## 六、对 OctoWork 的最终建议

基于以上调研，OctoWork 最适合的方案组合是：

```
┌─────────────────────────────────────────────────┐
│         OctoWork 推荐方案（四层组合）              │
├─────────────────────────────────────────────────┤
│                                                 │
│  第1层：SummaryBuffer（摘要缓冲）                 │
│  ├── 借鉴：LangChain ConversationSummaryBuffer  │
│  ├── 做法：最近 N 轮保留原文，之前的用 AI 摘要     │
│  ├── 清空时：让 AI 生成结构化摘要再清               │
│  └── 用于：单聊 session 清理（解决 P0 失忆问题）   │
│                                                 │
│  第2层：角色+任务注入（Grounding）                 │
│  ├── 借鉴：Copilot Graph Grounding               │
│  ├── 做法：每次调用前从 Agent 公寓读取              │
│  │         memory/*.md + 角色设定 + 当前任务状态   │
│  └── 用于：单聊+群聊（解决"每次像新人"问题）       │
│                                                 │
│  第3层：滑动窗口+相关性过滤（群聊专用）             │
│  ├── 借鉴：Google Multi-Agent Sliding+Compaction │
│  ├── 做法：群消息按相关性过滤+时间衰减权重          │
│  │         窗口外消息摘要为"群聊摘要"注入           │
│  └── 用于：群聊 @Bot（解决 P0 群聊失忆问题）       │
│                                                 │
│  第4层：持久记忆（ChatGPT Memory 模式）            │
│  ├── 借鉴：ChatGPT 用户记忆 + Letta 文件系统      │
│  ├── 做法：Agent 公寓 memory/ 目录就是持久记忆     │
│  │         每次对话注入最新 memory 条目             │
│  │         蒸馏塔第三层（记忆大师）负责更新          │
│  └── 用于：跨会话/跨天记忆（解决"隔天失忆"问题）   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 实施优先级建议：

| 优先级 | 改动 | 效果 | 工作量 |
|--------|------|------|--------|
| 🔴 P0 | 清空前让AI生成结构化摘要（替代盲选5条+废话） | 解决单聊失忆 | 中（改清理流程） |
| 🔴 P0 | 每次调用前从 memory/ 读取并注入到 message | 解决跨会话失忆 | 小（改 openclawClient） |
| 🔴 P0 | 群聊上下文改为滑动窗口+摘要混合 | 解决群聊失忆 | 中（改 groupController） |
| 🟡 P1 | 实现蒸馏塔第三层（记忆大师每日提炼） | 解决隔天失忆 | 大（新模块） |
| 🟢 P2 | 上下文压缩（LLMLingua 思路） | 优化 token 使用 | 中（可后做） |
| 🟢 P2 | 蒸馏塔第四层（章鱼学院/知识库） | 跨 Bot 知识共享 | 大（新系统） |

---

## 七、参考资料

| 来源 | 链接 |
|------|------|
| ChatGPT 记忆逆向工程 | https://llmrefs.com/blog/reverse-engineering-chatgpt-memory |
| Claude Context Editing API | https://platform.claude.com/docs/en/build-with-claude/context-editing |
| Gemini Context Caching 官方文档 | https://ai.google.dev/gemini-api/docs/caching |
| MemGPT 论文 (UC Berkeley) | https://arxiv.org/abs/2310.08560 |
| Letta 文件系统基准测试 | https://www.letta.com/blog/benchmarking-ai-agent-memory |
| Mem0 2026 状态报告 | https://mem0.ai/blog/state-of-ai-agent-memory-2026 |
| LangChain Memory 文档 | https://python.langchain.com/docs/modules/memory/ |
| LLMLingua (微软研究院) | https://llmlingua.com/ |
| Google 多Agent上下文框架 | https://developers.googleblog.com/architecting-efficient-context-aware-multi-agent-framework-for-production/ |
| Context Engineering 2026 综述 | https://medium.com/@kushalbanda/state-of-context-engineering-in-2026 |
| AI Agent Memory 2026 框架对比 | https://vectorize.io/articles/best-ai-agent-memory-systems |
| Copilot Memory 企业指南 | https://collabsummit.eu/blog/microsoft-365-copilot-memory-enterprise-guide-european-organizations |

---

*调研完成。老板看完后可以继续讨论 OctoWork 的"充电"方案细节。*
