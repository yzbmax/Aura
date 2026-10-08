/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Floating Deck Drawer (Structured Inbox Style with Category Badges & + Buttons)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem, TodoSource } from '../models/TodoItem';
import { getTaskVisual } from './FlowSpineAxis';
import { HapticService } from '../common/media/HapticService';

@ComponentV2
export struct FloatingDeckDrawer {
  @Param floatingItems: TodoItem[] = [];
  @Event onQuickSchedule: (item: TodoItem) => void = () => {};

  build() {
    Column({ space: 10 }) {
      // 1. 头部：参考图同款珊瑚粉 Inbox 药丸徽标
      Row({ space: 8 }) {
        Row({ space: 5 }) {
          Image($r('app.media.ic_box'))
            .width(13)
            .height(13)
            .fillColor(Color.White)

          Text('Inbox · 机动备选池')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)

          if (this.floatingItems.length > 0) {
            Text(`${this.floatingItems.length}`)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .padding({ left: 5, right: 5, top: 1, bottom: 1 })
              .borderRadius(10)
              .backgroundColor('rgba(255, 255, 255, 0.25)')
          }
        }
        .padding({ left: 10, right: 12, top: 5, bottom: 5 })
        .borderRadius(14)
        .backgroundColor(ColorConstants.ACCENT_CORAL)

        Blank()

        Text('点击 + 快速智能装箱')
          .fontSize(11)
          .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          .margin({ right: 48 })
      }
      .width('100%')

      // 2. 列表内容
      if (this.floatingItems.length === 0) {
        Row() {
          Text('机动池空空如也，所有要事均已安放')
            .fontSize(12)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 10, bottom: 10 })
      } else {
        Column({ space: 8 }) {
          ForEach(this.floatingItems, (item: TodoItem) => {
            Row({ space: 10 }) {
              // 左侧：参考图同款分类微晶色块圆斑
              Stack({ alignContent: Alignment.Center }) {
                Circle({ width: 34, height: 34 })
                  .fill(getTaskVisual(item).softColor)

                Image(getTaskVisual(item).icon)
                  .width(16)
                  .height(16)
                  .fillColor(getTaskVisual(item).color)
              }
              .width(34)
              .height(34)

              // 中间：时长微字 + 任务名称
              Column({ space: 2 }) {
                Row({ space: 4 }) {
                  Text(`${item.estimatedMinutes} min`)
                    .fontSize(11)
                    .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)

                  if (item.source === TodoSource.PARKING_LOT) {
                    Text('· 杂念秒录')
                      .fontSize(10)
                      .fontColor(ColorConstants.BLOCK_DENIM_BLUE)
                  }
                }

                Text(item.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 右侧：参考图同款极简 + 号加入排期按钮
              Button({ type: ButtonType.Circle }) {
                Text('+')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(getTaskVisual(item).color)
              }
              .width(28)
              .height(28)
              .backgroundColor(getTaskVisual(item).softColor)
              .onClick(() => {
                HapticService.getInstance().triggerClick();
                this.onQuickSchedule(item);
              })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .borderRadius(16)
            .backgroundEffect({
              radius: 20,
              saturation: 1.25,
              brightness: 1.05,
              color: 'rgba(255, 255, 255, 0.82)',
              adaptiveColor: AdaptiveColor.DEFAULT
            })
            .border({
              width: 0.8,
              color: 'rgba(255, 255, 255, 0.90)'
            })
            .shadow({ radius: 10, color: 'rgba(85, 70, 50, 0.035)', offsetY: 2 })
          })
        }
        .width('100%')
      }
    }
    .width('100%')
  }
}
