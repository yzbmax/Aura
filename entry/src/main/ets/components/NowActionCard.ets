/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Now Only Active Task Central Stage Action Card
 * ArkUI V2 Component with PanGesture Physics & Real-time Gestural Dynamics
 */

import { curves } from '@kit.ArkUI';
import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { Priority, TodoItem, TodoStatus } from '../models/TodoItem';
import { SubTaskItem } from '../models/SubTaskItem';
import { getTaskVisual, TaskBlockVisual } from './TaskVisualHelper';
import { HapticService } from '../common/media/HapticService';
import { AudioService } from '../common/media/AudioService';
import { CardDeckKinematics, HapticHysteresisState } from './CardDeckKinematics';

@ComponentV2
export struct NowActionCard {
  @Param item: TodoItem | null = null;
  @Event onComplete: () => void = () => {};
  @Event onSkip: () => void = () => {};
  @Event onOpenFocus: (item: TodoItem) => void = () => {};
  @Event onHeightChange: (h: number) => void = () => {};
  @Event onGestureProgressChange: (progress: number, offsetX: number, offsetY: number) => void = () => {};
  @Event onDragStateChange: (isDragging: boolean) => void = () => {};

  @Local private offsetX: number = 0;
  @Local private offsetY: number = 0;
  @Local private rotateAngle: number = 0;
  @Local private cardOpacity: number = 1.0;
  @Local private isDragging: boolean = false;
  @Local private isAnimatingTransition: boolean = false;
  @Local private lastReportedHeight: number = 0;
  private hapticHysteresis: HapticHysteresisState = new HapticHysteresisState();

  private executeFlyout(isComplete: boolean): void {
    if (this.isAnimatingTransition) {
      return;
    }
    this.isAnimatingTransition = true;

    // 即时多感官反馈: 完成(升阶和弦+清脆微震), 跳过(静默微气雾脉冲)
    if (isComplete) {
      AudioService.getInstance().playChordStep();
      HapticService.getInstance().triggerClick();
    } else {
      HapticService.getInstance().triggerTick();
    }

    const targetX: number = isComplete ? CardDeckKinematics.EXIT_TRANSLATE_X : -CardDeckKinematics.EXIT_TRANSLATE_X;
    const targetAngle: number = isComplete ? CardDeckKinematics.EXIT_ROTATE_ANGLE : -CardDeckKinematics.EXIT_ROTATE_ANGLE;

    // 轨 1: 顶层卡片飞出动画 (高爆发弹簧，260ms 内飞离消融)
    animateTo({
      curve: CurveConstants.SPRING_CARD_FLYOUT
    }, () => {
      this.offsetX = targetX;
      this.rotateAngle = targetAngle;
      this.cardOpacity = 0.0;
    });

    // 轨 2: 次层卡片弹簧超调弹射就位 (SPRING_CARD_SNAP_FOCUS: 0.34, 0.62，8.35% 欠阻尼弹性过冲)
    animateTo({
      curve: CurveConstants.SPRING_CARD_SNAP_FOCUS,
      onFinish: () => {
        this.offsetX = 0;
        this.offsetY = 0;
        this.rotateAngle = 0;
        this.cardOpacity = 1.0;
        this.hapticHysteresis.reset();
        this.onGestureProgressChange(0.0, 0, 0);
        this.isAnimatingTransition = false;
        if (isComplete) {
          this.onComplete();
        } else {
          this.onSkip();
        }
      }
    }, () => {
      this.onGestureProgressChange(1.0, targetX, 0);
    });
  }

  private executeSnapBack(): void {
    animateTo({
      curve: CurveConstants.SPRING_CARD_CANCEL_RESET,
      onFinish: () => {
        this.hapticHysteresis.reset();
        this.onGestureProgressChange(0.0, 0, 0);
      }
    }, () => {
      this.offsetX = 0;
      this.offsetY = 0;
      this.rotateAngle = 0;
      this.cardOpacity = 1.0;
      this.onGestureProgressChange(0.0, 0, 0);
    });
  }

