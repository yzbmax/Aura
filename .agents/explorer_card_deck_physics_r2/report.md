# Aura 视差卡组物理动力学审查与 8.35% 超调回弹接线分析报告

- **报告主体**: Explorer Physics R2
- **任务目标**: 审查 `CurveConstants.SPRING_CARD_SNAP_FOCUS = curves.springMotion(0.34, 0.62)` 弹簧物理参数，验证 `NextPeekCard` 与 `ParallaxCardDeck` 的接线机制以达成次层卡片（Layer 2）弹射就位时的 8.35% 真实垂直微过冲回弹，并为 `LocalUnit.test.ets` 设计防劣化自动化回归单元测试。
- **关联缺陷**: Reviewer Handoff F-02 (Major - `SPRING_CARD_SNAP_FOCUS` 被孤立未接线), F-01 (Major - 多感官重复触发), F-03 (Minor - 缩放锚点中心收缩)。

---

## 1. 核心结论与速览 (Executive Summary)

1. **数学与物理参数真实性验证通过（100% 成立）**：
   - 华为 ArkUI `curves.springMotion(0.34, 0.62)` 对应的二阶欠阻尼质量-弹簧-阻尼系统参数为：响应时间 $T = 0.34\text{s}$，阻尼比 $\zeta = 0.62$。
   - 理论最大超调比率严格满足经典动力学闭式解：
     $$M_p = \exp\left(-\frac{\pi \zeta}{\sqrt{1 - \zeta^2}}\right) = \exp\left(-\frac{0.62 \pi}{\sqrt{1 - 0.62^2}}\right) \approx 0.0835338 \approx \mathbf{8.35\%}$$
   - 在次层（Layer 2）基准位移行程 $\Delta Y = 22.0\text{vp}$（或 $24.0\text{vp}$）下，垂直过冲距离精准对应为 **$1.84\text{vp}$**（或 **$2.00\text{vp}$**），首次过冲峰值时刻发生于 $t_p \approx \mathbf{216.6\text{ms}}$，并在 $t_s \approx \mathbf{340\text{ms}}$ 内紧致收敛至 $0\text{vp}$。物理触感清脆机械，无多余晃动。

2. **缺陷 F-02 根因定位与架构陷阱排查**：
   - **根因**：当前 `NowActionCard.ets:54-75` 的 `executeFlyout` 中，将 `this.onGestureProgressChange(1.0, targetX, 0)` 错误包裹在顶层飞牌专用的 `animateTo({ curve: CurveConstants.SPRING_CARD_FLYOUT })`（$\zeta = 0.82$, 属于近过阻尼/无回弹曲线，超调仅 $1.11\%$）内部，导致次层卡片的位移和缩放完全被 `SPRING_CARD_FLYOUT` 劫持；而 `CurveConstants.SPRING_CARD_SNAP_FOCUS` 被完全孤立。
   - **重大陷阱预警**：**严禁在 `NextPeekCard` 属性上无条件附加 `.animation({ curve: CurveConstants.SPRING_CARD_SNAP_FOCUS })`**！因为若属性动画常驻，用户在拖拽顶层卡片（`PanGesture.onActionUpdate`）时，每一帧微小位移都会触发 340ms 弹簧响应，导致底层卡片严重滞后、拖手、颤动，彻底破坏 R1（1:1 实时手势动力学跟随）要求。
   - **推荐架构解法**：在 `NowActionCard.executeFlyout` 提交阶段实施**双轨协同 `animateTo` 解耦**——顶层飞牌使用 `SPRING_CARD_FLYOUT`（0.30, 0.82, 260ms 出界）；次层弹射使用 `SPRING_CARD_SNAP_FOCUS`（0.34, 0.62, 340ms 弹射就位），并在 340ms 弹射收敛后触发队列推进，确保用户完整感受这枚 8.35% 的多巴胺微弹。

3. **单元测试与回归门禁升级**：
   - 在 `CardDeckKinematics.ets` 中显式固化弹簧物理参数基准与时域响应解析方程。
   - 在 `LocalUnit.test.ets` 中新增 3 项高严苛测试（测试项总数由 31 项扩充至 34 项），全面锁死超调比率（8.35%）、时域峰值时刻（216.6ms）、双弹簧阻尼比差分（$7.5\times$ 弹性差异）及常量导出的完整性。

---

## 2. 物理与数学深度推导 (Physics & Kinematic Proof)

