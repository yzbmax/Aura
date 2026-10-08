/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Database Schema, DDL & Index Definitions for RelationalStore
 */

export class AuraDatabaseSchema {
  public static readonly DB_NAME: string = 'aura_flow.db';
  public static readonly DB_VERSION: number = 1;

  // 表名
  public static readonly TABLE_TODO: string = 'todo_items';
  public static readonly TABLE_SUBTASK: string = 'sub_task_items';
  public static readonly TABLE_SETTINGS: string = 'user_settings';
  public static readonly TABLE_VERSION: string = 'schema_version';

  // 待办主表建表 DDL
  public static readonly CREATE_TODO_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${AuraDatabaseSchema.TABLE_TODO} (
      id                  TEXT PRIMARY KEY,
      title               TEXT NOT NULL,
      description         TEXT DEFAULT '',
      priority            INTEGER DEFAULT 2,
      status              INTEGER DEFAULT 0,
      due_date            INTEGER DEFAULT 0,
      created_at          INTEGER NOT NULL,
      updated_at          INTEGER NOT NULL,
      completed_at        INTEGER DEFAULT 0,
      estimated_minutes   INTEGER DEFAULT 25,
      actual_minutes      INTEGER DEFAULT 0,
      timing_mode         INTEGER DEFAULT 0,
      scheduled_start_at  INTEGER DEFAULT 0,
      scheduled_end_at    INTEGER DEFAULT 0,
      is_pinned           INTEGER DEFAULT 0,
      is_exploration_slice INTEGER DEFAULT 0,
      source              INTEGER DEFAULT 0,
      aging_level         INTEGER DEFAULT 0,
      is_frozen           INTEGER DEFAULT 0,
      tags                TEXT DEFAULT '[]',
      assigned_to         TEXT DEFAULT '',
      device_id           TEXT DEFAULT '',
      is_deleted          INTEGER DEFAULT 0,
      deleted_at          INTEGER DEFAULT 0,
      is_dirty            INTEGER DEFAULT 1,
      last_synced_at      INTEGER DEFAULT 0
    );
  `;

  // 待办表高性能联合索引
  public static readonly CREATE_INDEX_TODO_SCHEDULE: string = `
    CREATE INDEX IF NOT EXISTS idx_todo_schedule ON ${AuraDatabaseSchema.TABLE_TODO}(scheduled_start_at, is_deleted);
  `;
  public static readonly CREATE_INDEX_TODO_STATUS: string = `
    CREATE INDEX IF NOT EXISTS idx_todo_status ON ${AuraDatabaseSchema.TABLE_TODO}(status, is_deleted);
  `;
  public static readonly CREATE_INDEX_TODO_DELETED: string = `
    CREATE INDEX IF NOT EXISTS idx_todo_deleted ON ${AuraDatabaseSchema.TABLE_TODO}(is_deleted);
  `;

  // 子任务从表建表 DDL
  public static readonly CREATE_SUBTASK_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${AuraDatabaseSchema.TABLE_SUBTASK} (
      id              TEXT PRIMARY KEY,
      todo_id         TEXT NOT NULL,
      title           TEXT NOT NULL,
      done            INTEGER DEFAULT 0,
      sort_order      INTEGER DEFAULT 0,
      updated_at      INTEGER NOT NULL,
      is_deleted      INTEGER DEFAULT 0,
      deleted_at      INTEGER DEFAULT 0,
      is_dirty        INTEGER DEFAULT 1,
      last_synced_at  INTEGER DEFAULT 0,
      FOREIGN KEY (todo_id) REFERENCES ${AuraDatabaseSchema.TABLE_TODO}(id) ON DELETE CASCADE
    );
  `;

  public static readonly CREATE_INDEX_SUBTASK_TODO: string = `
    CREATE INDEX IF NOT EXISTS idx_subtask_todo ON ${AuraDatabaseSchema.TABLE_SUBTASK}(todo_id);
  `;

  // 用户设置表
  public static readonly CREATE_SETTINGS_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${AuraDatabaseSchema.TABLE_SETTINGS} (
      key   TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `;

  // 版本元数据表
  public static readonly CREATE_VERSION_TABLE: string = `
    CREATE TABLE IF NOT EXISTS ${AuraDatabaseSchema.TABLE_VERSION} (
      version     INTEGER PRIMARY KEY,
      upgraded_at INTEGER NOT NULL
    );
  `;
}
