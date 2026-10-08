/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * First-Launch Privacy Policy & Terms Compliance Modal (Huawei AppGallery Standard)
 */

import { ColorConstants } from '../common/constants/ColorConstants';

@ComponentV2
export struct PrivacyDialog {
  @Param isVisible: boolean = false;
  @Event onAgree: () => void = () => {};
  @Event onDisagree: () => void = () => {};

  build() {
    if (this.isVisible) {
      Stack() {
        // 半透明深色蒙层
        Rect()
          .width('100%')
          .height('100%')
          .fill('rgba(0, 0, 0, 0.45)')

        // 弹窗卡片本体
        Column({ space: 14 }) {
          Row({ space: 8 }) {
            Image($r('app.media.ic_shield'))
              .width(20)
              .height(20)
              .fillColor(ColorConstants.LIGHT_DAWN_CYAN)
            Text('用户协议与隐私保护提示')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          }
          .width('100%')

          Scroll() {
            Column({ space: 10 }) {
              Text('感谢您使用「Aura · 同频」！我们高度重视您的个人信息与隐私安全。')
                .fontSize(13)
                .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
                .lineHeight(20)

              Text('1. 本地优先 (Local-First)：待办、时间块、杂念停机坪记录均持久化存储于您的设备本地 SQLite 中，无需联网亦可完整运行。')
                .fontSize(12)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                .lineHeight(18)

              Text('2. 权限说明：当您使用解压触感与和弦音效时，应用将调用系统微触感与音频接口；保存打烊成就卡使用系统安全控件 SaveButton，免除相册敏感权限。')
                .fontSize(12)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                .lineHeight(18)

              Text('3. 随时撤回：您可随时在「偏好与设置」中查阅个人信息清单、撤回隐私同意或执行数据彻底清退。')
                .fontSize(12)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                .lineHeight(18)
            }
          }
          .height(130)
          .scrollBar(BarState.Off)

          // 对等双选操作区
          Row({ space: 12 }) {
            Button('不同意并退出')
              .fontSize(13)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .backgroundColor('rgba(0, 0, 0, 0.05)')
              .layoutWeight(1)
              .height(38)
              .onClick(() => {
                this.onDisagree();
              })

            Button('同意并开启')
              .fontSize(13)
              .fontColor(Color.White)
              .backgroundColor(ColorConstants.ACCENT_CORAL)
              .layoutWeight(1)
              .height(38)
              .onClick(() => {
                this.onAgree();
              })
          }
          .width('100%')
        }
        .width('86%')
        .padding(20)
        .borderRadius(20)
        .backgroundColor(ColorConstants.LIGHT_CARD_BG)
        .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
        .shadow({ radius: 30, color: 'rgba(0, 0, 0, 0.12)', offsetY: 8 })
      }
      .width('100%')
      .height('100%')
    }
  }
}
