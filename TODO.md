# 「Aura · 同频」工程开发全景路线与 TODO 清单

> **基线规范**：HarmonyOS NEXT (API 24 / 6.1.1 Release) · ArkTS 严格模式 · ArkUI V2 (`@ComponentV2` / `@ObservedV2`)  
> **数据哲学**：Local-First 本地优先 · 零敏感特权依赖 · 零多余常驻保活  
> **设计哲学**：暖科技 · 柔和光感 · 心流呼吸 (Warm Technology & Immersive Flow)  
> **关联文档**：[`docs/AuraPRD.md`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/docs/AuraPRD.md) · [`docs/DESIGN.md`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/docs/DESIGN.md)

---

## 目录结构落地情况 (Production Directory Structure)

```text
entry/src/main/
├── ets/
│   ├── entryability/
│   │   └── EntryAbility.ets               # 沉浸式窗口初始化、冷启动时效与生命周期
│   ├── common/
│   │   ├── constants/
│   │   │   ├── AppConstants.ets           # 算法默认阈值 (4.5h上限, 15m留白) [已实现]
│   │   │   ├── ColorConstants.ets         # 昼夜节律双模色彩 Design Tokens [已实现]
│   │   │   └── CurveConstants.ets         # 阻尼弹簧曲线常量 (curves.springMotion) [已实现]
│   │   ├── utils/
│   │   │   ├── Logger.ets                 # 统一 Hilog 封装 [已实现]
│   │   │   └── TimeUtils.ets              # 时间戳、时段格式化与日期计算 [已实现]
│   │   └── media/
│   │       ├── AudioService.ets           # soundPool 低延迟和弦音频池管理 [已实现]
│   │       └── HapticService.ets          # vibrator 线性微触感震动管理 [已实现]
│   ├── database/
│   │   ├── RdbHelper.ets                  # RelationalStore 数据库初始化、建表与升级封装 [已实现]
│   │   ├── schema/
│   │   │   └── AuraDatabaseSchema.ets     # SQL DDL、高性能索引定义 [已实现]
│   │   └── dao/
│   │       ├── TodoDao.ets                # 待办与时间块 CRUD、软删除墓碑与机动池过滤 [已实现]
│   │       ├── SubTaskDao.ets             # 独立子任务 CRUD [已实现]
│   │       └── UserSettingsDao.ets        # 用户排期偏好配置持久化 [已实现]
│   ├── models/
│   │   ├── TodoItem.ets                   # ArkUI V2 响应式实体 (@ObservedV2, @Trace) [已实现]
│   │   ├── SubTaskItem.ets                # 子任务响应式实体 [已实现]
│   │   ├── TimeSlot.ets                   # 时间切片与装箱槽位实体 [已实现]
│   │   └── UserSettings.ets               # 工作时段与脑力硬上限配置实体 [已实现]
│   ├── engine/
│   │   ├── BinPackingScheduler.ets        # 本地离线贪心区间装箱与弹性调度算法引擎 [已实现]
│   │   ├── StarvationProtector.ets        # 大任务 45m 探索切片防饥饿保底器 [已实现]
│   │   └── MildAgingEngine.ets            # 温和老化与冷冻舱休眠计算器 [已实现]
│   ├── components/
│   │   ├── MobileTopBar.ets               # 沉浸式微晶顶栏 (品牌微标 + 脑力环形微晶罗盘) [已实现]
│   │   ├── ParkingLotInputBar.ets         # 36vp 杂念快录微胶囊 (回车轻烟消融秒停泊) [已实现]
│   │   ├── FlowSpineAxis.ets              # Structured 纵向 1.5px 主轴导轨与圆珠节点 [已实现]
│   │   ├── MistMorphingCard.ets           # 雾化开合卡片 (0.8Hz微脉动 + 原位沙漏形变) [已实现]
│   │   ├── CushionCard.ets                # 15m 留白呼吸缓冲卡片 [已实现]
│   │   ├── FloatingDeckDrawer.ets         # 机动备选池折叠抽屉 [已实现]
│   │   ├── HdsFloatingDock.ets            # 底部 HDS 悬浮微晶胶囊底栏 (黄金 3 Tab + 安全区避让) [已实现]
│   │   └── PrivacyDialog.ets              # 首屏合规双选隐私协议强校验弹窗 [已实现]
│   ├── views/
│   │   ├── TodayFlowView.ets              # Tab 1: 今日心流主视图 (65%+ 纵向时间轴主战场) [已实现]
│   │   ├── TaskMatrixView.ets             # Tab 2: 任务视界主视图 (四象限 + 冷冻舱) [已实现]
│   │   ├── SettingsView.ets               # Tab 3: 偏好与合规主视图 (双清单、撤回同意、注销) [已实现]
│   │   ├── FocusImmersionPage.ets         # 沉浸独立路由: 全屏禅意融化沙漏 / 正计时 [已实现]
│   │   └── SunsetCeremonyPage.ets         # 沉浸独立路由: 晚间打烊仪式 (SaveButton存图) [已实现]
│   └── pages/
│       └── Index.ets                      # Navigation 主入口与多端断点分栏中枢 [已实现]
└── resources/
    ├── rawfile/audio/                     # C4, E4, G4, C5 纯正弦低延迟音频采样 (114KB ≤ 200KB) [已生成]
    └── base/element/                      # 色彩、文本与矢量资源
```

