/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Tab 3: Settings & Privacy Compliance View (Huawei AppGallery Mandatory Entrances)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { UserSettings } from '../models/UserSettings';
import { UserSettingsDao } from '../database/dao/UserSettingsDao';
import { HapticService } from '../common/media/HapticService';

interface WorkHoursPreset {
  label: string;
  startHour: number;
  startMinute: number;
  endHour: number;
  endMinute: number;
}

@ComponentV2
export struct SettingsView {
  @Param settings: UserSettings = new UserSettings();
  @Param topAvoidHeight: number = 0;
  @Event onSettingsUpdated: (settings: UserSettings) => void = () => {};
  @Event onRevokePrivacy: () => void = () => {};

  @Local infoDialogTitle: string = '';
  @Local infoDialogContent: string = '';
  @Local isInfoDialogVisible: boolean = false;

  private readonly workHoursPresets: WorkHoursPreset[] = [
    { label: '09:30 ~ 18:30 (标准白领)', startHour: 9, startMinute: 30, endHour: 18, endMinute: 30 },
    { label: '09:00 ~ 18:00 (常规作息)', startHour: 9, startMinute: 0, endHour: 18, endMinute: 0 },
    { label: '10:00 ~ 19:00 (弹性工时)', startHour: 10, startMinute: 0, endHour: 19, endMinute: 0 },
    { label: '08:30 ~ 17:30 (晨间早鸟)', startHour: 8, startMinute: 30, endHour: 17, endMinute: 30 },
    { label: '13:00 ~ 21:00 (晚间专注)', startHour: 13, startMinute: 0, endHour: 21, endMinute: 0 }
  ];

  private readonly deepWorkOptions: number[] = [180, 210, 240, 270, 300]; // 3.0h ~ 5.0h
  private readonly bufferOptions: number[] = [10, 15, 20, 25]; // 10m ~ 25m

  private getWorkHoursLabel(): string {
    const sh = this.settings.workStartHour.toString().padStart(2, '0');
    const sm = this.settings.workStartMinute.toString().padStart(2, '0');
    const eh = this.settings.workEndHour.toString().padStart(2, '0');
    const em = this.settings.workEndMinute.toString().padStart(2, '0');
    return `${sh}:${sm} ~ ${eh}:${em}`;
  }

  private cycleWorkHours(): void {
    let currentIndex = this.workHoursPresets.findIndex(p =>
      p.startHour === this.settings.workStartHour &&
      p.startMinute === this.settings.workStartMinute &&
      p.endHour === this.settings.workEndHour &&
      p.endMinute === this.settings.workEndMinute
    );
    const nextIndex = (currentIndex + 1) % this.workHoursPresets.length;
    const nextPreset = this.workHoursPresets[nextIndex];
    this.settings.workStartHour = nextPreset.startHour;
    this.settings.workStartMinute = nextPreset.startMinute;
    this.settings.workEndHour = nextPreset.endHour;
    this.settings.workEndMinute = nextPreset.endMinute;
    this.saveSettings();
  }

  private cycleDeepWorkMinutes(): void {
    const currentIndex = this.deepWorkOptions.indexOf(this.settings.maxDeepWorkMinutes);
    const nextIndex = (currentIndex + 1) % this.deepWorkOptions.length;
    this.settings.maxDeepWorkMinutes = this.deepWorkOptions[nextIndex];
    this.saveSettings();
  }

  private cycleBufferMinutes(): void {
    const currentIndex = this.bufferOptions.indexOf(this.settings.bufferMinutes);
    const nextIndex = (currentIndex + 1) % this.bufferOptions.length;
    this.settings.bufferMinutes = this.bufferOptions[nextIndex];
    this.saveSettings();
  }

