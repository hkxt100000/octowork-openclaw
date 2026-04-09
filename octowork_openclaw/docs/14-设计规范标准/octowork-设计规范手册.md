# OctoWork 设计规范手册

> **版本**: v1.1  
> **日期**: 2026-04-04  
> **设计基准**: Apple Human Interface Guidelines + GenSpark Design System  
> **适用范围**: OctoWork 全产品线（开发版 octowork-chat-dev + 用户版 octowork-chat）  
> **CSS 文件**: `frontend/src/renderer/styles/` 目录下 25 个模块化 CSS 文件  
> **一句话原则**: 像 Apple 一样克制，像 GenSpark 一样高效

---

## 一、设计哲学

### 1.1 三条铁律

| # | 铁律 | Apple 对标 | GenSpark 对标 |
|---|------|-----------|--------------|
| 1 | **内容优先** — UI 退后，数据说话 | iOS 的留白和信息密度平衡 | GenSpark 的搜索结果直出，零装饰 |
| 2 | **一致性** — 同类元素永远同一个样子 | SF Symbols + 统一圆角 + 统一动效 | GenSpark 全站统一的卡片/按钮/间距 |
| 3 | **可预期** — 用户点一次就知道下次会怎样 | 标准 iOS 控件行为 | GenSpark 的交互一致性 |

### 1.2 设计态度

- **不用圆角不如死** — 每个容器、卡片、按钮、输入框都有圆角
- **不用过渡不如死** — 每个交互状态变化都有 0.2s 过渡
- **不用层次不如死** — 阴影、模糊、透明度构建 Z 轴深度
- **不硬编码不如死** — 所有视觉值通过 CSS 变量引用

### 1.3 Apple 设计参考要点

