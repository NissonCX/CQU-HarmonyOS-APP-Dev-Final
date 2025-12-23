/**
 * 个人信息编辑页面
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { UserInfo } from '../models/HealthRecord';
import { DataManager } from '../utils/DataManager';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';

@Entry
@Component
struct ProfileEditPage {
  @State userInfo: UserInfo = {
    nickname: '',
    avatar: '',
    gender: 'male',
    signature: ''
  };
  @State colors: ThemeColors = getThemeColors();
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;

  private dataManager: DataManager = DataManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();

  // 预设头像列表
  private avatars: string[] = ['👨', '👩', '🧑', '👧', '👦', '🧓', '👴', '👵', '🐱', '🐶', '🐰', '🦊', '🐼', '🐨', '🐯', '🦁'];

  async aboutToAppear() {
    this.userInfo = await this.dataManager.getUserInfo();
  }

  updateColors() {
    this.colors = getThemeColors();
  }

  async saveProfile() {
    if (!this.userInfo.nickname.trim()) {
      promptAction.showToast({
        message: '请输入昵称',
        duration: 2000
      });
      return;
    }

    const success = await this.dataManager.saveUserInfo(this.userInfo);
    if (success) {
      promptAction.showToast({
        message: '保存成功',
        duration: 2000
      });
      setTimeout(() => {
        router.back();
      }, 500);
    } else {
      promptAction.showToast({
        message: '保存失败，请重试',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('<') // 使用文本符号替代图标
          .fontSize(24)
          .fontColor(this.colors.textPrimary)
          .onClick(() => {
            router.back();
          })

        Text('编辑个人信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .margin({ left: 16 })

        Blank()

        Text('保存')
          .fontSize(16)
          .fontColor(this.colors.primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.saveProfile();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .backgroundColor(this.colors.background)

      Scroll() {
        Column({ space: 20 }) {
          // 头像选择
          Column() {
            Text('选择头像')
              .fontSize(14)
              .fontColor(this.colors.textSecondary)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            Grid() {
              ForEach(this.avatars, (avatar: string) => {
                GridItem() {
                  Text(avatar)
                    .fontSize(30)
                    .width(50)
                    .height(50)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(this.userInfo.avatar === avatar ? this.colors.primary + '33' : 'transparent')
                    .borderRadius(25)
                    .border({
                      width: this.userInfo.avatar === avatar ? 2 : 0,
                      color: this.colors.primary
                    })
                    .onClick(() => {
                      this.userInfo.avatar = avatar;
                    })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
            .rowsGap(10)
            .height(180)
          }
          .padding(15)
          .backgroundColor(this.colors.surface)
          .borderRadius(12)

          // 基本信息表单
          Column({ space: 15 }) {
            // 昵称
            Column() {
              Text('昵称')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              TextInput({ text: this.userInfo.nickname, placeholder: '请输入昵称' })
                .width('100%')
                .height(48)
                .backgroundColor(this.themeManager.isDark() ? '#1A1A1A' : '#F5F5F5')
                .borderRadius(8)
                .fontColor(this.colors.textPrimary)
                .onChange((value: string) => {
                  this.userInfo.nickname = value;
                })
            }

            // 个性签名
            Column() {
              Text('个性签名')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              TextInput({ text: this.userInfo.signature, placeholder: '写一句鼓励自己的话' })
                .width('100%')
                .height(48)
                .backgroundColor(this.themeManager.isDark() ? '#1A1A1A' : '#F5F5F5')
                .borderRadius(8)
                .fontColor(this.colors.textPrimary)
                .onChange((value: string) => {
                  this.userInfo.signature = value;
                })
            }

            // 性别
            Column() {
              Text('性别')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              Row({ space: 15 }) {
                this.GenderOption('male', '男 👨')
                this.GenderOption('female', '女 👩')
              }
              .width('100%')
            }

            // 身高
            Column() {
              Text('身高 (cm)')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              TextInput({ text: this.userInfo.height ? this.userInfo.height.toString() : '', placeholder: '0' })
                .width('100%')
                .height(48)
                .type(InputType.Number)
                .backgroundColor(this.themeManager.isDark() ? '#1A1A1A' : '#F5F5F5')
                .borderRadius(8)
                .fontColor(this.colors.textPrimary)
                .onChange((value: string) => {
                  const val = parseFloat(value);
                  if (!isNaN(val)) {
                    this.userInfo.height = val;
                  }
                })
            }

            // 目标体重
            Column() {
              Text('目标体重 (kg)')
                .fontSize(14)
                .fontColor(this.colors.textSecondary)
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              TextInput({ text: this.userInfo.targetWeight ? this.userInfo.targetWeight.toString() : '', placeholder: '0' })
                .width('100%')
                .height(48)
                .type(InputType.Number)
                .backgroundColor(this.themeManager.isDark() ? '#1A1A1A' : '#F5F5F5')
                .borderRadius(8)
                .fontColor(this.colors.textPrimary)
                .onChange((value: string) => {
                  const val = parseFloat(value);
                  if (!isNaN(val)) {
                    this.userInfo.targetWeight = val;
                  }
                })
            }
          }
          .padding(15)
          .backgroundColor(this.colors.surface)
          .borderRadius(12)
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  @Builder
  GenderOption(value: string, label: string) {
    Row() {
      Radio({ value: value, group: 'gender' })
        .checked(this.userInfo.gender === value)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.userInfo.gender = value as 'male' | 'female' | 'other';
          }
        })
      Text(label)
        .fontSize(16)
        .fontColor(this.colors.textPrimary)
    }
  }
}
