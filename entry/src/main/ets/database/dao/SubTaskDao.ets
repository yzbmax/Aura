/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * SubTask Data Access Object (DAO)
 */

import { relationalStore } from '@kit.ArkData';
import { SubTaskItem } from '../../models/SubTaskItem';
import { RdbHelper } from '../RdbHelper';
import { AuraDatabaseSchema } from '../schema/AuraDatabaseSchema';
import { Logger } from '../../common/utils/Logger';

export class SubTaskDao {
  public static async insert(subTask: SubTaskItem): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    const bucket: relationalStore.ValuesBucket = {
      'id': subTask.id,
      'todo_id': subTask.todoId,
      'title': subTask.title,
      'done': subTask.done ? 1 : 0,
      'sort_order': subTask.sortOrder,
      'updated_at': subTask.updatedAt,
      'is_deleted': subTask.isDeleted ? 1 : 0,
      'deleted_at': subTask.deletedAt,
      'is_dirty': 1,
      'last_synced_at': subTask.lastSyncedAt
    };
    await store.insert(AuraDatabaseSchema.TABLE_SUBTASK, bucket);
  }

  public static async update(subTask: SubTaskItem): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    subTask.updatedAt = Date.now();
    const bucket: relationalStore.ValuesBucket = {
      'title': subTask.title,
      'done': subTask.done ? 1 : 0,
      'sort_order': subTask.sortOrder,
      'updated_at': subTask.updatedAt,
      'is_deleted': subTask.isDeleted ? 1 : 0,
      'deleted_at': subTask.deletedAt,
      'is_dirty': 1
    };
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_SUBTASK);
    predicates.equalTo('id', subTask.id);
    await store.update(bucket, predicates);
  }

  public static async queryByTodoId(todoId: string): Promise<SubTaskItem[]> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_SUBTASK);
    predicates.equalTo('todo_id', todoId)
      .equalTo('is_deleted', 0)
      .orderByAsc('sort_order');

    const resultSet = await store.query(predicates);
    const list: SubTaskItem[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const item = new SubTaskItem(
          resultSet.getString(resultSet.getColumnIndex('id')),
          resultSet.getString(resultSet.getColumnIndex('todo_id')),
          resultSet.getString(resultSet.getColumnIndex('title')),
          resultSet.getLong(resultSet.getColumnIndex('done')) === 1
        );
        item.sortOrder = resultSet.getLong(resultSet.getColumnIndex('sort_order'));
        item.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
        item.isDeleted = resultSet.getLong(resultSet.getColumnIndex('is_deleted')) === 1;
        item.deletedAt = resultSet.getLong(resultSet.getColumnIndex('deleted_at'));
        list.push(item);
      }
    } catch (err) {
      Logger.error('SubTaskDao', 'queryByTodoId error: %{public}s', JSON.stringify(err));
    } finally {
      resultSet.close();
    }
    return list;
  }
}
