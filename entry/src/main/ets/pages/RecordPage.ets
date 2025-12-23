/**
 * 数据记录页面
 * 用于添加和编辑健康数据记录
 */
import { HealthRecord } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { generateId, formatDate, calculateBMI, getBMICategory } from '../utils/CommonUtils';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';
import router from '@ohos.router';

/**
 * 输入字段接口定义
 */
interface InputField {
  label: string;
  value: string;
  unit: string;
  onInput: (value: string) => void;
}

@Entry
@Component
struct RecordPage {
  @State date: string = formatDate(new Date());
  @State weight: string = '';
  @State heightValue: string = '';
  @State bloodPressureHigh: string = '';
  @State bloodPressureLow: string = '';
  @State heartRate: string = '';
  @State sleepHours: string = '';
  @State steps: string = '';
  @State waterIntake: string = '';
  @State note: string = '';
  @State showSuccessToast: boolean = false;
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private recordId: string = '';

  aboutToAppear() {
    // 尝试加载今日数据
    this.loadTodayData();
  }

  /**
   * 加载今日数据（如果存在）
   */
  async loadTodayData() {
    const record = await this.dataManager.getHealthRecordByDate(this.date);
    if (record) {
      this.recordId = record.id;
      this.weight = record.weight?.toString() || '';
      this.heightValue = record.height?.toString() || '';
      this.bloodPressureHigh = record.bloodPressureHigh?.toString() || '';
      this.bloodPressureLow = record.bloodPressureLow?.toString() || '';
      this.heartRate = record.heartRate?.toString() || '';
      this.sleepHours = record.sleepHours?.toString() || '';
      this.steps = record.steps?.toString() || '';
      this.waterIntake = record.waterIntake?.toString() || '';
      this.note = record.note || '';
    }
  }

  /**
   * 保存记录
   */
  async saveRecord() {
    // 构建健康记录对象
    const record: HealthRecord = {
      id: this.recordId || generateId(),
      date: this.date,
      weight: this.weight ? parseFloat(this.weight) : undefined,
      height: this.heightValue ? parseFloat(this.heightValue) : undefined,
      bloodPressureHigh: this.bloodPressureHigh ? parseInt(this.bloodPressureHigh) : undefined,
      bloodPressureLow: this.bloodPressureLow ? parseInt(this.bloodPressureLow) : undefined,
      heartRate: this.heartRate ? parseInt(this.heartRate) : undefined,
      sleepHours: this.sleepHours ? parseFloat(this.sleepHours) : undefined,
      steps: this.steps ? parseInt(this.steps) : undefined,
      waterIntake: this.waterIntake ? parseInt(this.waterIntake) : undefined,
      note: this.note
    };

    // 保存到数据库
    const success = await this.dataManager.saveHealthRecord(record);

    if (success) {
      // 显示成功提示
      this.showSuccessToast = true;

      // 1秒后返回首页
      setTimeout(() => {
        router.back();
      }, 1000);
    }
  }

  /**
   * 更新主题颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('返回')
          .fontSize(16)
          .fontColor(this.colors.primary)
          .onClick(() => {
            router.back();
          })

        Text('记录健康数据')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('保存')
          .fontSize(16)
          .fontColor(this.colors.primary)
          .onClick(() => {
            this.saveRecord();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.colors.surface)

      Scroll() {
        Column() {
          // 日期选择
          this.buildDateSection()

          // 基础指标
          this.buildSection('基础指标', [
            { label: '体重', value: this.weight, unit: 'kg', onInput: (val: string): void => { this.weight = val } },
            { label: '身高', value: this.heightValue, unit: 'cm', onInput: (val: string): void => { this.heightValue = val } }
          ])

          // 血压与心率
          this.buildSection('血压与心率', [
            { label: '收缩压', value: this.bloodPressureHigh, unit: 'mmHg',
              onInput: (val: string): void => { this.bloodPressureHigh = val } },
            { label: '舒张压', value: this.bloodPressureLow, unit: 'mmHg',
              onInput: (val: string): void => { this.bloodPressureLow = val } },
            { label: '心率', value: this.heartRate, unit: 'bpm',
              onInput: (val: string): void => { this.heartRate = val } }
          ])

          // 生活习惯
          this.buildSection('生活习惯', [
            { label: '步数', value: this.steps, unit: '步', onInput: (val: string): void => { this.steps = val } },
            { label: '睡眠', value: this.sleepHours, unit: '小时',
              onInput: (val: string): void => { this.sleepHours = val } },
            { label: '饮水', value: this.waterIntake, unit: 'ml',
              onInput: (val: string): void => { this.waterIntake = val } }
          ])

          // 备注
          this.buildNoteSection()

          // BMI提示
          if (this.weight && this.heightValue) {
            this.buildBMIHint()
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 成功提示
      if (this.showSuccessToast) {
        this.buildSuccessToast()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  /**
   * 构建日期选择区域
   */
  @Builder
  buildDateSection() {
    Column() {
      Text('日期')
        .fontSize(14)
        .fontColor(this.colors.textTertiary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8 })

      Text(this.date)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .width('100%')
        .padding(16)
        .backgroundColor(this.colors.surface)
        .borderRadius(8)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 构建输入区域
   */
  @Builder
  buildSection(title: string, fields: InputField[]) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      ForEach(fields, (field: InputField) => {
        Row() {
          Text(field.label)
            .fontSize(15)
            .fontColor(this.colors.textSecondary)
            .width(80)

          TextInput({ text: field.value, placeholder: `请输入${field.label}` })
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .type(InputType.Number)
            .backgroundColor(this.colors.surfaceVariant)
            .borderRadius(8)
            .onChange((value: string) => {
              field.onInput(value);
            })

          Text(field.unit)
            .fontSize(14)
            .fontColor(this.colors.textTertiary)
            .width(60)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: 12 })
      }, (field: InputField) => field.label)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 20 })
  }

  /**
   * 构建备注区域
   */
  @Builder
  buildNoteSection() {
    Column() {
      Text('备注')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      TextArea({ text: this.note, placeholder: '记录今日感受...' })
        .width('100%')
        .height(100)
        .fontSize(15)
        .backgroundColor(this.colors.surfaceVariant)
        .borderRadius(8)
        .onChange((value: string) => {
          this.note = value;
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 20 })
  }

  /**
   * 构建BMI提示
   */
  @Builder
  buildBMIHint() {
    Row() {
      Column() {
        Text('体重指数 (BMI)')
          .fontSize(14)
          .fontColor(this.colors.textTertiary)

        Text(`${calculateBMI(parseFloat(this.weight), parseFloat(this.heightValue))} - ${getBMICategory(calculateBMI(parseFloat(this.weight), parseFloat(this.heightValue)))}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.primary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.themeManager.isDark() ? this.colors.surfaceVariant : '#E8F8F5')
    .borderRadius(12)
  }

  /**
   * 构建成功提示
   */
  @Builder
  buildSuccessToast() {
    Column() {
      Text('✓')
        .fontSize(40)
        .fontColor(this.colors.textInverse)
        .margin({ bottom: 10 })

      Text('保存成功')
        .fontSize(16)
        .fontColor(this.colors.textInverse)
    }
    .width(150)
    .height(150)
    .backgroundColor(this.colors.primary)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .position({ x: '50%', y: '40%' })
    .translate({ x: '-50%', y: '-50%' })
    .shadow({
      radius: 20,
      color: '#40000000',
      offsetX: 0,
      offsetY: 4
    })
  }
}
