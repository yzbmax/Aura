/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Global Create Todo & Rapid Parking Lot Modal Dialog (Things 3 & Structured Style)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem, Priority, TimingMode, TodoSource, TodoStatus } from '../models/TodoItem';
import { TodoDao } from '../database/dao/TodoDao';
import { HapticService } from '../common/media/HapticService';
import { AudioService } from '../common/media/AudioService';
import { TimeUtils } from '../common/utils/TimeUtils';
import { CurveConstants } from '../common/constants/CurveConstants';
import { promptAction, curves } from '@kit.ArkUI';

export enum CreateDialogTab {
  PARKING_LOT = 0, // 闪念秒存 (杂念停泊)
  TIME_BOX = 1     // 排期时间块
}

@ComponentV2
export struct CreateTodoDialog {
  @Param isVisible: boolean = false;
  @Event onClose: () => void = () => {};
  @Event onCreated: () => void = () => {};

  @Local currentTab: CreateDialogTab = CreateDialogTab.PARKING_LOT;
  @Local todoTitle: string = '';
  @Local todoMinutes: number = 25;
  @Local todoPriority: Priority = Priority.MEDIUM;
  @Local isExploration: boolean = false;

  // 显式弹簧物理动力学与透明度驱动状态 (Explicit Spring Physics Drivers)
  @Local cardScale: number = 0.82;
  @Local cardTranslateY: number = 100;
  @Local cardOpacity: number = 0.0;
  @Local isClosing: boolean = false;

  aboutToAppear(): void {
    if (this.isVisible) {
      this.playEnterAnimation();
    }
  }

  @Monitor('isVisible')
  onVisibilityChanged(): void {
    if (this.isVisible) {
      this.playEnterAnimation();
    } else {
      this.resetAnimationState();
    }
  }

  private resetAnimationState(): void {
    this.cardScale = 0.82;
    this.cardTranslateY = 100;
    this.cardOpacity = 0.0;
    this.isClosing = false;
  }

  private playEnterAnimation(): void {
    this.isClosing = false;
    this.cardScale = 0.82;
    this.cardTranslateY = 100;
    this.cardOpacity = 0.0;

    // 延迟 20ms 等待首帧挂载就绪后，驱动弹簧物理动力学弹性升起
    setTimeout(() => {
      // 白玉卡片弹簧物理动力学升起 (带温润微过冲物理弹簧触感)
      animateTo({
        curve: CurveConstants.SPRING_MODAL_POP
      }, () => {
        this.cardScale = 1.0;
        this.cardTranslateY = 0;
        this.cardOpacity = 1.0;
      });
    }, 20);
  }

