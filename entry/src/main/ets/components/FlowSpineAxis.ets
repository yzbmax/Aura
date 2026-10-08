/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Structured Flow Spine: Longitudinal Axis, Timestamp Scale & Extended Capsule Nodes
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { SlotType, TimeSlot } from '../models/TimeSlot';
import { Priority, TodoItem, TodoStatus } from '../models/TodoItem';
import { MistMorphingCard } from './MistMorphingCard';
import { CushionCard } from './CushionCard';
import { TimeUtils } from '../common/utils/TimeUtils';

import { TaskBlockVisual, getTaskVisual } from './TaskVisualHelper';
export { TaskBlockVisual, getTaskVisual };

@ComponentV2
export struct FlowSpineAxis {
  @Param timelineSlots: TimeSlot[] = [];
  @Param isPaperMode: boolean = false;
  @Event onToggleComplete: (item: TodoItem) => void = () => {};
  @Event onContinueFocus: (item: TodoItem) => void = () => {};
  @Event onAdjustDuration: (item: TodoItem, deltaMinutes: number) => void = () => {};
  @Event onTogglePin: (item: TodoItem) => void = () => {};

  private getSlotHeight(item: TodoItem): number {
    const m = Math.max(15, item.estimatedMinutes);
    let h = Math.round(m * 1.4);
    // 超过 10 个字符的长标题，确保卡片高度至少 74vp，完全容纳两行文字与内边距
    if (item.title.length > 10) {
      h = Math.max(74, h);
    } else {
      h = Math.max(58, h);
    }
    return Math.min(125, h);
  }

  private isSlotActive(slot: TimeSlot): boolean {
    if (!slot.taskItem || slot.taskItem.scheduledStartAt <= 0 || slot.taskItem.scheduledEndAt <= 0) {
      return false;
    }
    const now = Date.now();
    return now >= slot.taskItem.scheduledStartAt && now < slot.taskItem.scheduledEndAt;
  }

  private getNowProgress(slot: TimeSlot): number {
    if (!slot.taskItem || slot.taskItem.scheduledStartAt <= 0 || slot.taskItem.scheduledEndAt <= 0) {
      return 0.5;
    }
    const now = Date.now();
    const duration = slot.taskItem.scheduledEndAt - slot.taskItem.scheduledStartAt;
    if (duration <= 0) {
      return 0.5;
    }
    const elapsed = now - slot.taskItem.scheduledStartAt;
    const ratio = elapsed / duration;
    return Math.max(0.12, Math.min(0.88, ratio));
  }