---

## 阶段规划概览

- [x] **Phase 0：工程脚手架、资源接入与设计变量体系** (基座工程、Design Tokens、音视频静态资源)
- [x] **Phase 1：数据持久化底座与响应式领域模型** (RelationalStore、V2 实体、DAO、墓碑清理)
- [x] **Phase 2：自适应时间块装箱与弹性调度引擎** (区间装箱算法、防饥饿切片、流体正计时)
- [x] **Phase 3：多感官反馈引擎** (`soundPool` 和弦阶梯、`vibrator` 泡泡纸微震动)
- [x] **Phase 4：核心微晶组件库** (ArkUI V2 雾化形变卡片、杂念停机坪、纵向主轴、悬浮底栏)
- [x] **Phase 5：核心业务场景视图与路由整合** (黄金 3 Tab、禅意融化沙漏、晚间打烊仪式)
- [x] **Phase 6：多端响应式适配与断点矩阵** (Phone 纵向单列、Tablet 展开双列、2in1 宽屏工作台)
- [x] **Phase 7：华为应用市场审核合规门禁与提审自检** (双清单、SaveButton、零违规保活、Local-First)
- [ ] **Phase 8：V1.0β 生态旗舰演进** (Live View Kit 实况窗、软总线分布式同步、Share Kit 甩单)

---

## 详细任务完成状态

### Phase 0: 工程脚手架与设计变量体系

- [x] **TASK-001**: 依赖与环境初始化
  - **交付文件**: [`entry/oh-package.json5`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/oh-package.json5)
  - **验收结果**: 纯血鸿蒙 SDK 内建套件对齐，hvigor/ohpm 工具链完整通畅。
- [x] **TASK-002**: 资源文件接入与规范定义
  - **交付文件**: `entry/src/main/resources/rawfile/audio/*`
  - **验收结果**: 4 阶正弦波和弦采样 (`sound_chord_c4.wav`, `e4.wav`, `g4.wav`, `c5.wav`) 生成完毕，总大小 114KB，严格小于 200KB 上限。
