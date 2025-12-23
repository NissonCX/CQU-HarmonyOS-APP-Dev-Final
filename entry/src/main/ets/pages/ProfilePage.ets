/**
 * 我的页面
 * 展示个人信息、目标管理和设置
 */
import { HealthGoal, GoalType, GoalDirection, UserInfo } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { DataInitializer } from '../utils/DataInitializer';
import { updateGoalsProgress } from '../utils/CommonUtils';
import { ThemeManager, ThemeType, ThemeColors, getThemeColors } from '../utils/ThemeManager';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Component
export struct ProfilePage {
  @State goals: HealthGoal[] = [];
  @State userName: string = '用户';
  @State userInfo: UserInfo = {
    nickname: '用户',
    avatar: '👨',
    gender: 'male',
    signature: '坚持记录健康数据'
  };
  @State totalRecords: number = 0;
  @State clickCount: number = 0; // 用于隐藏功能
  @StorageProp('appTheme') @Watch('onThemeChange') currentTheme: string = 'light';
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private intervalId: number = -1;

  aboutToAppear() {
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
    // 先更新目标进度
    await updateGoalsProgress();

    // 然后加载最新数据
    this.goals = await this.dataManager.getAllHealthGoals();
    const records = await this.dataManager.getAllHealthRecords();
    this.totalRecords = records.length;

    // 加载用户信息
    this.userInfo = await this.dataManager.getUserInfo();
    this.userName = this.userInfo.nickname;
  }

  /**
   * 计算目标完成度
   */
  calculateProgress(goal: HealthGoal): number {
    if (goal.targetValue === 0) return 0;
    return Math.min(100, Math.floor((goal.currentValue / goal.targetValue) * 100));
  }

  /**
   * 编辑目标
   */
  editGoal(goal: HealthGoal) {
    router.pushUrl({
      url: 'pages/GoalEditPage',
      params: {
        goal: goal
      }
    });
  }

