/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * EntryFormAbility: Form Lifecycle Management for Aura Desktop Widgets
 */

import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { Logger } from '../common/utils/Logger';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formName = want.parameters ? want.parameters[formInfo.FormParam.NAME_KEY] as string : '';
    Logger.info('EntryFormAbility', 'onAddForm called for: %{public}s', formName);

    // 默认提供温润初始数据
    const formData: Record<string, string | number | boolean> = {
      'currentTaskTitle': '当下无专注 · 脑力舒适',
      'remainingTime': '25:00',
      'todayDeepWork': '2.5h / 4.5h',
      'isFocusing': false,
      'slot1': '09:30 架构方案重构',
      'slot2': '11:00 15m 留白呼吸',
      'slot3': '11:15 跨部门同步评审',
      'slot4': '14:00 撰写周报'
    };

    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string): void {
    Logger.info('EntryFormAbility', 'onCastToNormalForm: %{public}s', formId);
  }

  onUpdateForm(formId: string): void {
    Logger.info('EntryFormAbility', 'onUpdateForm: %{public}s', formId);
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    Logger.info('EntryFormAbility', 'onChangeFormVisibility: %{public}s', JSON.stringify(newStatus));
  }

  onFormEvent(formId: string, message: string): void {
    Logger.info('EntryFormAbility', 'onFormEvent: %{public}s, message: %{public}s', formId, message);
  }

  onRemoveForm(formId: string): void {
    Logger.info('EntryFormAbility', 'onRemoveForm: %{public}s', formId);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
