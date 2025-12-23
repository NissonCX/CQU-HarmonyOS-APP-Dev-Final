/**
 * 数据导出管理类
 * 支持将健康数据导出为 CSV 和 JSON 格式
 */
import { HealthRecord, HealthGoal, ReminderSettings } from '../models/HealthRecord';
import { DataManager } from './DataManager';
import { formatDate, formatTime } from './CommonUtils';
import { fileIo } from '@kit.CoreFileKit';

/**
 * 导出格式枚举
 */
export enum ExportFormat {
  CSV = 'csv',
  JSON = 'json'
}

/**
 * 导出内容类型枚举
 */
export enum ExportDataType {
  HEALTH_RECORDS = 'health_records',
  HEALTH_GOALS = 'health_goals',
  REMINDERS = 'reminders',
  ALL = 'all'
}

/**
 * 导出结果接口
 */
export interface ExportResult {
  success: boolean;
  filePath?: string;
  fileName?: string;
  message: string;
}

/**
 * JSON 导出数据结构接口
 */
interface ExportJsonData {
  exportTime: string;
  dataType: string;
  records?: HealthRecord[];
  goals?: HealthGoal[];
  reminders?: ReminderSettings[];
  healthRecords?: HealthRecord[];
  healthGoals?: HealthGoal[];
}

/**
 * 数据导出管理器
 */
export class ExportManager {
  private static instance: ExportManager;
  private dataManager: DataManager;

  private constructor() {
    this.dataManager = DataManager.getInstance();
  }

  /**
   * 获取 ExportManager 单例
   */
  static getInstance(): ExportManager {
    if (!ExportManager.instance) {
      ExportManager.instance = new ExportManager();
    }
    return ExportManager.instance;
  }

  /**
   * 导出数据
   * @param context 应用上下文
   * @param dataType 导出数据类型
   * @param format 导出格式
   */
  async exportData(
    context: Context,
    dataType: ExportDataType,
    format: ExportFormat
  ): Promise<ExportResult> {
    try {
      // 生成文件名
      const fileName = this.generateFileName(dataType, format);

      // 获取文件路径
      const filePath = `${context.cacheDir}/${fileName}`;

      // 根据数据类型和格式生成内容
      let content: string;

      if (format === ExportFormat.CSV) {
        content = await this.generateCSVContent(dataType);
      } else {
        content = await this.generateJSONContent(dataType);
      }

      // 写入文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, content);
      fileIo.closeSync(file.fd);

      return {
        success: true,
        filePath: filePath,
        fileName: fileName,
        message: `数据已导出到:\n${filePath}`
      };
    } catch (error) {
      console.error('导出数据失败:', JSON.stringify(error));
      return {
        success: false,
        message: `导出失败: ${error.message || '未知错误'}`
      };
    }
  }

  /**
   * 生成文件名
   */
  private generateFileName(dataType: ExportDataType, format: ExportFormat): string {
    const now = new Date();
    const date = formatDate(now);
    const time = formatTime(now).replace(':', '');

    let typeName: string;
    switch (dataType) {
      case ExportDataType.HEALTH_RECORDS:
        typeName = 'HealthRecords';
        break;
      case ExportDataType.HEALTH_GOALS:
        typeName = 'HealthGoals';
        break;
      case ExportDataType.REMINDERS:
        typeName = 'Reminders';
        break;
      case ExportDataType.ALL:
        typeName = 'AllData';
        break;
      default:
        typeName = 'Export';
    }

    return `HealthTracker_${typeName}_${date}_${time}.${format}`;
  }

  /**
   * 生成 CSV 格式内容
   */
  private async generateCSVContent(dataType: ExportDataType): Promise<string> {
    let content = '';

    switch (dataType) {
      case ExportDataType.HEALTH_RECORDS:
        content = await this.generateHealthRecordsCSV();
        break;
      case ExportDataType.HEALTH_GOALS:
        content = await this.generateHealthGoalsCSV();
        break;
      case ExportDataType.REMINDERS:
        content = await this.generateRemindersCSV();
        break;
      case ExportDataType.ALL:
        content = await this.generateAllDataCSV();
        break;
    }

    return content;
  }

  /**
   * 生成 JSON 格式内容
   */
  private async generateJSONContent(dataType: ExportDataType): Promise<string> {
    let data: ExportJsonData;

    switch (dataType) {
      case ExportDataType.HEALTH_RECORDS:
        data = {
          exportTime: new Date().toISOString(),
          dataType: 'health_records',
          records: await this.dataManager.getAllHealthRecords()
        };
        break;
      case ExportDataType.HEALTH_GOALS:
        data = {
          exportTime: new Date().toISOString(),
          dataType: 'health_goals',
          goals: await this.dataManager.getAllHealthGoals()
        };
        break;
      case ExportDataType.REMINDERS:
        data = {
          exportTime: new Date().toISOString(),
          dataType: 'reminders',
          reminders: await this.dataManager.getAllReminders()
        };
        break;
      case ExportDataType.ALL:
        data = {
          exportTime: new Date().toISOString(),
          dataType: 'all_data',
          healthRecords: await this.dataManager.getAllHealthRecords(),
          healthGoals: await this.dataManager.getAllHealthGoals(),
          reminders: await this.dataManager.getAllReminders()
        };
        break;
      default:
        data = {
          exportTime: new Date().toISOString(),
          dataType: 'unknown'
        };
    }

    return JSON.stringify(data, null, 2);
  }

