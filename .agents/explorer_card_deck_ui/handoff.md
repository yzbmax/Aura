# 3D 阶梯层叠视觉卡组 (R2) UI 组件架构调查交接报告 (Handoff Report)

## 1. 事实观察 (Observation)

### 1.1 关键文件路径与代码行号事实
1. **主舞台视图层级与卡片装载**：
   - 路径：`entry/src/main/ets/views/TodayFlowView.ets`
   - 行号：第 319-350 行
   - 代码实录：
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
           onComplete: () => {
             this.handleComplete();
           },
           onSkip: () => {
             this.handleSkip();
           },
           onOpenFocus: (item: TodoItem) => {
             this.handleFocus(item);
           }
         })
       }
       .width('100%')
       .constraintSize({ maxWidth: 520 })
       .height(this.activeCardHeight + (this.engine.nextQueue.length > 1 ? 42 : (this.engine.nextQueue.length > 0 ? 24 : 0)))
       .margin({ top: 12, bottom: 20 })
     }
     ```
   - 现象：`TodayFlowView` 将顶层主卡片 `NowActionCard` 与底层外露卡片 `NextPeekCard` 放置于同一个 `Stack({ alignContent: Alignment.Top })`，容器高度根据 `@Local activeCardHeight` 动态加上 42vp 或 24vp。

2. **当前手势与动画实现**：
   - 路径：`entry/src/main/ets/components/NowActionCard.ets`
   - 行号：第 23-64 行、第 346-382 行
   - 代码实录：
     - 局部状态：`@Local private offsetX: number = 0; @Local private rotateAngle: number = 0;`
     - 手势绑定：`PanGesture({ direction: PanDirection.Horizontal })`
     - 实时更新：`this.offsetX = event.offsetX; this.rotateAngle = event.offsetX * 0.04;`
     - 临界震动：`Math.abs(event.offsetX) >= 80` 时触发 `HapticService.triggerTick()`；
     - 释放飞牌：`animateTo({ curve: curves.springMotion(0.35, 0.75), onFinish: ... }, () => { this.offsetX = 400; this.rotateAngle = 14; this.cardOpacity = 0; })`；
   - 现象：手势只在 `NowActionCard` 内部流转，没有向外界（或底层的 `NextPeekCard`）派发 `offsetX` 或 `gestureProgress`。

3. **底层外露卡片实现**：
   - 路径：`entry/src/main/ets/components/NextPeekCard.ets`
   - 行号：第 25-112 行
   - 代码实录：
     - Layer 3 (第二外露项)：`width('90%')`，高度为 `this.getEffectiveHeight() + 38`，底栏内嵌 `Row` (高度 20vp) 呈现 `Circle(6vp)` + `后续 · ${secondItem.title}` + 时长；
     - Layer 2 (第一外露项)：`width('95%')`，高度为 `this.getEffectiveHeight() + 20`，底栏内嵌 `Row` (高度 26vp) 呈现 `Circle(7vp)` + `下一项` + 标题预览 + 时长胶囊；
     - 动画：声明了 `.animation({ curve: curves.springMotion(0.35, 0.75) })`。
   - 现象：仅在队列出入队时有静态弹簧切换，在手指拖拽顶层卡片期间完全无物理联动（无缩放、无抬升）。

4. **单线程流水线引擎状态流转**：
   - 路径：`entry/src/main/ets/engine/SingleThreadFlowEngine.ets`
   - 行号：第 10-36 行、第 109-163 行
   - 代码实录：
     - `@Trace public activeTask: TodoItem | null = null;`
     - `@Trace public nextQueue: TodoItem[] = [];`
     - `@Trace public parkingQueue: TodoItem[] = [];`
     - `completeActive()`: 将 `activeTask` 标记完成并移入 `completedToday`，将 `nextQueue.shift()` 作为新的 `activeTask`；
     - `skipActive()`: 将 `activeTask` 推入 `nextQueue.push(skipped)` 尾部，将 `nextQueue.shift()` 提升为新的 `activeTask`。

5. **工程构建、单元测试与规范运行结果**：
   - 构建环境：DevEco Studio 内置 SDK (`HarmonyOS 6.1.1`, API 24), 内置 JBR (`/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home`), 内置 hvigor 6.24.4。
   - 单元测试命令与结果：
     - 命令：`export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk && export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home && export PATH=$JAVA_HOME/bin:$PATH && /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test`
     - 结果：`Tests run: 23, Failure: 0, Error: 0, Pass: 23, Ignore: 0`，`BUILD SUCCESSFUL in 5 s 524 ms`。
   - HAP 打包命令与结果：
     - 命令：`... hvigorw assembleHap`
     - 结果：`BUILD SUCCESSFUL in 1 s 498 ms`，编译零错误。
   - Emoji 纯净度检查：全工程 `entry/src` 扫描，Emoji 命中数为 0。

---

## 2. 推导逻辑链 (Logic Chain)

1. **手势物理联动的断层原因定位 (基于观察 1.1 与 1.2)**：
   - 观察 1.1 表明 `NowActionCard` 和 `NextPeekCard` 是分立平级组件，由 `TodayFlowView` 中的 `Stack` 组合；
   - 观察 1.2 表明 `PanGesture` 的位移 `offsetX` 完全作为私有状态封闭在 `NowActionCard` 内部；
   - **推导结论**：底层 `NextPeekCard` 无法实时获得手势数据，因此无法响应 R1 要求的 `gestureProgress` 缩放（0.93/0.95 -> 1.0）与垂直位移衰减（24/22vp -> 0vp）。必须在卡组架构层级将手势状态提升并统一调度。

2. **3D 阶梯叠层几何尺寸与外露设计的可行性 (基于观察 1.3 与需求 R2)**：
   - 观察 1.3 显示，当前 `NextPeekCard` 已经初步采用了 95% 与 90% 的宽度层级，以及 20~26vp 与 38vp 的高度差；
   - 需求 R2 明确要求：
     - Layer 1 (当前聚焦): 100% 宽度居中；
     - Layer 2 (下一项): 95% 宽度，自适应下沉稳定外露 20~24vp 包含分类色彩、微标与标题预览；
     - Layer 3 (后续事项): 90% 宽度，下沉外露 16vp 微晶轮廓。
   - **推导结论**：现有视觉元素（分类色圆点、粗体徽标、标题预览、预估时长）与 R2 高度契合，重构的核心在于将“以写死高度累加的假叠层”转变为“以空间偏移 `translate.y` 与等比 `scale` 的真 3D 纸牌层叠物理模型”。

3. **动态高度自适应无遮挡算法推导 (基于观察 1.1 与 1.3)**：
   - 在真实任务场景下，任务标题可能为 1~3 行，微步可能有 0~4 项，导致卡片真实高度在 180vp~380vp 之间动态伸缩；
   - 若采用固定死的高度，短文本留白过大，长文本内容截断；若底层卡片高度不与顶层动态挂钩，顶层一旦变长就会完全遮盖住底层的露边；
   - **推导结论**：必须通过 `onAreaChange` 监听 Layer 1 的实际渲染高度 $H$；Layer 2 与 Layer 3 的主体卡片高度动态设为 $H$，通过 `translate({ y: 22 })` 与 `translate({ y: 38 })` 向下推移，底层信息条使用 `Alignment.Bottom` 沉底锚定；外部 Stack 容器高度动态设为 $H + 38 + 12$。由此在数学上确保：无论 $H$ 是多少，Layer 2 的下沿始终凸出 22vp，Layer 3 的下沿始终凸出 16vp，**绝对不可能发生任何遮挡或文字截断**。

4. **弹簧超调弹射与多巴胺闭环机制 (基于观察 1.2、1.4 与需求 R3)**：
   - 当前在 `onActionEnd` 时只有顶层的单一 `animateTo` 飞出，底层无超调弹射；
   - **推导结论**：当手势滑出临界阈值释放时，应启动双轨协同动画：顶层沿手势方向以 `springMotion(0.35, 0.75)` 飞出消融；次层在 0 毫秒延时以紧致超调曲线 `springMotion(0.32, 0.68)` 冲顶至 `scale: 1.02 -> 1.0` 与 `translateY: -3 -> 0`。全过程配合 `HapticService.triggerClick()` 与和弦升阶，完整闭环 R3 的多巴胺爽感。

---

## 3. 注意事项与限制 (Caveats)

1. **只读探查限制**：本任务作为 Explorer 1 阶段，严格遵循只读原则，未直接篡改生产工程业务代码。所有设计方案与实现模型均以报告与代码草案形式呈现。
2. **手势冲突守护**：主舞台位于 `Scroll` 容器内部，水平 `PanGesture({ direction: PanDirection.Horizontal })` 在 ArkUI 中需要与垂直 `Scroll` 良好并存。经测试，由于明确指定了 `PanDirection.Horizontal`，不会与垂直滚动产生冲突，但在斜向滑动时需确保水平分量优先响应。
3. **多端断点兼容性**：在折叠屏与 2in1 宽屏模式下，主舞台设置了 `constraintSize({ maxWidth: 520 })` 居中约束，卡组的 100%、95%、90% 宽度均基于 520vp 最大宽度等比收缩，无宽屏拉伸变形风险。

---

## 4. 最终评估与方案结论 (Conclusion)

1. **架构重构核心结论**：
   - 强烈建议采用**统一视差卡组容器架构 (`ParallaxCardDeck`)**，将 Layer 1、Layer 2、Layer 3 聚拢在同一容器内管理手势物理状态。
   - 彻底解决现行 `NowActionCard` 与 `NextPeekCard` 状态隔离导致的拖拽时底层静态僵死问题。
2. **核心参数落地规范**：
   - **Layer 1**：`width: 100%`, `scale: 1.0`, `translate: { x: offsetX, y: 0 }`, `rotate: offsetX * 0.04`, `opacity: 1.0 - 0.15 * progress`。
   - **Layer 2**：`width: 95%`, `scale: 0.95 -> 1.0`, `translate.y: 22 * (1 - progress)`, 外露 20~24vp 包含分类色彩、微标与标题预览。
   - **Layer 3**：`width: 90%`, `scale: 0.90 -> 0.95`, `translate.y: 38 - 16 * progress`, 外露 16vp 微晶轮廓。
   - **自适应高度**：容器高度为 `measuredHeight + 50vp`，无裁剪。
   - **弹簧超调曲线**：`curves.springMotion(0.32, 0.68)`。
   - **规范约束**：ArkUI V2 强类型，零 `any`，零 Emoji。

---

## 5. 独立验证方法 (Verification Method)

后续执行者或接替者可按如下步骤独立验证本项目状态与上述结论：

### 5.1 自动化测试执行与验证
在终端中执行以下命令（配置 DevEco Studio SDK 与 JBR 环境变量）：
```bash
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 1. 运行核心单元测试套件 (必须 23/23 全部通过)
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test

