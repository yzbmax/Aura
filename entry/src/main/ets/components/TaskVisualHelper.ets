/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Task Visual Representation Helper: Color, Soft Tone & Icon Mapping
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { Priority, TodoItem, TodoStatus } from '../models/TodoItem';

export class TaskBlockVisual {
  color: string = ColorConstants.BLOCK_DENIM_BLUE;
  softColor: string = ColorConstants.BLOCK_DENIM_SOFT;
  icon: Resource = $r('app.media.ic_sparkle');
  badge: string = '';
}

export function getTaskVisual(item: TodoItem): TaskBlockVisual {
  const visual: TaskBlockVisual = new TaskBlockVisual();
  if (item.status === TodoStatus.COMPLETED) {
    visual.color = ColorConstants.ACCENT_COMPLETED;
    visual.softColor = ColorConstants.BLOCK_SAGE_SOFT;
    visual.icon = $r('app.media.ic_check');
    return visual;
  }

  const title: string = item.title.toLowerCase();
  if (item.priority === Priority.HIGH || title.includes('攻坚') || title.includes('核心')) {
    visual.color = ColorConstants.ACCENT_CORAL;
    visual.softColor = ColorConstants.ACCENT_CORAL_SOFT;
    visual.icon = $r('app.media.ic_bolt');
  } else if (title.includes('茶歇') || title.includes('呼吸') || title.includes('留白') || title.includes('补水') || item.priority === Priority.LOW) {
    visual.color = ColorConstants.BLOCK_SAGE_GREEN;
    visual.softColor = ColorConstants.BLOCK_SAGE_SOFT;
    visual.icon = $r('app.media.ic_cup');
  } else if (title.includes('评审') || title.includes('合规') || title.includes('会议') || title.includes('自检')) {
    visual.color = ColorConstants.BLOCK_WARM_AMBER;
    visual.softColor = ColorConstants.BLOCK_WARM_AMBER_SOFT;
    visual.icon = $r('app.media.ic_shield');
  } else {
    visual.color = ColorConstants.BLOCK_DENIM_BLUE;
    visual.softColor = ColorConstants.BLOCK_DENIM_SOFT;
    visual.icon = $r('app.media.ic_box');
  }
  return visual;
}
