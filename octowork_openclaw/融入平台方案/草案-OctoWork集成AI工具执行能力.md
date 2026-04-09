# OctoWork 集成 AI 工具执行能力 —— 产品方案草案

> **文档版本**: v0.1（草案）  
> **日期**: 2026-04-09  
> **作者**: PM 视角梳理  
> **目标读者**: 研发团队、产品团队  

---

## 一、背景与目标

### 1.1 现状痛点

用户目前要获得「AI 帮我操作电脑/执行脚本」这个能力，需要：

1. 安装 **OpenClaw**（一个独立的第三方 AI Agent 运行时，582MB，复杂度极高）  
2. 安装 **OctoWork**（我们的业务管理平台）  
3. 两套系统通过 WebSocket 联通  

这带来了巨大的安装门槛、维护成本，以及不必要的产品耦合。

### 1.2 目标

> **用户只安装 OctoWork，就能让 AI 员工调用各种脚本和工具来完成真实任务。**

具体来说：
- 模型配置在 OctoWork 内进行
- Agent（AI 员工/部门）在 OctoWork 内创建和管理
- AI 直接调用工具（执行命令、读写文件、联网搜索、截图等）
- **不再依赖 OpenClaw 进程**

### 1.3 不在本期范围

- 技能（Skills）系统
- 语义记忆（Memory/Embedding）
- 多 Agent 协作调度
- 消息平台接入（Telegram、WhatsApp）

---

## 二、我们要实现的核心功能拆解

根据对 OpenClaw 源码（`src/agents/`）的分析，其核心能力可拆解为：

| 能力模块 | OpenClaw 实现位置 | 我们需要做什么 | 优先级 |
|----------|-----------------|--------------|--------|
| **调用 LLM API** | `pi-embedded-runner/run.ts` + `@mariozechner/pi-agent-core` | 直接 fetch，自行管理 | ⭐⭐⭐ 最高 |
| **会话管理（多轮对话）** | `src/sessions/` + SQLite | 复用现有 chat.db | ⭐⭐⭐ 最高 |
| **工具注册机制** | `pi-tools.ts` → 向 LLM 声明工具 schema | 自行实现 Tool 数组 | ⭐⭐⭐ 最高 |
| **执行 shell 命令** | `bash-tools.exec.ts` → `runExecProcess()` | 封装 child_process | ⭐⭐⭐ 最高 |
| **读写文件** | `pi-tools.read.ts` + `createReadTool/WriteTool` | 封装 fs 模块 | ⭐⭐ 高 |
| **联网搜索** | `tools/web-search.ts` → 调 Brave/DuckDuckGo API | 集成搜索 API | ⭐⭐ 高 |
| **网页抓取** | `tools/web-fetch.ts` | 封装 fetch | ⭐ 中 |
| **系统提示构建** | `pi-embedded-runner/system-prompt.ts` | 为每个 Agent 定制 prompt | ⭐⭐⭐ 最高 |
| **安全沙箱** | `bash-tools.shared.ts` + Docker | V1 先不做，本地受信执行 | ❌ 暂不 |

---

## 三、技术方案：三层架构

```
┌─────────────────────────────────────────────────────────┐
│                     OctoWork 前端（Vue 3）                │
│   ChatArea.vue  ←→  AgentConfig.vue  ←→  TaskBoard.vue   │
└─────────────────────────────┬───────────────────────────┘
                              │ HTTP / WebSocket
┌─────────────────────────────▼───────────────────────────┐
│                   OctoWork 后端（Node + Express）          │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │ ChatRouter   │  │ AgentManager │  │ ModelConfig   │ │
│  │ (对话路由)   │  │ (Agent配置)  │  │ (模型管理)    │ │
│  └──────┬───────┘  └──────────────┘  └───────────────┘ │
│         │                                                │
│  ┌──────▼────────────────────────────────────────────┐  │
│  │              LLM Agent Core（新增模块）             │  │
│  │                                                    │  │
│  │  ① LLM Client    → fetch() 调用 OpenAI/Anthropic  │  │
│  │  ② Tool Registry → 声明工具 schema 给 LLM          │  │
│  │  ③ Tool Executor → 执行 LLM 发回的 tool_call       │  │
│  │  ④ Loop Runner   → 多轮 tool_call 直到 final reply │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
└─────────────────────────────────────────────────────────┘
                              │ 执行层
┌─────────────────────────────▼───────────────────────────┐
│               本地操作系统（工具实际执行位置）              │
│   shell exec  /  fs read+write  /  web search+fetch      │
└─────────────────────────────────────────────────────────┘
```

