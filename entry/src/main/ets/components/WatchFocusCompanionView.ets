/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Wearable Companion View: 466x466 Round Dial Focus Companion for HUAWEI WATCH
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { HapticService } from '../common/media/HapticService';
import { WatchSyncService } from '../engine/WatchSyncService';
import { FocusSyncState, SyncAction } from '../models/WatchSyncModel';

@ComponentV2
export struct WatchFocusCompanionView {
  @Local syncState: FocusSyncState = WatchSyncService.getInstance().getCurrentState();
  @Local isParkingOpen: boolean = false;
  @Local parkingText: string = '';

  private stateListener = (state: FocusSyncState): void => {
    this.syncState = state;
  };

  aboutToAppear(): void {
    WatchSyncService.getInstance().subscribeState(this.stateListener);
  }

  aboutToDisappear(): void {
    WatchSyncService.getInstance().unsubscribeState(this.stateListener);
  }

  private get progressPercent(): number {
    const totalSec = Math.max(60, this.syncState.totalMinutes * 60);
    return Math.min(100, Math.round((this.syncState.elapsedSeconds / totalSec) * 100));
  }

  private get formattedTime(): string {
    const totalSec = Math.max(60, this.syncState.totalMinutes * 60);
    const remSec = Math.max(0, totalSec - this.syncState.elapsedSeconds);
    const m = Math.floor(remSec / 60).toString().padStart(2, '0');
    const s = (remSec % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 1. 手表圆形背景底盘 (466x466 纯净暗夜)
      Circle({ width: '100%', height: '100%' })
        .fill(ColorConstants.DARK_BG_DEEP)

      // 2. 环形流体沙漏进度圈 (Progress Ring)
      Progress({
        value: this.progressPercent,
        total: 100,
        type: ProgressType.Ring
      })
        .color(ColorConstants.ACCENT_CORAL)
        .style({ strokeWidth: 8, enableSmoothEffect: true })
        .width('92%')
        .height('92%')

      // 3. 表盘核心内容排版
      Column({ space: 8 }) {
        // 顶部抬腕闪念微胶囊按钮
        Row({ space: 4 }) {
          Image($r('app.media.ic_anchor'))
            .width(10)
            .height(10)
            .fillColor(ColorConstants.DARK_TEXT_SECONDARY)
          Text('杂念停泊')
            .fontSize(10)
            .fontColor(ColorConstants.DARK_TEXT_SECONDARY)
        }
        .backgroundColor('rgba(255, 255, 255, 0.08)')
        .height(24)
        .borderRadius(12)
        .padding({ left: 10, right: 10 })
        .onClick(() => {
          HapticService.getInstance().triggerTick();
          this.isParkingOpen = !this.isParkingOpen;
        })

        if (this.isParkingOpen) {
          // 简易快捷杂念输入
          Row({ space: 4 }) {
            TextInput({ placeholder: '杂念...', text: this.parkingText })
              .fontSize(11)
              .height(28)
              .fontColor(Color.White)
              .backgroundColor('rgba(255, 255, 255, 0.12)')
              .layoutWeight(1)
              .onChange((val: string) => {
                this.parkingText = val;
              })
              .onSubmit(() => {
                if (this.parkingText.trim().length > 0) {
                  WatchSyncService.getInstance().sendParkingLot(this.parkingText.trim());
                  this.parkingText = '';
                  this.isParkingOpen = false;
                  HapticService.getInstance().triggerTick();
                }
              })
          }
          .width('75%')
        }

        // 当前任务名称
        Text(this.syncState.taskTitle || '今日心流伴随')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 20, right: 20 })
          .textAlign(TextAlign.Center)

        // 倒计时时间
        Text(this.formattedTime)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConstants.ACCENT_CORAL)

        // 底部双微胶囊控制按键
        Row({ space: 12 }) {
          // 暂停/继续
          Row({ space: 5 }) {
            Image(this.syncState.isRunning ? $r('app.media.ic_pause') : $r('app.media.ic_bolt'))
              .width(11)
              .height(11)
              .fillColor(Color.White)
            Text(this.syncState.isRunning ? '暂停' : '继续')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .backgroundColor('rgba(255, 255, 255, 0.14)')
          .height(30)
          .borderRadius(15)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            HapticService.getInstance().triggerClick();
            if (this.syncState.isRunning) {
              WatchSyncService.getInstance().syncFocusPause();
            } else {
              WatchSyncService.getInstance().syncFocusResume();
            }
          })

          // 完成打勾
          Row({ space: 5 }) {
            Image($r('app.media.ic_check'))
              .width(11)
              .height(11)
              .fillColor(Color.White)
            Text('完成')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .linearGradient({
            angle: 135,
            colors: [['#628A61', 0.0], ['#4E724D', 1.0]]
          })
          .height(30)
          .borderRadius(15)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            HapticService.getInstance().triggerClick();
            WatchSyncService.getInstance().syncFocusComplete();
          })
        }
        .margin({ top: 4 })
      }
      .width('85%')
      .alignItems(HorizontalAlign.Center)
    }
    .width(360)
    .height(360)
    .borderRadius(180)
    .clip(true)
  }
}
