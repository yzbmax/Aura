/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Design Tokens for Aura · Circadian Dual-Theme Palette (WCAG AA Compliant)
 */

export class ColorConstants {
  // === 暗夜深空调色盘 (Dark Mode) ===
  public static readonly DARK_BG_DEEP: string = '#0E1015';
  public static readonly DARK_BG_CANVAS: string = '#131620';
  public static readonly DARK_BG_SUNSET: string = '#151322';
  public static readonly DARK_DAWN_CYAN: string = '#70A9A1';
  public static readonly DARK_FLOW_VIOLET: string = '#9D8DF1';
  public static readonly DARK_FLOW_VIOLET_DEEP: string = '#6C5CE7';
  public static readonly DARK_REST_SAGE: string = '#95B8A2';
  public static readonly DARK_FROST_BLUE: string = '#8FA2B0';
  public static readonly DARK_CARD_BG: string = 'rgba(255, 255, 255, 0.05)';
  public static readonly DARK_CARD_BORDER: string = 'rgba(255, 255, 255, 0.12)';
  public static readonly DARK_TEXT_PRIMARY: string = 'rgba(255, 255, 255, 0.95)';
  public static readonly DARK_TEXT_SECONDARY: string = 'rgba(255, 255, 255, 0.65)';
  public static readonly DARK_TEXT_TERTIARY: string = 'rgba(255, 255, 255, 0.45)';

  // === 方案 A：自然原木与柔和珊瑚陶土微晶调色盘 (Option A: Natural Earth & Terracotta Coral) ===
  public static readonly LIGHT_BG_CANVAS: string = '#F7F5F0'; // 典雅温暖的燕麦米色画布 (Warm Oat Beige)
  public static readonly LIGHT_BG_SUNSET: string = '#EDE7E0'; // 暮光暖米
  public static readonly LIGHT_CARD_BG: string = '#FFFFFF'; // 暖白羊脂玉微晶卡片底色
  public static readonly LIGHT_CARD_BORDER: string = 'rgba(85, 70, 50, 0.07)'; // 极柔和的暖棕自然晕染边界

  // 核心行动主色（全面取代原有的心流紫）
  public static readonly ACCENT_CORAL: string = '#E87A64'; // 柔和珊瑚陶土红（主行动色/底栏激活/FAB/晨间）
  public static readonly ACCENT_CORAL_LIGHT: string = '#F48E7A'; // 珊瑚柔和高光
  public static readonly ACCENT_CORAL_SOFT: string = 'rgba(232, 122, 100, 0.12)'; // 珊瑚微膜光晕

  // 参考图同款：多色低饱和任务大色块系统
  public static readonly BLOCK_DENIM_BLUE: string = '#5A7D9A'; // 静谧牛仔灰蓝（深度编码/核心攻坚）
  public static readonly BLOCK_DENIM_SOFT: string = 'rgba(90, 125, 154, 0.12)';
  public static readonly BLOCK_SAGE_GREEN: string = '#628A61'; // 草木牛油果绿（留白/运动/茶歇/健康）
  public static readonly BLOCK_SAGE_SOFT: string = 'rgba(98, 138, 97, 0.12)';
  public static readonly BLOCK_WARM_AMBER: string = '#D69A56'; // 暖沙黄/陶土琥珀（会议/沟通/打卡）
  public static readonly BLOCK_WARM_AMBER_SOFT: string = 'rgba(214, 154, 86, 0.12)';

  // 兼容重定向映射（确保无缝切换，彻底告别紫色）
  public static readonly LIGHT_FLOW_VIOLET: string = '#E87A64'; // 映射为珊瑚陶土红
  public static readonly LIGHT_FLOW_VIOLET_SOFT: string = '#F48E7A';
  public static readonly LIGHT_DAWN_CYAN: string = '#5A7D9A';
  public static readonly LIGHT_REST_SAGE: string = '#628A61';
  public static readonly LIGHT_FROST_BLUE: string = '#647A8A';

  // 暖浓缩咖啡柔和字阶 (Soft Espresso & Heather) - 符合视觉极简与护眼原则
  public static readonly LIGHT_TEXT_PRIMARY: string = '#38322D'; // 柔和深焙暖灰 (告别死黑，温润耐看)
  public static readonly LIGHT_TEXT_SECONDARY: string = '#686058'; // 雅致亚麻褐 (柔和次级引导)
  public static readonly LIGHT_TEXT_TERTIARY: string = '#8E857C'; // 轻盈透气烟灰 (弱化元数据与时间刻度)

  // 状态与完成徽标
  public static readonly ACCENT_COMPLETED: string = '#628A61'; // 完成打卡绿
  public static readonly AGING_MILD_AMBER: string = '#D69A56'; // 4~7天秋叶黄
  public static readonly FROZEN_CRYSTAL: string = '#6E8B9E'; // 8+天冷冻舱冰晶蓝
}
