/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Mist Morphing Card (Structured Style Task Layout & Coordinated Completion Rings)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { LiquidGlassState } from '../common/utils/LiquidGlassHelper';
import { TodoItem, TodoStatus } from '../models/TodoItem';
import { getTaskVisual } from './FlowSpineAxis';

@ComponentV2
export struct MistMorphingCard {
  @Param item: TodoItem = new TodoItem();
  @Param cardHeight: number = 0;
  @Param isPaperMode: boolean = false;
  @Event onToggleComplete: (item: TodoItem) => void = () => {};
  @Event onContinueFocus: (item: TodoItem) => void = () => {};
  @Event onAdjustDuration: (item: TodoItem, deltaMinutes: number) => void = () => {};
  @Event onTogglePin: (item: TodoItem) => void = () => {};

  @Local liquidState: LiquidGlassState = new LiquidGlassState();

  build() {
    Row() {
      // 核心内容区
      Column({ space: 4 }) {
        // 1. 时段微调、锁定与状态标签行 (直接物理操控)
        Row({ space: 6 }) {
          Text(`${this.item.estimatedMinutes} min`)
            .fontSize(11)
            .fontColor('#4A423A')
            .fontWeight(FontWeight.Medium)

          // 原地时长微调手柄 (-15m / +15m)
          Row({ space: 2 }) {
            Text('−15')
              .fontSize(9)
              .fontColor(this.item.estimatedMinutes > 15 ? ColorConstants.LIGHT_TEXT_SECONDARY : ColorConstants.LIGHT_TEXT_TERTIARY)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(4)
              .backgroundColor('rgba(36, 32, 29, 0.05)')
              .onClick(() => {
                this.onAdjustDuration(this.item, -15);
              })

            Text('+15')
              .fontSize(9)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(4)
              .backgroundColor('rgba(36, 32, 29, 0.05)')
              .onClick(() => {
                this.onAdjustDuration(this.item, 15);
              })
          }

          // 原地排期锚定锁定手柄
          Row({ space: 2 }) {
            Image($r('app.media.ic_pin'))
              .width(9)
              .height(9)
              .fillColor(this.item.isPinned ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_TERTIARY)
            Text(this.item.isPinned ? '已锁定' : '锁定')
              .fontSize(9)
              .fontColor(this.item.isPinned ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_TERTIARY)
          }
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .borderRadius(4)
          .backgroundColor(this.item.isPinned ? ColorConstants.ACCENT_CORAL_SOFT : 'rgba(85, 70, 50, 0.05)')
          .onClick(() => {
            this.onTogglePin(this.item);
          })

          if (this.item.isExplorationSlice) {
            Text('45m 切片')
              .fontSize(9)
              .fontColor(getTaskVisual(this.item).color)
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(4)
              .backgroundColor(getTaskVisual(this.item).softColor)
          }
        }

        // 2. 任务大标题 (柔和深焙暖灰，中等字重，极简克制)
        Text(this.item.title)
          .fontSize(15)
          .lineHeight(20)
          .fontColor(this.item.status === TodoStatus.COMPLETED
            ? ColorConstants.LIGHT_TEXT_TERTIARY
            : ColorConstants.LIGHT_TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(this.cardHeight >= 70 ? 2 : 1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .decoration({
            type: this.item.status === TodoStatus.COMPLETED
              ? TextDecorationType.LineThrough
              : TextDecorationType.None
          })

        // 3. 辅助元数据行 (参考图同款微型子项复选进度)
        if (this.item.subTasks.length > 0) {
          Row({ space: 4 }) {
            Image($r('app.media.ic_check'))
              .width(10)
              .height(10)
              .fillColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            Text(this.getSubTaskSummary())
              .fontSize(10)
              .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          }
          .padding({ top: 1 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => {
        if (this.item.status !== TodoStatus.COMPLETED) {
          this.onContinueFocus(this.item);
        }
      })

      // 4. 右侧 22vp 纤细几何打卡圆环 (高对比打卡圈)
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 22, height: 22 })
          .fill(this.item.status === TodoStatus.COMPLETED
            ? getTaskVisual(this.item).color
            : 'rgba(36, 32, 29, 0.03)')
          .stroke(getTaskVisual(this.item).color)
          .strokeWidth(this.item.status === TodoStatus.COMPLETED ? 0 : 1.6)

        if (this.item.status === TodoStatus.COMPLETED) {
          Image($r('app.media.ic_check'))
            .width(11)
            .height(11)
            .fillColor(Color.White)
        }
      }
      .width(32)
      .height(32)
      .margin({ left: 6 })
      .onClick(() => {
        this.onToggleComplete(this.item);
      })
    }
    .width('100%')
    .height(this.cardHeight > 0 ? this.cardHeight : undefined)
    .constraintSize({ minHeight: 58 })
    .padding({ left: 14, right: 12, top: 8, bottom: 8 })
    .borderRadius(18)
    .backgroundColor('#FFFFFF')
    .border({
      width: 0.8,
      color: 'rgba(36, 32, 29, 0.06)'
    })
    .shadow(this.isPaperMode ? undefined : {
      radius: 8,
      color: 'rgba(40, 32, 24, 0.035)',
      offsetY: 2
    })
    .translate({ x: this.liquidState.offsetX, y: this.liquidState.offsetY })
    .scale({ x: this.liquidState.scaleX, y: this.liquidState.scaleY })
    .onTouch((event: TouchEvent) => {
      if (this.isPaperMode) {
        return;
      }
      const touch = event.touches[0];
      if (event.type === TouchType.Down && touch) {
        animateTo({ curve: CurveConstants.SPRING_LIQUID_STRETCH }, () => {
          this.liquidState.handleTouchDown(touch.x, touch.y);
        });
      } else if (event.type === TouchType.Move && touch) {
        this.liquidState.handleTouchMove(touch.x, touch.y);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({ curve: CurveConstants.SPRING_LIQUID_SNAP }, () => {
          this.liquidState.handleTouchUp();
        });
      }
    })
    .alignItems(VerticalAlign.Center)
  }

  private getSubTaskSummary(): string {
    const doneCount = this.item.subTasks.filter(s => s.done).length;
    return `${doneCount}/${this.item.subTasks.length}`;
  }
}
