/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Fluid Damper Spring & Physics Curves for Aura Animation
 */

import { curves } from '@kit.ArkUI';

export class CurveConstants {
  /**
   * 核心展开/闭合：温润拉开水膜感（开合雾化核心）
   */
  public static readonly SPRING_MIST_OPEN = curves.springMotion(0.48, 0.84);

  /**
   * 触碰按下微回弹：紧致微晶轻触感
   */
  public static readonly SPRING_TOUCH_BOUNCE = curves.responsiveSpringMotion(0.28, 0.72);

  /**
   * 水滴拖拽拉伸流体阻尼响应
   */
  public static readonly SPRING_LIQUID_STRETCH = curves.responsiveSpringMotion(0.22, 0.68);

  /**
   * 水滴表面张力微震荡回弹归位
   */
  public static readonly SPRING_LIQUID_SNAP = curves.springMotion(0.28, 0.58);

  /**
   * 微晶操作底板与抽屉弹性升起阻尼
   */
  public static readonly SPRING_BOTTOM_SHEET = curves.springMotion(0.42, 0.85);

  /**
   * 模态弹窗与悬浮卡片弹性弹出动效（带温润微过冲物理弹簧触感）
   */
  public static readonly SPRING_MODAL_POP = curves.springMotion(0.38, 0.72);

  /**
   * 全局撤销胶囊底部弹性涌出
   */
  public static readonly SPRING_UNDO_BOUNCE = curves.springMotion(0.35, 0.75);

  /**
   * 打勾流体吸缩与矢量弹出
   */
  public static readonly SPRING_CHECK_MORPH = curves.springMotion(0.26, 0.62);

  /**
   * 连胜静息护盾舒展展开
   */
  public static readonly SPRING_REVIVAL_EXPAND = curves.springMotion(0.52, 0.82);

  /**
   * 杂念吸入消融曲线：轻盈向上收缩
   */
  public static readonly CURVE_MIST_DISSOLVE = curves.cubicBezierCurve(0.25, 1.0, 0.5, 1.0);

  /**
   * 杂念轻烟消融曲线
   */
  public static readonly CURVE_MIST_SMOKE = curves.cubicBezierCurve(0.2, 0.8, 0.2, 1.0);

  /**
   * 0.8Hz 留白慢节律呼吸光晕
   */
  public static readonly CURVE_BREATHING = curves.cubicBezierCurve(0.4, 0.0, 0.2, 1.0);

  /**
   * 纸牌堆叠流：顶层飞牌飞出消融曲线 (高爆发弹簧，260ms 内利落飞离)
   */
  public static readonly SPRING_CARD_FLYOUT = curves.springMotion(0.30, 0.82);

  /**
   * 纸牌堆叠流：次层有力超调弹射就位曲线 (8.4% 弹性过冲，340ms 紧致收敛)
   */
  public static readonly SPRING_CARD_SNAP_FOCUS = curves.springMotion(0.34, 0.62);

  /**
   * 纸牌堆叠流：未达阈值高回弹磁吸归位曲线 (紧凑阻尼，无滞后)
   */
  public static readonly SPRING_CARD_CANCEL_RESET = curves.springMotion(0.28, 0.76);
}