- [x] **TASK-003**: 昼夜节律双模 Design Tokens 与动效常量
  - **交付文件**: 
    - [`entry/src/main/ets/common/constants/ColorConstants.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/constants/ColorConstants.ets)
    - [`entry/src/main/ets/common/constants/CurveConstants.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/constants/CurveConstants.ets)
    - [`entry/src/main/ets/common/constants/AppConstants.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/constants/AppConstants.ets)
  - **验收结果**: WCAG AA 高对比度色盘就绪，阻尼弹簧曲线常量建立完毕。
- [x] **TASK-004**: 系统级 Hilog 封装
  - **交付文件**: [`entry/src/main/ets/common/utils/Logger.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/utils/Logger.ets)
  - **验收结果**: Hilog 统一封装完成，支持领域分类日志输出。

---

### Phase 1: 数据持久化底座与响应式领域模型 (Local-First)

- [x] **TASK-101**: ArkUI V2 响应式实体建模
  - **交付文件**: 
    - [`entry/src/main/ets/models/TodoItem.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/models/TodoItem.ets)
    - [`entry/src/main/ets/models/SubTaskItem.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/models/SubTaskItem.ets)
    - [`entry/src/main/ets/models/UserSettings.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/models/UserSettings.ets)
    - [`entry/src/main/ets/models/TimeSlot.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/models/TimeSlot.ets)
  - **验收结果**: 全量采用 `@ObservedV2` 与 `@Trace`，强类型约束，0 `any`。
- [x] **TASK-102**: SQLite 关系型数据库底层封装 (`RelationalStore`)
  - **交付文件**: 
    - [`entry/src/main/ets/database/schema/AuraDatabaseSchema.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/database/schema/AuraDatabaseSchema.ets)
    - [`entry/src/main/ets/database/RdbHelper.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/database/RdbHelper.ets)
  - **验收结果**: 待办主表、子任务从表及索引完整建立，事务与生命周期安全。
- [x] **TASK-103**: 数据访问层 (DAO) 实现与 30 天墓碑清理
  - **交付文件**: 
    - [`entry/src/main/ets/database/dao/TodoDao.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/database/dao/TodoDao.ets)
    - [`entry/src/main/ets/database/dao/SubTaskDao.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/database/dao/SubTaskDao.ets)
    - [`entry/src/main/ets/database/dao/UserSettingsDao.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/database/dao/UserSettingsDao.ets)
  - **验收结果**: CRUD、机动池查询、30 天过期墓碑安全物理清理全部就绪。

---

### Phase 2: 自适应时间块装箱与弹性调度引擎

- [x] **TASK-201**: 贪心区间装箱调度算法核心 (`BinPackingScheduler`)
  - **交付文件**: [`entry/src/main/ets/engine/BinPackingScheduler.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/engine/BinPackingScheduler.ets)
  - **验收结果**: 纯离线算法，综合打分加权贪心装箱，耗时 <2ms。
- [x] **TASK-202**: 人性化“反压迫”三大边界守门机制
  - **交付文件**: [`entry/src/main/ets/engine/BinPackingScheduler.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/engine/BinPackingScheduler.ets)
  - **验收结果**: 脑力上限 ≤4.5h 严格截断、15m 留白强制插入、排不下项平滑归入机动池。
- [x] **TASK-203**: 大任务防饥饿切片策略 (`StarvationProtector`)
  - **交付文件**: [`entry/src/main/ets/engine/StarvationProtector.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/engine/StarvationProtector.ets)
  - **验收结果**: 高优大任务遇碎片空隙自动切出 45m 探索切片保底装箱。
- [x] **TASK-204**: 弹性流体正计时与机动备选池逻辑
  - **交付文件**: [`entry/src/main/ets/engine/BinPackingScheduler.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/engine/BinPackingScheduler.ets)
  - **验收结果**: STOPWATCH 模式 25m 弹性占位装箱验证无误。

---

### Phase 3: 多感官反馈引擎 (Sensory & Feedback Engine)

- [x] **TASK-301**: 低延迟和弦音频池服务 (`AudioService`)
  - **交付文件**: [`entry/src/main/ets/common/media/AudioService.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/media/AudioService.ets)
  - **验收结果**: 基于 `soundPool` 预加载 4 阶纯音采样，支持 `Do-Mi-Sol-Do'` 爬升。
