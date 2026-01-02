import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/video_provider.dart';
import '../providers/export_provider.dart';
import '../models/clip_settings.dart';

/// 底部控制面板组件
class ControlPanel extends StatefulWidget {
  final bool isLandscape;
  
  const ControlPanel({super.key, this.isLandscape = false});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final _startTimeController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _startTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  /// 选择输出目录
  Future<void> _pickOutputFolder(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null && mounted) {
        final exportProvider = context.read<ExportProvider>();
        exportProvider.setCustomOutputDir(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('输出目录已设置: ${result.split(RegExp(r'[/\\]')).last}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('选择输出目录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择目录失败: $e')),
        );
      }
    }
  }

  /// 显示导出对话框
  void _showExportDialog(BuildContext context) {
    final videoProvider = context.read<VideoProvider>();
    final exportProvider = context.read<ExportProvider>();

    if (videoProvider.currentVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要导出的视频')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExportDialog(
        videoProvider: videoProvider,
        exportProvider: exportProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Color(0xFF3D3D3D)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3D3D3D)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                const Text(
                  '裁剪参数',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // 设置输出目录按钮
                Consumer<ExportProvider>(
                  builder: (context, exportProvider, _) {
                    return IconButton(
                      icon: const Icon(Icons.folder_special, size: 20),
                      color: exportProvider.customOutputDir != null 
                          ? Colors.green 
                          : Colors.white70,
                      tooltip: exportProvider.customOutputDir != null
                          ? '输出目录: ${exportProvider.customOutputDir!.split(RegExp(r'[/\\]')).last}'
                          : '设置输出目录',
                      onPressed: () => _pickOutputFolder(context),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // 导出按钮
                Consumer<VideoProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.currentVideo != null
                          ? () => _showExportDialog(context)
                          : null,
                      icon: const Icon(Icons.file_upload, size: 18),
                      label: const Text('导出'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.shade700,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 参数设置区域
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(widget.isLandscape ? 12 : 16),
              child: Consumer<VideoProvider>(
                builder: (context, provider, _) {
                  final clipSettings = provider.clipSettings;
                  
                  // 更新输入框文本
                  _startTimeController.text = clipSettings.formattedStart;
                  _durationController.text = clipSettings.durationSeconds.toStringAsFixed(2);

                  // 横屏时使用垂直布局
                  if (widget.isLandscape) {
                    return _buildLandscapeContent(provider, clipSettings);
                  }
                  
                  // 竖屏时使用水平布局
                  return _buildPortraitContent(provider, clipSettings);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 横屏内容布局 - 垂直排列，字体更大
  Widget _buildLandscapeContent(VideoProvider provider, ClipSettings clipSettings) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 开始时间
          _LandscapeParameterField(
            label: '开始时间',
            controller: _startTimeController,
            hint: '00:00.00',
            enabled: provider.isInitialized,
            onSubmitted: (value) {
              final ms = ClipSettings.parseTime(value);
              if (ms != null) {
                provider.setClipStart(ms);
              }
            },
            buttonIcon: Icons.timer,
            buttonColor: Colors.amber,
            buttonTooltip: '设为当前时间',
            onButtonPressed: provider.isInitialized
                ? () => provider.setClipStartToCurrent()
                : null,
          ),

          const SizedBox(height: 12),

          // 持续时间
          _LandscapeParameterField(
            label: '持续时间（秒）',
            controller: _durationController,
            hint: '0.00',
            enabled: provider.isInitialized,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (value) {
              final seconds = double.tryParse(value);
              if (seconds != null) {
                provider.setClipDurationSeconds(seconds);
              }
            },
            buttonIcon: Icons.check,
            buttonColor: Colors.green,
            buttonTooltip: '确认并保存为默认值',
            onButtonPressed: provider.isInitialized
                ? () async {
                    final seconds = double.tryParse(_durationController.text);
                    if (seconds != null) {
                      provider.setClipDurationSeconds(seconds);
                      // 保存为默认持续时间
                      await provider.saveDefaultDurationSeconds(seconds);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已保存默认持续时间: ${seconds}秒'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),

          const SizedBox(height: 16),

          // 切换视频 - 横向排列
          const Text(
            '切换视频',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LandscapeQuickButton(
                  icon: Icons.skip_previous,
                  label: '上一个',
                  onPressed: provider.canSelectPrevious
                      ? () => provider.selectPreviousVideo()
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LandscapeQuickButton(
                  icon: Icons.skip_next,
                  label: '下一个',
                  onPressed: provider.canSelectNext
                      ? () => provider.selectNextVideo()
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 竖屏内容布局 - 垂直排列，���免挤压
  Widget _buildPortraitContent(VideoProvider provider, ClipSettings clipSettings) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 开始时间
          _ParameterField(
            label: '开始时间',
            controller: _startTimeController,
            hint: '00:00.00',
            enabled: provider.isInitialized,
            onSubmitted: (value) {
              final ms = ClipSettings.parseTime(value);
              if (ms != null) {
                provider.setClipStart(ms);
              }
            },
            suffix: IconButton(
              icon: const Icon(Icons.timer, size: 18),
              color: Colors.amber,
              tooltip: '设为当前时间',
              onPressed: provider.isInitialized
                  ? () => provider.setClipStartToCurrent()
                  : null,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          // 持续时间
          _ParameterField(
            label: '持续时间（秒）',
            controller: _durationController,
            hint: '0.00',
            enabled: provider.isInitialized,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (value) {
              final seconds = double.tryParse(value);
              if (seconds != null) {
                provider.setClipDurationSeconds(seconds);
              }
            },
            suffix: IconButton(
              icon: const Icon(Icons.check, size: 18),
              color: Colors.green,
              tooltip: '确认并保存为默认值',
              onPressed: provider.isInitialized
                  ? () async {
                      final seconds = double.tryParse(_durationController.text);
                      if (seconds != null) {
                        provider.setClipDurationSeconds(seconds);
                        // 保存为默认持续时间
                        await provider.saveDefaultDurationSeconds(seconds);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已保存默认持续时间: ${seconds}秒'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    }
                  : null,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          // 切换视频 - 横向排列按钮
          Row(
            children: [
              const Text(
                '切换视频',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _PortraitQuickButton(
                        icon: Icons.skip_previous,
                        label: '上一个',
                        onPressed: provider.canSelectPrevious
                            ? () => provider.selectPreviousVideo()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PortraitQuickButton(
                        icon: Icons.skip_next,
                        label: '下一个',
                        onPressed: provider.canSelectNext
                            ? () => provider.selectNextVideo()
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 参数输入字段
class _ParameterField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _ParameterField({
    required this.label,
    required this.controller,
    required this.hint,
    this.enabled = true,
    this.keyboardType,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF3D3D3D)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: onSubmitted,
                  inputFormatters: keyboardType == const TextInputType.numberWithOptions(decimal: true)
                      ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                      : null,
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

/// 快捷按钮
class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _QuickButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3D3D3D),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 20,
              color: onPressed != null ? Colors.white70 : Colors.white30,
            ),
          ),
        ),
      ),
    );
  }
}

/// 横屏参数输入字段 - 更大的字体和按钮
class _LandscapeParameterField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final IconData buttonIcon;
  final Color buttonColor;
  final String buttonTooltip;
  final VoidCallback? onButtonPressed;

  const _LandscapeParameterField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.buttonIcon,
    required this.buttonColor,
    required this.buttonTooltip,
    this.enabled = true,
    this.keyboardType,
    this.onSubmitted,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF3D3D3D)),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: onSubmitted,
                  inputFormatters: keyboardType == const TextInputType.numberWithOptions(decimal: true)
                      ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: buttonColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: onButtonPressed,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Tooltip(
                    message: buttonTooltip,
                    child: Icon(
                      buttonIcon,
                      size: 24,
                      color: onButtonPressed != null ? buttonColor : Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 竖屏快捷按钮 - 紧凑尺寸带文字
class _PortraitQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _PortraitQuickButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3D3D3D),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: onPressed != null ? Colors.white70 : Colors.white30,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null ? Colors.white70 : Colors.white30,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 横屏快捷按钮 - 更大尺寸带文字
class _LandscapeQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _LandscapeQuickButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3D3D3D),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: onPressed != null ? Colors.white70 : Colors.white30,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null ? Colors.white70 : Colors.white30,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 导出对话框
class _ExportDialog extends StatefulWidget {
  final VideoProvider videoProvider;
  final ExportProvider exportProvider;

  const _ExportDialog({
    required this.videoProvider,
    required this.exportProvider,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  @override
  void initState() {
    super.initState();
    // 开始导出
    _startExport();
  }

  Future<void> _startExport() async {
    await widget.exportProvider.exportClip(
      widget.videoProvider.currentVideo!,
      widget.videoProvider.clipSettings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.exportProvider,
      builder: (context, _) {
        final state = widget.exportProvider.state;
        final progress = widget.exportProvider.progress;
        final errorMessage = widget.exportProvider.errorMessage;
        final outputPath = widget.exportProvider.outputPath;

        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: Row(
            children: [
              Icon(
                state == ExportState.success
                    ? Icons.check_circle
                    : state == ExportState.error
                        ? Icons.error
                        : Icons.file_upload,
                color: state == ExportState.success
                    ? Colors.green
                    : state == ExportState.error
                        ? Colors.red
                        : Colors.amber,
              ),
              const SizedBox(width: 12),
              Text(
                state == ExportState.success
                    ? '导出完成'
                    : state == ExportState.error
                        ? '导出失败'
                        : '正在导出...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state == ExportState.exporting || state == ExportState.preparing) ...[
                  LinearProgressIndicator(
                    value: state == ExportState.preparing ? null : progress,
                    backgroundColor: const Color(0xFF3D3D3D),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state == ExportState.preparing
                        ? '准备中...'
                        : '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                if (state == ExportState.success && outputPath != null) ...[
                  const Text(
                    '文件已保存到:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      outputPath,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
                if (state == ExportState.error && errorMessage != null) ...[
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (state == ExportState.exporting || state == ExportState.preparing)
              TextButton(
                onPressed: () {
                  widget.exportProvider.cancelExport();
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
            if (state == ExportState.success || state == ExportState.error)
              TextButton(
                onPressed: () {
                  widget.exportProvider.reset();
                  Navigator.of(context).pop();
                },
                child: const Text('确定'),
              ),
          ],
        );
      },
    );
  }
}
