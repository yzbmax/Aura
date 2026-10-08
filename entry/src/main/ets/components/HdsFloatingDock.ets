/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * HDS Floating Dock: Spatial Halo Glass Dock (Huawei HDS 6.0 & visionOS Style)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { HapticService } from '../common/media/HapticService';

interface DockTabItem {
  name: string;
  icon: Resource;
}

@ComponentV2
export struct HdsFloatingDock {
  @Param selectedIndex: number = 0;
  @Event onTabChange: (index: number) => void = () => {};

  // 华为官方 HDS 底部悬浮页签标准尺寸：3 Tab 宽度为 76 * 3 + 8 = 236vp
  private readonly dockWidth: number = 236;
  private readonly dockHeight: number = 56;

  private readonly tabs: DockTabItem[] = [
    { name: '今日心流', icon: $r('app.media.ic_bolt') },
    { name: '任务视界', icon: $r('app.media.ic_box') },
    { name: '偏好设置', icon: $r('app.media.ic_gear') }
  ];

  // 单个 Tab 分区宽度为 76vp
  private getTabWidth(): number {
    return (this.dockWidth - 8) / 3; // 76vp
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      // 1. 顶部液态玻璃镜面折射光弧（1.5vp 高光微线）
      Row()
        .width('82%')
        .height(1.5)
        .position({ x: '9%', y: 1 })
        .linearGradient({
          angle: 90,
          colors: [
            ['rgba(255, 255, 255, 0)', 0.0],
            ['rgba(255, 255, 255, 0.95)', 0.5],
            ['rgba(255, 255, 255, 0)', 1.0]
          ]
        })
        .zIndex(1)

      // 2. 空间微晶柔暖珊瑚光晕滑块 (Luminous Halo: 柔和暖珊瑚沉浸光感，绝无生硬边框)
      Row()
        .width(68)
        .height(46)
        .borderRadius(23)
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(232, 122, 100, 0.16)', 0.0],
            ['rgba(232, 122, 100, 0.04)', 1.0]
          ]
        })
        .shadow({
          radius: 12,
          color: 'rgba(232, 122, 100, 0.20)',
          offsetY: 0
        })
        .position({
          x: 4 + this.selectedIndex * this.getTabWidth() + (this.getTabWidth() - 68) / 2,
          y: 5
        })
        .animation({
          curve: CurveConstants.SPRING_LIQUID_SNAP,
          duration: 280
        })
        .zIndex(2)

      // 3. 上下纵向图文排布（20vp 细线矢量微标 + 10vp 呼吸字标）
      Row() {
        ForEach(this.tabs, (tab: DockTabItem, index: number) => {
          Column({ space: 2 }) {
            Image(tab.icon)
              .width(20)
              .height(20)
              .fillColor(this.selectedIndex === index
                ? ColorConstants.ACCENT_CORAL
                : ColorConstants.LIGHT_TEXT_TERTIARY)
              .scale(this.selectedIndex === index
                ? { x: 1.05, y: 1.05 }
                : { x: 1.0, y: 1.0 })
              .animation({ duration: 220 })

            Text(tab.name)
              .fontSize(10)
              .fontWeight(this.selectedIndex === index ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.selectedIndex === index
                ? ColorConstants.ACCENT_CORAL
                : ColorConstants.LIGHT_TEXT_TERTIARY)
              .letterSpacing(0.2)
              .animation({ duration: 220 })
          }
          .layoutWeight(1)
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.selectedIndex !== index) {
              HapticService.getInstance().triggerTick();
              this.onTabChange(index);
            }
          })
        })
      }
      .width('100%')
      .height('100%')
      .zIndex(3)
    }
    .width(this.dockWidth)
    .height(this.dockHeight)
    .borderRadius(this.dockHeight / 2)
    // 华为沉浸光感：暖色高透光学模糊与高饱和色彩还原
    .backgroundEffect({
      radius: 28,
      saturation: 1.5,
      brightness: 1.06,
      color: 'rgba(255, 254, 250, 0.76)',
      adaptiveColor: AdaptiveColor.AVERAGE
    })
    // 物理液态玻璃外切高光边缘 (0.8vp 微晶微描边)
    .border({
      width: 0.8,
      color: 'rgba(255, 255, 255, 0.92)'
    })
    // 空间级双层弥散温暖环境光晕阴影
    .shadow({
      radius: 24,
      color: 'rgba(85, 70, 50, 0.08)',
      offsetY: 8
    })
    .renderGroup(true)
  }
}
