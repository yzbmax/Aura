/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * TV Ambient Focus View: 10-Foot Living Room Macro Focus Wall
 * Optimized for Smart Screen (TV) with D-Pad Remote Control & Focus Effects
 * Completely decoupled from BinPackingScheduler and TimeSlot
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem, TodoStatus } from '../models/TodoItem';
import { UserSettings } from '../models/UserSettings';
import { TodoDao } from '../database/dao/TodoDao';
import { AudioService } from '../common/media/AudioService';

@ComponentV2
export struct TvAmbientFocusView {
  @Param settings: UserSettings = new UserSettings();

  @Local activeTasks: TodoItem[] = [];
  @Local currentTask: TodoItem | null = null;
  @Local isTimerRunning: boolean = true;
  @Local remainingSeconds: number = 25 * 60;
  @Local focusedControlId: string = 'btn_toggle_timer';

  private timerIntervalId: number = -1;

  async aboutToAppear(): Promise<void> {
    await this.loadTasks();
    this.startTimer();
  }

  aboutToDisappear(): void {
    if (this.timerIntervalId !== -1) {
      clearInterval(this.timerIntervalId);
      this.timerIntervalId = -1;
    }
  }

  private async loadTasks(): Promise<void> {
    try {
      const activeTodos = await TodoDao.queryAllActive();
      this.activeTasks = activeTodos.filter((t: TodoItem): boolean => !t.isDeleted && t.status !== TodoStatus.CANCELLED);
      if (this.activeTasks.length > 0) {
        // 寻找第一个未完成的任务
        const firstUnfinished = this.activeTasks.find((t: TodoItem): boolean => t.status !== TodoStatus.COMPLETED);
        this.currentTask = firstUnfinished ?? this.activeTasks[0];
        if (this.currentTask) {
          this.remainingSeconds = this.currentTask.estimatedMinutes * 60;
        }
      }
    } catch {
      // 容错降级
    }
  }

  private startTimer(): void {
    if (this.timerIntervalId !== -1) {
      clearInterval(this.timerIntervalId);
    }
    this.timerIntervalId = setInterval(() => {
      if (this.isTimerRunning && this.remainingSeconds > 0) {
        this.remainingSeconds--;
        if (this.remainingSeconds === 0) {
          AudioService.getInstance().playSunsetGong();
          this.isTimerRunning = false;
        }
      }
    }, 1000);
  }

  private toggleTimer(): void {
    this.isTimerRunning = !this.isTimerRunning;
    AudioService.getInstance().playChordStep();
  }

