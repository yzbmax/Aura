/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Sample Data Loader: High-fidelity Flow Routine Seed for Realistic Experience
 */

import { Priority, TimingMode, TodoItem, TodoSource, TodoStatus } from '../models/TodoItem';
import { TodoDao } from './dao/TodoDao';
import { RdbHelper } from './RdbHelper';
import { AuraDatabaseSchema } from './schema/AuraDatabaseSchema';
import { relationalStore } from '@kit.ArkData';

export class SampleDataLoader {
  /**
   * 清除脏数据并重置为高质感真实心流工作流
   */
  public static async loadRealisticSampleData(): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    // 1. 清理现有测试数据
    try {
      const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
      predicates.isNotNull('id');
      await store.delete(predicates);
    } catch {
      // 容错兜底
    }

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 9, 30).getTime();

    // 2. 预置事项 1：晨曦破冰 · 架构重构 (45m)
    const item1 = new TodoItem('flow_001', '深度编码 · Aura 核心架构微晶重构');
    item1.priority = Priority.HIGH;
    item1.estimatedMinutes = 45;
    item1.timingMode = TimingMode.COUNTDOWN;
    item1.status = TodoStatus.PENDING;
    item1.source = TodoSource.MANUAL;
    item1.scheduledStartAt = todayStart;
    item1.scheduledEndAt = todayStart + 45 * 60 * 1000;
    item1.createdAt = todayStart - 3600000;
    item1.tags = ['核心攻坚', '架构'];
    await TodoDao.insert(item1);

    // 3. 预置事项 2：技术评审 · 合规自检 (45m)
    const item2 = new TodoItem('flow_002', '技术评审 · 华为应用市场合规自检');
    item2.priority = Priority.MEDIUM;
    item2.estimatedMinutes = 45;
    item2.timingMode = TimingMode.COUNTDOWN;
    item2.status = TodoStatus.PENDING;
    item2.source = TodoSource.MANUAL;
    item2.scheduledStartAt = todayStart + 60 * 60 * 1000;
    item2.scheduledEndAt = item2.scheduledStartAt + 45 * 60 * 1000;
    item2.createdAt = todayStart - 3400000;
    item2.tags = ['合规', '评审'];
    await TodoDao.insert(item2);

    // 4. 预置事项 3：软总线流转探索 (45m)
    const item3 = new TodoItem('flow_003', '分布式软总线 · 局域网无缝流转探索');
    item3.priority = Priority.HIGH;
    item3.estimatedMinutes = 45;
    item3.timingMode = TimingMode.COUNTDOWN;
    item3.status = TodoStatus.PENDING;
    item3.source = TodoSource.MANUAL;
    item3.scheduledStartAt = todayStart + 120 * 60 * 1000;
    item3.scheduledEndAt = item3.scheduledStartAt + 45 * 60 * 1000;
    item3.createdAt = todayStart - 3200000;
    item3.tags = ['分布式', '架构'];
    await TodoDao.insert(item3);

    // 5. 预置事项 4：图标与色彩规范走查 (45m)
    const item4 = new TodoItem('flow_004', '极简设计 · 细线矢量微晶图标走查');
    item4.priority = Priority.MEDIUM;
    item4.estimatedMinutes = 45;
    item4.timingMode = TimingMode.COUNTDOWN;
    item4.status = TodoStatus.PENDING;
    item4.source = TodoSource.MANUAL;
    item4.scheduledStartAt = todayStart + 180 * 60 * 1000;
    item4.scheduledEndAt = item4.scheduledStartAt + 45 * 60 * 1000;
    item4.createdAt = todayStart - 3000000;
    item4.tags = ['设计', '微标'];
    await TodoDao.insert(item4);

    // 6. 预置事项 5：容灾与持久化压测 (40m)
    const item5 = new TodoItem('flow_005', '容灾压测 · 离线 RDB 持久化异常注入');
    item5.priority = Priority.MEDIUM;
    item5.estimatedMinutes = 40;
    item5.timingMode = TimingMode.COUNTDOWN;
    item5.status = TodoStatus.PENDING;
    item5.source = TodoSource.MANUAL;
    item5.scheduledStartAt = todayStart + 240 * 60 * 1000;
    item5.scheduledEndAt = item5.scheduledStartAt + 40 * 60 * 1000;
    item5.createdAt = todayStart - 2800000;
    item5.tags = ['数据库', '压测'];
    await TodoDao.insert(item5);

    // 7. 预置事项 6：性能微调 · 声明式渲染 (40m)
    const item6 = new TodoItem('flow_006', '性能微调 · 声明式组件按需刷新优化');
    item6.priority = Priority.LOW;
    item6.estimatedMinutes = 40;
    item6.timingMode = TimingMode.COUNTDOWN;
    item6.status = TodoStatus.PENDING;
    item6.source = TodoSource.MANUAL;
    item6.scheduledStartAt = todayStart + 295 * 60 * 1000;
    item6.scheduledEndAt = item6.scheduledStartAt + 40 * 60 * 1000;
    item6.createdAt = todayStart - 2600000;
    item6.tags = ['性能', 'ArkUI'];
    await TodoDao.insert(item6);

    // 8. 预置事项 7：机动备选池事项（未排期杂念停泊）
    const item7 = new TodoItem('flow_007', '杂念停机坪：调研软总线近场握手协议');
    item7.priority = Priority.LOW;
    item7.estimatedMinutes = 20;
    item7.timingMode = TimingMode.STOPWATCH;
    item7.status = TodoStatus.PENDING;
    item7.source = TodoSource.PARKING_LOT;
    item7.scheduledStartAt = 0;
    item7.scheduledEndAt = 0;
    item7.createdAt = todayStart - 1800000;
    item7.tags = ['探索机动'];
    await TodoDao.insert(item7);

    // 9. 预置事项 8：已完成事项（晨间成果沉淀）
    const item8 = new TodoItem('flow_008', '晨间静心 · 禅意温润燕麦色板校准');
    item8.priority = Priority.HIGH;
    item8.estimatedMinutes = 30;
    item8.actualMinutes = 28;
    item8.status = TodoStatus.COMPLETED;
    item8.completedAt = todayStart - 10000;
    item8.createdAt = todayStart - 7200000;
    item8.tags = ['设计', '微标'];
    await TodoDao.insert(item8);

    // 10. 预置事项 9：冷冻舱事项（反内疚休眠）
    const item9 = new TodoItem('flow_009', '旧网络模块淘汰清理（静默休眠）');
    item9.priority = Priority.LOW;
    item9.estimatedMinutes = 60;
    item9.status = TodoStatus.FROZEN;
    item9.isFrozen = true;
    item9.agingLevel = 3;
    item9.createdAt = todayStart - 15 * 86400000;
    item9.tags = ['重构'];
    await TodoDao.insert(item9);
  }

  /**
   * 若当前待办极少或只有测试垃圾数据，自动植入心流样本
   */
  public static async autoSeedIfBare(): Promise<boolean> {
    const active = await TodoDao.queryAllActive();
    const hasOnlyJunk = active.length > 0 && active.every(t => t.title.toLowerCase().includes('qwe'));
    const hasDuplicateCore = active.filter(t => t.title === '核心攻坚').length >= 2;
    if (active.length < 6 || hasOnlyJunk || hasDuplicateCore) {
      await SampleDataLoader.loadRealisticSampleData();
      return true;
    }
    return false;
  }
}
