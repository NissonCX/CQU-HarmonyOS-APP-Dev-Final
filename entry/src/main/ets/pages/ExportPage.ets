/**
 * 数据导出页面
 * 允许用户选择导出格式和数据类型
 */
import { ExportManager, ExportFormat, ExportDataType, ExportResult } from '../utils/ExportManager';
import { ThemeColors, getThemeColors, ThemeManager } from '../utils/ThemeManager';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

@Entry
@Component
struct ExportPage {
  @State selectedFormat: ExportFormat = ExportFormat.CSV;
  @State selectedDataType: ExportDataType = ExportDataType.ALL;
  @State isExporting: boolean = false;
  @State exportedFiles: string[] = [];
  @StorageProp('themeChanged') @Watch('updateColors') themeChanged: number = 0;
  @State colors: ThemeColors = getThemeColors();
  private exportManager: ExportManager = ExportManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();

  aboutToAppear() {
    this.loadExportedFiles();
  }

  /**
   * 加载已导出的文件列表
   */
  async loadExportedFiles() {
    try {
      this.exportedFiles = await this.exportManager.getExportedFiles(getContext(this));
      // 按时间倒序排列（最新的在前）
      this.exportedFiles.sort((a, b) => b.localeCompare(a));
    } catch (error) {
      console.error('加载导出文件列表失败:', JSON.stringify(error));
    }
  }

  /**
   * 更新颜色
   */
  updateColors() {
    this.colors = getThemeColors();
  }

  /**
   * 执行导出
   */
  async performExport() {
    if (this.isExporting) {
      return;
    }

    this.isExporting = true;

    try {
      const result: ExportResult = await this.exportManager.exportData(
        getContext(this),
        this.selectedDataType,
        this.selectedFormat
      );

      if (result.success) {
        promptAction.showDialog({
          title: '导出成功',
          message: result.message,
          buttons: [{ text: '确定', color: this.colors.primary }]
        });

        // 刷新文件列表
        await this.loadExportedFiles();
      } else {
        promptAction.showDialog({
          title: '导出失败',
          message: result.message,
          buttons: [{ text: '确定', color: this.colors.error }]
        });
      }
    } catch (error) {
      promptAction.showDialog({
        title: '导出失败',
        message: `发生错误: ${error.message || '未知错误'}`,
        buttons: [{ text: '确定', color: this.colors.error }]
      });
    } finally {
      this.isExporting = false;
    }
  }

  /**
   * 删除导出文件
   */
  async deleteFile(fileName: string) {
    promptAction.showDialog({
      title: '删除文件',
      message: `确定要删除文件 "${fileName}" 吗？`,
      buttons: [
        { text: '取消', color: this.colors.textSecondary },
        { text: '删除', color: this.colors.error }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        const success = await this.exportManager.deleteExportedFile(getContext(this), fileName);
        if (success) {
          promptAction.showToast({
            message: '文件已删除',
            duration: 2000
          });
          await this.loadExportedFiles();
        } else {
          promptAction.showToast({
            message: '删除失败',
            duration: 2000
          });
        }
      }
    });
  }

