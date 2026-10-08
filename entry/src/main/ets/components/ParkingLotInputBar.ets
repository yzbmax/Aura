/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * The Parking Lot: Rapid Ingestion Collapsible Micro-Capsule
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { HapticService } from '../common/media/HapticService';
import { promptAction } from '@kit.ArkUI';

@ComponentV2
export struct ParkingLotInputBar {
  @Event onParkingSubmit: (text: string) => void = () => {};

  @Local inputText: string = '';
  @Local isExpanded: boolean = false;
  @Local isIngesting: boolean = false;

  build() {
    if (!this.isExpanded) {
      // 1. 平时态：极简折叠微晶胶囊 (36vp 呼吸胶囊、低视觉压迫、柔和呼吸感)
      Row({ space: 8 }) {
        Image($r('app.media.ic_sparkle'))
          .width(14)
          .height(14)
          .fillColor(ColorConstants.ACCENT_CORAL)

        Text('记下此刻杂念，稍后处理...')
          .fontSize(13)
          .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
      }
      .width('100%')
      .height(36)
      .padding({ left: 14, right: 14 })
      .borderRadius(18)
      .backgroundColor('rgba(85, 70, 50, 0.04)')
      .border({ width: 0.5, color: 'rgba(85, 70, 50, 0.08)' })
      .onClick(() => {
        animateTo({ duration: 220, curve: Curve.FastOutSlowIn }, () => {
          this.isExpanded = true;
        });
        HapticService.getInstance().triggerTick();
      })
    } else {
      // 2. 展开态：聚焦录入微晶条 (输入即存、存毕自退、零夺焦)
      Row({ space: 8 }) {
        Image($r('app.media.ic_sparkle'))
          .width(14)
          .height(14)
          .fillColor(ColorConstants.ACCENT_CORAL)

        TextInput({
          placeholder: '记下此刻杂念，稍后处理...',
          text: this.inputText
        })
          .placeholderColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(38)
          .defaultFocus(true)
          .onChange((val: string) => {
            this.inputText = val;
          })
          .onSubmit(() => {
            const content = this.inputText.trim();
            if (content.length > 0) {
              this.handleIngest(content);
            }
          })

        if (this.inputText.trim().length > 0) {
          Button({ type: ButtonType.Capsule }) {
            Text('停泊')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .backgroundColor(ColorConstants.ACCENT_CORAL)
          .height(26)
          .onClick(() => {
            this.handleIngest(this.inputText.trim());
          })
        }

        // 收起按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_close'))
            .width(10)
            .height(10)
            .fillColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .width(26)
        .height(26)
        .backgroundColor('rgba(85, 70, 50, 0.05)')
        .onClick(() => {
          animateTo({ duration: 200, curve: Curve.FastOutSlowIn }, () => {
            this.isExpanded = false;
            this.inputText = '';
          });
          HapticService.getInstance().triggerTick();
        })
      }
      .width('100%')
      .height(44)
      .padding({ left: 14, right: 10 })
      .borderRadius(22)
      .backgroundColor(ColorConstants.LIGHT_CARD_BG)
      .border({ width: 0.8, color: ColorConstants.ACCENT_CORAL })
      .shadow({ radius: 14, color: 'rgba(232, 122, 100, 0.12)', offsetY: 2 })
    }
  }

  private handleIngest(content: string): void {
    this.isIngesting = true;
    HapticService.getInstance().triggerTick();

    setTimeout(() => {
      this.onParkingSubmit(content);
      this.inputText = '';
      this.isIngesting = false;
      animateTo({ duration: 200, curve: Curve.FastOutSlowIn }, () => {
        this.isExpanded = false;
      });
      try {
        promptAction.showToast({
          message: '已停泊入机动序列，当前心流不受打扰',
          duration: 1500
        });
      } catch {
        // 容错
      }
    }, 180);
  }
}
