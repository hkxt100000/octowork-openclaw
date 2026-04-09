# Sage - 老Bot聊天管理器 - 项目开发文档

> **文档用途**：任何人（包括我自己）看完这份文档，就能完整了解项目、独立安装启动、排查问题、进行开发  
> **更新时间**：2026-03-09 02:25 GMT+8  
> **更新人员**：Hannah (Bot聊天管理器技术管家)  
> **文档位置**：`/Users/jason/.openclaw/workspace/OctoWork/projects/Sage 老Bot聊天管理器 项目开发文档.md`  
> **维护规则**：Bot聊天管理器的任何重要功能更新或架构变更都必须更新本文档，确保团队思想统一

---

## 📌 项目概述

### 项目定位
**老Bot聊天管理器 = Jason内部使用的AI团队管理工具**

- **用户**：Jason + 15个AI Agent（Jack、Hannah、Edward等）
- **用途**：管理AI团队的聊天、任务、文件、协作
- **技术栈**：Vue 3 + Node.js + SQLite + WebSocket + OpenClaw
- **状态**：✅ Web版已完成，功能完整，可正常使用

### 项目位置
```
/Users/jason/.openclaw/workspace/OctoWork/projects/bot-chat-manager/
├── frontend/           # Vue 3前端
├── backend/            # Node.js后端
├── config.json         # 核心配置文件
├── START.sh            # 一键启动脚本
└── 数据库位置：backend/data/chat.db
```

---

## ✅ 当前已完成功能（2026-03-09）

### 1️⃣ 核心聊天功能
- ✅ **1对1聊天**：与任意Bot实时对话
- ✅ **群聊功能**：创建群组，@成员协作
- ✅ **消息历史**：自动保存所有聊天记录（SQLite）
- ✅ **Bot列表分组显示**（2026-03-07新增）：
  - 🕐 **最近聊天**：显示最近3个聊过天的Bot，按时间排序
  - 👥 **默认团队**：显示所有16个初始成员，按名称排序
  - ⏳ 未来扩展：单个成员组、团队包组（为市场化预留）
- ✅ **未读消息**：红色角标 + 脉动动画，点击清除

### 2️⃣ UI/UX（GenSpark风格）
- ✅ **左侧导航**：7个一级菜单（首页、聊天、群聊、任务、企微、市场、数据、设置）
- ✅ **Bot卡片式列表**：头像 + 名称 + 最后消息 + 时间 + 未读角标
- ✅ **毛玻璃效果**：导航栏半透明背景 + 模糊效果
- ✅ **现代输入框**：圆角卡片 + 自适应高度 + 模型标签

### 3️⃣ 实时推送系统
- ✅ **WebSocket推送**：Bot回复实时显示（延迟<100ms）
- ✅ **心跳检测**：自动重连机制
- ✅ **三重保障**：
  1. WebSocket实时推送
  2. Webhook保底推送（WebSocket失败时）
  3. 自动对账补录（30秒扫描outbox）

### 4️⃣ 任务监控系统
- ✅ **任务状态跟踪**：运行中/等待/完成/失败
- ✅ **实时进度条**：显示Bot处理进度
- ✅ **任务耗时统计**：显示执行时长
- ✅ **TODO清单识别**：自动识别`[x]` `[ ]` `[~]`格式

### 5️⃣ 文件管理
- ✅ **多层级文件夹**：最多10层目录
- ✅ **层级缩进**：每级16px缩进
- ✅ **Hover动画**：右移4px + 阴影加深

### 6️⃣ 数据统计
- ✅ **消息统计**：总消息数、今日消息数
- ✅ **Bot统计**：团队成员数量
- ✅ **任务统计**：待处理/进行中/已完成

### 7️⃣ 多环境支持
- ✅ **本地Bot**（`ai-brain-*`）：通过OpenClaw API实时通信
- ✅ **远程Bot**（`crm-*`）：通过文件系统队列异步通信
- ✅ **自动环境识别**：根据Bot ID前缀自动切换通信方式

### 8️⃣ Bot加载机制
- ✅ **固定配置模式**（当前使用）：
  - 手动维护 `config.json` 中的Bot列表
  - 适合内部固定团队，精确控制每个Bot信息
  - 支持部门分组、自定义头像、角色描述
- ✅ **自动扫描模式**（已实现并启用）：
  - 扫描 `departments/ai-brain/agents/` 目录
  - 读取每个Bot的 `IDENTITY.md` 配置文件（解析姓名、职务、编号等信息）
  - 适合内部团队管理，自动发现新Bot成员
  - 当前使用：混合模式（固定核心Bot配置 + 自动扫描补充）

### 9️⃣ PWA支持
- ✅ **添加到主屏幕**：iOS/Android可作为独立App使用
- ✅ **离线访问**：基础功能离线可用
- ⏸️ **推送通知**：技术已实现，未开启

---

## ✅ 重要更新（2026-03-09）

### 🔧 稳定性与用户体验优化

#### 1️⃣ 重复消息检测与防重机制
- ✅ **5秒窗口去重**：后端内存缓存，5秒内相同内容自动跳过
- ✅ **单机环境优化**：适合每个用户单机部署场景，重启服务缓存重置
- ✅ **前后端兼容**：前端无需修改，后端返回 `isDuplicate: true` 标记
- ✅ **全面覆盖**：支持普通聊天和群聊两种场景
- ✅ **修复Bug**：解决WebSocket重连、前端快速点击导致的重复消息问题

#### 2️⃣ Shift+Enter换行功能
- ✅ **输入体验优化**：`Shift+Enter`换行，`Enter`单独发送消息
- ✅ **双场景支持**：普通聊天输入框和群聊输入框都实现
- ✅ **自然交互**：Vue el-textarea自动处理，光标位置正确保持
- ✅ **Mention兼容**：群聊@mention建议导航与换行功能完美兼容

#### 3️⃣ 四列布局调整实施
- ✅ **布局优化**：第3列（聊天区域）固定700px宽度，第4列（工作台）自适应100%
- ✅ **智能切换**：选中Bot时显示四列布局，未选中时显示三列布局（类似群聊界面）
- ✅ **CSS实现**：通过 `.dual-sidebar.four-columns` 和 `.dual-sidebar.three-columns` 类动态切换
- ✅ **用户反馈集成**：根据实际使用反馈调整布局，提升工作效率

