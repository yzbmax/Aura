/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * RelationalStore Helper Singleton for Local SQLite Operations
 */

import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AuraDatabaseSchema } from './schema/AuraDatabaseSchema';
import { Logger } from '../common/utils/Logger';

export class RdbHelper {
  private static instance: RdbHelper | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitializing: boolean = false;

  private constructor() {}

  public static getInstance(): RdbHelper {
    if (!RdbHelper.instance) {
      RdbHelper.instance = new RdbHelper();
    }
    return RdbHelper.instance;
  }

  /**
   * 初始化数据库并自动建表与升级
   */
  public async init(context: common.Context): Promise<relationalStore.RdbStore> {
    if (this.rdbStore) {
      return this.rdbStore;
    }

    const config: relationalStore.StoreConfig = {
      name: AuraDatabaseSchema.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.isInitializing = true;
      Logger.info('RdbHelper', 'Initializing RelationalStore: %{public}s', AuraDatabaseSchema.DB_NAME);
      const store = await relationalStore.getRdbStore(context, config);
      this.rdbStore = store;

      // 执行 DDL
      await this.initTables(store);
      Logger.info('RdbHelper', 'RelationalStore initialized successfully.');
      return store;
    } catch (err) {
      Logger.error('RdbHelper', 'Failed to initialize RdbStore: %{public}s', JSON.stringify(err));
      throw new Error(String(err));
    } finally {
      this.isInitializing = false;
    }
  }

  public getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('RdbStore has not been initialized. Please call init(context) first.');
    }
    return this.rdbStore;
  }

  private async initTables(store: relationalStore.RdbStore): Promise<void> {
    try {
      await store.executeSql(AuraDatabaseSchema.CREATE_TODO_TABLE);
      await store.executeSql(AuraDatabaseSchema.CREATE_INDEX_TODO_SCHEDULE);
      await store.executeSql(AuraDatabaseSchema.CREATE_INDEX_TODO_STATUS);
      await store.executeSql(AuraDatabaseSchema.CREATE_INDEX_TODO_DELETED);

      await store.executeSql(AuraDatabaseSchema.CREATE_SUBTASK_TABLE);
      await store.executeSql(AuraDatabaseSchema.CREATE_INDEX_SUBTASK_TODO);

      await store.executeSql(AuraDatabaseSchema.CREATE_SETTINGS_TABLE);
      await store.executeSql(AuraDatabaseSchema.CREATE_VERSION_TABLE);
    } catch (err) {
      Logger.error('RdbHelper', 'Failed to execute DDL statements: %{public}s', JSON.stringify(err));
      throw new Error(String(err));
    }
  }
}
