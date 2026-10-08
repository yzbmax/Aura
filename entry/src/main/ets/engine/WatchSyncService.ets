/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Distributed Watch Sync Service (Watch-to-Phone Sync via distributedDataObject)
 */

import { distributedDataObject } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { FocusSyncState, SyncAction } from '../models/WatchSyncModel';
import { TodoItem, TimingMode } from '../models/TodoItem';
import { Logger } from '../common/utils/Logger';

interface SyncDataObject extends distributedDataObject.DataObject {
  taskId?: string;
  taskTitle?: string;
  timingMode?: number;
  totalMinutes?: number;
  elapsedSeconds?: number;
  isRunning?: boolean;
  action?: SyncAction;
  parkingLotText?: string;
  timestamp?: number;
}

export class WatchSyncService {
  private static instance: WatchSyncService | null = null;
  private syncObject: distributedDataObject.DataObject | null = null;
  private currentState: FocusSyncState = {
    sessionId: 'aura_focus_sync_session',
    taskId: '',
    taskTitle: '',
    timingMode: 0,
    totalMinutes: 25,
    elapsedSeconds: 0,
    isRunning: false,
    action: SyncAction.IDLE,
    parkingLotText: '',
    timestamp: Date.now()
  };

  private listeners: ((state: FocusSyncState) => void)[] = [];
  private parkingLotListeners: ((text: string) => void)[] = [];

  private constructor() {}

  public static getInstance(): WatchSyncService {
    if (!WatchSyncService.instance) {
      WatchSyncService.instance = new WatchSyncService();
    }
    return WatchSyncService.instance;
  }

  /**
   * 初始化分布式数据对象协同通道
   */
  public async init(context: common.Context): Promise<void> {
    try {
      this.syncObject = distributedDataObject.create(context, this.currentState);
      await this.syncObject.setSessionId('aura_focus_sync_session');
      this.syncObject.on('change', (sessionId: string, fields: Array<string>) => {
        Logger.info('WatchSyncService', 'Distributed object changed in session %{public}s: %{public}s', sessionId, fields.join(','));
        this.notifyStateChanged();
      });
      Logger.info('WatchSyncService', 'WatchSyncService initialized with session aura_focus_sync_session');
    } catch (err) {
      Logger.warn('WatchSyncService', 'Failed to initialize distributedDataObject (fallback to local state): %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 注册心流状态变更监听器
   */
  public subscribeState(listener: (state: FocusSyncState) => void): void {
    this.listeners.push(listener);
    listener(this.currentState);
  }

  /**
   * 取消注册
   */
  public unsubscribeState(listener: (state: FocusSyncState) => void): void {
    this.listeners = this.listeners.filter(l => l !== listener);
  }

  /**
   * 注册抬腕闪念接收监听器
   */
  public subscribeParkingLot(listener: (text: string) => void): void {
    this.parkingLotListeners.push(listener);
  }

  /**
   * 取消注册闪念监听器
   */
  public unsubscribeParkingLot(listener: (text: string) => void): void {
    this.parkingLotListeners = this.parkingLotListeners.filter(l => l !== listener);
  }

  /**
   * 手机端发起：专注开始
   */
  public syncFocusStart(item: TodoItem): void {
    this.updateState({
      taskId: item.id,
      taskTitle: item.title,
      timingMode: item.timingMode,
      totalMinutes: item.estimatedMinutes > 0 ? item.estimatedMinutes : 25,
      elapsedSeconds: 0,
      isRunning: true,
      action: SyncAction.START,
      parkingLotText: ''
    });
  }

  /**
   * 定时器心跳同步
   */
  public syncFocusTick(elapsedSeconds: number): void {
    this.updateState({
      elapsedSeconds: elapsedSeconds,
      action: SyncAction.TICK
    });
  }

  /**
   * 暂停专注
   */
  public syncFocusPause(): void {
    this.updateState({
      isRunning: false,
      action: SyncAction.PAUSE
    });
  }

  /**
   * 恢复专注
   */
  public syncFocusResume(): void {
    this.updateState({
      isRunning: true,
      action: SyncAction.RESUME
    });
  }

  /**
   * 完成专注
   */
  public syncFocusComplete(): void {
    this.updateState({
      isRunning: false,
      action: SyncAction.COMPLETE
    });
  }

  /**
   * 终止/退出专注
   */
  public syncFocusStop(): void {
    this.updateState({
      isRunning: false,
      action: SyncAction.STOP
    });
  }

  /**
   * 手表端/手机端发送闪念停机坪
   */
  public sendParkingLot(text: string): void {
    this.updateState({
      parkingLotText: text,
      action: SyncAction.PARKING_LOT
    });
    for (const l of this.parkingLotListeners) {
      l(text);
    }
  }

  /**
   * 广播杂念停机坪（车载/手表/多端通用）
   */
  public broadcastParkingLotThought(text: string): void {
    this.sendParkingLot(text);
  }

  /**
   * 获取当前心流快照
   */
  public getCurrentState(): FocusSyncState {
    return this.currentState;
  }

  private updateState(partial: Partial<FocusSyncState>): void {
    this.currentState = {
      sessionId: this.currentState.sessionId,
      taskId: partial.taskId !== undefined ? partial.taskId : this.currentState.taskId,
      taskTitle: partial.taskTitle !== undefined ? partial.taskTitle : this.currentState.taskTitle,
      timingMode: partial.timingMode !== undefined ? partial.timingMode : this.currentState.timingMode,
      totalMinutes: partial.totalMinutes !== undefined ? partial.totalMinutes : this.currentState.totalMinutes,
      elapsedSeconds: partial.elapsedSeconds !== undefined ? partial.elapsedSeconds : this.currentState.elapsedSeconds,
      isRunning: partial.isRunning !== undefined ? partial.isRunning : this.currentState.isRunning,
      action: partial.action !== undefined ? partial.action : this.currentState.action,
      parkingLotText: partial.parkingLotText !== undefined ? partial.parkingLotText : this.currentState.parkingLotText,
      timestamp: Date.now()
    };

    if (this.syncObject) {
      try {
        const obj = this.syncObject as SyncDataObject;
        obj.taskId = this.currentState.taskId;
        obj.taskTitle = this.currentState.taskTitle;
        obj.timingMode = this.currentState.timingMode;
        obj.totalMinutes = this.currentState.totalMinutes;
        obj.elapsedSeconds = this.currentState.elapsedSeconds;
        obj.isRunning = this.currentState.isRunning;
        obj.action = this.currentState.action;
        obj.parkingLotText = this.currentState.parkingLotText;
        obj.timestamp = this.currentState.timestamp;
      } catch (err) {
        Logger.debug('WatchSyncService', 'Error setting distributedDataObject fields: %{public}s', JSON.stringify(err));
      }
    }

    this.notifyStateChanged();
  }

  private notifyStateChanged(): void {
    for (const l of this.listeners) {
      l(this.currentState);
    }
  }
}