#### 4️⃣ 前端模块化重构完成
- ✅ **代码结构优化**：App.vue从6389行减少到约50行
- ✅ **AI Token节省**：估计减少75%的Token消耗
- ✅ **模块化架构**：创建 `src/views/`、`src/layouts/`、`src/stores/`、`src/router/`、`src/components/chat/` 等目录
- ✅ **TypeScript强化**：解决类型错误，添加 `shims-vue.d.ts` 类型声明
- ✅ **开发规范建立**：创建详细开发规范文档和模块结构文档

#### 5️⃣ 团队协作与Git管理
- ✅ **本地更改推送**：将所有本地修复和优化推送到OctoWork仓库的development分支
- ✅ **批量提交**：包含Bot聊天管理器修复、界面优化、OpenViking自动化部署、文件清理
- ✅ **文件变动**：933个文件，+129,870行/-33,309行，大规模清理冗余文件
- ✅ **自动化部署**：OpenViking V2.0自动化系统部署到所有16个bot公寓

#### 6️⃣ SOUL.md标准化
- ✅ **格式统一**：Hannah和Jack的SOUL.md完全按照Jack格式重写
- ✅ **聊天模式集成**：将Bot聊天管理器的6种聊天模式识别规则集成到SOUL.md中
- ✅ **团队一致性**：确保所有Bot团队成员遵循相同的交互规则和格式标准

### 🎯 技术实现细节

#### 重复消息检测实现
```javascript
// 后端server.js中的关键代码
const duplicateCache = new Map()
const DUPLICATE_WINDOW_MS = 5000 // 5秒窗口

// 消息处理逻辑
const cacheKey = `${botId}:${content}`
const lastTime = duplicateCache.get(cacheKey)
if (lastTime && Date.now() - lastTime < DUPLICATE_WINDOW_MS) {
  console.log(`🔄 检测到重复消息，跳过处理`)
  return res.json({ success: true, isDuplicate: true })
}
duplicateCache.set(cacheKey, Date.now())
```

#### 布局CSS实现
```css
/* 四列布局：固定宽度聊天区域 + 自适应工作台 */
.dual-sidebar.four-columns .chat-area {
  width: 700px;
  min-width: 700px;
  max-width: 700px;
  flex: none !important;
}

.dual-sidebar.four-columns .workspace-panel {
  flex: 1;
  min-width: 0; /* 允许缩小 */
  overflow: hidden;
}

/* 三列布局：聊天区域自适应100% */
.dual-sidebar.three-columns .chat-area {
  flex: 1;
  width: auto;
  min-width: auto;
  max-width: none;
}

.dual-sidebar.three-columns .workspace-panel {
  display: none;
}
```

#### 动态布局切换
```vue
<!-- App.vue根元素 -->
<div class="bot-chat-manager dual-sidebar" :class="selectedBot ? 'four-columns' : 'three-columns'">
```

---

## 🚀 V2.0规划：四栏工作驾驶舱（2026-03-07设计）

### 核心理念
**Bot聊天管理器 ≠ 传统聊天工具，而是"工作驾驶舱"**

传统聊天工具只显示文字对话，但Bot的实际工作成果（文档、脚本、图片、视频）都藏在文字里，不直观。
V2.0设计目标：**让Bot的工作成果可见化、可操作化**

### 四栏布局设计 (2026-03-09已部分实现)

```
┌─────┬─────────────┬──────────────────┬────────────────────┐
│导航 │  Bot列表    │   聊天区域       │  工作台            │
│80px │  240px      │   700px固定      │  自适应100%        │
├─────┼─────────────┼──────────────────┼────────────────────┤
│🏠首页│ 👤 Jack     │ 💬 对话框        │ 📁 文件树          │
│💬聊天│ 👤 Alice    │ ┌──────────────┐│ ├─ 📄 docs (3)    │
│👥群聊│ 👤 Bob      │ │用户：写个文档││ ├─ 💻 tools (2)   │
│📋任务│ 👤 Diana    │ │Jack：完成了  ││ ├─ 📊 outputs (5) │
│👔企微│             │ └──────────────┘│ └─ 📝 tasks (12)  │
│🛒市场│             │                  │                    │
│📊数据│             │ ⚡ 6种模式       │ 👁️ 预览区         │
│⚙️设置│             │ 🗣️💬📋⚙️🧠⚡    │ ┌────────────────┐│
│      │             │                  │ │ 📄 API.md      ││
│      │             │ 📝 输入框        │ │ [Markdown预览] ││
│      │             │ [询问问题...]    │ │ [🔍 独立窗口]  ││
│      │             │                  │ └────────────────┘│
└─────┴─────────────┴──────────────────┴────────────────────┘
```

**实际实现状态** (2026-03-09):
- ✅ **布局结构**: 四列布局已实现，支持三列/四列智能切换
- ✅ **尺寸调整**: 聊天区域固定700px，工作台自适应100%
- ✅ **动态切换**: `selectedBot ? 'four-columns' : 'three-columns'`
- ⏸️ **工作台功能**: 界面框架已搭建，具体功能待实现
- ⏸️ **文件树/预览**: 预留界面，功能开发中

### 第四栏：工作台详细设计

#### Tab设计（2个Tab切换）

```
┌────────────────────────────────────┐
│ 📁 文件树  |  👁️ 预览             │ ← Tab切换栏
├────────────────────────────────────┤
│                                    │
│   【根据选中Tab显示对应内容】      │
│                                    │
│   Tab1: 文件树列表                 │
│   Tab2: 文件预览区（含4个按钮）    │
│                                    │
└────────────────────────────────────┘
```

---

#### Tab 1: 📁 文件树

```
📁 Hannah 的工作空间
├─ 📄 docs (3)               ← 文档类文件
│  ├─ API设计文档.md    [今天 14:23] 
│  ├─ 数据库方案.md      [今天 10:15]
│  └─ 部署指南.md         [昨天 18:30]
├─ 💻 tools (2)              ← 代码脚本
│  ├─ deploy.py          [今天 14:30]
│  └─ check_status.sh    [今天 09:00]
├─ 📊 outputs (5)            ← 图片视频
│  ├─ 数据分析.png        [今天 16:00]
│  ├─ 流程图.svg          [昨天 20:10]
│  └─ 演示视频.mp4        [2天前]
└─ 📝 task_box (12)          ← 任务清单
   ├─ ✅ 已完成 (8)
   └─ ⏳ 进行中 (4)

特性：
- 按类型分组（docs/tools/outputs/tasks）
- 显示文件数量 + 最后修改时间
- 点击文件 → **自动切换到"预览"Tab** + 显示文件内容
- 右键菜单：下载/删除/重命名
```

