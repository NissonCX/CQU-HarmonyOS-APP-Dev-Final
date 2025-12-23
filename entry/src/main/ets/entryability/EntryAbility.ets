import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DataManager } from '../utils/DataManager';
import { DataInitializer } from '../utils/DataInitializer';

const DOMAIN = 0x0000;

/**
 * 应用主Ability
 * 管理应用的生命周期和初始化工作
 */
export default class EntryAbility extends UIAbility {
  /**
   * Ability创建时的回调
   * 初始化数据管理器和应用配置
   */
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      // 设置颜色模式为系统默认
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    // 初始化数据管理器
    await DataManager.getInstance().init(this.context);

    // 初始化模拟数据（仅在首次启动时）
    try {
      const initializer = new DataInitializer();
      await initializer.initializeMockData();
      hilog.info(DOMAIN, 'testTag', 'Mock data initialized successfully');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize mock data. Cause: %{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * WindowStage创建时的回调
   * 加载主页面
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /**
   * WindowStage销毁时的回调
   * 释放UI相关资源
   */
  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  /**
   * Ability切换到前台时的回调
   */
  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  /**
   * Ability切换到后台时的回调
   */
  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}