import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../models/video_file.dart';
import '../models/clip_settings.dart';

/// 视频状态管理Provider
class VideoProvider extends ChangeNotifier {
  /// 视频文件列表（仅存储路径，零拷贝）
  List<VideoFile> _videoFiles = [];
  List<VideoFile> get videoFiles => _videoFiles;

  /// 当前选中的视频
  VideoFile? _currentVideo;
  VideoFile? get currentVideo => _currentVideo;

  /// 视频播放器控制器
  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;

  /// 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 是否正在播放
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  /// 是否已初始化
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// 当前位置（毫秒）
  int get positionMs => _controller?.value.position.inMilliseconds ?? 0;

  /// 总时长（毫秒）
  int get durationMs => _controller?.value.duration.inMilliseconds ?? 0;

  /// 视频帧率
  double get fps => _currentVideo?.fps ?? 30.0;

  /// 裁剪设置
  ClipSettings _clipSettings = const ClipSettings();
  ClipSettings get clipSettings => _clipSettings;

  /// 当前播放速度
  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  /// 当前文件夹路径
  String? _currentFolder;
  String? get currentFolder => _currentFolder;

  /// 添加视频文件列表
  void setVideoFiles(List<VideoFile> files) {
    _videoFiles = files;
    notifyListeners();
  }

  /// 设置当前文件夹
  void setCurrentFolder(String? folder) {
    _currentFolder = folder;
    notifyListeners();
  }

  /// 从文件夹加载视频
  Future<void> loadVideosFromFolder(String folderPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final directory = Directory(folderPath);
      if (await directory.exists()) {
        final files = await directory.list().toList();
        final videoFiles = <VideoFile>[];

        for (var entity in files) {
          if (entity is File && VideoFile.isSupportedVideo(entity.path)) {
            videoFiles.add(VideoFile.fromPath(entity.path));
          }
        }

        _videoFiles = videoFiles;
        _currentFolder = folderPath;
      }
    } catch (e) {
      debugPrint('加载视频文件夹失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加单个视频文件
  void addVideoFile(VideoFile file) {
    if (!_videoFiles.contains(file)) {
      _videoFiles.add(file);
      notifyListeners();
    }
  }

  /// 选择并加载视频
  Future<void> selectVideo(VideoFile video) async {
    if (_currentVideo == video && _controller != null) return;

    _isLoading = true;
    notifyListeners();

    // 销毁旧的控制器（内存回收）
    await _disposeController();

    try {
      _currentVideo = video;
      _controller = VideoPlayerController.file(File(video.path));
      
      await _controller!.initialize();
      
      // 获取视频信息
      video.durationMs = _controller!.value.duration.inMilliseconds;
      video.width = _controller!.value.size.width.toInt();
      video.height = _controller!.value.size.height.toInt();
      
      // 重置裁剪设置
      _clipSettings = ClipSettings(
        startMs: 0,
        durationMs: video.durationMs ?? 0,
      );
      
      // 设置播放速度
      await _controller!.setPlaybackSpeed(_playbackSpeed);
      
      // 添加位置监听
      _controller!.addListener(_onVideoPositionChanged);
      
    } catch (e) {
      debugPrint('加载视频失败: $e');
      _currentVideo = null;
      await _disposeController();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 视频位置变化回调
  void _onVideoPositionChanged() {
    notifyListeners();
  }

  /// 销毁控制器
  Future<void> _disposeController() async {
    if (_controller != null) {
      _controller!.removeListener(_onVideoPositionChanged);
      await _controller!.dispose();
      _controller = null;
    }
  }

  /// 播放/暂停切换
  Future<void> togglePlayPause() async {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
    notifyListeners();
  }

  /// 播放
  Future<void> play() async {
    await _controller?.play();
    notifyListeners();
  }

  /// 暂停
  Future<void> pause() async {
    await _controller?.pause();
    notifyListeners();
  }

  /// 跳转到指定位置
  Future<void> seekTo(int positionMs) async {
    await _controller?.seekTo(Duration(milliseconds: positionMs));
    notifyListeners();
  }

  /// 跳转到指定比例位置
  Future<void> seekToRatio(double ratio) async {
    if (_controller == null) return;
    final position = (durationMs * ratio).toInt();
    await seekTo(position);
  }

  /// 拖动进度条时更新开始时间（保持持续时间不变）
  Future<void> seekToRatioAndUpdateClipStart(double ratio) async {
    if (_controller == null) return;
    final position = (durationMs * ratio).toInt();
    await seekTo(position);
    // 更新开始时间，保持持续时间不变
    setClipStartKeepDuration(position);
  }

  /// 设置裁剪开始时间（保持持续时间不变）
  void setClipStartKeepDuration(int startMs) {
    final currentDuration = _clipSettings.durationMs;
    // 确保开始时间不会导致结束时间超出视频长度
    final maxStart = durationMs - currentDuration;
    final clampedStart = startMs.clamp(0, maxStart > 0 ? maxStart : 0);
    
    _clipSettings = _clipSettings.copyWith(
      startMs: clampedStart,
      durationMs: currentDuration,
    );
    notifyListeners();
  }

  /// 上一帧
  Future<void> previousFrame() async {
    if (_controller == null) return;
    final frameMs = (1000 / fps).round();
    final newPosition = (positionMs - frameMs).clamp(0, durationMs);
    await seekTo(newPosition);
  }

  /// 下一帧
  Future<void> nextFrame() async {
    if (_controller == null) return;
    final frameMs = (1000 / fps).round();
    final newPosition = (positionMs + frameMs).clamp(0, durationMs);
    await seekTo(newPosition);
  }

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _controller?.setPlaybackSpeed(speed);
    _clipSettings = _clipSettings.copyWith(playbackSpeed: speed);
    notifyListeners();
  }

  /// 设置裁剪开始时间
  void setClipStart(int startMs) {
    _clipSettings = _clipSettings.copyWith(
      startMs: startMs.clamp(0, durationMs),
    );
    notifyListeners();
  }

  /// 设置裁剪开始时间为当前位置
  void setClipStartToCurrent() {
    setClipStart(positionMs);
  }

  /// 设置裁剪持续时间
  void setClipDuration(int durationMs) {
    final maxDuration = this.durationMs - _clipSettings.startMs;
    _clipSettings = _clipSettings.copyWith(
      durationMs: durationMs.clamp(0, maxDuration),
    );
    notifyListeners();
  }

  /// 设置裁剪持续时间（秒）
  void setClipDurationSeconds(double seconds) {
    setClipDuration((seconds * 1000).round());
  }

  /// 设置裁剪结束时间
  void setClipEnd(int endMs) {
    final newDuration = endMs - _clipSettings.startMs;
    setClipDuration(newDuration);
  }

  /// 设置裁剪结束时间为当前位置
  void setClipEndToCurrent() {
    setClipEnd(positionMs);
  }

  /// 跳转到裁剪开始位置
  Future<void> seekToClipStart() async {
    await seekTo(_clipSettings.startMs);
  }

  /// 跳转到裁剪结束位置
  Future<void> seekToClipEnd() async {
    await seekTo(_clipSettings.endMs);
  }

  /// 预览裁剪片段
  Future<void> previewClip() async {
    await seekToClipStart();
    await play();
  }

  /// 清除选择
  void clearSelection() {
    _disposeController();
    _currentVideo = null;
    _clipSettings = const ClipSettings();
    notifyListeners();
  }

  /// 清除所有
  void clearAll() {
    _disposeController();
    _videoFiles.clear();
    _currentVideo = null;
    _currentFolder = null;
    _clipSettings = const ClipSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}