- [x] **TASK-302**: 线性微触感马达服务 (`HapticService`)
  - **交付文件**: [`entry/src/main/ets/common/media/HapticService.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/media/HapticService.ets)
  - **验收结果**: 接入 `vibrator` 泡泡纸微震 (35ms)、气雾微脉冲 (18ms) 与打烊落锁 (70ms)。

---

### Phase 4: 核心微晶组件库 (ArkUI V2)

- [x] **TASK-401**: 沉浸微晶顶栏组件 (`MobileTopBar`)
  - **交付文件**: [`entry/src/main/ets/components/MobileTopBar.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/MobileTopBar.ets)
- [x] **TASK-402**: 杂念停机坪快录微胶囊 (`ParkingLotInputBar`)
  - **交付文件**: [`entry/src/main/ets/components/ParkingLotInputBar.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/ParkingLotInputBar.ets)
- [x] **TASK-403**: Structured 纵向时间轴脊柱组件 (`FlowSpineAxis` / `CushionCard`)
  - **交付文件**: 
    - [`entry/src/main/ets/components/FlowSpineAxis.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/FlowSpineAxis.ets)
    - [`entry/src/main/ets/components/CushionCard.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/CushionCard.ets)
- [x] **TASK-404**: 雾化开合破冰卡片 (`MistMorphingCard`)
  - **交付文件**: [`entry/src/main/ets/components/MistMorphingCard.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/MistMorphingCard.ets)
- [x] **TASK-405**: 机动备选池折叠抽屉 (`FloatingDeckDrawer`)
  - **交付文件**: [`entry/src/main/ets/components/FloatingDeckDrawer.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/FloatingDeckDrawer.ets)
- [x] **TASK-406**: 底部 HDS 悬浮微晶胶囊底栏 (`HdsFloatingDock`)
  - **交付文件**: [`entry/src/main/ets/components/HdsFloatingDock.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/HdsFloatingDock.ets)

---

### Phase 5: 核心页面流与业务场景打通

- [x] **TASK-501**: Tab 1「今日心流」主页面整合 (`TodayFlowView`)
  - **交付文件**: [`entry/src/main/ets/views/TodayFlowView.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/TodayFlowView.ets)
- [x] **TASK-502**: Tab 2「任务视界」与冷冻舱视图 (`TaskMatrixView`)
  - **交付文件**: [`entry/src/main/ets/views/TaskMatrixView.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/TaskMatrixView.ets)
- [x] **TASK-503**: Tab 3「偏好与合规」设置主视图 (`SettingsView`)
  - **交付文件**: [`entry/src/main/ets/views/SettingsView.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/SettingsView.ets)
- [x] **TASK-504**: 沉浸独立路由「专注沙漏场域」(`FocusImmersionPage`)
  - **交付文件**: [`entry/src/main/ets/views/FocusImmersionPage.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/FocusImmersionPage.ets)
- [x] **TASK-505**: 沉浸独立路由「晚间打烊仪式」(`SunsetCeremonyPage`)
  - **交付文件**: [`entry/src/main/ets/views/SunsetCeremonyPage.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/SunsetCeremonyPage.ets)

---

### Phase 6: 多端响应式适配 (Phone / Tablet / 2in1 PC)

- [x] **TASK-601**: 多端断点监听与导航模式动态适配
  - **交付文件**: [`entry/src/main/ets/pages/Index.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/pages/Index.ets)

---

### Phase 7: 华为应用市场审核合规门禁 (V1.0α 提审防线)