### 3.1 模块说明

**① LLM Client**  
封装对 LLM API 的调用，支持流式（SSE）输出。  
- 输入：system prompt + messages 历史 + tools schema  
- 输出：text 或 tool_call 事件流  
- 支持提供商：OpenAI、Anthropic Claude、Gemini、本地 Ollama（通过 openai-compat 接口）

**② Tool Registry（工具注册表）**  
以 JSON Schema 格式向 LLM 声明可用工具，告诉 LLM「你能做什么」。  
初期工具清单：

| 工具名 | 功能 | 参数 |
|--------|------|------|
| `exec` | 执行 shell 命令 | `command`, `workdir`, `timeout` |
| `read_file` | 读取文件内容 | `path` |
| `write_file` | 写入文件内容 | `path`, `content` |
| `web_search` | 联网搜索 | `query`, `count` |
| `web_fetch` | 抓取网页内容 | `url` |

**③ Tool Executor（工具执行器）**  
接收 LLM 返回的 `tool_call`，调用对应的本地函数，返回执行结果给 LLM。  
每个工具都是一个独立的 async 函数，有统一的输入/输出接口。

**④ Loop Runner（循环运行器）**  
实现 ReAct 循环：调用 LLM → 若返回 tool_call → 执行工具 → 把结果追加到 messages → 再次调用 LLM → 直到返回 final text 或达到最大轮次。

---

## 四、新增文件结构（仅后端）

```
backend/
├── src/
│   ├── llm-agent/                  ← 新增核心模块
│   │   ├── index.js                ← 对外暴露的入口
│   │   ├── llm-client.js           ← LLM API 调用（OpenAI/Anthropic/Gemini）
│   │   ├── tool-registry.js        ← 工具 schema 注册与管理
│   │   ├── tool-executor.js        ← 工具执行调度器
│   │   ├── loop-runner.js          ← 多轮 tool_call 主循环
│   │   ├── system-prompt.js        ← 根据 Agent 配置生成 system prompt
│   │   └── tools/                  ← 具体工具实现
│   │       ├── exec-tool.js        ← shell 命令执行
│   │       ├── fs-tool.js          ← 文件读写
│   │       ├── web-search-tool.js  ← 联网搜索
│   │       └── web-fetch-tool.js   ← 网页抓取
│   └── controllers/
│       └── botController.js        ← 改造：调用 llm-agent 而非 openclaw CLI
```

---

## 五、核心流程详解

### 5.1 一次完整的 Agent 对话流程

```
用户在 ChatArea 发送消息
        │
        ▼
botController.sendMessage()
        │
        ├── 1. 从 chat.db 加载历史 messages
        ├── 2. 从 Agent 配置加载：model / system_prompt / 工具白名单
        │
        ▼
loop-runner.run(systemPrompt, messages, tools)
        │
        ├── 调用 llm-client.chat()          ← LLM 推理
        │           │
        │           ├── 返回 text           → 直接结束，回复用户
        │           │
        │           └── 返回 tool_calls     → 进入工具执行循环
        │                       │
        │               tool-executor.execute(tool_calls)
        │                       │
        │               ├── exec_tool: child_process.exec()
        │               ├── read_file: fs.readFile()
        │               ├── web_search: 调搜索 API
        │               └── web_fetch: fetch(url)
        │                       │
        │               将 tool_result 追加到 messages
        │                       │
        │               再次调用 llm-client.chat()
        │                       │
        │               循环直到返回 text 或超过 maxTurns
        │
        ▼
保存完整对话到 chat.db
        │
        ▼
通过 WebSocket 推送回前端
```

### 5.2 Agent 配置与 System Prompt 生成

每个 AI 员工（Agent）在 OctoWork 中有如下配置（存于 bot 表）：

```json
{
  "id": "bot_001",
  "name": "研发助理",
  "role": "你是一名资深研发工程师，负责处理代码相关任务",
  "model": "gpt-4o",
  "provider": "openai",
  "allowed_tools": ["exec", "read_file", "write_file", "web_search"],
  "workspace_dir": "/home/user/workspace/project-a",
  "max_turns": 20
}
```

`system-prompt.js` 根据以上配置自动生成 system prompt，注入：
- 角色描述（role）
- 工作目录（workspace_dir）
- 当前时间/日期
- 可用工具说明（从 allowed_tools 过滤）
- 行为约束（禁止删除 workspace 以外的文件等）

---

## 六、安全设计（V1 基础版）

OpenClaw 有完整的 Docker 沙箱，我们 V1 先做基础安全：

