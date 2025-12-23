/**
 * 应用主入口页面
 * 使用Tabs组件实现底部导航栏
 */
import { HomePage } from './HomePage';
import { TrendsPage } from './TrendsPage';
import { ProfilePage } from './ProfilePage';
import { ThemeManager, ThemeColors, getThemeColors } from '../utils/ThemeManager';
import { window } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State refreshKey: number = 0; // 用于触发子组件刷新
  @StorageLink('currentTabIndex') @Watch('onStorageTabIndexChange') storageTabIndex: number = 0;
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private themeManager: ThemeManager = ThemeManager.getInstance();

  aboutToAppear() {
    // 初始化AppStorage
    if (!AppStorage.has('currentTabIndex')) {
      AppStorage.setOrCreate('currentTabIndex', 0);
    }
    // 设置状态栏颜色
    this.setStatusBarColor();
  }

  onStorageTabIndexChange() {
    // 当AppStorage中的值变化时，更新当前索引
    this.currentIndex = this.storageTabIndex;
  }

  /**
   * 更新主题颜色
   */
  updateColors() {
    this.colors = getThemeColors();
    this.setStatusBarColor();
  }

  /**
   * 设置状态栏颜色
   */
  async setStatusBarColor() {
    try {
      const windowClass = await window.getLastWindow(getContext(this));
      const isDark = this.themeManager.isDark();

      // 设置状态栏背景颜色
      await windowClass.setWindowSystemBarProperties({
        statusBarContentColor: isDark ? '#FFFFFF' : '#000000', // 状态栏文字颜色
        navigationBarContentColor: isDark ? '#FFFFFF' : '#000000', // 导航栏按钮颜色
        statusBarColor: this.colors.background, // 状态栏背景色
        navigationBarColor: this.colors.surface // 导航栏背景色（底部虚拟按键区域）
      });
    } catch (err) {
      console.error('Failed to set status bar color:', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 使用Tabs组件实现底部导航
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        // 首页标签
        TabContent() {
          HomePage()
        }
        .tabBar(this.buildTabBarItem(0, '首页', '🏠'))

        // 趋势标签
        TabContent() {
          TrendsPage()
        }
        .tabBar(this.buildTabBarItem(1, '趋势', '📊'))

        // 我的标签
        TabContent() {
          ProfilePage()
        }
        .tabBar(this.buildTabBarItem(2, '我的', '👤'))
      }
      .width('100%')
      .height('100%')
      .barMode(BarMode.Fixed)
      .barBackgroundColor(this.colors.surface)
      .onChange((index: number) => {
        this.currentIndex = index;
        AppStorage.setOrCreate('currentTabIndex', index);
        // 切换标签时刷新对应页面
        this.refreshKey++;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colors.background)
  }

  /**
   * 构建底部导航栏项
   * @param index 标签索引
   * @param title 标签标题
   * @param icon 标签图标(文本)
   */
  @Builder
  buildTabBarItem(index: number, title: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(24)
        .fontColor(this.currentIndex === index ? this.colors.primary : this.colors.textTertiary)
        .margin({ bottom: 4 })

      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? this.colors.primary : this.colors.textTertiary)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}