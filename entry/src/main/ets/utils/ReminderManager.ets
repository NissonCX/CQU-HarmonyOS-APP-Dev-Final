/**
 * 提醒管理工具类
 * 使用HarmonyOS的notificationManager实现本地通知提醒
 * 注意：由于ReminderAgent API可能不可用，这里使用简化的通知实现
 */
import { notificationManager } from '@kit.NotificationKit';
import { ReminderSettings, ReminderType } from '../models/HealthRecord';
import { BusinessError } from '@kit.BasicServicesKit';

export class ReminderManager {
  private static instance: ReminderManager;

  private constructor() {}

  /**
   * 获取ReminderManager单例
   */
  static getInstance(): ReminderManager {
    if (!ReminderManager.instance) {
      ReminderManager.instance = new ReminderManager();
    }
    return ReminderManager.instance;
  }

  /**
   * 请求通知权限
   */
  async requestNotificationPermission(): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification();
      console.info('通知权限请求成功');
      return true;
    } catch (error) {
      console.error('请求通知权限失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 发布提醒
   * 注意：这是简化实现，仅保存提醒设置，实际通知需要后台服务支持
   */
  async publishReminder(reminder: ReminderSettings): Promise<boolean> {
    try {
      // 保存提醒配置
      await this.saveReminderConfig(reminder);

      console.info(`提醒已配置: ${reminder.title}`);
      console.info(`模式: ${reminder.mode}`);

      if (reminder.mode === 'fixed') {
        console.info(`时间: ${reminder.time}, 重复: ${reminder.repeatDays?.join(',')}`);
      } else {
        console.info(`间隔: ${reminder.intervalMinutes}分钟, 时段: ${reminder.startTime}-${reminder.endTime}`);
      }

      // 发送测试通知
      await this.sendTestNotification(reminder);

      return true;
    } catch (error) {
      console.error('发布提醒失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 发送测试通知
   */
  private async sendTestNotification(reminder: ReminderSettings): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: this.getNotificationId(reminder.id),
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: reminder.title,
            text: reminder.content,
            additionalText: '提醒已设置'
          }
        }
      };

      await notificationManager.publish(notificationRequest);
      console.info('测试通知发送成功');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`发送测试通知失败: code=${err.code}, message=${err.message}`);
    }
  }

  /**
   * 取消提醒
   */
  async cancelReminder(reminderId: string): Promise<boolean> {
    try {
      // 清除提醒配置
      await this.clearReminderConfig(reminderId);

      // 取消相关通知
      const notificationId = this.getNotificationId(reminderId);
      await notificationManager.cancel(notificationId);

      console.info(`提醒已取消: ${reminderId}`);
      return true;
    } catch (error) {
      console.error('取消提醒失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 取消所有提醒
   */
  async cancelAllReminders(): Promise<boolean> {
    try {
      await notificationManager.cancelAll();
      console.info('取消所有提醒成功');
      return true;
    } catch (error) {
      console.error('取消所有提醒失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 获取通知ID（用于通知管理）
   */
  private getNotificationId(id: string): number {
    // 将字符串ID转换为数字ID
    let hash = 0;
    for (let i = 0; i < id.length; i++) {
      hash = ((hash << 5) - hash) + id.charCodeAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
  }

  /**
   * 保存提醒配置
   */
  private async saveReminderConfig(reminder: ReminderSettings): Promise<void> {
    try {
      const key = `reminder_config_${reminder.id}`;
      AppStorage.setOrCreate(key, JSON.stringify(reminder));
    } catch (error) {
      console.error('保存提醒配置失败:', JSON.stringify(error));
    }
  }

  /**
   * 清除提醒配置
   */
  private async clearReminderConfig(id: string): Promise<void> {
    try {
      const key = `reminder_config_${id}`;
      AppStorage.delete(key);
    } catch (error) {
      console.error('清除提醒配置失败:', JSON.stringify(error));
    }
  }

  /**
   * 获取提醒配置
   */
  private async getReminderConfig(id: string): Promise<ReminderSettings | null> {
    try {
      const key = `reminder_config_${id}`;
      const value = AppStorage.get<string>(key);
      if (value) {
        const config: ReminderSettings = JSON.parse(value as string) as ReminderSettings;
        return config;
      }
      return null;
    } catch (error) {
      console.error('获取提醒配置失败:', JSON.stringify(error));
      return null;
    }
  }
}
