# 🎨 OctoWork Logo 生成提示词库

> **标准Logo参考图**：`/home/user/webapp/docs/octowork-brand/social-media/icon-only.png`  
> **最后更新**：2026-03-18  
> **用途**：确保品牌一致性，方便后续生成不偏离原始设计

---

## 📋 目录

1. [标准Logo提示词](#标准logo提示词)
2. [完整Logo（带文字）提示词](#完整logo带文字提示词)
3. [变体提示词](#变体提示词)
4. [颜色规范](#颜色规范)
5. [使用说明](#使用说明)

---

## 🎯 标准Logo提示词

### 英文版（推荐使用）

```
A cute cartoon octopus mascot with blue-purple gradient colors. The octopus has:
- Round head with AI brain pattern (neural network circuit lines) visible on top
- Wearing round black-framed glasses
- Large friendly eyes with white highlights
- Gentle smile expression
- Left tentacle giving thumbs up gesture
- Right tentacle making OK hand sign (thumb and index finger forming circle)
- 8 tentacles total with suction cups visible
- Blue to purple gradient: light blue (#4169E1) on head transitioning to purple (#9370DB) on lower tentacles
- Smooth cartoon style with clean outlines
- White or transparent background
- No text, icon only
- Square format, centered composition
```

### 中文版（备用）

```
可爱的卡通章鱼吉祥物，蓝紫渐变色。章鱼特征：
- 圆形头部，顶部有AI大脑图案（神经网络电路线条）
- 戴着圆形黑框眼镜
- 大而友好的眼睛，带白色高光
- 温和的微笑表情
- 左侧触手竖大拇指
- 右侧触手做OK手势（拇指和食指形成圆圈）
- 总共8条触手，触手上有吸盘
- 蓝紫渐变：头部浅蓝色（#4169E1）过渡到下方紫色（#9370DB）
- 流畅的卡通风格，清晰的轮廓线
- 白色或透明背景
- 无文字，仅图标
- 方形格式，居中构图
```

---

## 📝 完整Logo（带文字）提示词

### 英文版

```
A complete brand logo with two parts:

TOP PART - Octopus Icon:
- Cute cartoon octopus mascot
- Blue-purple gradient colors (light blue #4169E1 to purple #9370DB)
- Round head with AI brain pattern (neural network lines) on top
- Wearing round black-framed glasses
- Large friendly eyes with white highlights
- Gentle smile
- Left tentacle: thumbs up gesture
- Right tentacle: OK hand sign
- 8 tentacles total with visible suction cups
- Cartoon style with clean outlines

BOTTOM PART - Text:
- "OctoWork" text below the octopus
- "Octo" in blue-purple gradient (#4169E1 to #9370DB)
- "Work" in dark gray (#333333) or black
- Modern rounded sans-serif font
- Clean and professional typography

LAYOUT:
- Octopus icon centered on top
- Text "OctoWork" centered below
- White or light background
- Balanced vertical composition
- Square or portrait format
```

### 中文版

```
完整的品牌Logo，包含两部分：

上部分 - 章鱼图标：
- 可爱的卡通章鱼吉祥物
- 蓝紫渐变色（浅蓝色#4169E1到紫色#9370DB）
- 圆形头部，顶部有AI大脑图案（神经网络线条）
- 戴着圆形黑框眼镜
- 大而友好的眼睛，带白色高光
- 温和的微笑
- 左侧触手：竖大拇指
- 右侧触手：OK手势
- 总共8条触手，触手上有吸盘
- 卡通风格，清晰的轮廓线

下部分 - 文字：
- 章鱼下方显示"OctoWork"文字
- "Octo"使用蓝紫渐变色（#4169E1到#9370DB）
- "Work"使用深灰色（#333333）或黑色
- 现代圆润的无衬线字体
- 清晰专业的排版

布局：
- 章鱼图标居中在上方
- "OctoWork"文字居中在下方
- 白色或浅色背景
- 垂直构图平衡
- 方形或竖版格式
```

---

## 🎨 变体提示词

### 1. 深色模式Logo

```
[使用标准Logo提示词] + "dark mode version, white outline, suitable for dark backgrounds, background color #1a1a1a or #2d2d2d"
```

### 2. 单色版Logo（用于印章、水印）

```
[使用标准Logo提示词] + "monochrome version, single color navy blue (#2c3e50), no gradients, simple flat design"
```

### 3. 线条版Logo（简化版）

```
[使用标准Logo提示词] + "line art version, outline only, no fill colors, vector style, minimalist design"
```

### 4. 3D立体版Logo

```
[使用标准Logo提示词] + "3D render style, soft lighting, slight shadows, glossy surface, modern 3D look"
```

### 5. 像素风格Logo

```
[使用标准Logo提示词] + "pixel art style, 8-bit retro gaming aesthetic, pixelated edges"
```

### 6. 手绘风格Logo

```
[使用标准Logo提示词] + "hand-drawn illustration style, sketch-like lines, watercolor texture"
```

---

## 🎨 颜色规范

### 主色调

| 颜色名称 | HEX | RGB | 用途 |
|---------|-----|-----|------|
| 主蓝色 | `#4169E1` | `65, 105, 225` | 章鱼头部、渐变起点 |
| 主紫色 | `#9370DB` | `147, 112, 219` | 章鱼触手、渐变终点 |
| 青绿色（辅助） | `#20B2AA` | `32, 178, 170` | 高光、强调元素 |

### 辅助色

| 颜色名称 | HEX | RGB | 用途 |
|---------|-----|-----|------|
| 深灰色 | `#333333` | `51, 51, 51` | "Work"文字、轮廓线 |
| 纯白色 | `#FFFFFF` | `255, 255, 255` | 背景、眼睛高光 |
| 浅灰色 | `#F5F5F5` | `245, 245, 245` | 可选背景色 |

### 渐变配置

```css
/* 主渐变 */
background: linear-gradient(180deg, #4169E1 0%, #9370DB 100%);

/* 或使用角度渐变 */
background: linear-gradient(135deg, #4169E1 0%, #9370DB 100%);
```

---

## 🔑 关键设计元素

### 必须包含的元素（核心特征）

1. ✅ **AI大脑图案**：头部顶端的神经网络线条
2. ✅ **圆形眼镜**：黑框，彰显智能感
3. ✅ **左手大拇指**：竖起大拇指手势
4. ✅ **右手OK手势**：拇指和食指形成圆圈
5. ✅ **8条触手**：象征多任务能力
6. ✅ **触手吸盘**：触手上的圆形吸盘细节
7. ✅ **蓝紫渐变**：从蓝色到紫色的自然过渡
8. ✅ **友好微笑**：温和的表情

### 可选元素

- 🔵 背景颜色（白色/透明/浅灰）
- 🔵 轮廓线粗细
- 🔵 高光位置和强度
- 🔵 触手姿态的微调

---

## 📐 尺寸规范

### 推荐生成尺寸

| 用途 | 尺寸 | 格式 | 备注 |
|------|------|------|------|
| 网站图标 | 512×512 | PNG | 高清显示 |
| 社交媒体头像 | 400×400 | PNG | Twitter/GitHub/LinkedIn |
| Favicon | 192×192 | PNG | 浏览器图标 |
| App图标 | 1024×1024 | PNG | iOS/Android应用 |
| 印刷海报 | 4096×4096 | PNG | 高分辨率打印 |

---

## 🛠️ 使用说明

### 1. 如何使用提示词

**方法A：直接复制粘贴**
```bash
# 复制"标准Logo提示词"中的英文版
# 粘贴到图片生成工具（如Midjourney、DALL-E、Stable Diffusion等）
```

**方法B：参考图片+提示词**
```bash
# 上传参考图：/home/user/webapp/docs/octowork-brand/social-media/icon-only.png
# 添加提示词："Generate a logo similar to this image, keep the same style"
```

**方法C：使用变体提示词**
```bash
# 选择"标准Logo提示词" + 一个"变体提示词"
# 例如：[标准提示词] + "dark mode version..."
```

### 2. 生成后的质量检查

检查以下要点，确保生成的Logo符合标准：

✅ **颜色检查**
- 头部是否为蓝色（#4169E1附近）
- 触手是否为紫色（#9370DB附近）
- 渐变过渡是否自然

✅ **元素检查**
- AI大脑图案是否清晰可见
- 眼镜是否为圆形黑框
- 左手是否竖大拇指
- 右手是否做OK手势
- 触手是否为8条

✅ **风格检查**
- 卡通风格是否一致
- 轮廓线是否清晰
- 表情是否友好

✅ **背景检查**
- 背景是否为白色或透明
- 构图是否居中

### 3. 常见问题解决

**问题1：颜色不对**
```
解决方案：在提示词中明确指定HEX颜色值
添加："exact colors: head #4169E1, tentacles #9370DB"
```

**问题2：手势错误**
```
解决方案：强调手势细节
添加："left tentacle clearly showing thumbs up, right tentacle making OK sign with thumb and index finger touching"
```

**问题3：风格偏差**
```
解决方案：强调参考图
添加："maintain the exact same cartoon style as shown in reference image"
```

**问题4：触手数量不对**
```
解决方案：明确指定数量
添加："exactly 8 tentacles, count carefully: 2 front (gestures), 6 background"
```

---

## 📦 标准文件引用

### 当前标准Logo文件

```
纯Logo图标（无文字）：
/home/user/webapp/docs/octowork-brand/social-media/icon-only.png
尺寸：1024×1024
格式：PNG
大小：863 KB

完整Logo（带文字）：
/home/user/webapp/docs/octowork-brand/social-media/profile-github.png
尺寸：400×400
格式：PNG

网站Logo：
/home/user/webapp/docs/octowork-brand/website/hero-icon.png
尺寸：256×256
格式：PNG
```

### 生成历史记录

| 日期 | 版本 | 模型 | 文件路径 | 备注 |
|------|------|------|----------|------|
| 2026-03-18 | v1.0 | nano-banana-pro | `social-media/icon-only.png` | ✅ 标准版 |
| 2026-03-18 | v1.0 | nano-banana-pro | `social-media/profile-github.png` | 带文字版 |
| 2026-03-18 | v1.0 | ImageMagick | `website/*` | 多尺寸版本 |

---

## 🔄 更新日志

### v1.0 - 2026-03-18
- ✅ 创建标准Logo提示词（英文+中文）
- ✅ 创建完整Logo提示词（带文字版本）
- ✅ 添加6种变体提示词
- ✅ 定义颜色规范和设计元素
- ✅ 提供详细使用说明和问题解决方案

---

## 📞 联系方式

如需修改或更新Logo设计，请：
1. 参考此文档中的提示词
2. 保存新生成的Logo到对应目录
3. 更新本文档中的"生成历史记录"表格
4. 更新版本号和更新日志

---

**🐙 OctoWork - 让AI团队协作更简单**

---

## 附录：AI模型使用建议

### 推荐模型（按优先级）

1. **nano-banana-pro** ⭐⭐⭐⭐⭐
   - 优点：卡通风格一致，颜色还原度高
   - 适用场景：所有Logo生成
   - 本项目使用的主力模型

2. **DALL-E 3**
   - 优点：细节精细，遵循提示词准确
   - 适用场景：需要精确控制时

3. **Midjourney v6**
   - 优点：艺术风格强，可用于海报设计
   - 适用场景：营销物料、创意海报

4. **Stable Diffusion XL**
   - 优点：开源免费，可本地运行
   - 适用场景：批量生成、自定义训练

### 不推荐的模型

❌ **Midjourney v5** - 风格不够卡通
❌ **DALL-E 2** - 细节不够清晰
❌ **Stable Diffusion 1.5** - 颜色还原度差

---

**文档结束**