  /**
   * 清空所有导出文件
   */
  async clearAllFiles() {
    if (this.exportedFiles.length === 0) {
      promptAction.showToast({
        message: '没有可清空的文件',
        duration: 2000
      });
      return;
    }

    promptAction.showDialog({
      title: '清空所有文件',
      message: `确定要删除所有 ${this.exportedFiles.length} 个导出文件吗？`,
      buttons: [
        { text: '取消', color: this.colors.textSecondary },
        { text: '清空', color: this.colors.error }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        const deletedCount = await this.exportManager.clearAllExportedFiles(getContext(this));
        promptAction.showToast({
          message: `已删除 ${deletedCount} 个文件`,
          duration: 2000
        });
        await this.loadExportedFiles();
      }
    });
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

        Text('数据导出')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .margin({ left: 15 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // 导出格式选择
          this.buildFormatSection()

          // 数据类型选择
          this.buildDataTypeSection()

          // 导出按钮
          this.buildExportButton()

          // 已导出文件列表
          this.buildExportedFilesSection()
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
   * 构建格式选择区域
   */
  @Builder
  buildFormatSection() {
    Column() {
      Text('导出格式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      Row() {
        this.buildFormatOption('CSV', ExportFormat.CSV, '适合 Excel 打开')
        this.buildFormatOption('JSON', ExportFormat.JSON, '适合程序处理')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .margin({ bottom: 20 })
  }

  /**
   * 构建格式选项
   */
  @Builder
  buildFormatOption(label: string, format: ExportFormat, description: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedFormat === format ? this.colors.primary : this.colors.textPrimary)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 5 })

      Text(description)
        .fontSize(12)
        .fontColor(this.colors.textTertiary)
    }
    .width('48%')
    .padding(15)
    .backgroundColor(this.selectedFormat === format ?
      (this.themeManager.isDark() ? '#1A3A38' : '#E8F8F5') :
      this.colors.surface)
    .borderRadius(12)
    .border({
      width: 2,
      color: this.selectedFormat === format ? this.colors.primary : 'transparent'
    })
    .onClick(() => {
      this.selectedFormat = format;
    })
  }

  /**
   * 构建数据类型选择区域
   */
  @Builder
  buildDataTypeSection() {
    Column() {
      Text('导出内容')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.colors.textPrimary)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)

      this.buildDataTypeOption('全部数据', ExportDataType.ALL, '包含所有健康记录、目标和提醒')
      this.buildDataTypeOption('健康记录', ExportDataType.HEALTH_RECORDS, '仅导出日常健康数据记录')
      this.buildDataTypeOption('健康目标', ExportDataType.HEALTH_GOALS, '仅导出您的健康目标')
      this.buildDataTypeOption('提醒设置', ExportDataType.REMINDERS, '仅导出提醒配置')
    }
    .margin({ bottom: 20 })
  }

  /**
   * 构建数据类型选项
   */
  @Builder
  buildDataTypeOption(label: string, dataType: ExportDataType, description: string) {
    Row() {
      Column() {
        Text(label)
          .fontSize(15)
          .fontColor(this.colors.textPrimary)
          .fontWeight(this.selectedDataType === dataType ? FontWeight.Bold : FontWeight.Normal)
          .alignSelf(ItemAlign.Start)

        Text(description)
          .fontSize(12)
          .fontColor(this.colors.textTertiary)
          .margin({ top: 3 })
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 选中标记
      if (this.selectedDataType === dataType) {
        Text('✓')
          .fontSize(20)
          .fontColor(this.colors.primary)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding(15)
    .backgroundColor(this.selectedDataType === dataType ?
      (this.themeManager.isDark() ? '#1A3A38' : '#E8F8F5') :
      this.colors.surface)
    .borderRadius(12)
    .margin({ bottom: 10 })
    .border({
      width: 2,
      color: this.selectedDataType === dataType ? this.colors.primary : 'transparent'
    })
    .onClick(() => {
      this.selectedDataType = dataType;
    })
  }

  /**
   * 构建导出按钮
   */
  @Builder
  buildExportButton() {
    Button(this.isExporting ? '导出中...' : '开始导出')
      .width('100%')
      .height(50)
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor(this.isExporting ? this.colors.textTertiary : this.colors.primary)
      .borderRadius(12)
      .margin({ bottom: 30 })
      .enabled(!this.isExporting)
      .onClick(() => {
        this.performExport();
      })
  }

  /**
   * 构建已导出文件列表区域
   */
  @Builder
  buildExportedFilesSection() {
    Column() {
      Row() {
        Text('已导出文件')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.colors.textPrimary)

        if (this.exportedFiles.length > 0) {
          Text('清空全部')
            .fontSize(14)
            .fontColor(this.colors.error)
            .onClick(() => {
              this.clearAllFiles();
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 15 })

      if (this.exportedFiles.length === 0) {
        Text('暂无导出文件')
          .fontSize(14)
          .fontColor(this.colors.textTertiary)
          .padding(20)
          .width('100%')
          .backgroundColor(this.colors.surface)
          .borderRadius(12)
      } else {
        ForEach(this.exportedFiles, (fileName: string) => {
          this.buildFileItem(fileName);
        }, (fileName: string) => fileName)
      }
    }
  }

  /**
   * 构建文件项
   */
  @Builder
  buildFileItem(fileName: string) {
    Row() {
      Column() {
        Text(fileName)
          .fontSize(14)
          .fontColor(this.colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .alignSelf(ItemAlign.Start)

        Text(this.getFileDescription(fileName))
          .fontSize(12)
          .fontColor(this.colors.textTertiary)
          .margin({ top: 3 })
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('删除')
        .fontSize(14)
        .fontColor(this.colors.error)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.themeManager.isDark() ? '#3A1F1F' : '#FFE8E8')
        .borderRadius(8)
        .onClick(() => {
          this.deleteFile(fileName);
        })
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
   * 获取文件描述
   */
  getFileDescription(fileName: string): string {
    if (fileName.includes('AllData')) {
      return '全部数据';
    } else if (fileName.includes('HealthRecords')) {
      return '健康记录';
    } else if (fileName.includes('HealthGoals')) {
      return '健康目标';
    } else if (fileName.includes('Reminders')) {
      return '提醒设置';
    }
    return '导出文件';
  }
}
