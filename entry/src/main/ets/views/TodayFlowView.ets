/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Tab 1: Today Flow Master View (Now Only Single-Thread Flow Architecture)
 * Completely eliminates timestamps, timeline rails, and bin-packing stress.
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { Priority, TodoItem, TodoSource, TodoStatus } from '../models/TodoItem';
import { UserSettings } from '../models/UserSettings';
import { SingleThreadFlowEngine } from '../engine/SingleThreadFlowEngine';
import { NowActionCard } from '../components/NowActionCard';
import { NextPeekCard } from '../components/NextPeekCard';
import { ParallaxCardDeck } from '../components/ParallaxCardDeck';
import { TodayFootprintRibbon } from '../components/TodayFootprintRibbon';
import { QueueDrawer } from '../components/QueueDrawer';
import { GlobalUndoCapsule } from '../components/GlobalUndoCapsule';
import { StreakFreezeRevivalCard } from '../components/StreakFreezeRevivalCard';
import { HapticService } from '../common/media/HapticService';
import { UndoService } from '../common/utils/UndoService';
import { TimeUtils } from '../common/utils/TimeUtils';
import { TodoDao } from '../database/dao/TodoDao';
import { UserSettingsDao } from '../database/dao/UserSettingsDao';
import { MildAgingEngine } from '../engine/MildAgingEngine';
import { SampleDataLoader } from '../database/SampleDataLoader';
import { Logger } from '../common/utils/Logger';

@ComponentV2
export struct TodayFlowView {
  @Param settings: UserSettings = new UserSettings();
  @Param isInitialized: boolean = false;
  @Param refreshTrigger: number = 0;
  @Param isCreateTodoOpen: boolean = false;
  @Param topAvoidHeight: number = 0;
  @Param bottomAvoidHeight: number = 0;
  @Param isQueueDrawerOpen: boolean = false;
  @Event onQueueDrawerStateChange: (isOpen: boolean) => void = () => {};
  @Event onOpenFocus: (item: TodoItem) => void = () => {};
  @Event onOpenSunset: () => void = () => {};
  @Event onOpenSettings: () => void = () => {};
  @Event onOpenCreateTodo: () => void = () => {};

  @Local engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
  @Local streakShieldActive: boolean = false;
  @Local autoFrozenCount: number = 0;
  @Local streakDays: number = 7;
  @Local activeCardHeight: number = 240;

  @Monitor('refreshTrigger')
  onRefreshTriggerChanged(): void {
    this.refreshData();
  }

  @Monitor('isInitialized')
  onInitChanged(): void {
    if (this.isInitialized) {
      this.initViewData();
    }
  }

  async aboutToAppear(): Promise<void> {
    if (this.isInitialized) {
      await this.initViewData();
    }
  }

  private async initViewData(): Promise<void> {
    try {
      await SampleDataLoader.autoSeedIfBare();
      await this.checkStreakAndAging();
      await this.refreshData();
    } catch {
      // 容错兜底
    }
  }

  private async checkStreakAndAging(): Promise<void> {
    try {
      const currentSettings = await UserSettingsDao.getSettings();
      const now = Date.now();
      const TWO_DAYS_MS = 48 * 60 * 60 * 1000;

      if (currentSettings.lastActiveTimestamp > 0 && (now - currentSettings.lastActiveTimestamp) >= TWO_DAYS_MS) {
        // 用户离线超过 48 小时：触发杜林戈式连胜护盾与待办温和冷冻归档
        const activeTodos = await TodoDao.queryAllActive();
        let frozenCount = 0;

        for (const t of activeTodos) {
          if (t.dueDate > 0 && t.dueDate < now) {
            MildAgingEngine.freeze(t);
            await TodoDao.update(t);
            frozenCount++;
          }
        }

        currentSettings.streakShieldActive = true;
        currentSettings.lastActiveTimestamp = now;
        await UserSettingsDao.saveSettings(currentSettings);

        this.streakShieldActive = true;
        this.streakDays = currentSettings.streakDays > 0 ? currentSettings.streakDays : 7;
        this.autoFrozenCount = frozenCount;
      } else if (currentSettings.streakShieldActive) {
        this.streakShieldActive = true;
        this.streakDays = currentSettings.streakDays > 0 ? currentSettings.streakDays : 7;
      } else {
        currentSettings.lastActiveTimestamp = now;
        await UserSettingsDao.saveSettings(currentSettings);
      }
    } catch {
      // 容错兜底
    }
  }

