/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Today Footprint Ribbon: Today's Completed Micro-Step Milestones
 * Zero-pressure positive dopamine feedback without schedules or bin-packing
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { Priority, TodoItem } from '../models/TodoItem';
import { HapticService } from '../common/media/HapticService';

@ComponentV2
export struct TodayFootprintRibbon {
  @Param completedItems: TodoItem[] = [];
  @Event onUndoItem: (item: TodoItem) => void = () => {};
  @Event onOpenSunset: () => void = () => {};

  @Local private isCollapsed: boolean = false;

  private get totalFocusMinutes(): number {
    return this.completedItems.reduce((acc: number, curr: TodoItem): number => {
      return acc + (curr.estimatedMinutes > 0 ? curr.estimatedMinutes : 20);
    }, 0);
  }

  private getPriorityLabel(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return '高优';
    } else if (priority === Priority.LOW) {
      return '轻缓';
    }
    return '稳步';
  }

  private getPriorityColor(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return ColorConstants.ACCENT_CORAL;
    } else if (priority === Priority.LOW) {
      return ColorConstants.BLOCK_SAGE_GREEN;
    }
    return ColorConstants.BLOCK_WARM_AMBER;
  }

  private getPriorityBg(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return 'rgba(232, 122, 100, 0.12)';
    } else if (priority === Priority.LOW) {
      return 'rgba(129, 178, 154, 0.12)';
    }
    return 'rgba(224, 159, 62, 0.12)';
  }

  build() {
    Column({ space: 10 }) {
      if (this.completedItems.length > 0) {
        // 1. 顶部标题与折叠开关
        Row() {
          Row({ space: 6 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 22, height: 22 })
                .fill(ColorConstants.BLOCK_SAGE_SOFT)
              Image($r('app.media.ic_check'))
                .width(11)
                .height(11)
                .fillColor(ColorConstants.BLOCK_SAGE_GREEN)
            }

            Text('今日心流足迹')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

            Text(`${this.completedItems.length} 步`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.BLOCK_SAGE_GREEN)
              .backgroundColor(ColorConstants.BLOCK_SAGE_SOFT)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(6)
          }

          Blank()

          Row({ space: 8 }) {
            Text(`累计 ${this.totalFocusMinutes} 分钟专注`)
              .fontSize(12)
              .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

            Button({ type: ButtonType.Normal }) {
              Text(this.isCollapsed ? '展开' : '收起')
                .fontSize(12)
                .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
            }
            .height(26)
            .padding({ left: 8, right: 8 })
            .borderRadius(13)
            .backgroundColor('rgba(85, 70, 50, 0.05)')
            .onClick(() => {
              this.isCollapsed = !this.isCollapsed;
              HapticService.getInstance().triggerTick();
            })
          }
        }
        .width('100%')
        .padding({ left: 4, right: 4, top: 4 })

        // 2. 已达成足迹微卡片列表
        if (!this.isCollapsed) {
          Column({ space: 8 }) {
            ForEach(this.completedItems, (item: TodoItem) => {
              Row({ space: 10 }) {
                // 已完成勾选圆环
                Stack({ alignContent: Alignment.Center }) {
                  Circle({ width: 20, height: 20 })
                    .fill(ColorConstants.BLOCK_SAGE_GREEN)
                  Image($r('app.media.ic_check'))
                    .width(10)
                    .height(10)
                    .fillColor(Color.White)
                }

                // 优先级标签
                Text(this.getPriorityLabel(item.priority))
                  .fontSize(10)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.getPriorityColor(item.priority))
                  .backgroundColor(this.getPriorityBg(item.priority))
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(6)

                // 标题 (带划线表示已达成)
                Text(item.title)
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                  .decoration({ type: TextDecorationType.LineThrough })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                // 专注耗时
                Text(`${item.estimatedMinutes > 0 ? item.estimatedMinutes : 20}m`)
                  .fontSize(11)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

                // 撤回按钮 (反悔重做)
                Button({ type: ButtonType.Capsule }) {
                  Text('撤回')
                    .fontSize(11)
                    .fontWeight(FontWeight.Normal)
                    .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                    .padding({ left: 6, right: 6, top: 3, bottom: 3 })
                }
                .backgroundColor('rgba(85, 70, 50, 0.05)')
                .height(24)
                .onClick(() => {
                  HapticService.getInstance().triggerTick();
                  this.onUndoItem(item);
                })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .borderRadius(14)
              .backgroundColor('rgba(255, 255, 255, 0.82)')
              .border({ width: 0.5, color: 'rgba(85, 70, 50, 0.08)' })
            }, (item: TodoItem): string => item.id)

            // 晚间打烊引导按钮
            Row({ space: 6 }) {
              Image($r('app.media.ic_sunset'))
                .width(14)
                .height(14)
                .fillColor(ColorConstants.BLOCK_WARM_AMBER)
              Text('今日心流进展良好 · 查看晚间打烊仪式')
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorConstants.BLOCK_WARM_AMBER)
            }
            .width('100%')
            .height(36)
            .justifyContent(FlexAlign.Center)
            .borderRadius(12)
            .backgroundColor(ColorConstants.BLOCK_WARM_AMBER_SOFT)
            .margin({ top: 4 })
            .onClick(() => {
              HapticService.getInstance().triggerClick();
              this.onOpenSunset();
            })
          }
          .width('100%')
        }
      } else {
        // 3. 禅意空态卡片：未有足迹时的温和激励
        Row({ space: 10 }) {
          Image($r('app.media.ic_sparkle'))
            .width(18)
            .height(18)
            .fillColor(ColorConstants.BLOCK_SAGE_GREEN)

          Column({ space: 2 }) {
            Text('今日心流正在蓄力')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

            Text('完成上方主舞台动作，即可点亮首个微晶足迹')
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderRadius(16)
        .backgroundColor('rgba(255, 255, 255, 0.75)')
        .border({ width: 0.5, color: 'rgba(85, 70, 50, 0.06)' })
      }
    }
    .width('100%')
    .constraintSize({ maxWidth: 520 })
  }
}
