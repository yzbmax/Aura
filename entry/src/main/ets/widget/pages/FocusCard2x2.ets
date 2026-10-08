/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * FocusCard2x2: 2x2 Desktop Service Widget (当下聚焦与微沙漏)
 */

const storage2x2 = new LocalStorage();

@Entry(storage2x2)
@Component
struct FocusCard2x2 {
  @LocalStorageProp('currentTaskTitle') currentTaskTitle: string = '当下无专注 · 脑力舒适';
  @LocalStorageProp('remainingTime') remainingTime: string = '25:00';
  @LocalStorageProp('todayDeepWork') todayDeepWork: string = '2.5h / 4.5h';
  @LocalStorageProp('isFocusing') isFocusing: boolean = false;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 8 }) {
        // 1. 卡片顶栏
        Row() {
          Row({ space: 4 }) {
            Image($r('app.media.ic_hourglass'))
              .width(13)
              .height(13)
              .fillColor('#E87A64')
            Text('Aura 专注')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#5E564F')
          }

          Blank()

          Text(this.todayDeepWork)
            .fontSize(10)
            .fontColor('#6E665E')
        }
        .width('100%')

        Blank()

        // 2. 居中微沙漏与倒计时
        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 72, height: 72 })
            .fill('rgba(232, 122, 100, 0.08)')

          Circle({ width: 64, height: 64 })
            .stroke('#E87A64')
            .strokeWidth(2.5)
            .fill(Color.White)

          Column({ space: 1 }) {
            Text(this.remainingTime)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#24201D')

            Text(this.isFocusing ? '进行中' : '破冰就绪')
              .fontSize(8)
              .fontColor(this.isFocusing ? '#628A61' : '#E87A64')
          }
        }
        .width('100%')

        Blank()

        // 3. 任务标题与启动提示
        Text(this.currentTaskTitle)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#24201D')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding(12)
      .backgroundColor('#F7F5F0')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          target: 'focus'
        }
      });
    })
  }
}
