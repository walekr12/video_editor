/// 裁剪设置模型
class ClipSettings {
  /// 开始时间（毫秒）
  final int startMs;
  
  /// 持续时间（毫秒）
  final int durationMs;
  
  /// 播放速度倍率
  final double playbackSpeed;

  const ClipSettings({
    this.startMs = 0,
    this.durationMs = 0,
    this.playbackSpeed = 1.0,
  });

  /// 结束时间（毫秒）
  int get endMs => startMs + durationMs;

  /// 格式化开始时间
  String get formattedStart => _formatTime(startMs);

  /// 格式化结束时间
  String get formattedEnd => _formatTime(endMs);

  /// 格式化持续时间
  String get formattedDuration => _formatTime(durationMs);

  /// 持续时间（秒）
  double get durationSeconds => durationMs / 1000.0;

  /// 格式化时间
  static String _formatTime(int ms) {
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final millis = duration.inMilliseconds.remainder(1000) ~/ 10;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  /// 从时间字符串解析毫秒数
  static int? parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hours = 0, minutes = 0;
      double seconds = 0;
      
      if (parts.length == 3) {
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        seconds = double.parse(parts[2]);
      } else if (parts.length == 2) {
        minutes = int.parse(parts[0]);
        seconds = double.parse(parts[1]);
      } else if (parts.length == 1) {
        seconds = double.parse(parts[0]);
      }
      
      return (hours * 3600000 + minutes * 60000 + (seconds * 1000).round());
    } catch (e) {
      return null;
    }
  }

  ClipSettings copyWith({
    int? startMs,
    int? durationMs,
    double? playbackSpeed,
  }) {
    return ClipSettings(
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }

  @override
  String toString() => 'ClipSettings(start: $formattedStart, duration: $formattedDuration, speed: ${playbackSpeed}x)';
}

/// 播放速度选项
class PlaybackSpeedOption {
  final String label;
  final double speed;

  const PlaybackSpeedOption(this.label, this.speed);

  static const List<PlaybackSpeedOption> options = [
    PlaybackSpeedOption('0.25x', 0.25),
    PlaybackSpeedOption('0.5x', 0.5),
    PlaybackSpeedOption('0.75x', 0.75),
    PlaybackSpeedOption('1x', 1.0),
    PlaybackSpeedOption('1.25x', 1.25),
    PlaybackSpeedOption('1.5x', 1.5),
    PlaybackSpeedOption('2x', 2.0),
    PlaybackSpeedOption('2.5x', 2.5),
    PlaybackSpeedOption('3x', 3.0),
  ];
}