---

#### Tab 2: 👁️ 预览区

**顶部操作栏（4个按钮）**：
```
┌────────────────────────────────────┐
│ 预览 | 源码 | 📋 复制 | 🔲 独立窗口 │ ← 操作按钮
├────────────────────────────────────┤
│                                    │
│   【文件内容显示区】                │
│   根据文件类型动态切换渲染方式      │
│                                    │
└────────────────────────────────────┘
```

**按钮功能**：
1. **预览**：渲染后效果（Markdown→HTML / 图片→img / 视频→player）
2. **源码**：显示原始文本/代码
3. **复制**：一键复制内容到剪贴板
4. **独立窗口**：弹出大窗口查看

---

#### 预览区内容样式（根据文件类型）

**Markdown文件预览**：
```
┌────────────────────────────────────┐
│ 预览 | 源码 | 📋 复制 | 🔲 独立窗口 │
├────────────────────────────────────┤
│ # API设计文档                      │
│                                    │
│ ## 1. 用户接口                     │
│ POST /api/users                    │
│ - 参数: name, email                │
│                                    │
│ [Markdown渲染预览，可滚动]         │
└────────────────────────────────────┘
```

**代码文件预览**：
```
┌────────────────────────────────────┐
│ 预览 | 源码 | 📋 复制 | 🔲 独立窗口 │
├────────────────────────────────────┤
│  1  import os                      │
│  2  import sys                     │
│  3                                 │
│  4  def deploy():                  │
│  5      print("部署中...")         │
│                                    │
│ [语法高亮 + 行号显示，可滚动]      │
└────────────────────────────────────┘
```

**图片文件预览**：
```
┌────────────────────────────────────┐
│ 预览 | 源码 | 📋 复制 | 🔲 独立窗口 │
├────────────────────────────────────┤
│                                    │
│      [图片居中显示]                │
│                                    │
│ 📐 1920x1080  💾 2.3MB            │
└────────────────────────────────────┘
```

**视频文件预览**：
```
┌────────────────────────────────────┐
│ 预览 | 源码 | 📋 复制 | 🔲 独立窗口 │
├────────────────────────────────────┤
│                                    │
│   [视频播放器 + 进度条]            │
│                                    │
│ ⏱️ 03:25  💾 15.8MB               │
└────────────────────────────────────┘
```

---

#### 核心交互流程

**场景1：Bot推送文件 → 用户点击查看**（主流程）
```
1. Bot在聊天框发送：
   "✅ 方案已完成：documents/产品分析方案.md"
   
2. 用户点击文件链接 "产品分析方案.md"

3. 第四栏 **自动切换到"预览"Tab**

4. 显示文件内容（根据类型渲染）

5. 用户可点击"源码/复制/独立窗口"切换查看方式
```

**场景2：用户主动浏览文件**
```
1. 用户点击第四栏 "📁 文件树" Tab

2. 在文件树中找到目标文件

3. 点击文件名

4. **自动切换到"预览"Tab** + 显示文件内容
```

**关键特性**：
- ✅ 点击任何文件链接 → **自动切预览Tab**（用户无需手动切换）
- ✅ 预览Tab始终显示"最后点击的那个文件"
- ✅ 文件树Tab仅用于"浏览目录结构"
- ✅ 类似GenSpark的交互逻辑（点击文件→右侧自动显示）

---

#### 独立弹窗查看器

**点击[🔍 独立窗口]后打开：**
```
[半透明黑色遮罩]
    ┌─────────────────────────────────┐
    │ 📄 API设计.md    [—][□][✕]     │
    ├─────────────────────────────────┤
    │                                 │
    │   [完整内容显示]                │
    │   - 宽度: 80vw                  │
    │   - 高度: 80vh                  │
    │   - 可拖拽调整大小              │
    │   - 可滚动查看完整内容          │
    │   - Markdown可编辑              │
    │   - 代码可高亮+复制             │
    │   - 图片可缩放                  │
    │   - 视频可播放                  │
    │                                 │
    │ [📥 下载][📋 复制][✏️ 编辑][⛶ 全屏]│
    └─────────────────────────────────┘

交互：
- ESC键关闭
- F11全屏显示
- 支持拖拽调整大小
- 支持鼠标滚轮缩放（图片）
```

### 空间布局方案

#### 方案A：固定宽度（推荐）
```
导航：60px（纯图标）
列表：250px（固定）
聊天：flex: 1（自适应，最小600px）
工作台：400px（可拖拽调整 300-600px）

总宽度要求：≥1310px（推荐1920px）
```

#### 方案B：可折叠
```
工作台默认展开，点击右上角[折叠]按钮：
- 折叠后只显示一个30px的侧边栏
- 鼠标悬停显示文件列表
- 点击展开恢复

优点：节省空间
缺点：多一步交互
```

#### 方案C：智能显示（推荐）
```
无文件时：工作台自动隐藏
有文件时：工作台自动展开
用户可手动控制：展开/折叠

优点：最佳用户体验
实现：通过状态管理自动切换
```

### 技术实现要点

#### 前端组件设计
```
src/components/
├── Workspace/
│   ├── WorkspacePanel.vue       # 工作台主容器（含Tab切换）
│   ├── FileTreeTab.vue          # Tab1: 文件树组件
│   ├── PreviewTab.vue           # Tab2: 预览区容器
│   ├── previews/
│   │   ├── MarkdownPreview.vue  # Markdown预览
│   │   ├── CodePreview.vue      # 代码预览
│   │   ├── ImagePreview.vue     # 图片预览
│   │   ├── VideoPreview.vue     # 视频预览
│   │   └── TaskPreview.vue      # 任务清单预览
│   └── modals/
│       ├── FileModal.vue        # 独立弹窗容器
│       └── FullscreenViewer.vue # 全屏查看器
```

