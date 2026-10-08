/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * TodayFlowCard2x4: 2x4 Desktop Service Widget (今日心流节奏轨)
 */

const storage2x4 = new LocalStorage();

@Entry(storage2x4)
@Component
struct TodayFlowCard2x4 {
  @LocalStorageProp('slot1') slot1: string = '09:30 架构方案重构 (90m)';
  @LocalStorageProp('slot2') slot2: string = '11:00 15m 留白呼吸';
  @LocalStorageProp('slot3') slot3: string = '11:15 跨部门同步评审 (45m)';
  @LocalStorageProp('slot4') slot4: string = '14:00 撰写周报 (30m)';

  build() {
    Column({ space: 6 }) {
      // 1. 卡片顶栏
      Row() {
        Row({ space: 4 }) {
          Image($r('app.media.ic_sparkle'))
            .width(13)
            .height(13)
            .fillColor('#E87A64')
          Text('Aura 今日心流节奏')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#24201D')
        }

        Blank()

        Text('4 个时段 · 脑力舒适')
          .fontSize(10)
          .fontColor('#6E665E')
      }
      .width('100%')
      .padding({ bottom: 2 })

      // 2. 微缩 Structured 纵向时段流
      Column({ space: 4 }) {
        this.buildSlotItem(this.slot1, '#5A7D9A', 'rgba(90, 125, 154, 0.12)')
        this.buildSlotItem(this.slot2, '#628A61', 'rgba(98, 138, 97, 0.12)')
        this.buildSlotItem(this.slot3, '#D69A56', 'rgba(214, 154, 86, 0.12)')
        this.buildSlotItem(this.slot4, '#5A7D9A', 'rgba(90, 125, 154, 0.12)')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#F7F5F0')
    .borderRadius(16)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          target: 'today_flow'
        }
      });
    })
  }

  @Builder
  private buildSlotItem(title: string, dotColor: string, bgColor: string) {
    Row({ space: 8 }) {
      Circle({ width: 7, height: 7 })
        .fill(dotColor)

      Text(title)
        .fontSize(11)
        .fontColor('#24201D')
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .height(26)
    .padding({ left: 8, right: 8 })
    .borderRadius(8)
    .backgroundColor(bgColor)
  }
}
