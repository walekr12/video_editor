import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
/// 使用原生 Android MediaMuxer API 进行视频裁剪，无需依赖外部服务器
class ExportProvider extends ChangeNotifier {
  /// 原生方法通道
  static const MethodChannel _channel = MethodChannel('com.example.video_editor/trimmer');
  static const EventChannel _eventChannel = EventChannel('com.example.video_editor/progress');

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

  /// 用户指定的输出目录
  String? _customOutputDir;
  String? get customOutputDir => _customOutputDir;

  /// 是否正在导出
  bool get isExporting => _state == ExportState.exporting || _state == ExportState.preparing;

  /// 设置自定义输出目录
  void setCustomOutputDir(String? dir) {
    _customOutputDir = dir;
    notifyListeners();
  }

  /// 获取导出目录
  Future<String> _getExportDirectory() async {
    // 如果用户指定了输出目录，使用用户的
    if (_customOutputDir != null && _customOutputDir!.isNotEmpty) {
      final customDir = Directory(_customOutputDir!);
      if (await customDir.exists()) {
        return _customOutputDir!;
      }
    }
    
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

  /// 获取下一个导出序号
  Future<int> _getNextExportIndex(String exportDir) async {
    final dir = Directory(exportDir);
    if (!await dir.exists()) {
      return 1;
    }
    
    final files = await dir.list().toList();
    int maxIndex = 0;
    
    // 查找形如 N_Xs.mp4 的文件，获取最大序号
    final pattern = RegExp(r'^(\d+)_\d+s\.mp4$');
    for (var entity in files) {
      if (entity is File) {
        final fileName = entity.path.split('/').last.split('\\').last;
        final match = pattern.firstMatch(fileName);
        if (match != null) {
          final index = int.tryParse(match.group(1)!) ?? 0;
          if (index > maxIndex) {
            maxIndex = index;
          }
        }
      }
    }
    
    return maxIndex + 1;
  }

  /// 生成输出文件名
  /// 格式：序号_时长s.mp4（如 1_5s.mp4, 2_10s.mp4）
  Future<String> _generateOutputFileName(String exportDir, int durationMs) async {
    final nextIndex = await _getNextExportIndex(exportDir);
    final durationSeconds = (durationMs / 1000).round();
    return '${nextIndex}_${durationSeconds}s.mp4';
  }

  /// 导出视频裁剪片段
  /// 使用原生 Android API，无需依赖 FFmpeg
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
      
      // 生成规范化的文件名：序号_时长s.mp4
      final outputFileName = await _generateOutputFileName(exportDir, clipSettings.durationMs);
      _outputPath = '$exportDir/$outputFileName';

      // 计算时间参数
      final startMs = clipSettings.startMs;
      final endMs = clipSettings.startMs + clipSettings.durationMs;

      debugPrint('准备导出: 开始=${startMs}ms, 结束=${endMs}ms');
      debugPrint('输入路径: ${video.path}');
      debugPrint('输出路径: $_outputPath');

      _state = ExportState.exporting;
      notifyListeners();

      // 监听进度事件
      _eventChannel.receiveBroadcastStream().listen(
        (progress) {
          if (progress is int) {
            _progress = progress / 100.0;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('进度监听错误: $error');
        },
      );

      // 调用原生裁剪方法
      final result = await _channel.invokeMethod('trimVideo', {
        'inputPath': video.path,
        'outputPath': _outputPath,
        'startMs': startMs,
        'endMs': endMs,
      });

      if (result != null) {
        _state = ExportState.success;
        _progress = 1.0;
        _outputPath = result as String;
        debugPrint('导出成功: $_outputPath');
        notifyListeners();
        return true;
      } else {
        throw Exception('裁剪返回空结果');
      }

    } on PlatformException catch (e) {
      _state = ExportState.error;
      _errorMessage = '导出失败: ${e.message}\n\n错误代码: ${e.code}';
      debugPrint(_errorMessage);
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