### 2.1 ArkUI `curves.springMotion` 动力学方程推导

在 HarmonyOS ArkUI 中，`curves.springMotion(response, dampingRatio, overlapDuration)` 构建了标准的二阶质量-弹簧-阻尼动力学系统：
$$m \ddot{y}(t) + c \dot{y}(t) + k (y(t) - y_{\text{target}}) = 0$$

将其标准化为固有角频率 $\omega_n$ 与阻尼比 $\zeta$ 的形式：
$$\ddot{y}(t) + 2\zeta\omega_n \dot{y}(t) + \omega_n^2 (y(t) - y_{\text{target}}) = 0$$

参数映射关系如下：
1. **响应时间（Response Time）**：$T_{\text{response}} = 0.34\text{s}$
   无阻尼固有角频率为：
   $$\omega_n = \frac{2\pi}{T_{\text{response}}} = \frac{2\pi}{0.34} \approx 18.4799 \text{ rad/s}$$
2. **阻尼比（Damping Ratio）**：$\zeta = 0.62$
   由于 $0 < \zeta < 1$，系统处于严格的**欠阻尼状态（Underdamped System）**。
3. **有阻尼振荡角频率（Damped Angular Frequency）**：
   $$\omega_d = \omega_n \sqrt{1 - \zeta^2} = 18.4799 \times \sqrt{1 - 0.62^2} = 18.4799 \times 0.784602 \approx \mathbf{14.500 \text{ rad/s}}$$

### 2.2 阶跃响应与时域过冲极值

卡片从初始静止位移 $y(0) = Y_{\text{base}}$ 释放向目标平衡点 $y_{\text{target}} = 0$ 运动。其归一化无量纲阶跃响应函数为：
$$s(t) = 1 - e^{-\zeta \omega_n t} \left( \cos(\omega_d t) + \frac{\zeta}{\sqrt{1 - \zeta^2}} \sin(\omega_d t) \right)$$

求导确定速度零点 $\dot{s}(t) = 0$：
$$\dot{s}(t) = \frac{\omega_n}{\sqrt{1 - \zeta^2}} e^{-\zeta \omega_n t} \sin(\omega_d t) = 0$$

首次速度归零点（即卡片向上冲过目标平衡点达到最顶峰的时刻 $t_p$）发生于：
$$\omega_d t_p = \pi \implies t_p = \frac{\pi}{\omega_d} = \frac{\pi}{14.500} \approx \mathbf{0.2166 \text{ s} = 216.6 \text{ ms}}$$

在 $t_p$ 时刻将 $\sin(\pi) = 0, \cos(\pi) = -1$ 代入响应方程，得到理论最大超调量 $M_p$：
$$s(t_p) = 1 - e^{-\zeta \omega_n \frac{\pi}{\omega_d}} (-1) = 1 + \exp\left(-\frac{\zeta \pi}{\sqrt{1 - \zeta^2}}\right)$$
$$M_p = \exp\left(-\frac{\zeta \pi}{\sqrt{1 - \zeta^2}}\right)$$

代入 $\zeta = 0.62$：
$$\frac{\zeta \pi}{\sqrt{1 - \zeta^2}} = \frac{0.62 \times \pi}{0.784602} = \frac{1.947787}{0.784602} \approx 2.482517$$
$$M_p = e^{-2.482517} = 0.08353381 \implies \mathbf{8.353\% \approx 8.35\%}$$

### 2.3 空间几何位移与收敛包络

| 参数项 | 公式 / 计算值 | 物理含义与用户视感 |
|---|---|---|
| **行程基准 $\Delta Y_1$** | $22.0\text{vp}$ | 静止待机时 Layer 2 拟物下沉距离 |
| **过冲峰值高度 $\Delta Y_{\text{overshoot}, 1}$** | $22.0 \times 8.353\% = \mathbf{1.838\text{vp}}$ | 卡片冲过 $0\text{vp}$ 向上反弹至 $-1.84\text{vp}$ |
| **行程基准 $\Delta Y_2$** | $24.0\text{vp}$ | 外露拟物操作条高度 |
| **过冲峰值高度 $\Delta Y_{\text{overshoot}, 2}$** | $24.0 \times 8.353\% = \mathbf{2.005\text{vp}}$ | 约 $2.0\text{vp}$ 的物理微晶回弹 |
| **峰值时刻 $t_p$** | $216.6\text{ms}$ | 释放后约 0.22 秒达到最高过冲点 |
| **2% 误差收敛时间 $t_s$** | $t_s \approx \frac{4}{\zeta \omega_n} \approx \frac{4}{0.62 \times 18.48} \approx \mathbf{349\text{ms}}$ | 340~350ms 内完全回稳至 $0\text{vp}$ |

