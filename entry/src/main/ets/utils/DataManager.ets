/**
 * 数据管理工具类
 * 使用Preferences实现数据持久化
 */
import { preferences } from '@kit.ArkData';
import { HealthRecord, HealthGoal, ReminderSettings, UserInfo } from '../models/HealthRecord';

const PREFERENCES_NAME = 'health_tracker_data';
const KEY_HEALTH_RECORDS = 'health_records';
const KEY_HEALTH_GOALS = 'health_goals';
const KEY_REMINDERS = 'reminders';
const KEY_USER_INFO = 'user_info';

export class DataManager {
  private static instance: DataManager;
  private dataPreferences: preferences.Preferences | null = null;

  private constructor() {}

  /**
   * 获取DataManager单例
   */
  static getInstance(): DataManager {
    if (!DataManager.instance) {
      DataManager.instance = new DataManager();
    }
    return DataManager.instance;
  }

  /**
   * 初始化数据存储
   */
  async init(context: Context): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, PREFERENCES_NAME);
    } catch (error) {
      console.error('初始化Preferences失败:', JSON.stringify(error));
    }
  }

  /**
   * 保存健康记录
   */
  async saveHealthRecord(record: HealthRecord): Promise<boolean> {
    try {
      const records = await this.getAllHealthRecords();
      const index = records.findIndex(r => r.id === record.id);

      if (index >= 0) {
        records[index] = record;
      } else {
        records.push(record);
      }

      await this.dataPreferences?.put(KEY_HEALTH_RECORDS, JSON.stringify(records));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('保存健康记录失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取所有健康记录
   */
  async getAllHealthRecords(): Promise<HealthRecord[]> {
    try {
      const data = await this.dataPreferences?.get(KEY_HEALTH_RECORDS, '[]') as string;
      return JSON.parse(data) as HealthRecord[];
    } catch (error) {
      console.error('获取健康记录失败:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 根据日期获取健康记录
   */
  async getHealthRecordByDate(date: string): Promise<HealthRecord | null> {
    const records = await this.getAllHealthRecords();
    return records.find(r => r.date === date) || null;
  }

  /**
   * 删除健康记录
   */
  async deleteHealthRecord(id: string): Promise<boolean> {
    try {
      const records = await this.getAllHealthRecords();
      const filteredRecords = records.filter(r => r.id !== id);
      await this.dataPreferences?.put(KEY_HEALTH_RECORDS, JSON.stringify(filteredRecords));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('删除健康记录失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 保存健康目标
   */
  async saveHealthGoal(goal: HealthGoal): Promise<boolean> {
    try {
      const goals = await this.getAllHealthGoals();
      const index = goals.findIndex(g => g.id === goal.id);

      if (index >= 0) {
        goals[index] = goal;
      } else {
        goals.push(goal);
      }

      await this.dataPreferences?.put(KEY_HEALTH_GOALS, JSON.stringify(goals));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('保存健康目标失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取所有健康目标
   */
  async getAllHealthGoals(): Promise<HealthGoal[]> {
    try {
      const data = await this.dataPreferences?.get(KEY_HEALTH_GOALS, '[]') as string;
      return JSON.parse(data) as HealthGoal[];
    } catch (error) {
      console.error('获取健康目标失败:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 删除健康目标
   */
  async deleteHealthGoal(id: string): Promise<boolean> {
    try {
      const goals = await this.getAllHealthGoals();
      const filteredGoals = goals.filter(g => g.id !== id);
      await this.dataPreferences?.put(KEY_HEALTH_GOALS, JSON.stringify(filteredGoals));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('删除健康目标失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 保存提醒设置
   */
  async saveReminder(reminder: ReminderSettings): Promise<boolean> {
    try {
      const reminders = await this.getAllReminders();
      const index = reminders.findIndex(r => r.id === reminder.id);

      if (index >= 0) {
        reminders[index] = reminder;
      } else {
        reminders.push(reminder);
      }

      await this.dataPreferences?.put(KEY_REMINDERS, JSON.stringify(reminders));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('保存提醒设置失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取所有提醒设置
   */
  async getAllReminders(): Promise<ReminderSettings[]> {
    try {
      const data = await this.dataPreferences?.get(KEY_REMINDERS, '[]') as string;
      return JSON.parse(data) as ReminderSettings[];
    } catch (error) {
      console.error('获取提醒设置失败:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 删除提醒设置
   */
  async deleteReminder(id: string): Promise<boolean> {
    try {
      const reminders = await this.getAllReminders();
      const filteredReminders = reminders.filter(r => r.id !== id);
      await this.dataPreferences?.put(KEY_REMINDERS, JSON.stringify(filteredReminders));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('删除提醒设置失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 保存用户信息
   */
  async saveUserInfo(userInfo: UserInfo): Promise<boolean> {
    try {
      await this.dataPreferences?.put(KEY_USER_INFO, JSON.stringify(userInfo));
      await this.dataPreferences?.flush();
      return true;
    } catch (error) {
      console.error('保存用户信息失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取用户信息
   */
  async getUserInfo(): Promise<UserInfo> {
    try {
      const defaultInfo: UserInfo = {
        nickname: '用户',
        avatar: 'user_avatar',
        gender: 'male',
        signature: '坚持记录健康数据'
      };

      const data = await this.dataPreferences?.get(KEY_USER_INFO, '') as string;
      if (!data) {
        return defaultInfo;
      }
      return JSON.parse(data) as UserInfo;
    } catch (error) {
      console.error('获取用户信息失败:', JSON.stringify(error));
      return {
        nickname: '用户',
        avatar: 'user_avatar',
        gender: 'male',
        signature: '坚持记录健康数据'
      };
    }
  }
}