  build() {
    Column({ space: 0 }) {
      if (this.timelineSlots.length === 0) {
        Column({ space: 8 }) {
          Image($r('app.media.ic_sprout'))
            .width(28)
            .height(28)
            .fillColor(ColorConstants.BLOCK_SAGE_GREEN)
          Text('今日时间轴尚未排期，点击下方一键智能装箱')
            .fontSize(13)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: 32, bottom: 32 })
        .alignItems(HorizontalAlign.Center)
      } else {
        ForEach(this.timelineSlots, (slot: TimeSlot) => {
          if (slot.type === SlotType.BUFFER) {
            // 留白呼吸缓冲带 (Structured Free Time 样式)
            CushionCard({
              startMs: slot.startMs,
              endMs: slot.endMs,
              text: slot.title
            })
          } else if (slot.taskItem) {
            // 普通或切片时间块 (根据时长与标题长度自适应比例尺高度)
            Stack({ alignContent: Alignment.TopStart }) {
              Row({ space: 8 }) {
                // 1. 左侧 42vp 时间刻度标尺 (极简纯粹开始时刻，消灭杂乱重叠)
                Column() {
                  if (this.isSlotActive(slot)) {
                    Row({ space: 3 }) {
                      Circle({ width: 4, height: 4 }).fill(ColorConstants.ACCENT_CORAL)
                      Text('NOW')
                        .fontSize(8)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ColorConstants.ACCENT_CORAL)
                    }
                    .padding({ left: 4, right: 4, top: 1.5, bottom: 1.5 })
                    .borderRadius(4)
                    .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
                    .margin({ bottom: 3 })
                  }

                  Text(TimeUtils.formatTime(slot.taskItem.scheduledStartAt))
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.isSlotActive(slot) ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_PRIMARY)
                    .letterSpacing(0.2)
                }
                .width(42)
                .height(this.getSlotHeight(slot.taskItem))
                .alignItems(HorizontalAlign.End)
                .justifyContent(FlexAlign.Start)
                .padding({ top: 6 })

                // 2. 纵向时间轴脊柱导轨节点 (胶囊高度 1:1 贴合卡片高度，实现像素级顶部与底部齐平)
                Column() {
                  if (slot.taskItem.estimatedMinutes >= 35) {
                    // 参考图同款：纵向延伸时间切片胶囊，高度与卡片完全一致
                    Column({ space: 4 }) {
                      Image(getTaskVisual(slot.taskItem).icon)
                        .width(13)
                        .height(13)
                        .fillColor(Color.White)
                        .margin({ top: 7 })

                      Line()
                        .width(2)
                        .height(Math.max(12, this.getSlotHeight(slot.taskItem) - 32))
                        .backgroundColor('rgba(255, 255, 255, 0.55)')
                    }
                    .width(28)
                    .height(this.getSlotHeight(slot.taskItem))
                    .borderRadius(14)
                    .backgroundColor(getTaskVisual(slot.taskItem).color)
                    .alignItems(HorizontalAlign.Center)
                    .shadow(this.isSlotActive(slot) ?
                      { radius: 10, color: ColorConstants.ACCENT_CORAL_SOFT, offsetY: 0 } :
                      { radius: 8, color: 'rgba(36, 32, 29, 0.12)', offsetY: 2 })
                  } else {
                    // 短任务：28vp 彩色实体圆形节点 + 延伸连贯轴线
                    Stack({ alignContent: Alignment.Center }) {
                      if (this.isSlotActive(slot)) {
                        Circle({ width: 34, height: 34 })
                          .fill(ColorConstants.ACCENT_CORAL_SOFT)
                      }

                      Circle({ width: 28, height: 28 })
                        .fill(getTaskVisual(slot.taskItem).color)

                      Image(getTaskVisual(slot.taskItem).icon)
                        .width(13)
                        .height(13)
                        .fillColor(Color.White)
                    }
                    .width(28)
                    .height(28)
                    .shadow(this.isSlotActive(slot) ?
                      { radius: 8, color: ColorConstants.ACCENT_CORAL_SOFT, offsetY: 0 } :
                      { radius: 6, color: 'rgba(36, 32, 29, 0.10)', offsetY: 2 })

                    Line()
                      .width(2)
                      .height(Math.max(10, this.getSlotHeight(slot.taskItem) - 28))
                      .backgroundColor('rgba(36, 32, 29, 0.20)')
                  }
                }
                .width(28)
                .height(this.getSlotHeight(slot.taskItem))
                .alignItems(HorizontalAlign.Center)

                // 3. 卡片主体 (Structured 风格排版与同色勾选环，高度 1:1 锚定)
                MistMorphingCard({
                  item: slot.taskItem,
                  cardHeight: this.getSlotHeight(slot.taskItem),
                  isPaperMode: this.isPaperMode,
                  onToggleComplete: (target: TodoItem) => {
                    this.onToggleComplete(target);
                  },
                  onContinueFocus: (target: TodoItem) => {
                    this.onContinueFocus(target);
                  },
                  onAdjustDuration: (target: TodoItem, delta: number) => {
                    this.onAdjustDuration(target, delta);
                  },
                  onTogglePin: (target: TodoItem) => {
                    this.onTogglePin(target);
                  }
                })
                .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              // 4. 实时时间流动游标 (Live Now Indicator: 贯穿导轨与卡片的动态时刻线)
              if (this.isSlotActive(slot)) {
                Row() {
                  // 导轨处发光圆点 (呼吸微光外环 + 核心红点)
                  Stack({ alignContent: Alignment.Center }) {
                    Circle({ width: 14, height: 14 })
                      .fill(ColorConstants.ACCENT_CORAL_SOFT)
                    Circle({ width: 6, height: 6 })
                      .fill(ColorConstants.ACCENT_CORAL)
                  }
                  .width(14)
                  .height(14)
                  .margin({ left: 57 })

                  // 延伸贯穿卡片的微光水平指示线
                  Row()
                    .layoutWeight(1)
                    .height(1.5)
                    .margin({ left: 4 })
                    .linearGradient({
                      angle: 90,
                      colors: [
                        [ColorConstants.ACCENT_CORAL, 0.0],
                        ['rgba(232, 122, 100, 0.40)', 0.5],
                        ['rgba(232, 122, 100, 0.0)', 1.0]
                      ]
                    })
                }
                .width('100%')
                .position({ y: Math.round(this.getSlotHeight(slot.taskItem) * this.getNowProgress(slot)) - 7 })
                .zIndex(5)
                .hitTestBehavior(HitTestMode.None)
              }
            }
            .width('100%')
            .margin({ top: 3, bottom: 3 })
          }
        })
      }
    }
    .width('100%')
  }
}
