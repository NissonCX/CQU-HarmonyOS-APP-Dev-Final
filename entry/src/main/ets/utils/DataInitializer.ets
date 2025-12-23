/**
 * 数据初始化工具
 * 用于生成模拟的健康数据
 */
import { HealthRecord } from '../models/HealthRecord';
import { DataManager } from './DataManager';
import { generateId, formatDate } from './CommonUtils';

export class DataInitializer {
  private dataManager: DataManager;

  constructor() {
    this.dataManager = DataManager.getInstance();
  }

  /**
   * 初始化模拟数据
   * 生成过去10天的健康数据，数据变化在合理范围内
   */
  async initializeMockData(): Promise<void> {
    // 检查是否已有数据
    const existingRecords = await this.dataManager.getAllHealthRecords();
    if (existingRecords.length > 0) {
      console.info('已存在数据，跳过初始化');
      return;
    }

    console.info('开始生成模拟数据...');

    // 基准值（模拟一个健康成年人的数据）
    const baseWeight: number = 70;           // 70kg
    const baseHeight: number = 175;          // 175cm
    const baseBloodPressureHigh: number = 120; // 120mmHg
    const baseBloodPressureLow: number = 80;   // 80mmHg
    const baseHeartRate: number = 75;        // 75bpm
    const baseSleepHours: number = 7.5;      // 7.5小时
    const baseSteps: number = 8000;          // 8000步
    const baseWaterIntake: number = 2000;    // 2000ml

    // 生成过去10天的数据
    const today = new Date();
    for (let i = 10; i >= 1; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = formatDate(date);

      // 生成该日的数据，加入合理的随机波动
      const record: HealthRecord = {
        id: generateId(),
        date: dateStr,
        weight: this.addVariation(baseWeight, 0.5, 1), // ±0.5kg, 1位小数
        height: baseHeight, // 身高不变
        bloodPressureHigh: this.addVariation(baseBloodPressureHigh, 5, 0), // ±5mmHg
        bloodPressureLow: this.addVariation(baseBloodPressureLow, 5, 0), // ±5mmHg
        heartRate: this.addVariation(baseHeartRate, 5, 0), // ±5bpm
        sleepHours: this.addVariation(baseSleepHours, 1, 1), // ±1小时
        steps: this.addVariation(baseSteps, 2000, 0), // ±2000步
        waterIntake: this.addVariation(baseWaterIntake, 300, 0), // ±300ml
        note: this.generateNote(i)
      };

      // 保存记录
      await this.dataManager.saveHealthRecord(record);
      console.info(`生成数据: ${dateStr}`);
    }

    console.info('模拟数据生成完成！');
  }

  /**
   * 添加随机波动
   * @param baseValue 基准值
   * @param variation 波动范围
   * @param decimalPlaces 小数位数
   */
  private addVariation(baseValue: number, variation: number, decimalPlaces: number): number {
    // 生成 -variation 到 +variation 的随机数
    const randomVariation = (Math.random() * 2 - 1) * variation;
    const result = baseValue + randomVariation;
    return Number(result.toFixed(decimalPlaces));
  }

  /**
   * 生成备注（偶尔添加一些有趣的备注）
   */
  private generateNote(daysAgo: number): string {
    const notes = [
      '',
      '',
      '',
      '今天运动了30分钟',
      '睡眠质量不错',
      '工作比较忙，运动少了',
      '周末休息，多睡了一会儿',
      '今天喝水有点少',
      '饮食比较健康',
      '感觉状态很好'
    ];

    // 30%概率添加备注
    if (Math.random() < 0.3) {
      const index = Math.floor(Math.random() * notes.length);
      return notes[index];
    }

    return '';
  }

  /**
   * 清除所有数据
   */
  async clearAllData(): Promise<void> {
    const records = await this.dataManager.getAllHealthRecords();
    for (const record of records) {
      await this.dataManager.deleteHealthRecord(record.id);
    }
    console.info('所有数据已清除');
  }

  /**
   * 生成趋势数据（模拟体重下降或上升）
   * @param trend 'increase' | 'decrease' | 'stable'
   */
  async initializeTrendData(trend: 'increase' | 'decrease' | 'stable' = 'stable'): Promise<void> {
    console.info(`生成${trend}趋势的数据...`);

    const baseWeight: number = 70;
    const baseHeight: number = 175;
    const baseBloodPressureHigh: number = 120;
    const baseBloodPressureLow: number = 80;
    const baseHeartRate: number = 75;
    const baseSleepHours: number = 7.5;
    const baseSteps: number = 8000;
    const baseWaterIntake: number = 2000;

    const today = new Date();
    for (let i = 10; i >= 1; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = formatDate(date);

      // 根据趋势调整体重
      let weightAdjustment = 0;
      if (trend === 'increase') {
        // 逐渐增加，总共+2kg
        weightAdjustment = (10 - i) * 0.2;
      } else if (trend === 'decrease') {
        // 逐渐减少，总共-2kg
        weightAdjustment = -(10 - i) * 0.2;
      }

      const record: HealthRecord = {
        id: generateId(),
        date: dateStr,
        weight: this.addVariation(baseWeight + weightAdjustment, 0.3, 1),
        height: baseHeight,
        bloodPressureHigh: this.addVariation(baseBloodPressureHigh, 5, 0),
        bloodPressureLow: this.addVariation(baseBloodPressureLow, 5, 0),
        heartRate: this.addVariation(baseHeartRate, 5, 0),
        sleepHours: this.addVariation(baseSleepHours, 1, 1),
        steps: this.addVariation(baseSteps, 2000, 0),
        waterIntake: this.addVariation(baseWaterIntake, 300, 0),
        note: this.generateNote(i)
      };

      await this.dataManager.saveHealthRecord(record);
    }

    console.info('趋势数据生成完成！');
  }
}
