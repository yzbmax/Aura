/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * ArkUI V2 SubTask Entity Model
 */

@ObservedV2
export class SubTaskItem {
  @Trace public id: string = '';                          // UUID (主键)
  @Trace public todoId: string = '';                      // 所属待办 ID (外键)
  @Trace public title: string = '';                       // 标题
  @Trace public done: boolean = false;                    // 完成标记
  @Trace public sortOrder: number = 0;                    // 排序
  @Trace public updatedAt: number = 0;                    // 独立更新时间戳 (毫秒级 LWW)
  @Trace public isDeleted: boolean = false;               // 独立墓碑
  @Trace public deletedAt: number = 0;
  @Trace public isDirty: boolean = true;
  @Trace public lastSyncedAt: number = 0;

  constructor(id: string = '', todoId: string = '', title: string = '', done: boolean = false) {
    this.id = id;
    this.todoId = todoId;
    this.title = title;
    this.done = done;
    this.updatedAt = Date.now();
  }
}