对比飞离曲线与弹射曲线的物理特性差异：
- **`SPRING_CARD_FLYOUT`** ($\zeta = 0.82$)：超调量 $M_p = \exp\left(-\frac{0.82\pi}{\sqrt{1-0.82^2}}\right) \approx 1.11\%$。近乎临界阻尼，顶层卡片飞出屏幕时利落干脆，绝不向屏幕内反弹回扑。
- **`SPRING_CARD_SNAP_FOCUS`** ($\zeta = 0.62$)：超调量 $M_p \approx 8.35\%$。次层卡片由下而上弹入时，产生鲜明的单次机械微弹簧顿挫，视觉与触觉反馈极度扎实。
- **超调弹性倍率**：$\frac{8.35\%}{1.11\%} \approx \mathbf{7.52 \text{ 倍}}$。

---

## 3. ArkUI 卡片堆叠架构与动画接线方案

### 3.1 现状缺陷诊断：为何 `SPRING_CARD_SNAP_FOCUS` 会被孤立？

在现存代码 `entry/src/main/ets/components/NowActionCard.ets:54-75` 中：
```typescript
// 顶层卡片飞出动画 (高爆发弹簧，260ms 内飞离消融)
animateTo({
  curve: CurveConstants.SPRING_CARD_FLYOUT, // 错误：此曲线 damping = 0.82
  onFinish: () => {
    ...
  }
}, () => {
  this.offsetX = targetX;
  this.rotateAngle = targetAngle;
  this.cardOpacity = 0.0;
  // 致命问题：在此处触发底层进度通知，导致底层也继承了 SPRING_CARD_FLYOUT
  this.onGestureProgressChange(1.0, targetX, 0);
});
```
由于 `this.onGestureProgressChange(1.0)` 会更新 `ParallaxCardDeck.gestureProgress`，而 `NextPeekCard` 的 `translateY` 与 `scale` 均响应式绑定于 `gestureProgress`，因此整个底层完全运行在 `SPRING_CARD_FLYOUT` 之下。定义好的 `SPRING_CARD_SNAP_FOCUS` 从未被传入任何渲染调度器中。

### 3.2 方案比选：显式双轨 `animateTo` vs `NextPeekCard` 内部 `.animation()`

| 评估维度 | 方案 A: `NextPeekCard` 加 `.animation()` | 方案 B: 显式双轨 `animateTo` 解耦（推荐） |
|---|---|---|
| **拖拽实时跟随（R1）** | **严重翻车**：用户拖拽过程中，每一帧 `gestureProgress` 的变更都会被拦截并施加 340ms 弹簧，导致严重迟滞与抖动 | **完美契合**：拖拽阶段保持纯数据直通（无动画拦截），达到原生 120Hz 1:1 跟手 |
| **释放弹射超调（R3）** | 难以在拖拽态与释放态之间安全切换动画曲线 | **精准控制**：释放时顶层与底层分别应用各自的最佳物理弹簧曲线 |
| **ArkUI V2 规范遵从** | 容易发生状态拦截污染 | 完全遵从声明式状态提升与显式转场规范 |
| **生命周期同步性** | 缺乏可靠的 `onFinish` 回调通知数据层切项 | 底层弹簧 340ms 到位后精确触发 `onComplete/onSkip` |

### 3.3 实施方案详解（推荐给 Worker 的代码调整）