  private async dismissStreakShield(): Promise<void> {
    try {
      this.streakShieldActive = false;
      const currentSettings = await UserSettingsDao.getSettings();
      currentSettings.streakShieldActive = false;
      currentSettings.lastActiveTimestamp = Date.now();
      await UserSettingsDao.saveSettings(currentSettings);
      await this.refreshData();
    } catch {
      // 容错兜底
    }
  }

  public async refreshData(): Promise<void> {
    try {
      const activeTodos = await TodoDao.queryAllActive();
      this.engine.load(activeTodos);
      Logger.info('TodayFlowView',
        'Refreshed flow engine. Active=%{public}s, NextQueue=%{public}d, Completed=%{public}d',
        this.engine.activeTask ? this.engine.activeTask.title : 'none',
        this.engine.nextQueue.length,
        this.engine.completedToday.length
      );
    } catch (e) {
      Logger.error('TodayFlowView', 'refreshData error: %{public}s', JSON.stringify(e));
    }
  }

  private async handleComplete(): Promise<void> {
    const completed = this.engine.completeActive();
    if (!completed) {
      return;
    }

    // 1. 数据层持久化更新 (多感官即时反馈已由 NowActionCard.executeFlyout 在提交瞬间触发，避免二次触发)
    await TodoDao.update(completed);

    // 2. 触发 5 秒无痛撤销胶囊
    UndoService.getInstance().showUndo(`已完成「${completed.title}」`, async () => {
      completed.status = TodoStatus.PENDING;
      completed.completedAt = 0;
      await TodoDao.update(completed);
      await this.refreshData();
    });
  }

  private async handleSkip(): Promise<void> {
    const skipped = this.engine.skipActive();
    if (!skipped) {
      return;
    }

    // 数据层持久化更新 (跳过微震反馈已由 NowActionCard.executeFlyout 在提交瞬间触发，避免二次触发)
    await TodoDao.update(skipped);
  }

  private handleFocus(item: TodoItem): void {
    this.onOpenFocus(item);
  }

  private async handleUndoCompleted(item: TodoItem): Promise<void> {
    const restored = this.engine.uncomplete(item.id);
    if (restored) {
      await TodoDao.update(restored);
      if (this.engine.activeTask) {
        await TodoDao.update(this.engine.activeTask);
      }
      HapticService.getInstance().triggerClick();
    }
  }

  private async handlePromote(id: string): Promise<void> {
    const success: boolean = this.engine.promoteToTop(id);
    if (success) {
      if (this.engine.activeTask) {
        await TodoDao.update(this.engine.activeTask);
      }
      HapticService.getInstance().triggerTick();
    }
  }

  private async handleTriageCryo(id: string): Promise<void> {
    const success: boolean = this.engine.triageToCryo(id);
    if (success) {
      const frozen: TodoItem | undefined = this.engine.frozenTasks.find((t: TodoItem): boolean => t.id === id);
      if (frozen) {
        await TodoDao.update(frozen);
      }
      if (this.engine.activeTask) {
        await TodoDao.update(this.engine.activeTask);
      }
      HapticService.getInstance().triggerTick();
    }
  }

