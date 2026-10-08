/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Hilog Unified Wrapper for Aura
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

export class Logger {
  private static readonly DOMAIN: number = 0x0001;
  private static readonly TAG: string = 'AuraFlow';

  public static debug(tag: string, format: string, ...args: Object[]): void {
    hilog.debug(Logger.DOMAIN, `${Logger.TAG}_${tag}`, format, ...args);
  }

  public static info(tag: string, format: string, ...args: Object[]): void {
    hilog.info(Logger.DOMAIN, `${Logger.TAG}_${tag}`, format, ...args);
  }

  public static warn(tag: string, format: string, ...args: Object[]): void {
    hilog.warn(Logger.DOMAIN, `${Logger.TAG}_${tag}`, format, ...args);
  }

  public static error(tag: string, format: string, ...args: Object[]): void {
    hilog.error(Logger.DOMAIN, `${Logger.TAG}_${tag}`, format, ...args);
  }
}
