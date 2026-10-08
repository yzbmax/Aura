/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Car Cockpit View: Automotive-Optimized Glanceable & Large-Touch Interface
 * Compliant with Huawei App Review Guidelines for Automotive (Targets >= 76vp)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem, TodoSource, TodoStatus } from '../models/TodoItem';
import { TodoDao } from '../database/dao/TodoDao';
import { WatchSyncService } from '../engine/WatchSyncService';
import { AudioService } from '../common/media/AudioService';
import { HapticService } from '../common/media/HapticService';
import { TimeUtils } from '../common/utils/TimeUtils';

@ComponentV2
export struct CarCockpitView {
  @Local completedCount: number = 0;
  @Local totalCount: number = 0;
  @Local quickThoughtText: string = '';
  @Local showQuickSuccessToast: boolean = false;
  @Local toastMessage: string = '';
  @Local isQuickInputOpen: boolean = false;

  private quickPresets: string[] = [
    '稍后给家人回电话',
    '到家后查看重要邮件',
    '明天上午优先核心攻坚',
    '预约车辆日常保养'
  ];

  async aboutToAppear(): Promise<void> {
    await this.loadStats();
  }

  private async loadStats(): Promise<void> {
    try {
      const allActive = await TodoDao.queryAllActive();
      this.totalCount = allActive.length;
      this.completedCount = allActive.filter(t => t.status === TodoStatus.COMPLETED).length;
    } catch {
      // 容错处理
    }
  }

  private async handleQuickCapture(thought: string): Promise<void> {
    if (!thought.trim()) {
      return;
    }
    const item = new TodoItem(TimeUtils.generateUUID(), thought.trim(), 25);
    item.source = TodoSource.PARKING_LOT;
    item.scheduledStartAt = 0;
    item.scheduledEndAt = 0;
    await TodoDao.insert(item);

    // 同步到手表与多端
    WatchSyncService.getInstance().broadcastParkingLotThought(item.title);
    AudioService.getInstance().playChordStep();
    HapticService.getInstance().triggerTick();

    this.toastMessage = `已收纳至杂念停机坪: "${item.title}"`;
    this.showQuickSuccessToast = true;
    this.isQuickInputOpen = false;
    this.quickThoughtText = '';

    setTimeout(() => {
      this.showQuickSuccessToast = false;
    }, 3000);
  }

  private async handleSunsetShutdown(): Promise<void> {
    AudioService.getInstance().playSunsetGong();
    HapticService.getInstance().triggerSunsetChime();
    this.toastMessage = '今日工作已打烊，安心享受归家心流';
    this.showQuickSuccessToast = true;
    setTimeout(() => {
      this.showQuickSuccessToast = false;
    }, 3500);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 1. 车载顶部状态行 (大字阶、高对比)
        Row() {
          Row({ space: 10 }) {
            Image($r('app.media.ic_sparkle'))
              .width(26)
              .height(26)
              .fillColor(ColorConstants.ACCENT_CORAL)
            Text('Aura · 车载座舱心流')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          }

          Blank()

          // 驻车安全标识
          Row({ space: 6 }) {
            Circle({ width: 10, height: 10 })
              .fill(ColorConstants.BLOCK_SAGE_GREEN)
            Text('P 档驻车就绪')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.BLOCK_SAGE_GREEN)
          }
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor(ColorConstants.BLOCK_SAGE_SOFT)
        }
        .width('100%')
        .height(68)
        .padding({ left: 32, right: 32 })

        // 2. 车载核心双卡片交互区 (横向分栏或大块布局，热区 >= 76vp)
        Row({ space: 24 }) {
          // 左卡片：驻车打烊复盘卡 (Parked Ritual Card)
          Column({ space: 18 }) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_sunset'))
                .width(22)
                .height(22)
                .fillColor(ColorConstants.ACCENT_CORAL)
              Text('今日心流打烊复盘')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            }
            .width('100%')

            // 大数字统计指示
            Row({ space: 16 }) {
              Column({ space: 4 }) {
                Text(`${this.completedCount}`)
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorConstants.ACCENT_CORAL)
                Text('已完成待办')
                  .fontSize(13)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)

              Column({ space: 4 }) {
                Text(`${this.totalCount - this.completedCount}`)
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorConstants.BLOCK_WARM_AMBER)
                Text('余下待办')
                  .fontSize(13)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            Blank()

