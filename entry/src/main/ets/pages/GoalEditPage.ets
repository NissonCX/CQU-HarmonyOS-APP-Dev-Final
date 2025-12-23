/**
 * 目标编辑页面
 * 用于添加或编辑健康目标
 */
import { HealthGoal, GoalType, GoalDirection } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { generateId } from '../utils/CommonUtils';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct GoalEditPage {
  @State goalType: GoalType = GoalType.WEIGHT;
  @State goalDirection: GoalDirection = GoalDirection.DECREASE;
  @State targetValue: string = '';
  @State deadline: string = '';
  @State isEdit: boolean = false;
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private editGoalId: string = '';
  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();

  aboutToAppear() {
    // 检查是否是编辑模式
    const params = router.getParams() as Record<string, Object>;
    if (params && params['goal']) {
      this.isEdit = true;
      const goal = params['goal'] as HealthGoal;
      this.editGoalId = goal.id;
      this.goalType = goal.type;
      this.goalDirection = goal.direction || GoalDirection.INCREASE;
      this.targetValue = goal.targetValue.toString();
      this.deadline = goal.deadline || '';
    } else {
      // 新建模式：根据目标类型设置默认方向
      this.updateDefaultDirection();
    }
  }

  /**
   * 根据目标类型更新默认方向
   */
  updateDefaultDirection() {
    switch (this.goalType) {
      case GoalType.WEIGHT:
        this.goalDirection = GoalDirection.DECREASE; // 默认减重
        break;
      case GoalType.STEPS:
      case GoalType.WATER:
      case GoalType.SLEEP:
      case GoalType.EXERCISE:
        this.goalDirection = GoalDirection.INCREASE; // 默认增加
        break;
    }
  }

  /**
   * 更新主题颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  /**
   * 保存目标
   */
  async saveGoal() {
    // 验证输入
    if (!this.targetValue || Number(this.targetValue) <= 0) {
      promptAction.showToast({
        message: '请输入有效的目标值',
        duration: 2000
      });
      return;
    }

    const goal: HealthGoal = {
      id: this.isEdit ? this.editGoalId : generateId(),
      type: this.goalType,
      targetValue: Number(this.targetValue),
      currentValue: 0,
      unit: this.getUnitForType(this.goalType),
      direction: this.goalDirection,
      deadline: this.deadline,
      isCompleted: false
    };

    const success = await this.dataManager.saveHealthGoal(goal);
    if (success) {
      promptAction.showToast({
        message: this.isEdit ? '目标已更新' : '目标已添加',
        duration: 2000
      });
      router.back();
    } else {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    }
  }

  /**
   * 获取目标类型对应的单位
   */
  getUnitForType(type: GoalType): string {
    switch (type) {
      case GoalType.WEIGHT:
        return 'kg';
      case GoalType.STEPS:
        return '步';
      case GoalType.WATER:
        return 'ml';
      case GoalType.SLEEP:
        return '小时';
      case GoalType.EXERCISE:
        return '分钟';
      default:
        return '';
    }
  }

  /**
   * 获取目标类型名称
   */
  getGoalTypeName(type: GoalType): string {
    switch (type) {
      case GoalType.WEIGHT:
        return '目标体重';
      case GoalType.STEPS:
        return '每日步数';
      case GoalType.WATER:
        return '每日饮水';
      case GoalType.SLEEP:
        return '睡眠时长';
      case GoalType.EXERCISE:
        return '运动时长';
      default:
        return '未知目标';
    }
  }

  /**
   * 获取目标方向名称
   */
  getDirectionName(direction: GoalDirection): string {
    switch (direction) {
      case GoalDirection.DECREASE:
        return '减少到';
      case GoalDirection.INCREASE:
        return '增加到';
      case GoalDirection.REACH:
        return '达到';
      default:
        return '达到';
    }
  }

  /**
   * 获取目标类型可用的方向选项
   */
  getAvailableDirections(type: GoalType): GoalDirection[] {
    switch (type) {
      case GoalType.WEIGHT:
        // 体重可以减少或增加
        return [GoalDirection.DECREASE, GoalDirection.INCREASE];
      case GoalType.STEPS:
      case GoalType.WATER:
      case GoalType.SLEEP:
      case GoalType.EXERCISE:
        // 其他指标通常是增加或达到
        return [GoalDirection.INCREASE, GoalDirection.REACH];
      default:
        return [GoalDirection.REACH];
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor(this.colors.textPrimary)
          .onClick(() => {
            router.back();
          })

        Text(this.isEdit ? '编辑目标' : '添加目标')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('保存')
          .fontSize(16)
          .fontColor(this.colors.primary)
          .onClick(() => {
            this.saveGoal();
          })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.colors.surface)

      Scroll() {
        Column() {
          // 目标类型选择
          Column() {
            Text('目标类型')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary)
              .margin({ bottom: 15 })
              .alignSelf(ItemAlign.Start)

            Column() {
              this.buildGoalTypeOption(GoalType.WEIGHT, '目标体重', 'kg')
              this.buildGoalTypeOption(GoalType.STEPS, '每日步数', '步')
              this.buildGoalTypeOption(GoalType.WATER, '每日饮水', 'ml')
              this.buildGoalTypeOption(GoalType.SLEEP, '睡眠时长', '小时')
              this.buildGoalTypeOption(GoalType.EXERCISE, '运动时长', '分钟')
            }
            .width('100%')
            .backgroundColor(this.colors.surface)
            .borderRadius(12)
            .padding(10)
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 目标方向选择
          Column() {
            Text('目标方向')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary)
              .margin({ bottom: 15 })
              .alignSelf(ItemAlign.Start)

            Column() {
              ForEach(this.getAvailableDirections(this.goalType), (direction: GoalDirection) => {
                this.buildDirectionOption(direction);
              }, (direction: GoalDirection) => direction)
            }
            .width('100%')
            .backgroundColor(this.colors.surface)
            .borderRadius(12)
            .padding(10)
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 目标值输入
          Column() {
            Text('目标值')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary)
              .margin({ bottom: 15 })
              .alignSelf(ItemAlign.Start)

            Row() {
              TextInput({ placeholder: '请输入目标值', text: this.targetValue })
                .layoutWeight(1)
                .type(InputType.Number)
                .fontSize(16)
                .backgroundColor(this.colors.surface)
                .onChange((value: string) => {
                  this.targetValue = value;
                })

              Text(this.getUnitForType(this.goalType))
                .fontSize(14)
                .fontColor(this.colors.textTertiary)
                .margin({ left: 10 })
            }
            .width('100%')
            .padding(15)
            .backgroundColor(this.colors.surface)
            .borderRadius(12)
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 截止日期（可选）
          Column() {
            Text('截止日期（可选）')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary)
              .margin({ bottom: 15 })
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: 'YYYY-MM-DD', text: this.deadline })
              .width('100%')
              .fontSize(16)
              .backgroundColor(this.colors.surface)
              .borderRadius(12)
              .padding(15)
              .onChange((value: string) => {
                this.deadline = value;
              })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 提示信息
          Column() {
            Text('提示')
              .fontSize(14)
              .fontColor(this.colors.textTertiary)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            Text('• 目标进度会根据你的健康记录自动更新\n• 达到目标值后会自动标记为完成\n• 你可以随时编辑或删除目标')
              .fontSize(12)
              .fontColor(this.colors.textTertiary)
              .lineHeight(20)
          }
          .width('100%')
          .padding(15)
          .backgroundColor(this.themeManager.isDark() ? this.colors.surfaceVariant : '#FFF9E6')
          .borderRadius(12)
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
   * 构建目标类型选项
   */
  @Builder
  buildGoalTypeOption(type: GoalType, name: string, unit: string) {
    Row() {
      Row() {
        if (this.goalType === type) {
          Row()
            .width(16)
            .height(16)
            .backgroundColor(this.colors.primary)
            .borderRadius(8)
            .margin({ right: 10 })
        } else {
          Row()
            .width(16)
            .height(16)
            .border({ width: 2, color: this.colors.border })
            .borderRadius(8)
            .margin({ right: 10 })
        }

        Text(name)
          .fontSize(15)
          .fontColor(this.colors.textPrimary)

        Text(`(${unit})`)
          .fontSize(12)
          .fontColor(this.colors.textTertiary)
          .margin({ left: 5 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .padding({ left: 10, right: 10 })
    .onClick(() => {
      this.goalType = type;
      // 切换类型时，更新默认方向
      this.updateDefaultDirection();
    })
  }

  /**
   * 构建目标方向选项
   */
  @Builder
  buildDirectionOption(direction: GoalDirection) {
    Row() {
      Row() {
        if (this.goalDirection === direction) {
          Row()
            .width(16)
            .height(16)
            .backgroundColor(this.colors.primary)
            .borderRadius(8)
            .margin({ right: 10 })
        } else {
          Row()
            .width(16)
            .height(16)
            .border({ width: 2, color: this.colors.border })
            .borderRadius(8)
            .margin({ right: 10 })
        }

        Text(this.getDirectionName(direction))
          .fontSize(15)
          .fontColor(this.colors.textPrimary)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .padding({ left: 10, right: 10 })
    .onClick(() => {
      this.goalDirection = direction;
    })
  }
}
