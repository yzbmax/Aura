/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Sunset Ceremony: Today's Micro-Flow Trajectory (今日微步心流轨迹 · 每一步都算数)
 * Anti-Overload Psychology & Guilt-Free Queue Continuation
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem, TodoStatus } from '../models/TodoItem';
import { TodoDao } from '../database/dao/TodoDao';
import { HapticService } from '../common/media/HapticService';
import { AudioService } from '../common/media/AudioService';
import { TimeUtils } from '../common/utils/TimeUtils';

@ComponentV2
export struct SunsetCeremonyPage {
  @Event onClose: () => void = () => {};

  @Local completedToday: TodoItem[] = [];
  @Local incompleteTasks: TodoItem[] = [];
  @Local isSavedCardToast: boolean = false;
  @Local isDetailExpanded: boolean = false;
  @Local topAvoidHeight: number = 38;
  @Local bottomAvoidHeight: number = 24;

  aboutToAppear(): void {
    const topPx = AppStorage.get<number>('topAvoidPx') ?? 0;
    const bottomPx = AppStorage.get<number>('bottomAvoidPx') ?? 0;
    if (topPx > 0) {
      this.topAvoidHeight = px2vp(topPx);
    }
    if (bottomPx > 0) {
      this.bottomAvoidHeight = px2vp(bottomPx);
    }
    this.loadCeremonyData();
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 1. 顶栏关闭/跳过 (置顶常驻)
        Row() {
          Blank()
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_close'))
              .width(14)
              .height(14)
              .fillColor(ColorConstants.DARK_TEXT_SECONDARY)
          }
          .backgroundColor('rgba(255, 255, 255, 0.08)')
          .width(32)
          .height(32)
          .onClick(() => {
            this.onClose();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        .backgroundColor(ColorConstants.DARK_BG_SUNSET)
        .zIndex(10)

        Scroll() {
          Column({ space: 16 }) {
            // 2. 暮光落幕仪式标题与微步轨迹主导语
            Column({ space: 8 }) {
              Image($r('app.media.ic_sunset'))
                .width(40)
                .height(40)
                .fillColor(ColorConstants.DARK_FLOW_VIOLET)

              Text('今日微步心流轨迹 · 每一步都算数')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorConstants.DARK_TEXT_PRIMARY)
                .textAlign(TextAlign.Center)

              Text('告别时间焦虑，沉淀今日每一次前行的微小推力。')
                .fontSize(13)
                .fontColor(ColorConstants.DARK_FLOW_VIOLET)
                .textAlign(TextAlign.Center)
                .lineHeight(20)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ left: 16, right: 16, top: 4 })

            // 3. 拍立得微步轨迹成就卡片 (含 SaveButton 零权限存相册)
            Column({ space: 14 }) {
              Row({ space: 8 }) {
                Circle({ width: 10, height: 10 }).fill(ColorConstants.DARK_FLOW_VIOLET)
                Text('Aura · 今日微步心流轨迹')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.DARK_TEXT_PRIMARY)

                Blank()

                Text(`${this.completedToday.length} 步已成`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.DARK_DAWN_CYAN)
              }
              .width('100%')

              // 微步时间珠轨迹 (Chronological bead trajectory)
              if (this.completedToday.length === 0) {
                Column({ space: 6 }) {
                  Image($r('app.media.ic_sparkle'))
                    .width(22)
                    .height(22)
                    .fillColor(ColorConstants.DARK_TEXT_TERTIARY)

                  Text('今天虽未标记完成事项，但充分的放空休整，也是可持续节律的关键一部分。')
                    .fontSize(12)
                    .fontColor(ColorConstants.DARK_TEXT_SECONDARY)
                    .textAlign(TextAlign.Center)
                    .lineHeight(18)
                }
                .padding({ top: 16, bottom: 16 })
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              } else {
                Column({ space: 8 }) {
                  ForEach(this.completedToday, (item: TodoItem) => {
                    Row({ space: 10 }) {
                      // 珠点标记与时间
                      Row({ space: 4 }) {
                        Circle({ width: 8, height: 8 })
                          .fill(ColorConstants.DARK_DAWN_CYAN)
                        Text(TimeUtils.formatTime(item.completedAt))
                          .fontSize(11)
                          .fontColor(ColorConstants.DARK_TEXT_TERTIARY)
                      }
                      .width(62)

                      // 事项标题
                      Text(item.title)
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(ColorConstants.DARK_TEXT_PRIMARY)
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      // 温润勾选完成态
                      Image($r('app.media.ic_check'))
                        .width(14)
                        .height(14)
                        .fillColor(ColorConstants.DARK_DAWN_CYAN)
                    }
                    .width('100%')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  }, (item: TodoItem): string => item.id)
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })
              }

              // 底部原生零权限安全控件 SaveButton
              Row() {
                SaveButton({
                  icon: SaveIconStyle.FULL_FILLED,
                  text: SaveDescription.SAVE_IMAGE,
                  buttonType: ButtonType.Capsule
                })
                  .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                    if (result === SaveButtonOnClickResult.SUCCESS) {
                      this.isSavedCardToast = true;
                      HapticService.getInstance().triggerClick();
                      setTimeout(() => {
                        this.isSavedCardToast = false;
                      }, 1500);
                    }
                  })
                  .height(36)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: 4 })
            }
            .width('90%')
            .padding(18)
            .borderRadius(18)
            .backgroundColor('rgba(255, 255, 255, 0.06)')
            .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.12)' })

            // 4. 【零负罪感待办顺延】：明日机动就绪
            Column({ space: 12 }) {
              Row() {
                Text('未完成事项 · 无负罪感流转')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.DARK_TEXT_SECONDARY)
              }
              .width('100%')

              if (this.incompleteTasks.length === 0) {
                Text('今日所有待办均已达成，心流澄澈无挂碍。')
                  .fontSize(13)
                  .fontColor(ColorConstants.DARK_DAWN_CYAN)
                  .padding(12)
              } else {
                Column({ space: 8 }) {
                  Text(`剩余 ${this.incompleteTasks.length} 项待办`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ColorConstants.DARK_TEXT_PRIMARY)

                  Text('剩余待办已在明天机动就绪，无需补卡，今晚安心休息。')
                    .fontSize(12)
                    .fontColor(ColorConstants.DARK_TEXT_SECONDARY)
                    .lineHeight(18)
                }
                .width('100%')
                .padding({ top: 4, bottom: 4 })
                .alignItems(HorizontalAlign.Start)

                // 核心解脱按钮：安心打烊，开启明天
                Button({ type: ButtonType.Capsule }) {
                  Row({ space: 6 }) {
                    Image($r('app.media.ic_sprout'))
                      .width(15)
                      .height(15)
                      .fillColor(Color.White)
                    Text('安心打烊，开启明天')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.White)
                  }
                }
                .backgroundColor(ColorConstants.DARK_FLOW_VIOLET_DEEP)
                .width('100%')
                .height(44)
                .shadow({ radius: 12, color: 'rgba(108, 92, 231, 0.25)', offsetY: 3 })
                .onClick(() => {
                  this.handleBatchRolloverTomorrow();
                })

                // 可选次级入口：展开单独挑选事项冷冻或放弃
                Row() {
                  Text(this.isDetailExpanded ? '收起逐项微调' : `需要单独挑选个别事项？展开微调 (${this.incompleteTasks.length})`)
                    .fontSize(11)
                    .fontColor(ColorConstants.DARK_TEXT_TERTIARY)
                }
                .padding({ top: 4, bottom: 2 })
                .onClick(() => {
                  this.isDetailExpanded = !this.isDetailExpanded;
                  HapticService.getInstance().triggerTick();
                })

                if (this.isDetailExpanded) {
                  ForEach(this.incompleteTasks, (item: TodoItem) => {
                    Column({ space: 8 }) {
                      Text(item.title)
                        .fontSize(14)
                        .fontColor(ColorConstants.DARK_TEXT_PRIMARY)
                        .fontWeight(FontWeight.Medium)

                      Row({ space: 8 }) {
                        Button({ type: ButtonType.Capsule }) {
                          Row({ space: 4 }) {
                            Image($r('app.media.ic_frost'))
                              .width(11)
                              .height(11)
                              .fillColor(ColorConstants.DARK_FROST_BLUE)
                            Text('冷冻舱')
                              .fontSize(11)
                              .fontColor(ColorConstants.DARK_FROST_BLUE)
                          }
                          .padding({ left: 6, right: 6 })
                        }
                        .backgroundColor('rgba(143, 162, 176, 0.12)')
                        .height(26)
                        .layoutWeight(1)
                        .onClick(() => {
                          this.handleFreezeTask(item);
                        })

                        Button({ type: ButtonType.Capsule }) {
                          Row({ space: 4 }) {
                            Image($r('app.media.ic_trash'))
                              .width(11)
                              .height(11)
                              .fillColor(ColorConstants.DARK_TEXT_TERTIARY)
                            Text('算了')
                              .fontSize(11)
                              .fontColor(ColorConstants.DARK_TEXT_TERTIARY)
                          }
                          .padding({ left: 6, right: 6 })
                        }
                        .backgroundColor('rgba(255, 255, 255, 0.05)')
                        .height(26)
                        .layoutWeight(1)
                        .onClick(() => {
                          this.handleCancelTask(item);
                        })
                      }
                      .width('100%')
                    }
                    .width('100%')
                    .padding(12)
                    .borderRadius(14)
                    .backgroundColor('rgba(255, 255, 255, 0.04)')
                    .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.08)' })
                  }, (item: TodoItem): string => item.id)
                }
              }
            }
            .width('90%')

            // 5. 彻底物理断电按钮
            Button('彻底物理断电 · 安心享受私人时光')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.DARK_TEXT_SECONDARY)
              .backgroundColor('rgba(255, 255, 255, 0.06)')
              .width('90%')
              .height(44)
              .margin({ top: 12, bottom: 32 })
              .onClick(() => {
                HapticService.getInstance().triggerHeavy();
                this.onClose();
              })
          }
          .width('100%')
          .padding({ top: 8, bottom: this.bottomAvoidHeight + 20 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.topAvoidHeight })

      if (this.isSavedCardToast) {
        Row({ space: 6 }) {
          Image($r('app.media.ic_check'))
            .width(12)
            .height(12)
            .fillColor(Color.White)
          Text('已零权限保存至系统相册')
            .fontSize(12)
            .fontColor(Color.White)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .borderRadius(14)
        .backgroundColor(ColorConstants.DARK_FLOW_VIOLET)
        .margin({ bottom: this.bottomAvoidHeight + 32 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.DARK_BG_SUNSET)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private async loadCeremonyData(): Promise<void> {
    try {
      const allCompleted: TodoItem[] = await TodoDao.queryCompleted();
      const now = new Date();
      const startOfDay: number = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();
      this.completedToday = allCompleted
        .filter((t: TodoItem): boolean => t.completedAt >= startOfDay)
        .reverse();

      const allActive: TodoItem[] = await TodoDao.queryAllActive();
      this.incompleteTasks = allActive.filter((t: TodoItem): boolean => t.status !== TodoStatus.COMPLETED);
    } catch {
      this.completedToday = [];
      this.incompleteTasks = [];
    }
  }

  private async handleBatchRolloverTomorrow(): Promise<void> {
    try {
      for (const item of this.incompleteTasks) {
        item.scheduledStartAt = 0;
        item.scheduledEndAt = 0;
        item.isPinned = false;
        await TodoDao.update(item);
      }
      this.incompleteTasks = [];
      AudioService.getInstance().playChordStep();
      HapticService.getInstance().triggerHeavy();
      this.onClose();
    } catch {
      this.onClose();
    }
  }

  private async handleFreezeTask(item: TodoItem): Promise<void> {
    item.isFrozen = true;
    item.status = TodoStatus.FROZEN;
    item.agingLevel = 3;
    item.scheduledStartAt = 0;
    item.scheduledEndAt = 0;
    await TodoDao.update(item);
    HapticService.getInstance().triggerTick();
    await this.loadCeremonyData();
  }

  private async handleCancelTask(item: TodoItem): Promise<void> {
    await TodoDao.deleteTombstone(item.id);
    HapticService.getInstance().triggerTick();
    await this.loadCeremonyData();
  }
}
