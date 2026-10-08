/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Lightweight Collapsible Queue Drawer: Zero-Distraction Single-Thread Pipeline
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { Priority, TodoItem } from '../models/TodoItem';
import { HapticService } from '../common/media/HapticService';

@ComponentV2
export struct QueueDrawer {
  @Param nextQueue: TodoItem[] = [];
  @Param parkingQueue: TodoItem[] = [];
  @Param isExpanded: boolean = false;
  @Param bottomAvoidHeight: number = 0;
  @Event onExpandedChange: (expanded: boolean) => void = () => {};
  @Event onPromote: (id: string) => void = () => {};
  @Event onTriageCryo: (id: string) => void = () => {};

  private get totalCount(): number {
    return this.nextQueue.length + this.parkingQueue.length;
  }

  private getPriorityLabel(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return '高优';
    }
    if (priority === Priority.LOW) {
      return '低优';
    }
    return '中优';
  }

  private getPriorityColor(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return ColorConstants.ACCENT_CORAL;
    }
    if (priority === Priority.LOW) {
      return ColorConstants.BLOCK_SAGE_GREEN;
    }
    return ColorConstants.BLOCK_WARM_AMBER;
  }

  private getPriorityBg(priority: Priority): string {
    if (priority === Priority.HIGH) {
      return 'rgba(232, 122, 100, 0.12)';
    }
    if (priority === Priority.LOW) {
      return 'rgba(129, 178, 154, 0.12)';
    }
    return 'rgba(224, 159, 62, 0.12)';
  }

  build() {
    Column() {
      if (!this.isExpanded) {
        // 1. 折叠默认态：32vp 悬浮微胶囊 (零视线干扰，极简拖拽条与待办计数)
        Row({ space: 7 }) {
          Row()
            .width(14)
            .height(2.5)
            .borderRadius(1.5)
            .backgroundColor('rgba(85, 70, 50, 0.35)')

          Text(`待办序列 (${this.totalCount})`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
        }
        .height(32)
        .padding({ left: 13, right: 15 })
        .borderRadius(16)
        .backgroundColor('rgba(255, 255, 255, 0.94)')
        .border({ width: 0.5, color: 'rgba(85, 70, 50, 0.12)' })
        .shadow({ radius: 10, color: 'rgba(85, 70, 50, 0.08)', offsetY: 2 })
        .onClick(() => {
          this.onExpandedChange(true);
          HapticService.getInstance().triggerTick();
        })
      } else {
        // 2. 展开态：平滑滑出的待办序列轻量抽屉
        Column({ space: 12 }) {
          // 顶部拖拽把手与收起操作
          Column({ space: 6 }) {
            Row() {
              Blank()
              // 拖拽把手指示条
              Row()
                .width(36)
                .height(4)
                .borderRadius(2)
                .backgroundColor('rgba(85, 70, 50, 0.20)')
              Blank()
            }
            .width('100%')
            .padding({ top: 8 })
            .onClick(() => {
              this.onExpandedChange(false);
              HapticService.getInstance().triggerTick();
            })

            Row() {
              Column({ space: 2 }) {
                Row({ space: 6 }) {
                  Text(`待办序列 (${this.totalCount})`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                }

                Text('流水线推力队列 · 零时间压力')
                  .fontSize(11)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              // 关闭收起按钮
              Button({ type: ButtonType.Circle }) {
                Image($r('app.media.ic_close'))
                  .width(12)
                  .height(12)
                  .fillColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              }
              .width(28)
              .height(28)
              .backgroundColor('rgba(85, 70, 50, 0.05)')
              .onClick(() => {
                this.onExpandedChange(false);
                HapticService.getInstance().triggerTick();
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          }
          .width('100%')

          // 待办序列内容滚动列表
          Scroll() {
            Column({ space: 14 }) {
              if (this.totalCount === 0) {
                // 禅意空态
                Column({ space: 8 }) {
                  Image($r('app.media.ic_sparkle'))
                    .width(24)
                    .height(24)
                    .fillColor(ColorConstants.BLOCK_SAGE_GREEN)

                  Text('待办序列空空如也')
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)

                  Text('尽情沉浸于当前心流')
                    .fontSize(11)
                    .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                }
                .width('100%')
                .padding({ top: 32, bottom: 32 })
                .alignItems(HorizontalAlign.Center)
              } else {
                // 就绪待推队列
                if (this.nextQueue.length > 0) {
                  Column({ space: 8 }) {
                    Row() {
                      Text(`就绪推进 (${this.nextQueue.length})`)
                        .fontSize(12)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16 })

                    ForEach(this.nextQueue, (item: TodoItem) => {
                      Row({ space: 10 }) {
                        // 优先级微标
                        Text(this.getPriorityLabel(item.priority))
                          .fontSize(10)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.getPriorityColor(item.priority))
                          .backgroundColor(this.getPriorityBg(item.priority))
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .borderRadius(6)

                        // 标题
                        Text(item.title)
                          .fontSize(13)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)

                        // 操作区：置顶 & 冷冻
                        Row({ space: 6 }) {
                          Button({ type: ButtonType.Capsule }) {
                            Text('置顶')
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(ColorConstants.ACCENT_CORAL)
                              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          }
                          .backgroundColor('rgba(232, 122, 100, 0.10)')
                          .height(26)
                          .onClick(() => {
                            this.onPromote(item.id);
                            HapticService.getInstance().triggerTick();
                          })

                          Button({ type: ButtonType.Capsule }) {
                            Text('冷冻')
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(ColorConstants.DARK_FROST_BLUE)
                              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          }
                          .backgroundColor('rgba(143, 162, 176, 0.12)')
                          .height(26)
                          .onClick(() => {
                            this.onTriageCryo(item.id);
                            HapticService.getInstance().triggerTick();
                          })
                        }
                      }
                      .width('100%')
                      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                      .borderRadius(14)
                      .backgroundColor(ColorConstants.LIGHT_CARD_BG)
                      .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
                    }, (item: TodoItem): string => item.id)
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12 })
                }

                // 机动停泊池
                if (this.parkingQueue.length > 0) {
                  Column({ space: 8 }) {
                    Row() {
                      Text(`机动停泊 (${this.parkingQueue.length})`)
                        .fontSize(12)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16 })

                    ForEach(this.parkingQueue, (item: TodoItem) => {
                      Row({ space: 10 }) {
                        // 杂念标志
                        Row({ space: 4 }) {
                          Image($r('app.media.ic_sparkle'))
                            .width(10)
                            .height(10)
                            .fillColor(ColorConstants.ACCENT_CORAL)
                          Text('机动')
                            .fontSize(10)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(ColorConstants.ACCENT_CORAL)
                        }
                        .backgroundColor('rgba(232, 122, 100, 0.10)')
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .borderRadius(6)

                        // 标题
                        Text(item.title)
                          .fontSize(13)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)

                        // 操作区：置顶 & 冷冻
                        Row({ space: 6 }) {
                          Button({ type: ButtonType.Capsule }) {
                            Text('置顶')
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(ColorConstants.ACCENT_CORAL)
                              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          }
                          .backgroundColor('rgba(232, 122, 100, 0.10)')
                          .height(26)
                          .onClick(() => {
                            this.onPromote(item.id);
                            HapticService.getInstance().triggerTick();
                          })

                          Button({ type: ButtonType.Capsule }) {
                            Text('冷冻')
                              .fontSize(11)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(ColorConstants.DARK_FROST_BLUE)
                              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          }
                          .backgroundColor('rgba(143, 162, 176, 0.12)')
                          .height(26)
                          .onClick(() => {
                            this.onTriageCryo(item.id);
                            HapticService.getInstance().triggerTick();
                          })
                        }
                      }
                      .width('100%')
                      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                      .borderRadius(14)
                      .backgroundColor(ColorConstants.LIGHT_CARD_BG)
                      .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
                    }, (item: TodoItem): string => item.id)
                  }
                  .width('100%')
                  .padding({ left: 12, right: 12 })
                }
              }

              // 底部安全留白
              Blank().height(16)
            }
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .constraintSize({ maxHeight: 320 })
          .width('100%')
        }
        .width('100%')
        .padding({ bottom: this.bottomAvoidHeight > 0 ? this.bottomAvoidHeight + 8 : 16 })
        .borderRadius({ topLeft: 22, topRight: 22 })
        .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
        .border({ width: { top: 0.5, left: 0.5, right: 0.5 }, color: ColorConstants.LIGHT_CARD_BORDER })
        .shadow({ radius: 24, color: 'rgba(85, 70, 50, 0.14)', offsetY: -4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