- [x] **TASK-701**: 首屏对等双选隐私弹窗与零调用防线
  - **交付文件**: [`entry/src/main/ets/components/PrivacyDialog.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/components/PrivacyDialog.ets)
- [x] **TASK-702**: 权限最小化与优雅降级检测
  - **交付文件**: [`entry/src/main/module.json5`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/module.json5)
  - **验收结果**: 仅声明系统级 `ohos.permission.VIBRATE`，零任何后台违规常驻保活。
- [x] **TASK-703**: 生产构建与 Release 验证
  - **验收结果**: `BUILD SUCCESSFUL`，Release 模式 HAP 包构建通过。
- [x] **TASK-704**: 细线矢量图标规范与全屏沉浸贯穿 (去 Emoji 与状态栏/底部栏穿透)
  - **交付文件**: 
    - `entry/src/main/resources/base/media/ic_*.svg` (15 组 1.8px 细线 SVG 原生矢量图标)
    - [`entry/src/main/ets/entryability/EntryAbility.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/entryability/EntryAbility.ets)
    - [`entry/src/main/ets/pages/Index.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/pages/Index.ets)
  - **验收结果**: 全量移除功能与状态 Emoji，替换为规范的细线 SVG 矢量图标；启用全屏沉浸式窗口与透明状态栏/导航栏，背景自然贯穿延伸，安全区精准避让。

---

### Phase 8: V1.0β 生态旗舰演进 (Milestone 2 路线图)

- [ ] **TASK-801**: 华为账号快捷登录 (Account Kit)
- [ ] **TASK-802**: 软总线局域网多设备分布式数据同步
- [ ] **TASK-803**: 全域心流广播与实况窗交互 (Live View Kit)
- [ ] **TASK-804**: 系统全局会议日程缝隙融合 (Calendar Kit ACL)
- [ ] **TASK-805**: Share Kit 华为分享隔空甩单
- [x] **TASK-806**: 习惯镜像与专注热力图可视化 (`@ohmos/activity_overview`)
  - **交付文件**: 
    - [`entry/oh-package.json5`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/oh-package.json5)
    - [`entry/src/main/ets/views/TaskMatrixView.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/TaskMatrixView.ets)
    - [`entry/src/main/ets/database/dao/TodoDao.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/database/dao/TodoDao.ets)
  - **验收结果**: 成功引入 GitHub 开源零依赖热力图组件并适配 Aura 暖紫调色盘与触感微震，HAP 包编译通过。

---

## 提审前合规终检验收清单 (Release Acceptance Checklist)

| 检查项 | 验证内容与红线标准 | 状态 |
|---|---|:---:|
| **1. 纯血鸿蒙底座** | API 24 (HarmonyOS 6.1.1 Release)，纯 ArkTS 严格模式，0 `any` 警告 | [x] |
| **2. 隐私首屏协议** | 对等双选“同意/不同意”，点击不同意平稳退出；同意前绝对零读写零线程 | [x] |
| **3. 权限按需与降级** | 仅声明 `VIBRATE` 系统权限，无 `KEEP_BACKGROUND_RUNNING` 违规保活 | [x] |
| **4. 双清单完备性** | 设置页包含真实“已收集个人信息清单”与“第三方共享清单” | [x] |
| **5. 撤回与注销入口** | 设置页支持撤回隐私政策同意与数据物理清空 | [x] |
| **6. 零权限相册保存** | 打烊成就卡严格采用 ArkUI 原生 `SaveButton` 控件，免申请相册写入权限 | [x] |
| **7. 纯单机 Local-First** | 离线断网状态下待办 CRUD、装箱算法、5m 破冰、正计时、打烊仪式 100% 顺畅可用 | [x] |
| **8. 性能指标达标** | 调度耗时 $\le 2\text{ms}$，音频延迟 $\le 20\text{ms}$，冷启动 $\le 1.0\text{s}$，无连续模糊插值 | [x] |
| **9. 列表虚拟滚动** | 全量采用声明式模板与响应式更新，无内存泄漏 | [x] |
| **10. 视觉质感规范** | 严格遵循 Symbol / 细线矢量图标，界面无 Emoji 充当功能图标，全屏手势避让准确 | [x] |
