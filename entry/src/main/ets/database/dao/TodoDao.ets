/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * TodoItem Data Access Object (DAO) with Tombstone Support
 */

import { relationalStore } from '@kit.ArkData';
import { Priority, TimingMode, TodoItem, TodoSource, TodoStatus } from '../../models/TodoItem';
import { RdbHelper } from '../RdbHelper';
import { AuraDatabaseSchema } from '../schema/AuraDatabaseSchema';
import { SubTaskDao } from './SubTaskDao';
import { Logger } from '../../common/utils/Logger';

export class TodoDao {
  /**
   * 插入待办/时间块
   */
  public static async insert(item: TodoItem): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    const bucket: relationalStore.ValuesBucket = {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'priority': item.priority,
      'status': item.status,
      'due_date': item.dueDate,
      'created_at': item.createdAt,
      'updated_at': item.updatedAt,
      'completed_at': item.completedAt,
      'estimated_minutes': item.estimatedMinutes,
      'actual_minutes': item.actualMinutes,
      'timing_mode': item.timingMode,
      'scheduled_start_at': item.scheduledStartAt,
      'scheduled_end_at': item.scheduledEndAt,
      'is_pinned': item.isPinned ? 1 : 0,
      'is_exploration_slice': item.isExplorationSlice ? 1 : 0,
      'source': item.source,
      'aging_level': item.agingLevel,
      'is_frozen': item.isFrozen ? 1 : 0,
      'tags': JSON.stringify(item.tags),
      'assigned_to': item.assignedTo,
      'device_id': item.deviceId,
      'is_deleted': item.isDeleted ? 1 : 0,
      'deleted_at': item.deletedAt,
      'is_dirty': 1,
      'last_synced_at': item.lastSyncedAt
    };
    await store.insert(AuraDatabaseSchema.TABLE_TODO, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  /**
   * 更新待办
   */
  public static async update(item: TodoItem): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    item.updatedAt = Date.now();
    const bucket: relationalStore.ValuesBucket = {
      'title': item.title,
      'description': item.description,
      'priority': item.priority,
      'status': item.status,
      'due_date': item.dueDate,
      'updated_at': item.updatedAt,
      'completed_at': item.completedAt,
      'estimated_minutes': item.estimatedMinutes,
      'actual_minutes': item.actualMinutes,
      'timing_mode': item.timingMode,
      'scheduled_start_at': item.scheduledStartAt,
      'scheduled_end_at': item.scheduledEndAt,
      'is_pinned': item.isPinned ? 1 : 0,
      'is_exploration_slice': item.isExplorationSlice ? 1 : 0,
      'source': item.source,
      'aging_level': item.agingLevel,
      'is_frozen': item.isFrozen ? 1 : 0,
      'tags': JSON.stringify(item.tags),
      'is_deleted': item.isDeleted ? 1 : 0,
      'deleted_at': item.deletedAt,
      'is_dirty': 1
    };
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('id', item.id);
    await store.update(bucket, predicates);
  }

