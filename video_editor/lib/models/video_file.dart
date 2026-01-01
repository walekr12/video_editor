/// 视频文件模型 - 仅存储文件路径，实现零拷贝策略
class VideoFile {
  /// 文件绝对路径
  final String path;
  
  /// 文件名
  final String name;
  
  /// 文件大小（字节）
  final int? size;
  
  /// 视频时长（毫秒），延迟加载
  int? durationMs;
  
  /// 视频帧率
  double? fps;
  
  /// 视频宽度
  int? width;
  
  /// 视频高度
  int? height;

  VideoFile({
    required this.path,
    required this.name,
    this.size,
    this.durationMs,
    this.fps,
    this.width,
    this.height,
  });

  /// 从文件路径创建
  factory VideoFile.fromPath(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    return VideoFile(path: path, name: name);
  }

  /// 获取格式化的时长
  String get formattedDuration {
    if (durationMs == null) return '--:--';
    final duration = Duration(milliseconds: durationMs!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取文件扩展名
  String get extension => name.split('.').last.toLowerCase();

  /// 是否为支持的视频格式
  static bool isSupportedVideo(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', '3gp'].contains(ext);
  }

  @override
  String toString() => 'VideoFile($name)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoFile && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