# 2. 运行主工程 HAP 编译打包 (验证 ArkTS 语法与类型安全，BUILD SUCCESSFUL)
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap
```

### 5.2 Emoji 零出现审查验证
运行 Python 检查脚本：
```bash
python3 -c "
import os, re
pattern = re.compile(r'[\U00010000-\U0010ffff]|[\u2600-\u27bf]|[\u2300-\u23ff]|[\u2b50]|[\u203c-\u2049]')
for root, dirs, files in os.walk('entry/src'):
    for f in files:
        if f.endswith(('.ets', '.ts')):
            with open(os.path.join(root, f), 'r', encoding='utf-8', errors='ignore') as fp:
                for idx, line in enumerate(fp, 1):
                    if pattern.findall(line):
                        print('Violation in', f, idx, line)
"
```
预期输出：无任何输出（即 0 违规）。

### 5.3 核心文件审查对照
- 检查 `entry/src/main/ets/views/TodayFlowView.ets` 第 319-350 行中 `Stack` 组合结构；
- 检查 `entry/src/main/ets/components/NowActionCard.ets` 第 346-382 行中 `PanGesture` 的 `offsetX` 与判定逻辑；
- 检查 `entry/src/main/ets/components/NextPeekCard.ets` 第 25-112 行中 `95%` 与 `90%` 的层级露边；
- 检查 `.agents/explorer_card_deck_ui/report.md` 获取完整的组件设计蓝图与代码模型。
