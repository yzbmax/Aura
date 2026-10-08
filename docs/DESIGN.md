# 「Aura · 同频」UI/UX 视觉与交互设计规范 (Design System Specification)

> **版本**：v1.0 (生产落地版) · **日期**：2026-09-17
> **设计哲学**：**"暖科技 · 柔和光感 · 心流呼吸" (Warm Technology & Immersive Flow)**
> **技术基准**：HarmonyOS NEXT (API 24 / 6.1.1 Release) · ArkUI V2 (`@ComponentV2`) · UI Design Kit (`@kit.UIDesignKit`)

---

## 目录

1. [设计哲学与核心隐喻](#1-设计哲学与核心隐喻)
 - 1.1 品牌核心理念与视觉映射
 - 1.2 宽屏工作台视觉主形态 (Soft-Bento Workbench)
 - 1.3 手机端专属响应规范：自适应时间轴纵向心流架构 (Mobile Flow Spine Architecture)
 - 1.4 多端响应式断点联动矩阵 (Responsive Breakpoint Matrix)
2. [设计变量体系 (Design Tokens)](#2-设计变量体系-design-tokens)
 - 2.1 昼夜节律双模色彩系统 (Circadian Dual-Theme Palette & WCAG AA)
 - 2.2 材质与光影规范 (Materials & Elevation)
 - 2.3 字体排版系统 (Typography)
 - 2.4 空间与圆角栅格 (Space & Geometry)
 - 2.5 高精密度微晶组件与纹理系统 (Precision Micro-Elements & Textures)
3. [动效与物理动力学 (Motion & Physics)](#3-动效与物理动力学-motion--physics)
 - 3.1 流体阻尼弹簧曲线
 - 3.2 渐进式雾化开合规范 (Progressive Mist & GPU Safety)
 - 3.3 华为 HDS 5 大沉浸光影视效规范矩阵 (`@kit.UIDesignKit`)
4. [PRD 核心业务场景交互细化](#4-prd-核心业务场景交互细化)
 - 4.1 【5 分钟破冰船】：卡片原位微脉动与禅意融化沙漏
 - 4.2 【杂念停机坪】：快录微胶囊与轻烟气雾吸入 (Mist Ingestion)
 - 4.3 【多巴胺和弦阶梯】：游丝高光波与星尘消散
 - 4.4 【晚间打烊仪式】：暮光雾帘合拢与冷冻舱冰霜结晶
 - 4.5 【自适应时间轴】：Structured 纵向主轴线与留白透气框
 - 4.6 矢量图标规范（严禁使用 Emoji）
5. [多感官协同规范 (Sensory Design)](#5-多感官协同规范-sensory-design)
 - 5.1 纯净和弦音频采样 (`soundPool` / Web Audio)
 - 5.2 解压微触感振动脉冲 (`vibrator`)
6. [ArkUI V2 生产级参考实现](#6-arkui-v2-生产级参考实现)
 - 6.1 HDS 沉浸光感悬浮导航 (`HdsTabs`)
 - 6.2 雾化开合破冰卡片 (`MistMorphingCard`)
 - 6.3 手机端自适应心流主视图 (`AuraTodayMobileView`)
 - 6.4 底部 HDS 悬浮微晶胶囊导航与手势避让 (`HdsFloatingDock`)
7. [性能约束与功耗防线 (Performance Guardrails)](#7-性能约束与功耗防线-performance-guardrails)

---

## 1. 设计哲学与核心隐喻

### 1.1 品牌核心理念与视觉映射
传统待办类应用充斥着“红字警报、机械划线、密集表格、冰冷弹窗”，在无形中给用户施加心理压迫，导致“启动畏难”与“逾期内疚”。

「Aura · 同频」主张 **暖科技 (Warm Technology / Soft Sci-Fi)**：
* **消灭冰冷**：用“柔和晨雾、温润玉石、暮光微光”取代生硬的黑白灰与刺眼霓虹。
* **消灭突兀**：界面元素如同具有表面张力的水膜与气态烟雾，在开合展开时产生自然平滑的渐进虚化与粘滞形变。
* **双核驱动美学架构**：
 1. **全局骨架**：深度继承华为官方 **HDS（HarmonyOS Design System）沉浸光感**，利用 `@kit.UIDesignKit` 带来系统级悬浮通透感、点光源交互与最优功耗控制；
 2. **关键动效**：吸纳折叠屏概念中的 **“开合渐进雾化（Progressive Mist）”** 与 **流体光晕**，在破冰、打烊、和弦反馈等高潮节点提供震撼仪式感。

### 1.2 宽屏工作台视觉主形态：HDS 微晶心流工作台 (大屏/折叠展开态)
针对 1060vp 宽屏、折叠屏展开态与平板等大视口，Aura 采用 **"HDS Flow Workbench"**：
1. **左侧深墨悬浮控制舱 (Deep Charcoal Capsule Nav)**：
 * 宽 110vp、背景 `#1B1E26` 的深空墨色磨砂半透明胶囊垂直悬浮于左侧，严格遵循 PRD 黄金 3 Tab 架构（今日心流、任务视界、偏好设置），底部集成 18:30 晚间打烊快捷关机舱。
2. **右侧温润微晶大画板 (HDS Flow Canvas)**：
 * 32vp 大圆角温润主舞台，采用分层柔和漫反射多层阴影（`0 12px 36px rgba(0,0,0,0.06)`），杜绝生硬描边。
3. **头部概况与脑力负荷罗盘 (Daily Flow Summary)**：
 * 主标题 `Let's start strong!` 搭配当前脑力负荷 `2.8h / 4.5h (45%)` 细线渐变微光进度卡片；
 * 常驻 36vp 杂念快录微胶囊，输入回车秒级吸入落盘机动池。
4. **核心自适应时间轴大看板 (Structured Master Timeline)**：
 * 大屏中央呈现 Structured 纵向双列时间轴与甘特块，展示全天会议锁定块、算法排期任务块与 15m 留白呼吸带；
 * 右侧抽屉展示【机动备选池】与【精力昼夜洞察】，支持直接拖拽入时间轴。

---

### 1.3 手机端专属响应规范：自适应时间轴纵向心流架构 (Mobile Flow Spine Architecture)

遵循 HarmonyOS NEXT “一次开发、多端部署” 原则，在 390~412vp 竖屏手机视口中，Aura 坚守**“待办本位与心智减负”**核心，消灭花哨的仪表盘喧宾夺主，将 **65% 以上黄金屏幕视域归还给自适应时间轴**：

#### 1.3.1 手机端设计意图与心智减负 (Core Focus & Ergonomics)
* **待办主线为先**：用户打开 App 的第一眼，必须清晰知晓“当前正在做什么、下一个是什么、何时留白休息”，拒绝让纯静态图表霸屏；
* **悬浮底栏避让**：原侧边栏功能收拢为**底部居中悬浮的 HDS 微晶胶囊 Dock (`HdsFloatingDock`)**，正处于大拇指黄金落点区；
* **安全区强制避让**：底栏底部强制集成系统手势导航条避让垫片（`safeArea` 避让），彻底杜绝与鸿蒙系统全屏返回桌面横条发生触控冲突。

#### 1.3.2 沉浸微晶顶栏 (Mobile HDS Nav)
* **尺寸与布局**：高度 52vp，水平两端对齐（`Row()`, `justifyContent: FlexAlign.SpaceBetween`）；
* **左侧品牌微标**：28vp 圆形微晶图标（内嵌 1.6px 细线 Aura `A` 渐变线性 SVG）+ `Aura · 今日心流`（15fp，`FontWeight.Medium`）；
* **右侧脑力负荷微胶囊**：30vp 高度半透微晶胶囊，内置极简钟表微标与 `2.8h / 4.5h` 文本（12fp，暮光紫），动态反映当日脑力池占用比例。

#### 1.3.3 问候与杂念秒级停泊胶囊 (Hero & Rapid Parking Bar)
* **紧凑问候区**：高度缩敛至 32vp，柔和文本 `“早安，今日已装箱 3 个核心时间块，舒适留白 45m”`（13fp，次要文本色）；
* **常驻杂念快录胶囊**：
 * 高度 36vp，全圆角微晶胶囊底衬（`rgba(255, 255, 255, 0.08)`）；
 * 占位符：`“闪现杂念？敲回车秒停泊 ”`；
 * 敲击回车瞬间触发文字轻烟吸入消融动画，数据落盘本地 SQLite 机动池，保持当前专注心流零中断。

#### 1.3.4 自适应时间轴主战场 (Structured Flow Spine - 65%+ 视域)
作为首页核心主视觉，采用 Structured 纵向贯通主轴设计：
* **纵向时间脊柱 (Spine Axis)**：
 * 左侧贯通一根 1.5px 静谧微光导轨实线，任务节点采用 38vp 柔光微晶圆珠徽章（会议日程、深度攻坚、留白茶盏）；
 * 正在进行中的时间块节点触发 0.8Hz 环形呼吸微光；
* **自适应任务时间块微晶卡片**：
 * 卡片呈现：时段 `09:30 - 10:15 (45m)`、任务标题、子任务进度微标（` 1/3`）；
 * 右侧配置统一直径 22vp 的极简圆环勾选圈，完成时触发和弦与微触感；
 * 视口停留 $\ge 3.5\text{s}$ 触发卡片边缘微脉动：“试试 5 分钟？”，点击原位形变为融化微沙漏，无任何切页撕裂感；
* **留白透气卡片 (Free-Time Cushion)**：
 * 任务间 15~30m 空白自动渲染为虚线导轨引导的留白卡片（` 15m 留白透气 · 喝杯温水`），提供心理缓冲空间。

#### 1.3.5 机动备选池折叠抽屉 (Floating Deck Drawer)
* 位于时间轴下方，收拢所有 `scheduled_start_at = 0` 的弹性事项与今日停泊杂念；
* 支持一键展开/收起，可将杂念直接拖拽或点击分配至时间轴空闲缝隙。

#### 1.3.6 底部 HDS 悬浮微晶胶囊底栏与安全区避让 (Floating Bottom Capsule Dock)
* **物理规格**：宽度自适应屏幕 90%（约 345~360vp），高度 54vp，圆角 27vp，悬浮脱离屏幕底部 16vp；
* **手势防冲突避让**：在系统开启全屏手势导航时，自动叠加系统安全区底部高度（`safeAreaBottom`），垫高底栏位置，杜绝误触；
* **黄金 3 Tab 架构（严格对齐 PRD）**：
 1. `今日心流`（自适应时间轴看板、脑力进度、机动池、打烊入口）；
 2. `任务视界`（四象限矩阵、全部待办清单、底部折叠冷冻舱）；
 3. `偏好设置`（排期偏好、感官音效、**已收集个人信息清单、第三方共享清单、撤回同意、账号注销** —— 坚决守护华为应用市场审核红线）。

---

### 1.4 多端响应式断点联动矩阵 (Responsive Breakpoint Matrix)

遵循 HarmonyOS 官方多端适配规范，Aura 针对不同屏幕宽度动态切换最舒适的布局拓扑：

| 断点标识 (Breakpoint) | 视口宽度范围 (Width vp) | 目标典型设备 | 布局拓扑结构 | 导航呈现模式 | 核心操作流 |
|---|---|---|---|---|---|
| **sm (Compact)** | `< 600 vp` | 华为直板手机 (Mate 70 / Pura 70)、外屏折叠态 | 单列纵向时间轴流 (Single Column Flow Spine) | 底部悬浮 HDS 微晶胶囊 Dock (3 Tab + 手势安全避让) | 卡片原位 5m 微脉动与沙漏形变 |
| **md (Medium)** | `600 ~ 840 vp` | 折叠屏内屏展开态 (Mate X5 / X6 方屏) | 双列响应式画板 (时间轴 + 机动备选池) | 左侧紧凑胶囊导航栏 (3 Tab 图标居中) | 左右拖拽装箱与原位沙漏 |
| **lg (Expanded)** | `> 840 vp` | 平板 (MatePad Pro)、PC 二合一终端、智慧大屏 | 经典宽屏工作台 (左侧深墨胶囊导航 + 右侧时间块大看板) | 左侧展开式胶囊菜单 + 晚间打烊快捷关机舱 | 宽屏甘特视图与多端流转甩单 |

---

## 2. 设计变量体系 (Design Tokens)

### 2.1 昼夜节律双模色彩系统 (Circadian Dual-Theme Palette)
Aura 拒绝死黑（#000000）与刺眼纯白（#FFFFFF），色彩根据昼夜模式自适应调优：

#### 2.1.1 暗夜深空调色盘 (Dark Mode)
| 语义变量名 | 色值 Hex / RGBA | 对应色相 | 核心应用场景 |
|---|---|---|---|
| `COLOR_BG_DEEP` | `#0E1015` | 深空墨底 | 全局应用主底色（低对比度护眼深色） |
| `COLOR_BG_SUNSET` | `#151322` | 暮光幽紫 | 18:30 晚间打烊与静谧夜间模式底衬 |
| `COLOR_DAWN_CYAN` | `#70A9A1` | 清心天青 | 晨间 09:00 开工光感、低认知/日常任务主色 |
| `COLOR_FLOW_VIOLET`| `#9D8DF1` | 暮光幻紫 | 5分钟破冰船、深度攻坚时间块、边缘主流光、核心高光（无橙色） |
| `COLOR_REST_SAGE` | `#95B8A2` | 鼠尾草绿 | 强制呼吸缓冲带、已完成安抚状态 |
| `COLOR_FROST_BLUE`| `#8FA2B0` | 晨雾冰蓝 | 冷冻舱休眠任务、次级辅助说明标签 |
| `COLOR_TEXT_PRIMARY`| `rgba(255, 255, 255, 0.95)` | 柔白 | 核心主标题、重点时间、任务主体 (对比度 16.5:1) |
| `COLOR_TEXT_SECONDARY`| `rgba(255, 255, 255, 0.65)`| 灰白 | 副标题、标签、非活动态描述 (对比度 7.2:1) |
| `COLOR_TEXT_TERTIARY` | `rgba(255, 255, 255, 0.45)`| 明暗白 | 留白时间提示、已沉底完成事项 (严格满足 WCAG AA ≥4.5:1) |

#### 2.1.2 晨曦微晶白调色盘 (Light Mode - 满足 WCAG AA 规范)
> 拒绝“惨白盲光与模糊不清”，采用**温润纯血微晶白 + 强边界漫反射 + 高对比度文本**：

| 语义变量名 | 色值 Hex / RGBA | 对应色相 | 核心应用场景与对比度说明 |
|---|---|---|---|
| `LIGHT_BG_CANVAS` | `#F1F4F9` | 浅云灰青 | 全局主画布（温润明亮，杜绝发灰与强光眩目） |
| `LIGHT_BG_SUNSET` | `#E8E4F0` | 暮光紫霞 | 亮色下的打烊沉浸背景底色 |
| `LIGHT_DAWN_CYAN` | `#1A7A6E` | 墨玉天青 | 晨间/日常任务色（在白底上达到 5.1:1 高对比度） |
| `LIGHT_FLOW_VIOLET`| `#5B4BD8` | 皇家鸢尾紫 | 核心破冰高光、沙漏微光（在白底上达到 6.2:1 对比度） |
| `LIGHT_REST_SAGE` | `#3D6E4E` | 幽兰草绿 | 留白缓冲带文本与状态 |
| `LIGHT_CARD_BG` | `rgba(255, 255, 255, 0.92)`| 纯透微晶白 | 卡片基底，内嵌 0.5px 精致边界折射，拒绝白融融一片 |
| `LIGHT_CARD_BORDER`| `rgba(25, 28, 33, 0.08)` | 微晶漫反射边 | 卡片边界，强化物理分层感 |
| `LIGHT_TEXT_PRIMARY`| `#14171E` | 浓黛墨色 | 核心文字（温润深墨，对比度高达 14.8:1） |
| `LIGHT_TEXT_SECONDARY`| `#485264`| 深铅灰 | 任务次要信息、标签、未选态说明 (对比度 7.1:1) |
| `LIGHT_TEXT_TERTIARY` | `#5A6474`| 暮沙灰 | 刻度、提示性留白字、时间轴标记 (严格满足 WCAG AA 4.8:1) |

---

### 2.2 材质与光影规范 (Materials & Elevation)

#### 材质分级（严格映射 HDS Material）
1. **Level 1 · 悬浮胶囊材质（Ultra Material）**：
 * 应用于 `HdsTabs` 底部悬浮胶囊与 `HdsNavigation` 沉浸顶栏；
 * 属性：`materialType: hdsMaterial.MaterialType.IMMERSIVE`，`materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE`；
 * 背景混合：`rgba(255, 255, 255, 0.12)`，背景模糊半径 45vp。
2. **Level 2 · 时间块卡片材质（Glass Card）**：
 * 应用于自适应时间轴看板中的任务卡片；
 * 暗色样式：`backgroundBlurStyle(BlurStyle.Thin)` + `backgroundColor('rgba(255, 255, 255, 0.05)')` + 边框 `0.5px solid rgba(255, 255, 255, 0.16)`；
 * 亮色样式：`backgroundColor('rgba(255, 255, 255, 0.92)')` + 边框 `0.5px solid rgba(25, 28, 33, 0.08)` + 阴影 `0 4px 16px rgba(16, 24, 40, 0.04)`。
3. **Level 3 · 冰霜休眠材质（Frosted Cold Deck）**：
 * 应用于逾期 8 天以上的“冷冻舱”事项；
 * 样式：`backgroundBlurStyle(BlurStyle.Regular)` + 结霜蒙层 `rgba(143, 162, 176, 0.14)`。

#### 阴影与微光规范
* **普通微晶阴影**：`shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.06)', offsetY: 4 })`
* **呼吸光晕阴影（破冰高光）**：`shadow({ radius: 28, color: 'rgba(157, 141, 241, 0.28)', offsetY: 2 })`

---

### 2.3 字体排版系统 (Typography)
基于 HarmonyOS Sans 字体，通过粗细阶梯与清晰对比建立空间层次感：

| 层级 | 字号 (fp) | 字重 (FontWeight) | 颜色 Token | 场景说明 |
|---|---|---|---|---|
| **Display** | 28 | Bold | `COLOR_TEXT_PRIMARY` | 打烊仪式时长数字、破冰船完成标题 |
| **Title 1** | 20 | Medium | `COLOR_TEXT_PRIMARY` | 页面大标题（今日心流、任务视界） |
| **Title 2** | 16 | Medium | `COLOR_TEXT_PRIMARY` | 时间块任务名称、弹窗操作标题 |
| **Body** | 14 | Regular | `COLOR_TEXT_SECONDARY` | 任务副文本、杂念输入框占位符 |
| **Caption** | 11 | Regular | `COLOR_TEXT_TERTIARY` | 时间轴刻度、标签 Chip、缓冲带提示 |

---

### 2.4 空间与圆角栅格 (Space & Geometry)
* **基础栅格**：严格遵循 8vp 倍数原则（4vp 微间隙、8vp、16vp、24vp、32vp）。
* **圆角体系**：
 * **大胶囊与悬浮主容器**：`borderRadius(28vp)`（如 `HdsTabs`、悬浮底栏）；
 * **时间块与内容卡片**：`borderRadius(18vp)`；
 * **微胶囊与输入 Tag**：`borderRadius(16vp)`（如杂念停机坪 36vp 微胶囊）。

### 2.5 核心微晶组件与时间轴视觉规范 (Precision Flow Elements)
剔除冗余厚重的拟物噪点，专注于纯粹、轻量、高质感的心流微交互组件：

1. **脑力负荷环形微晶罗盘 (Circular Brain Dial)**：
 * 位于顶栏右侧，30vp 直径细线环形仪表盘，展示已排时长与 4.5h 脑力上限比例（`stroke-dashoffset` 随装箱调度平滑旋转）。
2. **Structured 纵向主轴线骨架体系 (Structured Flow Spine System)**：
 * **1.5px 微光导轨实线**：纵向贯通整个今日心流主轴，随任务完成状态从上到下动态充能；
 * **38vp 图标圆珠节点**：将会议日历、破冰沙漏、留白茶盏作为主轴锚点节点，形成清晰的手账节律感；
 * **右侧垂直对齐圆环勾选圈**：统一配置 22vp 极简圆环，未完成为空心细圈，勾选时触发 `Do-Mi-Sol-Do'` 纯音与泡泡纸轻震；
 * **精准时段与切片微标**：卡片顶部标明 `09:30 - 10:15 (45m)` 与 `[ 45m 探索切片 ]`，消除体量焦虑。
3. **空白缝隙磁吸卡片与留白呼吸框 (Cushion Cards)**：
 * 任务块之间若存在 15~45 分钟空白，主轴线切换为优雅虚线穿引，浮现带虚线边框的微晶透气框（` 15m 留白透气 · 喝杯温水`），杜绝密恐压迫。
4. **Tiimo 柔和光晕弧 (Halo Arc)**：
 * 任务卡片进入 5 分钟破冰时，原位展开呈现 100vp 直径的暮紫光晕弧，300 秒平滑消融收缩，彻底摒弃催命的红色倒数数字。

---

## 3. 动效与物理动力学 (Motion & Physics)

### 3.1 流体阻尼弹簧曲线
拒绝机械化的 `linear` 或突兀的 `ease-in`。Aura 全量采用 ArkUI 物理弹簧模型：

```typescript
// 1. 核心展开/闭合：温润拉开水膜感（开合雾化核心）
export const SPRING_MIST_OPEN = curves.springMotion(0.48, 0.84);

// 2. 触碰按下微回弹：紧致微晶轻触感
export const SPRING_TOUCH_BOUNCE = curves.responsiveSpringMotion(0.28, 0.72);

// 3. 杂念吸入消融曲线：轻盈向上收缩
export const CURVE_MIST_DISSOLVE = curves.cubicBezierCurve(0.25, 1.0, 0.5, 1.0);
```

---

### 3.2 渐进式雾化开合规范 (Progressive Mist & GPU Safety)
为保证极致丝滑高刷（120fps），系统严禁在 `animateTo` 动画帧中高频动态插值高斯模糊半径（会造成 GPU 着色器反复重编译与显存抖动）。
采用**“离屏预设微晶层 + 物理弹簧形变 + 双向交叉淡入淡出 (Cross-fade)”**方案：

* **收拢常态**：卡片维持固定轻度磨砂 `backgroundBlurStyle(BlurStyle.Thin)`，内容锐利清晰；
* **展开过渡态**：
 * 通过 `curves.springMotion(0.48, 0.84)` 驱动高度形变（从 72vp 平滑扩展至 300vp）；
 * 收拢态内容通过 `opacity: 0` 快速淡出，沙漏场域内容通过 `opacity: 1` 柔和淡入；
 * 底层微光渐变层通过固定参数的 `linearGradientBlur` 一次性烘焙，杜绝连续动态重算。

---

### 3.3 华为 HDS 5 大沉浸光影视效规范矩阵 (`@kit.UIDesignKit`)

| 视效名称 | 官方 API 接口 | 视觉物理表现 | Aura 生产场景 |
|---|---|---|---|
| **1. 点光源 (Point Light)** | `new hdsEffect.HdsEffectBuilder().pointLight({ illuminatedType: BORDER })` | 3D 物理光感，单组件支持 12 个光源，边框跟手折射高光 | 时间块卡片长按/拖拽时，指尖点亮 0.5px 微晶边界 |
| **2. 双边边缘流光 (Edge Streamer)** | `.shaderEffect({ effectType: DUAL_EDGE_FLOW_LIGHT })` | 顶边与底边相对游走的细线光束，两端虚化渐隐 | 5分钟破冰船微脉动、任务和弦完成扫光 |
| **3. 背景流光 (BG Streamer)** | `.shaderEffect({ effectType: BACKGROUND_STREAMER })` | 全域有机位移的大气光斑场，随昼夜色温自然流动 | 全局应用底座、专注场域昼夜氛围底衬 |
| **4. 背景流光遮罩 (Streamer w/ Mask)**| `.mask(...)` 结合背景流光 | 流动的光场被文字或特定轮廓裁剪，在裂隙中渗光 | 杂念停机坪文字气雾吸入消融、沙漏流光通道 |
| **5. HDS 沉浸材质 (Material)** | `HdsTabs` / `HdsNavigation` 设置 `systemMaterialEffect` | 系统级自适应半透明微晶磨砂，底层内容丝滑穿透 | 黄金 3 Tab 悬浮底栏与沉浸式顶栏 |

---

## 4. PRD 核心业务场景交互细化

### 4.1 【5 分钟破冰船】：卡片原位微脉动与禅意融化沙漏
* **微脉动邀约（视口停留 ≥ 3.5s）**：卡片边缘产生 0.8Hz、1.02 倍极柔和呼吸脉动，提示“试试 5 分钟，随时可停”；
* **点击原位形变（Morphing）**：
 * 卡片沿纵向平滑拉伸至 300vp，无路由跳转、无全屏弹窗遮挡；
 * **Tiimo 柔和光晕弧 (Halo Arc)**：中央展开 100vp 直径的暮紫/天青圆环发光光弧（`#9D8DF1`），300 秒（5分钟）平滑消融收缩；
 * 彻底消灭红色催命倒计时，光弧中心显示当前任务阶段目标与柔和正弦波呼吸；
 * **到期宽容双选**：弹出等权微晶双选：`[ 状态不错，继续！ ]`（接续完整时间块）与 `[ 先到这里 ]`（认可已投入 5 分钟，安心结束）。

---

### 4.2 【杂念停机坪】：快录微胶囊与轻烟气雾吸入 (Mist Ingestion)
* **入口规范**：常驻于主屏顶栏下方及专注全屏界面底部，高度统一为 36vp 微晶胶囊；
* **秒级停靠交互**：
 1. 闪现杂念敲下回车瞬间，输入文字原地高亮；
 2. 文字化为一缕轻烟向上收缩（`translate({ y: -12 })` + `opacity(0)`），并伴随轻柔微震 `EFFECT_TICK`；
 3. 中央浮现 1.2 秒气态微 Toast：“已安全停泊，放心专注 ”；
 4. 数据静默落盘 SQLite 机动池（`scheduled_start_at = 0`），晚间打烊仪式中集中复盘；
 5. **生命周期守护**：超过 48 小时未处理的杂念，自动在机动池中呈现灰度温和老化，避免杂念池膨胀为第二拖延清单。

---

### 4.3 【多巴胺和弦阶梯】：游丝高光波与星尘消散
* **勾选第 1~3 任务**：
 * 勾选框发出纯净乐音 `Do(C)` / `Mi(E)` / `Sol(G)`；
 * 卡片外围 0.5px 边框以勾选点为起点，顺时针扫过一道高亮光脉冲（波长 80vp，耗时 320ms）；
 * 马达触发类泡泡纸微爆破震感。
* **勾选第 4 任务（终极大和弦 High C'）**：
 * 卡片整体发生 **渐进气雾解体**；
 * 卡片边缘散裂为数十颗温润光斑，向上飘散 15vp 后渐隐消融，随后整行平滑收拢沉底至已完成区域。

---

### 4.4 【晚间打烊仪式】：暮光雾帘合拢与冷冻舱冰霜结晶
* **18:30 暮光落幕**：
 * 屏幕四周如同折叠屏闭合一样，徐徐合拢一层深空柔紫（#161322）的双色渐进雾帘；
 * 所有白天未完成任务收拢到磨砂玻璃遮罩之下；
* **成就认可与 SaveButton**：
 * 展示今日心流时长，ArkUI 原生安全控件 `SaveButton` 完美融入玻璃卡片底部，无需申请多余存储权限，零权限存相册；
* **冷冻舱（温和老化）**：
 * 逾期任务不标红，转入冷冻舱后表面覆上细腻冰晶霜纹（Frosted Texture），呈现休眠安睡感。

---

### 4.5 【自适应时间轴】：Structured 纵向主轴线与留白透气框
* **纵向时间轴脊柱 (Spine Axis)**：
 - 时间流左侧垂直贯穿一根 1.5px 的微光导轨实线，每个任务节点前置 14vp 圆珠节点；
 - 历史节点填充静谧青绿带微勾，正在进行节点产生环形呼吸光环，未来节点保持 0.5px 极细圆圈；
 - 实时位置呈现“激光指示线 (Now Laser)”，高亮显示当前时间与微弱脉动。
* **留白透气卡片 (Free-Time Cushion)**：
 - 任务块之间若存在 15~45 分钟空白，主轴线切换为虚线穿引；
 - 显示虚线边界的磁吸透气框 `(i) 30min 留白透气 · 喝杯温水`，提供心智呼吸空间，杜绝密恐感。

---

### 4.6 矢量图标规范（严禁使用 Emoji）
* **设计原则**：界面严禁以 Emoji 表情作为功能图标或状态符号，以维持高精度工业质感与各设备端的一致性；
* **规格标准**：全量使用 HarmonyOS Symbol 字体图标或 1.5~1.8px 细线 SVG 矢量图标（描边端点统一为 `Round`，不填充生硬色块）；
* **常用语义映射**：
 * 破冰船沙漏：`sys.symbol.hourglass` / 线性漏斗矢量；
 * 杂念停泊锚点：`sys.symbol.anchor` / 线性定位锚点；
 * 冷冻舱结晶：`sys.symbol.snowflake` / 六角细线冰晶；
 * 留白杯盏：`sys.symbol.cup_and_saucer` / 线性热饮微标。

---

## 5. 多感官协同规范 (Sensory Design)

### 5.1 纯净和弦音频采样 (`soundPool`)
系统使用预加载的无损正弦波/原声纯音采样，避免高音刺耳：
* **阶梯 1**：`sound_chord_c4.ogg` (261.63Hz) · 持续 280ms
* **阶梯 2**：`sound_chord_e4.ogg` (329.63Hz) · 持续 280ms
* **阶梯 3**：`sound_chord_g4.ogg` (392.00Hz) · 持续 280ms
* **阶梯 4**：`sound_chord_c5.ogg` (523.25Hz) · 持续 450ms (伴随泛音混响衰减)

---

### 5.2 解压微触感振动脉冲 (`vibrator`)
调用鸿蒙原生 `vibrator` 预置效果：
* **勾选待办**：`vibrator.EffectId.EFFECT_CLICK`（类微型气泡破裂）
* **杂念停泊**：`vibrator.EffectId.EFFECT_TICK`（极短轻柔脉冲）
* **打烊完成**：`vibrator.EffectId.EFFECT_HEAVY_CLICK`（沉稳厚重落锁感）

---

## 6. ArkUI V2 生产级参考实现

### 6.1 HDS 沉浸光感悬浮导航 (`HdsTabs`)
应用于主应用骨架，让自适应时间轴在悬浮底栏下通透穿透：

```typescript
// entry/src/main/ets/components/AuraFloatingTabs.ets
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';

@ComponentV2
export struct AuraFloatingTabs {
 @Param selectedIndex: number = 0;
 @Event onTabChange: (index: number) => void = () => {};

 build() {
 HdsTabs({
 selectedIndex: this.selectedIndex,
 barFloatingStyle: {
 // 核心：启用华为自适应沉浸光感材质，硬件级省电与通透
 materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE,
 materialType: hdsMaterial.MaterialType.IMMERSIVE,
 borderRadius: 28,
 offsetY: -16
 },
 onChange: (index: number) => {
 this.onTabChange(index);
 }
 })
 .margin({ bottom: 18 })
 }
}
```

---

### 6.2 雾化开合破冰卡片 (`MistMorphingCard`)
实现 iPhone Duo 式平滑展开与收拢的生产级标准组件（GPU 硬件友好，无连续模糊插值）：

```typescript
// entry/src/main/ets/components/MistMorphingCard.ets
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct MistMorphingCard {
 @Param title: string = "重构分布式同步协议";
 @Param timeSlot: string = "09:30 - 10:15 (45m)";
 @Param isExplorationSlice: boolean = true;

 @Local isExpanded: boolean = false;
 @Local isCompleted: boolean = false;

 build() {
 Column() {
 if (!this.isExpanded) {
 // === 收拢常态：Structured 自适应任务时间块 ===
 Row() {
 Column({ space: 4 }) {
 Row({ space: 6 }) {
 Text(this.timeSlot)
 .fontSize(11)
 .fontColor($r('sys.color.font_tertiary'))
 if (this.isExplorationSlice) {
 Text("45m 探索切片")
 .fontSize(10)
 .fontColor('#9D8DF1')
 .padding({ left: 6, right: 6, top: 2, bottom: 2 })
 .borderRadius(8)
 .backgroundColor('rgba(157, 141, 241, 0.12)')
 }
 }

 Text(this.title)
 .fontSize(15)
 .fontColor($r('sys.color.font_primary'))
 .fontWeight(FontWeight.Medium)
 .decoration({ type: this.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
 }
 .alignItems(HorizontalAlign.Start)
 .layoutWeight(1)

 // 破冰触发按钮（微脉动入口）
 Button("试试 5 分钟")
 .type(ButtonType.Capsule)
 .fontSize(12)
 .fontColor($r('sys.color.font_primary'))
 .backgroundColor('rgba(157, 141, 241, 0.16)')
 .height(28)
 .border({ width: 0.5, color: 'rgba(157, 141, 241, 0.35)' })
 .onClick(() => this.toggleMorph())

 // 右侧垂直对齐极简圆环勾选圈 (22vp)
 Circle({ width: 22, height: 22 })
 .fill(this.isCompleted ? '#70A9A1' : Color.Transparent)
 .border({ width: 1.5, color: this.isCompleted ? '#70A9A1' : $r('sys.color.font_tertiary') })
 .margin({ left: 12 })
 .onClick(() => {
 this.isCompleted = !this.isCompleted;
 // 触发 Do-Mi-Sol-Do' 音效与 vibrator
 })
 }
 .width('100%')
 .padding({ left: 16, right: 16, top: 14, bottom: 14 })
 } else {
 // === 展开态：禅意微光沙漏场域（原位展开，无路由跳转） ===
 Column({ space: 16 }) {
 Row() {
 Text("破冰攻坚 · 随时可停")
 .fontSize(12)
 .fontColor($r('sys.color.font_secondary'))
 Blank()
 Text("心流呼吸中 · 5 分钟")
 .fontSize(12)
 .fontColor('#9D8DF1')
 }
 .width('100%')

 // Tiimo 柔和光晕弧（无催命数字倒计时）
 Stack() {
 Circle({ width: 80, height: 80 })
 .fill('rgba(157, 141, 241, 0.15)')
 .blur(20)

 Circle({ width: 44, height: 44 })
 .fill('rgba(112, 169, 161, 0.2)')
 .blur(14)

 Text("专注投入中")
 .fontSize(12)
 .fontColor($r('sys.color.font_primary'))
 }
 .height(100)
 .width('100%')

 // 宽容双选
 Row({ space: 12 }) {
 Button("先到这里")
 .fontSize(12)
 .fontColor($r('sys.color.font_secondary'))
 .backgroundColor('rgba(255, 255, 255, 0.08)')
 .layoutWeight(1)
 .height(34)
 .onClick(() => this.toggleMorph())

 Button("状态不错，继续！")
 .fontSize(12)
 .fontColor(Color.White)
 .backgroundColor('#9D8DF1')
 .layoutWeight(1)
 .height(34)
 .onClick(() => this.toggleMorph())
 }
 .width('100%')
 }
 .width('100%')
 .padding(18)
 }
 }
 .width('100%')
 .clip(true)
 .borderRadius(18)
 .border({
 width: 0.5,
 color: this.isExpanded ? 'rgba(157, 141, 241, 0.45)' : 'rgba(25, 28, 33, 0.08)'
 })
 .backgroundBlurStyle(BlurStyle.Thin, {
 colorMode: ThemeColorMode.SYSTEM,
 adaptiveColor: AdaptiveColor.DEFAULT
 })
 .backgroundColor(this.isExpanded ? 'rgba(22, 19, 34, 0.75)' : 'rgba(255, 255, 255, 0.85)')
 .animation({ curve: curves.springMotion(0.48, 0.84) })
 }

 private toggleMorph() {
 this.isExpanded = !this.isExpanded;
 }
}
```

---

### 6.3 手机端自适应心流主视图 (`AuraTodayMobileView`)
以自适应时间轴为绝对主战场的沉浸流完整视图：

```typescript
// entry/src/main/ets/view/AuraTodayMobileView.ets
import { curves } from '@kit.ArkUI';
import { HdsFloatingDock } from './HdsFloatingDock';
import { MistMorphingCard } from '../components/MistMorphingCard';

@ComponentV2
export struct AuraTodayMobileView {
 @Local currentTabIndex: number = 0;
 @Local parkingText: string = "";
 @Local isFloatingDeckOpen: boolean = false;

 build() {
 Stack({ alignContent: Alignment.Bottom }) {
 // 主可滚动视界
 Scroll() {
 Column({ space: 16 }) {
 // 1. 沉浸式微晶顶栏
 Row() {
 Row({ space: 8 }) {
 Circle({ width: 28, height: 28 })
 .fill('rgba(157, 141, 241, 0.2)')
 Text("Aura · 今日心流")
 .fontSize(16)
 .fontWeight(FontWeight.Medium)
 .fontColor($r('sys.color.font_primary'))
 }
 Blank()
 // 脑力负荷环形微胶囊
 Row({ space: 6 }) {
 Circle({ width: 8, height: 8 }).fill('#9D8DF1')
 Text("2.8h / 4.5h")
 .fontSize(12)
 .fontWeight(FontWeight.Medium)
 .fontColor('#9D8DF1')
 }
 .padding({ left: 10, right: 10, top: 4, bottom: 4 })
 .borderRadius(14)
 .backgroundColor('rgba(157, 141, 241, 0.12)')
 }
 .width('100%')
 .height(52)

 // 2. 问候与常驻杂念快录胶囊 (秒级停泊，心流零打断)
 Column({ space: 10 }) {
 Text("早安，今日已装箱 3 个核心时间块，舒适留白 45m ")
 .fontSize(13)
 .fontColor($r('sys.color.font_secondary'))
 .width('100%')

 // 杂念停机坪快录胶囊
 Row({ space: 8 }) {
 TextInput({ placeholder: "闪现杂念？敲回车秒停泊 ", text: this.parkingText })
 .placeholderColor($r('sys.color.font_tertiary'))
 .fontColor($r('sys.color.font_primary'))
 .fontSize(13)
 .backgroundColor(Color.Transparent)
 .layoutWeight(1)
 .height(36)
 .onSubmit(() => {
 if (this.parkingText.trim().length > 0) {
 // 数据静默落盘 SQLite 机动池，触发微震
 this.parkingText = "";
 }
 })
 }
 .width('100%')
 .padding({ left: 14, right: 14 })
 .borderRadius(18)
 .backgroundColor('rgba(255, 255, 255, 0.75)')
 .border({ width: 0.5, color: 'rgba(25, 28, 33, 0.08)' })
 }
 .width('100%')

 // 3. 【核心主战场】Structured 纵向自适应时间轴 (占 65%+ 黄金视域)
 Column({ space: 0 }) {
 // 时间块 1: 架构攻坚
 Row({ space: 12 }) {
 // 纵向脊柱导轨节点
 Column() {
 Circle({ width: 14, height: 14 })
 .fill('#9D8DF1')
 .shadow({ radius: 8, color: '#9D8DF1' })
 Line().width(1.5).height(74).backgroundColor('rgba(157, 141, 241, 0.4)')
 }
 // 卡片本体 (含原位 5 分钟破冰)
 MistMorphingCard({
 title: "重构分布式装箱调度算法",
 timeSlot: "09:30 - 10:15 (45m)",
 isExplorationSlice: true
 })
 .layoutWeight(1)
 }
 .width('100%')

 // 留白呼吸缓冲带 (强制 15m)
 Row({ space: 12 }) {
 Column() {
 Circle({ width: 8, height: 8 }).fill('#3D6E4E')
 Line().width(1.5).height(46).strokeDashArray([4, 4]).backgroundColor('rgba(61, 110, 78, 0.3)')
 }
 // 留白透气微晶框
 Row() {
 Text(" 10:15 - 10:30 (15m 留白呼吸 · 喝杯温水)")
 .fontSize(12)
 .fontColor('#3D6E4E')
 }
 .width('100%')
 .layoutWeight(1)
 .padding({ left: 14, top: 10, bottom: 10 })
 .borderRadius(12)
 .backgroundColor('rgba(61, 110, 78, 0.08)')
 .border({ width: 0.5, color: 'rgba(61, 110, 78, 0.2)' })
 }
 .width('100%')
 .margin({ top: 4, bottom: 4 })

 // 时间块 2: 外部日历会议 (锁定不可排)
 Row({ space: 12 }) {
 Column() {
 Circle({ width: 12, height: 12 }).fill('#8FA2B0')
 Line().width(1.5).height(68).backgroundColor('rgba(143, 162, 176, 0.4)')
 }
 Row() {
 Column({ space: 4 }) {
 Text("10:30 - 11:30 (60m)")
 .fontSize(11)
 .fontColor($r('sys.color.font_tertiary'))
 Text(" 跨端协同技术方案评审 (锁定日程)")
 .fontSize(14)
 .fontColor($r('sys.color.font_primary'))
 .fontWeight(FontWeight.Medium)
 }
 .alignItems(HorizontalAlign.Start)
 }
 .layoutWeight(1)
 .padding(14)
 .borderRadius(16)
 .backgroundColor('rgba(143, 162, 176, 0.12)')
 }
 .width('100%')
 }
 .width('100%')

 // 4. 机动备选池折叠抽屉 (Floating Deck)
 Column({ space: 8 }) {
 Row() {
 Text("机动备选池 · 2 项待分配")
 .fontSize(13)
 .fontWeight(FontWeight.Medium)
 .fontColor($r('sys.color.font_secondary'))
 Blank()
 Text(this.isFloatingDeckOpen ? "收起 ▲" : "展开 ▼")
 .fontSize(12)
 .fontColor('#9D8DF1')
 }
 .width('100%')
 .onClick(() => {
 this.isFloatingDeckOpen = !this.isFloatingDeckOpen;
 })

 if (this.isFloatingDeckOpen) {
 Column({ space: 6 }) {
 Text("• 查阅 HarmonyOS NEXT 审核红线 (30m)")
 .fontSize(13)
 .fontColor($r('sys.color.font_primary'))
 Text("• 杂念停泊: 买降噪耳塞")
 .fontSize(13)
 .fontColor($r('sys.color.font_tertiary'))
 }
 .width('100%')
 .padding(12)
 .borderRadius(14)
 .backgroundColor('rgba(255, 255, 255, 0.6)')
 }
 }
 .width('100%')
 .padding(14)
 .borderRadius(16)
 .backgroundColor('rgba(255, 255, 255, 0.5)')
 .border({ width: 0.5, color: 'rgba(25, 28, 33, 0.06)' })

 // 底部留白，结合系统安全区撑开高度，防止遮挡
 Blank().height(96)
 }
 .padding({ left: 16, right: 16 })
 }
 .scrollBar(BarState.Off)
 .width('100%')
 .height('100%')

 // 5. 底部居中悬浮微晶 HDS 胶囊 Dock (黄金 3 Tab + 全屏手势避让)
 HdsFloatingDock({
 selectedIndex: this.currentTabIndex,
 onTabChange: (index: number) => {
 this.currentTabIndex = index;
 }
 })
 .margin({ bottom: 16 })
 }
 .width('100%')
 .height('100%')
 .backgroundColor('#F1F4F9')
 }
}
```

---

### 6.4 底部 HDS 悬浮微晶胶囊导航与手势避让 (`HdsFloatingDock`)
严格对齐 PRD 黄金 3 Tab，并集成全屏手势安全区避让：

```typescript
// entry/src/main/ets/view/HdsFloatingDock.ets
import { hdsMaterial } from '@kit.UIDesignKit';

@ComponentV2
export struct HdsFloatingDock {
 @Param selectedIndex: number = 0;
 @Event onTabChange: (index: number) => void = () => {};

 // 严格落地 PRD 黄金 3 Tab 架构
 // 注：Tab 3 (偏好设置) 内建已收集个人信息清单、第三方共享清单、撤回隐私同意与账号注销等华为审核红线入口
 private readonly tabs: Array<string> = ['今日心流', '任务视界', '偏好设置'];

 build() {
 Row() {
 ForEach(this.tabs, (name: string, index: number) => {
 Column({ space: 3 }) {
 Text(name)
 .fontSize(12)
 .fontWeight(this.selectedIndex === index ? FontWeight.Medium : FontWeight.Regular)
 .fontColor(this.selectedIndex === index ? '#5B4BD8' : '#5A6474')

 // 激活态微晶发光圆点 (3vp)
 Circle({ width: 3, height: 3 })
 .fill(this.selectedIndex === index ? '#5B4BD8' : Color.Transparent)
 .shadow(this.selectedIndex === index ? { radius: 6, color: '#5B4BD8' } : undefined)
 }
 .layoutWeight(1)
 .onClick(() => {
 this.onTabChange(index);
 })
 })
 }
 .width('88%')
 .height(52)
 .borderRadius(26)
 .backgroundColor('rgba(255, 255, 255, 0.88)')
 .backgroundBlurStyle(BlurStyle.Thin, {
 colorMode: ThemeColorMode.LIGHT,
 adaptiveColor: AdaptiveColor.DEFAULT
 })
 .border({ width: 0.5, color: 'rgba(25, 28, 33, 0.1)' })
 .shadow({ radius: 20, color: 'rgba(16, 24, 40, 0.08)', offsetY: 6 })
 // 手势导航安全区避让：保证在开启全面屏手势条时绝不发生触控冲突
 .padding({ bottom: 2 })
 .renderGroup(true)
 }
}
```

---

## 7. 性能约束与功耗防线 (Performance Guardrails)

为了百分之百满足 PRD **“纯离线、单次装箱调度 <2ms、零多余电量消耗、冷启动 ≤1.0s”** 的严苛红线，UI 视效必须遵循以下防御原则：

1. **拒绝高频动态模糊插值**：禁止在连续动画帧中动态修改 `linearGradientBlur` 的模糊半径；采用固定微晶模糊底座与物理弹簧尺寸形变，保障高刷新率（120fps）毫不掉帧；
2. **合理规范离屏锁层 (`renderGroup(true)`)**：对于仅发生尺寸拉伸或静态穿透的微晶容器显式启用 `renderGroup`；高频子组件重绘时避免盲目滥用造成 GPU 内存带宽冗余；
3. **HDS 材质自适应 (`MaterialLevel.ADAPTIVE`)**：严格采用系统级自适应沉浸材质，委托操作系统依据当前芯片温度与电量动态升降级着色器采样率；
4. **全屏手势安全区自适应**：所有悬浮组件底部必须留出充分的防误触避让空间，杜绝与鸿蒙全屏返回手势冲突。

---

*文档归档于 `docs/DESIGN.md`，作为 Aura 项目全周期 UI 还原与组件封装的唯一事实来源。*

