/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Distributed Watch Sync Data Contract & Session Model
 */

export enum SyncAction {
  IDLE = 'IDLE',
  START = 'START',
  PAUSE = 'PAUSE',
  RESUME = 'RESUME',
  TICK = 'TICK',
  COMPLETE = 'COMPLETE',
  STOP = 'STOP',
  PARKING_LOT = 'PARKING_LOT'
}

export interface FocusSyncState {
  sessionId: string;
  taskId: string;
  taskTitle: string;
  timingMode: number;
  totalMinutes: number;
  elapsedSeconds: number;
  isRunning: boolean;
  action: SyncAction;
  parkingLotText: string;
  timestamp: number;
}