  private getPriorityLabel(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return '高优核心';
    } else if (priority === Priority.LOW) {
      return '轻缓微步';
    }
    return '稳步推进';
  }

  private getPriorityBgColor(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return ColorConstants.ACCENT_CORAL_SOFT;
    } else if (priority === Priority.LOW) {
      return ColorConstants.BLOCK_SAGE_SOFT;
    }
    return ColorConstants.BLOCK_DENIM_SOFT;
  }

  private getPriorityTextColor(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return ColorConstants.ACCENT_CORAL;
    } else if (priority === Priority.LOW) {
      return ColorConstants.BLOCK_SAGE_GREEN;
    }
    return ColorConstants.BLOCK_DENIM_BLUE;
  }

  build() {
    if (this.item) {
      Stack({ alignContent: Alignment.Center }) {
        // 卡片主体
        Column({ space: 16 }) {
          // 1. 顶部状态药丸组：分类视觉 + 优先级 + 预估时长胶囊 (绝对无时刻戳)
          Row({ space: 8 }) {
            // 分类徽标
            Row({ space: 5 }) {
              Image(getTaskVisual(this.item).icon)
                .width(13)
                .height(13)
                .fillColor(getTaskVisual(this.item).color)

              Text('当前行动')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(getTaskVisual(this.item).color)
            }
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
            .backgroundColor(getTaskVisual(this.item).softColor)

            // 优先级徽标
            Text(this.getPriorityLabel(this.item.priority))
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getPriorityTextColor(this.item.priority))
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(12)
              .backgroundColor(this.getPriorityBgColor(this.item.priority))

            Blank()

            // 预估时长胶囊 (动作负荷估算，非钟表刻度)
            Row({ space: 4 }) {
              Image($r('app.media.ic_sparkle'))
                .width(12)
                .height(12)
                .fillColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              Text(`${this.item.estimatedMinutes} min`)
                .fontSize(12)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(10)
            .backgroundColor('rgba(85, 70, 50, 0.05)')
          }
          .width('100%')

          // 2. 核心大标题与描述 (居中布局，绝对掌控感锚点)
          Column({ space: 8 }) {
            Text(this.item.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              .textAlign(TextAlign.Center)
              .lineHeight(30)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            if (this.item.description && this.item.description.trim().length > 0) {
              Text(this.item.description)
                .fontSize(14)
                .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .width('100%')
          .padding({ left: 6, right: 6, top: 4, bottom: 4 })

          // 3. 微步清单 (SubTasks 交互微复选)
          if (this.item.subTasks && this.item.subTasks.length > 0) {
            Column({ space: 8 }) {
              Row() {
                Text('微步推进')
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                Blank()
                Text(`${this.item.subTasks.filter(s => s.done).length}/${this.item.subTasks.length}`)
                  .fontSize(12)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .width('100%')
              .padding({ left: 4, right: 4 })

              ForEach(this.item.subTasks.slice(0, 4), (sub: SubTaskItem) => {
                Row({ space: 10 }) {
                  // 微复选圆环
                  Stack({ alignContent: Alignment.Center }) {
                    Circle({ width: 18, height: 18 })
                      .fill(sub.done ? ColorConstants.BLOCK_SAGE_GREEN : Color.Transparent)
                      .stroke(sub.done ? ColorConstants.BLOCK_SAGE_GREEN : 'rgba(85, 70, 50, 0.3)')
                      .strokeWidth(1.5)

                    if (sub.done) {
                      Image($r('app.media.ic_check'))
                        .width(11)
                        .height(11)
                        .fillColor(Color.White)
                    }
                  }
                  .width(22)
                  .height(22)

                  Text(sub.title)
                    .fontSize(14)
                    .fontColor(sub.done ? ColorConstants.LIGHT_TEXT_TERTIARY : ColorConstants.LIGHT_TEXT_PRIMARY)
                    .decoration({ type: sub.done ? TextDecorationType.LineThrough : TextDecorationType.None })
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor('rgba(85, 70, 50, 0.03)')
                .borderRadius(12)
                .onClick(() => {
                  sub.done = !sub.done;
                  sub.updatedAt = Date.now();
                  HapticService.getInstance().triggerClick();
                })
              })
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }

          // 4. 滑动手势指示与操作按钮组
          Row({ space: 12 }) {
            // 稍后 / 跳过
            Button({ type: ButtonType.Normal }) {
              Row({ space: 4 }) {
                Text('稍后')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              }
            }
            .layoutWeight(1)
            .height(44)
            .backgroundColor('rgba(85, 70, 50, 0.06)')
            .borderRadius(22)
            .onClick(() => {
              this.executeFlyout(false);
            })

            // 专注沙漏
            Button({ type: ButtonType.Normal }) {
              Row({ space: 6 }) {
                Image($r('app.media.ic_bolt'))
                  .width(15)
                  .height(15)
                  .fillColor(ColorConstants.BLOCK_DENIM_BLUE)

                Text('专注')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.BLOCK_DENIM_BLUE)
              }
            }
            .layoutWeight(1.2)
            .height(44)
            .backgroundColor(ColorConstants.BLOCK_DENIM_SOFT)
            .borderRadius(22)
            .onClick(() => {
              if (this.item) {
                HapticService.getInstance().triggerClick();
                this.onOpenFocus(this.item);
              }
            })

            // 完成此项
            Button({ type: ButtonType.Normal }) {
              Row({ space: 6 }) {
                Image($r('app.media.ic_check'))
                  .width(15)
                  .height(15)
                  .fillColor(Color.White)

                Text('完成')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
            }
            .layoutWeight(1.3)
            .height(44)
            .backgroundColor(ColorConstants.ACCENT_CORAL)
            .borderRadius(22)
            .shadow({
              radius: 12,
              color: 'rgba(232, 122, 100, 0.35)',
              offsetY: 4
            })
            .onClick(() => {
              this.executeFlyout(true);
            })
          }
          .width('100%')
          .padding({ top: 6 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 22, bottom: 22 })
        .borderRadius(24)
        .backgroundColor(ColorConstants.LIGHT_CARD_BG)
        .border({ width: 1, color: ColorConstants.LIGHT_CARD_BORDER })
        .shadow({
          radius: CardDeckKinematics.calcShadowRadius(24, 16, CardDeckKinematics.calcGestureProgress(this.offsetX)),
          color: 'rgba(85, 70, 50, 0.08)',
          offsetY: CardDeckKinematics.calcShadowOffsetY(8, 10, CardDeckKinematics.calcGestureProgress(this.offsetX))
        })

        // 滑动状态下的提示微光条
        if (this.offsetX > 20) {
          Row({ space: 6 }) {
            Image($r('app.media.ic_check'))
              .width(20)
              .height(20)
              .fillColor(ColorConstants.BLOCK_SAGE_GREEN)
            Text('释放完成')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.BLOCK_SAGE_GREEN)
          }
          .position({ x: 20, y: 24 })
          .opacity(Math.min(1.0, this.offsetX / 80))
        } else if (this.offsetX < -20) {
          Row({ space: 6 }) {
            Text('释放推迟')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.BLOCK_WARM_AMBER)
          }
          .position({ x: '68%', y: 24 })
          .opacity(Math.min(1.0, Math.abs(this.offsetX) / 80))
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: 520 })
      .translate({ x: this.offsetX, y: this.offsetY })
      .rotate({ angle: this.rotateAngle })
      .opacity(this.cardOpacity)
      .zIndex(3)
      .onAreaChange((oldA: Area, newA: Area) => {
        const h = Number(newA.height);
        if (h > 0 && Math.abs(h - this.lastReportedHeight) > 1) {
          this.lastReportedHeight = h;
          this.onHeightChange(h);
        }
      })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionUpdate((event: GestureEvent) => {
            if (this.isAnimatingTransition) {
              return;
            }
            this.isDragging = true;
            this.onDragStateChange(true);
            this.offsetX = event.offsetX;
            this.offsetY = event.offsetY * 0.15; // 垂直仿生阻尼微跟随
            this.rotateAngle = CardDeckKinematics.calcLayer1Rotation(event.offsetX);
            const progress = CardDeckKinematics.calcGestureProgress(event.offsetX);
            this.cardOpacity = CardDeckKinematics.calcLayer1Opacity(progress);
            this.onGestureProgressChange(progress, this.offsetX, this.offsetY);

            // 触觉迟滞门禁防抖
            if (this.hapticHysteresis.update(event.offsetX)) {
              HapticService.getInstance().triggerTick();
            }
          })
          .onActionEnd((event: GestureEvent) => {
            if (this.isAnimatingTransition) {
              return;
            }
            this.isDragging = false;
            this.onDragStateChange(false);

            const isComplete: boolean = CardDeckKinematics.isCommitRight(this.offsetX, event.velocityX);
            const isSkip: boolean = CardDeckKinematics.isCommitLeft(this.offsetX, event.velocityX);

            if (isComplete) {
              this.executeFlyout(true);
            } else if (isSkip) {
              this.executeFlyout(false);
            } else {
              this.executeSnapBack();
            }
          })
          .onActionCancel(() => {
            if (this.isAnimatingTransition) {
              return;
            }
            this.isDragging = false;
            this.onDragStateChange(false);
            this.executeSnapBack();
          })
      )
    }
  }
}
