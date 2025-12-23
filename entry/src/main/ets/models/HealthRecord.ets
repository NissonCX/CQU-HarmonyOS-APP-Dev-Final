/**
 * 健康记录数据模型
 * 用于存储用户的各项健康指标
 */
export interface HealthRecord {
  id: string;                    // 记录唯一标识
  date: string;                  // 记录日期 (YYYY-MM-DD)
  weight?: number;               // 体重 (kg)
  height?: number;               // 身高 (cm)
  bloodPressureHigh?: number;    // 收缩压 (mmHg)
  bloodPressureLow?: number;     // 舒张压 (mmHg)
  heartRate?: number;            // 心率 (bpm)
  sleepHours?: number;           // 睡眠时长 (小时)
  steps?: number;                // 步数
  waterIntake?: number;          // 饮水量 (ml)
  note?: string;                 // 备注
}

/**
 * 健康目标数据模型
 */
export interface HealthGoal {
  id: string;                    // 目标唯一标识
  type: GoalType;                // 目标类型
  targetValue: number;           // 目标值
  currentValue: number;          // 当前值
  unit: string;                  // 单位
  direction: GoalDirection;      // 目标方向
  deadline?: string;             // 截止日期
  isCompleted: boolean;          // 是否完成
}

/**
 * 目标类型枚举
 */
export enum GoalType {
  WEIGHT = 'weight',             // 体重目标
  STEPS = 'steps',               // 步数目标
  WATER = 'water',               // 饮水目标
  SLEEP = 'sleep',               // 睡眠目标
  EXERCISE = 'exercise'          // 运动目标
}

/**
 * 目标方向枚举
 */
export enum GoalDirection {
  DECREASE = 'decrease',         // 减少（如减重）
  INCREASE = 'increase',         // 增加（如增重、增加步数）
  REACH = 'reach'                // 达到（如达到目标值）
}

/**
 * 提醒类型枚举
 */
export enum ReminderType {
  DAILY_RECORD = 'daily_record',     // 每日记录提醒
  DRINK_WATER = 'drink_water',       // 喝水提醒
  EXERCISE = 'exercise',             // 运动提醒
  SLEEP = 'sleep',                   // 睡眠提醒
  MEDICINE = 'medicine'              // 用药提醒
}

/**
 * 提醒设置数据模型
 */
export interface ReminderSettings {
  id: string;                        // 提醒唯一标识
  type: ReminderType;                // 提醒类型
  enabled: boolean;                  // 是否启用

  // 提醒模式：'fixed' 固定时间 | 'interval' 间隔提醒
  mode: 'fixed' | 'interval';

  // 固定时间模式（如：每天21:00提醒记录数据）
  time?: string;                     // 提醒时间 (HH:mm)
  repeatDays?: number[];             // 重复日期 (0-6, 0为周日)

  // 间隔提醒模式（如：每隔2小时提醒喝水）
  intervalMinutes?: number;          // 间隔分钟数（120=2小时）
  startTime?: string;                // 生效开始时间 (HH:mm)
  endTime?: string;                  // 生效结束时间 (HH:mm)

  title: string;                     // 提醒标题
  content: string;                   // 提醒内容
}

/**
 * 用户信息数据模型
 */
export interface UserInfo {
  nickname: string;                  // 用户昵称
  avatar: string;                    // 头像（使用emoji或图标名称）
  gender?: 'male' | 'female' | 'other'; // 性别
  birthDate?: string;                // 出生日期 (YYYY-MM-DD)
  height?: number;                   // 身高 (cm)
  targetWeight?: number;             // 目标体重 (kg)
  signature?: string;                // 个性签名
}