  /**
   * 生成健康记录 CSV
   */
  private async generateHealthRecordsCSV(): Promise<string> {
    const records = await this.dataManager.getAllHealthRecords();

    // CSV 表头
    let csv = 'ID,日期,体重(kg),身高(cm),收缩压(mmHg),舒张压(mmHg),心率(bpm),睡眠(小时),步数,饮水量(ml),备注\n';

    // 数据行
    for (const record of records) {
      const row = [
        record.id,
        record.date,
        record.weight ?? '',
        record.height ?? '',
        record.bloodPressureHigh ?? '',
        record.bloodPressureLow ?? '',
        record.heartRate ?? '',
        record.sleepHours ?? '',
        record.steps ?? '',
        record.waterIntake ?? '',
        this.escapeCsvValue(record.note ?? '')
      ];
      csv += row.join(',') + '\n';
    }

    return csv;
  }

  /**
   * 生成健康目标 CSV
   */
  private async generateHealthGoalsCSV(): Promise<string> {
    const goals = await this.dataManager.getAllHealthGoals();

    // CSV 表头
    let csv = 'ID,目标类型,目标值,当前值,单位,方向,截止日期,是否完成\n';

    // 数据行
    for (const goal of goals) {
      const row = [
        goal.id,
        goal.type,
        goal.targetValue,
        goal.currentValue,
        goal.unit,
        goal.direction,
        goal.deadline ?? '',
        goal.isCompleted ? '是' : '否'
      ];
      csv += row.join(',') + '\n';
    }

    return csv;
  }

  /**
   * 生成提醒设置 CSV
   */
  private async generateRemindersCSV(): Promise<string> {
    const reminders = await this.dataManager.getAllReminders();

    // CSV 表头
    let csv = 'ID,类型,是否启用,模式,时间,重复日期,间隔分钟,开始时间,结束时间,标题,内容\n';

    // 数据行
    for (const reminder of reminders) {
      const row = [
        reminder.id,
        reminder.type,
        reminder.enabled ? '是' : '否',
        reminder.mode,
        reminder.time ?? '',
        reminder.repeatDays?.join(';') ?? '',
        reminder.intervalMinutes ?? '',
        reminder.startTime ?? '',
        reminder.endTime ?? '',
        this.escapeCsvValue(reminder.title),
        this.escapeCsvValue(reminder.content)
      ];
      csv += row.join(',') + '\n';
    }

    return csv;
  }

  /**
   * 生成全部数据 CSV（多个表格）
   */
  private async generateAllDataCSV(): Promise<string> {
    let csv = '=== 健康记录 ===\n';
    csv += await this.generateHealthRecordsCSV();
    csv += '\n=== 健康目标 ===\n';
    csv += await this.generateHealthGoalsCSV();
    csv += '\n=== 提醒设置 ===\n';
    csv += await this.generateRemindersCSV();

    return csv;
  }

  /**
   * 转义 CSV 值（处理逗号和引号）
   */
  private escapeCsvValue(value: string): string {
    if (!value) return '';

    // 如果包含逗号、换行或引号，需要用引号包裹并转义引号
    if (value.includes(',') || value.includes('\n') || value.includes('"')) {
      return `"${value.replace(/"/g, '""')}"`;
    }

    return value;
  }

  /**
   * 获取导出文件列表（应用缓存目录下的导出文件）
   */
  async getExportedFiles(context: Context): Promise<string[]> {
    try {
      const files: string[] = [];
      const dirPath = context.cacheDir;

      // 列出目录中的文件
      const listResult = fileIo.listFileSync(dirPath);

      // 筛选导出文件
      for (const fileName of listResult) {
        if (fileName.startsWith('HealthTracker_') &&
            (fileName.endsWith('.csv') || fileName.endsWith('.json'))) {
          files.push(fileName);
        }
      }

      return files;
    } catch (error) {
      console.error('获取导出文件列表失败:', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 删除导出文件
   */
  async deleteExportedFile(context: Context, fileName: string): Promise<boolean> {
    try {
      const filePath = `${context.cacheDir}/${fileName}`;
      fileIo.unlinkSync(filePath);
      return true;
    } catch (error) {
      console.error('删除文件失败:', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 清空所有导出文件
   */
  async clearAllExportedFiles(context: Context): Promise<number> {
    try {
      const files = await this.getExportedFiles(context);
      let deletedCount = 0;

      for (const fileName of files) {
        const success = await this.deleteExportedFile(context, fileName);
        if (success) {
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (error) {
      console.error('清空导出文件失败:', JSON.stringify(error));
      return 0;
    }
  }
}