| 安全措施 | 实现方式 |
|----------|---------|
| 工具白名单 | 每个 Agent 只能使用 `allowed_tools` 中声明的工具 |
| 工作目录限制 | `exec` 和文件操作只能在 `workspace_dir` 内运行 |
| 命令超时 | 每个 shell 命令强制设 30 秒超时 |
| 危险命令拦截 | 拦截 `rm -rf /`、`sudo` 等高风险指令（黑名单） |
| 输出长度限制 | shell 输出截断到 50KB，防止 token 爆炸 |
| 审计日志 | 每次 tool_call 记录到 tool_executions 表（命令、时间、执行人、结果） |

---

## 七、模型配置管理（在 OctoWork 内）

用户在 OctoWork 设置界面配置模型：

```
设置 → AI 模型配置
├── 添加提供商
│   ├── OpenAI         → API Key + Base URL
│   ├── Anthropic      → API Key
│   ├── Google Gemini  → API Key
│   ├── DeepSeek       → API Key + Base URL
│   ├── Ollama（本地）  → http://localhost:11434
│   └── 自定义（OpenAI 兼容） → Base URL + API Key
│
└── 为每个 Agent 指定默认模型
```

数据库新增 `model_providers` 表：

| 字段 | 说明 |
|------|------|
| id | 主键 |
| user_id | 所属用户 |
| provider | openai / anthropic / google / ollama / custom |
| display_name | 显示名称 |
| api_key | 加密存储 |
| base_url | 自定义 endpoint |
| models | 该提供商支持的模型列表（JSON） |
| is_default | 是否为默认提供商 |

---

## 八、前端改动（最小化）

前端不需要大改，主要调整：

1. **ChatArea.vue**  
   - 支持显示 `tool_call` 状态（"正在执行：exec ls -la..."）  
   - 支持显示工具执行结果的折叠展示（类似代码块）  
   - 支持流式输出（SSE）

2. **Bot 配置页面（DashboardView 或独立页面）**  
   - 新增「工具权限」设置（勾选允许哪些工具）  
   - 新增「工作目录」设置  
   - 新增「模型选择」下拉框  

3. **设置页面**  
   - 新增「AI 模型配置」模块（添加/编辑/删除提供商）

---

## 九、数据库变更（最小化）

在现有 `chat.db` 基础上新增：

```sql
-- 模型提供商配置
CREATE TABLE model_providers (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,         -- openai/anthropic/google/ollama/custom
  display_name TEXT NOT NULL,
  api_key TEXT,                   -- AES-256 加密存储
  base_url TEXT,
  models JSON,                    -- ["gpt-4o","gpt-4o-mini",...]
  is_default BOOLEAN DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 工具执行审计日志
CREATE TABLE tool_executions (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  bot_id TEXT NOT NULL,
  tool_name TEXT NOT NULL,        -- exec/read_file/web_search/...
  tool_input JSON NOT NULL,       -- 工具参数
  tool_output TEXT,               -- 执行结果（截断到50KB）
  exit_code INTEGER,              -- shell命令退出码
  duration_ms INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Bot 表扩展字段（ALTER TABLE）
ALTER TABLE bots ADD COLUMN allowed_tools JSON DEFAULT '["exec","read_file","write_file","web_search","web_fetch"]';
ALTER TABLE bots ADD COLUMN workspace_dir TEXT;
ALTER TABLE bots ADD COLUMN max_turns INTEGER DEFAULT 20;
ALTER TABLE bots ADD COLUMN model_provider_id TEXT;
ALTER TABLE bots ADD COLUMN model_id TEXT;
```

---

## 十、开发计划（分阶段交付）

### Phase 1：核心 LLM + 工具执行（目标：1周）

**目标**：AI 员工能调用 `exec` 执行 shell 命令、能读写文件。

| 任务 | 负责 | 工时 |
|------|------|------|
| 实现 `llm-client.js`（支持 OpenAI + Anthropic） | 后端 | 1天 |
| 实现 `tool-registry.js` + `loop-runner.js` | 后端 | 1天 |
| 实现 `exec-tool.js`（child_process 封装） | 后端 | 0.5天 |
| 实现 `fs-tool.js`（read/write） | 后端 | 0.5天 |
| 改造 `botController.js` 使用新模块 | 后端 | 0.5天 |
| 前端 ChatArea 显示 tool_call 状态 | 前端 | 0.5天 |
| 数据库迁移脚本 | 后端 | 0.5天 |
| 集成测试（对话→工具调用→结果返回） | 全栈 | 1天 |

