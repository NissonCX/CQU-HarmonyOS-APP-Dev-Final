<div align="center">

# 🏥 健康助手 - HarmonyOS 健康记录管理应用

<p align="center">
  <img src="https://img.shields.io/badge/HarmonyOS-3.0+-success?logo=harmonyos&style=for-the-badge" alt="HarmonyOS">
  <img src="https://img.shields.io/badge/Language-ArkTS-blue?style=for-the-badge&logo=typescript" alt="Language">
  <img src="https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
</p>

**✨ 一款专注于个人健康数据管理的原生HarmonyOS应用 | 简洁 · 智能 · 优雅**

</div>

> 💡 **项目背景**: 本项目为重庆大学计算机学院移动应用开发课程的期末自主选题项目，实现较为基础，仅供学习交流和参考之用。

---

---

## 🌟 项目简介

**健康助手** 是一款基于HarmonyOS开发的个人健康数据管理应用，致力于帮助用户记录、跟踪和分析个人健康指标。应用提供直观的数据可视化、智能提醒功能和优雅的用户界面，让健康管理变得更加简单高效。

### 🎯 核心特性

- 📊 **智能数据可视化** - 通过图表展示健康趋势，直观了解身体变化
- 📝 **便捷数据记录** - 简洁的输入界面，快速记录健康数据
- 🎯 **目标设定追踪** - 个性化健康目标，激励用户达成健康计划
- 🔔 **智能提醒系统** - 可自定义的定时提醒，养成良好习惯
- 💾 **数据安全导出** - 本地数据存储，支持数据备份与导出
- 🌙 **暗色主题支持** - 保护夜间视力，提供舒适使用体验
- 📱 **响应式设计** - 适配多种HarmonyOS设备屏幕尺寸

---

## 🚀 功能预览

### 📊 健康数据管理
- 体重记录与BMI计算
- 历史数据趋势分析
- 个性化健康备注

### 📈 数据可视化
- 动态趋势图表展示
- 数据统计摘要
- 直观健康状态呈现

### 🎯 目标管理
- 个性化健康目标设定
- 进度跟踪与提醒
- 成就感激励机制

### 🔔 智能提醒
- 可配置提醒时间
- 个性化提醒内容
- 习惯养成辅助

---

## 🛠 技术架构

```
健康助手应用
├── 数据层 (Data Layer)
│   ├── HealthRecord 模型
│   ├── DataManager 数据管理
│   └── 本地存储 (Preferences API)
├── 业务逻辑层 (Business Layer)
│   ├── 数据处理与计算
│   ├── 提醒管理
│   └── 数据导出功能
├── UI层 (Presentation Layer)
│   ├── 首页 (HomePage)
│   ├── 趋势页 (TrendsPage)
│   ├── 记录页 (RecordPage)
│   ├── 个人页 (ProfilePage)
│   └── 设置页 (SettingsPage)
└── 工具层 (Utils Layer)
    ├── CommonUtils 通用工具
    ├── ThemeManager 主题管理
    └── DataInitializer 数据初始化
```

### 🛠 核心技术栈

| 技术 | 说明 |
|------|------|
| **HarmonyOS** | 应用运行平台 |
| **ArkTS** | 主要开发语言 |
| **Preferences API** | 本地数据存储 |
| **HarmonyOS Chart** | 数据可视化组件 |
| **Notification** | 提醒功能实现 |

---

## 📋 目录结构

```
entry/
├── src/
│   ├── main/
│   │   ├── ets/
│   │   │   ├── entryability/      # 应用入口
│   │   │   ├── models/           # 数据模型
│   │   │   ├── pages/            # 页面组件
│   │   │   └── utils/            # 工具类
│   │   └── resources/            # 资源文件
│   └── ohosTest/                 # 测试文件
├── hvigorfile.ts                 # 构建配置
└── obfuscation-rules.txt         # 混淆规则
```

---

## 🚀 快速开始

### 环境要求

- **操作系统**: macOS / Windows / Linux
- **开发工具**: DevEco Studio 6.0.0+
- **HarmonyOS SDK**: 3.0+
- **Node.js**: 16.0+ (用于构建工具)

### 项目构建

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd HarmonyFinal
   ```

2. **打开项目**
   ```bash
   # 在DevEco Studio中打开项目
   ```

3. **构建应用**
   ```bash
   # 使用Hvigor构建系统
   hvigor build
   ```

4. **运行应用**
   - 在DevEco Studio中点击运行按钮
   - 或使用模拟器/真机进行测试

---

## 🎨 UI 设计理念

### 设计原则

- **简约美学**: 简洁明了的界面设计，突出核心功能
- **直观操作**: 符合用户习惯的交互设计
- **视觉层次**: 清晰的信息架构和视觉引导
- **响应式布局**: 适配不同屏幕尺寸的设备

### 色彩方案

| 颜色 | 用途 | Hex值 |
|------|------|-------|
| 主色调 | 操作按钮、重要信息 | #007DFF |
| 背景色 | 页面背景 | #FFFFFF / #121212 |
| 文字色 | 主要文字 | #212121 / #FFFFFF |
| 辅助色 | 辅助信息、边框 | #9E9E9E |

---

## 📖 使用指南

### 基本操作

1. **添加健康记录**
   - 点击首页的"添加记录"按钮
   - 输入体重、日期等信息
   - 系统自动计算BMI值

2. **查看趋势分析**
   - 进入"趋势"页面
   - 查看健康数据的可视化图表
   - 分析健康变化趋势

3. **设置健康目标**
   - 在目标页面设定健康目标
   - 跟踪目标完成进度
   - 接收达成提醒

4. **配置提醒功能**
   - 进入提醒设置页面
   - 选择提醒时间和频率
   - 启用健康提醒功能

---

## 🧪 测试策略

### 单元测试
- 数据模型验证
- 业务逻辑测试
- 工具函数测试

### UI测试
- 页面交互测试
- 响应式布局验证
- 主题切换测试

### 兼容性测试
- 不同HarmonyOS版本
- 多种设备屏幕尺寸
- 各种网络环境

---

## 🤝 贡献指南

欢迎任何形式的贡献！包括但不限于：

- 🐛 **Bug 报告**: 提交问题和建议
- ✨ **功能增强**: 提交功能请求和改进
- 📝 **文档完善**: 补充和完善文档
- 🌍 **国际化**: 帮助本地化翻译

### 开发流程

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 [MIT License](LICENSE) - 详见 [LICENSE](LICENSE) 文件

---

## 📞 支持与联系

- 📧 邮箱: [您的邮箱地址]
- 🌐 HarmonyOS 开发者社区
- 🐛 GitHub Issues

---

<div align="center">

### 💖 喜欢这个项目吗？

[![Star History Chart](https://api.star-history.com/svg?repos=your-username/your-repo&type=Date)](https://star-history.com/#your-username/your-repo&Date)

**给项目点个 ⭐ Star** 如果它对你有帮助！

---

<p align="center">
Built with ❤️ for HarmonyOS | © 2025 Health Assistant
</p>

</div>