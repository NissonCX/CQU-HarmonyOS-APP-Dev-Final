/**
 * 提醒设置页面
 * 用于管理各类健康提醒
 */
import { ReminderSettings, ReminderType } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';
import { ReminderManager } from '../utils/ReminderManager';
import { generateId } from '../utils/CommonUtils';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct ReminderSettingsPage {
  @State reminders: ReminderSettings[] = [];
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  @State showEditDialog: boolean = false;
  @State editingReminder: ReminderSettings | null = null;
  @State editMode: 'fixed' | 'interval' = 'fixed';
  @State editTime: string = '';
  @State editRepeatDays: number[] = [];
  @State editIntervalMinutes: number = 120;
  @State editStartTime: string = '08:00';
  @State editEndTime: string = '22:00';
  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private reminderManager: ReminderManager = ReminderManager.getInstance();

  async aboutToAppear() {
    // 请求通知权限
    await this.reminderManager.requestNotificationPermission();
    // 加载提醒设置
    this.loadReminders();
  }

  /**
   * 加载提醒设置
   */
  async loadReminders() {
    this.reminders = await this.dataManager.getAllReminders();
    // 如果没有提醒，初始化默认提醒
    if (this.reminders.length === 0) {
      await this.initDefaultReminders();
      this.reminders = await this.dataManager.getAllReminders();
    }
  }

  /**
   * 初始化默认提醒
   */
  async initDefaultReminders() {
    const defaultReminders: ReminderSettings[] = [
      {
        id: generateId(),
        type: ReminderType.DAILY_RECORD,
        enabled: false,
        mode: 'fixed',
        time: '21:00',
        repeatDays: [1, 2, 3, 4, 5, 6, 0], // 每天
        title: '记录今日数据',
        content: '别忘了记录今天的健康数据哦~'
      },
      {
        id: generateId(),
        type: ReminderType.DRINK_WATER,
        enabled: false,
        mode: 'interval',
        intervalMinutes: 120,  // 每2小时提醒一次
        startTime: '08:00',    // 早上8点开始
        endTime: '22:00',      // 晚上10点结束
        title: '喝水提醒',
        content: '该喝水了，保持充足的水分摄入~'
      },
      {
        id: generateId(),
        type: ReminderType.EXERCISE,
        enabled: false,
        mode: 'fixed',
        time: '18:00',
        repeatDays: [1, 2, 3, 4, 5], // 工作日
        title: '运动提醒',
        content: '该运动了，动起来让身体更健康~'
      },
      {
        id: generateId(),
        type: ReminderType.SLEEP,
        enabled: false,
        mode: 'fixed',
        time: '22:30',
        repeatDays: [1, 2, 3, 4, 5, 6, 0], // 每天
        title: '睡眠提醒',
        content: '该休息了，充足的睡眠很重要~'
      }
    ];

    for (const reminder of defaultReminders) {
      await this.dataManager.saveReminder(reminder);
    }
  }

  /**
   * 更新主题颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  /**
   * 切换提醒开关
   */
  async toggleReminder(reminder: ReminderSettings, index: number) {
    // 直接修改状态数组中的对象
    this.reminders[index].enabled = !this.reminders[index].enabled;

    // 保存到数据库
    await this.dataManager.saveReminder(this.reminders[index]);

    // 发布或取消系统提醒
    if (this.reminders[index].enabled) {
      const success = await this.reminderManager.publishReminder(this.reminders[index]);
      if (!success) {
        // 发布失败，回滚状态
        this.reminders[index].enabled = false;
        await this.dataManager.saveReminder(this.reminders[index]);
        promptAction.showToast({
          message: '提醒设置失败，请检查权限',
          duration: 2000
        });
      } else {
        promptAction.showToast({
          message: '提醒已开启',
          duration: 1500
        });
      }
    } else {
      await this.reminderManager.cancelReminder(this.reminders[index].id);
      promptAction.showToast({
        message: '提醒已关闭',
        duration: 1500
      });
    }

    // 触发UI更新 - 创建新数组引用
    this.reminders = [...this.reminders];
  }

  /**
   * 编辑提醒
   */
  editReminder(reminder: ReminderSettings) {
    this.editingReminder = reminder;
    this.editMode = reminder.mode;

    if (reminder.mode === 'fixed') {
      this.editTime = reminder.time || '';
      this.editRepeatDays = reminder.repeatDays ? [...reminder.repeatDays] : [];
    } else {
      this.editIntervalMinutes = reminder.intervalMinutes || 120;
      this.editStartTime = reminder.startTime || '08:00';
      this.editEndTime = reminder.endTime || '22:00';
    }

    this.showEditDialog = true;
  }

  /**
   * 保存编辑
   */
  async saveEdit() {
    if (this.editingReminder) {
      const wasEnabled = this.editingReminder.enabled;

      this.editingReminder.mode = this.editMode;

      if (this.editMode === 'fixed') {
        this.editingReminder.time = this.editTime;
        this.editingReminder.repeatDays = [...this.editRepeatDays];
        // 清空间隔模式的字段
        this.editingReminder.intervalMinutes = undefined;
        this.editingReminder.startTime = undefined;
        this.editingReminder.endTime = undefined;
      } else {
        this.editingReminder.intervalMinutes = this.editIntervalMinutes;
        this.editingReminder.startTime = this.editStartTime;
        this.editingReminder.endTime = this.editEndTime;
        // 清空固定时间模式的字段
        this.editingReminder.time = undefined;
        this.editingReminder.repeatDays = undefined;
      }

      await this.dataManager.saveReminder(this.editingReminder);

      // 如果提醒已开启，需要重新发布
      if (wasEnabled) {
        await this.reminderManager.cancelReminder(this.editingReminder.id);
        const success = await this.reminderManager.publishReminder(this.editingReminder);
        if (!success) {
          promptAction.showToast({
            message: '提醒设置失败，请检查权限',
            duration: 2000
          });
        }
      }

      // 触发UI更新
      this.reminders = [...this.reminders];

      promptAction.showToast({
        message: '保存成功',
        duration: 1500
      });

      this.showEditDialog = false;
    }
  }

  /**
   * 取消编辑
   */
  cancelEdit() {
    this.showEditDialog = false;
    this.editingReminder = null;
  }

  /**
   * 切换重复日期
   */
  toggleRepeatDay(day: number) {
    const index = this.editRepeatDays.indexOf(day);
    if (index >= 0) {
      this.editRepeatDays.splice(index, 1);
    } else {
      this.editRepeatDays.push(day);
    }
    this.editRepeatDays = [...this.editRepeatDays];
  }

  /**
   * 选择所有日期
   */
  selectAllDays() {
    this.editRepeatDays = [1, 2, 3, 4, 5, 6, 0];
  }

  /**
   * 选择工作日
   */
  selectWorkdays() {
    this.editRepeatDays = [1, 2, 3, 4, 5];
  }

  /**
   * 选择周末
   */
  selectWeekends() {
    this.editRepeatDays = [0, 6];
  }

  /**
   * 获取提醒类型名称
   */
  getReminderTypeName(type: ReminderType): string {
    switch (type) {
      case ReminderType.DAILY_RECORD:
        return '每日记录';
      case ReminderType.DRINK_WATER:
        return '喝水提醒';
      case ReminderType.EXERCISE:
        return '运动提醒';
      case ReminderType.SLEEP:
        return '睡眠提醒';
      case ReminderType.MEDICINE:
        return '用药提醒';
      default:
        return '未知提醒';
    }
  }

  /**
   * 获取提醒类型图标
   */
  getReminderTypeIcon(type: ReminderType): string {
    switch (type) {
      case ReminderType.DAILY_RECORD:
        return '📝';
      case ReminderType.DRINK_WATER:
        return '💧';
      case ReminderType.EXERCISE:
        return '🏃';
      case ReminderType.SLEEP:
        return '🌙';
      case ReminderType.MEDICINE:
        return '💊';
      default:
        return '🔔';
    }
  }

  /**
   * 格式化重复日期
   */
  formatRepeatDays(repeatDays?: number[]): string {
    if (!repeatDays || repeatDays.length === 0) {
      return '';
    }

    if (repeatDays.length === 7) {
      return '每天';
    }

    const workdays = [1, 2, 3, 4, 5];
    const isWorkdays = workdays.every(day => repeatDays.includes(day)) &&
                       !repeatDays.includes(0) &&
                       !repeatDays.includes(6);
    if (isWorkdays) {
      return '工作日';
    }

    const dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return repeatDays.sort().map(day => dayNames[day]).join(', ');
  }

  /**
   * 格式化提醒时间信息
   */
  formatReminderTime(reminder: ReminderSettings): string {
    if (reminder.mode === 'interval') {
      // 检查必要字段是否存在
      if (!reminder.intervalMinutes) {
        return '间隔时间未设置';
      }
      
      const hours = Math.floor(reminder.intervalMinutes / 60);
      const minutes = reminder.intervalMinutes % 60;
      let intervalText = '';
      
      if (hours > 0) {
        intervalText = `每${hours}小时`;
        if (minutes > 0) {
          intervalText += `${minutes}分钟`;
        }
      } else {
        // 确保至少显示分钟数
        intervalText = `每${minutes}分钟`;
      }
      
      // 检查开始和结束时间是否存在
      const startTime = reminder.startTime || '未设置';
      const endTime = reminder.endTime || '未设置';
      
      return `${intervalText} (${startTime}-${endTime})`;
    } else {
      return reminder.time || '时间未设置';
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

        Text('提醒设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text(' ')
          .fontSize(24)
          .width(24) // 占位保持居中
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.colors.surface)

      Scroll() {
        Column() {
          // 提示信息
          Column() {
            Text('💡 设置健康提醒')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary)
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)

            Text('开启提醒后，应用会在指定时间向你发送通知，帮助你养成良好的健康习惯。')
              .fontSize(14)
              .fontColor(this.colors.textSecondary)
              .lineHeight(22)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.themeManager.isDark() ? this.colors.surfaceVariant : '#E8F5FF')
          .borderRadius(12)
          .margin({ bottom: 20 })

          // 提醒列表
          if (this.reminders.length === 0) {
            this.buildEmptyState()
          } else {
            ForEach(this.reminders, (reminder: ReminderSettings, index: number) => {
              this.buildReminderItem(reminder, index);
            }, (reminder: ReminderSettings) => reminder.id)
          }
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 编辑对话框
      if (this.showEditDialog && this.editingReminder) {
        this.buildEditDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  /**
   * 构建空状态
   */
  @Builder
  buildEmptyState() {
    Column() {
      Text('🔔')
        .fontSize(48)
        .margin({ bottom: 12 })

      Text('暂无提醒')
        .fontSize(16)
        .fontColor(this.colors.textSecondary)
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建提醒项
   */
  @Builder
  buildReminderItem(reminder: ReminderSettings, index: number) {
    Column() {
      Row() {
        // 左侧图标和信息
        Row() {
          Text(this.getReminderTypeIcon(reminder.type))
            .fontSize(32)
            .margin({ right: 12 })

          Column() {
            Text(this.getReminderTypeName(reminder.type))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary)
              .alignSelf(ItemAlign.Start)

            Text(reminder.content)
              .fontSize(13)
              .fontColor(this.colors.textSecondary)
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .alignSelf(ItemAlign.Start)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)

        // 右侧开关
        Toggle({ type: ToggleType.Switch, isOn: reminder.enabled })
          .selectedColor(this.colors.primary)
          .onChange((isOn: boolean) => {
            this.toggleReminder(reminder, index);
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 时间和重复信息 - 始终显示
      Column() {
        // 时间信息行
        Row() {
          Text('🕐')
            .fontSize(14)
            .margin({ right: 6 })

          Text(this.formatReminderTime(reminder))
            .fontSize(14)
            .fontColor(this.colors.textSecondary)
        }
        .alignSelf(ItemAlign.Start)

        // 重复日期行（仅固定时间模式显示）
        if (reminder.mode === 'fixed' && reminder.repeatDays) {
          Row() {
            Text('📅')
              .fontSize(14)
              .margin({ right: 6 })

            Text(this.formatRepeatDays(reminder.repeatDays))
              .fontSize(14)
              .fontColor(this.colors.textSecondary)
          }
          .alignSelf(ItemAlign.Start)
          .margin({ top: 6 })
        }

        // 提醒模式标签
        Text(reminder.mode === 'interval' ? '间隔提醒' : '定时提醒')
          .fontSize(12)
          .fontColor(this.colors.textInverse)
          .backgroundColor(reminder.mode === 'interval' ? this.colors.secondary : this.colors.primary)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
          .margin({ top: 8 })
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 编辑按钮 - 始终显示
      Text('编辑')
        .fontSize(14)
        .fontColor(this.colors.primary)
        .margin({ top: 12 })
        .onClick(() => {
          this.editReminder(reminder);
        })
        .alignSelf(ItemAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .shadow({
      radius: 8,
      color: this.colors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }

  /**
   * 构建编辑对话框
   */
  @Builder
  buildEditDialog() {
    Stack() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.cancelEdit();
        })

      // 对话框内容
      Column() {
        // 对话框标题
        Row() {
          Text('编辑提醒')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.colors.textPrimary)
            .layoutWeight(1)

          Text('✕')
            .fontSize(24)
            .fontColor(this.colors.textSecondary)
            .onClick(() => {
              this.cancelEdit();
            })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor(this.colors.surface)

        Scroll() {
          Column() {
            // 提醒类型
            Column() {
              Text('提醒类型')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8 })

              Row() {
                Text(this.getReminderTypeIcon(this.editingReminder!.type))
                  .fontSize(24)
                  .margin({ right: 8 })

                Text(this.getReminderTypeName(this.editingReminder!.type))
                  .fontSize(16)
                  .fontColor(this.colors.textPrimary)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.colors.surfaceVariant)
              .borderRadius(8)
            }
            .width('100%')
            .margin({ bottom: 20 })

            // 提醒模式选择
            Column() {
              Text('提醒模式')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8 })

              Row() {
                // 定时提醒按钮
                Text('定时提醒')
                  .fontSize(15)
                  .fontColor(this.editMode === 'fixed' ? this.colors.textInverse : this.colors.textPrimary)
                  .backgroundColor(this.editMode === 'fixed' ? this.colors.primary : this.colors.surface)
                  .padding(12)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .border({
                    width: 2,
                    color: this.editMode === 'fixed' ? this.colors.primary : this.colors.border
                  })
                  .onClick(() => {
                    this.editMode = 'fixed';
                  })

                // 间隔提醒按钮
                Text('间隔提醒')
                  .fontSize(15)
                  .fontColor(this.editMode === 'interval' ? this.colors.textInverse : this.colors.textPrimary)
                  .backgroundColor(this.editMode === 'interval' ? this.colors.secondary : this.colors.surface)
                  .padding(12)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .border({
                    width: 2,
                    color: this.editMode === 'interval' ? this.colors.secondary : this.colors.border
                  })
                  .onClick(() => {
                    this.editMode = 'interval';
                  })
                  .margin({ left: 12 })
              }
              .width('100%')
            }
            .width('100%')
            .margin({ bottom: 20 })

            // 定时提醒设置
            if (this.editMode === 'fixed') {
              Column() {
                // 提醒时间
                Column() {
                  Text('提醒时间')
                    .fontSize(14)
                    .fontColor(this.colors.textSecondary)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 8 })

                  Row() {
                    Text('🕐')
                      .fontSize(20)
                      .margin({ right: 8 })

                    TextInput({ text: this.editTime, placeholder: '请输入时间 (HH:mm)' })
                      .layoutWeight(1)
                      .height(44)
                      .fontSize(16)
                      .backgroundColor(this.colors.surfaceVariant)
                      .borderRadius(8)
                      .onChange((value: string) => {
                        this.editTime = value;
                      })
                  }
                  .width('100%')
                }
                .width('100%')
                .margin({ bottom: 20 })

                // 重复设置
                this.buildRepeatDaysSection()
              }
              .width('100%')
            }

            // 间隔提醒设置
            if (this.editMode === 'interval') {
              Column() {
                // 间隔时间
                Column() {
                  Text('提醒间隔')
                    .fontSize(14)
                    .fontColor(this.colors.textSecondary)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 8 })

                  Row() {
                    Text('⏱️')
                      .fontSize(20)
                      .margin({ right: 8 })

                    TextInput({
                      text: this.editIntervalMinutes.toString(),
                      placeholder: '输入分钟数'
                    })
                      .layoutWeight(1)
                      .height(44)
                      .fontSize(16)
                      .type(InputType.Number)
                      .backgroundColor(this.colors.surfaceVariant)
                      .borderRadius(8)
                      .onChange((value: string) => {
                        this.editIntervalMinutes = parseInt(value) || 120;
                      })

                    Text('分钟')
                      .fontSize(14)
                      .fontColor(this.colors.textSecondary)
                      .margin({ left: 8 })
                  }
                  .width('100%')
                }
                .width('100%')
                .margin({ bottom: 16 })

                // 快捷间隔按钮
                Row() {
                  Text('30分钟')
                    .fontSize(13)
                    .fontColor(this.colors.primary)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(this.colors.surface)
                    .borderRadius(6)
                    .border({ width: 1, color: this.colors.border })
                    .onClick(() => {
                      this.editIntervalMinutes = 30;
                    })

                  Text('1小时')
                    .fontSize(13)
                    .fontColor(this.colors.primary)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(this.colors.surface)
                    .borderRadius(6)
                    .border({ width: 1, color: this.colors.border })
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.editIntervalMinutes = 60;
                    })

                  Text('2小时')
                    .fontSize(13)
                    .fontColor(this.colors.primary)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(this.colors.surface)
                    .borderRadius(6)
                    .border({ width: 1, color: this.colors.border })
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.editIntervalMinutes = 120;
                    })

                  Text('3小时')
                    .fontSize(13)
                    .fontColor(this.colors.primary)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor(this.colors.surface)
                    .borderRadius(6)
                    .border({ width: 1, color: this.colors.border })
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.editIntervalMinutes = 180;
                    })
                }
                .width('100%')
                .margin({ bottom: 20 })

                // 生效时间段
                Column() {
                  Text('生效时间段')
                    .fontSize(14)
                    .fontColor(this.colors.textSecondary)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 8 })

                  Row() {
                    // 开始时间
                    Row() {
                      Text('从')
                        .fontSize(14)
                        .fontColor(this.colors.textSecondary)
                        .margin({ right: 6 })

                      TextInput({ text: this.editStartTime, placeholder: 'HH:mm' })
                        .layoutWeight(1)
                        .height(40)
                        .fontSize(15)
                        .backgroundColor(this.colors.surfaceVariant)
                        .borderRadius(6)
                        .onChange((value: string) => {
                          this.editStartTime = value;
                        })
                    }
                    .layoutWeight(1)

                    Text('-')
                      .fontSize(16)
                      .fontColor(this.colors.textSecondary)
                      .margin({ left: 8, right: 8 })

                    // 结束时间
                    Row() {
                      Text('至')
                        .fontSize(14)
                        .fontColor(this.colors.textSecondary)
                        .margin({ right: 6 })

                      TextInput({ text: this.editEndTime, placeholder: 'HH:mm' })
                        .layoutWeight(1)
                        .height(40)
                        .fontSize(15)
                        .backgroundColor(this.colors.surfaceVariant)
                        .borderRadius(6)
                        .onChange((value: string) => {
                          this.editEndTime = value;
                        })
                    }
                    .layoutWeight(1)
                  }
                  .width('100%')
                }
                .width('100%')
              }
              .width('100%')
            }

            // 提示信息
            if (this.editingReminder) {
              Column() {
                Text(this.editingReminder.content)
                  .fontSize(13)
                  .fontColor(this.colors.textSecondary)
                  .lineHeight(20)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.themeManager.isDark() ? this.colors.surfaceVariant : '#E8F5FF')
              .borderRadius(8)
              .margin({ bottom: 20 })
            }
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)

        // 底部按钮
        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor(this.colors.textSecondary)
            .backgroundColor(this.colors.surfaceVariant)
            .width('48%')
            .height(44)
            .onClick(() => {
              this.cancelEdit();
            })

          Button('保存')
            .fontSize(16)
            .fontColor(this.colors.textInverse)
            .backgroundColor(this.colors.primary)
            .width('48%')
            .height(44)
            .onClick(() => {
              this.saveEdit();
            })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor(this.colors.surface)
      }
      .width('90%')
      .height('70%')
      .backgroundColor(this.colors.background)
      .borderRadius(16)
      .shadow({
        radius: 24,
        color: '#40000000',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  /**
   * 构建重复日期选择区域
   */
  @Builder
  buildRepeatDaysSection() {
    Column() {
      Row() {
        Text('重复日期')
          .fontSize(14)
          .fontColor(this.colors.textSecondary)
          .layoutWeight(1)

        // 快捷按钮
        Row() {
          Text('每天')
            .fontSize(12)
            .fontColor(this.colors.primary)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.colors.surface)
            .borderRadius(4)
            .onClick(() => {
              this.selectAllDays();
            })
            .margin({ right: 6 })

          Text('工作日')
            .fontSize(12)
            .fontColor(this.colors.primary)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.colors.surface)
            .borderRadius(4)
            .onClick(() => {
              this.selectWorkdays();
            })
            .margin({ right: 6 })

          Text('周末')
            .fontSize(12)
            .fontColor(this.colors.primary)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.colors.surface)
            .borderRadius(4)
            .onClick(() => {
              this.selectWeekends();
            })
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 星期选择器
      Row() {
        this.buildDayButton('周一', 1)
        this.buildDayButton('周二', 2)
        this.buildDayButton('周三', 3)
        this.buildDayButton('周四', 4)
        this.buildDayButton('周五', 5)
        this.buildDayButton('周六', 6)
        this.buildDayButton('周日', 0)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }

  /**
   * 构建星期按钮
   */
  @Builder
  buildDayButton(label: string, day: number) {
    Text(label)
      .fontSize(13)
      .fontColor(this.editRepeatDays.includes(day) ? this.colors.textInverse : this.colors.textPrimary)
      .backgroundColor(this.editRepeatDays.includes(day) ? this.colors.primary : this.colors.surface)
      .width(45)
      .height(45)
      .textAlign(TextAlign.Center)
      .borderRadius(22.5)
      .border({
        width: 2,
        color: this.editRepeatDays.includes(day) ? this.colors.primary : this.colors.border
      })
      .onClick(() => {
        this.toggleRepeatDay(day);
      })
  }
}
