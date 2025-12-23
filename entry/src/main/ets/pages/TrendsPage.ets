/**
 * 数据趋势页面
 * 展示健康数据的图表和统计分析
 */
import { HealthRecord } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { getRecentDates, formatDate } from '../utils/CommonUtils';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';

@Component
export struct TrendsPage {
  @State records: HealthRecord[] = [];
  @State recentDates: string[] = [];
  @State selectedMetric: string = 'weight'; // weight, heartRate, bloodPressure, steps
  @State selectedDateIndex: number = -1; // 选中的日期索引
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private intervalId: number = -1;

  aboutToAppear() {
    this.recentDates = getRecentDates(7); // 最近7天
    this.loadData();
    // 定时刷新数据（每5秒）
    this.intervalId = setInterval(() => {
      this.loadData();
    }, 5000);
  }

  aboutToDisappear() {
    // 清除定时器
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
    }
  }

  /**
   * 加载数据
   */
  async loadData() {
    this.records = await this.dataManager.getAllHealthRecords();
  }

  /**
   * 更新主题颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  /**
   * 获取指定日期的数据值
   */
  getValueForDate(date: string): number {
    const record = this.records.find(r => r.date === date);
    if (!record) return 0;

    switch (this.selectedMetric) {
      case 'weight':
        return record.weight || 0;
      case 'heartRate':
        return record.heartRate || 0;
      case 'bloodPressure':
        return record.bloodPressureHigh || 0;
      case 'steps':
        return record.steps || 0;
      default:
        return 0;
    }
  }

  /**
   * 获取指定日期的记录
   */
  getRecordForDate(date: string): HealthRecord | null {
    return this.records.find(r => r.date === date) || null;
  }

  /**
   * 计算平均值
   */
  calculateAverage(): number {
    const validRecords = this.records.filter(r => {
      const value = this.getValueFromRecord(r);
      return value > 0;
    });

    if (validRecords.length === 0) return 0;

    const sum = validRecords.reduce((acc, r) => acc + this.getValueFromRecord(r), 0);
    return Number((sum / validRecords.length).toFixed(1));
  }

  /**
   * 计算最大值
   */
  calculateMax(): number {
    const values = this.records.map(r => this.getValueFromRecord(r)).filter(v => v > 0);
    return values.length > 0 ? Math.max(...values) : 0;
  }

  /**
   * 计算最小值
   */
  calculateMin(): number {
    const values = this.records.map(r => this.getValueFromRecord(r)).filter(v => v > 0);
    return values.length > 0 ? Math.min(...values) : 0;
  }

  /**
   * 从记录中获取值
   */
  getValueFromRecord(record: HealthRecord): number {
    switch (this.selectedMetric) {
      case 'weight':
        return record.weight || 0;
      case 'heartRate':
        return record.heartRate || 0;
      case 'bloodPressure':
        return record.bloodPressureHigh || 0;
      case 'steps':
        return record.steps || 0;
      default:
        return 0;
    }
  }

  /**
   * 获取度量单位
   */
  getUnit(): string {
    switch (this.selectedMetric) {
      case 'weight':
        return 'kg';
      case 'heartRate':
        return 'bpm';
      case 'bloodPressure':
        return 'mmHg';
      case 'steps':
        return '步';
      default:
        return '';
    }
  }

  /**
   * 获取度量名称
   */
  getMetricName(): string {
    switch (this.selectedMetric) {
      case 'weight':
        return '体重';
      case 'heartRate':
        return '心率';
      case 'bloodPressure':
        return '血压';
      case 'steps':
        return '步数';
      default:
        return '';
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('数据趋势')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // 指标选择器
          this.buildMetricSelector()

          // 统计卡片（增强版）
          this.buildEnhancedStatisticsCard()

          // 图表展示区域（增强版）
          this.buildEnhancedChartArea()

          // 选中日期的详细数据
          if (this.selectedDateIndex >= 0) {
            this.buildSelectedDateDetail()
          }

          // 数据列表
          this.buildDataList()
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  /**
   * 构建指标选择器
   */
  @Builder
  buildMetricSelector() {
    Row() {
      this.buildMetricButton('体重', 'weight')
      this.buildMetricButton('心率', 'heartRate')
      this.buildMetricButton('血压', 'bloodPressure')
      this.buildMetricButton('步数', 'steps')
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 20 })
  }

  /**
   * 构建指标按钮
   */
  @Builder
  buildMetricButton(label: string, value: string) {
    Text(label)
      .fontSize(14)
      .fontColor(this.selectedMetric === value ? this.colors.textInverse : this.colors.textSecondary)
      .padding({ top: 8, bottom: 8, left: 16, right: 16 })
      .backgroundColor(this.selectedMetric === value ? this.colors.primary : this.colors.surface)
      .borderRadius(20)
      .onClick(() => {
        this.selectedMetric = value;
        this.selectedDateIndex = -1; // 重置选中的日期
      })
  }

  /**
   * 构建增强版统计卡片
   */
  @Builder
  buildEnhancedStatisticsCard() {
    Column() {
      Row() {
        // 平均值
        Column() {
          Text('平均值')
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ bottom: 5 })

          Text(`${this.calculateAverage()}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.primary)

          Text(this.getUnit())
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 分隔线
        Column()
          .width(1)
          .height(50)
          .backgroundColor(this.colors.divider)

        // 最大值
        Column() {
          Text('最大值')
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ bottom: 5 })

          Text(`${this.calculateMax()}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.error)

          Text(this.getUnit())
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 分隔线
        Column()
          .width(1)
          .height(50)
          .backgroundColor(this.colors.divider)

        // 最小值
        Column() {
          Text('最小值')
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ bottom: 5 })

          Text(`${this.calculateMin()}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.secondary)

          Text(this.getUnit())
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 20 })
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建增强版图表区域
   */
  @Builder
  buildEnhancedChartArea() {
    Column() {
      Text(`${this.getMetricName()}趋势（最近7天）`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      // 图表区域
      Column() {
        ForEach(this.recentDates, (date: string, index: number) => {
          this.buildEnhancedBarItem(date, index)
        }, (date: string) => date)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 20 })
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建增强版柱状图项（横向）
   */
  @Builder
  buildEnhancedBarItem(date: string, index: number) {
    Column() {
      Row() {
        // 日期标签
        Column() {
          Text(date.substring(5))
            .fontSize(12)
            .fontColor(this.colors.textSecondary)

          Text(this.getWeekDay(date))
            .fontSize(10)
            .fontColor(this.colors.textTertiary)
            .margin({ top: 2 })
        }
        .width(60)
        .alignItems(HorizontalAlign.Start)

        // 柱状图
        Row() {
          Row()
            .width(this.getBarWidth(date))
            .height('100%')
            .backgroundColor(this.selectedDateIndex === index ? this.colors.error : this.colors.primary)
            .borderRadius(4)
            .animation({
              duration: 300,
              curve: Curve.EaseOut
            })
        }
        .layoutWeight(1)
        .height(30)
        .backgroundColor(this.colors.surfaceVariant)
        .borderRadius(4)
        .margin({ left: 10, right: 10 })

        // 数值显示
        Text(this.getValueForDate(date) > 0 ? `${this.getValueForDate(date)}` : '--')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedDateIndex === index ? this.colors.error : this.colors.textPrimary)
          .width(50)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .onClick(() => {
        // 点击柱状图显示详细数据
        this.selectedDateIndex = this.selectedDateIndex === index ? -1 : index;
      })
    }
    .margin({ bottom: 12 })
  }

  /**
   * 计算柱状图宽度（百分比）
   */
  getBarWidth(date: string): string {
    const value = this.getValueForDate(date);
    if (value === 0) return '0%';

    const maxValue = Math.max(...this.recentDates.map(d => this.getValueForDate(d)));
    if (maxValue === 0) return '0%';

    const percentage = (value / maxValue) * 100;
    return `${Math.max(5, percentage)}%`; // 最小5%
  }

  /**
   * 获取星期几
   */
  getWeekDay(dateStr: string): string {
    const date = new Date(dateStr);
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekDays[date.getDay()];
  }

  /**
   * 获取选中日期的记录（辅助方法）
   */
  getSelectedRecord(): HealthRecord | null {
    if (this.selectedDateIndex >= 0 && this.selectedDateIndex < this.recentDates.length) {
      return this.getRecordForDate(this.recentDates[this.selectedDateIndex]);
    }
    return null;
  }

  /**
   * 获取选中的日期字符串
   */
  getSelectedDateString(): string {
    if (this.selectedDateIndex >= 0 && this.selectedDateIndex < this.recentDates.length) {
      return this.recentDates[this.selectedDateIndex];
    }
    return '';
  }

  /**
   * 构建选中日期的详细数据
   */
  @Builder
  buildSelectedDateDetail() {
    Column() {
      Row() {
        Text('详细数据')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)

        Text('✕')
          .fontSize(18)
          .fontColor(this.colors.textTertiary)
          .onClick(() => {
            this.selectedDateIndex = -1;
          })
      }
      .width('100%')
      .margin({ bottom: 15 })

      // 日期标题
      Text(`${this.getSelectedDateString()} ${this.getWeekDay(this.getSelectedDateString())}`)
        .fontSize(14)
        .fontColor(this.colors.textSecondary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      // 详细数据网格
      Column() {
        // 第一行
        Row() {
          this.buildDetailItem('体重', this.getSelectedRecord()?.weight?.toString() || '--', 'kg', this.colors.chart1)
          this.buildDetailItem('身高', this.getSelectedRecord()?.height?.toString() || '--', 'cm', this.colors.chart2)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 10 })

        // 第二行
        Row() {
          this.buildDetailItem('收缩压', this.getSelectedRecord()?.bloodPressureHigh?.toString() || '--', 'mmHg', this.colors.chart3)
          this.buildDetailItem('舒张压', this.getSelectedRecord()?.bloodPressureLow?.toString() || '--', 'mmHg', this.colors.chart4)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 10 })

        // 第三行
        Row() {
          this.buildDetailItem('心率', this.getSelectedRecord()?.heartRate?.toString() || '--', 'bpm', this.colors.chart5)
          this.buildDetailItem('步数', this.getSelectedRecord()?.steps?.toString() || '--', '步', this.colors.chart6)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 10 })

        // 第四行
        Row() {
          this.buildDetailItem('睡眠', this.getSelectedRecord()?.sleepHours?.toString() || '--', '小时', this.colors.chart4)
          this.buildDetailItem('饮水', this.getSelectedRecord()?.waterIntake?.toString() || '--', 'ml', this.colors.chart5)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }

      // 备注（使用条件渲染）
      if (this.getSelectedRecord()?.note) {
        Column() {
          Text('备注')
            .fontSize(12)
            .fontColor(this.colors.textTertiary)
            .margin({ bottom: 5 })
            .alignSelf(ItemAlign.Start)

          Text(this.getSelectedRecord()?.note || '')
            .fontSize(14)
            .fontColor(this.colors.textSecondary)
            .padding(10)
            .backgroundColor(this.colors.surfaceVariant)
            .borderRadius(8)
            .width('100%')
        }
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.themeManager.isDark() ? this.colors.surfaceVariant : '#FFF9E6')
    .borderRadius(12)
    .margin({ bottom: 20 })
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建详细数据项
   */
  @Builder
  buildDetailItem(label: string, value: string, unit: string, color: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(this.colors.textTertiary)
        .margin({ bottom: 5 })

      Row() {
        Text(value)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)

        Text(unit)
          .fontSize(12)
          .fontColor(this.colors.textTertiary)
          .margin({ left: 3 })
      }
    }
    .width('48%')
    .padding(12)
    .backgroundColor(this.colors.surface)
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 构建数据列表
   */
  @Builder
  buildDataList() {
    Column() {
      Text('历史记录')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      if (this.records.length === 0) {
        Text('暂无数据记录')
          .fontSize(14)
          .fontColor(this.colors.textTertiary)
          .margin({ top: 20 })
      } else {
        ForEach(this.records.slice().reverse(), (record: HealthRecord) => {
          this.buildRecordItem(record);
        }, (record: HealthRecord) => record.id)
      }
    }
    .width('100%')
  }

  /**
   * 构建单条记录项
   */
  @Builder
  buildRecordItem(record: HealthRecord) {
    Row() {
      Column() {
        Text(record.date)
          .fontSize(14)
          .fontColor(this.colors.textPrimary)
          .fontWeight(FontWeight.Medium)

        Text(this.getRecordSummary(record))
          .fontSize(12)
          .fontColor(this.colors.textTertiary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.getValueFromRecord(record) > 0 ?
        `${this.getValueFromRecord(record)} ${this.getUnit()}` : '--')
        .fontSize(16)
        .fontColor(this.colors.primary)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(this.colors.surface)
    .borderRadius(8)
    .margin({ bottom: 10 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /**
   * 获取记录摘要
   */
  getRecordSummary(record: HealthRecord): string {
    const items: string[] = [];
    if (record.weight) items.push(`体重${record.weight}kg`);
    if (record.heartRate) items.push(`心率${record.heartRate}bpm`);
    if (record.steps) items.push(`步数${record.steps}`);
    return items.length > 0 ? items.join(' · ') : '无数据';
  }
}
