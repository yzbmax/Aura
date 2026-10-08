import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.getMainWindow((err, windowClass) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err));
        return;
      }

      // 1. 设置沉浸式全屏布局，使背景贯通延伸覆盖状态栏与底部手势导航条
      windowClass.setWindowLayoutFullScreen(true, (setFullErr) => {
        if (setFullErr.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to setWindowLayoutFullScreen. Cause: %{public}s', JSON.stringify(setFullErr));
        }
      });

      // 2. 将状态栏和底部导航栏设置为完全透明
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#101828',
        navigationBarContentColor: '#101828'
      }, (barErr) => {
        if (barErr.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to setWindowSystemBarProperties. Cause: %{public}s', JSON.stringify(barErr));
        }
      });

      // 3. 记录系统避让区域高度 (px) 到 AppStorage
      try {
        const avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate('topAvoidPx', avoidArea.topRect.height);
        AppStorage.setOrCreate('bottomAvoidPx', avoidArea.bottomRect.height);

        windowClass.on('avoidAreaChange', (data) => {
          if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
            AppStorage.setOrCreate('topAvoidPx', data.area.topRect.height);
            AppStorage.setOrCreate('bottomAvoidPx', data.area.bottomRect.height);
          }
        });
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', 'Failed to getWindowAvoidArea: %{public}s', JSON.stringify(e));
      }

      windowStage.loadContent('pages/Index', (loadErr) => {
        if (loadErr.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(loadErr));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}