/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Focus Immersion Page: Zen Melting Hourglass & Fluid Timing Field
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TimingMode, TodoItem, TodoSource, TodoStatus } from '../models/TodoItem';
import { ParkingLotInputBar } from '../components/ParkingLotInputBar';
import { AudioService } from '../common/media/AudioService';
import { HapticService } from '../common/media/HapticService';
import { TodoDao } from '../database/dao/TodoDao';
import { TimeUtils } from '../common/utils/TimeUtils';
import { WatchSyncService } from '../engine/WatchSyncService';
import { FocusSyncState, SyncAction } from '../models/WatchSyncModel';
import { LiveViewService } from '../engine/LiveViewService';
import { MicroStepIcebreaker } from '../components/concept/MicroStepIcebreaker';

@ComponentV2
export struct FocusImmersionPage {
  @Param item: TodoItem = new TodoItem();
  @Event onClose: () => void = () => {};

  @Local elapsedSeconds: number = 0;
  @Local isRunning: boolean = true;
  @Local isIcebroken: boolean = true;
  @Local isShowingIcebreaker: boolean = false;
  @Local showPeekTime: boolean = false;
  @Local topAvoidHeight: number = 38;
  @Local bottomAvoidHeight: number = 24;
  private timerId: number = -1;
  private peekTimerId: number = -1;

  private remoteListener = (state: FocusSyncState): void => {
    if (state.action === SyncAction.PAUSE && this.isRunning) {
      this.isRunning = false;
      this.stopTimer();
    } else if (state.action === SyncAction.RESUME && !this.isRunning) {
      this.isRunning = true;
      this.startTimer();
    } else if (state.action === SyncAction.COMPLETE) {
      this.handleComplete();
    }
  };

  aboutToAppear(): void {
    const topPx = AppStorage.get<number>('topAvoidPx') ?? 0;
    const bottomPx = AppStorage.get<number>('bottomAvoidPx') ?? 0;
    if (topPx > 0) {
      this.topAvoidHeight = px2vp(topPx);
    }
    if (bottomPx > 0) {
      this.bottomAvoidHeight = px2vp(bottomPx);
    }

    // 默认判断：若为未知复杂度或预估 >= 45m 大任务，保留破冰待命状态
    if (this.item.estimatedMinutes >= 45) {
      this.isIcebroken = false;
    }

    const totalSec = Math.max(5, this.item.estimatedMinutes) * 60;
    LiveViewService.getInstance().startLiveView(this.item, totalSec);
    WatchSyncService.getInstance().syncFocusStart(this.item);
    WatchSyncService.getInstance().subscribeState(this.remoteListener);
    this.startTimer();
  }

  aboutToDisappear(): void {
    this.stopTimer();
    if (this.peekTimerId !== -1) {
      clearTimeout(this.peekTimerId);
      this.peekTimerId = -1;
    }
    LiveViewService.getInstance().stopLiveView();
    WatchSyncService.getInstance().unsubscribeState(this.remoteListener);
    WatchSyncService.getInstance().syncFocusStop();
  }

