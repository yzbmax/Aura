/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Application Main Index: Navigation & Multi-Device Breakpoint Matrix
 */

import { deviceInfo } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { AppConstants } from '../common/constants/AppConstants';
import { TodoItem, TodoSource } from '../models/TodoItem';
import { UserSettings } from '../models/UserSettings';
import { RdbHelper } from '../database/RdbHelper';
import { TodoDao } from '../database/dao/TodoDao';
import { UserSettingsDao } from '../database/dao/UserSettingsDao';
import { AudioService } from '../common/media/AudioService';
import { WatchSyncService } from '../engine/WatchSyncService';
import { TimeUtils } from '../common/utils/TimeUtils';
import { TodayFlowView } from '../views/TodayFlowView';
import { TaskMatrixView } from '../views/TaskMatrixView';
import { SettingsView } from '../views/SettingsView';
import { FocusImmersionPage } from '../views/FocusImmersionPage';
import { SunsetCeremonyPage } from '../views/SunsetCeremonyPage';
import { PrivacyDialog } from '../components/PrivacyDialog';
import { CreateTodoDialog } from '../components/CreateTodoDialog';
import { HdsFloatingDock } from '../components/HdsFloatingDock';
import { WatchFocusCompanionView } from '../components/WatchFocusCompanionView';
import { CarCockpitView } from '../views/CarCockpitView';
import { TvAmbientFocusView } from '../views/TvAmbientFocusView';
import { GlobalUndoCapsule } from '../components/GlobalUndoCapsule';
import { Logger } from '../common/utils/Logger';

@Entry
@ComponentV2
struct Index {
  @Local currentTabIndex: number = 0;
  @Local userSettings: UserSettings = new UserSettings();
  @Local currentDeviceType: string = deviceInfo.deviceType;

  @Local activeFocusItem: TodoItem | null = null;
  @Local isSunsetOpen: boolean = false;
  @Local isPrivacyDialogOpen: boolean = false;
  @Local isCreateTodoOpen: boolean = false;
  @Local todoRefreshTrigger: number = 0;
  @Local isInitialized: boolean = false;
  @Local isQueueDrawerOpen: boolean = false;

  @Local topAvoidHeight: number = 38;
  @Local bottomAvoidHeight: number = 24;

  private navPathStack: NavPathStack = new NavPathStack();
  private swiperController: SwiperController = new SwiperController();

  async aboutToAppear(): Promise<void> {
    this.currentDeviceType = deviceInfo.deviceType;
    const topPx = AppStorage.get<number>('topAvoidPx') ?? 0;
    const bottomPx = AppStorage.get<number>('bottomAvoidPx') ?? 0;
    if (topPx > 0) {
      this.topAvoidHeight = px2vp(topPx);
    }
    if (bottomPx > 0) {
      this.bottomAvoidHeight = px2vp(bottomPx);
    }

    const context = getContext(this) as common.UIAbilityContext;
    try {
      const pref = await preferences.getPreferences(context, 'aura_launch_prefs');
      const agreed = await pref.get('agreed_privacy', false) as boolean;
      if (!agreed) {
        // 未同意隐私协议，绝不提前初始化任何数据库与后台线程
        this.isPrivacyDialogOpen = true;
      } else {
        this.userSettings.isAgreedPrivacy = true;
        await this.initAppServices(context);
      }
    } catch (err) {
      Logger.warn('Index', 'Failed to check launch preferences: %{public}s', JSON.stringify(err));
      this.isPrivacyDialogOpen = true;
    }
  }

  onBackPress(): boolean | void {
    if (this.isQueueDrawerOpen) {
      this.isQueueDrawerOpen = false;
      return true;
    }
    if (this.isCreateTodoOpen) {
      this.isCreateTodoOpen = false;
      return true;
    }
    if (this.activeFocusItem) {
      this.activeFocusItem = null;
      return true;
    }
    if (this.isSunsetOpen) {
      this.isSunsetOpen = false;
      return true;
    }
    return false;
  }

