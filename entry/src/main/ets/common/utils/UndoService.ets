/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Global Undo Manager for Non-Destructive Actions (5s Window)
 */

@ObservedV2
export class UndoService {
  private static instance: UndoService | null = null;

  @Trace public isVisible: boolean = false;
  @Trace public message: string = '';

  private undoAction: (() => Promise<void>) | null = null;
  private timerId: number = -1;

  private constructor() {}

  public static getInstance(): UndoService {
    if (!UndoService.instance) {
      UndoService.instance = new UndoService();
    }
    return UndoService.instance;
  }

  /**
   * 触发 5 秒非侵入式撤销浮窗
   */
  public showUndo(message: string, action: () => Promise<void>, durationMs: number = 5000): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }

    this.message = message;
    this.undoAction = action;
    this.isVisible = true;

    this.timerId = setTimeout(() => {
      this.dismiss();
    }, durationMs);
  }

  /**
   * 执行撤销
   */
  public async executeUndo(): Promise<void> {
    if (this.undoAction) {
      const act = this.undoAction;
      this.dismiss();
      await act();
    } else {
      this.dismiss();
    }
  }

  /**
   * 隐藏浮窗
   */
  public dismiss(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    this.isVisible = false;
    this.undoAction = null;
  }
}