  private dismiss(callback?: () => void): void {
    if (this.isClosing) {
      return;
    }
    this.isClosing = true;

    // 退场动画：卡片微缩下沉并淡出
    animateTo({ duration: 200, curve: Curve.FastOutSlowIn }, () => {
      this.cardScale = 0.86;
      this.cardTranslateY = 80;
      this.cardOpacity = 0.0;
    });

    setTimeout(() => {
      this.isClosing = false;
      this.todoTitle = '';
      if (callback) {
        callback();
      } else {
        this.onClose();
      }
    }, 210);
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // 1. 全屏纯净透明点击感应层 (背景完全透明，点击空白区域平滑收起)
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.handleClose();
          })

        // 2. 居中悬浮白玉微晶卡片 (Structured & Things 3 极简温润设计)
        Column({ space: 16 }) {
          // 顶部模式切换分段控制器
          Row({ space: 4 }) {
            this.buildTabItem('闪念秒存 (杂念停机坪)', CreateDialogTab.PARKING_LOT)
            this.buildTabItem('排期时间块', CreateDialogTab.TIME_BOX)
          }
          .width('100%')
          .height(38)
          .padding(3)
          .borderRadius(19)
          .backgroundColor('rgba(85, 70, 50, 0.06)')

          if (this.currentTab === CreateDialogTab.PARKING_LOT) {
            // === 模式 1：杂念秒级停机坪 (先倒空大脑，落盘机动池) ===
            Column({ space: 12 }) {
              Row({ space: 6 }) {
                Image($r('app.media.ic_sparkle'))
                  .width(13)
                  .height(13)
                  .fillColor(ColorConstants.ACCENT_CORAL)
                Text('闪现杂念？先倒空大脑，稍后打烊从容排期')
                  .fontSize(11)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .width('100%')

              TextInput({
                placeholder: '闪念秒存，例如：买猫粮、查快递、记灵感...',
                text: this.todoTitle
              })
                .fontSize(14)
                .height(46)
                .borderRadius(14)
                .backgroundColor('rgba(85, 70, 50, 0.05)')
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                .placeholderColor('rgba(110, 102, 94, 0.42)')
                .padding({ left: 14, right: 14 })
                .defaultFocus(true)
                .onChange((v: string) => {
                  this.todoTitle = v;
                })
                .onSubmit(() => {
                  this.handleSaveParkingLot();
                })

              Row({ space: 12 }) {
                Button('取消')
                  .fontSize(14)
                  .height(40)
                  .layoutWeight(1)
                  .borderRadius(14)
                  .backgroundColor('rgba(85, 70, 50, 0.06)')
                  .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                  .onClick(() => {
                    this.handleClose();
                  })

                Button('停泊入池')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .height(40)
                  .layoutWeight(1)
                  .borderRadius(14)
                  .backgroundColor(ColorConstants.ACCENT_CORAL)
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.handleSaveParkingLot();
                  })
              }
              .width('100%')
              .margin({ top: 4 })
            }
            .width('100%')
          } else {
            // === 模式 2：结构化自适应时间块 ===
            Column({ space: 14 }) {
              TextInput({
                placeholder: '要做什么？(例如：重构同步算法)',
                text: this.todoTitle
              })
                .fontSize(14)
                .height(46)
                .borderRadius(14)
                .backgroundColor('rgba(85, 70, 50, 0.05)')
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                .placeholderColor('rgba(110, 102, 94, 0.42)')
                .padding({ left: 14, right: 14 })
                .defaultFocus(true)
                .onChange((v: string) => {
                  this.todoTitle = v;
                })
                .onSubmit(() => {
                  this.handleSaveTimeBox();
                })

              // 预估时长快捷切片选择
              Row({ space: 6 }) {
                Text('时长:')
                  .fontSize(12)
                  .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)

                this.buildDurationChip('15m', 15, false)
                this.buildDurationChip('25m', 25, false)
                this.buildDurationChip('45m 探索', 45, true)
                this.buildDurationChip('60m', 60, false)
              }
              .width('100%')

              // 操作按钮行：取消 / 保存并排期
              Row({ space: 12 }) {
                Button('取消')
                  .fontSize(14)
                  .height(40)
                  .layoutWeight(1)
                  .borderRadius(14)
                  .backgroundColor('rgba(85, 70, 50, 0.06)')
                  .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                  .onClick(() => {
                    this.handleClose();
                  })

                Button('保存并排期')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .height(40)
                  .layoutWeight(1)
                  .borderRadius(14)
                  .backgroundColor(ColorConstants.ACCENT_CORAL)
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.handleSaveTimeBox();
                  })
              }
              .width('100%')
              .margin({ top: 4 })
            }
            .width('100%')
          }
        }
        .width('88%')
        .constraintSize({ maxWidth: 420 })
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
        .borderRadius(24)
        .backgroundColor('rgba(255, 254, 250, 0.94)')
        .backgroundBlurStyle(BlurStyle.Regular)
        .border({ width: 0.8, color: 'rgba(255, 255, 255, 0.9)' })
        .shadow({ radius: 20, color: 'rgba(60, 45, 30, 0.04)', offsetY: 4 })
        .scale({ x: this.cardScale, y: this.cardScale })
        .translate({ y: this.cardTranslateY })
        .opacity(this.cardOpacity)
        .onClick(() => {
          // 阻断卡片内部点击穿透冒泡至外层遮罩
        })
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .zIndex(999)
    }
  }

  @Builder
  private buildTabItem(title: string, tab: CreateDialogTab) {
    Stack() {
      if (this.currentTab === tab) {
        Rect()
          .width('100%')
          .height('100%')
          .radius(16)
          .fill(Color.White)
          .shadow({ radius: 4, color: 'rgba(85, 70, 50, 0.04)', offsetY: 1 })
      }

      Text(title)
        .fontSize(11)
        .fontWeight(this.currentTab === tab ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === tab ? ColorConstants.LIGHT_TEXT_PRIMARY : ColorConstants.LIGHT_TEXT_TERTIARY)
    }
    .layoutWeight(1)
    .height('100%')
    .borderRadius(16)
    .onClick(() => {
      animateTo({ curve: curves.springMotion(0.35, 0.75) }, () => {
        this.currentTab = tab;
      });
      HapticService.getInstance().triggerTick();
    })
  }

  @Builder
  private buildDurationChip(label: string, minutes: number, isExploration: boolean) {
    Button(label)
      .fontSize(11)
      .height(28)
      .padding({ left: 10, right: 10 })
      .borderRadius(14)
      .backgroundColor(this.todoMinutes === minutes ? ColorConstants.ACCENT_CORAL : 'rgba(85, 70, 50, 0.06)')
      .fontColor(this.todoMinutes === minutes ? Color.White : ColorConstants.LIGHT_TEXT_PRIMARY)
      .animation({ duration: 200, curve: Curve.FastOutSlowIn })
      .onClick(() => {
        this.todoMinutes = minutes;
        this.isExploration = isExploration;
        HapticService.getInstance().triggerTick();
      })
  }

  private handleClose(): void {
    this.dismiss(() => {
      this.onClose();
    });
  }

  private async handleSaveParkingLot(): Promise<void> {
    const trimmed = this.todoTitle.trim();
    if (trimmed.length === 0) {
      return;
    }
    const item = new TodoItem();
    item.id = TimeUtils.generateUUID();
    item.title = trimmed;
    item.source = TodoSource.PARKING_LOT;
    item.estimatedMinutes = 15;
    item.priority = Priority.MEDIUM;
    item.status = TodoStatus.PENDING;
    item.scheduledStartAt = 0; // 存放于机动备选池
    item.createdAt = Date.now();
    item.updatedAt = Date.now();

    await TodoDao.insert(item);
    AudioService.getInstance().playChordStep();
    HapticService.getInstance().triggerTick();

    try {
      promptAction.showToast({
        message: '已安全停泊至机动池，放心专注',
        duration: 1500
      });
    } catch {
      // 容错
    }

    this.dismiss(() => {
      this.onCreated();
    });
  }

  private async handleSaveTimeBox(): Promise<void> {
    const trimmed = this.todoTitle.trim();
    if (trimmed.length === 0) {
      return;
    }
    const item = new TodoItem(
      TimeUtils.generateUUID(),
      trimmed,
      this.todoMinutes
    );
    item.priority = this.todoPriority;
    item.timingMode = TimingMode.COUNTDOWN;
    item.isExplorationSlice = this.isExploration;
    item.scheduledStartAt = Date.now(); // 今日自适应排期

    await TodoDao.insert(item);
    AudioService.getInstance().playChordStep();
    HapticService.getInstance().triggerTick();

    this.dismiss(() => {
      this.onCreated();
    });
  }
}