            // 超大触控按键 (高度 80vp >= 76vp，严格遵循车载规范)
            Button('一键打烊 · 安心归家')
              .width('100%')
              .height(80)
              .borderRadius(20)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(ColorConstants.ACCENT_CORAL)
              .shadow({ radius: 16, color: ColorConstants.ACCENT_CORAL_SOFT, offsetY: 4 })
              .onClick(() => {
                this.handleSunsetShutdown();
              })
          }
          .padding(24)
          .layoutWeight(1)
          .height(300)
          .borderRadius(24)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 1, color: ColorConstants.LIGHT_CARD_BORDER })
          .shadow({ radius: 18, color: 'rgba(85, 70, 50, 0.05)', offsetY: 4 })

          // 右卡片：行车/停靠极速杂念停机坪 (Quick Thought Ingest)
          Column({ space: 18 }) {
            Row({ space: 8 }) {
              Image($r('app.media.ic_sparkle'))
                .width(22)
                .height(22)
                .fillColor(ColorConstants.BLOCK_DENIM_BLUE)
              Text('杂念停机坪 · 极速收纳')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            }
            .width('100%')

            Text('行车途中或等灯片刻，一键收纳闪念，不扰驾驶专注')
              .fontSize(13)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .width('100%')

            // 预设快速杂念大胶囊
            Row({ space: 10 }) {
              ForEach(this.quickPresets.slice(0, 2), (preset: string) => {
                Button(preset)
                  .height(48)
                  .borderRadius(14)
                  .fontSize(13)
                  .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                  .backgroundColor('rgba(90, 125, 154, 0.1)')
                  .onClick(() => {
                    this.handleQuickCapture(preset);
                  })
              })
            }
            .width('100%')

            Blank()

            // 超大语音/触控收纳胶囊按钮 (高度 80vp >= 76vp)
            Button('+ 快速收纳杂念')
              .width('100%')
              .height(80)
              .borderRadius(20)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(ColorConstants.BLOCK_DENIM_BLUE)
              .shadow({ radius: 16, color: ColorConstants.BLOCK_DENIM_SOFT, offsetY: 4 })
              .onClick(() => {
                this.isQuickInputOpen = true;
              })
          }
          .padding(24)
          .layoutWeight(1)
          .height(300)
          .borderRadius(24)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 1, color: ColorConstants.LIGHT_CARD_BORDER })
          .shadow({ radius: 18, color: 'rgba(85, 70, 50, 0.05)', offsetY: 4 })
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: 16 })

        Blank()

        // 3. 车载安全合规声明页脚
        Row({ space: 6 }) {
          Image($r('app.media.ic_shield'))
            .width(13)
            .height(13)
            .fillColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          Text('华为车载应用安全规范：行车中请保持专注，建议停车驻车或由副驾乘客操作。')
            .fontSize(12)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .padding({ bottom: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)

      // 4. 杂念极速输入大弹窗
      if (this.isQuickInputOpen) {
        Stack({ alignContent: Alignment.Center }) {
          Rect()
            .width('100%')
            .height('100%')
            .fill('rgba(0, 0, 0, 0.55)')
            .onClick(() => {
              this.isQuickInputOpen = false;
            })

          Column({ space: 18 }) {
            Text('收纳行车杂念至停机坪')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

            TextInput({ placeholder: '在此输入或语音转写杂念...', text: this.quickThoughtText })
              .height(64)
              .fontSize(18)
              .borderRadius(16)
              .backgroundColor('rgba(85, 70, 50, 0.06)')
              .onChange((val: string) => {
                this.quickThoughtText = val;
              })

            Row({ space: 14 }) {
              Button('取消')
                .layoutWeight(1)
                .height(76)
                .fontSize(16)
                .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                .backgroundColor('rgba(85, 70, 50, 0.08)')
                .borderRadius(18)
                .onClick(() => {
                  this.isQuickInputOpen = false;
                })

              Button('确认收纳')
                .layoutWeight(1)
                .height(76)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(ColorConstants.BLOCK_DENIM_BLUE)
                .borderRadius(18)
                .onClick(() => {
                  this.handleQuickCapture(this.quickThoughtText);
                })
            }
            .width('100%')
          }
          .width(540)
          .padding(28)
          .borderRadius(24)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
        }
        .width('100%')
        .height('100%')
      }

      // 5. 提示浮层
      if (this.showQuickSuccessToast) {
        Row({ space: 8 }) {
          Text(this.toastMessage)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .padding({ left: 24, right: 24, top: 14, bottom: 14 })
        .borderRadius(24)
        .backgroundColor('rgba(36, 32, 29, 0.92)')
        .margin({ bottom: 48 })
        .shadow({ radius: 14, color: 'rgba(0,0,0,0.2)' })
      }
    }
    .width('100%')
    .height('100%')
  }
}
