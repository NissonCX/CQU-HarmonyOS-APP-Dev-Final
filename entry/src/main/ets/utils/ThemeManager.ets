/**
 * 主题管理类
 * 定义浅色和暗色主题的配色方案
 */

/**
 * 主题类型枚举
 */
export enum ThemeType {
  LIGHT = 'light',
  DARK = 'dark'
}

/**
 * 主题颜色接口
 */
export interface ThemeColors {
  // 基础颜色
  primary: string;           // 主色调
  secondary: string;         // 次要色
  accent: string;            // 强调色

  // 背景颜色
  background: string;        // 页面背景
  surface: string;           // 卡片/表面背景
  surfaceVariant: string;    // 表面变体

  // 文字颜色
  textPrimary: string;       // 主要文字
  textSecondary: string;     // 次要文字
  textTertiary: string;      // 三级文字
  textInverse: string;       // 反色文字（用于深色背景）

  // 状态颜色
  success: string;           // 成功/完成
  warning: string;           // 警告
  error: string;             // 错误/删除
  info: string;              // 信息

  // 边框和分割线
  border: string;            // 边框颜色
  divider: string;           // 分割线颜色

  // 阴影
  shadow: string;            // 阴影颜色

  // 图表颜色
  chart1: string;
  chart2: string;
  chart3: string;
  chart4: string;
  chart5: string;
  chart6: string;
}

/**
 * 浅色主题配色
 */
export const LightTheme: ThemeColors = {
  // 基础颜色
  primary: '#4ECDC4',
  secondary: '#45B7D1',
  accent: '#FF6B6B',

  // 背景颜色
  background: '#F5F5F5',
  surface: '#FFFFFF',
  surfaceVariant: '#F9F9F9',

  // 文字颜色
  textPrimary: '#333333',
  textSecondary: '#666666',
  textTertiary: '#999999',
  textInverse: '#FFFFFF',

  // 状态颜色
  success: '#4ECDC4',
  warning: '#FFEAA7',
  error: '#FF6B6B',
  info: '#45B7D1',

  // 边框和分割线
  border: '#E0E0E0',
  divider: '#F0F0F0',

  // 阴影
  shadow: '#1F000000',

  // 图表颜色
  chart1: '#FF6B6B',
  chart2: '#4ECDC4',
  chart3: '#45B7D1',
  chart4: '#96CEB4',
  chart5: '#FFEAA7',
  chart6: '#DFE6E9'
};

/**
 * 暗色主题配色
 */
export const DarkTheme: ThemeColors = {
  // 基础颜色 - 降低饱和度和亮度
  primary: '#3BA39C',        // 暗青色
  secondary: '#3694B0',      // 暗蓝色
  accent: '#E85555',         // 暗红色

  // 背景颜色 - 使用深灰色系
  background: '#121212',     // 最深背景（纯黑会太刺眼）
  surface: '#1E1E1E',        // 卡片背景
  surfaceVariant: '#2A2A2A', // 表面变体

  // 文字颜色 - 降低对比度
  textPrimary: '#E0E0E0',    // 主要文字（不用纯白）
  textSecondary: '#B0B0B0',  // 次要文字
  textTertiary: '#808080',   // 三级文字
  textInverse: '#1E1E1E',    // 反色文字

  // 状态颜色 - 柔和版本
  success: '#3BA39C',
  warning: '#D4B86A',
  error: '#E85555',
  info: '#3694B0',

  // 边框和分割线
  border: '#3A3A3A',
  divider: '#2A2A2A',

  // 阴影 - 暗色模式下使用更深的黑色
  shadow: '#00000050',

  // 图表颜色 - 柔和且对比明显
  chart1: '#E85555',
  chart2: '#3BA39C',
  chart3: '#3694B0',
  chart4: '#7BB299',
  chart5: '#D4B86A',
  chart6: '#B8BFC4'
};

/**
 * 主题管理类
 */
export class ThemeManager {
  private static instance: ThemeManager;
  private currentTheme: ThemeType = ThemeType.LIGHT;

  private constructor() {
    // 从AppStorage加载主题设置
    const savedTheme = AppStorage.get<string>('appTheme');
    if (savedTheme === 'dark') {
      this.currentTheme = ThemeType.DARK;
    }
  }

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  /**
   * 获取当前主题
   */
  getCurrentTheme(): ThemeType {
    return this.currentTheme;
  }

  /**
   * 设置主题
   */
  setTheme(theme: ThemeType): void {
    this.currentTheme = theme;
    AppStorage.setOrCreate('appTheme', theme);
    // 通知所有订阅者主题已变化
    AppStorage.setOrCreate('themeChanged', Date.now());
  }

  /**
   * 切换主题
   */
  toggleTheme(): void {
    const newTheme = this.currentTheme === ThemeType.LIGHT ? ThemeType.DARK : ThemeType.LIGHT;
    this.setTheme(newTheme);
  }

  /**
   * 是否为暗色主题
   */
  isDark(): boolean {
    return this.currentTheme === ThemeType.DARK;
  }

  /**
   * 获取当前主题颜色
   */
  getColors(): ThemeColors {
    return this.currentTheme === ThemeType.LIGHT ? LightTheme : DarkTheme;
  }
}

/**
 * 获取当前主题颜色的便捷函数
 */
export function getThemeColors(): ThemeColors {
  return ThemeManager.getInstance().getColors();
}

/**
 * 获取当前是否为暗色主题的便捷函数
 */
export function isDarkTheme(): boolean {
  return ThemeManager.getInstance().isDark();
}
