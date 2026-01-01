## 项目概述
这是一个 Flutter Android 视频编辑器应用，主要用于视频裁剪功能。使用原生 Android MediaMuxer 进行无损视频裁剪。

## 最新更新 (2026/1/1)

### 已修复的警告
1. **withOpacity 过时警告** - 全部改为 `withValues(alpha: x)`
   - `timeline_slider.dart`: Colors.amber.withValues(alpha: 0.3)
   - `video_monitor.dart`: Colors.white.withValues(alpha: 0.2/0.5), Colors.black.withValues(alpha: 0.5)
   - `control_panel.dart`: Colors.white.withValues(alpha: 0.3), buttonColor.withValues(alpha: 0.2)
   - `file_browser.dart`: 4处修复
   - `main.dart`: 2处修复

2. **prefer_const_declarations** - `timeline_slider.dart`
   - `final trackHeight = 6.0;` → `const trackHeight = 6.0;`

3. **prefer_const_constructors** - `editor_screen.dart`
   - `SizedBox(width: 220, child: const FileBrowser())` → `const SizedBox(width: 220, child: FileBrowser())`

4. **unused_import** - `timeline_slider.dart`
   - 移除未使用的 `import '../models/clip_settings.dart'`

### 新增功能：拖动进度条更新开始时间

**用户需求**: 持续时间由用户填写后保持固定，拖动进度条只改变开始时间

**实现修改**:

1. **video_provider.dart** - 新增两个方法：
   ```dart
   /// 拖动进度条时更新开始时间（保持持续时间不变）
   Future<void> seekToRatioAndUpdateClipStart(double ratio) async
   
   /// 设置裁剪开始时间（保持持续时间不变）
   void setClipStartKeepDuration(int startMs)
   ```

2. **timeline_slider.dart** - 修改拖动和点击行为：
   - `onHorizontalDragEnd`: 调用 `provider.seekToRatioAndUpdateClipStart(_dragValue)`
   - `onTapUp`: 调用 `provider.seekToRatioAndUpdateClipStart(ratio)`

### 优化横屏布局

**用户需求**: 横屏时按钮区域更大、字体更大、不遮挡

**实现修改**:

1. **editor_screen.dart** - 横屏布局改为左右三栏：
   - 左侧：资源管理器 (180px)
   - 中间：视频监视器 (flex: 5)
   - 右侧：控制面板 (280px)
   - AppBar 高度缩小为 40px

2. **control_panel.dart** - 新增横屏适配：
   - 添加 `isLandscape` 参数
   - 横屏时使用垂直布局 (`_buildLandscapeContent`)
   - 竖屏时使用水平布局 (`_buildPortraitContent`)
   - 新增 `_LandscapeParameterField` 组件 - 更大字体(16px)、更大按钮(44px)
   - 新增 `_LandscapeQuickButton` 组件 - 带文字标签的大按钮

## 项目结构

```
video_editor/
├── lib/
│   ├── main.dart                      # 应用入口
│   ├── screens/
│   │   └── editor_screen.dart         # 主编辑器界面
│   ├── widgets/
│   │   ├── file_browser.dart          # 文件浏览器
│   │   ├── video_monitor.dart         # 视频监视器
│   │   ├── control_panel.dart         # 控制面板
│   │   └── timeline_slider.dart       # 时间轴滑块
│   ├── providers/
│   │   ├── video_provider.dart        # 视频状态管理
│   │   └── export_provider.dart       # 导出状态管理
│   └── models/
│       ├── video_file.dart            # 视频文件模型
│       └── clip_settings.dart         # 裁剪设置模型
├── android/
│   └── app/src/main/kotlin/com/apkvideo/video_editor/
│       ├── MainActivity.kt            # Flutter MethodChannel
│       └── VideoTrimmer.kt            # 原生视频裁剪
└── .github/workflows/
    ├── build-android.yml              # Android 构建 CI
    └── release.yml                    # 发布 CI
```

## 技术要点

1. **视频裁剪**: 使用 Android MediaMuxer 无损裁剪（非 FFmpeg）
2. **Flutter-原生通信**: MethodChannel
3. **状态管理**: Provider
4. **GitHub Actions**: 自动构建 APK

## 待办事项
- [ ] 在真机上测试横屏布局
- [ ] 测试视频裁剪功能
- [ ] 优化文件浏览器横屏布局