  private getTodayHeaderDateText(): string {
    const d = new Date();
    const month = d.getMonth() + 1;
    const date = d.getDate();
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const week = weekDays[d.getDay()];
    return `${month}月${date}日 · ${week}`;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 1. 主视觉流滚动区域
      Scroll() {
        Column({ space: 16 }) {
          // 顶部状态栏避让占位
          Blank().height(this.topAvoidHeight > 0 ? this.topAvoidHeight : 8)

          // 2. 极简呼吸顶栏 (零时刻压迫，仅日期与状态)
          Row() {
            Column({ space: 4 }) {
              Row({ space: 6 }) {
                Image($r('app.media.ic_sparkle'))
                  .width(16)
                  .height(16)
                  .fillColor(ColorConstants.ACCENT_CORAL)

                Text('Aura · 心流主舞台')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorConstants.ACCENT_CORAL)
                  .letterSpacing(0.5)
              }

              Text(this.getTodayHeaderDateText())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Row({ space: 10 }) {
              // 今日进度轻量微标
              if (this.engine.completedToday.length > 0) {
                Row({ space: 4 }) {
                  Image($r('app.media.ic_check'))
                    .width(12)
                    .height(12)
                    .fillColor(ColorConstants.BLOCK_SAGE_GREEN)

                  Text(`${this.engine.completedToday.length} 步`)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorConstants.BLOCK_SAGE_GREEN)
                }
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(10)
                .backgroundColor(ColorConstants.BLOCK_SAGE_SOFT)
              }

              // 晚间打烊按钮
              Button({ type: ButtonType.Normal }) {
                Image($r('app.media.ic_sunset'))
                  .width(18)
                  .height(18)
                  .fillColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              }
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor('rgba(85, 70, 50, 0.06)')
              .onClick(() => {
                HapticService.getInstance().triggerClick();
                this.onOpenSunset();
              })

              // 设置入口
              Button({ type: ButtonType.Normal }) {
                Image($r('app.media.ic_gear'))
                  .width(18)
                  .height(18)
                  .fillColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              }
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor('rgba(85, 70, 50, 0.06)')
              .onClick(() => {
                HapticService.getInstance().triggerClick();
                this.onOpenSettings();
              })
            }
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })

          // 3. 连胜护盾卡片 (离线重返时温和保护)
          if (this.streakShieldActive) {
            StreakFreezeRevivalCard({
              streakDays: this.streakDays,
              frozenTaskCount: this.autoFrozenCount,
              onIgnite: () => {
                this.dismissStreakShield();
              }
            })
          }

          // 4. "Now Only" 单任务微晶主舞台 (视差卡组 ParallaxCardDeck 实时手势动力学堆叠)
          if (this.engine.activeTask !== null) {
            ParallaxCardDeck({
              activeTask: this.engine.activeTask,
              nextTask: this.engine.nextQueue.length > 0 ? this.engine.nextQueue[0] : null,
              thirdTask: this.engine.nextQueue.length > 1 ? this.engine.nextQueue[1] : null,
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
          } else {
            // 5. 禅意空态：今日所有心流微步已完成 (Zen All Clear)
            Column({ space: 16 }) {
              Image($r('app.media.ic_sparkle'))
                .width(44)
                .height(44)
                .fillColor(ColorConstants.BLOCK_SAGE_GREEN)

              Text('万籁俱寂，心流澄澈')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

              Text('今日所有心流微步已完成')
                .fontSize(15)
                .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)

              if (this.engine.completedToday.length > 0) {
                Row({ space: 6 }) {
                  Image($r('app.media.ic_check'))
                    .width(14)
                    .height(14)
                    .fillColor(ColorConstants.BLOCK_SAGE_GREEN)
                  Text(`今日已达成 ${this.engine.completedToday.length} 个微晶足迹`)
                    .fontSize(13)
                    .fontColor(ColorConstants.BLOCK_SAGE_GREEN)
                }
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .backgroundColor(ColorConstants.BLOCK_SAGE_SOFT)
                .borderRadius(14)

                Button('进入晚间打烊仪式')
                  .height(44)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .backgroundColor(ColorConstants.BLOCK_WARM_AMBER)
                  .borderRadius(22)
                  .padding({ left: 24, right: 24 })
                  .margin({ top: 8 })
                  .onClick(() => {
                    HapticService.getInstance().triggerClick();
                    this.onOpenSunset();
                  })
              } else {
                Button('开启第一步')
                  .height(44)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .backgroundColor(ColorConstants.ACCENT_CORAL)
                  .borderRadius(22)
                  .padding({ left: 24, right: 24 })
                  .margin({ top: 8 })
                  .onClick(() => {
                    HapticService.getInstance().triggerClick();
                    this.onOpenCreateTodo();
                  })
              }
            }
            .width('100%')
            .constraintSize({ maxWidth: 520 })
            .padding({ top: 56, bottom: 56, left: 24, right: 24 })
            .borderRadius(24)
            .backgroundColor(ColorConstants.LIGHT_CARD_BG)
            .border({ width: 1, color: ColorConstants.LIGHT_CARD_BORDER })
            .shadow({ radius: 20, color: 'rgba(85, 70, 50, 0.06)', offsetY: 6 })
            .alignItems(HorizontalAlign.Center)
            .margin({ top: 24, bottom: 20 })
          }

          // 5. 今日心流足迹·微晶里程碑 (零时间压迫的正向多巴胺反馈)
          TodayFootprintRibbon({
            completedItems: this.engine.completedToday,
            onUndoItem: (item: TodoItem) => {
              this.handleUndoCompleted(item);
            },
            onOpenSunset: () => {
              this.onOpenSunset();
            }
          })
          .margin({ top: 4, bottom: 8 })

          // 底部留白，保障悬浮组件不遮挡
          Blank().height(140)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 20 })
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
      .linearGradientBlur(22, {
        fractionStops: [
          [1.0, 0.0],
          [0.65, 0.03],
          [0.15, 0.06],
          [0.0, 0.085]
        ],
        direction: GradientDirection.Bottom
      })