#### 1) `NowActionCard.ets`：双轨解耦与多感官重复消除
```typescript
  private executeFlyout(isComplete: boolean): void {
    if (this.isAnimatingTransition) {
      return;
    }
    this.isAnimatingTransition = true;

    // 即时多感官反馈 (仅在此处触发 1 次，修复 F-01)
    if (isComplete) {
      AudioService.getInstance().playChordStep();
      HapticService.getInstance().triggerClick();
    } else {
      HapticService.getInstance().triggerTick();
    }

    const targetX: number = isComplete ? CardDeckKinematics.EXIT_TRANSLATE_X : -CardDeckKinematics.EXIT_TRANSLATE_X;
    const targetAngle: number = isComplete ? CardDeckKinematics.EXIT_ROTATE_ANGLE : -CardDeckKinematics.EXIT_ROTATE_ANGLE;

    // 轨 1: 顶层卡片飞离消融 (高爆发弹簧 0.30, 0.82，260ms 内彻底出界)
    animateTo({
      curve: CurveConstants.SPRING_CARD_FLYOUT,
      onFinish: () => {
        this.offsetX = 0;
        this.offsetY = 0;
        this.rotateAngle = 0;
        this.cardOpacity = 1.0;
        this.hapticHysteresis.reset();
      }
    }, () => {
      this.offsetX = targetX;
      this.rotateAngle = targetAngle;
      this.cardOpacity = 0.0;
    });

    // 轨 2: 次层卡片超调弹射就位 (欠阻尼弹簧 0.34, 0.62，提供真实 8.35% 垂直过冲回弹)
    animateTo({
      curve: CurveConstants.SPRING_CARD_SNAP_FOCUS,
      onFinish: () => {
        // 次层卡片 340ms 完成超调并平稳停靠焦点位置，平滑交接数据层
        this.onGestureProgressChange(0.0, 0, 0);
        this.isAnimatingTransition = false;
        if (isComplete) {
          this.onComplete();
        } else {
          this.onSkip();
        }
      }
    }, () => {
      // 触发 ParallaxCardDeck.gestureProgress 从当前拖拽位置平滑弹射至 1.0
      this.onGestureProgressChange(1.0, targetX, 0);
    });
  }
```

#### 2) `NextPeekCard.ets`：缩放锚点优化（解决 F-03）
将 Layer 2 和 Layer 3 的 `.scale(...)` 补充锚点，防止缩放时向中心收缩：
```typescript
  // Layer 2
  .scale({
    x: CardDeckKinematics.calcLayer2Scale(this.gestureProgress),
    y: CardDeckKinematics.calcLayer2Scale(this.gestureProgress),
    centerX: '50%',
    centerY: '100%' // 底部锚定，保持拟物外露边缘稳定
  })

  // Layer 3
  .scale({
    x: CardDeckKinematics.calcLayer3Scale(this.gestureProgress),
    y: CardDeckKinematics.calcLayer3Scale(this.gestureProgress),
    centerX: '50%',
    centerY: '100%' // 底部锚定
  })
```

#### 3) `TodayFlowView.ets`：移除重复反馈（彻底解决 F-01）
在 `TodayFlowView.ets:147-148` 与 `line 168` 中：
移除重复调用的 `AudioService.getInstance().playChordStep()` 与 `HapticService`，交由手势释放瞬间由 `NowActionCard` 统一触发。这样可确保用户单次划卡只触发一次清脆和弦升阶与触觉震动。

---

## 4. 自动化单元测试设计 (Regression Test Suite)

为了确保该物理接线、弹簧阻尼比与时域超调特征被永久性纳入 CI/门禁，建议在 `CardDeckKinematics.ets` 与 `LocalUnit.test.ets` 中扩充以下能力：

### 4.1 `CardDeckKinematics.ets` 补充时域解析函数
```typescript
  // 弹簧物理动力学参数基准
  public static readonly SPRING_SNAP_RESPONSE: number = 0.34;
  public static readonly SPRING_SNAP_DAMPING: number = 0.62;
  public static readonly SPRING_FLYOUT_RESPONSE: number = 0.30;
  public static readonly SPRING_FLYOUT_DAMPING: number = 0.82;
  public static readonly SPRING_RESET_RESPONSE: number = 0.28;
  public static readonly SPRING_RESET_DAMPING: number = 0.76;

  /**
   * 计算二阶弹簧固有角频率 omega_n = 2 * pi / response
   */
  public static calcNaturalFrequency(response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE): number {
    return (2.0 * Math.PI) / response;
  }

  /**
   * 计算二阶弹簧阻尼角频率 omega_d = omega_n * sqrt(1 - zeta^2)
   */
  public static calcDampedFrequency(
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    const wn = CardDeckKinematics.calcNaturalFrequency(response);
    return wn * Math.sqrt(1.0 - (zeta * zeta));
  }

  /**
   * 计算首次过冲峰值时间 (秒) tp = pi / omega_d
   */
  public static calcPeakOvershootTime(
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    const wd = CardDeckKinematics.calcDampedFrequency(response, zeta);
    return Math.PI / wd;
  }

  /**
   * 计算二阶弹簧在任意时间 t (秒) 的阶跃响应比例 [0, 1 + Mp]
   */
  public static calcSpringStepResponse(
    t: number,
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    if (t <= 0) {
      return 0.0;
    }
    const wn = CardDeckKinematics.calcNaturalFrequency(response);
    const wd = CardDeckKinematics.calcDampedFrequency(response, zeta);
    const decay = Math.exp(-zeta * wn * t);
    const harmonic = Math.cos(wd * t) + ((zeta / Math.sqrt(1.0 - (zeta * zeta))) * Math.sin(wd * t));
    return 1.0 - (decay * harmonic);
  }

  /**
   * 计算弹簧运动在时间 t (秒) 下的实际卡片位移 Y (vp)
   */
  public static calcSpringOffsetY(
    t: number,
    startY: number,
    targetY: number = 0.0,
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    const step = CardDeckKinematics.calcSpringStepResponse(t, response, zeta);
    return startY + ((targetY - startY) * step);
  }
```

