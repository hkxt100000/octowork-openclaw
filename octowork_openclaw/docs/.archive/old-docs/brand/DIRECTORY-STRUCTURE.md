# OctoWork 品牌资源目录结构

```
docs/octowork-brand/
│
├── 📄 README.md                          # 完整Logo规格清单（120个文件详细说明）
├── 📄 GENERATION-CHECKLIST.md           # 简化执行清单（分优先级）
│
├── 🌐 website/                           # 网站Logo（9个文件）
│   ├── header-logo.png                   # Header横版Logo 200×60px
│   ├── header-logo@2x.png                # Header高清版 400×120px
│   ├── header-logo-dark.png              # Header深色背景版 200×60px
│   ├── header-logo-dark@2x.png           # Header深色高清版 400×120px
│   ├── footer-logo.png                   # Footer小Logo 150×45px
│   ├── footer-logo@2x.png                # Footer高清版 300×90px
│   ├── hero-logo.png                     # 首页大Logo 400×120px
│   ├── hero-icon.png                     # 纯图标 256×256px
│   └── hero-icon@2x.png                  # 纯图标高清 512×512px
│
├── 📱 app-icons/                         # 应用图标（39个文件）
│   ├── iOS/
│   │   ├── ios-1024.png                  # App Store 1024×1024px
│   │   ├── ios-180.png                   # iPhone主屏 180×180px
│   │   ├── ios-167.png                   # iPad Pro 167×167px
│   │   ├── ios-152.png                   # iPad 152×152px
│   │   ├── ios-120.png                   # iPhone 120×120px
│   │   └── ... (共13个iOS尺寸)
│   │
│   ├── Android/
│   │   ├── android-512.png               # Google Play 512×512px
│   │   ├── android-192.png               # xxxhdpi 192×192px
│   │   └── ... (共6个Android尺寸)
│   │
│   ├── Windows/
│   │   ├── windows-310.png               # 大磁贴 310×310px
│   │   └── ... (共4个Windows尺寸)
│   │
│   └── macOS/
│       ├── macos-1024.png                # Retina 1024×1024px
│       └── ... (共7个macOS尺寸)
│
├── 🌍 social-media/                      # 社交媒体（17个文件）
│   ├── Profiles/
│   │   ├── profile-twitter.png           # Twitter头像 400×400px
│   │   ├── profile-linkedin.png          # LinkedIn头像 400×400px
│   │   ├── profile-github.png            # GitHub头像 500×500px
│   │   ├── profile-wechat.png            # 微信公众号 500×500px
│   │   └── ... (共7个平台头像)
│   │
│   ├── Banners/
│   │   ├── banner-twitter.png            # Twitter封面 1500×500px
│   │   ├── banner-linkedin-company.png   # LinkedIn公司页 1128×191px
│   │   └── ... (共5个封面)
│   │
│   └── OG-Images/
│       ├── og-image.png                  # 分享缩略图 1200×630px
│       └── og-image-square.png           # 方形缩略图 1200×1200px
│
├── 🖨️ print-materials/                   # 印刷物料（13个文件）
│   ├── BusinessCards/
│   │   ├── business-card-front.png       # 名片正面 1050×600px
│   │   ├── business-card-back.png        # 名片背面 1050×600px
│   │   └── business-card-logo.png        # 名片Logo 300×90px
│   │
│   ├── Posters/
│   │   ├── poster-a4.png                 # A4海报 2480×3508px
│   │   ├── poster-a3.png                 # A3海报 3508×4961px
│   │   └── poster-a2.png                 # A2海报 4961×7016px
│   │
│   ├── Banners/
│   │   ├── rollup-banner-80x200.png      # 易拉宝 2362×5906px
│   │   └── ... (共2个)
│   │
│   ├── Backdrops/
│   │   ├── backdrop-3x2m.png             # 背景板3×2米
│   │   └── backdrop-6x3m.png             # 背景板6×3米
│   │
│   └── Stickers/
│       ├── sticker-round-50mm.png        # 圆形贴纸 591×591px
│       └── ... (共3个)
│
├── 📊 presentation/                      # 演示文稿（8个文件）
│   ├── ppt-title-slide.png               # PPT标题页 1920×1080px
│   ├── ppt-header-logo.png               # PPT页眉Logo 400×120px
│   ├── ppt-icon.png                      # PPT图标 256×256px
│   ├── ppt-background.png                # PPT背景 1920×1080px
│   ├── pdf-cover-logo.png                # PDF封面Logo 800×240px
│   ├── pdf-header-logo.png               # PDF页眉Logo 300×90px
│   ├── pdf-watermark.png                 # PDF水印 400×400px
│   └── presentation-16-9.png             # 标准演示 1920×1080px
│
├── 🔖 favicon/                           # 网站图标（25个文件）
│   ├── favicon.ico                       # 多尺寸ICO文件
│   ├── favicon-16.png                    # 16×16px
│   ├── favicon-32.png                    # 32×32px
│   ├── favicon-48.png                    # 48×48px
│   ├── favicon-64.png                    # 64×64px
│   ├── favicon-128.png                   # 128×128px
│   │
│   ├── Apple/
│   │   ├── apple-touch-icon.png          # iOS书签 180×180px
│   │   ├── apple-touch-icon-152.png      # iPad 152×152px
│   │   └── ... (共9个Apple Touch Icon)
│   │
│   ├── Android/
│   │   ├── android-chrome-192.png        # Android主屏 192×192px
│   │   └── android-chrome-512.png        # Android启动 512×512px
│   │
│   └── Microsoft/
│       ├── mstile-150.png                # Windows磁贴 150×150px
│       └── ... (共4个Microsoft磁贴)
│
└── 📦 source/                            # 源文件（9个文件）
    ├── Vector/
    │   ├── octowork-logo-master.svg      # 主Logo矢量源文件
    │   ├── octowork-icon-only.svg        # 纯图标SVG
    │   ├── octowork-horizontal.svg       # 横版Logo SVG
    │   ├── octowork-vertical.svg         # 竖版Logo SVG
    │   ├── octowork-monochrome.svg       # 单色版SVG
    │   └── octowork-white.svg            # 白色版SVG
    │
    ├── DesignFiles/
    │   ├── octowork-logo-master.ai       # Adobe Illustrator
    │   ├── octowork-logo-master.sketch   # Sketch文件
    │   └── octowork-logo-master.figma    # Figma链接
    │
    └── Guidelines/
        ├── brand-guideline.pdf            # 品牌使用指南
        ├── color-palette.png              # 标准色彩板
        ├── typography-guide.png           # 字体指南
        └── spacing-guide.png              # 间距规范
```