**WorkspacePanel.vue 核心逻辑**：
```vue
<template>
  <div class="workspace-panel">
    <!-- Tab切换栏 -->
    <div class="tabs">
      <div :class="['tab', {active: currentTab === 'tree'}]" 
           @click="currentTab = 'tree'">
        📁 文件树
      </div>
      <div :class="['tab', {active: currentTab === 'preview'}]" 
           @click="currentTab = 'preview'">
        👁️ 预览
      </div>
    </div>
    
    <!-- Tab内容区 -->
    <div class="tab-content">
      <FileTreeTab v-show="currentTab === 'tree'" 
                   @file-click="handleFileClick" />
      <PreviewTab v-show="currentTab === 'preview'" 
                  :file="selectedFile" />
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const currentTab = ref('tree')  // 默认显示文件树
const selectedFile = ref(null)

// 关键逻辑：点击文件 → 自动切到预览Tab
const handleFileClick = (file) => {
  selectedFile.value = file
  currentTab.value = 'preview'  // 自动切换到预览Tab
}
</script>
```

#### 后端API设计
```
文件管理API：
GET  /api/bot/:botId/files           # 获取Bot的文件列表
GET  /api/bot/:botId/files/tree      # 获取文件树结构
GET  /api/files/:fileId              # 获取文件内容
GET  /api/files/:fileId/preview      # 获取文件预览（图片缩略图等）
GET  /api/files/:fileId/download     # 下载文件
POST /api/files/:fileId/update       # 更新文件内容（编辑后保存）
DELETE /api/files/:fileId            # 删除文件

响应格式示例：
{
  "success": true,
  "data": {
    "tree": {
      "docs": [
        {
          "id": "file_001",
          "name": "API设计.md",
          "type": "markdown",
          "size": 15360,
          "created_at": "2026-03-07 14:23:00",
          "updated_at": "2026-03-07 14:23:00"
        }
      ],
      "tools": [],
      "outputs": [],
      "tasks": []
    }
  }
}
```

#### 状态管理设计
```javascript
// stores/workspace.js
export const useWorkspaceStore = defineStore('workspace', {
  state: () => ({
    visible: false,          // 工作台是否显示
    width: 400,              // 工作台宽度（可调整）
    currentTab: 'tree',      // 当前Tab：'tree' | 'preview'
    selectedFile: null,      // 当前选中的文件
    files: [],               // 文件列表
    fileTree: {},            // 文件树结构
    modalVisible: false,     // 独立弹窗是否显示
    modalFile: null,         // 弹窗显示的文件
  }),
  
  actions: {
    async loadFiles(botId) {
      const res = await axios.get(`/api/bot/${botId}/files/tree`)
      this.fileTree = res.data.data.tree
      this.visible = Object.keys(this.fileTree).some(key => this.fileTree[key].length > 0)
    },
    
    // 关键方法：选中文件 + 自动切到预览Tab
    selectFile(file) {
      this.selectedFile = file
      this.currentTab = 'preview'  // 自动切换到预览Tab
    },
    
    // 从聊天消息点击文件链接
    selectFileFromChat(filePath) {
      const file = this.findFileByPath(filePath)
      if (file) {
        this.selectFile(file)
      }
    },
    
    openModal(file) {
      this.modalFile = file
      this.modalVisible = true
    },
    
    closeModal() {
      this.modalVisible = false
      this.modalFile = null
    }
  }
})
```

### 开发计划

#### Phase 1：基础布局 + Tab切换（1-2天）
- [ ] 实现四栏布局结构
- [ ] 第四栏：WorkspacePanel主容器
- [ ] Tab切换栏（文件树 | 预览）
- [ ] Tab内容区（v-show切换）
- [ ] 工作台可拖拽调整宽度
- [ ] 工作台可折叠/展开
- [ ] 响应式适配（最小宽度1310px）

#### Phase 2：文件树Tab（2-3天）
- [ ] FileTreeTab组件开发
- [ ] 按类型分组显示（docs/tools/outputs/tasks）
- [ ] 文件图标识别（根据扩展名）
- [ ] 时间戳显示（相对时间：今天/昨天/X天前）
- [ ] 点击文件 → 触发 `@file-click` 事件
- [ ] 右键菜单：下载/删除/重命名

#### Phase 3：预览Tab（3-4天）
- [ ] PreviewTab容器组件
- [ ] 顶部操作栏（4个按钮：预览|源码|复制|独立窗口）
- [ ] Markdown预览组件（markdown-it + highlight.js）
- [ ] 代码高亮预览组件（highlight.js）
- [ ] 图片预览组件（img + 缩放）
- [ ] 视频预览组件（video标签 + 进度条）
- [ ] 任务清单预览组件（TODO识别）

#### Phase 4：核心交互逻辑（1天）
- [ ] 文件树点击 → 自动切到预览Tab
- [ ] 聊天消息文件链接 → 自动切到预览Tab
- [ ] 预览Tab显示"最后点击的文件"
- [ ] 空状态提示（无文件时显示引导）

#### Phase 5：独立弹窗（2-3天）
- [ ] FileModal弹窗容器组件
- [ ] 拖拽调整大小
- [ ] 全屏显示模式
- [ ] 快捷键支持（ESC关闭/F11全屏）
- [ ] 编辑保存功能（Markdown）

#### Phase 6：后端API（2天）
- [ ] 文件列表API：`GET /api/bot/:botId/files`
- [ ] 文件树API：`GET /api/bot/:botId/files/tree`
- [ ] 文件内容获取API：`GET /api/files/:fileId`
- [ ] 文件预览API：`GET /api/files/:fileId/preview`
- [ ] 文件下载API：`GET /api/files/:fileId/download`
- [ ] 文件更新API：`POST /api/files/:fileId/update`
- [ ] WebSocket文件变化推送

#### Phase 7：联调优化（2-3天）
- [ ] 前后端联调
- [ ] 文件树实时更新（WebSocket推送）
- [ ] 性能优化（虚拟滚动）
- [ ] 交互优化（加载动画/错误提示）
- [ ] Bug修复
- [ ] 文档完善

**总预计工期：13-18天**

### 预期效果