### Phase 2：模型配置 UI + 搜索工具（目标：+3天）

| 任务 | 负责 | 工时 |
|------|------|------|
| 后端模型提供商 CRUD API | 后端 | 1天 |
| 前端「AI 模型配置」设置页 | 前端 | 1天 |
| 实现 `web-search-tool.js`（集成 DuckDuckGo/Brave API） | 后端 | 0.5天 |
| 实现 `web-fetch-tool.js` | 后端 | 0.5天 |

### Phase 3：Agent 工具权限管理 + 安全加固（目标：+3天）

| 任务 | 负责 | 工时 |
|------|------|------|
| Bot 配置页面添加工具权限/工作目录设置 | 前端 | 1天 |
| 危险命令拦截规则 | 后端 | 0.5天 |
| 工具执行审计日志 + 前端展示 | 全栈 | 1天 |
| Ollama 本地模型支持 | 后端 | 0.5天 |

---

## 十一、与 OpenClaw 的功能对比（V1 完成后）

| 功能 | OpenClaw | OctoWork V1 |
|------|----------|-------------|
| 调用 LLM | ✅ | ✅ |
| 执行 shell 命令 | ✅（Docker 沙箱） | ✅（本地，受限路径） |
| 读写文件 | ✅ | ✅ |
| 联网搜索 | ✅ | ✅ |
| 网页抓取 | ✅ | ✅ |
| 多模型支持 | ✅（30+ 提供商） | ✅（5 大主流提供商） |
| Agent 管理 UI | ❌（命令行配置） | ✅（可视化界面） |
| 部门/团队管理 | ❌ | ✅ |
| 任务看板 | ❌ | ✅ |
| 独立安装，无依赖 | ❌（需安装 OC） | ✅ |
| Docker 安全沙箱 | ✅ | ❌（V2 规划） |
| 记忆/Embedding | ✅ | ❌（V2 规划） |
| 消息平台集成 | ✅（20+） | ❌（不做） |

---

## 十二、关键技术决策说明

### 为什么不用 `@mariozechner/pi-agent-core`？

OpenClaw 的底层 Agent 运行时是 `@mariozechner/pi-agent-core`（v0.65.2），理论上可以直接引用。但：

1. 它是 TypeScript ESM 包，而我们后端是 CommonJS  
2. 它有大量内部状态和复杂依赖链  
3. 我们只需要「多轮 tool_call 循环」这一个核心能力，自己写不超过 200 行代码  
4. 自己写意味着完全可控，未来可以定制

**结论：自己实现 Loop Runner，参考 pi-agent-core 的设计思路即可。**

### 为什么不嵌入 OpenClaw 进程？

嵌入 OpenClaw 作为子进程意味着：
- 用户还是要安装 Node 22+、OpenClaw 依赖
- 进程间通信复杂
- 我们丧失对 LLM 调用的完整控制权（无法定制日志、错误处理、计费统计）

**结论：完全自己实现，保持最高控制权。**

---

## 十三、商业化考量

1. **用户门槛降低**：只安装一个 OctoWork，即可获得完整 AI 工具能力。对比之前需要安装 OpenClaw，安装成功率预计提升 60%+。

2. **模型计费接入**：我们掌握所有 LLM API 调用，可以在未来接入 Token 用量统计，为 SaaS 付费或企业版按量计费奠定基础。

3. **工具市场**：工具注册表（Tool Registry）天然是一个扩展点，未来可以让用户/第三方上传自定义工具（类似 OpenClaw 的插件系统），形成工具市场生态。

4. **Agent 模板**：预置多种行业 Agent 模板（研发助理、数据分析师、客服机器人），降低用户配置门槛，同时也是产品差异化卖点。

---

## 附录：参考的 OpenClaw 关键源文件

| 文件 | 我们参考的内容 |
|------|--------------|
| `src/agents/pi-embedded-runner/run.ts` | 多轮 tool_call 循环逻辑 |
| `src/agents/pi-embedded-runner/system-prompt.ts` | System prompt 构建策略 |
| `src/agents/bash-tools.exec.ts` | shell 命令执行安全处理 |
| `src/agents/tools/web-search.ts` | 搜索工具实现参考 |
| `src/agents/tools/web-fetch.ts` | 网页抓取实现参考 |
| `src/agents/pi-tools.ts` | 工具注册与 schema 声明 |
| `src/config/types.agents.ts` | Agent 配置字段设计参考 |
| `src/agents/defaults.ts` | 默认模型、token 限制参考 |

---

*本草案为 V0.1，待团队确认方向后进入详细技术设计阶段。*
