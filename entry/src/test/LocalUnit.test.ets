/**
 * 本地单元测试
 * 测试工具函数和数据模型
 */
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { calculateBMI, getBMICategory, formatDate, getRecentDates, getDaysDifference } from '../main/ets/utils/CommonUtils';

export default function localUnitTest() {
  describe('工具函数测试', () => {
    // 在所有测试用例开始前执行一次
    beforeAll(() => {
      console.info('开始执行工具函数测试');
    });

    // 在每个测试用例开始前执行
    beforeEach(() => {
      // 可以在这里进行数据初始化
    });

    // 在每个测试用例结束后执行
    afterEach(() => {
      // 可以在这里进行清理工作
    });

    // 在所有测试用例结束后执行一次
    afterAll(() => {
      console.info('工具函数测试完成');
    });

    /**
     * 测试BMI计算功能
     */
    it('测试BMI计算 - 正常体重', 0, () => {
      const bmi = calculateBMI(70, 175);
      expect(bmi).assertEqual(22.9);
    });

    it('测试BMI计算 - 偏瘦', 0, () => {
      const bmi = calculateBMI(50, 175);
      const category = getBMICategory(bmi);
      expect(category).assertEqual('偏瘦');
    });

    it('测试BMI计算 - 正常', 0, () => {
      const bmi = calculateBMI(65, 170);
      const category = getBMICategory(bmi);
      expect(category).assertEqual('正常');
    });

    it('测试BMI计算 - 偏胖', 0, () => {
      const bmi = calculateBMI(80, 170);
      const category = getBMICategory(bmi);
      expect(category).assertEqual('偏胖');
    });

    it('测试BMI计算 - 肥胖', 0, () => {
      const bmi = calculateBMI(90, 170);
      const category = getBMICategory(bmi);
      expect(category).assertEqual('肥胖');
    });

    /**
     * 测试日期格式化功能
     */
    it('测试日期格式化', 0, () => {
      const date = new Date('2024-01-15');
      const formatted = formatDate(date);
      expect(formatted).assertContain('2024');
      expect(formatted).assertContain('01');
      expect(formatted).assertContain('15');
    });

    /**
     * 测试获取最近日期功能
     */
    it('测试获取最近7天日期', 0, () => {
      const dates = getRecentDates(7);
      expect(dates.length).assertEqual(7);
      // 验证日期格式
      dates.forEach(date => {
        expect(date).assertContain('-');
        expect(date.length).assertEqual(10);
      });
    });

    /**
     * 测试日期差计算功能
     */
    it('测试日期差计算', 0, () => {
      const days = getDaysDifference('2024-01-01', '2024-01-08');
      expect(days).assertEqual(7);
    });

    /**
     * 测试BMI边界情况 - 身高为0
     */
    it('测试BMI计算边界情况 - 身高为0', 0, () => {
      const bmi = calculateBMI(70, 0);
      expect(bmi).assertEqual(0);
    });

    /**
     * 测试BMI边界情况 - 负数输入
     */
    it('测试BMI计算边界情况 - 负数身高', 0, () => {
      const bmi = calculateBMI(70, -175);
      expect(bmi).assertEqual(0);
    });
  });

  describe('数据模型测试', () => {
    /**
     * 测试健康记录模型
     */
    it('测试健康记录数据结构', 0, () => {
      const record = {
        id: 'test123',
        date: '2024-01-15',
        weight: 70,
        height: 175,
        heartRate: 75
      };

      expect(record.id).assertEqual('test123');
      expect(record.date).assertEqual('2024-01-15');
      expect(record.weight).assertEqual(70);
      expect(record.height).assertEqual(175);
      expect(record.heartRate).assertEqual(75);
    });
  });
}