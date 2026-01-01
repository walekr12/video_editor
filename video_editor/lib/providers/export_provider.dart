import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_file.dart';
import '../models/clip_settings.dart';

/// 导出状态
enum ExportState {
  idle,
  preparing,
  exporting,
  success,
  error,
}

/// 导出状态管理Provider
/// 注意：由于packages.arthenica.com无法访问，FFmpeg功能暂时不可用
/// 网络恢复后可以重新集成FFmpeg
class ExportProvider extends ChangeNotifier {
  /// 导出状态
  ExportState _state = ExportState.idle;
  ExportState get state => _state;

  /// 导出进度 (0.0 - 1.0)
  double _progress = 0.0;
  double get progress => _progress;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 导出文件路径
  String? _outputPath;
  String? get outputPath => _outputPath;

  /// 总时长（毫秒）
  int _totalDurationMs = 0;

  /// 是否正在导出
  bool get isExporting => _state == ExportState.exporting || _state == ExportState.preparing;

  /// 获取导出目录
  Future<String> _getExportDirectory() async {
    // 优先使用外部存储
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      final exportDir = Directory('${externalDir.path}/VideoEditor/Export');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      return exportDir.path;
    }
    
    // 回退到应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/Export');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  /// 生成输出文件名
  String _generateOutputFileName(String originalName) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final baseName = originalName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return '${baseName}_clip_$timestamp.mp4';
  }

  /// 导出视频裁剪片段
  /// 注意：FFmpeg暂时不可用，此功能将显示提示信息
  Future<bool> exportClip(VideoFile video, ClipSettings clipSettings) async {
    if (isExporting) return false;

    _state = ExportState.preparing;
    _progress = 0.0;
    _errorMessage = null;
    _outputPath = null;
    notifyListeners();

    try {
      // 获取导出目录
      final exportDir = await _getExportDirectory();
      final outputFileName = _generateOutputFileName(video.name);
      _outputPath = '$exportDir/$outputFileName';

      // 计算时间参数
      final startSeconds = clipSettings.startMs / 1000.0;
      final durationSeconds = clipSettings.durationMs / 1000.0;
      _totalDurationMs = clipSettings.durationMs;

      debugPrint('准备导出: 开始=${startSeconds}s, 时长=${durationSeconds}s');
      debugPrint('输出路径: $_outputPath');

      _state = ExportState.exporting;
      notifyListeners();

      // TODO: FFmpeg功能暂时不可用
      // 由于packages.arthenica.com无法访问，暂时无法下载FFmpeg��
      // 网络恢复后取消下面注释并重新添加ffmpeg_kit_flutter依赖:
      // 
      // final command = '-y -ss $startSeconds -i "${video.path}" -t $durationSeconds -c:v libx264 -c:a aac -preset fast -crf 23 "$_outputPath"';
      // final session = await FFmpegKit.executeAsync(command, ...);
      
      // 模拟导出进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        _progress = i / 100.0;
        notifyListeners();
      }

      // 暂时显示功能不可用的提示
      _state = ExportState.error;
      _errorMessage = 'FFmpeg导出功能暂时不可用\n\n原因：packages.arthenica.com 无法访问\n\n解决方案：\n1. 确保网络连接正常\n2. 尝试使用VPN访问\n3. 稍后重试\n\n裁剪参数已记录：\n开始时间: ${startSeconds.toStringAsFixed(2)}s\n持续时间: ${durationSeconds.toStringAsFixed(2)}s';
      notifyListeners();
      return false;

    } catch (e) {
      _state = ExportState.error;
      _errorMessage = '导出失败: $e';
      debugPrint(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// 取消导出
  Future<void> cancelExport() async {
    _state = ExportState.idle;
    _progress = 0.0;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _state = ExportState.idle;
    _progress = 0.0;
    _errorMessage = null;
    _outputPath = null;
    notifyListeners();
  }
}