  build() {
    Navigation(this.navPathStack) {
      if (this.currentDeviceType === 'wearable') {
        // 1. 智能手表端：466x466 圆形纯净微沙漏伴侣
        WatchFocusCompanionView()
      } else if (this.currentDeviceType === 'car') {
        // 2. 车载座舱端：大触控热区、安全合规与极速杂念收纳
        CarCockpitView()
      } else if (this.currentDeviceType === 'tv') {
        // 3. 智慧屏端：10尺客厅空间心流壁画与 D-pad 遥控器焦点
        TvAmbientFocusView({
          settings: this.userSettings
        })
      } else {
        // 4. 手机 / 平板 / 2in1：黄金 3 Tab 自适应工作台 (支持墨水屏/纸感模式)
        Stack({ alignContent: Alignment.Bottom }) {
          // 1. 黄金 3 Tab 主内容滑动区域 (Swiper 丝滑横向滑动切换与动效，多端 maxWidth 800 黄金工作台)
          Column() {
            Swiper(this.swiperController) {
              TodayFlowView({
                settings: this.userSettings,
                isInitialized: this.isInitialized,
                refreshTrigger: this.todoRefreshTrigger,
                isCreateTodoOpen: this.isCreateTodoOpen,
                topAvoidHeight: this.topAvoidHeight,
                bottomAvoidHeight: this.bottomAvoidHeight,
                isQueueDrawerOpen: this.isQueueDrawerOpen,
                onQueueDrawerStateChange: (isOpen: boolean) => {
                  this.isQueueDrawerOpen = isOpen;
                },
                onOpenFocus: (item: TodoItem) => {
                  this.activeFocusItem = item;
                },
                onOpenSunset: () => {
                  this.isSunsetOpen = true;
                },
                onOpenSettings: () => {
                  this.currentTabIndex = 2;
                  this.swiperController.changeIndex(2, true);
                },
                onOpenCreateTodo: () => {
                  this.isCreateTodoOpen = true;
                }
              })

              TaskMatrixView({
                isInitialized: this.isInitialized,
                topAvoidHeight: this.topAvoidHeight,
                onOpenFocus: (item: TodoItem) => {
                  this.activeFocusItem = item;
                }
              })

              SettingsView({
                settings: this.userSettings,
                topAvoidHeight: this.topAvoidHeight,
                onSettingsUpdated: (newSettings: UserSettings) => {
                  this.userSettings = newSettings;
                },
                onRevokePrivacy: () => {
                  this.handleRevokePrivacy();
                }
              })
            }
            .index(this.currentTabIndex)
            .loop(false)
            .indicator(false)
            .duration(280)
            .curve(Curve.FastOutSlowIn)
            .disableSwipe(this.isQueueDrawerOpen)
            .onChange((index: number) => {
              this.currentTabIndex = index;
            })
            .width('100%')
            .height('100%')
          }
          .width('100%')
          .constraintSize({ maxWidth: 800 })
          .height('100%')

        // 2. 底部悬浮 HDS 微晶胶囊 Dock (黄金 3 Tab，抽屉展开时优雅沉降并淡出)
        if (!this.activeFocusItem && !this.isSunsetOpen && !this.isQueueDrawerOpen) {
          HdsFloatingDock({
            selectedIndex: this.currentTabIndex,
            onTabChange: (index: number) => {
              this.currentTabIndex = index;
              this.swiperController.changeIndex(index, true);
            }
          })
          .margin({ bottom: this.bottomAvoidHeight > 0 ? this.bottomAvoidHeight + 8 : 20 })
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 30 })).animation({ duration: 200 }))
        }

        // 3. 全屏沉浸独立模态：专注沙漏场域
        if (this.activeFocusItem) {
          FocusImmersionPage({
            item: this.activeFocusItem,
            onClose: () => {
              this.activeFocusItem = null;
            }
          })
          .transition(TransitionEffect.OPACITY.animation({ duration: 250 }))
        }

        // 4. 全屏沉浸独立模态：晚间打烊仪式
        if (this.isSunsetOpen) {
          SunsetCeremonyPage({
            onClose: () => {
              this.isSunsetOpen = false;
            }
          })
          .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
        }

        // 5. 【华为审核红线】首屏对等双选隐私协议强校验弹窗
        PrivacyDialog({
          isVisible: this.isPrivacyDialogOpen,
          onAgree: () => {
            this.handleAgreePrivacy();
          },
          onDisagree: () => {
            this.handleDisagreePrivacy();
          }
        })

        // 6. 全局模态：新建待办 / 时间块极简弹窗 (全屏安全区完整覆盖，内置高精度物理弹簧动效)
        CreateTodoDialog({
          isVisible: this.isCreateTodoOpen,
          onClose: () => {
            this.isCreateTodoOpen = false;
          },
          onCreated: () => {
            this.isCreateTodoOpen = false;
            this.todoRefreshTrigger++;
          }
        })

        // 7. 全局撤销悬浮微胶囊 (非侵入式 5 秒防错)
        GlobalUndoCapsule()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private async initAppServices(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    try {
      // 1. 初始化 SQLite 数据库
      await RdbHelper.getInstance().init(context);

      // 2. 预加载低延迟和弦音频池
      await AudioService.getInstance().init(context);

      // 3. 加载排期偏好
      this.userSettings = await UserSettingsDao.getSettings();

      // 4. 执行 30 天过期软删除墓碑物理清理
      await TodoDao.cleanupOldTombstones(AppConstants.TOMBSTONE_CLEANUP_DAYS);

      // 5. 初始化分布式手表协同服务
      await WatchSyncService.getInstance().init(context);
      WatchSyncService.getInstance().subscribeParkingLot(async (text: string) => {
        const thought = new TodoItem(TimeUtils.generateUUID(), text, 25);
        thought.source = TodoSource.PARKING_LOT;
        thought.scheduledStartAt = 0;
        thought.scheduledEndAt = 0;
        await TodoDao.insert(thought);
        this.todoRefreshTrigger++;
      });

      this.isInitialized = true;
      Logger.info('Index', 'All core local services initialized cleanly.');
    } catch (err) {
      Logger.error('Index', 'Failed to initialize core app services: %{public}s', JSON.stringify(err));
    }
  }

  private async handleAgreePrivacy(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const pref = await preferences.getPreferences(context, 'aura_launch_prefs');
    await pref.put('agreed_privacy', true);
    await pref.flush();

    this.isPrivacyDialogOpen = false;
    this.userSettings.isAgreedPrivacy = true;
    await this.initAppServices(context);
  }

  private handleDisagreePrivacy(): void {
    const context = getContext(this) as common.UIAbilityContext;
    try {
      context.terminateSelf();
    } catch {
      // 优雅平稳退出
    }
  }

  private async handleRevokePrivacy(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const pref = await preferences.getPreferences(context, 'aura_launch_prefs');
    await pref.put('agreed_privacy', false);
    await pref.flush();

    this.isPrivacyDialogOpen = true;
    this.isInitialized = false;
  }
}