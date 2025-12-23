/**
 * 工具函数集合
 */

/**
 * 生成唯一ID
 */
export function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

/**
 * 格式化日期为 YYYY-MM-DD
 */
export function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * 格式化时间为 HH:mm
 */
export function formatTime(date: Date): string {
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}

/**
 * 解析日期字符串
 */
export function parseDate(dateStr: string): Date {
  return new Date(dateStr);
}

/**
 * 计算BMI (Body Mass Index)
 * @param weight 体重(kg)
 * @param height 身高(cm)
 * @returns BMI值
 */
export function calculateBMI(weight: number, height: number): number {
  if (height <= 0) return 0;
  const heightInMeters = height / 100;
  return Number((weight / (heightInMeters * heightInMeters)).toFixed(1));
}

/**
 * 获取BMI评价
 */
export function getBMICategory(bmi: number): string {
  if (bmi < 18.5) return '偏瘦';
  if (bmi < 24) return '正常';
  if (bmi < 28) return '偏胖';
  return '肥胖';
}

/**
 * 获取血压评价
 */
export function getBloodPressureCategory(high: number, low: number): string {
  if (high < 90 || low < 60) return '偏低';
  if (high < 120 && low < 80) return '正常';
  if (high < 140 && low < 90) return '正常高值';
  if (high < 160 && low < 100) return '轻度高血压';
  return '高血压';
}

/**
 * 获取心率评价
 */
export function getHeartRateCategory(heartRate: number): string {
  if (heartRate < 60) return '偏低';
  if (heartRate <= 100) return '正常';
  return '偏高';
}

/**
 * 获取日期差（天数）
 */
export function getDaysDifference(date1: string, date2: string): number {
  const d1 = new Date(date1);
  const d2 = new Date(date2);
  const diffTime = Math.abs(d2.getTime() - d1.getTime());
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

/**
 * 获取最近N天的日期数组
 */
export function getRecentDates(days: number): string[] {
  const dates: string[] = [];
  const today = new Date();

  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    dates.push(formatDate(date));
  }

  return dates;
}

/**
 * 获取星期几的中文名称
 */
export function getWeekDayName(dayIndex: number): string {
  const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  return weekDays[dayIndex] || '';
}

/**
 * 更新所有目标的进度
 * 根据健康记录自动计算目标的当前值
 */
export async function updateGoalsProgress(): Promise<void> {
  const DataManager = (await import('./DataManager')).DataManager;
  const dataManager = DataManager.getInstance();

  const goals = await dataManager.getAllHealthGoals();
  const records = await dataManager.getAllHealthRecords();

  if (records.length === 0) {
    return;
  }

  const GoalType = (await import('../models/HealthRecord')).GoalType;
  const GoalDirection = (await import('../models/HealthRecord')).GoalDirection;

  for (const goal of goals) {
    let currentValue = 0;

    switch (goal.type) {
      case GoalType.WEIGHT:
        // 体重目标：取最新的体重记录
        const latestRecordWithWeight = records
          .filter(r => r.weight !== undefined && r.weight !== null)
          .sort((a, b) => b.date.localeCompare(a.date))[0];
        if (latestRecordWithWeight && latestRecordWithWeight.weight !== undefined) {
          currentValue = latestRecordWithWeight.weight;
        }
        break;

      case GoalType.STEPS:
        // 步数目标：计算最近7天的平均步数
        const recentDates = getRecentDates(7);
        const recentRecords = records.filter(r => recentDates.includes(r.date));
        const totalSteps = recentRecords.reduce((sum, r) => sum + (r.steps || 0), 0);
        currentValue = recentRecords.length > 0 ? Math.floor(totalSteps / recentRecords.length) : 0;
        break;

      case GoalType.WATER:
        // 饮水目标：计算最近7天的平均饮水量
        const recentDates2 = getRecentDates(7);
        const recentRecords2 = records.filter(r => recentDates2.includes(r.date));
        const totalWater = recentRecords2.reduce((sum, r) => sum + (r.waterIntake || 0), 0);
        currentValue = recentRecords2.length > 0 ? Math.floor(totalWater / recentRecords2.length) : 0;
        break;

      case GoalType.SLEEP:
        // 睡眠目标：计算最近7天的平均睡眠时长
        const recentDates3 = getRecentDates(7);
        const recentRecords3 = records.filter(r => recentDates3.includes(r.date));
        const totalSleep = recentRecords3.reduce((sum, r) => sum + (r.sleepHours || 0), 0);
        currentValue = recentRecords3.length > 0 ?
          Number((totalSleep / recentRecords3.length).toFixed(1)) : 0;
        break;

      case GoalType.EXERCISE:
        // 运动目标：暂时设为0（因为当前记录中没有运动时长字段）
        currentValue = 0;
        break;
    }

    // 更新目标
    goal.currentValue = currentValue;

    // 根据目标方向检查是否完成
    const direction = goal.direction || GoalDirection.INCREASE;

    if (currentValue === 0) {
      goal.isCompleted = false;
    } else {
      switch (direction) {
        case GoalDirection.DECREASE:
          // 减少目标：当前值 <= 目标值
          goal.isCompleted = currentValue <= goal.targetValue;
          break;
        case GoalDirection.INCREASE:
          // 增加目标：当前值 >= 目标值
          goal.isCompleted = currentValue >= goal.targetValue;
          break;
        case GoalDirection.REACH:
          // 达到目标：当前值 >= 目标值（与增加相同）
          goal.isCompleted = currentValue >= goal.targetValue;
          break;
        default:
          goal.isCompleted = currentValue >= goal.targetValue;
      }
    }

    await dataManager.saveHealthGoal(goal);
  }
}