  /**
   * 软删除：赋予墓碑标记
   */
  public static async deleteTombstone(id: string): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    const now = Date.now();
    const bucket: relationalStore.ValuesBucket = {
      'is_deleted': 1,
      'deleted_at': now,
      'status': TodoStatus.CANCELLED,
      'updated_at': now,
      'is_dirty': 1
    };
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('id', id);
    await store.update(bucket, predicates);
  }

  /**
   * 撤销软删除：恢复墓碑为正常待办
   */
  public static async restoreTombstone(id: string): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    const now = Date.now();
    const bucket: relationalStore.ValuesBucket = {
      'is_deleted': 0,
      'deleted_at': 0,
      'status': TodoStatus.PENDING,
      'updated_at': now,
      'is_dirty': 1
    };
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('id', id);
    await store.update(bucket, predicates);
  }

  /**
   * 查询所有有效活跃待办 (非删除、非冷冻)
   */
  public static async queryAllActive(): Promise<TodoItem[]> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('is_deleted', 0)
      .equalTo('is_frozen', 0)
      .notEqualTo('status', TodoStatus.CANCELLED)
      .orderByAsc('due_date');

    return await TodoDao.executeQuery(store, predicates);
  }

  /**
   * 查询今日已排期的时间块
   */
  public static async queryTodayScheduled(startOfDayMs: number, endOfDayMs: number): Promise<TodoItem[]> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('is_deleted', 0)
      .greaterThanOrEqualTo('scheduled_start_at', startOfDayMs)
      .lessThanOrEqualTo('scheduled_start_at', endOfDayMs)
      .orderByAsc('scheduled_start_at');

    return await TodoDao.executeQuery(store, predicates);
  }

  /**
   * 查询机动备选池事项 (scheduled_start_at == 0 且未完成、未冷冻)
   */
  public static async queryFloatingDeck(): Promise<TodoItem[]> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('is_deleted', 0)
      .equalTo('scheduled_start_at', 0)
      .equalTo('is_frozen', 0)
      .notEqualTo('status', TodoStatus.COMPLETED)
      .notEqualTo('status', TodoStatus.CANCELLED)
      .orderByDesc('created_at');

    return await TodoDao.executeQuery(store, predicates);
  }

  /**
   * 查询所有已完成事项 (用于习惯镜像与打烊统计)
   */
  public static async queryCompleted(): Promise<TodoItem[]> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('is_deleted', 0)
      .equalTo('status', TodoStatus.COMPLETED)
      .orderByDesc('completed_at');

    return await TodoDao.executeQuery(store, predicates);
  }

  /**
   * 查询冷冻舱休眠事项
   */
  public static async queryFrozenItems(): Promise<TodoItem[]> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('is_deleted', 0)
      .equalTo('is_frozen', 1)
      .orderByDesc('updated_at');

    return await TodoDao.executeQuery(store, predicates);
  }

  /**
   * 批量更新排期分配结果
   */
  public static async batchUpdateSchedule(items: TodoItem[]): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    for (const item of items) {
      const bucket: relationalStore.ValuesBucket = {
        'scheduled_start_at': item.scheduledStartAt,
        'scheduled_end_at': item.scheduledEndAt,
        'is_exploration_slice': item.isExplorationSlice ? 1 : 0,
        'updated_at': Date.now(),
        'is_dirty': 1
      };
      const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
      predicates.equalTo('id', item.id);
      await store.update(bucket, predicates);
    }
  }

  /**
   * 30 天墓碑定时清理 (安全物理清理)
   */
  public static async cleanupOldTombstones(days: number = 30): Promise<number> {
    const store = RdbHelper.getInstance().getStore();
    const cutoffTimestamp = Date.now() - (days * 86400 * 1000);
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_TODO);
    predicates.equalTo('is_deleted', 1)
      .lessThan('deleted_at', cutoffTimestamp);

    const deletedRows = await store.delete(predicates);
    Logger.info('TodoDao', 'Cleaned up %{public}d old tombstones', deletedRows);
    return deletedRows;
  }

  private static async executeQuery(store: relationalStore.RdbStore, predicates: relationalStore.RdbPredicates): Promise<TodoItem[]> {
    const resultSet = await store.query(predicates);
    const list: TodoItem[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const id = resultSet.getString(resultSet.getColumnIndex('id'));
        const title = resultSet.getString(resultSet.getColumnIndex('title'));
        const item = new TodoItem(id, title);

        item.description = resultSet.getString(resultSet.getColumnIndex('description'));
        item.priority = resultSet.getLong(resultSet.getColumnIndex('priority')) as Priority;
        item.status = resultSet.getLong(resultSet.getColumnIndex('status')) as TodoStatus;
        item.dueDate = resultSet.getLong(resultSet.getColumnIndex('due_date'));
        item.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
        item.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
        item.completedAt = resultSet.getLong(resultSet.getColumnIndex('completed_at'));
        item.estimatedMinutes = resultSet.getLong(resultSet.getColumnIndex('estimated_minutes'));
        item.actualMinutes = resultSet.getLong(resultSet.getColumnIndex('actual_minutes'));
        item.timingMode = resultSet.getLong(resultSet.getColumnIndex('timing_mode')) as TimingMode;
        item.scheduledStartAt = resultSet.getLong(resultSet.getColumnIndex('scheduled_start_at'));
        item.scheduledEndAt = resultSet.getLong(resultSet.getColumnIndex('scheduled_end_at'));
        item.isPinned = resultSet.getLong(resultSet.getColumnIndex('is_pinned')) === 1;
        item.isExplorationSlice = resultSet.getLong(resultSet.getColumnIndex('is_exploration_slice')) === 1;
        item.source = resultSet.getLong(resultSet.getColumnIndex('source')) as TodoSource;
        item.agingLevel = resultSet.getLong(resultSet.getColumnIndex('aging_level'));
        item.isFrozen = resultSet.getLong(resultSet.getColumnIndex('is_frozen')) === 1;
        item.assignedTo = resultSet.getString(resultSet.getColumnIndex('assigned_to'));
        item.deviceId = resultSet.getString(resultSet.getColumnIndex('device_id'));
        item.isDeleted = resultSet.getLong(resultSet.getColumnIndex('is_deleted')) === 1;
        item.deletedAt = resultSet.getLong(resultSet.getColumnIndex('deleted_at'));

        const tagsRaw = resultSet.getString(resultSet.getColumnIndex('tags'));
        if (tagsRaw) {
          try {
            item.tags = JSON.parse(tagsRaw) as string[];
          } catch {
            item.tags = [];
          }
        }

        // 加载独立子任务
        item.subTasks = await SubTaskDao.queryByTodoId(id);
        list.push(item);
      }
    } catch (err) {
      Logger.error('TodoDao', 'executeQuery error: %{public}s', JSON.stringify(err));
    } finally {
      resultSet.close();
    }
    return list;
  }
}