### 4.2 `LocalUnit.test.ets` 新增单测用例定义

#### 用例 32: `testCardDeckSpringSnapFocusTheoreticalTrajectory`
- **目的**：断言 8.35% 超调量与 216.6ms 峰值时刻在时域轨迹中严格复现。
- **断言逻辑**：
  1. $M_p = \text{calcSpringOvershootRatio}(0.62) \in [0.0835, 0.0836]$；
  2. 峰值时间 $t_p = \text{calcPeakOvershootTime}(0.34, 0.62) \in [0.215, 0.218]$；
  3. $t = t_p$ 时，行程 22vp 的瞬时位移为 $-1.838\text{vp}$（反向过冲），$y(t_p) < 0$ 且 $|y(t_p)| > 1.8$；
  4. $t = 0.34\text{s}$ 时，$|y(t) - 0| \le 0.1\text{vp}$，证明已收敛归位。

#### 用例 33: `testCardDeckDualSpringDampingDifferentiation`
- **目的**：断言飞牌弹簧与次层弹簧物理阻尼的显著分化（防死板、防反扑）。
- **断言逻辑**：
  1. 飞牌弹簧 ($\zeta = 0.82$) 超调率 $< 0.015$（临界过阻尼，绝无弹回）；
  2. 次层弹簧 ($\zeta = 0.62$) 超调率 $\approx 0.0835$（显著机械回弹）；
  3. 回位弹簧 ($\zeta = 0.76$) 超调率 $< 0.03$；
  4. 验证 $\frac{M_{p, \text{snap}}}{M_{p, \text{flyout}}} \ge 7.0$。

#### 用例 34: `testCardDeckSnapFocusCurveWiringAndConstantsIntegrity`
- **目的**：断言 `CurveConstants` 中的常量导出非空，且物理参数基准在各模块间严格恒等，杜绝孤立常量再次发生。

---

## 5. 建议实施路线图 (Action Plan for Worker)

| 步骤 | 改动目标文件 | 核心改动 | 风险把控 |
|---|---|---|---|
| **Step 1** | `NowActionCard.ets` | 分解 `executeFlyout` 为双轨 `animateTo`，底层进度绑定 `SPRING_CARD_SNAP_FOCUS`；保留单次多感官调用 | 检查 `isAnimatingTransition` 门禁，避免重复触发 |
| **Step 2** | `TodayFlowView.ets` | 移除 `handleComplete` 与 `handleSkip` 中重复的 `AudioService` / `HapticService` | 保持持久化与撤销胶囊逻辑完好 |
| **Step 3** | `NextPeekCard.ets` | 为 Layer 2 / Layer 3 补充 `centerX: '50%', centerY: '100%'` | 确保底部拟物边缘不抖动 |
| **Step 4** | `CardDeckKinematics.ets` | 补充二阶弹簧时域响应解析函数与参数常量 | 强类型，0 any，0 emoji |
| **Step 5** | `LocalUnit.test.ets` | 追加测试项 32、33、34 | 验证 `hvigorw test` 34/34 全部 PASS |

---

## 6. 验证命令集 (Verification Commands)

```bash
# 1. 运行完整自动化单元测试套件 (期望 34/34 项全部通过)
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test

# 2. 检查测试结果文件
cat entry/.test/default/intermediates/test/coverage_data/test_result.txt

# 3. 验证主工程 HAP 编译通过
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
```
