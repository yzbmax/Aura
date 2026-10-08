/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Live View Service: HarmonyOS NEXT Live View (实况窗) Capsule & Lockscreen Card
 */

import { notificationManager } from '@kit.NotificationKit';
import { TodoItem } from '../models/TodoItem';
import { Logger } from '../common/utils/Logger';

export class LiveViewService {
  private static instance: LiveViewService | null = null;
  private readonly NOTIFICATION_ID: number = 1001;
  private isLiveViewActive: boolean = false;

  private constructor() {}

  public static getInstance(): LiveViewService {
    if (!LiveViewService.instance) {
      LiveViewService.instance = new LiveViewService();
    }
    return LiveViewService.instance;
  }

  /**
   * 启动实况窗 (在状态栏展示胶囊态，并在通知中心/锁屏展示大卡片)
   */
  public async startLiveView(item: TodoItem, totalSeconds: number): Promise<void> {
    try {
      // 检查或请求通知权限容错
      const isEnabled = await notificationManager.isNotificationEnabled();
      if (!isEnabled) {
        Logger.warn('LiveViewService', 'Notification is not enabled by user, live view degraded gracefully.');
        return;
      }

      const mm = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
      const ss = (totalSeconds % 60).toString().padStart(2, '0');
      const timeStr = `${mm}:${ss}`;

      const request: notificationManager.NotificationRequest = {
        id: this.NOTIFICATION_ID,
        notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
          systemLiveView: {
            title: item.title,
            text: timeStr,
            typeCode: 8,
            capsule: {
              title: timeStr,
              backgroundColor: '#E87A64'
            }
          }
        },
        badgeNumber: 1
      };

      await notificationManager.publish(request);
      this.isLiveViewActive = true;
      Logger.info('LiveViewService', 'Live View started successfully for: %{public}s', item.title);
    } catch (err) {
      Logger.warn('LiveViewService', 'Failed to start Live View: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 倒计时或状态变更时高频/定频刷新实况窗
   */
  public async updateLiveView(item: TodoItem, remainingSeconds: number, isRunning: boolean): Promise<void> {
    if (!this.isLiveViewActive) {
      return;
    }

    try {
      const mm = Math.floor(remainingSeconds / 60).toString().padStart(2, '0');
      const ss = (remainingSeconds % 60).toString().padStart(2, '0');
      const timeStr = `${mm}:${ss}`;

      const request: notificationManager.NotificationRequest = {
        id: this.NOTIFICATION_ID,
        notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
          systemLiveView: {
            title: item.title,
            text: isRunning ? `专注中: ${timeStr}` : `已暂停: ${timeStr}`,
            typeCode: 8,
            capsule: {
              title: isRunning ? timeStr : `暂停 ${timeStr}`,
              backgroundColor: isRunning ? '#E87A64' : '#D69A56'
            }
          }
        }
      };

      await notificationManager.publish(request);
    } catch (err) {
      Logger.warn('LiveViewService', 'Failed to update Live View: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 停止并清理实况窗
   */
  public async stopLiveView(): Promise<void> {
    if (!this.isLiveViewActive) {
      return;
    }
    try {
      await notificationManager.cancel(this.NOTIFICATION_ID);
      this.isLiveViewActive = false;
      Logger.info('LiveViewService', 'Live View canceled and cleaned.');
    } catch (err) {
      Logger.warn('LiveViewService', 'Failed to cancel Live View: %{public}s', JSON.stringify(err));
    }
  }
}
