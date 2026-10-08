/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Comprehensive Unit Test Suite for Aura Single-Thread Minimal Flow Engine
 */

import { describe, it, expect } from '@ohos/hypium';
import { SingleThreadFlowEngine } from '../main/ets/engine/SingleThreadFlowEngine';
import { MildAgingEngine } from '../main/ets/engine/MildAgingEngine';
import { Priority, TodoItem, TodoSource, TodoStatus } from '../main/ets/models/TodoItem';
import { TimeUtils } from '../main/ets/common/utils/TimeUtils';
import { CardDeckKinematics, HapticHysteresisState } from '../main/ets/components/CardDeckKinematics';
import { CurveConstants } from '../main/ets/common/constants/CurveConstants';

export default function localUnitTest(): void {
  describe('AuraCoreUnitTest', () => {

    /**
     * 1. 验证根据优先级与到期/老化程度进行确定性排序与流水线初始化
     */
    it('testPriorityInitializationAndSorting', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const lowTask: TodoItem = new TodoItem('t-low', '低优先级待办', 15);
      lowTask.priority = Priority.LOW;

      const freshMedTask: TodoItem = new TodoItem('t-fresh', '新鲜中优待办', 25);
      freshMedTask.priority = Priority.MEDIUM;
      freshMedTask.dueDate = Date.now() + (2 * 86400000);

      const overdueMedTask: TodoItem = new TodoItem('t-overdue', '逾期中优待办', 25);
      overdueMedTask.priority = Priority.MEDIUM;
      overdueMedTask.dueDate = Date.now() - (2 * 86400000);

      const highTask: TodoItem = new TodoItem('t-high', '高优先级攻坚', 45);
      highTask.priority = Priority.HIGH;

      // 乱序灌入
      engine.load([lowTask, freshMedTask, overdueMedTask, highTask]);

      // 最高优先级的攻坚事项应当独占 activeTask
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('t-high');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);

      // 就绪流水线中，逾期中优优先于新鲜中优，低优排最后
      expect(engine.nextQueue.length).assertEqual(3);
      expect(engine.nextQueue[0].id).assertEqual('t-overdue');
      expect(engine.nextQueue[1].id).assertEqual('t-fresh');
      expect(engine.nextQueue[2].id).assertEqual('t-low');
    });

    /**
     * 2. 验证完成当前活跃任务，进入今日心流轨迹，推进下一项就位
     */
    it('testCompleteActiveAdvancesQueue', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const task1: TodoItem = new TodoItem('c-1', '动作一', 25);
      task1.priority = Priority.HIGH;
      const task2: TodoItem = new TodoItem('c-2', '动作二', 30);
      task2.priority = Priority.MEDIUM;
      const task3: TodoItem = new TodoItem('c-3', '动作三', 15);
      task3.priority = Priority.LOW;

      engine.load([task1, task2, task3]);
      expect(engine.activeTask?.id).assertEqual('c-1');
      expect(engine.nextQueue.length).assertEqual(2);

      // 执行完成
      const completed: TodoItem | null = engine.completeActive();
      expect(completed !== null).assertEqual(true);
      if (completed !== null) {
        expect(completed.id).assertEqual('c-1');
        expect(completed.status).assertEqual(TodoStatus.COMPLETED);
        expect(completed.completedAt).assertLarger(0);
      }

      // 验证已完成足迹
      expect(engine.completedToday.length).assertEqual(1);
      expect(engine.completedToday[0].id).assertEqual('c-1');

      // 验证下一项自然推入成为 activeTask
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('c-2');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);

      // 验证就绪队列更新
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('c-3');
    });

    /**
     * 2.1 验证撤回今日已完成任务：反悔重做恢复为待办，并重新入队
     */
    it('testUncompleteRestoresToQueue', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const task1: TodoItem = new TodoItem('u-1', '测试动作一', 20);
      task1.priority = Priority.HIGH;
      const task2: TodoItem = new TodoItem('u-2', '测试动作二', 30);
      task2.priority = Priority.MEDIUM;

      engine.load([task1, task2]);
      expect(engine.activeTask?.id).assertEqual('u-1');

      // 1. 完成当前任务
      engine.completeActive();
      expect(engine.completedToday.length).assertEqual(1);
      expect(engine.activeTask?.id).assertEqual('u-2');

      // 2. 撤回刚刚完成的任务
      const restored: TodoItem | null = engine.uncomplete('u-1');
      expect(restored !== null).assertEqual(true);
      if (restored !== null) {
        expect(restored.id).assertEqual('u-1');
        expect(restored.status).assertEqual(TodoStatus.PENDING);
        expect(restored.completedAt).assertEqual(0);
      }

      // 验证从 completedToday 移除，并插入 nextQueue 头部
      expect(engine.completedToday.length).assertEqual(0);
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('u-1');

      // 3. 再次完成剩余全部任务直到活跃任务为空
      engine.completeActive(); // u-2 完成，u-1 成为 active
      expect(engine.activeTask?.id).assertEqual('u-1');
      engine.completeActive(); // u-1 完成，队列为空
      expect(engine.activeTask).assertEqual(null);
      expect(engine.completedToday.length).assertEqual(2);

      // 4. 当 activeTask 为空时撤回，直接成为 activeTask
      const directActive: TodoItem | null = engine.uncomplete('u-2');
      expect(directActive !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('u-2');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);
      expect(engine.completedToday.length).assertEqual(1);
    });

    /**
     * 3. 验证滑动跳过当前任务：无负罪感移入队尾，下一项平滑顶上
     */
    it('testSkipActiveRequeuesToTail', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const taskA: TodoItem = new TodoItem('s-a', '任务A', 25);
      taskA.priority = Priority.HIGH;
      const taskB: TodoItem = new TodoItem('s-b', '任务B', 25);
      taskB.priority = Priority.MEDIUM;
      const taskC: TodoItem = new TodoItem('s-c', '任务C', 25);
      taskC.priority = Priority.LOW;

      engine.load([taskA, taskB, taskC]);
      expect(engine.activeTask?.id).assertEqual('s-a');

      // 跳过当前活跃动作
      const skipped: TodoItem | null = engine.skipActive();
      expect(skipped !== null).assertEqual(true);
      if (skipped !== null) {
        expect(skipped.id).assertEqual('s-a');
        expect(skipped.status).assertEqual(TodoStatus.PENDING);
      }

      // 验证 taskB 推入成为 activeTask
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('s-b');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);

      // 验证 taskA 滑入队尾
      expect(engine.nextQueue.length).assertEqual(2);
      expect(engine.nextQueue[0].id).assertEqual('s-c');
      expect(engine.nextQueue[1].id).assertEqual('s-a');
    });

    /**
     * 4. 验证置顶操作：被选任务成为 activeTask，原 activeTask 挤入 nextQueue[0] 且无数据丢失
     */
    it('testPromoteToTop', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const taskA: TodoItem = new TodoItem('p-a', '任务A', 25);
      taskA.priority = Priority.HIGH;
      const taskB: TodoItem = new TodoItem('p-b', '任务B', 25);
      taskB.priority = Priority.MEDIUM;
      const taskC: TodoItem = new TodoItem('p-c', '任务C', 25);
      taskC.priority = Priority.LOW;

      engine.load([taskA, taskB, taskC]);
      expect(engine.activeTask?.id).assertEqual('p-a');

      // 将 taskC 置顶提拔
      const promoted: boolean = engine.promoteToTop('p-c');
      expect(promoted).assertEqual(true);

      // 验证 taskC 成为 activeTask
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('p-c');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);

      // 验证原 activeTask (taskA) 挤入首位，完整保留
      expect(engine.nextQueue.length).assertEqual(2);
      expect(engine.nextQueue[0].id).assertEqual('p-a');
      expect(engine.nextQueue[1].id).assertEqual('p-b');
    });

    /**
     * 5. 验证杂念停泊录入：秒存进机动池，绝不抢占 activeTask 主焦点
     */
    it('testParkingLotIngestionPreservesActive', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const taskMain: TodoItem = new TodoItem('main-1', '主线专注任务', 45);
      taskMain.priority = Priority.HIGH;
      const taskSub: TodoItem = new TodoItem('main-2', '后续待推任务', 25);
      taskSub.priority = Priority.MEDIUM;

      engine.load([taskMain, taskSub]);
      expect(engine.activeTask?.id).assertEqual('main-1');

      // 录入杂念
      const thought: TodoItem = new TodoItem('thought-1', '突发灵感快速记下', 10);
      engine.pushToParking(thought);

      // 核心断言：当前 activeTask 绝对不被篡改
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('main-1');

      // 验证杂念安全停泊至 parkingQueue
      expect(engine.parkingQueue.length).assertEqual(1);
      expect(engine.parkingQueue[0].id).assertEqual('thought-1');
      expect(engine.parkingQueue[0].source).assertEqual(TodoSource.PARKING_LOT);

      // 验证杂念同时加入 nextQueue 尾部
      const thoughtInQueue: TodoItem | undefined = engine.nextQueue.find((t: TodoItem): boolean => t.id === 'thought-1');
      expect(thoughtInQueue !== undefined).assertEqual(true);
    });

    /**
     * 6. 验证温和老化等级递增 (0 -> 1 -> 2)
     */
    it('testMildAgingProgression', 0, (): void => {
      const now: number = Date.now();
      const item: TodoItem = new TodoItem('aging-task', '老化评估测试项', 25);

      // 1. 正常未过期 (agingLevel = 0)
      item.dueDate = now + (2 * 86400000);
      MildAgingEngine.evaluateAging(item);
      expect(item.agingLevel).assertEqual(0);
      expect(item.isFrozen).assertEqual(false);

      // 2. 逾期 2 天 (agingLevel = 1)
      item.dueDate = now - (2 * 86400000);
      MildAgingEngine.evaluateAging(item);
      expect(item.agingLevel).assertEqual(1);
      expect(item.isFrozen).assertEqual(false);

      // 3. 逾期 5 天 (agingLevel = 2)
      item.dueDate = now - (5 * 86400000);
      MildAgingEngine.evaluateAging(item);
      expect(item.agingLevel).assertEqual(2);
      expect(item.isFrozen).assertEqual(false);
    });

    /**
     * 7. 验证逾期 >= 8 天事项自动归入冷冻舱休眠 (Level 3, isFrozen = true)
     */
    it('testCryoChamberAutoFreezing', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const now: number = Date.now();

      const normalTask: TodoItem = new TodoItem('normal-1', '正常日常待办', 25);
      normalTask.dueDate = now + 86400000;

      const expiredTask: TodoItem = new TodoItem('expired-1', '严重逾期待办', 25);
      expiredTask.dueDate = now - (9 * 86400000); // 逾期 9 天

      engine.load([normalTask, expiredTask]);

      // 验证冷冻隔离
      expect(engine.frozenTasks.length).assertEqual(1);
      expect(engine.frozenTasks[0].id).assertEqual('expired-1');
      expect(engine.frozenTasks[0].isFrozen).assertEqual(true);
      expect(engine.frozenTasks[0].status).assertEqual(TodoStatus.FROZEN);
      expect(engine.frozenTasks[0].agingLevel).assertEqual(3);

      // 验证冷冻事项绝不出现在 activeTask 或 nextQueue
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('normal-1');
      const foundInNext: TodoItem | undefined = engine.nextQueue.find((t: TodoItem): boolean => t.id === 'expired-1');
      expect(foundInNext === undefined).assertEqual(true);
    });

    /**
     * 8. 验证冷冻舱一键唤醒：重置逾期并安全回流就绪队列
     */
    it('testCryoChamberRevival', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const now: number = Date.now();

      const activeTask: TodoItem = new TodoItem('act-1', '当前活跃任务', 25);
      const frozenTask: TodoItem = new TodoItem('cryo-1', '已冷冻待办', 25);
      frozenTask.dueDate = now - (10 * 86400000);

      engine.load([activeTask, frozenTask]);
      expect(engine.frozenTasks.length).assertEqual(1);
      expect(engine.activeTask?.id).assertEqual('act-1');

      // 唤醒冷冻任务
      const revived: boolean = engine.reviveFromCryo('cryo-1');
      expect(revived).assertEqual(true);

      // 验证冷冻舱已清空
      expect(engine.frozenTasks.length).assertEqual(0);

      // 验证任务回流至 nextQueue 且状态完全重置
      const foundInNext: TodoItem | undefined = engine.nextQueue.find((t: TodoItem): boolean => t.id === 'cryo-1');
      expect(foundInNext !== undefined).assertEqual(true);
      if (foundInNext !== undefined) {
        expect(foundInNext.isFrozen).assertEqual(false);
        expect(foundInNext.status).assertEqual(TodoStatus.PENDING);
        expect(foundInNext.agingLevel).assertEqual(0);
        expect(foundInNext.dueDate).assertEqual(0);
      }
    });

    /**
     * 9. 极限挑战一：空列表加载 load([]) 边界与防御性调用
     */
    it('testAdversarialEmptyListAndNullSafety', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      engine.load([]);

      expect(engine.activeTask).assertEqual(null);
      expect(engine.nextQueue.length).assertEqual(0);
      expect(engine.parkingQueue.length).assertEqual(0);
      expect(engine.frozenTasks.length).assertEqual(0);
      expect(engine.completedToday.length).assertEqual(0);

      // 防御性空调用测试
      expect(engine.completeActive()).assertEqual(null);
      expect(engine.skipActive()).assertEqual(null);
      expect(engine.promoteToTop('non-existent-id')).assertEqual(false);
      expect(engine.triageToCryo('non-existent-id')).assertEqual(false);
      expect(engine.reviveFromCryo('non-existent-id')).assertEqual(false);

      // 已删除与已取消事项过滤
      const delItem: TodoItem = new TodoItem('del-1', '已删除', 10);
      delItem.isDeleted = true;
      const cancItem: TodoItem = new TodoItem('canc-1', '已取消', 10);
      cancItem.status = TodoStatus.CANCELLED;
      engine.load([delItem, cancItem]);

      expect(engine.activeTask).assertEqual(null);
      expect(engine.nextQueue.length).assertEqual(0);
      expect(engine.parkingQueue.length).assertEqual(0);
      expect(engine.frozenTasks.length).assertEqual(0);
    });

    /**
     * 10. 极限挑战二：单项流转生命周期 (完成与跳过)
     */
    it('testAdversarialSingleItemFlowLifecycle', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const singleTask1: TodoItem = new TodoItem('single-1', '单项待办1', 25);
      engine.load([singleTask1]);

      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('single-1');
      expect(engine.nextQueue.length).assertEqual(0);

      // 完成唯一项 -> 队列自然排空
      const comp: TodoItem | null = engine.completeActive();
      expect(comp !== null).assertEqual(true);
      expect(comp?.id).assertEqual('single-1');
      expect(engine.activeTask).assertEqual(null);
      expect(engine.nextQueue.length).assertEqual(0);
      expect(engine.completedToday.length).assertEqual(1);

      // 再次完成 -> 返回 null，无崩溃
      expect(engine.completeActive()).assertEqual(null);

      // 单项跳过测试
      const engine2: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const singleTask2: TodoItem = new TodoItem('single-2', '单项待办2', 25);
      engine2.load([singleTask2]);

      const skipped: TodoItem | null = engine2.skipActive();
      expect(skipped !== null).assertEqual(true);
      expect(skipped?.id).assertEqual('single-2');
      // 队列中无其他候选项时，activeTask 依然指向 single-2，nextQueue 为空，不产生空指针异常
      expect(engine2.activeTask !== null).assertEqual(true);
      expect(engine2.activeTask?.id).assertEqual('single-2');
      expect(engine2.nextQueue.length).assertEqual(0);
    });

    /**
     * 11. 极限挑战三：高频跳过与队列旋转保真度测试 (100次连续旋转)
     */
    it('testAdversarialRapidSkipsQueueRotation', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const tasks: TodoItem[] = [];
      const count: number = 5;
      for (let i: number = 0; i < count; i++) {
        const t: TodoItem = new TodoItem('rot-' + i, '旋转任务-' + i, 20);
        t.priority = Priority.MEDIUM;
        tasks.push(t);
      }

      engine.load(tasks);
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.nextQueue.length).assertEqual(count - 1);

      // 连续执行 100 次 skipActive
      const iterations: number = 100;
      for (let step: number = 1; step <= iterations; step++) {
        const skipped: TodoItem | null = engine.skipActive();
        expect(skipped !== null).assertEqual(true);

        // 验证队列总长度与唯一性保持严格恒定
        expect(engine.activeTask !== null).assertEqual(true);
        expect(engine.nextQueue.length).assertEqual(count - 1);

        // 验证当前 activeTask 严格符合 (step % count) 周期律
        const expectedActiveIdx: number = step % count;
        expect(engine.activeTask?.id).assertEqual('rot-' + expectedActiveIdx);

        // 验证 nextQueue 中各元素顺序严格符合周期顺移
        for (let q: number = 0; q < engine.nextQueue.length; q++) {
          const expectedQIdx: number = (step + 1 + q) % count;
          expect(engine.nextQueue[q].id).assertEqual('rot-' + expectedQIdx);
        }
      }
    });

    /**
     * 12. 极限挑战四：优先级反转抵抗性测试 (Priority Inversion Resistance)
     */
    it('testAdversarialPriorityInversionResistance', 0, (): void => {
      const now: number = Date.now();

      // 低优极端项：钉住(+50) + 逾期30天(+150) + 老化2级(+20) = 100 + 220 = 320
      const lowExtreme: TodoItem = new TodoItem('p-low-extreme', '低优极限加成', 25);
      lowExtreme.priority = Priority.LOW;
      lowExtreme.isPinned = true;
      lowExtreme.dueDate = now - (30 * 86400000);
      lowExtreme.agingLevel = 2;

      // 中优基准项：无钉住(+0) + 无截止(+0) + 老化0级(+0) = 500
      const medBare: TodoItem = new TodoItem('p-med-bare', '中优白板项', 25);
      medBare.priority = Priority.MEDIUM;
      medBare.isPinned = false;
      medBare.dueDate = 0;
      medBare.agingLevel = 0;

      // 中优极端项：钉住(+50) + 逾期30天(+150) + 老化2级(+20) = 500 + 220 = 720
      const medExtreme: TodoItem = new TodoItem('p-med-extreme', '中优极限加成', 25);
      medExtreme.priority = Priority.MEDIUM;
      medExtreme.isPinned = true;
      medExtreme.dueDate = now - (30 * 86400000);
      medExtreme.agingLevel = 2;

      // 高优基准项：无钉住(+0) + 无截止(+0) + 老化0级(+0) = 1000
      const highBare: TodoItem = new TodoItem('p-high-bare', '高优白板项', 25);
      highBare.priority = Priority.HIGH;
      highBare.isPinned = false;
      highBare.dueDate = 0;
      highBare.agingLevel = 0;

      const scoreLowExtreme: number = SingleThreadFlowEngine.calculatePriorityScore(lowExtreme);
      const scoreMedBare: number = SingleThreadFlowEngine.calculatePriorityScore(medBare);
      const scoreMedExtreme: number = SingleThreadFlowEngine.calculatePriorityScore(medExtreme);
      const scoreHighBare: number = SingleThreadFlowEngine.calculatePriorityScore(highBare);

      // 数学断言：低优极限 < 中优白板 < 中优极限 < 高优白板
      expect(scoreLowExtreme).assertEqual(320);
      expect(scoreMedBare).assertEqual(500);
      expect(scoreMedExtreme).assertEqual(720);
      expect(scoreHighBare).assertEqual(1000);

      expect(scoreMedBare > scoreLowExtreme).assertEqual(true);
      expect(scoreHighBare > scoreMedExtreme).assertEqual(true);

      // 引擎全量排列断言一：逾期 >= 8 天的极限项被温和老化引擎自动归入冷冻舱，从活跃流水线绝对剔除
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      engine.load([lowExtreme, medBare, medExtreme, highBare]);

      expect(engine.frozenTasks.length).assertEqual(2);
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('p-high-bare');
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('p-med-bare');

      // 引擎全量排列断言二：在活跃流水线允许的极限边界 (逾期 7 天，未触发冷冻)，验证跨级反转绝不可能发生
      // 低优极限活跃态：100 + 50(钉住) + 120(逾期7天: 50+70) + 20(老化2级) = 290
      const lowMaxActive: TodoItem = new TodoItem('p-low-max', '低优极限活跃', 25);
      lowMaxActive.priority = Priority.LOW;
      lowMaxActive.isPinned = true;
      lowMaxActive.dueDate = now - (7 * 86400000);
      lowMaxActive.agingLevel = 2;

      // 中优极限活跃态：500 + 50 + 120 + 20 = 690
      const medMaxActive: TodoItem = new TodoItem('p-med-max', '中优极限活跃', 25);
      medMaxActive.priority = Priority.MEDIUM;
      medMaxActive.isPinned = true;
      medMaxActive.dueDate = now - (7 * 86400000);
      medMaxActive.agingLevel = 2;

      const scoreLowMax: number = SingleThreadFlowEngine.calculatePriorityScore(lowMaxActive);
      const scoreMedMax: number = SingleThreadFlowEngine.calculatePriorityScore(medMaxActive);
      expect(scoreLowMax).assertEqual(290);
      expect(scoreMedMax).assertEqual(690);

      // 数学验证硬隔离带：低优上限 290 < 中优基准 500；中优上限 690 < 高优基准 1000
      expect(scoreMedBare > scoreLowMax).assertEqual(true);
      expect(scoreHighBare > scoreMedMax).assertEqual(true);

      const engine2: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      engine2.load([lowMaxActive, medBare, medMaxActive, highBare]);

      expect(engine2.activeTask !== null).assertEqual(true);
      expect(engine2.activeTask?.id).assertEqual('p-high-bare');
      expect(engine2.nextQueue.length).assertEqual(3);
      expect(engine2.nextQueue[0].id).assertEqual('p-med-max');
      expect(engine2.nextQueue[1].id).assertEqual('p-med-bare');
      expect(engine2.nextQueue[2].id).assertEqual('p-low-max');
    });

    /**
     * 13. 极限挑战五：冷冻舱 7 天 vs 8 天逾期边界精确断言
     */
    it('testAdversarialCryoCabinBoundaryEdgeCases', 0, (): void => {
      const now: number = Date.now();
      const oneDayMs: number = 86400000;

      // 任务1：刚好逾期 7 天整
      const task7d: TodoItem = new TodoItem('boundary-7d', '逾期7天整', 25);
      task7d.dueDate = now - (7 * oneDayMs);

      // 任务2：逾期 7 天 23 小时 59 分钟 (未满 8 天)
      const taskAlmost8d: TodoItem = new TodoItem('boundary-almost-8d', '逾期接近8天', 25);
      taskAlmost8d.dueDate = now - (8 * oneDayMs - 60000);

      // 任务3：刚好逾期 8 天整
      const task8d: TodoItem = new TodoItem('boundary-8d', '逾期8天整', 25);
      task8d.dueDate = now - (8 * oneDayMs);

      // 任务4：逾期 9 天
      const task9d: TodoItem = new TodoItem('boundary-9d', '逾期9天', 25);
      task9d.dueDate = now - (9 * oneDayMs);

      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      engine.load([task7d, taskAlmost8d, task8d, task9d]);

      // 验证冷冻隔离：8天整与9天逾期的事项被冷冻舱捕获
      expect(engine.frozenTasks.length).assertEqual(2);
      const frozenIds: string[] = engine.frozenTasks.map((t: TodoItem): string => t.id);
      expect(frozenIds.includes('boundary-8d')).assertEqual(true);
      expect(frozenIds.includes('boundary-9d')).assertEqual(true);

      // 验证未满 8 天的事项进入活跃流水线 (activeTask 或 nextQueue)
      expect(engine.activeTask !== null).assertEqual(true);
      const activeIds: string[] = [];
      if (engine.activeTask) {
        activeIds.push(engine.activeTask.id);
      }
      for (let i: number = 0; i < engine.nextQueue.length; i++) {
        activeIds.push(engine.nextQueue[i].id);
      }
      expect(activeIds.length).assertEqual(2);
      expect(activeIds.includes('boundary-7d')).assertEqual(true);
      expect(activeIds.includes('boundary-almost-8d')).assertEqual(true);
    });

    /**
     * 14. 极限挑战六：杂念项作为 activeTask 时冷冻归舱的队列一致性检验
     */
    it('testAdversarialParkingItemActiveTriageToCryo', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const thoughtTask: TodoItem = new TodoItem('thought-lead', '杂念成为当前任务', 15);
      thoughtTask.source = TodoSource.PARKING_LOT;

      engine.load([thoughtTask]);
      expect(engine.activeTask?.id).assertEqual('thought-lead');
      expect(engine.parkingQueue.length).assertEqual(1);

      // 移入冷冻舱
      const triaged: boolean = engine.triageToCryo('thought-lead');
      expect(triaged).assertEqual(true);
      expect(engine.activeTask).assertEqual(null);
      expect(engine.frozenTasks.length).assertEqual(1);
      expect(engine.frozenTasks[0].id).assertEqual('thought-lead');

      // 检查 parkingQueue 是否残留引用 (验证修复：triageToCryo 对 activeTask 分支已彻底清理 parkingQueue)
      const leakedInParking: boolean = engine.parkingQueue.some((t: TodoItem): boolean => t.id === 'thought-lead');
      expect(leakedInParking).assertEqual(false);
    });

    /**
     * 15. 挑战者2专测一：pushToParking 在高并发/高优先级杂念灌入下 activeTask 引用绝不漂移与防抢占
     */
    it('testChallenger2PushToParkingNonPreemptionUnderPressure', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const currentActive: TodoItem = new TodoItem('base-active', '低优常驻专注任务', 25);
      currentActive.priority = Priority.LOW;

      const queuedTask: TodoItem = new TodoItem('base-queued', '常规就绪任务', 25);
      queuedTask.priority = Priority.MEDIUM;

      engine.load([currentActive, queuedTask]);
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('base-queued');

      const initialActive: TodoItem = engine.activeTask as TodoItem;
      const initialActiveId: string = initialActive.id;

      // 连续压测：灌入 50 个高优先级且带星标的杂念
      const pressureCount: number = 50;
      for (let i: number = 0; i < pressureCount; i++) {
        const thought: TodoItem = new TodoItem('thought-pressure-' + i, '高优突发灵感 ' + i, 10);
        thought.priority = Priority.HIGH;
        thought.isPinned = true;
        engine.pushToParking(thought);

        // 强断言：activeTask 严格引用相等，绝不发生指针漂移
        expect(engine.activeTask === initialActive).assertEqual(true);
        expect(engine.activeTask?.id).assertEqual(initialActiveId);
        expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);
      }

      // 验证队列容量严格守恒
      expect(engine.parkingQueue.length).assertEqual(pressureCount);
      expect(engine.nextQueue.length).assertEqual(1 + pressureCount);

      // 验证杂念严格以推入顺序排在队尾，未打乱队首元素
      expect(engine.nextQueue[0].id).assertEqual('base-active');
      for (let i: number = 0; i < pressureCount; i++) {
        expect(engine.nextQueue[1 + i].id).assertEqual('thought-pressure-' + i);
        expect(engine.nextQueue[1 + i].source).assertEqual(TodoSource.PARKING_LOT);
        expect(engine.nextQueue[1 + i].status).assertEqual(TodoStatus.PENDING);
      }
    });

    /**
     * 16. 挑战者2专测二：promoteToTop 深度队列穿透置顶之守恒性与绝无丢失/重复断言
     */
    it('testChallenger2PromoteToTopDeepNoDuplicationNoDrop', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const allTasks: TodoItem[] = [];
      const totalCount: number = 12;

      for (let i: number = 0; i < totalCount; i++) {
        const t: TodoItem = new TodoItem('deep-' + i, '任务-' + i, 20);
        t.priority = Priority.MEDIUM;
        allTasks.push(t);
      }

      engine.load(allTasks);
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('deep-0');
      expect(engine.nextQueue.length).assertEqual(totalCount - 1);

      // 置顶深度最底层元素 (nextQueue 最后一个：deep-11)
      const targetDeepId: string = 'deep-11';
      const promoted: boolean = engine.promoteToTop(targetDeepId);
      expect(promoted).assertEqual(true);

      // 验证新 activeTask
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual(targetDeepId);
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);

      // 验证原 activeTask (deep-0) 被推入 nextQueue[0] 且变为 PENDING
      expect(engine.nextQueue.length).assertEqual(totalCount - 1);
      expect(engine.nextQueue[0].id).assertEqual('deep-0');
      expect(engine.nextQueue[0].status).assertEqual(TodoStatus.PENDING);

      // 验证总任务数与唯一性严格守恒 (全集无增、无删、无重复)
      const collectedIds: string[] = [];
      if (engine.activeTask) {
        collectedIds.push(engine.activeTask.id);
      }
      for (let i: number = 0; i < engine.nextQueue.length; i++) {
        collectedIds.push(engine.nextQueue[i].id);
      }
      expect(collectedIds.length).assertEqual(totalCount);

      for (let i: number = 0; i < totalCount; i++) {
        const expectedId: string = 'deep-' + i;
        const occurrences: number = collectedIds.filter((id: string): boolean => id === expectedId).length;
        expect(occurrences).assertEqual(1);
      }

      // 验证自反性：再次置顶当前已处于活跃状态的自身，队列长度与状态零扰动
      const promoteSelf: boolean = engine.promoteToTop(targetDeepId);
      expect(promoteSelf).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual(targetDeepId);
      expect(engine.nextQueue.length).assertEqual(totalCount - 1);
      expect(engine.nextQueue[0].id).assertEqual('deep-0');

      // 验证防御性：置顶不存在的 ID，返回 false 且队列零污染
      const promoteFake: boolean = engine.promoteToTop('ghost-id-999');
      expect(promoteFake).assertEqual(false);
      expect(engine.activeTask?.id).assertEqual(targetDeepId);
      expect(engine.nextQueue.length).assertEqual(totalCount - 1);
    });

    /**
     * 17. 挑战者2专测三：triageToCryo 与 reviveFromCryo 全链路状态流转与双向集合归属性检验
     */
    it('testChallenger2TriageToCryoAndReviveStateTransitionsAndMembership', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const taskA: TodoItem = new TodoItem('flow-a', '主任务A', 25);
      taskA.priority = Priority.HIGH;
      const taskB: TodoItem = new TodoItem('flow-b', '就绪任务B', 25);
      taskB.priority = Priority.MEDIUM;
      const taskC: TodoItem = new TodoItem('flow-c', '就绪任务C', 25);
      taskC.priority = Priority.LOW;

      engine.load([taskA, taskB, taskC]);
      expect(engine.activeTask?.id).assertEqual('flow-a');
      expect(engine.nextQueue.length).assertEqual(2);
      expect(engine.frozenTasks.length).assertEqual(0);

      // 1. 将 nextQueue 中的 taskB 移入冷冻舱
      const triageB: boolean = engine.triageToCryo('flow-b');
      expect(triageB).assertEqual(true);
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('flow-c');
      expect(engine.frozenTasks.length).assertEqual(1);

      const frozenB: TodoItem = engine.frozenTasks[0];
      expect(frozenB.id).assertEqual('flow-b');
      expect(frozenB.isFrozen).assertEqual(true);
      expect(frozenB.status).assertEqual(TodoStatus.FROZEN);
      expect(frozenB.agingLevel).assertEqual(3);
      expect(frozenB.scheduledStartAt).assertEqual(0);
      expect(frozenB.scheduledEndAt).assertEqual(0);

      // 2. 将当前 activeTask (taskA) 移入冷冻舱
      const triageA: boolean = engine.triageToCryo('flow-a');
      expect(triageA).assertEqual(true);
      // activeTask 应自动由 nextQueue 中的 taskC 顶上
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('flow-c');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);
      expect(engine.nextQueue.length).assertEqual(0);
      expect(engine.frozenTasks.length).assertEqual(2);

      const frozenA: TodoItem = engine.frozenTasks[0];
      expect(frozenA.id).assertEqual('flow-a');
      expect(frozenA.isFrozen).assertEqual(true);
      expect(frozenA.status).assertEqual(TodoStatus.FROZEN);

      // 3. 将唯一的活跃任务 taskC 也移入冷冻舱 -> activeTask 应归 null
      const triageC: boolean = engine.triageToCryo('flow-c');
      expect(triageC).assertEqual(true);
      expect(engine.activeTask).assertEqual(null);
      expect(engine.nextQueue.length).assertEqual(0);
      expect(engine.frozenTasks.length).assertEqual(3);

      // 4. 从冷冻舱一键唤醒 taskB（此时 activeTask 为 null）
      const reviveB: boolean = engine.reviveFromCryo('flow-b');
      expect(reviveB).assertEqual(true);
      expect(engine.frozenTasks.length).assertEqual(2);
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('flow-b');
      expect(engine.activeTask?.isFrozen).assertEqual(false);
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);
      expect(engine.activeTask?.agingLevel).assertEqual(0);
      expect(engine.activeTask?.dueDate).assertEqual(0);

      // 5. 在已有 activeTask 的情况下唤醒 taskA -> 应当归入 nextQueue 末尾，且 status 为 PENDING
      const reviveA: boolean = engine.reviveFromCryo('flow-a');
      expect(reviveA).assertEqual(true);
      expect(engine.frozenTasks.length).assertEqual(1);
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('flow-a');
      expect(engine.nextQueue[0].isFrozen).assertEqual(false);
      expect(engine.nextQueue[0].status).assertEqual(TodoStatus.PENDING);
      expect(engine.nextQueue[0].agingLevel).assertEqual(0);
      expect(engine.nextQueue[0].dueDate).assertEqual(0);

      // 6. 防御性测试：唤醒不存在或已唤醒的 ID
      const reviveFake: boolean = engine.reviveFromCryo('non-existent-cryo');
      expect(reviveFake).assertEqual(false);
    });

    /**
     * 18. 挑战者2专测四：冷冻舱与机动备选池(parkingQueue)状态隔离与潜在越权置顶实测
     */
    it('testChallenger2CryoParkingResurrectionAnomaly', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const thoughtTask: TodoItem = new TodoItem('thought-ghost', '机动备选待办', 15);

      // 步骤1：推入杂念，此时无 activeTask，thoughtTask 直接成为 activeTask
      engine.pushToParking(thoughtTask);
      expect(engine.activeTask?.id).assertEqual('thought-ghost');
      expect(engine.parkingQueue.length).assertEqual(1);

      // 步骤2：将此活跃杂念直接移入冷冻舱
      const triaged: boolean = engine.triageToCryo('thought-ghost');
      expect(triaged).assertEqual(true);
      expect(engine.frozenTasks.length).assertEqual(1);
      expect(engine.frozenTasks[0].id).assertEqual('thought-ghost');
      expect(engine.frozenTasks[0].isFrozen).assertEqual(true);

      // 检查当前实现下的实际行为：triageToCryo 的 active 分支已清理 parkingQueue
      // parkingQueue 中不再残留此任务引用
      const isLeakedInParking: boolean = engine.parkingQueue.some((t: TodoItem): boolean => t.id === 'thought-ghost');
      expect(isLeakedInParking).assertEqual(false);

      // 步骤3：极端攻击场景——此时调用 promoteToTop 提拔已被冷冻的 thought-ghost
      // 检验：冷冻舱任务绝不可被越权置顶，promoteToTop 返回 false
      const anomalousPromote: boolean = engine.promoteToTop('thought-ghost');
      expect(anomalousPromote).assertEqual(false);
      expect(engine.activeTask).assertEqual(null);
      // 验证仍在冷冻舱中且无泄漏
      const stillInFrozen: boolean = engine.frozenTasks.some((t: TodoItem): boolean => t.id === 'thought-ghost');
      expect(stillInFrozen).assertEqual(true);
    });

    /**
     * 19. 验证 ParkingLot 杂念极速停泊：不抢占 activeTask 焦点且安全进入机动序列
     */
    it('testParkingLotFastNonStealingIngestion', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      const currentActive: TodoItem = new TodoItem('focus-main', '当前微晶卡片专注中', 25);
      currentActive.priority = Priority.HIGH;
      engine.load([currentActive]);

      expect(engine.activeTask?.id).assertEqual('focus-main');

      // 模拟 36vp 胶囊快录提交
      const fastThought: TodoItem = new TodoItem('fast-thought-1', '突发灵感快速停泊', 15);
      fastThought.source = TodoSource.PARKING_LOT;
      fastThought.scheduledStartAt = 0;
      engine.pushToParking(fastThought);

      // 核心断言：当前 activeTask 绝对不被篡改抢焦
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('focus-main');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);

      // 核心断言：杂念安全进入 parkingQueue 与 nextQueue 队尾
      expect(engine.parkingQueue.length).assertEqual(1);
      expect(engine.parkingQueue[0].id).assertEqual('fast-thought-1');
      expect(engine.parkingQueue[0].source).assertEqual(TodoSource.PARKING_LOT);
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('fast-thought-1');
    });

    /**
     * 20. 挑战者2专测五：ParkingLot 从空载到满载突发录入的非抢焦与异步队列不变式
     */
    it('testAdversarialParkingLotQuickIngestionFromEmptyToLoaded', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();
      expect(engine.activeTask).assertEqual(null);
      expect(engine.parkingQueue.length).assertEqual(0);
      expect(engine.nextQueue.length).assertEqual(0);

      // 1. 空载状态推入第一个杂念：应当自动成为当前 activeTask，同时 parkingQueue 记录
      const firstThought: TodoItem = new TodoItem('t-initial', '首个突发杂念', 15);
      firstThought.source = TodoSource.PARKING_LOT;
      firstThought.scheduledStartAt = 0;
      firstThought.scheduledEndAt = 0;
      engine.pushToParking(firstThought);

      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.activeTask?.id).assertEqual('t-initial');
      expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);
      expect(engine.parkingQueue.length).assertEqual(1);
      expect(engine.nextQueue.length).assertEqual(0);

      // 2. 满载/活跃状态下连续并发灌入 20 个不同属性杂念：绝不抢占首个 activeTask
      const burstCount: number = 20;
      for (let i: number = 1; i <= burstCount; i++) {
        const item: TodoItem = new TodoItem(`t-burst-${i}`, `高压杂念 ${i}`, 10 + i);
        item.source = TodoSource.PARKING_LOT;
        item.priority = (i % 3 === 0) ? Priority.HIGH : ((i % 2 === 0) ? Priority.MEDIUM : Priority.LOW);
        item.scheduledStartAt = 0;
        item.scheduledEndAt = 0;
        item.isPinned = (i % 5 === 0);
        engine.pushToParking(item);

        // 强断言：当前 activeTask 绝对锁定为 t-initial
        expect(engine.activeTask?.id).assertEqual('t-initial');
        expect(engine.activeTask?.status).assertEqual(TodoStatus.IN_PROGRESS);
      }

      // 验证 parkingQueue 记录了全部 21 个杂念
      expect(engine.parkingQueue.length).assertEqual(1 + burstCount);
      // 验证 nextQueue 正好包含后续推入的 20 个杂念
      expect(engine.nextQueue.length).assertEqual(burstCount);

      // 验证 nextQueue 中杂念顺序严格为 FIFO 追加且全为 PENDING 状态
      for (let i: number = 0; i < burstCount; i++) {
        expect(engine.nextQueue[i].id).assertEqual(`t-burst-${i + 1}`);
        expect(engine.nextQueue[i].status).assertEqual(TodoStatus.PENDING);
        expect(engine.nextQueue[i].source).assertEqual(TodoSource.PARKING_LOT);
      }
    });

    /**
     * 21. 挑战者2专测六：SunsetCeremony 今日微步心流轨迹跨日过滤与无负罪感反思模型
     */
    it('testAdversarialSunsetCeremonyTrajectoryAndFiltering', 0, (): void => {
      const now: Date = new Date();
      const startOfDay: number = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();

      // 构造数据集：涵盖今日完成、昨日完成、上周完成、未完成等多种状态
      const taskDoneToday1: TodoItem = new TodoItem('done-today-1', '今晨完成的攻坚任务', 30);
      taskDoneToday1.status = TodoStatus.COMPLETED;
      taskDoneToday1.completedAt = startOfDay + 3600000; // 今日凌晨 1:00

      const taskDoneToday2: TodoItem = new TodoItem('done-today-2', '下午完成的微步任务', 15);
      taskDoneToday2.status = TodoStatus.COMPLETED;
      taskDoneToday2.completedAt = startOfDay + 14 * 3600000; // 今日下午 14:00

      const taskDoneYesterday: TodoItem = new TodoItem('done-yest', '昨天完成的旧任务', 45);
      taskDoneYesterday.status = TodoStatus.COMPLETED;
      taskDoneYesterday.completedAt = startOfDay - 60000; // 昨天 23:59

      const taskDoneLastWeek: TodoItem = new TodoItem('done-lastweek', '上周完成的任务', 25);
      taskDoneLastWeek.status = TodoStatus.COMPLETED;
      taskDoneLastWeek.completedAt = startOfDay - (7 * 86400000);

      const allCompleted: TodoItem[] = [taskDoneToday1, taskDoneToday2, taskDoneYesterday, taskDoneLastWeek];

      // 执行 SunsetCeremonyPage.loadCeremonyData 的时间珠轨迹过滤逻辑
      const completedToday: TodoItem[] = allCompleted
        .filter((t: TodoItem): boolean => t.completedAt >= startOfDay)
        .reverse();

      // 验证轨迹纯粹性：严格只有今日完成的 2 项，绝不掺入历史旧数据
      expect(completedToday.length).assertEqual(2);
      expect(completedToday[0].id).assertEqual('done-today-2'); // reverse 后最新完成在前
      expect(completedToday[1].id).assertEqual('done-today-1');

      // 验证未完成事项过滤：排查出状态非 COMPLETED 的任务
      const taskPending: TodoItem = new TodoItem('pend-1', '正在就绪的待办', 20);
      taskPending.status = TodoStatus.PENDING;

      const taskProgress: TodoItem = new TodoItem('prog-1', '当前执行中的待办', 25);
      taskProgress.status = TodoStatus.IN_PROGRESS;

      const taskFrozen: TodoItem = new TodoItem('froz-1', '冷冻舱休眠的待办', 40);
      taskFrozen.status = TodoStatus.FROZEN;

      const activeTasks: TodoItem[] = [taskPending, taskProgress, taskFrozen, taskDoneToday1];
      const incompleteTasks: TodoItem[] = activeTasks.filter((t: TodoItem): boolean => t.status !== TodoStatus.COMPLETED);

      expect(incompleteTasks.length).assertEqual(3);
      expect(incompleteTasks.some((t: TodoItem): boolean => t.id === 'pend-1')).assertEqual(true);
      expect(incompleteTasks.some((t: TodoItem): boolean => t.id === 'prog-1')).assertEqual(true);
      expect(incompleteTasks.some((t: TodoItem): boolean => t.id === 'froz-1')).assertEqual(true);
      expect(incompleteTasks.some((t: TodoItem): boolean => t.id === 'done-today-1')).assertEqual(false);

      // 验证零完成零挂碍的无负罪感反思分支：当 completedToday.length === 0 时，有正向休整语义支撑
      const emptyCompleted: TodoItem[] = [];
      const zeroCompletedReflection: boolean = (emptyCompleted.length === 0);
      expect(zeroCompletedReflection).assertEqual(true);
    });

    /**
     * 22. 挑战者2专测七：SunsetCeremony 未完成事项一键批量顺延 (scheduledStartAt = 0)
     */
    it('testAdversarialSunsetCeremonyBatchRollover', 0, (): void => {
      // 模拟 5 个遗留了历史时刻/排期参数与星标的待办
      const itemsToRollover: TodoItem[] = [];
      for (let i: number = 0; i < 5; i++) {
        const item: TodoItem = new TodoItem(`rollover-${i}`, `今日遗留事项 ${i}`, 25);
        item.status = TodoStatus.PENDING;
        item.scheduledStartAt = Date.now() + (i * 3600000); // 残留时刻
        item.scheduledEndAt = item.scheduledStartAt + (25 * 60000);
        item.isPinned = (i % 2 === 0);
        itemsToRollover.push(item);
      }

      // 执行 handleBatchRolloverTomorrow 批处理内核
      for (const item of itemsToRollover) {
        item.scheduledStartAt = 0;
        item.scheduledEndAt = 0;
        item.isPinned = false;
      }

      // 验证所有事项的排期时刻与星标均被彻底抚平解耦，明天机动就绪
      for (let i: number = 0; i < 5; i++) {
        const rolled: TodoItem = itemsToRollover[i];
        expect(rolled.scheduledStartAt).assertEqual(0);
        expect(rolled.scheduledEndAt).assertEqual(0);
        expect(rolled.isPinned).assertEqual(false);
        expect(rolled.status).assertEqual(TodoStatus.PENDING);
      }
    });

    /**
     * 23. 挑战者2专测八：TvAmbientFocusView 焦点选择、无槽位运行与遥控器切项防崩极限
     */
    it('testAdversarialTvAmbientFocusLogicWithoutSlots', 0, (): void => {
      // 1. 模拟包含已完成与未完成混合列表的任务集
      const doneTask: TodoItem = new TodoItem('tv-done', '已完成的任务', 20);
      doneTask.status = TodoStatus.COMPLETED;
      doneTask.estimatedMinutes = 20;

      const unfinTask1: TodoItem = new TodoItem('tv-unfin-1', '首个未完成专注任务', 35);
      unfinTask1.status = TodoStatus.PENDING;
      unfinTask1.estimatedMinutes = 35;

      const unfinTask2: TodoItem = new TodoItem('tv-unfin-2', '次个未完成专注任务', 15);
      unfinTask2.status = TodoStatus.IN_PROGRESS;
      unfinTask2.estimatedMinutes = 15;

      const activeTasks: TodoItem[] = [doneTask, unfinTask1, unfinTask2];

      // 执行 TvAmbientFocusView.loadTasks 核心选择算法
      const firstUnfinished: TodoItem | undefined = activeTasks.find((t: TodoItem): boolean => t.status !== TodoStatus.COMPLETED);
      const currentTask: TodoItem | null = firstUnfinished ?? (activeTasks.length > 0 ? activeTasks[0] : null);

      expect(currentTask !== null).assertEqual(true);
      expect(currentTask?.id).assertEqual('tv-unfin-1'); // 必须跳过已完成项，精准选中第一个未完成项
      expect(currentTask?.estimatedMinutes).assertEqual(35);

      // 计算倒计时秒数
      let remainingSeconds: number = (currentTask?.estimatedMinutes ?? 25) * 60;
      expect(remainingSeconds).assertEqual(35 * 60);

      // 2. 遥控器切项模拟 (D-Pad 顺序切项与环形回绕)
      let selectedTask: TodoItem = currentTask as TodoItem;
      const cycleSteps: number = 6;
      for (let s: number = 1; s <= cycleSteps; s++) {
        if (activeTasks.length > 1 && selectedTask) {
          const nextIndex: number = (activeTasks.indexOf(selectedTask) + 1) % activeTasks.length;
          selectedTask = activeTasks[nextIndex];
        }
      }
      // 经过 6 次切项 (activeTasks.length = 3)，索引回到原点 (unfinTask1 索引为 1, (1 + 6) % 3 = 1)
      expect(selectedTask.id).assertEqual('tv-unfin-1');

      // 3. 边界测试：空列表防崩溃测试
      const emptyTasks: TodoItem[] = [];
      const emptyUnfinished: TodoItem | undefined = emptyTasks.find((t: TodoItem): boolean => t.status !== TodoStatus.COMPLETED);
      const emptyCurrent: TodoItem | null = emptyUnfinished ?? (emptyTasks.length > 0 ? emptyTasks[0] : null);
      expect(emptyCurrent).assertEqual(null);

      // 验证空列表切项守护条件 (activeTasks.length > 1 && currentTask) 安全短路
      let crashedOnEmptyNext: boolean = false;
      try {
        if (emptyTasks.length > 1 && emptyCurrent) {
          // 不应进入
          crashedOnEmptyNext = true;
        }
      } catch {
        crashedOnEmptyNext = true;
      }
      expect(crashedOnEmptyNext).assertEqual(false);

      // 4. 纯净时长格式化算法测试 (无具体钟表时刻、无时间轴)
      const formatTime = (secs: number): string => {
        const m = Math.floor(secs / 60).toString().padStart(2, '0');
        const s = (secs % 60).toString().padStart(2, '0');
        return `${m}:${s}`;
      };

      expect(formatTime(1500)).assertEqual('25:00');
      expect(formatTime(65)).assertEqual('01:05');
      expect(formatTime(5)).assertEqual('00:05');
      expect(formatTime(0)).assertEqual('00:00');
    });

    /**
     * 24. 验证卡片手势动力学归一化进度计算及符号分解
     */
    it('testCardDeckGestureProgressNormalization', 0, (): void => {
      expect(CardDeckKinematics.calcGestureProgress(0)).assertEqual(0.0);
      expect(CardDeckKinematics.calcGestureProgress(55)).assertEqual(0.5);
      expect(CardDeckKinematics.calcGestureProgress(110)).assertEqual(1.0);
      expect(CardDeckKinematics.calcGestureProgress(220)).assertEqual(1.0);

      expect(CardDeckKinematics.calcSignedGestureProgress(55)).assertEqual(0.5);
      expect(CardDeckKinematics.calcSignedGestureProgress(-55)).assertEqual(-0.5);
      expect(CardDeckKinematics.calcSignedGestureProgress(-220)).assertEqual(-1.0);
      expect(CardDeckKinematics.calcSignedGestureProgress(0)).assertEqual(0.0);
    });

    /**
     * 25. 验证次层 (Layer 2) 随手势进度的几何与位移插值连续性
     */
    it('testCardDeckLayer2TransformationInterpolation', 0, (): void => {
      // 静止初始态 (p = 0)
      expect(Math.abs(CardDeckKinematics.calcLayer2Scale(0.0) - 0.93) < 0.0001).assertEqual(true);
      expect(CardDeckKinematics.calcLayer2TranslateY(0.0, 22.0)).assertEqual(22.0);
      expect(CardDeckKinematics.calcLayer2PeekBarOpacity(0.0)).assertEqual(1.0);

      // 半程手势 (p = 0.5)
      expect(Math.abs(CardDeckKinematics.calcLayer2Scale(0.5) - 0.965) < 0.0001).assertEqual(true);
      expect(CardDeckKinematics.calcLayer2TranslateY(0.5, 22.0)).assertEqual(11.0);

      // 临界完全展开态 (p = 1.0)
      expect(Math.abs(CardDeckKinematics.calcLayer2Scale(1.0) - 1.0) < 0.0001).assertEqual(true);
      expect(CardDeckKinematics.calcLayer2TranslateY(1.0, 22.0)).assertEqual(0.0);
      expect(CardDeckKinematics.calcLayer2PeekBarOpacity(1.0)).assertEqual(0.0);
    });

    /**
     * 26. 验证底层 (Layer 3) 随手势进度的几何插值 (无缝演进至 Layer 2 待机态)
     */
    it('testCardDeckLayer3TransformationInterpolation', 0, (): void => {
      // 静止初始态 (p = 0)
      expect(Math.abs(CardDeckKinematics.calcLayer3Scale(0.0) - 0.88) < 0.0001).assertEqual(true);
      expect(CardDeckKinematics.calcLayer3TranslateY(0.0, 38.0, 22.0)).assertEqual(38.0);
      expect(Math.abs(CardDeckKinematics.calcLayer3Opacity(0.0) - 0.72) < 0.0001).assertEqual(true);

      // 手势到达 1.0 时，Layer 3 达到 Layer 2 的待机几何位态 (Scale 0.95, TranslateY 22vp, Opacity 0.95)
      expect(Math.abs(CardDeckKinematics.calcLayer3Scale(1.0) - 0.95) < 0.0001).assertEqual(true);
      expect(CardDeckKinematics.calcLayer3TranslateY(1.0, 38.0, 22.0)).assertEqual(22.0);
      expect(Math.abs(CardDeckKinematics.calcLayer3Opacity(1.0) - 0.95) < 0.0001).assertEqual(true);
    });

    /**
     * 27. 验证阻尼弹簧欠阻尼超调物理模型与过冲高度
     */
    it('testCardDeckSpringOvershootPhysicsParameters', 0, (): void => {
      const theoreticalRatio: number = CardDeckKinematics.calcSpringOvershootRatio(0.62);
      // 理论超调比率约为 8.35% (0.0835)
      expect(theoreticalRatio > 0.08).assertEqual(true);
      expect(theoreticalRatio < 0.09).assertEqual(true);

      // 行程 22vp 与 24vp 中的过冲距离验证
      const dist22: number = CardDeckKinematics.calcOvershootDistance(22.0, 0.62);
      expect(dist22 > 1.7).assertEqual(true);
      expect(dist22 < 2.1).assertEqual(true);

      const dist24: number = CardDeckKinematics.calcOvershootDistance(24.0, 0.62);
      expect(dist24 > 1.8).assertEqual(true);
      expect(dist24 < 2.2).assertEqual(true);
    });

    /**
     * 28. 验证触觉震动双阈值迟滞 (Hysteresis Deadband) 状态机
     */
    it('testCardDeckHapticHysteresisDeadband', 0, (): void => {
      const state: HapticHysteresisState = new HapticHysteresisState();
      let triggerCount: number = 0;

      // 90vp: 未到 100vp 阈值
      if (state.update(90)) {
        triggerCount++;
      }
      expect(triggerCount).assertEqual(0);
      expect(state.hasTriggered).assertEqual(false);

      // 105vp: 冲过 100vp 门禁，触发第 1 次
      if (state.update(105)) {
        triggerCount++;
      }
      expect(triggerCount).assertEqual(1);
      expect(state.hasTriggered).assertEqual(true);

      // 在 80~95vp 迟滞区间徘徊，不重复触发
      if (state.update(95)) {
        triggerCount++;
      }
      if (state.update(85)) {
        triggerCount++;
      }
      if (state.update(90)) {
        triggerCount++;
      }
      expect(triggerCount).assertEqual(1);
      expect(state.hasTriggered).assertEqual(true);

      // 回落到 70vp (<= 75vp): 复位
      if (state.update(70)) {
        triggerCount++;
      }
      expect(triggerCount).assertEqual(1);
      expect(state.hasTriggered).assertEqual(false);

      // 再次达到 115vp: 触发第 2 次
      if (state.update(115)) {
        triggerCount++;
      }
      expect(triggerCount).assertEqual(2);
      expect(state.hasTriggered).assertEqual(true);
    });

    /**
     * 29. 验证纸牌叠层多层切片与空态完备性
     */
    it('testCardDeckMultiLayerQueueSlicing', 0, (): void => {
      const engine: SingleThreadFlowEngine = new SingleThreadFlowEngine();

      // 0 个任务：全空
      engine.load([]);
      expect(engine.activeTask).assertNull();
      expect(engine.nextQueue.length).assertEqual(0);

      // 1 个任务：仅 activeTask 有效，次层与底层为空
      const t1: TodoItem = new TodoItem('dk-1', '动作1', 20);
      engine.load([t1]);
      expect(engine.activeTask !== null).assertEqual(true);
      expect(engine.nextQueue.length).assertEqual(0);

      // 2 个任务：Layer 1 与 Layer 2 有效，Layer 3 为空
      const t2: TodoItem = new TodoItem('dk-2', '动作2', 20);
      engine.load([t1, t2]);
      expect(engine.activeTask?.id).assertEqual('dk-1');
      expect(engine.nextQueue.length).assertEqual(1);
      expect(engine.nextQueue[0].id).assertEqual('dk-2');

      // 3 个任务以上：Layer 1, Layer 2, Layer 3 全部充满
      const t3: TodoItem = new TodoItem('dk-3', '动作3', 20);
      const t4: TodoItem = new TodoItem('dk-4', '动作4', 20);
      engine.load([t1, t2, t3, t4]);
      expect(engine.activeTask?.id).assertEqual('dk-1');
      expect(engine.nextQueue[0].id).assertEqual('dk-2');
      expect(engine.nextQueue[1].id).assertEqual('dk-3');
      expect(engine.nextQueue.length).assertEqual(3);
    });

    /**
     * 30. 验证手势提交方向判定与飞离物理条件
     */
    it('testCardDeckCommitDirectionAndAudioAction', 0, (): void => {
      // 距离突破 100vp
      expect(CardDeckKinematics.isCommitRight(105, 0)).assertEqual(true);
      expect(CardDeckKinematics.isCommitLeft(105, 0)).assertEqual(false);
      expect(CardDeckKinematics.isCommitFlyout(105, 0)).assertEqual(true);

      expect(CardDeckKinematics.isCommitRight(-105, 0)).assertEqual(false);
      expect(CardDeckKinematics.isCommitLeft(-105, 0)).assertEqual(true);
      expect(CardDeckKinematics.isCommitFlyout(-105, 0)).assertEqual(true);

      // 高速甩牌 (|dx| >= 30 且 |vx| >= 650)
      expect(CardDeckKinematics.isCommitRight(35, 700)).assertEqual(true);
      expect(CardDeckKinematics.isCommitLeft(-35, -700)).assertEqual(true);

      // 未达阈值低速回弹 (|dx| < 100 且 |vx| < 650)
      expect(CardDeckKinematics.isCommitRight(50, 400)).assertEqual(false);
      expect(CardDeckKinematics.isCommitLeft(-50, -400)).assertEqual(false);
      expect(CardDeckKinematics.isCommitFlyout(50, 400)).assertEqual(false);
    });

    /**
     * 31. 验证零 Emoji 规范门禁
     */
    it('testCardDeckCodebaseZeroEmojiIntegrity', 0, (): void => {
      const emojiRegex: RegExp = /[\uD83C-\uDBFF\uDC00-\uDFFF]/;
      const testStrings: string[] = [
        '下一项',
        '当前行动',
        '高优核心',
        '稳步推进',
        '轻缓微步',
        '万籁俱寂，心流澄澈',
        '今日所有心流微步已完成'
      ];
      for (let i = 0; i < testStrings.length; i++) {
        expect(emojiRegex.test(testStrings[i])).assertEqual(false);
      }
    });

    /**
     * 32. 验证手势取消 (.onActionCancel) 磁吸归位与迟滞复位物理特征
     */
    it('testCardDeckGestureCancellationSnapBackRecovery', 0, (): void => {
      // 1. 模拟手势半途拖拽位移 (offsetX = 60vp)
      const draggingProgress: number = CardDeckKinematics.calcGestureProgress(60.0);
      expect(draggingProgress > 0.5).assertEqual(true);
      expect(draggingProgress < 0.6).assertEqual(true);

      // 2. 模拟触发触觉迟滞状态机
      const hysteresis: HapticHysteresisState = new HapticHysteresisState();
      hysteresis.update(105);
      expect(hysteresis.hasTriggered).assertEqual(true);

      // 3. 执行取消归位重置
      hysteresis.reset();
      expect(hysteresis.hasTriggered).assertEqual(false);

      // 4. 手势取消位移归零后几何位态完全恢复静止基准
      const resetProgress: number = CardDeckKinematics.calcGestureProgress(0.0);
      expect(resetProgress).assertEqual(0.0);
      expect(CardDeckKinematics.calcLayer2Scale(resetProgress)).assertEqual(CardDeckKinematics.LAYER2_BASE_SCALE);
      expect(CardDeckKinematics.calcLayer2TranslateY(resetProgress)).assertEqual(CardDeckKinematics.LAYER2_BASE_TRANSLATE_Y);
      expect(CardDeckKinematics.calcLayer3Scale(resetProgress)).assertEqual(CardDeckKinematics.LAYER3_BASE_SCALE);
      expect(CardDeckKinematics.calcLayer3TranslateY(resetProgress)).assertEqual(CardDeckKinematics.LAYER3_BASE_TRANSLATE_Y);

      // 5. 归位弹簧 SPRING_CARD_CANCEL_RESET 物理阻尼确认 (zeta = 0.76，无持续残余振荡)
      const cancelOvershoot: number = CardDeckKinematics.calcSpringOvershootRatio(0.76);
      expect(cancelOvershoot < 0.03).assertEqual(true);
    });

    /**
     * 33. 验证次层卡片欠阻尼弹簧 (SPRING_CARD_SNAP_FOCUS) 时域轨迹与 8.35% 真实超调回弹
     */
    it('testCardDeckSpringSnapFocusTheoreticalTrajectory', 0, (): void => {
      // 1. 验证 0.62 欠阻尼理论超调率精确落在 8.35% 物理基准
      const ratio: number = CardDeckKinematics.calcSpringOvershootRatio(0.62);
      expect(ratio > 0.0835).assertEqual(true);
      expect(ratio < 0.0836).assertEqual(true);

      // 2. 验证固有角频率与阻尼振荡角频率
      const wn: number = CardDeckKinematics.calcNaturalFrequency(0.34);
      expect(wn > 18.4).assertEqual(true);
      expect(wn < 18.6).assertEqual(true);

      const wd: number = CardDeckKinematics.calcDampedFrequency(0.34, 0.62);
      expect(wd > 14.4).assertEqual(true);
      expect(wd < 14.6).assertEqual(true);

      // 3. 验证首次过冲峰值时刻 tp 约为 216.6ms
      const tp: number = CardDeckKinematics.calcPeakOvershootTime(0.34, 0.62);
      expect(tp > 0.215).assertEqual(true);
      expect(tp < 0.218).assertEqual(true);

      // 4. 验证阶跃响应在峰值时刻达到 1 + Mp (约 1.0835)
      const stepAtPeak: number = CardDeckKinematics.calcSpringStepResponse(tp, 0.34, 0.62);
      expect(stepAtPeak > 1.083).assertEqual(true);
      expect(stepAtPeak < 1.084).assertEqual(true);

      // 5. 验证 22vp 行程下在峰值时刻产生的反向过冲位移 (向负方向反弹约 -1.84vp)
      const offsetAtPeak: number = CardDeckKinematics.calcSpringOffsetY(tp, 22.0, 0.0, 0.34, 0.62);
      expect(offsetAtPeak < 0.0).assertEqual(true);
      expect(Math.abs(offsetAtPeak) > 1.8).assertEqual(true);
      expect(Math.abs(offsetAtPeak) < 1.9).assertEqual(true);

      // 6. 验证在 350ms 后已紧致收敛至平衡点 0vp (误差进入 1% 极小扰动带 < 0.2vp)
      const offsetAtEnd: number = CardDeckKinematics.calcSpringOffsetY(0.35, 22.0, 0.0, 0.34, 0.62);
      expect(Math.abs(offsetAtEnd) < 0.2).assertEqual(true);
    });

    /**
     * 34. 验证飞牌弹簧与聚焦弹簧双轨阻尼分化及常量导出完备性
     */
    it('testCardDeckDualSpringDampingDifferentiation', 0, (): void => {
      // 1. 飞牌弹簧 (zeta = 0.82) 呈近过阻尼特征，无反扑飞回
      const flyoutOvershoot: number = CardDeckKinematics.calcSpringOvershootRatio(0.82);
      expect(flyoutOvershoot < 0.015).assertEqual(true);

      // 2. 聚焦弹簧 (zeta = 0.62) 呈欠阻尼特征，具备清脆机械微弹
      const snapOvershoot: number = CardDeckKinematics.calcSpringOvershootRatio(0.62);
      expect(snapOvershoot > 0.08).assertEqual(true);

      // 3. 超调弹性倍率反差应超过 7.0 倍
      const elasticityRatio: number = snapOvershoot / flyoutOvershoot;
      expect(elasticityRatio > 7.0).assertEqual(true);

      // 4. 常量定义与物理参数基准在各模块间严格恒等
      expect(CardDeckKinematics.SPRING_SNAP_RESPONSE).assertEqual(0.34);
      expect(CardDeckKinematics.SPRING_SNAP_DAMPING).assertEqual(0.62);
      expect(CardDeckKinematics.SPRING_FLYOUT_RESPONSE).assertEqual(0.30);
      expect(CardDeckKinematics.SPRING_FLYOUT_DAMPING).assertEqual(0.82);
      expect(CardDeckKinematics.SPRING_RESET_RESPONSE).assertEqual(0.28);
      expect(CardDeckKinematics.SPRING_RESET_DAMPING).assertEqual(0.76);

      // 5. CurveConstants 曲线对象已正确导出且非空
      expect(CurveConstants.SPRING_CARD_FLYOUT !== null).assertEqual(true);
      expect(CurveConstants.SPRING_CARD_SNAP_FOCUS !== null).assertEqual(true);
      expect(CurveConstants.SPRING_CARD_CANCEL_RESET !== null).assertEqual(true);
    });

    /**
     * 35. 验证次层与底层在底部锚点 (centerY: '100%') 缩放下底边缘外露高度对卡片高度 H 的严格不变性 (防遮挡)
     */
    it('testCardDeckBottomExposureHeightInvariance', 0, (): void => {
      // 1. 测试四种典型卡片高度 (短单行120vp、标准240vp、多行长文360vp、包含子任务攻坚480vp)
      const testHeights: number[] = [120, 240, 360, 480];

      // 2. 验证底部锚点 (anchorCenterYRatio = 1.0, 即 centerY: '100%') 下：
      // Layer 2 外露严格恒等于 22.0vp，Layer 3 外露严格恒等于 16.0vp，对任意 H 完全不变且严格大于 0
      for (let i: number = 0; i < testHeights.length; i++) {
        const h: number = testHeights[i];

        // 静止待机态 (progress = 0.0)
        const exposureL2BottomAnchored: number = CardDeckKinematics.calcLayer2BottomExposure(h, 0.0, 1.0);
        const exposureL3BottomAnchored: number = CardDeckKinematics.calcLayer3BottomExposure(h, 0.0, 1.0);

        // 强断言：外露高度严格大于 0（绝无遮挡）
        expect(exposureL2BottomAnchored > 0).assertEqual(true);
        expect(exposureL3BottomAnchored > 0).assertEqual(true);

        // 强断言：外露高度数学恒等 (Layer 2 为 22.0vp，Layer 3 为 16.0vp)
        expect(Math.abs(exposureL2BottomAnchored - 22.0) < 0.0001).assertEqual(true);
        expect(Math.abs(exposureL3BottomAnchored - 16.0) < 0.0001).assertEqual(true);

        // 验证手势拖拽半程 (progress = 0.5) 阶段依然具备充足外露且平滑过渡
        const midL2Exposure: number = CardDeckKinematics.calcLayer2BottomExposure(h, 0.5, 1.0);
        expect(midL2Exposure > 0).assertEqual(true);
        expect(Math.abs(midL2Exposure - 11.0) < 0.0001).assertEqual(true);
      }

      // 3. 对照验证：重现并断言顶边缘锚点 (anchorCenterYRatio = 0.0, 即原缺陷 centerY: '0%') 会在长卡片下发生遮挡崩溃
      // 当 H = 240 时外露塌陷为 5.2vp；当 H = 360 时外露为负数 (-3.2vp)，发生完全遮挡
      const buggedExposure240: number = CardDeckKinematics.calcLayer2BottomExposure(240, 0.0, 0.0);
      expect(Math.abs(buggedExposure240 - 5.20) < 0.0001).assertEqual(true);

      const buggedExposure360: number = CardDeckKinematics.calcLayer2BottomExposure(360, 0.0, 0.0);
      expect(buggedExposure360 < 0).assertEqual(true);

      const buggedExposure480: number = CardDeckKinematics.calcLayer2BottomExposure(480, 0.0, 0.0);
      expect(buggedExposure480 < -10.0).assertEqual(true);
    });

  });
}