      // 遮罩蒙层 (抽屉展开时点击背景快速收起)
      if (this.isQueueDrawerOpen) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.22)')
          .onClick(() => {
            this.onQueueDrawerStateChange(false);
          })
          .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
      }

      // 底部轻量待办序列抽屉 (收起时浮于 Dock 之上 12vp，展开时滑出沉浸抽屉)
      QueueDrawer({
        nextQueue: this.engine.nextQueue,
        parkingQueue: this.engine.parkingQueue,
        isExpanded: this.isQueueDrawerOpen,
        bottomAvoidHeight: this.bottomAvoidHeight,
        onExpandedChange: (expanded: boolean) => {
          this.onQueueDrawerStateChange(expanded);
        },
        onPromote: (id: string) => {
          this.handlePromote(id);
        },
        onTriageCryo: (id: string) => {
          this.handleTriageCryo(id);
        }
      })
      .width('100%')
      .margin({
        bottom: this.isQueueDrawerOpen
          ? 0
          : (this.bottomAvoidHeight > 0 ? this.bottomAvoidHeight + 76 : 88)
      })
      .animation({ duration: 240, curve: Curve.FastOutSlowIn })

      // 右下角纯净温润悬浮按钮 (FAB `+`)，与待办序列胶囊处于同一水平视觉基准线
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('+')
          .fontSize(26)
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
      }
      .width(52)
      .height(52)
      .backgroundColor(ColorConstants.ACCENT_CORAL)
      .shadow({
        radius: 16,
        color: 'rgba(232, 122, 100, 0.35)',
        offsetY: 6
      })
      .margin({
        right: 20,
        bottom: this.bottomAvoidHeight > 0 ? this.bottomAvoidHeight + 66 : 78
      })
      .opacity(this.isQueueDrawerOpen ? 0 : 1)
      .hitTestBehavior(this.isQueueDrawerOpen ? HitTestMode.None : HitTestMode.Default)
      .animation({ duration: 200 })
      .onClick(() => {
        HapticService.getInstance().triggerClick();
        this.onOpenCreateTodo();
      })

      // 全局撤销悬浮微胶囊
      GlobalUndoCapsule()

      // 顶部微晶渐变模糊遮罩 (紧凑范围，零触摸阻断，聚焦状态栏极窄消融)
      Row()
        .width('100%')
        .height(this.topAvoidHeight > 0 ? this.topAvoidHeight + 16 : 38)
        .position({ x: 0, y: 0 })
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(250, 248, 245, 0.96)', 0.0],
            ['rgba(250, 248, 245, 0.65)', 0.45],
            ['rgba(250, 248, 245, 0.00)', 1.0]
          ]
        })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
  }
}