---

## 📊 文件数量统计

| 分类 | 文件数 | 说明 |
|-----|--------|------|
| 🌐 网站Logo | 9 | 页眉、页脚、首页大Logo |
| 📱 应用图标 | 39 | iOS(13) + Android(6) + Windows(4) + macOS(16) |
| 🌍 社交媒体 | 17 | 头像(7) + 封面(5) + OG图(2) + 国内平台(3) |
| 🖨️ 印刷物料 | 13 | 名片、海报、展架、贴纸 |
| 📊 演示文稿 | 8 | PPT、PDF相关 |
| 🔖 Favicon | 25 | 浏览器、iOS、Android、Windows图标 |
| 📦 源文件 | 9 | SVG、设计文件、品牌指南 |
| **总计** | **120** | **所有尺寸和格式** |

---

## 🎯 优先级分级

### ⭐⭐⭐ 第一优先级（核心必需）
**22个文件 - 本周完成**

```
✓ 网站基础（9个）
  └─ Header、Footer、Hero Logo + 图标

✓ Favicon基础（6个）  
  └─ 16px, 32px, 48px, iOS, Android

✓ 社交媒体头像（7个）
  └─ Twitter, LinkedIn, GitHub, 微信, 微博, OG图×2
```

### ⭐⭐ 第二优先级（近期需要）
**35个文件 - 2周内完成**

```
✓ iOS完整图标套（13个）
✓ Android图标套（6个）
✓ 社交媒体封面（5个）
✓ 演示文稿（8个）
✓ 名片+基础海报（4个）
```

### ⭐ 第三优先级（按需生成）
**63个文件 - 按需生成**

```
✓ 完整Favicon套装（剩余19个）
✓ Windows/macOS图标（20个）
✓ 印刷物料扩展（9个）
✓ 源文件完整套（9个）
```

---

## 📌 重要说明

1. **所有目录已创建**，等待文件填充
2. **详细清单**见 `README.md`
3. **执行清单**见 `GENERATION-CHECKLIST.md`
4. **优先生成**第一优先级的22个文件
5. **批量生成**可使用自动化脚本或AI工具

---

**创建时间：2026-03-18**
**状态：目录结构已就绪，等待Logo生成**