| 原则 | OctoWork 落地 |
|------|--------------|
| **Clarity** (清晰) | 系统字体栈 `-apple-system`、标准 iOS 色彩 (#007AFF, #34C759 等) |
| **Deference** (顺从) | 毛玻璃 `backdrop-filter: blur(20px)` 让内容透出 |
| **Depth** (纵深) | 5 级阴影 + hover 浮起 `translateY(-2px)` 暗示可交互 |
| **Direct Manipulation** | 卡片拖拽(看板)、手势收起(侧栏)、点击即刻反馈 |
| **Consistency** | 全局 CSS 变量、统一组件 class、统一 0.2s 过渡曲线 |

### 1.4 GenSpark 设计参考要点

| 原则 | OctoWork 落地 |
|------|--------------|
| **信息密度优先** | 统计卡片 6 列网格，一行展示所有 KPI |
| **数据可视化集成** | 内嵌 mini-chart SVG，不跳页看图表 |
| **零装饰主义** | 不用纯装饰性 divider，用 `rgba(0,0,0,0.06)` 极淡分隔 |
| **高效操作** | 快捷键 (Alt+1~7 切换聊天模式)、键盘导航 @mention |
| **深色模式原生** | 不是后加的——变量系统从第一天就支持双主题 |

---

## 二、色彩系统

### 2.1 品牌色 + 语义色（来自 global.css :root）

```css
:root {
  /* ═══ 品牌主色 ═══ */
  --color-primary: #007AFF;         /* Apple Blue — 所有主操作、链接、选中态 */

  /* ═══ 语义色 ═══ */
  --color-danger:  #FF3B30;         /* 危险/删除/错误 */
  --color-warning: #FF9500;         /* 警告/待处理 */
  --color-success: #34C759;         /* 成功/在线/通过 */

  /* ═══ 信息色（扩展，看板流水线用） ═══ */
  --color-info:    #5AC8FA;         /* 提示/信息 */
  --color-purple:  #AF52DE;         /* 标签/模型标记 */
}
```

### 2.2 灰度色阶（文本 + 背景 + 边框）

```css
:root {
  /* ═══ 文本色阶 ═══ */
  --text-primary:   #1d1d1f;        /* 标题、正文主体 */
  --text-secondary: #86868B;        /* 副标题、说明文字、时间戳 */
  --text-tertiary:  #A8A8AC;        /* 占位符、禁用态 */
  --text-quaternary:#8e8e93;        /* 导航未选中、计数器 */

  /* ═══ 背景色阶 ═══ */
  --bg-primary:   #ffffff;          /* 主内容区、卡片 */
  --bg-secondary: #F5F5F7;          /* Apple 标准系统背景 */
  --bg-tertiary:  #F9FAFB;          /* 次级背景 */
  --bg-system:    #f2f2f7;          /* 全局最外层背景 (layout.css) */

  /* ═══ 边框色阶 ═══ */
  --border-light:  rgba(0,0,0,0.06); /* 卡片边框、文件面板分隔 */
  --border-medium: rgba(0,0,0,0.08); /* 标准分隔线 */
  --border-heavy:  rgba(0,0,0,0.12); /* 强调边框 */
  --border-apple:  #e5e5ea;          /* Apple 标准实色边框 (sidebar) */
}
```

### 2.3 数据可视化色板（Dashboard 驾驶舱专用）

| 指标类型 | 颜色 | Glow | 用途 |
|---------|------|------|------|
| **工作中 / 成功** | `#34C759` | `rgba(52,199,89,0.4)` | 活跃 Bot、完成率 |
| **总量 / 信息** | `#00D2FF` | `rgba(0,210,255,0.4)` | Bot 总数、Token 消耗 |
| **任务 / 警告** | `#FF9F0A` | `rgba(255,159,10,0.4)` | 今日任务、繁忙状态 |
| **产出 / 创意** | `#A855F7` | `rgba(168,85,247,0.4)` | 文件产出、模型标签 |

> **Glow 规则**: 在暗色模式中，状态指示器使用 `box-shadow: 0 0 12px {color}` 形成发光效果。
> **品牌渐变**: Logo 使用 `linear-gradient(135deg, #00D2FF, #A855F7)` (青→紫)。

### 2.4 流水线状态色（看板专用）

| 状态 | 颜色 | 变量名 | 用途 |
|------|------|--------|------|
| `blocked` | `#666666` | `--status-blocked` | 灰色，前置未完成 |
| `ready` | `#007AFF` | `--status-ready` | 蓝色闪烁，可开始 |
| `in_progress` | `#007AFF` | `--status-in-progress` | 蓝色旋转，执行中 |
| `completed` | `#FF9500` | `--status-completed` | 橙色，等待质检 |
| `passed` | `#34C759` | `--status-passed` | 绿色，已通过 |
| `rejected` | `#FF3B30` | `--status-rejected` | 红色，打回重做 |
| `failed` | `#FF3B30` | `--status-failed` | 红色闪烁，需人工 |

### 2.5 暗色模式

暗色模式通过 `.dark-mode` 类切换。Dashboard 使用 scoped 变量覆盖：

| 属性 | 亮色 | 暗色 |
|------|------|------|
| 全局背景 | `#f2f2f7` / `#ffffff` | `#1c1c1e` / `#000000` |
| 卡片背景 | `#ffffff` | `#1c1c1e` / `#2c2c2e` |
| 文本主色 | `#1d1d1f` | `#f5f5f7` / `#ffffff` |
| 文本次色 | `#86868B` / `#6E6E73` | `#98989D` |
| 边框 | `rgba(0,0,0,0.06)` | `rgba(255,255,255,0.06)` |
| 阴影 | `rgba(0,0,0,0.1)` | `rgba(0,0,0,0.3)` |
| 滚动条 | `rgba(0,0,0,0.1)` | `rgba(255,255,255,0.1)` |
| 跳转按钮 bg | `#ffffff` | `#2c2c2e` |
| 品牌蓝 | `#007AFF` | `#0A84FF` (更亮) |
| 成功绿 | `#34C759` | `#30D158` (更亮) |
| 警告橙 | `#FF9500` | `#FF9F0A` (更亮) |
| 危险红 | `#FF3B30` | `#FF453A` (更亮) |

> **暗色模式规则**: 语义色在暗色中使用 Apple 官方暗色变体（亮度更高以在深色背景上保持对比度）。

---

## 三、字体系统

### 3.1 字体栈

```css
/* 主字体 — Apple 系统字体优先 */
font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Display',
             'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;

/* Dashboard 中文补充 */
font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'PingFang SC', sans-serif;

/* 等宽字体 — 代码块 */
font-family: 'Monaco', 'Courier New', monospace;

/* 数据面板等宽字体 — Dashboard 数字/技术文本 */
font-family: 'JetBrains Mono', 'SF Mono', 'Menlo', 'Monaco', 'Consolas', monospace;

/* 超大数字字体 — Dashboard 统计大数字 (如 2.8M、1,024) */
font-family: 'Orbitron', 'SF Mono', 'Menlo', 'Monaco', 'Consolas', monospace;
```

### 3.2 字号规范

| 用途 | 字号 | 字重 | 行高 | 字间距 | 场景 |
|------|------|------|------|--------|------|
| **统计大数字** | 28-32px | 700 | 1.2 | 1px | Dashboard 数值 (StatsOverview) |
| **页面大标题** | 22px | 700 | 1.3 | -0.02em | Dashboard 标题 |
| **侧栏名称** | 20px | 700 | 1.3 | — | 用户姓名 (sidebar) |
| **Logo 文字** | 18px | 700 | 1.3 | 0.5px | OctoWork 品牌名（渐变色） |
| **对话框标题** | 18px | 600 | 1.4 | -0.02em | Dialog header |
| **区块标题** | 16px | 600 | 1.4 | — | 文件头部 h3、面板标题、菜单项 |
| **时钟数字** | 15px | 600 | 1 | 1px | Dashboard 时间显示 |
| **卡片标题** | 14px | 600 | 1.4 | -0.01em | Bot 名称、任务标题 |
| **正文** | 14px | 400 | 1.5 | — | 消息内容、描述文字、对话框按钮 |
| **辅助正文** | 13px | 500-600 | 1.4 | -0.2px | 按钮文字、分组标题、面板标题 |
| **标签/角标** | 12px | 500-600 | 1.2 | — | 角色描述、状态标签、统计标签 |
| **Tab 标签** | 11px | 590 | 1.2 | -0.2px | 导航 Tab、分组计数、面板头部 |
| **角标数字** | 10px | 700 | 1.0 | 0.3px | 未读角标、模型标记、状态栏 |
| **Dashboard 极小** | 7px | 600 | 1.2 | — | Bot Grid 名称 |
| **Dashboard 极小2** | 6px | 400 | 1.2 | — | Bot Grid 状态文字 |

### 3.3 字重规范

| 字重 | CSS 值 | 用途 |
|------|--------|------|
| Regular | `400` | 正文、消息内容 |
| Medium | `500` | 按钮文字、头部操作、状态文字、统计标签 |
| Semibold | `590` | Tab 标签 (SF Pro 专用值) |
| Semibold | `600` | 卡片标题、分组标题、强调文字、对话框按钮、统计副标签 |
| Bold | `700` | 页面大标题、角标数字、品牌名称、统计大数字 |

### 3.4 特殊文字效果

```css
/* 品牌渐变文字 (Logo) */
.logo-text {
  background: linear-gradient(135deg, var(--accent-cyan), var(--accent-purple));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* 表格数字等宽 (防止数字跳动) */
font-variant-numeric: tabular-nums;

/* 数字发光文字 (Dashboard 时钟) */
text-shadow: 0 0 10px rgba(0, 210, 255, 0.3);

/* 大数字微光 (Token 计数) */
text-shadow: 0 0 15px rgba(0, 210, 255, 0.2);
```

---

## 四、间距系统

### 4.1 间距变量（来自 global.css）

```css
:root {
  --space-1: 4px;    /* 最小间距：图标与文字间 */
  --space-2: 8px;    /* 小间距：列表项内 padding */
  --space-3: 12px;   /* 标准间距：卡片内 padding */
  --space-4: 16px;   /* 中间距：区块间、header padding */
  --space-5: 20px;   /* 大间距：主区域 padding */
  --space-6: 24px;   /* 最大间距：页面级 padding */
}
```

### 4.2 间距使用规则

| 场景 | 间距 | 说明 |
|------|------|------|
| 图标与文字 | 4-6px | `gap: 4px` (nav) / `gap: 6px` (卡片) |
| 按钮组内部 | 6px | `gap: 6px` (header-actions) |
| Grid 网格间隙 | 8px | Bot Card Grid `gap: 8px` |
| 列表项间距 | 8px | `margin-bottom: 8px` (bot-card) |
| 卡片内边距 | 12px | `padding: 12px` (bot-card) |
| 对话框按钮间距 | 12px | `gap: 12px` (dialog-footer) |
| 面板 padding | 16px | `padding: 16px 20px` (files-header) |
| Dashboard 区块间距 | 16px | `gap: 16px` (stats-grid, sections) |
| 统计卡片 padding | 18px 20px | `padding: 18px 20px` (stat-card) |
| 侧栏内容 padding | 24px | `padding: 24px` (sidebar-menu, dialog-body) |
| 全局左右 margin | 16px | Dashboard 区块 `margin: 8px 16px` |
| 导航栏宽度 | 80px | 全局固定导航 |
| 侧边栏宽度 | 300px | `width: 300px; min: 260; max: 340` |
| 用户侧栏宽度 | 360px | Dashboard 用户面板 |
| 聊天区域 | 700px | 四栏布局固定宽度 |

---

## 五、圆角系统

### 5.1 圆角变量

```css
:root {
  --radius-sm:  6px;   /* 代码块、小标签 */
  --radius-md:  10px;  /* 按钮、输入框 */
  --radius-lg:  16px;  /* 大号卡片、对话框 */
  --radius-xl:  20px;  /* 胶囊按钮 */
}
```

### 5.2 圆角使用规则

| 圆角 | 对应变量 | 使用场景 |
|------|---------|----------|
| **3px** | — | 内联 code 标签 |
| **4px** | — | trend-badge (小型指标标签) |
| **6px** | `--radius-sm` | 代码块 `pre`、blockquote、模型标签、时钟背景、checkbox |
| **8px** | — | 导航项 `nav-item`、Tab 项、头部按钮、Bot Grid 项、状态栏 |
| **10px** | `--radius-md` | Tinted 按钮、文本按钮、表单输入框、选择项、角标 |
| **12px** | — | Bot 卡片、创建按钮、头部操作组、统计卡片、对话框关闭按钮、状态指示器、状态栏圆角 |
| **16px** | `--radius-lg` | 大面板、对话框容器 |
| **18px** | — | 消息气泡 `message-text` |
| **20px** | `--radius-xl` | 胶囊按钮 `create-group-btn`、解锁按钮 |
| **50%** | — | 头像、状态圆点、在线指示器、图标按钮 |
| **9px** | — | 角标 (pill 形状: `border-radius: 9px` on 18px height) |

---

## 六、阴影系统

### 6.1 阴影等级

| 等级 | 值 | 用途 |
|------|-----|------|
| **Level 0** | `none` | 平面元素、分隔线足够的场景 |
| **Level 1** | `0 1px 3px rgba(0,0,0,0.04)` | 消息气泡 |
| **Level 1.5** | `0 1px 3px rgba(0,0,0,0.05)` | 侧边栏 |
| **Level 2** | `0 2px 8px rgba(0,0,0,0.06)` | Bot 卡片默认态、Bot Grid 容器 |
| **Level 2-D** | `0 2px 12px rgba(0,0,0,0.04)` | Dashboard 统计卡片、状态栏默认态 |
| **Level 2.5** | `0 2px 8px rgba(0,122,255,0.15)` | 选中卡片（带品牌色） |
| **Level 3** | `0 4px 12px rgba(0,0,0,0.08)` | 卡片 hover 态 |
| **Level 3-D** | `0 4px 16px rgba(0,0,0,0.12)` | Bot Grid 项 hover |
| **Level 3-S** | `0 4px 20px rgba(0,0,0,0.08)` | Dashboard 状态栏 hover |
| **Level 4** | `0 4px 12px rgba(0,122,255,0.25)` | 主操作按钮 |
| **Level 4-D** | `0 8px 32px rgba(0,0,0,0.16)` | 统计卡片 hover、悬浮详情面板 |
| **Level 5** | `0 6px 20px rgba(0,122,255,0.35)` | 主操作按钮 hover |
| **Level 6** | `0 20px 60px rgba(0,0,0,0.3)` | 对话框 (最高层级) |

### 6.2 阴影规则

- **静态元素**: Level 1-2
- **hover 态**: 比默认态升一到两级 (Level 2 → Level 3, Level 2-D → Level 4-D)
- **品牌色阴影**: 主操作按钮使用 `rgba(0,122,255, 0.25)` 而非黑色
- **active 态**: 阴影收缩 (Level 4 → Level 2)
- **导航栏**: `2px 0 12px rgba(0,0,0,0.05)` (水平方向)
- **用户侧栏**: `-4px 0 24px rgba(0,0,0,0.15)` (从右侧展出)
- **Dashboard 统计卡片 hover**: `translateY(-4px)` + Level 4-D（比标准卡片更大浮起）

### 6.3 毛玻璃 (Blur)

```css
/* 全局导航栏 */
backdrop-filter: blur(20px) saturate(1.2);
-webkit-backdrop-filter: blur(20px) saturate(1.2);
background: rgba(255, 255, 255, 0.7);

/* Dashboard 面板 / 统计卡片 */
backdrop-filter: blur(20px);
background: var(--bg-card);

/* 独立窗口状态栏 */
backdrop-filter: blur(10px);
background: rgba(255,255,255,0.9);

/* 对话框遮罩层 / 侧栏遮罩层 */
backdrop-filter: blur(4px);
-webkit-backdrop-filter: blur(4px);
background: rgba(0, 0, 0, 0.4);

/* 详情悬浮面板 */
backdrop-filter: blur(20px);
background: var(--bg-card, rgba(255, 255, 255, 0.98));
```

---

## 七、按钮系统

### 7.1 按钮类型

| 类型 | class | 外观 | 场景 |
|------|-------|------|------|
| **Primary** | `.create-group-button` | 渐变蓝色填充 + 白字 + 品牌阴影 | 核心操作：创建、提交、确认 |
| **Primary (Dialog)** | `.dialog-btn.confirm` | 渐变蓝 `#007AFF→#0051D5` + 白字 | 对话框确认 |
| **Gradient (Dashboard)** | `.unlock-btn` | 渐变 `#00D2FF→#A855F7` + 白字 | 解锁、特殊操作 |
| **Tinted** | `.tinted-button` | 浅蓝底 + 蓝字 + 蓝边框 | 次要操作：筛选、切换 |
| **Text** | `.text-button` | 透明底 + 灰字 | 辅助操作：取消、关闭 |
| **Cancel** | `.dialog-btn.cancel` | `#f5f5f7` 底 + 深色字 | 对话框取消 |
| **Header Action** | `.header-action-btn` | 透明底 + 灰字 (pill 组) | 头部操作组内 |
| **Icon** | `.icon-btn` | 纯图标 36x36 圆形 | Dashboard 头部工具 |
| **Danger** | `.dialog-btn.danger` / `.logout-btn` | 红色填充 或 红色底 + 红字 | 删除、退出登录 |

### 7.2 按钮状态

```
默认态:
  background: transparent / 渐变蓝
  transform: none
  box-shadow: Level 0 / Level 4

hover态:
  background: +0.02 opacity / 更亮渐变
  transform: translateY(-2px)          ← Apple 微浮起
  box-shadow: 升一级

  特例 — icon-btn:
  transform: scale(1.1)               ← Dashboard 图标按钮放大
  background: rgba(0,0,0,0.05)

active态:
  transform: translateY(0)             ← 回弹
  box-shadow: 降一级

  特例 — icon-btn:
  transform: scale(0.95)              ← 缩小反馈

disabled态:
  opacity: 0.3
  cursor: not-allowed
  pointer-events: none
```

### 7.3 按钮尺寸

| 尺寸 | padding | font-size | border-radius | 场景 |
|------|---------|-----------|---------------|------|
| **Small** | `6px 16px` | 13px | 10px | Tinted 按钮 |
| **Medium** | `7px 14px` | 13px | 8px | Header action |
| **Standard** | `10px 20px` | 14px | 10px | 对话框按钮 |
| **Large** | `12px 16px` | 15px | 12px | Create 按钮 |
| **Dashboard** | `10px 24px` | 14px | 20px | 解锁按钮 (胶囊) |
| **Wide** | `14px (全宽)` | 16px | 12px | 退出登录按钮 |

---

## 八、卡片系统

### 8.1 标准卡片（Bot 卡片）

```css
.card {
  background: #ffffff;
  border-radius: 12px;
  padding: 12px;
  border: 1px solid rgba(0,0,0,0.06);
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  cursor: pointer;
  transition: all 0.2s ease;
}

.card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  transform: translateY(-2px);
}

.card.active {
  background: linear-gradient(135deg, #f0f7ff 0%, #e3f2fd 100%);
  border-left: 3px solid #007AFF;
  box-shadow: 0 2px 8px rgba(0,122,255,0.15);
}
```

### 8.2 Dashboard 统计卡片

```css
.stat-card {
  background: var(--bg-card);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(0,0,0,0.06);
  border-radius: 12px;
  padding: 18px 20px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.04);
  transition: all 0.3s ease;        /* 比标准卡片慢 0.1s */
}

.stat-card:hover {
  transform: translateY(-4px);       /* 比标准多 2px */
  box-shadow: 0 8px 32px rgba(0,0,0,0.16);
}

/* hover 时顶部色条渐显 */
.stat-card::before {
  height: 3px;
  background: var(--accent-color);   /* 动态传入的指标颜色 */
  border-radius: 12px 12px 0 0;
  opacity: 0 → 1;
}
```

### 8.3 Dashboard 状态栏卡片

```css
.system-status-bar {
  height: 56px;
  border-radius: 12px;
  padding: 12px 24px;
  margin: 8px 16px 0;
  backdrop-filter: blur(20px);
  box-shadow: 0 2px 12px rgba(0,0,0,0.04);
}
```

### 8.4 卡片内头像

| 类型 | 尺寸 | 圆角 | 边框 | 阴影 |
|------|------|------|------|------|
| Bot 头像 (列表) | 44x44px | 50% | 2px solid rgba(0,0,0,0.1) | `0 2px 6px rgba(0,0,0,0.1)` |
| Bot 头像 (Grid) | 42x42px | 50% | 2px solid var(--border) | — |
| Emoji 头像 | 44x44px | 50% | — | 渐变底 `#667eea → #764ba2` |
| 用户头像 (状态栏) | 36x36px | 50% | 2px solid transparent (hover: #00D2FF) | hover: `0 0 0 2px rgba(0,210,255,0.2)` |
| 侧栏头像 | 100x100px | 50% | 3px solid #34C759 | — |
| 团队头像 | 48x48px | 50% | 2px solid rgba(0,0,0,0.06) | — |

### 8.5 角标 (Badge)

```css
/* 未读角标 */
.badge {
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  border-radius: 9px;
  font-size: 10px;
  font-weight: 700;
  background: linear-gradient(135deg, #FF3B30 0%, #FF6B60 100%);
  color: white;
  border: 2px solid white;
  box-shadow: 0 2px 4px rgba(255,59,48,0.3);
}

/* 导航红标 */
.nav-badge {
  /* 同上，定位 absolute top:6 right:10 */
  border: 2px solid rgba(255,255,255,0.9);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

/* 通知小圆点 (无数字) */
.notification-badge {
  width: 8px;
  height: 8px;
  background: #FF3B30;
  border-radius: 50%;
  border: 2px solid var(--bg-primary);
}

/* 菜单角标 */
.menu-badge {
  background: #FF3B30;
  color: white;
  font-size: 12px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 10px;
}
```

---

## 九、表单系统

### 9.1 输入框

```css
.form-input, .form-textarea {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid rgba(0,0,0,0.1);
  border-radius: 10px;
  font-size: 14px;
  color: #1d1d1f;
  background: #f5f5f7;
  transition: all 0.2s ease;
  font-family: inherit;
}

.form-input:focus, .form-textarea:focus {
  outline: none;
  border-color: #007AFF;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0,122,255,0.1);   /* Apple Focus Ring */
}
```

### 9.2 表单布局

```css
.form-group { margin-bottom: 20px; }
.form-label {
  font-size: 13px;
  font-weight: 600;
  color: #1d1d1f;
  margin-bottom: 8px;
}
.form-hint {
  font-size: 12px;
  color: #8e8e93;
  margin-top: 6px;
}
```

### 9.3 选择列表

```css
.select-item {
  padding: 12px 16px;
  background: #f5f5f7;
  border-radius: 10px;
  gap: 12px;
}

.select-item.selected {
  background: rgba(0,122,255,0.1);
  border: 2px solid #007AFF;
}

.select-checkbox {
  width: 20px; height: 20px;
  border: 2px solid #8e8e93;
  border-radius: 6px;
}

.select-item.selected .select-checkbox {
  background: #007AFF;
  border-color: #007AFF;
}
```

---

## 十、对话框系统

### 10.1 对话框结构

```css
/* 遮罩层 */
.dialog-overlay {
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  z-index: 1000;
  animation: fadeIn 0.2s ease;
}

/* 容器 */
.dialog-container {
  background: #ffffff;
  border-radius: 16px;
  max-width: 90%;
  max-height: 90vh;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
  animation: slideUp 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

/* 头部 */
.dialog-header {
  padding: 20px 24px;
  border-bottom: 1px solid rgba(0,0,0,0.08);
}

/* 内容 */
.dialog-body {
  padding: 24px;
  max-height: calc(90vh - 140px);
  overflow-y: auto;
}

/* 底部 */
.dialog-footer {
  padding: 16px 24px;
  border-top: 1px solid rgba(0,0,0,0.08);
  gap: 12px;
}
```

### 10.2 用户侧栏 (Dashboard)

```css
/* 侧栏面板 */
.user-sidebar {
  width: 360px;
  right: -400px → 0;                 /* 滑入动画 */
  transition: right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: -4px 0 24px rgba(0,0,0,0.15);
  z-index: 1000;
}

/* 遮罩 */
.sidebar-overlay {
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  z-index: 999;
}
```

### 10.3 悬浮详情面板

```css
.bot-detail-panel {
  backdrop-filter: blur(20px);
  border: 1px solid var(--border);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.16);
  padding: 16px;
  min-width: 280px;
  max-width: 320px;
}
```

---

## 十一、动效系统

### 11.1 过渡曲线

| 名称 | 值 | 用途 |
|------|-----|------|
| **Standard** | `ease` | 通用状态切换 |
| **Apple** | `cubic-bezier(0.25, 0.46, 0.45, 0.94)` | Tab 切换、卡片交互、对话框进入 |
| **Material** | `cubic-bezier(0.4, 0, 0.2, 1)` | 侧栏滑入 |

### 11.2 过渡时长

| 时长 | 用途 |
|------|------|
| **0.15s** | 最快反馈：列表项背景变化 |
| **0.2s** | 标准：所有 hover/active 状态、颜色变化、位移 |
| **0.3s** | 中速：滚动条显隐、展开收起、统计卡片 hover、背景/文字色渐变、侧栏滑入、对话框进入 |
| **2s** | 旋转动画 (loading spinner)、脉冲 (pulse) |
| **3s** | Logo 浮动动画 (float)、光晕脉冲 (pulse-glow) |
| **4s** | 章鱼浮动 (octopus-float)、光线脉冲 (light-pulse) |

### 11.3 关键帧动画

| 动画 | class | 用途 |
|------|-------|------|
| `fadeIn` | — | 页面/组件进入：`opacity 0→1 + scale 0.98→1` |
| `slideDown` | — | 下拉内容：`opacity 0→1 + translateY -10→0` |
| `slideUp` | — | 对话框进入：`opacity 0→1 + translateY 20→0` |
| `spin` | `.spinning` | 加载旋转：`rotate 0→360deg, 2s linear infinite` |
| `rotate` | — | 头像光环旋转：`0→360deg, 3s linear infinite` |
| `pulse` | — | 脉冲光晕：`opacity 1→0.5→1, 2s infinite` (状态圆点) |
| `float` | — | Logo 浮动：`translateY 0→-4px→0, 3s ease-in-out infinite` |
| `octopus-float` | — | 章鱼浮动：`translateY 0→-8px + rotate 0→3deg, 4s infinite` |
| `pulse-glow` | — | 发光脉冲：`scale 1→1.1 + opacity 0.5→1, 3s infinite` |
| `light-pulse` | — | 光线闪烁：`opacity 0→0.6→0, 4s infinite` |
| `fade (Vue transition)` | `.fade-enter/leave` | Vue 过渡：`opacity 0↔1, 0.2s ease` |

### 11.4 交互微动效

| 交互 | 效果 |
|------|------|
| 标准卡片 hover | `translateY(-2px)` 微浮起 |
| 统计卡片 hover | `translateY(-4px)` 大浮起 + 顶部色条渐显 |
| 按钮 hover | `translateY(-2px)` 微浮起 |
| icon-btn hover | `scale(1.1)` 放大 |
| icon-btn active | `scale(0.95)` 缩小回弹 |
| 导航 hover | `translateY(-1px)` 轻微浮起 |
| active/press | `translateY(0)` 回弹 或 `scale(0.98)` 缩放 |
| Tab 选中图标 | `scale(1.15)` + `drop-shadow` |
| 展开箭头 | `rotate(90deg)` |
| 用户头像 hover | `scale(1.05)` + 边框色变 `#00D2FF` |
| 团队头像 hover | `scale(1.1)` + 边框色变 `#00D2FF` |
| Bot Grid 项 hover | `translateY(-2px)` + 边框加深 + 增强阴影 |

---

## 十二、图标系统

### 12.1 图标规范

| 属性 | 值 | 说明 |
|------|-----|------|
| **风格** | 线性 (Stroke) | 与 Apple SF Symbols 对齐 |
| **描边** | `stroke-width: 2` | 全局统一 |
| **端点** | `stroke-linecap: round` | 圆角端点 |
| **连接** | `stroke-linejoin: round` | 圆角连接 |
| **尺寸 — 导航** | 20×20px | 全局导航图标 |
| **尺寸 — 状态栏** | 20×20px | Dashboard 头部工具 |
| **尺寸 — 菜单** | 24×24px | 侧栏菜单图标 |
| **尺寸 — 统计卡片** | 24×24px | StatsOverview 卡片图标 |
| **颜色 — 默认** | `currentColor` / `stroke="currentColor"` | 继承父级文本色 |
| **颜色 — 统计** | 各指标专属色 | `stroke="#34C759"` 等 |
| **不透明度** | 默认 0.6, hover 1.0 | 渐变显示 |

### 12.2 Mini-Chart SVG

Dashboard 统计卡片内嵌 60×24 的 mini-chart：

```css
.mini-chart {
  width: 60px;
  height: 24px;
  opacity: 0.5;
}
```

支持类型：折线 (`<path>`), 柱形 (`<rect>`), 散点 (`<circle>`)。

---

## 十三、布局系统

### 13.1 全局布局

```
┌──────────────────────────────────────────────────────┐
│  bot-chat-manager (100vw × 100vh, display: flex)      │
│                                                        │
│  ┌──────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐ │
│  │Global│ │ Sidebar   │ │ Chat     │ │ Workspace    │ │
│  │ Nav  │ │ (列表)    │ │ Area     │ │ (文件/任务)  │ │
│  │      │ │           │ │          │ │              │ │
│  │ 80px │ │ 300px     │ │ 700px    │ │ flex: 1      │ │
│  │fixed │ │ min:260   │ │ fixed    │ │ 自适应       │ │
│  │      │ │ max:340   │ │          │ │              │ │
│  └──────┘ └──────────┘ └──────────┘ └──────────────┘ │
└──────────────────────────────────────────────────────┘
```

### 13.2 Dashboard 布局

```
┌──────────────────────────────────────────────────────┐
│  dashboard-view (100vw, min-height 100vh, flex column) │
│                                                        │
│  ┌──── system-status-bar (h:56px) ────────────────┐   │
│  │ Logo + OctoWork    [🌙] [🔊] [↗] [🔔] [👤]   │   │
│  └────────────────────────────────────────────────┘   │
│                                                        │
│  ┌──── stats-grid (6 列) ─────────────────────────┐   │
│  │  [工作中]  [总Bot]  [今日任务]  [产出]  [...] │   │
│  └────────────────────────────────────────────────┘   │
│                                                        │
│  ┌──── bot-card-grid (9×3 网格) ──────────────────┐   │
│  │  [Bot01] [Bot02] ... [Bot09]                     │   │
│  │  [Bot10] [Bot11] ... [Bot18]                     │   │
│  │  [Bot19] [Bot20] ... [Bot27]                     │   │
│  └────────────────────────────────────────────────┘   │
│                                                        │
│  ┌──── log-stream-section ────────────────────────┐   │
│  │  实时日志流                                      │   │
│  └────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

### 13.3 布局模式

| 模式 | class | 列数 | 说明 |
|------|-------|------|------|
| 四栏 | `.four-columns` | 导航+侧栏+聊天(700px)+工作台 | 标准单聊 |
| 四栏群聊 | `.four-columns-group` | 同上 | 群聊 |
| 三栏 | `.three-columns` | 导航+侧栏+内容(flex:1) | 简化模式 |
| 两栏 | `.two-columns` | 导航+内容(flex:1) | Dashboard / 看板 |
| Dashboard | `.dashboard-view` | 全宽纵向 | 首页驾驶舱 |

### 13.4 响应式断点

| 断点 | 变化 |
|------|------|
| **≤ 1400px** | Dashboard 统计卡片 6列 → 3列 |
| **≤ 1200px** | 群聊四栏聊天区 700px → 500px |
| **≤ 900px** | Dashboard 统计卡片 3列 → 2列 |
| **≤ 768px** | 移动端：侧栏全宽、聊天全宽、隐藏工作台第四列、输入框 16px 防 iOS 缩放 |
| **≤ 375px** | 小屏手机：缩小 padding、减小标题字号 |

---

## 十四、组件速查表

### 14.1 状态圆点

```css
/* 在线 */
.status-dot { width: 6px; height: 6px; border-radius: 50%; background: #34C759; }
/* 离线 */
.status-dot.offline { background: #8e8e93; }

/* 头像上的在线指示器 */
.online-indicator { width: 12px; height: 12px; background: #34C759; border: 2px solid white; }

/* Dashboard Bot Grid 状态指示器 */
.status-indicator { width: 12px; height: 12px; border-radius: 50%; border: 2px solid var(--bg-card); }
.status-indicator.status-working { background: #34C759; }
.status-indicator.status-idle    { background: #00D2FF; }
.status-indicator.status-busy    { background: #FF9F0A; }
```

### 14.2 标签 (Tag)

```css
/* 模型标签 */
.model-tag {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 2px 6px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 600;
}

/* 分组计数标签 */
.group-count {
  background: rgba(142,142,147,0.12);
  padding: 3px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 600;
}

/* 趋势标签 (Dashboard) */
.trend-badge {
  font-size: 12px; font-weight: 600;
  padding: 2px 6px; border-radius: 4px;
}
.trend-up   { color: #34C759; background: rgba(52,199,89,0.1); }
.trend-down { color: #FF453A; background: rgba(255,69,58,0.1); }

/* 状态标签 (悬浮面板) */
.detail-status {
  font-size: 12px; padding: 4px 10px;
  border-radius: 12px; font-weight: 500;
}
.detail-status.status-working { background: rgba(52,199,89,0.15); color: #34C759; }
.detail-status.status-idle    { background: rgba(0,210,255,0.15); color: #00D2FF; }
.detail-status.status-busy    { background: rgba(255,159,10,0.15); color: #FF9F0A; }
```

### 14.3 消息气泡

```css
.message-bubble {
  background: #f2f2f7;        /* 收到的消息 */
  padding: 10px 12px;
  border-radius: 18px;
  font-size: 14px;
  line-height: 1.5;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}

/* 引用块 (在消息内) */
blockquote {
  border-left: 3px solid #007AFF;
  background: rgba(0,122,255,0.08);
  border-radius: 0 6px 6px 0;
}
```

### 14.4 空状态

```css
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 60px 20px;
  color: #8e8e93;
}
.empty-state-icon { font-size: 64px; opacity: 0.5; }
.empty-state-text { font-size: 14px; line-height: 1.6; }
```

### 14.5 滚动条

```css
/* 标准滚动条 */
::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb {
  background: rgba(0,0,0,0.1);
  border-radius: 6px;
  border: 3px solid transparent;
  background-clip: padding-box;
  opacity: 0;                      /* 默认隐藏，hover 显示 */
  transition: opacity 0.3s ease;
}

/* Dashboard 细滚动条 */
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-thumb {
  background: rgba(0,0,0,0.12);
  border-radius: 2.5px;
}

/* 暗色: rgba(255,255,255,0.1 / 0.12) */
```

### 14.6 进度条 / Track-Fill

```css
/* Dashboard 数据面板 */
.model-bar-track, .health-track {
  height: 4px;
  background: rgba(0,0,0,0.1);    /* 暗色: rgba(255,255,255,0.1) */
  border-radius: 2px;
}
.model-bar-fill, .health-fill {
  height: 100%;
  border-radius: 2px;
  /* background 由 JS 动态设置为指标颜色 */
}
```

---

## 十五、CSS 文件结构

### 15.1 文件清单 (25 个模块)

```
frontend/src/renderer/styles/
├── global.css        ← :root 变量 + 全局重置 (必须最先加载)
├── layout.css        ← 全局布局：四栏/三栏/两栏
├── navigation.css    ← 全局导航 + 导航项 + 红标
├── sidebar.css       ← 侧边栏 + Tab 栏
├── components.css    ← 通用组件：分组标题/Bot卡片/Tab/空状态
├── buttons.css       ← 所有按钮类型
├── messages.css      ← 消息气泡 + Markdown 渲染
├── chat.css          ← 聊天容器 + 输入区
├── headers.css       ← 聊天头部
├── lists.css         ← 列表项 + 最近聊天
├── mentions.css      ← @mention 弹窗
├── groups.css        ← 群聊特有样式
├── avatars.css       ← 头像系统
├── dialogs.css       ← 弹窗/模态框 + 表单输入 + 选择列表
├── files.css         ← 文件浏览/预览
├── tasks.css         ← 任务卡片
├── task-details.css  ← 任务详情弹窗
├── task-monitor.css  ← 任务监控面板
├── logs.css          ← 日志展示
├── animations.css    ← 关键帧动画
├── darkmode.css      ← 暗色模式覆盖
├── scrollbars.css    ← 自定义滚动条
├── responsive.css    ← 响应式断点
├── utilities.css     ← 工具类
└── overrides.css     ← Element Plus 覆盖
```

### 15.2 新增/修改规则

1. **新增样式** → 放到对应模块文件中，不要写到组件 `<style scoped>` 内（除非确实只在该组件内使用）
2. **新增变量** → 必须写到 `global.css` 的 `:root` 块中
3. **暗色覆盖** → 写到 `darkmode.css` 中，选择器前缀 `.dark-mode`
4. **Dashboard 专用样式** → 允许写在 `<style scoped>` 中（Dashboard 组件层级独立）
5. **不允许**：`!important` (除非覆盖第三方库)、硬编码颜色值（必须用变量）

---

## 十六、命名规范

### 16.1 CSS class 命名

```
组件级:    .bot-card、.message-text、.pipeline-bar、.stat-card
子元素:    .bot-card-avatar、.bot-card-info、.bot-card-name
状态修饰:  .bot-card.active、.status-dot.offline、.tab-item.active
尺寸修饰:  .avatar-sm、.avatar-lg
布局修饰:  .four-columns、.two-columns
主题修饰:  .dark-mode
功能修饰:  .locked、.status-working、.status-idle、.status-busy
趋势修饰:  .trend-up、.trend-down
对话框:    .dialog-overlay、.dialog-container、.dialog-header、.dialog-body、.dialog-footer
表单:      .form-group、.form-label、.form-input、.form-textarea、.form-hint
```

### 16.2 CSS 变量命名

```
颜色:    --color-primary、--color-danger
文本:    --text-primary、--text-secondary
背景:    --bg-primary、--bg-system
边框:    --border-light、--border-medium
间距:    --space-1 到 --space-6
圆角:    --radius-sm 到 --radius-xl
状态:    --status-blocked、--status-passed
强调:    --accent-blue、--accent-green、--accent-cyan、--accent-purple
发光:    --green-glow、--cyan-glow、--amber-glow、--purple-glow
```

---

## 十七、开发检查清单

每次提交前端代码前，对照检查：

- [ ] **颜色**: 没有硬编码颜色值，全部使用 CSS 变量（Dashboard scoped 组件可用 `var(--accent-color)` 动态变量）
- [ ] **字号**: 符合第三章字号表，不随意使用非标准字号
- [ ] **圆角**: 所有容器/卡片/按钮有圆角，数值符合第五章
- [ ] **阴影**: 静态 Level 1-2，hover Level 3-4，按钮 Level 4，对话框 Level 6
- [ ] **过渡**: 所有交互状态变化有 `transition: all 0.2s ease` (Dashboard 卡片可用 0.3s)
- [ ] **间距**: 使用 `--space-*` 变量或符合第四章数值
- [ ] **暗色**: 组件样式需在 `darkmode.css` 中有对应覆盖（或 Dashboard scoped 内处理）
- [ ] **滚动条**: 自定义样式，默认隐藏 hover 显示
- [ ] **字体**: 使用系统字体栈，等宽用 Monaco/JetBrains Mono，数字用 tabular-nums
- [ ] **动效**: hover 有 `translateY` 或 `scale` 浮起，active 有回弹
- [ ] **图标**: 线性 stroke-width:2 风格，尺寸 20/24px，颜色 currentColor
- [ ] **表单**: focus 有蓝色边框 + `box-shadow: 0 0 0 3px rgba(0,122,255,0.1)` 聚焦环
- [ ] **响应式**: 检查 1400/1200/900/768/375 五个断点
- [ ] **Apple 一致性**: 毛玻璃效果、系统字体、iOS 色彩、圆角按钮、微浮起动效
- [ ] **GenSpark 一致性**: 信息密度高、零装饰 border、数据直出、操作效率优先

---

## 附录 A：快速复制代码片段

### A.1 新建标准卡片

```css
.my-new-card {
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: 12px;
  padding: var(--space-3);
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  cursor: pointer;
  transition: all 0.2s ease;
}
.my-new-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  transform: translateY(-2px);
}
```

### A.2 新建主操作按钮

```css
.my-primary-btn {
  padding: 12px 16px;
  background: linear-gradient(135deg, #007AFF 0%, #0051D5 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 600;
  box-shadow: 0 4px 12px rgba(0,122,255,0.25);
  cursor: pointer;
  transition: all 0.2s ease;
}
.my-primary-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,122,255,0.35);
}
.my-primary-btn:active {
  transform: translateY(0);
  box-shadow: 0 2px 8px rgba(0,122,255,0.15);
}
```

### A.3 新建表单输入框

```css
.my-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid rgba(0,0,0,0.1);
  border-radius: 10px;
  font-size: 14px;
  color: var(--text-primary);
  background: var(--bg-secondary);
  transition: all 0.2s ease;
  font-family: inherit;
}
.my-input:focus {
  outline: none;
  border-color: var(--color-primary);
  background: var(--bg-primary);
  box-shadow: 0 0 0 3px rgba(0,122,255,0.1);
}
```

### A.4 新建对话框

```css
/* 遮罩 */
.my-overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  z-index: 1000;
  animation: fadeIn 0.2s ease;
}
/* 面板 */
.my-dialog {
  background: var(--bg-primary);
  border-radius: 16px;
  max-width: 90%; max-height: 90vh;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3);
  animation: slideUp 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}
```

---

## 附录 B：变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-04-04 | 首版，覆盖色彩/字体/间距/圆角/阴影/按钮/卡片/动效/布局/组件/CSS结构/命名/检查清单 |
| v1.1 | 2026-04-04 | 新增 §1.3/1.4 Apple+GenSpark 设计参考要点；§2.3 数据可视化色板；§2.5 暗色模式 Apple 暗色变体；§3.4 特殊文字效果；§8.2~8.3 Dashboard 统计/状态栏卡片；§9 表单系统；§10 对话框系统；§12 图标系统；§13.4 响应式断点；§14.6 进度条；附录A 快速复制代码片段 |
