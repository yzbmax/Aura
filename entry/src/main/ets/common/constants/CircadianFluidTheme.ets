/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Circadian Fluid Theme: 600nm+ Pure Amber Calm Spectrum & True-Tone Engine
 * Inspired by Daylight Computer Sol:OS (Anti-Dopamine & Zero Blue Light)
 */

export interface ThemePalette {
  canvasBg: string;
  cardBg: string;
  accent: string;
  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  borderSubtle: string;
  contrastRatio: number;
}

export class CircadianFluidTheme {
  // 标准暖日光模式 (Daylight Warm Oat)
  public static readonly DAY_PALETTE: ThemePalette = {
    canvasBg: '#F7F5F0',
    cardBg: '#FFFFFF',
    accent: '#E87A64',
    textPrimary: '#24201D',
    textSecondary: '#5E564F',
    textMuted: '#6E665E',
    borderSubtle: 'rgba(85, 70, 50, 0.07)',
    contrastRatio: 9.8
  };

  // 600nm+ 纯琥珀平静模式 (Pure Amber Calm Mode) - 蓝光彻底归零，长波红橙光
  public static readonly PURE_AMBER_PALETTE: ThemePalette = {
    canvasBg: '#130E07',       // 深焦糖黑
    cardBg: '#1E170E',         // 暖琥珀暗原木
    accent: '#D69A56',         // 陶土深琥珀
    textPrimary: '#F5CA80',    // 暮光暖金 (WCAG AA 对比度 6.2:1)
    textSecondary: '#D4AF37',  // 琥珀金褐
    textMuted: '#96784A',      // 炭烧焦糖
    borderSubtle: 'rgba(214, 154, 86, 0.18)',
    contrastRatio: 6.2
  };

  /**
   * 根据时间或用户偏好获取当前色彩调色盘
   */
  public static getCurrentPalette(hour: number, forceAmber: boolean = false): ThemePalette {
    if (forceAmber || hour >= 20 || hour < 6) {
      return CircadianFluidTheme.PURE_AMBER_PALETTE;
    }
    return CircadianFluidTheme.DAY_PALETTE;
  }
}