#### 用户体验提升
- ✅ **可见化**：Bot的工作成果直观展示
- ✅ **可操作化**：可预览、下载、编辑、运行
- ✅ **专业化**：像真正的工作台，不是聊天工具
- ✅ **高效化**：快速访问Bot生成的文件

#### 适用场景
1. **文档协作**：Bot生成设计文档→用户预览→编辑修改→保存
2. **代码生成**：Bot生成脚本→用户查看代码→复制使用→直接运行
3. **数据分析**：Bot生成图表→用户查看大图→下载保存
4. **任务管理**：Bot更新任务→用户查看进度→勾选完成

---

## ⚠️ 占位功能（仅有界面，无实际功能）

| 菜单 | 状态 | 说明 |
|------|------|------|
| 🏠 首页 | ⚠️占位 | 显示"功能开发中" |
| 👔 企微CRM | ⚠️占位 | 预留商业化功能（核心） |
| 🛒 数字人市场 | ⚠️占位 | 预留商业化功能 |

---

## 📜 重要历史决策

### ❌ 已否决的方案

#### Bot分组管理（2026-03-02否决）
- **原设计**：最近聊天 / AI智囊团 / Mac技术部 等固定分组
- **否决原因**：
  - 固定分组不够灵活
  - 按时间排序更符合使用习惯（参考微信/企业微信）
- **当前方案**：按最后消息时间自动排序
- **未来可能**：标签系统、收藏功能

---

## ⏸️ 待完善功能（讨论中）

### 1. Bot主动消息推送
**现状**：Bot只能被动回复，无法主动发消息  
**方案**：
- 方案A：轮询Outbox（简单，有10秒延迟）
- 方案B：Webhook（推荐，实时推送）⭐
- 方案C：SSE长连接（复杂，维护成本高）

**决策**：等Jason确认使用场景后再实现

---

### 2. 任务拆解功能
**用户需求**：聊天中交代的工作，能自动/手动拆解成可追踪的任务清单  
**示例**：
```
Jason对Jack说："帮我做竞品分析报告"
  ↓
系统自动拆解成：
✅ 任务1：收集竞品资料（进行中...）
✅ 任务2：分析优劣势（等待中）
✅ 任务3：撰写报告（等待中）
✅ 任务4：生成PPT（等待中）
```

**待讨论**：
- 谁来拆解？Bot自己？用户手动？AI自动识别？
- 任务颗粒度？
- 进度如何更新？

**决策**：暂停讨论，Jason需要时间理清思路

---

## 🔧 技术架构

### 前端架构
```
Vue 3 + TypeScript
├── 状态管理：Pinia + Ref + Reactive（模块化架构）
├── UI库：Element Plus
├── 通信：WebSocket + Axios
├── 图表：ECharts
└── 样式：GenSpark风格（毛玻璃 + 卡片式）
```

### 后端架构
```
Node.js + Express
├── 数据库：SQLite（存储在 backend/data/chat.db）
├── 实时推送：WebSocket（ws库）
├── 消息队列：内存 + 文件系统
├── OpenClaw集成：通过CLI调用
└── 对账服务：30秒扫描outbox
```

### 数据流
```
用户发送消息
  ↓
后端API → OpenClaw CLI → Bot处理 → 返回回复
  ↓
保存数据库 + 写入outbox
  ↓
WebSocket推送 → 前端实时显示
  ↓（失败）
Webhook保底推送
  ↓（仍失败）
30秒后对账补录
```

---

## 📂 核心文件位置

### 项目目录结构
```
bot-chat-manager/
├── config.json             # 核心配置文件（OpenClaw API、Bot列表、端口）
├── START.sh                # 一键启动脚本（推荐）
├── frontend/               # Vue 3前端
│   ├── src/
│   │   ├── renderer/
│   │   │   ├── App.vue     # 主界面（约50行，模块化架构）
│   │   │   ├── main.ts
│   │   │   └── router.ts
│   │   ├── views/          # 页面视图组件
│   │   ├── layouts/        # 布局组件
│   │   ├── stores/         # Pinia状态管理
│   │   ├── router/         # 路由配置
│   │   └── components/     # 通用组件
│   │   ├── components/
│   │   │   ├── FileExplorer.vue     # 文件浏览器
│   │   │   └── MarkdownViewer.vue   # Markdown查看器
│   │   └── main/           # Electron主进程
│   ├── package.json
│   └── vite.config.ts
└── backend/                # Node.js后端
    ├── server.js           # 主服务（46K，1300+行）
    ├── start_smart.js      # 智能启动脚本
    ├── api/
    │   └── openclaw.js     # OpenClaw客户端
    ├── db/
    │   └── database.js     # 数据库操作
    ├── services/
    │   ├── task-monitor.js           # 任务监控服务
    │   └── message-reconciliation.js  # 消息对账服务
    ├── utils/
    │   ├── outbox-writer.js  # Outbox写入工具
    │   └── webhook.js        # Webhook工具
    ├── websocket/
    │   └── manager.js        # WebSocket管理器
    ├── data/
    │   └── chat.db           # SQLite数据库（自动创建）
    └── package.json
```

### 数据库表结构
```
backend/data/chat.db

主要表：
├── messages          # 消息记录（id, bot_id, sender, content, timestamp）
├── group_messages    # 群聊消息
├── groups            # 群组信息
├── group_members     # 群组成员
└── task_monitor      # 任务监控（暂未实现持久化）
```

---

## 🚀 首次安装与启动

### 前置要求
- **Node.js**: >= 16.0
- **npm**: >= 8.0
- **OpenClaw**: 已安装并配置（`openclaw --version` 可用）
- **系统**: macOS / Linux

### 首次安装步骤
```bash
# 1. 安装后端依赖
cd /Users/jason/.openclaw/workspace/OctoWork/projects/bot-chat-manager/backend
npm install

# 2. 安装前端依赖
cd ../frontend
npm install

# 3. 配置OpenClaw连接
cd ..
cp config.example.json config.json  # 如果没有config.json
# 编辑 config.json，填写OpenClaw API地址和Token

# 4. 首次启动
./START.sh
```