  private formatRemainingTime(): string {
    const m = Math.floor(this.remainingSeconds / 60).toString().padStart(2, '0');
    const s = (this.remainingSeconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  build() {
    Row() {
      // 1. 左侧：巨型客厅沉浸沙漏与心流光晕 (10-foot Ambient Focus)
      Column({ space: 24 }) {
        // 智慧屏顶标
        Row({ space: 10 }) {
          Image($r('app.media.ic_sparkle'))
            .width(28)
            .height(28)
            .fillColor(ColorConstants.ACCENT_CORAL)
          Text('Aura · 空间心流壁画')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
        }
        .width('100%')
        .padding({ top: 12 })

        Blank()

        // 巨型脉动沙漏环 (直径 320vp，大屏气势恢宏)
        Stack({ alignContent: Alignment.Center }) {
          // 背景光晕
          Circle({ width: 330, height: 330 })
            .fill(ColorConstants.ACCENT_CORAL_SOFT)

          // 刻度环
          Circle({ width: 300, height: 300 })
            .stroke(ColorConstants.ACCENT_CORAL)
            .strokeWidth(6)
            .fill(ColorConstants.LIGHT_CARD_BG)
            .shadow({ radius: 24, color: 'rgba(232, 122, 100, 0.25)', offsetY: 4 })

          Column({ space: 8 }) {
            Text(this.formatRemainingTime())
              .fontSize(64)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              .letterSpacing(2)

            Text(this.currentTask?.title ?? '当下专注中')
              .fontSize(18)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Row({ space: 6 }) {
              Image(this.isTimerRunning ? $r('app.media.ic_sparkle') : $r('app.media.ic_pause'))
                .width(13)
                .height(13)
                .fillColor(this.isTimerRunning ? ColorConstants.BLOCK_SAGE_GREEN : ColorConstants.BLOCK_WARM_AMBER)
              Text(this.isTimerRunning ? '心流脉动中' : '已暂停')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.isTimerRunning ? ColorConstants.BLOCK_SAGE_GREEN : ColorConstants.BLOCK_WARM_AMBER)
            }
          }
        }
        .width(340)
        .height(340)

        Blank()

        // 遥控器焦点按键 (D-pad 适配，遥控器 OK 键直接触发展开/暂停)
        Row({ space: 16 }) {
          Button(this.isTimerRunning ? '暂停心流 (OK键)' : '继续专注 (OK键)')
            .height(56)
            .padding({ left: 32, right: 32 })
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor(this.isTimerRunning ? ColorConstants.BLOCK_WARM_AMBER : ColorConstants.ACCENT_CORAL)
            .borderRadius(18)
            .focusable(true)
            .onClick(() => {
              this.toggleTimer();
            })

          Button('切换下一项')
            .height(56)
            .padding({ left: 24, right: 24 })
            .fontSize(16)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            .backgroundColor('rgba(85, 70, 50, 0.08)')
            .borderRadius(18)
            .focusable(true)
            .onClick(() => {
              if (this.activeTasks.length > 1 && this.currentTask) {
                const nextIndex = (this.activeTasks.indexOf(this.currentTask) + 1) % this.activeTasks.length;
                this.currentTask = this.activeTasks[nextIndex];
                if (this.currentTask) {
                  this.remainingSeconds = this.currentTask.estimatedMinutes * 60;
                }
              }
            })
        }
        .margin({ bottom: 20 })
      }
      .width('44%')
      .height('100%')
      .padding({ left: 48, right: 24, top: 24, bottom: 24 })
      .alignItems(HorizontalAlign.Center)

      // 2. 右侧：今日心流序列 (宏观卡片序列，遥控器方向键列表浏览)
      Column({ space: 16 }) {
        Row() {
          Text('今日心流序列')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          Blank()
          Text(`${this.activeTasks.length} 项微步`)
            .fontSize(14)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: 16, bottom: 8 })

        List({ space: 12 }) {
          ForEach(this.activeTasks, (task: TodoItem) => {
            ListItem() {
              Row({ space: 14 }) {
                // 状态圆点
                Circle({ width: 12, height: 12 })
                  .fill(task.status === TodoStatus.COMPLETED
                    ? ColorConstants.BLOCK_SAGE_GREEN
                    : (task.id === this.currentTask?.id ? ColorConstants.ACCENT_CORAL : 'rgba(85, 70, 50, 0.2)'))

                // 预估耗时 (替代旧的时刻范围)
                Text(`${task.estimatedMinutes}m`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                  .width(60)

                // 标题
                Text(task.title)
                  .fontSize(16)
                  .fontWeight(task.id === this.currentTask?.id ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(task.id === this.currentTask?.id ? ColorConstants.LIGHT_TEXT_PRIMARY : ColorConstants.LIGHT_TEXT_SECONDARY)
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (task.id === this.currentTask?.id) {
                  Text('专注中')
                    .fontSize(12)
                    .fontColor(ColorConstants.ACCENT_CORAL)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(8)
                    .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
                }
              }
              .width('100%')
              .height(64)
              .padding({ left: 18, right: 18 })
              .borderRadius(16)
              .backgroundColor(task.id === this.currentTask?.id ? 'rgba(232, 122, 100, 0.08)' : ColorConstants.LIGHT_CARD_BG)
              .border({
                width: task.id === this.currentTask?.id ? 1.5 : 0.5,
                color: task.id === this.currentTask?.id ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_CARD_BORDER
              })
              .focusable(true)
              .onClick(() => {
                this.currentTask = task;
                this.remainingSeconds = task.estimatedMinutes * 60;
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('56%')
      .height('100%')
      .padding({ left: 24, right: 48, top: 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
  }
}
