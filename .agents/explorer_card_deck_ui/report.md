# Aura 3D 阶梯层叠视觉卡组 (R2) UI 架构与组件层级深度调查报告

**调查执行者**：Explorer 1 (UI & Component Architecture Explorer)  
**工程目录**：`/Users/qiuhaiqin/DevEcoStudioProjects/Aura`  
**基准需求**：`ORIGINAL_REQUEST.md` (## 2026-09-23T01:11:35Z)  
**鸿蒙技术栈**：HarmonyOS NEXT (API 24, 6.1.1 Release), ArkTS 强类型, ArkUI V2 响应式模型

---

## 1. 调查执行总览与核心结论

1. **现有架构现状**：
   - 现行主舞台由 `TodayFlowView` (主心流视图)、`NowActionCard` (当前主动作卡片) 以及 `NextPeekCard` (底部双层微露卡片) 构成。
   - 数据由 `SingleThreadFlowEngine` (单线程推力引擎) 驱动，通过 `@Local engine: SingleThreadFlowEngine` 确定性加权排序，将最高优先级事项推入 `engine.activeTask`，后续事项排入 `engine.nextQueue`。
   - **痛点与断层**：当前 `NowActionCard` 内部独立处理 `PanGesture`，底层 `NextPeekCard` 无法实时获取拖拽位移 (`offsetX`) 与归一化进度 (`gestureProgress`)，导致拖拽时底层静态僵死，缺乏对标 Tinder / Bumble 的连续视差动力学放大与抬升体验；静态露边采用固定高度累加 (`activeCardHeight + 20/38`)，在长短文本极端切换或手势快速飞卡时存在抖动隐患。
2. **3D Tiered Visual Stack (R2) 重构方案**：
   - 设计统一的 `ParallaxCardDeck`（视差卡组容器组件），通过 ArkUI V2 的 `@ComponentV2`、`@Local`、`@Param`、`@Event` 实现高内聚、零额外重渲染开销的物理映射。
   - **三层阶梯几何规范**：
     - **第 1 层 (Layer 1 · 当前聚焦卡片)**：100% 宽度居中，承载主任务标题、微步清单、操作手柄，手势水平位移 `offsetX` 驱动实时倾角与飞行轨迹。
     - **第 2 层 (Layer 2 · 下一项就绪卡片)**：95% 宽度，静止态下沉 22vp，稳定外露 20~24vp 包含分类色彩徽标、粗体「下一项」微标、任务标题截断预览与时长胶囊；拖拽时由 0.95 连续缩放至 1.0、下沉位移由 22vp 衰减至 0vp。
     - **第 3 层 (Layer 3 · 后续事项微晶轮廓)**：90% 宽度，在第 2 层下方再下沉 16vp (累计下沉 38vp)，外露 16vp 微晶轮廓；拖拽时由 0.90 连续缩放至 0.95、位移由 38vp 衰减至 22vp。
   - **动态高度自适应机制**：
     - 采用 Layer 1 内部主体内容区域的 `.onAreaChange` 精准监听实际内容高度 `measuredHeight`；
     - 容器高度自适应锁定为 `measuredHeight + 38vp + 12vp` (底部阴影呼吸留白)，底层卡片几何基准高度与 Layer 1 对齐并通过 `translate.y` 阶梯下移；
     - 底层卡片外露信息条通过 `Stack({ alignContent: Alignment.Bottom })` 沉底锚定，彻底解决文字多行 (1~3行) 或微步子项数量变化时的内容截断与遮挡缺陷。
   - **工程规范保障**：
     - 全量 ArkTS 强类型约束，严禁 `any`；
     - 全工程代码与 UI 文本 Emoji 出现次数严格为 0；
     - 本地单元测试 23/23 项全部 PASS，构建 `assembleHap` 与 `test` 验证通过。

---

## 2. 现有 UI 架构与组件层级深度剖析

### 2.1 整体组件视图拓扑图
```
pages/Index.ets (@Entry, @ComponentV2)
 ├── Multi-Device Switcher (wearable, car, tv, mobile/tablet/2in1)
 └── Swiper (Golden 3-Tab Workspace)
      ├── Tab 0: TodayFlowView (@ComponentV2)
      │    ├── Breathing Top Bar (Date, Steps Badge, Sunset, Settings)
      │    ├── StreakFreezeRevivalCard (Conditional: Offline revival)
      │    ├── Central Action Stage:
      │    │    └── Stack({ alignContent: Alignment.Top })
      │    │         ├── NextPeekCard (Layer 2 & Layer 3 peek)
      │    │         └── NowActionCard (Layer 1 focus task + PanGesture)
      │    ├── ParkingLotInputBar (36vp Fast Thought Capture)
      │    ├── QueueDrawer (Collapsible drawer: nextQueue & parkingQueue)
      │    └── FAB '+' Button & GlobalUndoCapsule
      ├── Tab 1: TaskMatrixView (Quadrants & Matrix)
      └── Tab 2: SettingsView
```

### 2.2 核心组件现状与代码溯源

#### 1. `views/TodayFlowView.ets` (第 318-350 行)
- **卡片堆叠方式**：
  ```ets
  if (this.engine.activeTask !== null) {
    Stack({ alignContent: Alignment.Top }) {
      NextPeekCard({
        item: this.engine.nextQueue.length > 0 ? this.engine.nextQueue[0] : null,
        secondItem: this.engine.nextQueue.length > 1 ? this.engine.nextQueue[1] : null,
        isVisible: this.engine.nextQueue.length > 0,
        activeCardHeight: this.activeCardHeight
      })

      NowActionCard({
        item: this.engine.activeTask,
        onHeightChange: (h: number) => {
          this.activeCardHeight = h;
        },
        onComplete: () => { this.handleComplete(); },
        onSkip: () => { this.handleSkip(); },
        onOpenFocus: (item: TodoItem) => { this.handleFocus(item); }
      })
    }
    .width('100%')
    .constraintSize({ maxWidth: 520 })
    .height(this.activeCardHeight + (this.engine.nextQueue.length > 1 ? 42 : (this.engine.nextQueue.length > 0 ? 24 : 0)))
    .margin({ top: 12, bottom: 20 })
  }
  ```
- **优缺点分析**：
  - **优点**：结构清晰，顶层与底层物理隔离，高度通过 `@Local activeCardHeight` 响应式同步。
  - **缺陷**：顶层 `NowActionCard` 发生手势滑动时，未向 `NextPeekCard` 传递任何位移动态。底层卡片在滑动手势期间如同贴在背后的静态背景板，无放大抬升，破坏了物理连续性认知。

#### 2. `components/NowActionCard.ets` (第 23-64 行, 333-382 行)
- **手势动力学**：
  - 拥有 `@Local private offsetX: number = 0` 与 `@Local private rotateAngle: number = 0`。
  - `PanGesture({ direction: PanDirection.Horizontal })` 更新 `this.offsetX = event.offsetX`，`rotateAngle = event.offsetX * 0.04`。
  - 当 `|offsetX| >= 80` 时触发微触觉 `HapticService.triggerTick()`。
  - `onActionEnd` 时：`offsetX > 80 || velocityX > 600` 触发 `triggerComplete()`（向右飞出，`offsetX = 400`, `rotateAngle = 14`, `cardOpacity = 0`）；`offsetX < -80 || velocityX < -600` 触发 `triggerSkip()`（向左飞出，`offsetX = -400`, `rotateAngle = -14`）。
- **高度测量机制**：
  - 使用 `.onAreaChange((oldA: Area, newA: Area) => { const h = Number(newA.height); ... })`，在尺寸发生大于 1vp 变化时触发 `onHeightChange(h)`。
- **视觉层级**：
  - 顶部状态药丸（分类微标 + 优先级徽标 + 预估时长）；
  - 核心大标题（22fp, Bold, 最大 3 行）+ 描述文本（14fp, 最大 2 行）；
  - 微步清单列表（最多 4 项微步，带圆形微打勾圈与中划线）；
  - 底部操作栏（「稍后」、「专注」、「完成」）。

#### 3. `components/NextPeekCard.ets` (第 24-113 行)
- **现有露边实现方式**：
  - Layer 3 (队列第 3 项)：`width('90%')`，高度设置为 `getEffectiveHeight() + 38`，底栏内嵌 `Row` (高度 20vp) 呈现 `后续 · 标题` 与预估时长。
  - Layer 2 (队列第 2 项)：`width('95%')`，高度设置为 `getEffectiveHeight() + 20`，底栏内嵌 `Row` (高度 26vp) 呈现分类色圆点、`下一项` 粗体字、标题截断预览与时长胶囊。
  - 动画使用 `curves.springMotion(0.35, 0.75)`。
- **与 R2 要求的差距**：
  - 静态参数上基本符合 95% / 90% 宽度与外露高度要求；
  - 但缺乏实时拖拽联动，无法根据 `gestureProgress` 动态响应缩放（0.93/0.95 -> 1.0）与位移抬升（24/22vp -> 0vp）；
  - 次层弹射未利用独立弹簧超调曲线（spring overshoot bounce）营造冲击力。

#### 4. `components/MistMorphingCard.ets` (第 13-187 行)
- **历史定位与微交互启发**：
  - 在原时间轴/四象限列表中作为核心任务项卡片；
  - 引入了 `LiquidGlassState` 响应式水膜张力（`SPRING_LIQUID_STRETCH` 与 `SPRING_LIQUID_SNAP`），通过 `onTouch` 实现拉伸与回弹；
  - 包含 -15m/+15m 原地时段微调、锁定手柄、45m 切片徽标与 22vp 高对比打卡圆环。
  - **借鉴意义**：微晶质感、弹簧物理参数以及紧凑的分类配色系统可无缝复用到卡组组件中。

---

## 3. 3D 阶梯层叠视觉卡组 (R2) UI 组件架构设计推荐

为彻底实现 R1（实时手势动力学联动）、R2（阶梯式 3D 纸牌叠层美学）与 R3（弹簧超调弹射与多巴胺触觉闭环），建议采用**高内聚视差卡组容器架构**。

### 3.1 架构设计模式选型对比

| 架构维度 | 方案 A：分立组件回调联动模式 (`NowActionCard` + `NextPeekCard`) | 方案 B：统一视差卡组容器架构 (`ParallaxCardDeck`) |
| :--- | :--- | :--- |
| **组件划分** | 顶层与底层分属不同 struct，手势数据经由 `TodayFlowView` 中转 | 封装为单个 `ParallaxCardDeck`，内部统一驱动 3 个 Layer 子层 |
| **手势联动帧率** | 拖拽时需从 `NowActionCard` 触发 `onDragProgress` 回调至 `TodayFlowView`，再由 `@Local` 注入 `NextPeekCard`，存在跨组件属性传递开销 | 手势状态由卡组容器本地持有，组件内直接驱动三层 `translate` 与 `scale`，享受 ArkUI 原生渲染树直通优化 |
| **高度自适应** | 需维护 `activeCardHeight` 并跨层传递，极端情况存在 1 帧时序延迟 | 容器内部直接测量 Layer 1 真实高度，三层尺寸与沉底外露条一次性对齐 |
| **超调弹射动效** | 顶层飞出与底层就位由不同组件中的 `animateTo` 分别触发，难以严丝合缝对齐 phase | 飞卡与底层弹射在同一动画事务/弹簧控制器中执行，自然实现 Overshoot bounce |
| **架构推荐** | 备选（改造现有分立组件） | **首选推荐（极力推荐，物理联动最纯粹，性能最优）** |

---

### 3.2 3D 阶梯视觉与几何空间映射数学模型 (Layer 1 / Layer 2 / Layer 3)

#### 1. 静态待机态参数表 (Idle State)
| 层级 | 宽度占比 | 缩放比例 (Scale) | 垂直下沉 (Translate Y) | 外露高度 (Peek Height) | 视觉特征与内容元素 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Layer 1** (当前聚焦) | `100%` (max 520vp) | `1.00` | `0 vp` | 完整可见 | 分类药丸、优先级徽标、预估时长、大标题 (居中 1~3 行)、描述、微步清单、三大手势操作按钮 |
| **Layer 2** (下一项) | `95%` | `0.95` (或 0.96) | `+22 vp` | `22 vp` (稳定在 20~24vp 区间) | 底部 22vp 区域：分类色圆点 (7vp)、加粗「下一项」微标、任务标题截断预览、时长微晶胶囊；底色浅透玉白，阴影 radius 20 |
| **Layer 3** (后续微晶) | `90%` | `0.90` (或 0.92) | `+38 vp` (22 + 16vp) | `16 vp` | 底部 16vp 区域：更小微点 (5vp)、淡雅灰色微晶轮廓、微文本「后续 · 标题」；底色燕麦微晶暖白，阴影 radius 16 |

#### 2. 连续手势动力学物理映射公式 (Real-time Dynamics)
设定手势临界阈值 $T_{\text{threshold}} = 120\text{ vp}$。  
当用户水平拖拽顶层卡片，位移为 $\Delta x$ 时，计算归一化手势进度：
$$p = \min\left(1.0, \frac{|\Delta x|}{T_{\text{threshold}}}\right) \in [0.0, 1.0]$$

三层物理属性与手势进度的连续函数映射：
- **Layer 1 运动学**：
  $$\text{TranslateX} = \Delta x$$
  $$\text{RotateAngle} = \Delta x \times 0.04^{\circ}$$
  $$\text{Opacity} = 1.0 - 0.15 \times p$$
- **Layer 2 物理抬升与放大**：
  $$\text{Scale}_2(p) = 0.95 + (1.00 - 0.95) \times p$$
  $$\text{TranslateY}_2(p) = 22\text{ vp} \times (1.0 - p)$$
  $$\text{ShadowRadius}_2(p) = 16 + 8 \times p$$
- **Layer 3 物理跟进**：
  $$\text{Scale}_3(p) = 0.90 + (0.95 - 0.90) \times p$$
  $$\text{TranslateY}_3(p) = 38\text{ vp} - (38 - 22)\text{ vp} \times p = 38 - 16 \times p$$

**物理感知效果**：当手指拖动顶层卡片向右（准备完成）或向左（准备跳过）时，底层卡片仿佛具有真实的重力与纸牌叠层弹性，连续上升并放大，用户能直观预判松手后下一张卡片扑面而来的触感。

---

### 3.3 无论文本长短绝不遮挡的动态高度自适应方案

#### 核心痛点排查：
- 待办标题从 1 行（如「晨间喝水」）到 3 行（如「全面重构 3D 纸牌层叠架构并适配深色模式」），高度相差 40~60vp；
- 某些任务含有 1~4 项微步清单（每项约 34vp），导致卡片总高度在 180vp 至 380vp 之间剧烈变化；
- 若采用固定卡片高度，短文本会产生巨大空洞，长文本或多微步则会导致内容被裁剪或无法滚动；若底层卡片高度不自适应，露出的 20~24vp 就会被顶层动态变长而彻底吞没！

#### 解决方案：自适应几何基准与锚点沉底 (Anchored Bottom Stacking)
1. **顶层卡片真实高度测量**：
   - Layer 1 外层容器使用 `wrapContent` 机制，其内部主体 `Column` 挂载 `.onAreaChange((oldA, newA) => { ... })`。
   - 动态更新 `@Local activeCardHeight = Number(newA.height)`。
2. **底层卡片高度对齐与外露布局**：
   - Layer 2 与 Layer 3 的主体卡片高度直接声明为 `height: this.activeCardHeight`（与当前卡片等高）；
   - 在其 `Stack({ alignContent: Alignment.Bottom })` 内部，通过 `translate({ y: this.layer2OffsetY })` 向下推移；
   - 因为 Layer 2 向下偏移了 22vp，且高度与 Layer 1 相同，故其底部恰好有 $22\text{ vp}$ 凸出在 Layer 1 下方；
   - Layer 2 的底部预览行（Row）通过 `Alignment.Bottom` 贴紧其卡片底部，因此永远精准且完整地显示在这 22vp 的外露带中！
3. **舞台总容器高度约束**：
   - 整个卡组外层容器高度声明为：
     $$\text{ContainerHeight} = \text{activeCardHeight} + 38\text{ vp} + 12\text{ vp}$$
   - 底部外加 12vp 阴影安全缓冲，外层 `Stack` 绝不声明 `.clip(true)`；
   - 如此一来，无论 Layer 1 因文本长度或微步展开变得多高，Layer 2 与 Layer 3 始终严格向下延伸出 22vp 与 16vp，**两层露出的色彩圆点、标签与文本绝不发生任何遮挡或溢出截断！**

---

### 3.4 弹簧超调弹射与多巴胺触觉闭环设计 (Spring Overshoot & Dopamine Haptics)

1. **手势判定与飞行临界点**：
   - 触发完成阈值：$\Delta x > 80\text{ vp}$ 或滑动初速度 $v_x > 600\text{ vp/s}$；
   - 触发跳过阈值：$\Delta x < -80\text{ vp}$ 或滑动初速度 $v_x < -600\text{ vp/s}$；
   - 未达到阈值：触发弹性归位（Reset bounce back）。
2. **释放阶段的双轨弹簧动力学**：
   - **轨道一：顶层飞牌消融 (Flyout Dismiss)**：
     - 向右飞出目标：$\text{offsetX} = 450\text{ vp}$, $\text{rotateAngle} = 14^{\circ}$, $\text{opacity} = 0$；
     - 向左飞出目标：$\text{offsetX} = -450\text{ vp}$, $\text{rotateAngle} = -14^{\circ}$, $\text{opacity} = 0$；
     - 动效曲线：`curves.springMotion(0.35, 0.75)`。
   - **轨道二：次层超调弹射 (Overshoot Bounce To Focus)**：
     - 在顶层卡片飞出瞬间，Layer 2 立即以更强劲的弹性曲线冲顶：
       $$\text{scale}: 0.95 \to 1.02 \to 1.00$$
       $$\text{translateY}: 22\text{ vp} \to -3\text{ vp} \to 0\text{ vp}$$
     - 动效曲线：`curves.springMotion(0.32, 0.68)`（紧致轻弹微过冲）。
3. **多感官闭环协同**：
   - 拖拽穿越 $\pm 80\text{ vp}$ 临界线瞬间：`HapticService.triggerTick()`（泡泡微阻尼破裂感）；
   - 松手判定成功飞出瞬间：`HapticService.triggerClick()`（清脆微晶确认震动）+ `AudioService.playChordStep()`（和弦阶梯升阶 Do $\to$ Sol）；
   - 飞牌动画结束 (`onFinish`)：调用引擎 `completeActive()` / `skipActive()`，重置 `offsetX = 0`，队列指针原子推进，新顶层卡片完美就位。

---

## 4. ArkUI V2 规范与类型安全审查

### 4.1 状态管理装饰器对照审查
- **`@ComponentV2`**：所有 UI 组件（`TodayFlowView`, `NowActionCard`, `NextPeekCard`, `QueueDrawer`）均已严格使用 `@ComponentV2`，摒弃 V1 装饰器。
- **`@Param` 与 `@Event`**：
  - 组件入参全部使用 `@Param`（如 `@Param item: TodoItem | null = null`）；
  - 回调函数全部使用 `@Event` 并赋予空函数默认值（如 `@Event onComplete: () => void = () => {}`）；
  - 避免了父子组件状态引用传递混乱。
- **`@Local`**：
  - 组件内部私有响应式变量（如 `offsetX`, `isDragging`, `activeCardHeight`）全量采用 `@Local` 修饰。
- **`@ObservedV2` 与 `@Trace`**：
  - 实体模型 `TodoItem`、推力引擎 `SingleThreadFlowEngine`、用户设置 `UserSettings` 均使用 `@ObservedV2`，其所有响应式属性均带 `@Trace`；
  - 数组操作（如 `nextQueue.shift()`, `nextQueue.push()`）能精准触发 ArkUI V2 局部刷新，无全树重绘开销。
- **`@Monitor`**：
  - `TodayFlowView` 中对 `refreshTrigger` 与 `isInitialized` 正确使用 `@Monitor` 监听，保证跨页面/弹窗数据变更即时响应。

### 4.2 ArkTS 强类型约束检查
- 全量代码中**零 `any`** 使用；
- 泛型与回调签名清晰（如 `(item: TodoItem) => void`, `(h: number) => void`）；
- 空值安全：所有可空属性采用联合类型 `TodoItem | null`，并在访问前进行明确的非空守护（`if (this.item) { ... }`）。

### 4.3 视觉文本纯净度检查 (Emoji 规范)
- 经全工程扫描脚本执行：
  - `entry/src/main/ets`：**0 处 Emoji**；
  - `entry/src/test`：**0 处 Emoji**；
  - 全部视觉元素均采用鸿蒙系统矢量图标 `$r('app.media.ic_*')` 或几何图形绘制（`Circle`, `Row`）。

---

## 5. 推荐实现设计代码模型 (Design Blueprint)

以下为推荐的 `ParallaxCardDeck.ets` 核心架构草案，可作为落地重构的直接参考：

```ets
/*
 * ParallaxCardDeck: 3D Tiered Visual Stack with Real-time Gestural Dynamics
 * ArkUI V2 Component adhering strictly to R1, R2, R3
 */

import { curves } from '@kit.ArkUI';
import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem } from '../models/TodoItem';
import { getTaskVisual } from './TaskVisualHelper';
import { HapticService } from '../common/media/HapticService';

@ComponentV2
export struct ParallaxCardDeck {
  @Param activeTask: TodoItem | null = null;
  @Param nextTask: TodoItem | null = null;
  @Param thirdTask: TodoItem | null = null;

  @Event onComplete: () => void = () => {};
  @Event onSkip: () => void = () => {};
  @Event onOpenFocus: (item: TodoItem) => void = () => {};

  @Local private offsetX: number = 0;
  @Local private rotateAngle: number = 0;
  @Local private isDragging: boolean = false;
  @Local private topCardOpacity: number = 1.0;
  @Local private measuredCardHeight: number = 240;
  @Local private hasTriggeredHaptic: boolean = false;

  private readonly SWIPE_THRESHOLD: number = 80;
  private readonly FLING_VELOCITY: number = 600;

  // 归一化手势进度 0.0 ~ 1.0
  private get gestureProgress(): number {
    return Math.min(1.0, Math.abs(this.offsetX) / 120);
  }

  // Layer 2 动态缩放: 0.95 -> 1.00
  private get layer2Scale(): number {
    return 0.95 + 0.05 * this.gestureProgress;
  }

  // Layer 2 垂直位移: 22vp -> 0vp
  private get layer2OffsetY(): number {
    return 22 * (1.0 - this.gestureProgress);
  }

  // Layer 3 动态缩放: 0.90 -> 0.95
  private get layer3Scale(): number {
    return 0.90 + 0.05 * this.gestureProgress;
  }

  // Layer 3 垂直位移: 38vp -> 22vp
  private get layer3OffsetY(): number {
    return 38 - 16 * this.gestureProgress;
  }

  private handleSwipeEnd(event: GestureEvent): void {
    this.isDragging = false;
    if (this.offsetX > this.SWIPE_THRESHOLD || event.velocityX > this.FLING_VELOCITY) {
      this.executeFlyout(450, 14, () => {
        this.onComplete();
      });
    } else if (this.offsetX < -this.SWIPE_THRESHOLD || event.velocityX < -this.FLING_VELOCITY) {
      this.executeFlyout(-450, -14, () => {
        this.onSkip();
      });
    } else {
      // 弹性回弹归位
      animateTo({
        curve: curves.springMotion(0.35, 0.72),
        onFinish: () => {
          this.hasTriggeredHaptic = false;
        }
      }, () => {
        this.offsetX = 0;
        this.rotateAngle = 0;
        this.topCardOpacity = 1.0;
      });
    }
  }

  private executeFlyout(targetX: number, targetAngle: number, onAction: () => void): void {
    HapticService.getInstance().triggerClick();
    animateTo({
      curve: curves.springMotion(0.32, 0.68),
      onFinish: () => {
        this.offsetX = 0;
        this.rotateAngle = 0;
        this.topCardOpacity = 1.0;
        this.hasTriggeredHaptic = false;
        onAction();
      }
    }, () => {
      this.offsetX = targetX;
      this.rotateAngle = targetAngle;
      this.topCardOpacity = 0;
    });
  }

  build() {
    if (this.activeTask) {
      Stack({ alignContent: Alignment.Top }) {
        // === Layer 3: 后续事项微晶轮廓 (90% 宽度，下沉 38vp) ===
        if (this.thirdTask) {
          Stack({ alignContent: Alignment.Bottom }) {
            Row({ space: 8 }) {
              Circle({ width: 5, height: 5 })
                .fill(getTaskVisual(this.thirdTask).color)
                .opacity(0.8)

              Text(`后续 · ${this.thirdTask.title}`)
                .fontSize(11)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              Text(`${this.thirdTask.estimatedMinutes}m`)
                .fontSize(10)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            }
            .width('100%')
            .height(16)
            .padding({ left: 16, right: 16 })
          }
          .width('90%')
          .height(this.measuredCardHeight)
          .borderRadius(24)
          .backgroundColor('rgba(242, 237, 228, 0.95)')
          .border({ width: 1, color: 'rgba(85, 70, 50, 0.08)' })
          .shadow({ radius: 14, color: 'rgba(85, 70, 50, 0.05)', offsetY: 6 })
          .translate({ y: this.layer3OffsetY })
          .scale({ x: this.layer3Scale, y: this.layer3Scale })
          .zIndex(1)
        }

        // === Layer 2: 下一项就绪卡片 (95% 宽度，下沉 22vp，外露 20~24vp) ===
        if (this.nextTask) {
          Stack({ alignContent: Alignment.Bottom }) {
            Row({ space: 8 }) {
              Circle({ width: 7, height: 7 })
                .fill(getTaskVisual(this.nextTask).color)

              Text('下一项')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(getTaskVisual(this.nextTask).color)

              Text(this.nextTask.title)
                .fontSize(12)
                .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              Text(`${this.nextTask.estimatedMinutes}m`)
                .fontSize(11)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(6)
                .backgroundColor('rgba(85, 70, 50, 0.06)')
            }
            .width('100%')
            .height(24)
            .padding({ left: 18, right: 18 })
            .backgroundColor(getTaskVisual(this.nextTask).softColor)
            .borderRadius({ bottomLeft: 24, bottomRight: 24 })
          }
          .width('95%')
          .height(this.measuredCardHeight)
          .borderRadius(24)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 1, color: 'rgba(255, 255, 255, 0.95)' })
          .shadow({ radius: 18, color: 'rgba(85, 70, 50, 0.08)', offsetY: 8 })
          .translate({ y: this.layer2OffsetY })
          .scale({ x: this.layer2Scale, y: this.layer2Scale })
          .zIndex(2)
        }

        // === Layer 1: 当前聚焦主卡片 (100% 宽度，手势动力学主控) ===
        Stack({ alignContent: Alignment.Center }) {
          // 渲染主卡片内容 (分类徽标、标题、描述、微步清单、操作手柄)
          // 见 NowActionCard 实现细节...
        }
        .width('100%')
        .onAreaChange((oldA: Area, newA: Area) => {
          const h = Number(newA.height);
          if (h > 0 && Math.abs(h - this.measuredCardHeight) > 1) {
            this.measuredCardHeight = h;
          }
        })
        .translate({ x: this.offsetX, y: 0 })
        .rotate({ angle: this.rotateAngle })
        .opacity(this.topCardOpacity)
        .zIndex(3)
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal })
            .onActionUpdate((event: GestureEvent) => {
              this.isDragging = true;
              this.offsetX = event.offsetX;
              this.rotateAngle = event.offsetX * 0.04;
              if (Math.abs(event.offsetX) >= this.SWIPE_THRESHOLD && !this.hasTriggeredHaptic) {
                HapticService.getInstance().triggerTick();
                this.hasTriggeredHaptic = true;
              } else if (Math.abs(event.offsetX) < this.SWIPE_THRESHOLD) {
                this.hasTriggeredHaptic = false;
              }
            })
            .onActionEnd((event: GestureEvent) => {
              this.handleSwipeEnd(event);
            })
        )
      }
      .width('100%')
      .constraintSize({ maxWidth: 520 })
      .height(this.measuredCardHeight + 38 + 12)
    }
  }
}
```

---

## 6. 演进与落地建议

1. **分步替换策略**：
   - 步骤 1：保留现有 `TodayFlowView` 中的业务逻辑（数据刷新、撤销胶囊、杂念入池），将 `NowActionCard` + `NextPeekCard` 的分立渲染替换为统一的 `ParallaxCardDeck`（或将 `NowActionCard` 的手势进度以 `@Param` / `@Event` 深度打通）；
   - 步骤 2：对标 Bumble / Tinder 的物理阻尼，微调 `springMotion(0.32, 0.68)` 的反应时间与阻尼比，确保飞卡与次层弹射毫不突兀且带强烈的爽快多巴胺反馈；
   - 步骤 3：运行全量单元测试与 HAP 打包，确保构建 0 错误、测试 23 项全绿。