  /**
   * 确认删除目标
   */
  confirmDeleteGoal(goal: HealthGoal) {
    promptAction.showDialog({
      title: '删除目标',
      message: `确定要删除"${this.getGoalTypeName(goal.type)}"吗？`,
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#FF6B6B' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        await this.deleteGoal(goal.id);
      }
    });
  }

  /**
   * 删除目标
   */
  async deleteGoal(goalId: string) {
    const success = await this.dataManager.deleteHealthGoal(goalId);
    if (success) {
      promptAction.showToast({
        message: '目标已删除',
        duration: 2000
      });
      this.loadData();
    } else {
      promptAction.showToast({
        message: '删除失败，请重试',
        duration: 2000
      });
    }
  }

  /**
   * 主题变化回调
   */
  onThemeChange() {
    // 主题已变化，组件会自动重新渲染
  }

  /**
   * 更新颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  /**
   * 切换主题
   */
  toggleTheme() {
    this.themeManager.toggleTheme();
    const isDark = this.themeManager.isDark();
    promptAction.showToast({
      message: isDark ? '已切换到暗色模式' : '已切换到浅色模式',
      duration: 2000
    });
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('我的')
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
          // 用户信息卡片
          this.buildUserInfoCard()

          // 统计信息
          this.buildStatisticsSection()

          // 健康目标
          this.buildGoalsSection()

          // 设置选项
          this.buildSettingsSection()
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
   * 构建用户信息卡片
   */
  @Builder
  buildUserInfoCard() {
    Row() {
      // 头像（连续点击5次显示数据管理选项）
      Column() {
        Text(this.userInfo.avatar || '👨')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
        .width(60)
        .height(60)
        .backgroundColor(this.colors.primary)
        .borderRadius(30)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.clickCount++;
          if (this.clickCount >= 5) {
            this.showDataManagementDialog();
            this.clickCount = 0;
          }
        })

      Column() {
        Row() {
          Text(this.userInfo.nickname || '用户')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)

          Text('✎') // 使用文本符号替代图标
            .fontSize(16)
            .fontColor(this.colors.textSecondary)
            .margin({ left: 8 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/ProfileEditPage'
              });
            })
        }

        Text(this.userInfo.signature || '坚持记录健康数据')
          .fontSize(14)
          .fontColor(this.colors.textTertiary)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 15 })
      .layoutWeight(1)
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ProfileEditPage'
        });
      })
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
   * 显示数据管理对话框
   */
  async showDataManagementDialog() {
    promptAction.showDialog({
      title: '数据管理',
      message: '选择操作',
      buttons: [
        { text: '重新生成数据', color: '#4ECDC4' },
        { text: '清空所有数据', color: '#FF6B6B' },
        { text: '取消', color: '#999999' }
      ]
    }).then(async (result) => {
      if (result.index === 0) {
        // 重新生成数据
        const initializer = new DataInitializer();
        await initializer.clearAllData();
        await initializer.initializeMockData();
        promptAction.showToast({
          message: '数据已重新生成',
          duration: 2000
        });
        this.loadData();
      } else if (result.index === 1) {
        // 清空数据
        const initializer = new DataInitializer();
        await initializer.clearAllData();
        promptAction.showToast({
          message: '数据已清空',
          duration: 2000
        });
        this.loadData();
      }
    });
  }

  /**
   * 构建统计信息区域
   */
  @Builder
  buildStatisticsSection() {
    Column() {
      Text('数据统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      Row() {
        this.buildStatItem('记录天数', this.totalRecords.toString(), this.colors.error)
        this.buildStatItem('完成目标', this.goals.filter(g => g.isCompleted).length.toString(), this.colors.primary)
        this.buildStatItem('进行中', this.goals.filter(g => !g.isCompleted).length.toString(), this.colors.secondary)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .margin({ bottom: 20 })
  }

  /**
   * 构建统计项
   */
  @Builder
  buildStatItem(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)

      Text(label)
        .fontSize(12)
        .fontColor(this.colors.textTertiary)
        .margin({ top: 5 })
    }
    .width('30%')
    .padding(15)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建目标区域
   */
  @Builder
  buildGoalsSection() {
    Column() {
      Row() {
        Text('我的目标')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        Text('添加')
          .fontSize(14)
          .fontColor(this.colors.primary)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/GoalEditPage'
            });
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 15 })

      if (this.goals.length === 0) {
        Text('暂无健康目标，点击添加新目标')
          .fontSize(14)
          .fontColor(this.colors.textTertiary)
          .padding(20)
          .width('100%')
          .backgroundColor(this.colors.surface)
          .borderRadius(12)
      } else {
        ForEach(this.goals, (goal: HealthGoal) => {
          this.buildGoalItem(goal);
        }, (goal: HealthGoal) => goal.id)
      }
    }
    .margin({ bottom: 20 })
  }

  /**
   * 构建目标项
   */
  @Builder
  buildGoalItem(goal: HealthGoal) {
    Column() {
      Row() {
        Column() {
          Text(this.getGoalTypeName(goal.type))
            .fontSize(16)
            .fontColor(this.colors.textPrimary)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)

          Text(this.getDirectionLabel(goal.direction || GoalDirection.INCREASE))
            .fontSize(12)
            .fontColor(this.colors.textSecondary)
            .margin({ top: 3 })
            .alignSelf(ItemAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(goal.isCompleted ? '已完成' : '进行中')
          .fontSize(12)
          .fontColor(goal.isCompleted ? this.colors.success : this.colors.error)
          .padding({ top: 4, bottom: 4, left: 10, right: 10 })
          .backgroundColor(goal.isCompleted ? (this.themeManager.isDark() ? '#1A3A38' : '#E8F8F5') : (this.themeManager.isDark() ? '#3A1F1F' : '#FFE8E8'))
          .borderRadius(10)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 10 })

      Row() {
        Text(`${goal.currentValue} / ${goal.targetValue} ${goal.unit}`)
          .fontSize(14)
          .fontColor(this.colors.textSecondary)

        Text(`${this.calculateProgress(goal)}%`)
          .fontSize(14)
          .fontColor(this.colors.primary)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 10 })

      // 进度条
      Row() {
        Row()
          .width(`${this.calculateProgress(goal)}%`)
          .height('100%')
          .backgroundColor(this.colors.primary)
          .borderRadius(4)
      }
      .width('100%')
      .height(8)
      .backgroundColor(this.themeManager.isDark() ? '#1A3A38' : '#E8F8F5')
      .borderRadius(4)
      .margin({ bottom: 10 })

      // 操作按钮
      Row() {
        Text('编辑')
          .fontSize(14)
          .fontColor(this.colors.primary)
          .padding({ top: 5, bottom: 5, left: 15, right: 15 })
          .backgroundColor(this.themeManager.isDark() ? '#1A3A38' : '#E8F8F5')
          .borderRadius(8)
          .onClick(() => {
            this.editGoal(goal);
          })

        Text('删除')
          .fontSize(14)
          .fontColor(this.colors.error)
          .padding({ top: 5, bottom: 5, left: 15, right: 15 })
          .backgroundColor(this.themeManager.isDark() ? '#3A1F1F' : '#FFE8E8')
          .borderRadius(8)
          .margin({ left: 10 })
          .onClick(() => {
            this.confirmDeleteGoal(goal);
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
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
   * 获取目标方向描述
   */
  getGoalDirectionDesc(goal: HealthGoal): string {
    const direction = goal.direction || GoalDirection.INCREASE;
    const typeName = this.getGoalTypeName(goal.type);

    switch (direction) {
      case GoalDirection.DECREASE:
        return `${typeName}（减少到${goal.targetValue}${goal.unit}）`;
      case GoalDirection.INCREASE:
        return `${typeName}（增加到${goal.targetValue}${goal.unit}）`;
      case GoalDirection.REACH:
        return `${typeName}（达到${goal.targetValue}${goal.unit}）`;
      default:
        return typeName;
    }
  }

  /**
   * 获取目标方向标签
   */
  getDirectionLabel(direction: GoalDirection): string {
    switch (direction) {
      case GoalDirection.DECREASE:
        return '减少目标';
      case GoalDirection.INCREASE:
        return '增加目标';
      case GoalDirection.REACH:
        return '达到目标';
      default:
        return '增加目标';
    }
  }

  /**
   * 构建设置区域
   */
  @Builder
  buildSettingsSection() {
    Column() {
      Text('设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      // 主题切换
      this.buildThemeToggle()

      this.buildSettingItem('提醒设置', () => {
        router.pushUrl({
          url: 'pages/ReminderSettingsPage'
        });
      })

      this.buildSettingItem('数据导出', () => {
        router.pushUrl({
          url: 'pages/ExportPage'
        });
      })

      this.buildSettingItem('关于应用', () => {
        promptAction.showDialog({
          title: '关于应用',
          message: 'HealthTracker v1.4\n\n个人健康管理助手\n\n帮助您记录和追踪日常健康数据\n\n✨ 支持浅色/暗色主题切换',
          buttons: [{ text: '确定', color: '#4ECDC4' }]
        });
      })
    }
  }

  /**
   * 构建主题切换开关
   */
  @Builder
  buildThemeToggle() {
    Row() {
      Column() {
        Text('暗色模式')
          .fontSize(15)
          .fontColor(this.colors.textPrimary)

        Text(this.themeManager.isDark() ? '护眼模式已开启' : '点击开启护眼模式')
          .fontSize(12)
          .fontColor(this.colors.textTertiary)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 切换开关
      Toggle({ type: ToggleType.Switch, isOn: this.themeManager.isDark() })
        .selectedColor(this.colors.primary)
        .onChange((isOn: boolean) => {
          this.toggleTheme();
        })
    }
    .width('100%')
    .height(60)
    .padding({ left: 15, right: 15 })
    .backgroundColor(this.colors.surface)
    .borderRadius(8)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 10 })
  }

  /**
   * 构建设置项
   */
  @Builder
  buildSettingItem(label: string, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.colors.textPrimary)

      Text('>')
        .fontSize(16)
        .fontColor(this.colors.textTertiary)
    }
    .width('100%')
    .height(50)
    .padding({ left: 15, right: 15 })
    .backgroundColor(this.colors.surface)
    .borderRadius(8)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 10 })
    .onClick(() => {
      onClick();
    })
  }
}
