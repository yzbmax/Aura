/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Structured-Style Week Calendar & Header Bar Component
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { HapticService } from '../common/media/HapticService';

export interface CalendarDay {
  dayName: string;      // 'Mon', 'Tue', etc.
  dayNumber: number;    // 18
  isToday: boolean;     // true for current day
  timestamp: number;
  hasCoralEvent: boolean;
  hasBlueEvent: boolean;
  hasGreenEvent: boolean;
  hasAmberEvent: boolean;
}

@ComponentV2
export struct WeekCalendarBar {
  @Param selectedTimestamp: number = Date.now();
  @Param topAvoidHeight: number = 0;
  @Event onSelectDay: (timestamp: number) => void = () => {};
  @Event onOpenSettings: () => void = () => {};
  @Event onTriggerAI: () => void = () => {};

  @Local weekDays: CalendarDay[] = [];
  @Local headerDayMonthString: string = '';
  @Local headerYearString: string = '';

  @Monitor('selectedTimestamp')
  onSelectedTimestampChanged(): void {
    this.calculateWeekDays();
  }

  aboutToAppear(): void {
    this.calculateWeekDays();
  }

  private calculateWeekDays(): void {
    const now = new Date(this.selectedTimestamp);
    const dayOfWeek = (now.getDay() + 6) % 7; // 0 = Mon, 6 = Sun
    const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dayOfWeek);

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    this.headerDayMonthString = `${now.getDate()}. ${monthNames[now.getMonth()]}`;
    this.headerYearString = `${now.getFullYear()}`;

    const days: CalendarDay[] = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i);
      const isSelected = d.getDate() === now.getDate() &&
                         d.getMonth() === now.getMonth() &&
                         d.getFullYear() === now.getFullYear();

      days.push({
        dayName: dayNames[i],
        dayNumber: d.getDate(),
        isToday: isSelected,
        timestamp: d.getTime(),
        hasCoralEvent: i % 2 === 0,
        hasBlueEvent: i === 4 || i === 0,
        hasGreenEvent: true,
        hasAmberEvent: i === 4 || i === 2
      });
    }

    this.weekDays = days;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 核心内容区
      Column({ space: 10 }) {
        // 1. 顶行：参考图同款大日期标题与操作胶囊 (7. October 2025 > 样式)
        Row() {
          // 左侧：18. September 2026 › (深色日月 + 珊瑚色年份与指示箭头)
          Row({ space: 4 }) {
            Text(this.headerDayMonthString)
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

            Text(`${this.headerYearString} ›`)
              .fontSize(21)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.ACCENT_CORAL)
          }
          .alignItems(VerticalAlign.Center)

          Blank()

          // 右侧：+ AI 智能装箱胶囊 + 设置齿轮微标
          Row({ space: 8 }) {
            Button({ type: ButtonType.Capsule }) {
              Row({ space: 4 }) {
                Image($r('app.media.ic_sparkle'))
                  .width(12)
                  .height(12)
                  .fillColor(ColorConstants.ACCENT_CORAL)
                Text('AI 智排')
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorConstants.ACCENT_CORAL)
              }
              .padding({ left: 9, right: 9, top: 4, bottom: 4 })
            }
            .height(26)
            .backgroundColor('rgba(232, 122, 100, 0.12)')
            .border({ width: 0.8, color: 'rgba(232, 122, 100, 0.30)' })
            .shadow({ radius: 8, color: 'rgba(232, 122, 100, 0.10)', offsetY: 1 })
            .onClick(() => {
              HapticService.getInstance().triggerClick();
              this.onTriggerAI();
            })

            Button({ type: ButtonType.Circle }) {
              Image($r('app.media.ic_hourglass'))
                .width(14)
                .height(14)
                .fillColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            }
            .width(28)
            .height(28)
            .backgroundColor('#FFFFFF')
            .border({ width: 0.8, color: 'rgba(36, 32, 29, 0.08)' })
            .shadow({ radius: 6, color: 'rgba(40, 32, 24, 0.04)', offsetY: 1 })
            .onClick(() => {
              HapticService.getInstance().triggerClick();
              this.onOpenSettings();
            })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        // 2. 参考图 1:1 7 天水平周历滑条
        Row() {
          ForEach(this.weekDays, (day: CalendarDay) => {
            Column({ space: 4 }) {
              // 星期简写 Mon, Tue...
              Text(day.dayName)
                .fontSize(11)
                .fontWeight(day.isToday ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(day.isToday
                  ? ColorConstants.LIGHT_TEXT_PRIMARY
                  : ColorConstants.LIGHT_TEXT_TERTIARY)

              // 日期数字：当天为暖珊瑚实体极简圆球，非当天为自然纯字 (纯粹圆角，杜绝方形阴影伪影)
              Text(`${day.dayNumber}`)
                .fontSize(13)
                .fontWeight(day.isToday ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(day.isToday ? Color.White : ColorConstants.LIGHT_TEXT_PRIMARY)
                .textAlign(TextAlign.Center)
                .width(28)
                .height(28)
                .borderRadius(14)
                .backgroundColor(day.isToday ? ColorConstants.ACCENT_CORAL : Color.Transparent)
                .shadow(day.isToday ? { radius: 10, color: 'rgba(232, 122, 100, 0.35)', offsetY: 2 } : { radius: 0 })
                .border(day.isToday ? { width: 0.6, color: 'rgba(255, 255, 255, 0.85)' } : { width: 0 })

              // 日程彩色微粒点 (精简为 1~2 粒低饱和柔和点)
              Row({ space: 2.5 }) {
                if (day.hasCoralEvent) {
                  Circle().width(3).height(3).fill(ColorConstants.ACCENT_CORAL).opacity(0.85)
                }
                if (day.hasBlueEvent) {
                  Circle().width(3).height(3).fill(ColorConstants.BLOCK_DENIM_BLUE).opacity(0.85)
                } else if (day.hasGreenEvent) {
                  Circle().width(3).height(3).fill(ColorConstants.BLOCK_SAGE_GREEN).opacity(0.85)
                }
              }
              .height(4)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              HapticService.getInstance().triggerTick();
              this.onSelectDay(day.timestamp);
            })
          })
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
      }
      .width('100%')
      .padding({
        top: (this.topAvoidHeight > 0 ? this.topAvoidHeight + 6 : 10),
        bottom: 8
      })
      .zIndex(1)

      // 3. 底部边缘向内容区自然过渡的微羽化透明渐变 (消解生硬切线)
      Row()
        .width('100%')
        .height(10)
        .position({ x: 0, y: '100%' })
        .linearGradient({
          angle: 180,
          colors: [
            ['rgba(255, 254, 250, 0.40)', 0.0],
            ['rgba(255, 254, 250, 0.0)', 1.0]
          ]
        })
        .hitTestBehavior(HitTestMode.None)
        .zIndex(3)
    }
    .width('100%')
    .backgroundEffect({
      radius: 24,
      saturation: 1.25,
      brightness: 1.04,
      color: 'rgba(255, 254, 250, 0.48)',
      adaptiveColor: AdaptiveColor.AVERAGE
    })
    .linearGradient({
      angle: 180,
      colors: [
        ['rgba(255, 255, 255, 0.42)', 0.0],
        ['rgba(255, 255, 255, 0.30)', 0.65],
        ['rgba(255, 255, 255, 0.08)', 0.88],
        ['rgba(255, 255, 255, 0.0)', 1.0]
      ]
    })
    .shadow({
      radius: 16,
      color: 'rgba(85, 70, 50, 0.03)',
      offsetY: 4
    })
  }
}
