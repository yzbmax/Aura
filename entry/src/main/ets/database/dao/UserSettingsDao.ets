/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * User Settings Data Access Object
 */

import { relationalStore } from '@kit.ArkData';
import { UserSettings } from '../../models/UserSettings';
import { RdbHelper } from '../RdbHelper';
import { AuraDatabaseSchema } from '../schema/AuraDatabaseSchema';
import { AppConstants } from '../../common/constants/AppConstants';
import { Logger } from '../../common/utils/Logger';

export class UserSettingsDao {
  private static readonly KEY_SETTINGS: string = 'app_user_settings';

  public static async saveSettings(settings: UserSettings): Promise<void> {
    const store = RdbHelper.getInstance().getStore();
    const jsonStr = JSON.stringify(settings);
    const bucket: relationalStore.ValuesBucket = {
      'key': UserSettingsDao.KEY_SETTINGS,
      'value': jsonStr
    };
    await store.insert(AuraDatabaseSchema.TABLE_SETTINGS, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    Logger.info('UserSettingsDao', 'Settings persisted successfully');
  }

  public static async getSettings(): Promise<UserSettings> {
    const store = RdbHelper.getInstance().getStore();
    const predicates = new relationalStore.RdbPredicates(AuraDatabaseSchema.TABLE_SETTINGS);
    predicates.equalTo('key', UserSettingsDao.KEY_SETTINGS);
    const resultSet = await store.query(predicates);

    try {
      if (resultSet.goToNextRow()) {
        const value = resultSet.getString(resultSet.getColumnIndex('value'));
        if (value) {
          const parsed = JSON.parse(value) as UserSettings;
          const settings = new UserSettings();
          settings.workStartHour = parsed.workStartHour ?? AppConstants.DEFAULT_WORK_START_HOUR;
          settings.workStartMinute = parsed.workStartMinute ?? AppConstants.DEFAULT_WORK_START_MINUTE;
          settings.workEndHour = parsed.workEndHour ?? AppConstants.DEFAULT_WORK_END_HOUR;
          settings.workEndMinute = parsed.workEndMinute ?? AppConstants.DEFAULT_WORK_END_MINUTE;
          settings.maxDeepWorkMinutes = (parsed.maxDeepWorkMinutes && parsed.maxDeepWorkMinutes > 0)
            ? parsed.maxDeepWorkMinutes
            : AppConstants.DEFAULT_MAX_DEEP_WORK_MINUTES;
          settings.bufferMinutes = (parsed.bufferMinutes && parsed.bufferMinutes > 0)
            ? parsed.bufferMinutes
            : AppConstants.DEFAULT_BUFFER_MINUTES;
          settings.isChordAudioEnabled = parsed.isChordAudioEnabled ?? true;
          settings.isHapticEnabled = parsed.isHapticEnabled ?? true;
          settings.isPaperMode = parsed.isPaperMode ?? false;
          settings.isAmberMode = parsed.isAmberMode ?? false;
          settings.isAgreedPrivacy = parsed.isAgreedPrivacy ?? false;
          settings.lastActiveTimestamp = parsed.lastActiveTimestamp ?? 0;
          settings.streakShieldActive = parsed.streakShieldActive ?? false;
          settings.streakDays = parsed.streakDays ?? 7;
          return settings;
        }
      }
    } catch (err) {
      Logger.error('UserSettingsDao', 'Failed to load settings: %{public}s', JSON.stringify(err));
    } finally {
      resultSet.close();
    }
    return new UserSettings();
  }
}