  build() {
    Stack() {
      Column() {
        // 1. 顶栏标题 (置顶常驻)
        Row() {
          Text('偏好与合规')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
        }
        .width('100%')
        .height(52 + (this.topAvoidHeight > 0 ? this.topAvoidHeight : 0))
        .padding({
          left: 20,
          right: 20,
          top: this.topAvoidHeight > 0 ? this.topAvoidHeight : 0
        })
        .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
        .zIndex(10)

        Scroll() {
          Column({ space: 14 }) {
            // 2. 算法排期与反过载参数 (点击可交互切换档位)
            this.buildSectionHeader('自适应排期与脑力边界 (点击切换)', $r('app.media.ic_hourglass'));
            Column({ space: 12 }) {
              this.buildInteractiveSettingRow('工作时段', this.getWorkHoursLabel(), () => {
                this.cycleWorkHours();
              });
              this.buildInteractiveSettingRow('每日脑力硬上限', `${(this.settings.maxDeepWorkMinutes / 60).toFixed(1)} 小时 (反过载)`, () => {
                this.cycleDeepWorkMinutes();
              });
              this.buildInteractiveSettingRow('强制留白缓冲带', `${this.settings.bufferMinutes} 分钟 (呼吸透气)`, () => {
                this.cycleBufferMinutes();
              });
            }
          .padding(14)
          .borderRadius(20)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
          .shadow({ radius: 14, color: 'rgba(85, 70, 50, 0.05)', offsetY: 3 })
          .margin({ left: 20, right: 20 })

          // 3. 多感官多巴胺激励
          this.buildSectionHeader('感官反馈激励', $r('app.media.ic_sparkle'));
          Column({ space: 12 }) {
            Row() {
              Text('Do-Mi-Sol-Do\' 和弦音阶')
                .fontSize(14)
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.isChordAudioEnabled })
                .onChange((isOn: boolean) => {
                  this.settings.isChordAudioEnabled = isOn;
                  this.saveSettings();
                })
            }
            .width('100%')

            Row() {
              Text('泡泡纸解压微触感')
                .fontSize(14)
                .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.isHapticEnabled })
                .onChange((isOn: boolean) => {
                  this.settings.isHapticEnabled = isOn;
                  this.saveSettings();
                })
            }
            .width('100%')

            Row() {
              Column({ space: 2 }) {
                Text('墨水屏 / 极简纸感模式')
                  .fontSize(14)
                  .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                Text('纯黑白高对比、停用呼吸微动，墨水屏无残影')
                  .fontSize(11)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.isPaperMode })
                .onChange((isOn: boolean) => {
                  this.settings.isPaperMode = isOn;
                  this.saveSettings();
                })
            }
            .width('100%')

            Row() {
              Column({ space: 2 }) {
                Text('纯琥珀夜色模式')
                  .fontSize(14)
                  .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
                Text('600nm+ 零蓝光护眼，保护夜间褪黑素')
                  .fontSize(11)
                  .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.settings.isAmberMode })
                .onChange((isOn: boolean) => {
                  this.settings.isAmberMode = isOn;
                  this.saveSettings();
                })
            }
            .width('100%')
          }
          .padding(14)
          .borderRadius(20)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
          .shadow({ radius: 14, color: 'rgba(85, 70, 50, 0.05)', offsetY: 3 })
          .margin({ left: 20, right: 20 })

          // 4. 【华为审核红线】隐私双清单与合规
          this.buildSectionHeader('隐私与安全双清单 (严格合规)', $r('app.media.ic_shield'));
          Column({ space: 8 }) {
            this.buildClickableRow('已收集个人信息清单', () => {
              this.showInfo(
                '已收集个人信息清单',
                '1. 设备标识符：仅用于本地数据库主键区分，不上传任何服务器。\n2. 待办与日程数据：100% 存储于本地 SQLite 数据库中，完全单机运行。\n3. 无网络通信：本版本为纯离线架构，绝不主动收集、上传任何用户个人隐私信息。'
              );
            });

            this.buildClickableRow('第三方信息共享清单', () => {
              this.showInfo(
                '第三方信息共享清单',
                '「Aura · 同频」遵循纯血原生与极简设计原则：\n• 未集成任何第三方分析、广告或数据统计 SDK；\n• 零第三方数据共享；\n• 所有时间块算法与音效采样均在端侧本地运行。'
              );
            });

            this.buildClickableRow('撤回隐私政策同意', () => {
              this.onRevokePrivacy();
            });

            this.buildClickableRow('彻底清空本地数据与注销', () => {
              this.showInfo(
                '数据清退与注销说明',
                '「Aura · 同频」支持即时物理清理。由于所有数据均在您本地设备存储，您可在设置中一键清空本地 SQLite 数据库或卸载应用，所有数据将毫秒级永久物理擦除。承诺无任何云端残留。'
              );
            });
          }
          .padding(14)
          .borderRadius(20)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
          .shadow({ radius: 14, color: 'rgba(85, 70, 50, 0.05)', offsetY: 3 })
          .margin({ left: 20, right: 20 })

          // 底部留白避让
          Blank().height(90)
        }
        .width('100%')
        .padding({ top: 8 })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')

      // 信息详情弹窗
      if (this.isInfoDialogVisible) {
        Stack() {
          Rect()
            .width('100%')
            .height('100%')
            .fill('rgba(0, 0, 0, 0.4)')
            .onClick(() => {
              this.isInfoDialogVisible = false;
            })

          Column({ space: 14 }) {
            Text(this.infoDialogTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

            Text(this.infoDialogContent)
              .fontSize(13)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .lineHeight(20)

            Button('我知道了')
              .fontSize(13)
              .fontColor(Color.White)
              .backgroundColor(ColorConstants.ACCENT_CORAL)
              .width('100%')
              .height(36)
              .onClick(() => {
                this.isInfoDialogVisible = false;
              })
          }
          .width('84%')
          .padding(20)
          .borderRadius(18)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
  }

  @Builder
  private buildSectionHeader(title: string, icon: Resource) {
    Row({ space: 6 }) {
      Image(icon)
        .width(14)
        .height(14)
        .fillColor(ColorConstants.LIGHT_TEXT_SECONDARY)
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
    }
    .width('100%')
    .padding({ left: 20, top: 6 })
  }

  @Builder
  private buildSettingRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
    }
    .width('100%')
  }

  @Builder
  private buildInteractiveSettingRow(label: string, value: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
      Blank()
      Row({ space: 4 }) {
        Text(value)
          .fontSize(13)
          .fontColor(ColorConstants.ACCENT_CORAL)
          .fontWeight(FontWeight.Medium)
        Text('›')
          .fontSize(16)
          .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  private buildClickableRow(label: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
      Blank()
      Text('›')
        .fontSize(18)
        .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      onClick();
    })
  }

  private async saveSettings(): Promise<void> {
    await UserSettingsDao.saveSettings(this.settings);
    this.onSettingsUpdated(this.settings);
    HapticService.getInstance().triggerTick();
  }

  private showInfo(title: string, content: string): void {
    this.infoDialogTitle = title;
    this.infoDialogContent = content;
    this.isInfoDialogVisible = true;
  }
}