### 配置文件说明（config.json）
```json
{
  "openclaw": {
    "api_url": "http://localhost:18789",  // OpenClaw API地址
    "token": "your-token-here",           // OpenClaw API Token
    "timeout": 30000
  },
  "server": {
    "port": 6726,                          // 后端服务端口（默认6726）
    "host": "localhost"
  },
  "bots": [                                // Bot列表（固定配置模式）
    {
      "id": "ai-brain-commander-jack",
      "custom_name": "Jack",
      "role": "总指挥官",
      "department": "管理组",
      "environment": "local",
      "avatar": "https://...",
      "department_path": "departments/ai-brain/agents/..."
    }
  ],
  "database": {
    "path": "data/chat.db"                 // 数据库文件路径（相对backend/）
  }
}
```

### 日常启动方式

#### 方式1：一键启动（推荐）✅
```bash
cd /Users/jason/.openclaw/workspace/OctoWork/projects/bot-chat-manager
./START.sh

# 自动完成：
# - 停止旧进程
# - 启动前端服务（端口5174）
# - 启动后端服务（端口6726或智能选择）
# - 验证服务状态
# - 显示访问地址和日志位置
```

#### 方式2：手动启动
```bash
# 终端1：启动后端
cd /Users/jason/.openclaw/workspace/OctoWork/projects/bot-chat-manager/backend
node start_smart.js  # 智能启动（自动选择可用端口）
# 或
node server.js       # 直接启动（使用config.json配置的端口）

# 终端2：启动前端
cd /Users/jason/.openclaw/workspace/OctoWork/projects/bot-chat-manager/frontend
npm run dev

# 访问地址
http://localhost:5174
```

#### 方式3：生产环境（使用PM2）
```bash
# 安装PM2（如果没有）
npm install -g pm2

# 启动后端
cd /Users/jason/.openclaw/workspace/OctoWork/projects/bot-chat-manager/backend
pm2 start server.js --name bot-chat-backend

# 管理命令
pm2 status                  # 查看状态
pm2 logs bot-chat-backend   # 查看日志
pm2 restart bot-chat-backend  # 重启
pm2 stop bot-chat-backend     # 停止
pm2 delete bot-chat-backend   # 删除
```

### 停止服务
```bash
# 停止所有相关进程
pkill -9 -f "node.*server.js"
pkill -9 -f "vite"

# 或使用PM2
pm2 stop bot-chat-backend
pm2 delete bot-chat-backend
```

### 查看日志
```bash
# 方式1：START.sh 启动后
tail -f frontend.log   # 前端日志
tail -f backend.log    # 后端日志

# 方式2：PM2启动后
pm2 logs bot-chat-backend

# 方式3：直接启动时查看终端输出
```

---

## 🔧 常见问题排查

### 问题1：后端启动失败

**症状**：执行 `node server.js` 报错

**排查步骤**：
```bash
# 1. 检查端口是否被占用
lsof -i:6726
# 解决：杀掉占用进程或修改config.json中的端口

# 2. 检查OpenClaw API是否可访问
curl http://localhost:18789
# 解决：启动OpenClaw服务

# 3. 检查config.json是否正确
cat config.json | grep -A 3 openclaw
# 解决：确认api_url和token正确

# 4. 查看详细错误日志
node server.js
```

### 问题2：前端无法访问

**症状**：浏览器无法打开 `http://localhost:5174`

**排查步骤**：
```bash
# 1. 检查端口是否被占用
lsof -i:5174
# 解决：杀掉占用进程或修改vite.config.ts中的端口

# 2. 查看前端日志
tail -f frontend.log
# 或直接运行
cd frontend && npm run dev

# 3. 检查依赖是否完整
cd frontend && npm install
```

### 问题3：Bot无响应

**症状**：发送消息后Bot不回复

**排查步骤**：
```bash
# 1. 检查后端日志
tail -f backend.log
# 查看是否有错误信息

# 2. 检查Bot配置
cat config.json | grep -A 5 "ai-brain-commander-jack"
# 确认Bot ID和路径正确

# 3. 测试OpenClaw CLI
openclaw agent --agent ai-brain-commander-jack --message "test" --json
# 确认Bot可以正常响应

# 4. 检查WebSocket连接
# 打开浏览器控制台，查看是否有WebSocket连接错误
```

### 问题4：数据库错误

**症状**：报错 `SQLITE_ERROR` 或 `database is locked`

**排查步骤**：
```bash
# 1. 检查数据库文件权限
ls -la backend/data/chat.db
chmod 644 backend/data/chat.db

# 2. 检查是否有多个后端进程
ps aux | grep server.js
# 解决：杀掉所有后端进程，只保留一个

# 3. 备份并重建数据库（⚠️ 会丢失数据）
cd backend/data
mv chat.db chat.db.backup
# 重启后端，会自动创建新数据库
```

### 问题5：依赖安装失败

**症状**：`npm install` 报错

**排查步骤**：
```bash
# 1. 清理缓存
npm cache clean --force

# 2. 删除旧依赖
rm -rf node_modules package-lock.json

# 3. 重新安装
npm install

# 4. 如果还是失败，尝试使用国内镜像
npm config set registry https://registry.npmmirror.com
npm install
```

---

## ⚠️ 核心注意事项

### 1. Git操作铁律
- 🚫 **永远不要**在子目录内执行 `git init`
- ✅ 所有提交都通过主仓库 `/Users/jason/.openclaw/workspace/OctoWork/` 进行
- ✅ 检查命令：`find /Users/jason/.openclaw/workspace/OctoWork -name ".git" -type d`（应该只有1个结果）

### 2. OpenClaw依赖
- 项目依赖OpenClaw CLI（`openclaw agent --agent xxx --message xxx --json`）
- OpenClaw必须已安装并配置好
- Bot目录：`~/.openclaw/bots/ai-brain-*/`

### 3. 消息保底机制
- WebSocket断开时，消息仍会通过Webhook保底推送
- 最坏情况：30秒内通过对账服务自动补录
- **消息不会丢失**

### 4. 环境识别机制
- `ai-brain-*` → 本地OpenClaw API（实时）
- `crm-*` → 远程文件系统（异步）
- 自动识别，无需手动配置

### 5. 记忆文档位置
- 项目开发文档：`/Users/jason/.openclaw/workspace/OctoWork/projects/Sage 老Bot聊天管理器 项目开发文档.md`
- 团队记忆文档：`/Users/jason/.openclaw/workspace/OctoWork/MEMORY.md`
- Bot公寓记忆：`/Users/jason/.openclaw/workspace/OctoWork/departments/ai-brain/agents/*/MEMORY.md`