  private handlePeekProgress(): void {
    HapticService.getInstance().triggerTick();
    this.showPeekTime = true;
    if (this.peekTimerId !== -1) {
      clearTimeout(this.peekTimerId);
    }
    this.peekTimerId = setTimeout(() => {
      this.showPeekTime = false;
      this.peekTimerId = -1;
    }, 2500);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 24 }) {
        // 1. 顶栏导航与退出
        Row() {
          Button('‹ 返回时间轴')
            .fontSize(13)
            .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
            .backgroundColor('rgba(0,0,0,0.04)')
            .height(30)
            .onClick(() => {
              this.handleExit();
            })

          Blank()

          Text(this.item.timingMode === TimingMode.STOPWATCH ? '流体正计时模式' : '时间箱探索切片')
            .fontSize(12)
            .fontColor(ColorConstants.ACCENT_CORAL)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })

        // 2. 专注任务名称与按需微步破冰
        Column({ space: 8 }) {
          Text('正在沉浸')
            .fontSize(12)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          Text(this.item.title || '专注心流')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            .textAlign(TextAlign.Center)
            .padding({ left: 24, right: 24 })

          if (!this.isIcebroken && !this.isShowingIcebreaker) {
            Button({ type: ButtonType.Capsule }) {
              Row({ space: 4 }) {
                Image($r('app.media.ic_sparkle'))
                  .width(11)
                  .height(11)
                  .fillColor(ColorConstants.BLOCK_SAGE_GREEN)
                Text('感到阻力？尝试微步破冰')
                  .fontSize(11)
                  .fontColor(ColorConstants.BLOCK_SAGE_GREEN)
              }
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
            }
            .backgroundColor(ColorConstants.BLOCK_SAGE_SOFT)
            .height(26)
            .onClick(() => {
              this.isShowingIcebreaker = true;
            })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        if (this.isShowingIcebreaker) {
          // 微物理阻尼非线性破冰舱 (按需展开，击碎 ADHD 启动瘫痪)
          MicroStepIcebreaker({
            taskTitle: this.item.title,
            onIcebroken: () => {
              this.isShowingIcebreaker = false;
              this.isIcebroken = true;
              if (!this.isRunning) {
                this.isRunning = true;
                this.startTimer();
              }
            },
            onSkip: () => {
              this.isShowingIcebreaker = false;
              this.isIcebroken = true;
            }
          })
          .margin({ left: 20, right: 20 })
        } else {
          // 3. 禅意物理融化微沙漏 (纯净光晕与羊脂玉水膜，消灭催命数字倒数，支持轻触偷看)
          Stack({ alignContent: Alignment.Center }) {
            // 外层呼吸光晕 (暖珊瑚陶土)
            Circle({ width: 220, height: 220 })
              .fill('rgba(232, 122, 100, 0.08)')
              .blur(40)

            // 中层原木鼠尾草绿光晕
            Circle({ width: 160, height: 160 })
              .fill('rgba(98, 138, 97, 0.12)')
              .blur(24)

            // 内层核心水膜球体
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 96, height: 96 })
                .fill('rgba(255, 255, 255, 0.90)')
                .border({ width: 1, color: 'rgba(232, 122, 100, 0.20)' })
                .shadow({ radius: 16, color: 'rgba(85, 70, 50, 0.08)', offsetY: 4 })

              if (this.showPeekTime) {
                // 轻触浮现整分钟标签 (2.5 秒后平滑隐退)
                Column({ space: 2 }) {
                  Text(`${Math.max(1, Math.floor(this.elapsedSeconds / 60))}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ColorConstants.ACCENT_CORAL)
                  Text('MINUTES')
                    .fontSize(9)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                    .letterSpacing(1)
                }
                .transition(TransitionEffect.OPACITY.animation({ duration: 250 }))
              } else {
                // 默认纯净禅意状态：仅静谧沙漏图标与轻触感知指引
                Column({ space: 4 }) {
                  Image($r('app.media.ic_hourglass'))
                    .width(22)
                    .height(22)
                    .fillColor(this.isRunning ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_TERTIARY)
                  Text('静心沉浸')
                    .fontSize(10)
                    .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                }
                .transition(TransitionEffect.OPACITY.animation({ duration: 250 }))
              }
            }
            .width(96)
            .height(96)
            .onClick(() => {
              this.handlePeekProgress();
            })
          }
          .height(230)
          .width('100%')

          // 4. 操作按钮栏
          Row({ space: 16 }) {
            Button(this.isRunning ? '暂停' : '继续')
              .fontSize(14)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              .backgroundColor('rgba(0,0,0,0.06)')
              .height(40)
              .layoutWeight(1)
              .onClick(() => {
                if (this.isRunning) {
                  this.stopTimer();
                  const totalSec = Math.max(5, this.item.estimatedMinutes) * 60;
                  const remainingSec = Math.max(0, totalSec - this.elapsedSeconds);
                  LiveViewService.getInstance().updateLiveView(this.item, remainingSec, false);
                } else {
                  this.startTimer();
                }
                this.isRunning = !this.isRunning;
                HapticService.getInstance().triggerTick();
              })

            Button({ type: ButtonType.Capsule }) {
              Row({ space: 4 }) {
                Image($r('app.media.ic_check'))
                  .width(14)
                  .height(14)
                  .fillColor(Color.White)
                Text('完成此项')
                  .fontSize(14)
                  .fontColor(Color.White)
              }
            }
            .backgroundColor(ColorConstants.ACCENT_CORAL)
            .height(40)
            .layoutWeight(1)
            .onClick(() => {
              this.handleComplete();
            })
          }
          .width('86%')
        }

        Blank()

        // 5. 底部常驻【杂念停机坪】(专注中走神秒级停泊，零打断)
        Column({ space: 6 }) {
          Text('走神了？敲回车秒停泊，安心留给打烊复盘')
            .fontSize(11)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

          ParkingLotInputBar({
            onParkingSubmit: (text: string) => {
              this.handleParkThought(text);
            }
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.topAvoidHeight, bottom: this.bottomAvoidHeight })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private startTimer(): void {
    this.stopTimer();
    this.timerId = setInterval(() => {
      this.elapsedSeconds++;
      WatchSyncService.getInstance().syncFocusTick(this.elapsedSeconds);
      const totalSec = Math.max(5, this.item.estimatedMinutes) * 60;
      const remainingSec = Math.max(0, totalSec - this.elapsedSeconds);
      LiveViewService.getInstance().updateLiveView(this.item, remainingSec, this.isRunning);
    }, 1000);
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private async handleExit(): Promise<void> {
    this.stopTimer();
    LiveViewService.getInstance().stopLiveView();
    WatchSyncService.getInstance().syncFocusStop();
    const addedMinutes = Math.round(this.elapsedSeconds / 60);
    this.item.actualMinutes += addedMinutes;
    await TodoDao.update(this.item);
    this.onClose();
  }

  private async handleComplete(): Promise<void> {
    this.stopTimer();
    LiveViewService.getInstance().stopLiveView();
    WatchSyncService.getInstance().syncFocusComplete();
    const addedMinutes = Math.round(this.elapsedSeconds / 60);
    this.item.actualMinutes += addedMinutes;
    this.item.status = TodoStatus.COMPLETED;
    this.item.completedAt = Date.now();

    AudioService.getInstance().playChordStep();
    HapticService.getInstance().triggerClick();

    await TodoDao.update(this.item);
    this.onClose();
  }

  private async handleParkThought(text: string): Promise<void> {
    const thought = new TodoItem(TimeUtils.generateUUID(), text, 25);
    thought.source = TodoSource.PARKING_LOT;
    thought.scheduledStartAt = 0;
    thought.scheduledEndAt = 0;
    await TodoDao.insert(thought);
  }
}
