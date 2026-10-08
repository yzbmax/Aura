/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Tab 2: Task Matrix View & Frozen Deck (Mild Aging & Cold Cabin)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { Priority, TodoItem, TodoSource, TodoStatus } from '../models/TodoItem';
import { TodoDao } from '../database/dao/TodoDao';
import { MildAgingEngine } from '../engine/MildAgingEngine';
import { HapticService } from '../common/media/HapticService';
import { AudioService } from '../common/media/AudioService';
import { ActivityCalendar, ContributionItem } from '@ohmos/activity_overview';
import { SampleDataLoader } from '../database/SampleDataLoader';
import { UndoService } from '../common/utils/UndoService';
import { CurveConstants } from '../common/constants/CurveConstants';

enum MatrixTab {
  WORKSHOP = 0, // 待办工坊 (列表与分类过滤)
  INSIGHTS = 1  // 精力镜像 (Bento 便当盒看板)
}

enum WorkshopFilter {
  ALL = 0,
  HIGH_PRIORITY = 1,
  EXPLORATION = 2,
  PARKING_OR_FLOATING = 3,
  FROZEN = 4
}

@ComponentV2
export struct TaskMatrixView {
  @Param isInitialized: boolean = false;
  @Param topAvoidHeight: number = 0;
  @Event onOpenFocus: (item: TodoItem) => void = () => {};
  @Local currentSubTab: MatrixTab = MatrixTab.WORKSHOP;
  @Local workshopFilter: WorkshopFilter = WorkshopFilter.ALL;
  @Local allTasks: TodoItem[] = [];
  @Local frozenTasks: TodoItem[] = [];
  @Local completedTasks: TodoItem[] = [];
  @Local contributions: ContributionItem[] = [];
  @Local selectedDate: string = '';
  @Local selectedCount: number = -1;
  @Local streakDays: number = 0;
  @Local todayCompletedCount: number = 0;
  @Local todayFocusMinutes: number = 0;
  @Local todayTargetMinutes: number = 270; // 4.5h 脑力硬上限

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
      await this.loadData();
    } catch {
      // 容错兜底
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 14 }) {
        // 1. 顶栏标题 (极简微晶质感 + 日期呼吸感)
        Row() {
          Column({ space: 3 }) {
            Text('Aura · 任务视界')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            Text(this.getTodayFormattedDate())
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 右侧微光指示器
          Row({ space: 5 }) {
            Circle().width(6).height(6).fill(ColorConstants.ACCENT_CORAL)
            Text(`${this.allTasks.length} 待办 · ${this.completedTasks.length} 完成`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
          }
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('rgba(85, 70, 50, 0.05)')
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
        .zIndex(10)

        // 2. Apple 风格流体分段胶囊控制器 (Sliding Segmented Control)
        Row({ space: 6 }) {
          this.buildSegmentItem('待办工坊', MatrixTab.WORKSHOP)
          this.buildSegmentItem('精力镜像', MatrixTab.INSIGHTS)
        }
        .width('90%')
        .height(38)
        .padding(3)
        .borderRadius(19)
        .backgroundColor('rgba(85, 70, 50, 0.05)')

        // 3. 内容展示区
        Scroll() {
          Column({ space: 14 }) {
            if (this.currentSubTab === MatrixTab.WORKSHOP) {
              this.buildWorkshopView();
            } else {
              this.buildInsightsView();
            }

            // 底部悬浮底栏留白避让
            Blank().height(96)
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.topAvoidHeight > 0 ? this.topAvoidHeight : 0 })
      .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildSegmentItem(title: string, tab: MatrixTab) {
    Stack() {
      if (this.currentSubTab === tab) {
        Rect()
          .width('100%')
          .height('100%')
          .radius(16)
          .fill(Color.White)
          .shadow({ radius: 8, color: 'rgba(85, 70, 50, 0.08)', offsetY: 2 })
      }

      Text(title)
        .fontSize(12)
        .fontWeight(this.currentSubTab === tab ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentSubTab === tab ? ColorConstants.LIGHT_TEXT_PRIMARY : ColorConstants.LIGHT_TEXT_TERTIARY)
    }
    .layoutWeight(1)
    .height('100%')
    .borderRadius(16)
    .onClick(() => {
      if (this.currentSubTab !== tab) {
        this.currentSubTab = tab;
        HapticService.getInstance().triggerTick();
      }
    })
  }

  @Builder
  private buildSwipeDeleteAction(taskId: string) {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_trash'))
          .width(18)
          .height(18)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor(ColorConstants.ACCENT_CORAL)
      .onClick(() => {
        this.deleteTask(taskId);
      })
    }
    .justifyContent(FlexAlign.Center)
    .width(56)
    .height('100%')
  }

  private getFilteredTasks(): TodoItem[] {
    if (this.workshopFilter === WorkshopFilter.HIGH_PRIORITY) {
      return this.allTasks.filter(t => t.priority === Priority.HIGH);
    } else if (this.workshopFilter === WorkshopFilter.EXPLORATION) {
      return this.allTasks.filter(t => t.isExplorationSlice);
    } else if (this.workshopFilter === WorkshopFilter.PARKING_OR_FLOATING) {
      return this.allTasks.filter(t => t.scheduledStartAt <= 0 || t.source === TodoSource.PARKING_LOT);
    }
    return this.allTasks;
  }

  @Builder
  private buildFilterChip(label: string, filter: WorkshopFilter, count: number) {
    Row({ space: 5 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(this.workshopFilter === filter ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.workshopFilter === filter ? Color.White : ColorConstants.LIGHT_TEXT_SECONDARY)

      if (count > 0) {
        Text(`${count}`)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.workshopFilter === filter ? 'rgba(255,255,255,0.92)' : ColorConstants.LIGHT_TEXT_TERTIARY)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .borderRadius(8)
          .backgroundColor(this.workshopFilter === filter ? 'rgba(255,255,255,0.22)' : 'rgba(85, 70, 50, 0.06)')
      }
    }
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .borderRadius(16)
    .backgroundColor(this.workshopFilter === filter ? ColorConstants.ACCENT_CORAL : 'rgba(85, 70, 50, 0.05)')
    .onClick(() => {
      if (this.workshopFilter !== filter) {
        this.workshopFilter = filter;
        HapticService.getInstance().triggerTick();
      }
    })
  }

  @Builder
  private buildWorkshopView() {
    Column({ space: 12 }) {
      // 1. 水平滑动分类胶囊条 (Filter Chips)
      Scroll() {
        Row({ space: 8 }) {
          this.buildFilterChip('全部', WorkshopFilter.ALL, this.allTasks.length)
          this.buildFilterChip('核心攻坚', WorkshopFilter.HIGH_PRIORITY, this.allTasks.filter(t => t.priority === Priority.HIGH).length)
          this.buildFilterChip('45m探索', WorkshopFilter.EXPLORATION, this.allTasks.filter(t => t.isExplorationSlice).length)
          this.buildFilterChip('机动池', WorkshopFilter.PARKING_OR_FLOATING, this.allTasks.filter(t => t.scheduledStartAt <= 0 || t.source === TodoSource.PARKING_LOT).length)
          this.buildFilterChip('冷冻舱', WorkshopFilter.FROZEN, this.frozenTasks.length)
        }
        .padding({ left: 2, right: 2, top: 2, bottom: 2 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      // 2. 列表内容展示
      if (this.workshopFilter === WorkshopFilter.FROZEN) {
        this.buildFrozenDeck();
      } else {
        this.buildAllTaskList();
      }
    }
    .width('100%')
  }

  @Builder
  private buildInsightsView() {
    Column({ space: 14 }) {
      // 1. Apple 风格双核微晶能量环看板 (Dual Activity Rings & Streak Hero Card)
      this.buildHeroEnergyCard();

      // 2. 带自然月份标尺的心流热力图卡片 (Month-Guided Micro-Glow Heatmap)
      this.buildHeatmapCard();
    }
    .width('100%')
  }

  @Builder
  private buildAllTaskList() {
    Column({ space: 10 }) {
      if (this.getFilteredTasks().length === 0) {
        Column({ space: 6 }) {
          Image($r('app.media.ic_sparkle'))
            .width(28)
            .height(28)
            .fillColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          Text('当前分类下暂无事项，尽享轻松时刻')
            .fontSize(13)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: 40 })
      } else {
        // 顶部轻量提示与指引
        Row() {
          Text(`进行中事项 (${this.getFilteredTasks().length})`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)

          Blank()

          Text('左滑删除 · 触点打勾')
            .fontSize(11)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ left: 4, right: 4, bottom: 2 })

        List({ space: 8 }) {
          ForEach(this.getFilteredTasks(), (task: TodoItem) => {
            ListItem() {
              Row({ space: 10 }) {
                // 1. 微晶完成环 (Things 3 式打勾微交互)
                Stack() {
                  Circle({ width: 22, height: 22 })
                    .fill(task.status === TodoStatus.COMPLETED ? ColorConstants.BLOCK_SAGE_GREEN : Color.Transparent)
                    .stroke(task.status === TodoStatus.COMPLETED ? ColorConstants.BLOCK_SAGE_GREEN : 'rgba(85, 70, 50, 0.25)')
                    .strokeWidth(1.5)

                  if (task.status === TodoStatus.COMPLETED) {
                    Image($r('app.media.ic_check'))
                      .width(13)
                      .height(13)
                      .fillColor(Color.White)
                  }
                }
                .width(32)
                .height(32)
                .onClick(() => {
                  this.toggleTaskComplete(task);
                })

                // 2. 事项主体 (标题 + 核心/沉底微标 + 排期属性)
                Column({ space: 3 }) {
                  Row({ space: 6 }) {
                    if (task.priority === Priority.HIGH) {
                      Row({ space: 2 }) {
                        Image($r('app.media.ic_flame'))
                          .width(9)
                          .height(9)
                          .fillColor(ColorConstants.ACCENT_CORAL)
                        Text('核心')
                          .fontSize(9)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(ColorConstants.ACCENT_CORAL)
                      }
                      .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      .borderRadius(4)
                      .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
                    }

                    Text(task.title)
                      .fontSize(14)
                      .fontColor(task.status === TodoStatus.COMPLETED ? ColorConstants.LIGHT_TEXT_TERTIARY : ColorConstants.LIGHT_TEXT_PRIMARY)
                      .fontWeight(FontWeight.Medium)
                      .decoration({
                        type: task.status === TodoStatus.COMPLETED ? TextDecorationType.LineThrough : TextDecorationType.None,
                        color: ColorConstants.LIGHT_TEXT_TERTIARY
                      })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                  }
                  .width('100%')

                  Row({ space: 6 }) {
                    Text(`${task.estimatedMinutes} 分钟`)
                      .fontSize(11)
                      .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

                    if (task.scheduledStartAt > 0) {
                      Text('· 今日已排期')
                        .fontSize(11)
                        .fontColor(ColorConstants.BLOCK_DENIM_BLUE)
                    } else {
                      Text('· 机动待办')
                        .fontSize(11)
                        .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .onClick(() => {
                  if (task.status !== TodoStatus.COMPLETED) {
                    this.onOpenFocus(task);
                  }
                })

                // 3. 右侧极简微晶时间胶囊与更多操作 (彻底移除重复的「删除」文字)
                Row({ space: 4 }) {
                  Text(`${task.estimatedMinutes}m`)
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                    .padding({ left: 7, right: 7, top: 3, bottom: 3 })
                    .borderRadius(8)
                    .backgroundColor('rgba(85, 70, 50, 0.05)')

                  Button({ type: ButtonType.Circle }) {
                    Text('···')
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                  }
                  .width(28)
                  .height(28)
                  .backgroundColor(Color.Transparent)
                  .bindMenu([
                    {
                      value: '移入冷冻舱',
                      action: () => {
                        this.freezeTask(task);
                      }
                    },
                    {
                      value: '删除事项',
                      action: () => {
                        this.deleteTask(task.id);
                      }
                    }
                  ])
                }
              }
              .width('100%')
              .padding(12)
              .borderRadius(18)
              .backgroundColor(ColorConstants.LIGHT_CARD_BG)
              .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
              .shadow({ radius: 10, color: 'rgba(85, 70, 50, 0.03)', offsetY: 2 })
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.buildSwipeDeleteAction(task.id);
                }
              }
            })
          })
        }
        .width('100%')
        .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
  }

  @Builder
  private buildFrozenDeck() {
    Column({ space: 12 }) {
      // 1. 三阶温和老化机制图解卡片 (Anti-guilt Aging Horizon Card)
      Column({ space: 10 }) {
        Row({ space: 6 }) {
          Image($r('app.media.ic_frost'))
            .width(16)
            .height(16)
            .fillColor(ColorConstants.FROZEN_CRYSTAL)
          Text('冷冻舱 · 反内疚精力休眠机制')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.FROZEN_CRYSTAL)
        }
        .width('100%')

        // 三阶演化图解
        Row({ space: 6 }) {
          Column({ space: 2 }) {
            Text('0 ~ 7 天')
              .fontSize(10)
              .fontColor(ColorConstants.LIGHT_REST_SAGE)
              .fontWeight(FontWeight.Bold)
            Text('活跃心流')
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          }
          .layoutWeight(1)
          .padding(6)
          .borderRadius(8)
          .backgroundColor('rgba(94, 168, 122, 0.08)')
          .alignItems(HorizontalAlign.Center)

          Text('→').fontSize(12).fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

          Column({ space: 2 }) {
            Text('7 ~ 14 天')
              .fontSize(10)
              .fontColor(ColorConstants.AGING_MILD_AMBER)
              .fontWeight(FontWeight.Bold)
            Text('温和沉底')
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          }
          .layoutWeight(1)
          .padding(6)
          .borderRadius(8)
          .backgroundColor('rgba(194, 131, 63, 0.08)')
          .alignItems(HorizontalAlign.Center)

          Text('→').fontSize(12).fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

          Column({ space: 2 }) {
            Text('14 天以上')
              .fontSize(10)
              .fontColor(ColorConstants.FROZEN_CRYSTAL)
              .fontWeight(FontWeight.Bold)
            Text('冰晶休眠')
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          }
          .layoutWeight(1)
          .padding(6)
          .borderRadius(8)
          .backgroundColor('rgba(143, 162, 176, 0.15)')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')

        Text('久置的事项不是失败，只是时机未到。冷冻舱屏蔽一切催命逾期红字，让任务安静安歇，随时可一键唤醒。')
          .fontSize(11)
          .lineHeight(16)
          .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
      }
      .width('100%')
      .padding(14)
      .borderRadius(18)
      .backgroundColor('rgba(143, 162, 176, 0.08)')
      .border({ width: 0.5, color: 'rgba(143, 162, 176, 0.2)' })

      // 2. 冷冻事项列表
      if (this.frozenTasks.length === 0) {
        Column({ space: 6 }) {
          Image($r('app.media.ic_frost'))
            .width(28)
            .height(28)
            .fillColor(ColorConstants.FROZEN_CRYSTAL)
          Text('冷冻舱暂无休眠事项 · 精力状态饱满')
            .fontSize(12)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
      } else {
        ForEach(this.frozenTasks, (item: TodoItem) => {
          Row() {
            Column({ space: 3 }) {
              Row({ space: 6 }) {
                Image($r('app.media.ic_frost'))
                  .width(12)
                  .height(12)
                  .fillColor(ColorConstants.FROZEN_CRYSTAL)
                Text(item.title)
                  .fontSize(14)
                  .fontColor(ColorConstants.FROZEN_CRYSTAL)
              }
              Text('已休眠 · 无催命红字警报')
                .fontSize(11)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button('解冻唤醒')
              .type(ButtonType.Capsule)
              .fontSize(11)
              .fontColor(ColorConstants.ACCENT_CORAL)
              .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
              .height(26)
              .onClick(() => {
                this.unfreezeTask(item);
              })
          }
          .width('100%')
          .padding(14)
          .borderRadius(18)
          .backgroundColor('rgba(143, 162, 176, 0.12)')
          .border({ width: 0.5, color: 'rgba(143, 162, 176, 0.25)' })
        })
      }
    }
    .width('100%')
  }

  @Builder
  private buildHeroEnergyCard() {
    Row({ space: 16 }) {
      // 左侧：双层闭环心流能量微晶环 (Apple Fitness 质感)
      Stack() {
        // 外环：珊瑚陶土 - 今日专注投入时长 / 4.5h 脑力上限
        Progress({
          value: Math.min(this.todayFocusMinutes, this.todayTargetMinutes),
          total: this.todayTargetMinutes,
          type: ProgressType.Ring
        })
          .color(ColorConstants.ACCENT_CORAL)
          .width(96)
          .height(96)
          .style({ strokeWidth: 8 })

        // 内环：鼠尾草绿 - 今日完成待办比例
        Progress({
          value: this.todayCompletedCount,
          total: Math.max(this.todayCompletedCount + this.allTasks.length, 1),
          type: ProgressType.Ring
        })
          .color(ColorConstants.BLOCK_SAGE_GREEN)
          .width(74)
          .height(74)
          .style({ strokeWidth: 7 })

        // 环心：能量微标 (0 专注时显示蓄能萌芽，有专注时显示心流火苗)
        Image(this.todayFocusMinutes > 0 ? $r('app.media.ic_flame') : $r('app.media.ic_sprout'))
          .width(18)
          .height(18)
          .fillColor(this.todayFocusMinutes > 0 ? ColorConstants.ACCENT_CORAL : ColorConstants.BLOCK_SAGE_GREEN)
      }
      .width(96)
      .height(96)

      // 右侧：多维成就看板与自律指标
      Column({ space: 8 }) {
        // 连续心流 Streak 徽章
        Row({ space: 6 }) {
          Text(`${this.streakDays}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.ACCENT_CORAL)
          Text('天连续心流')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
        }
        Text(this.todayFocusMinutes > 0
          ? '保持节律 · 专注投入渐入佳境'
          : '今日大脑充分休整 · 留白沉淀亦是节律的一部分')
          .fontSize(11)
          .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          .letterSpacing(0.2)

        Divider().color('rgba(0, 0, 0, 0.05)')

        // 闭环详情
        Row({ space: 10 }) {
          Row({ space: 4 }) {
            Circle().width(6).height(6).fill(this.todayFocusMinutes > 0 ? ColorConstants.ACCENT_CORAL : ColorConstants.BLOCK_SAGE_GREEN)
            Text(this.todayFocusMinutes > 0 ? `专注 ${(this.todayFocusMinutes / 60).toFixed(1)}h` : '蓄能留白')
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .letterSpacing(0.2)
          }

          Row({ space: 4 }) {
            Circle().width(6).height(6).fill(ColorConstants.BLOCK_SAGE_GREEN)
            Text(`已达成 ${this.todayCompletedCount} 项`)
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .letterSpacing(0.2)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(ColorConstants.LIGHT_CARD_BG)
    .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
    .shadow({ radius: 10, color: 'rgba(85, 70, 50, 0.05)', offsetY: 3 })
  }

  @Builder
  private buildHeatmapCard() {
    Column({ space: 10 }) {
      // 头部标题与周数标签
      Row({ space: 6 }) {
        Image($r('app.media.ic_sparkle'))
          .width(15)
          .height(15)
          .fillColor(ColorConstants.ACCENT_CORAL)
        Text('心流足迹 · 每日专注沉淀')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
        Blank()
        Text('近 16 周')
          .fontSize(11)
          .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
      }
      .width('100%')

      Text('横向滑动探索自律轨迹，色块越深代表当日心流投入越深')
        .fontSize(11)
        .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        .width('100%')

      // 自然月份对齐标尺
      Row() {
        ForEach(this.getMonthLabels(), (m: string) => {
          Text(m)
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 10, right: 10, top: 4 })

      // 嵌入开源热力图组件
      Row() {
        ActivityCalendar({
          contributions: this.contributions,
          weeks: 16,
          blockSize: 13,
          blockSpace: 3,
          colors: ['#EDEAE2', '#FAD8D0', '#F4B0A4', '#E87A64', '#C95944'],
          thresholds: [1, 2, 4, 6],
          onBlockClick: (date: string, count: number) => {
            this.selectedDate = date;
            this.selectedCount = count;
            HapticService.getInstance().triggerTick();
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 选定日期微晶高光气泡条与渐变图例
      Row() {
        if (this.selectedDate !== '') {
          Row({ space: 6 }) {
            Image($r('app.media.ic_sparkle'))
              .width(12)
              .height(12)
              .fillColor(ColorConstants.ACCENT_CORAL)
            Text(`${this.selectedDate} · 完成了 ${this.selectedCount} 个专注事项`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.ACCENT_CORAL)
          }
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(12)
          .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
        } else {
          Text('点击方格查看对应日期的心流达成')
            .fontSize(11)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            .padding({ top: 3, bottom: 3 })
        }

        Blank()

        Row({ space: 4 }) {
          Text('少').fontSize(9).fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          Row({ space: 2 }) {
            Rect().width(8).height(8).radius(2).fill('#EDEAE2')
            Rect().width(8).height(8).radius(2).fill('#FAD8D0')
            Rect().width(8).height(8).radius(2).fill('#F4B0A4')
            Rect().width(8).height(8).radius(2).fill('#E87A64')
            Rect().width(8).height(8).radius(2).fill('#C95944')
          }
          Text('多').fontSize(9).fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
      }
      .width('100%')
      .padding({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(ColorConstants.LIGHT_CARD_BG)
    .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
    .shadow({ radius: 10, color: 'rgba(0, 0, 0, 0.02)', offsetY: 2 })
  }

  private getTodayFormattedDate(): string {
    const now = new Date();
    const m = now.getMonth() + 1;
    const d = now.getDate();
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return `${m}月${d}日 · ${days[now.getDay()]}`;
  }

  private getMonthLabels(): string[] {
    const now = new Date();
    const labels: string[] = [];
    for (let i = 3; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      labels.push(`${d.getMonth() + 1}月`);
    }
    return labels;
  }

  private computeContributions(): void {
    const map: Map<string, number> = new Map<string, number>();

    // 统计真实已完成任务
    for (const item of this.completedTasks) {
      const ts = item.completedAt > 0 ? item.completedAt : item.updatedAt;
      if (ts > 0) {
        const d = new Date(ts);
        const y = d.getFullYear();
        const m = (d.getMonth() + 1).toString().padStart(2, '0');
        const day = d.getDate().toString().padStart(2, '0');
        const key = `${y}-${m}-${day}`;
        map.set(key, (map.get(key) || 0) + 1);
      }
    }

    // 若无历史数据或刚安装，提供过去 14 天的温和基线示范数据，保持热力图生动
    if (map.size === 0) {
      const today = new Date();
      for (let i = 1; i <= 14; i++) {
        const past = new Date(today.getTime() - i * 86400000);
        const y = past.getFullYear();
        const m = (past.getMonth() + 1).toString().padStart(2, '0');
        const day = past.getDate().toString().padStart(2, '0');
        const key = `${y}-${m}-${day}`;
        const sampleCount = (i % 3 === 0) ? 0 : ((i * 3) % 5) + 1;
        if (sampleCount > 0) {
          map.set(key, sampleCount);
        }
      }
    }

    const list: ContributionItem[] = [];
    map.forEach((count: number, date: string) => {
      list.push({ date: date, count: count });
    });
    this.contributions = list;

    // 计算连续心流天数 (Streak)
    let streak = 0;
    const checkDate = new Date();
    for (let i = 0; i < 30; i++) {
      const y = checkDate.getFullYear();
      const m = (checkDate.getMonth() + 1).toString().padStart(2, '0');
      const day = checkDate.getDate().toString().padStart(2, '0');
      const key = `${y}-${m}-${day}`;
      if ((map.get(key) || 0) > 0) {
        streak++;
        checkDate.setDate(checkDate.getDate() - 1);
      } else if (i === 0) {
        // 今天若刚开始，不中断昨天算起的连续天数
        checkDate.setDate(checkDate.getDate() - 1);
      } else {
        break;
      }
    }
    this.streakDays = streak;
  }

  private async loadData(): Promise<void> {
    try {
      const active = await TodoDao.queryAllActive();
      for (const t of active) {
        MildAgingEngine.evaluateAging(t);
      }
      this.allTasks = active.filter(t => !t.isFrozen);
      this.frozenTasks = await TodoDao.queryFrozenItems();
      this.completedTasks = await TodoDao.queryCompleted();

      // 计算今日专注总时长与已完成事项数
      const now = new Date();
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
      let minutes = 0;
      let doneCount = 0;
      for (const item of this.completedTasks) {
        const ts = item.completedAt > 0 ? item.completedAt : item.updatedAt;
        if (ts >= startOfDay) {
          doneCount++;
          minutes += (item.actualMinutes > 0 ? item.actualMinutes : item.estimatedMinutes);
        }
      }
      this.todayCompletedCount = doneCount;
      this.todayFocusMinutes = minutes;

      this.computeContributions();
    } catch {
      // 容错
    }
  }

  private async deleteTask(id: string): Promise<void> {
    const target = this.allTasks.find(t => t.id === id) || this.frozenTasks.find(t => t.id === id);
    const title = target ? target.title : '待办事项';
    await TodoDao.deleteTombstone(id);
    HapticService.getInstance().triggerTick();
    await this.loadData();

    UndoService.getInstance().showUndo(`已删除「${title}」`, async () => {
      await TodoDao.restoreTombstone(id);
      await this.loadData();
    });
  }

  private async unfreezeTask(item: TodoItem): Promise<void> {
    MildAgingEngine.unfreeze(item);
    await TodoDao.update(item);
    HapticService.getInstance().triggerClick();
    await this.loadData();
  }

  private async freezeTask(item: TodoItem): Promise<void> {
    MildAgingEngine.freeze(item);
    await TodoDao.update(item);
    HapticService.getInstance().triggerTick();
    await this.loadData();
    UndoService.getInstance().showUndo(`已将「${item.title}」移入冷冻舱`, async () => {
      MildAgingEngine.unfreeze(item);
      await TodoDao.update(item);
      await this.loadData();
    });
  }

  private async toggleTaskComplete(task: TodoItem): Promise<void> {
    const isNowCompleted = task.status !== TodoStatus.COMPLETED;
    task.status = isNowCompleted ? TodoStatus.COMPLETED : TodoStatus.PENDING;
    task.completedAt = isNowCompleted ? Date.now() : 0;

    if (isNowCompleted) {
      AudioService.getInstance().playChordStep();
      HapticService.getInstance().triggerClick();
    } else {
      HapticService.getInstance().triggerTick();
    }

    await TodoDao.update(task);
    await this.loadData();
  }
}