---

## 📊 项目状态总结

| 类别 | 状态 | 说明 |
|------|------|------|
| Web版 | ✅ 完成 | 可正常使用 |
| macOS原生 | ❌ 已放弃 | Web版已足够 |
| Electron打包 | ⏸️ 待定 | 30分钟可完成 |
| 核心功能 | ✅ 完整 | 聊天、群聊、任务、文件 |
| 占位功能 | ⚠️ 无实现 | 首页、企微、市场 |
| Bot主动消息 | ⏸️ 待讨论 | 等Jason确认场景 |
| 任务拆解 | ⏸️ 待讨论 | 等Jason理清需求 |

---

## 🔗 相关项目

### BotDeck（商业化版本）
- **位置**：`/Users/jason/.openclaw/workspace/OctoWork/projects/BotDeck/`
- **关系**：复用老Bot聊天管理器90%代码
- **差异**：新增设备绑定、企微CRM、数字人市场、合伙人后台
- **状态**：产品文档完成，代码未开始

---

## 📝 文档维护说明

**本文档作用**：
1. 任何人看完能快速了解项目状态
2. 失忆后能迅速恢复工作
3. 不写实现代码，只写功能状态

**更新时机**：
- 新功能完成时
- 功能状态变化时
- 重大决策时

**其他记忆文档**：
- `Sage-Bot聊天管理器开发者-记忆库.md`（核心决策、经验教训）
- `Sage 每日流水记账本.md`（日常任务记录）

---

## 🖼️ 2026-03-09 头像系统修复

### 修复内容
1. **头像本地化存储**
   - 下载16个Pravatar真实头像到 `backend/avatars/` 目录
   - 头像编号：12、13、14、15、16、17、18、20、32、33、44、45、47、48、49、51、59、60、68
   - 创建 `avatar_mapping.json` 映射文件

2. **重复Bot配置修复**
   - 为3个重复Bot创建完整 `bot.json` 配置：
     - `ai-brain-devops-sre-george` (George/运维应急员)
     - `ai-brain-quality-inspector-diana` (Diana/质量总监)
     - `ai-brain-security-warden-ivan` (Ivan/安全卫士)
   - 统一16个Bot显示，API返回正确的本地头像URL

3. **前端头像显示逻辑修复**
   - 修复App.vue头像显示条件，支持 `http` 和 `/api/avatar/` 双路径
   - 修复 `getFullAvatarUrl` 函数语法错误
   - 更新Bot列表和聊天窗口的CSS样式

4. **文件系统安全原则确立**
   - 在MEMORY.md中添加文件系统安全原则
   - 记录错误教训：未经授权删除Bot目录
   - 清理临时备份目录 `.temp_deleted_bots/`

### 技术细节
- **API路径**：`/api/avatar/avatar_XX.jpg` (XX为头像编号)
- **后端服务**：统一端口6726，本地头像服务
- **前端兼容**：自动检测头像路径格式，支持本地/远程
- **Git提交**：`5272fa98` - "头像系统修复：本地化16个Bot头像..."

### 学习教训
- **严禁**未经授权删除Bot公寓目录
- 发现数量异常(16变19)应先汇报，而不是直接删除
- 文件系统操作必须获得Jason明确授权
- sed批量替换需检查括号优先级和语法正确性

---

## 🛠️ 2026-03-11 组件模块化拆分与6种说话模式集成

### 🔧 模块化重构进展

#### 已完成模块拆分
1. **MainLayout.vue** - 全局导航栏组件
   - 提取80px高度导航栏，包含OctoWork Logo、搜索框、用户菜单
   - 支持深色/浅色主题同步，修复颜色不匹配问题
   - 保持原有毛玻璃效果和响应式设计

2. **ContentSidebar.vue** - 左侧内容侧边栏组件
   - 提取Bot列表、分组、最近聊天、搜索功能
   - 支持分组展开/收起状态管理（toggleGroup函数）
   - 界面优化：右侧添加分隔线和阴影效果，增强视觉层次
   - 显示最近5个聊天记录（从3个增加到5个）

3. **Dialog组件模块化**
   - **CreateGroupDialog.vue** - 创建群组对话框
   - **MembersDialog.vue** - 群组成员管理对话框  
   - **TaskDetailDialog.vue** - 任务详情对话框
   - 保持原有功能，独立组件便于维护

4. **ChatHeader.vue** - 聊天头部组件
   - 支持'bot'和'group'两种类型显示
   - 提取Bot名称、头像、状态显示逻辑
   - 统一聊天区域标题显示风格

5. **MessageInput.vue** - 消息输入组件
   - 完整提取GenSpark风格输入区域
   - 支持6种聊天风格切换、模型选择、发送/停止控制
   - 新增"跳转到最新消息"按钮，优化长对话体验
   - 修复样式问题，保持与原始设计100%一致

6. **UI体验优化**
   - 取消所有自动消息提示（ElNotification/ElMessage）
   - 优化未读消息红标：固定宽高，强制圆形显示
   - 侧边栏分组调整："默认团队"改为"我的OctoWork"
   - 添加6个空分组占位：我的AI员工、天号城号卡分销团队、企业微信管理团队、微信公众号团队、私域课抖音视频团队、小红书运营团队

#### 技术实现细节
- **拆分原则**：豆腐块推进，一个模块测试通过再进入下一个
- **样式保持**：100% UI一致性，用户无感知切换
- **状态管理**：props/events数据流，保持业务逻辑在App.vue
- **错误处理**：严格遵循"1次错误必须停"原则

### 🎭 OctoWork 6种说话模式集成

