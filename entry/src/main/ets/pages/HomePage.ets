/**
 * 主页面 - 今日健康数据概览
 * 展示今日健康数据快速录入和概览信息
 */
import { HealthRecord } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { formatDate, calculateBMI, getBMICategory, updateGoalsProgress } from '../utils/CommonUtils';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';
import router from '@ohos.router';

@Component
export struct HomePage {
  @State todayRecord: HealthRecord | null = null;
  @State currentDate: string = '';
  @State bmi: number = 0;
  @State bmiCategory: string = '';
  @State isLoading: boolean = false;
  @State scaleValues: number[] = [1, 1, 1, 1, 1, 1]; // 用于卡片动画
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private intervalId: number = -1;

  aboutToAppear() {
    this.currentDate = formatDate(new Date());
    this.loadTodayData();
    // 启动卡片入场动画
    this.animateCards();
    // 定时刷新数据（每5秒）
    this.intervalId = setInterval(() => {
      this.loadTodayData();
    }, 5000);
  }

  aboutToDisappear() {
    // 清除定时器
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
    }
  }

  /**
   * 启动卡片入场动画
   */
  animateCards() {
    this.scaleValues.forEach((_, index) => {
      setTimeout(() => {
        this.scaleValues[index] = 1.05;
        setTimeout(() => {
          this.scaleValues[index] = 1;
        }, 200);
      }, index * 100);
    });
  }

  /**
   * 加载今日数据
   */
  async loadTodayData() {
    this.isLoading = true;

    // 更新目标进度
    await updateGoalsProgress();

    const record = await this.dataManager.getHealthRecordByDate(this.currentDate);
    this.todayRecord = record;

    // 计算BMI
    if (record?.weight && record?.height) {
      this.bmi = calculateBMI(record.weight, record.height);
      this.bmiCategory = getBMICategory(this.bmi);
    } else {
      this.bmi = 0;
      this.bmiCategory = '';
    }
    this.isLoading = false;
  }

  /**
   * 刷新数据
   */
  async refreshData() {
    await this.loadTodayData();
    this.animateCards();
  }

  /**
   * 更新主题颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('健康追踪')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)

        // 刷新按钮
        Text('⟳')
          .fontSize(24)
          .fontColor(this.colors.primary)
          .rotate({ angle: this.isLoading ? 360 : 0 })
          .animation({
            duration: 1000,
            curve: Curve.Linear,
            iterations: this.isLoading ? -1 : 0
          })
          .onClick(() => {
            this.refreshData();
          })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // 日期和问候语
          this.buildGreetingSection()

          // 今日数据概览
          if (this.todayRecord) {
            this.buildTodayDataSection()
          } else {
            this.buildEmptyDataHint()
          }

          // 今日目标进度（如果有）
          this.buildTodayGoalsSection()

          // 记录按钮
          this.buildRecordButton()
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
   * 问候语部分
   */
  @Builder
  buildGreetingSection() {
    Column() {
      Text(this.getGreeting())
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colors.textPrimary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 5 })

      Text(this.currentDate)
        .fontSize(14)
        .fontColor(this.colors.textTertiary)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .margin({ bottom: 25 })
  }

  /**
   * 获取问候语
   */
  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 6) return '夜深了';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  /**
   * 今日数据概览
   */
  @Builder
  buildTodayDataSection() {
    Column() {
      Text('今日数据')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 15 })

      // 健康数据卡片
      this.buildHealthDataCards()

      // BMI 显示
      if (this.bmi > 0) {
        this.buildBMICard()
      }
    }
    .width('100%')
    .margin({ bottom: 25 })
  }

  /**
   * 空数据提示
   */
  @Builder
  buildEmptyDataHint() {
    Column() {
      Text('📝')
        .fontSize(48)
        .margin({ bottom: 15 })

      Text('还没有记录今日数据')
        .fontSize(16)
        .fontColor(this.colors.textSecondary)
        .margin({ bottom: 5 })

      Text('点击下方按钮开始记录')
        .fontSize(14)
        .fontColor(this.colors.textTertiary)
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .backgroundColor(this.colors.surface)
    .borderRadius(16)
    .margin({ bottom: 25 })
  }

  /**
   * 今日目标进度
   */
  @Builder
  buildTodayGoalsSection() {
    // TODO: 显示今日目标完成情况
    // 这里可以显示"今日已完成2/3个目标"等信息
  }

  /**
   * 记录按钮
   */
  @Builder
  buildRecordButton() {
    Button(this.todayRecord ? '更新今日数据' : '记录今日数据')
      .width('100%')
      .height(56)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(this.colors.primary)
      .borderRadius(28)
      .onClick(() => {
        router.pushUrl({
          url: 'pages/RecordPage'
        });
      })
  }

  /**
   * 构建健康数据卡片
   */
  @Builder
  buildHealthDataCards() {
    Column() {
      // 第一行：体重和身高
      Row() {
        this.buildDataCard('体重', this.todayRecord?.weight?.toString() || '--', 'kg', '#FF6B6B')
        this.buildDataCard('身高', this.todayRecord?.height?.toString() || '--', 'cm', '#4ECDC4')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 15 })

      // 第二行：血压和心率
      Row() {
        this.buildDataCard('收缩压',
          this.todayRecord?.bloodPressureHigh?.toString() || '--', 'mmHg', '#45B7D1')
        this.buildDataCard('心率', this.todayRecord?.heartRate?.toString() || '--', 'bpm', '#96CEB4')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 15 })

      // 第三行：步数和睡眠
      Row() {
        this.buildDataCard('步数', this.todayRecord?.steps?.toString() || '--', '步', '#FFEAA7')
        this.buildDataCard('睡眠', this.todayRecord?.sleepHours?.toString() || '--', '小时', '#DFE6E9')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
  }

  /**
   * 构建单个数据卡片
   */
  @Builder
  buildDataCard(title: string, value: string, unit: string, color: string) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(this.colors.textTertiary)
        .margin({ bottom: 10 })

      Row() {
        Text(value)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)

        Text(unit)
          .fontSize(14)
          .fontColor(this.colors.textTertiary)
          .margin({ left: 5, bottom: 5 })
          .alignSelf(ItemAlign.End)
      }
    }
    .width('48%')
    .height(100)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
    .scale({ x: this.scaleValues[0], y: this.scaleValues[0] })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
  }

  /**
   * 构建BMI卡片
   */
  @Builder
  buildBMICard() {
    Column() {
      Text('体重指数 (BMI)')
        .fontSize(16)
        .fontColor(this.colors.textSecondary)
        .margin({ bottom: 10 })

      Row() {
        Text(this.bmi.toString())
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.error)

        Column() {
          Text(this.bmiCategory)
            .fontSize(18)
            .fontColor(this.colors.error)
            .fontWeight(FontWeight.Medium)
        }
        .margin({ left: 20 })
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ top: 15 })
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }
}