#### 后端系统提示词方案（方案A - 优化情感温度版）
```javascript
// 🗣️ 说人话模式 - 简洁高效沟通，带情感温度
"[系统指令：请用1-5句话回答，像朋友聊天一样自然，带点情绪和温度，不要机械，不要解释，直接给结论]"

// 💬 交流探讨模式 - 分析讨论问题，限制200字以内  
"[系统指令：请从多个角度分析这个问题，但控制在200字以内，用自然的口语表达，不要长篇大论，要有对话感]"

// 📋 方案报告模式 - 详细结构化报告
"[系统指令：请用结构化格式回答：1.问题分析 2.解决方案 3.实施步骤]"

// ⚙️ 任务工作模式 - 显示进度和步骤
"[系统指令：请按步骤回答，显示进度，给出明确的操作指导]"

// 🧠 创意脑暴模式 - 天马行空创意
"[系统指令：请发挥创意，天马行空，不要局限于常规思维]"

// ⚡ 快速决策模式 - 直接结论行动
"[系统指令：请直接给出结论和理由，不要模棱两可]"
```

**优化说明**：
- **说人话模式**：限制1-5句话，要求"像朋友聊天一样自然"，增加情感温度
- **交流探讨模式**：限制200字以内，强调"自然的口语表达"，避免长篇大论
- **其他模式**：保持原有结构，确保AI回复符合预期风格

#### 功能特点
1. **前端UI支持**：6种模式可视化切换，Alt+1~6快捷键
2. **后端处理**：style参数传递到OpenClaw调用
3. **系统指令**：添加到消息前，直接影响AI回复风格
4. **无缝集成**：保持原有消息流程，不增加延迟

### 📋 新增功能：消息复制按钮

#### 实现内容
1. **UI位置**：Bot回复消息底部，时间右侧
2. **样式一致**：GenSpark风格，半透明边框，hover效果
3. **功能完整**：点击复制纯文本，自动去除Markdown标签
4. **用户体验**：成功/失败提示，支持移动端触摸

#### 技术细节
- 使用`navigator.clipboard.writeText()` API
- 自动提取纯文本：`div.textContent || div.innerText`
- 错误降级：失败时提示手动复制
- 样式设计：11px字体，12px图标，与时间显示同行

### 📁 团队包样板间创建

#### 创建5个演示团队包
```
OctoWork_Team/
├── 企业微信管理团队/
├── 微信公众号团队/
├── 私域课抖音视频团队/
├── 天号城号卡分销团队/
└── 小红书运营团队/
```

#### 实现目的
1. **演示结构**：展示团队包目录标准格式
2. **未来扩展**：为市场化团队包提供样板
3. **技术验证**：验证目录扫描和显示逻辑
4. **用户体验**：中文名称显示，便于识别

### 🧪 测试验证结果

#### 已完成测试
- ✅ 导航栏功能正常，主题同步正确
- ✅ 侧边栏分组展开/收起，最近聊天显示5个
- ✅ 对话框组件独立运行，功能完整
- ✅ 聊天头部根据类型正确显示
- ✅ 消息输入区域样式恢复，功能正常
- ✅ 复制按钮点击复制成功，提示正确
- ✅ 后端服务重启成功，6种模式日志输出正常

#### 待测试项目（由Jason执行）
- 🔄 6种说话模式实际效果验证
- 🔄 群组聊天输入区域升级（使用MessageInput组件）
- 🔄 消息列表组件拆分（MessagesView）

### 📊 项目架构演进

#### 拆分前后对比
| 维度 | 拆分前 (2026-03-10) | 拆分后 (2026-03-11) |
|------|-------------------|-------------------|
| **App.vue行数** | 6680行 | 约200行（目标） |
| **模块化程度** | 单体架构 | 组件化架构 |
| **可维护性** | 困难 | 容易 |
| **新功能添加** | 复杂 | 简单 |
| **团队协作** | 串行 | 并行 |

#### 下一步计划
1. **MessagesView组件**：提取消息列表显示逻辑
2. **ChatArea组件**：整合聊天头部、消息列表、输入区域
3. **GroupChat升级**：群聊使用统一的MessageInput组件
4. **状态管理迁移**：Pinia stores统一管理状态
5. **路由系统集成**：Vue Router实现页面导航

### 🚀 待集成功能（2026-03-15新增）

#### 🔧 智能防卡顿引擎
**问题背景**：OpenClaw自动压缩机制导致5-10分钟卡顿，严重影响用户体验

**解决方案**（已完整开发）：
1. **主动监控**：每5分钟检查所有活跃Agent会话Token数
2. **智能清理**：Token超过60,000立即清理（安全余量40,000）
3. **自动归档**：历史完整保存到Agent公寓 `~/.octowork/agents/{id}/chat_history/`
4. **上下文保持**：保留5条最新消息 + 系统摘要，Agent不"失忆"
5. **用户无感**：OpenClaw永远没机会触发压缩

**集成要求**：
- ✅ **应用内置**：功能集成到OctoWork应用（Electron版）中，用户下载即得
- ✅ **用户无感知**：应用首次运行时自动安装服务，无需手动操作
- ❌ **不是手动脚本**：用户不需要知道安装过程

**相关文件**：
- 主脚本：`shared/tools/session-manager/octowork_session_manager.py`
- 详细文档：`shared/tools/session-manager/README.md`
- 功能标记：`projects/bot-chat-manager/TODO_智能防卡顿引擎.md`

**待办任务**：
- [ ] 设计Electron应用集成方案（首次运行自动安装服务）
- [ ] 创建设置界面：开关、阈值调整、日志查看
- [ ] 跨平台支持：macOS LaunchAgent、Windows服务、Linux systemd

### 🔐 安全与规范

#### 新增开发规范
1. **组件拆分原则**：一个功能一个组件，职责单一
2. **props接口设计**：明确数据类型，提供默认值
3. **样式一致性**：使用GenSpark设计系统，保持统一
4. **错误处理**：严格遵循"1次错误必须停"原则

#### Git操作安全
- 每次推送前验证工作目录、分支、仓库正确性
- 防止跨Bot仓库操作错误
- 分支策略：development开发分支，main生产分支

---

**最后更新**：2026-03-15 04:15 GMT+8 by 章鱼博士 (OctoTech技术负责人)  
**更新内容**：添加智能防卡顿引擎功能规划（已开发完成，待集成到OctoWork应用），解决OpenClaw自动压缩导致的5-10分钟卡顿问题

**历史更新**：
- 2026-03-11：组件模块化拆分（MainLayout/ContentSidebar/Dialogs/ChatHeader/MessageInput）、OctoWork 6种说话模式系统指令集成与情感温度优化（说人话1-5句/交流探讨200字内）、消息复制按钮功能、团队包样板间创建、UI体验优化
