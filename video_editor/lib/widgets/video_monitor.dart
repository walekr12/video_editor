import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_provider.dart';
import '../models/clip_settings.dart';
import 'timeline_slider.dart';

/// 中间视频监视器组件
class VideoMonitor extends StatelessWidget {
  const VideoMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3D3D3D)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                const Text(
                  '监视器',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // 视频信息
                Consumer<VideoProvider>(
                  builder: (context, provider, _) {
                    if (provider.currentVideo != null && provider.isInitialized) {
                      final video = provider.currentVideo!;
                      return Text(
                        '${video.width ?? 0}x${video.height ?? 0} • ${provider.playbackSpeed}x',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // 视频播放区域
          Expanded(
            child: Consumer<VideoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 16),
                        Text(
                          '加载视频中...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.controller == null || !provider.isInitialized) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 80,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '选择视频开始编辑',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => provider.togglePlayPause(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 视频画面
                      Center(
                        child: AspectRatio(
                          aspectRatio: provider.controller!.value.aspectRatio,
                          child: VideoPlayer(provider.controller!),
                        ),
                      ),

                      // 播放/暂停提示
                      AnimatedOpacity(
                        opacity: provider.isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 播放控制栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              border: Border(
                top: BorderSide(color: Color(0xFF3D3D3D)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 进度条
                const TimelineSlider(),
                
                const SizedBox(height: 12),
                
                // 控制按钮
                Consumer<VideoProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 上一帧
                        _ControlButton(
                          icon: Icons.skip_previous,
                          tooltip: '上一帧',
                          onPressed: provider.isInitialized
                              ? () => provider.previousFrame()
                              : null,
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 播放/暂停
                        _PlayPauseButton(
                          isPlaying: provider.isPlaying,
                          onPressed: provider.isInitialized
                              ? () => provider.togglePlayPause()
                              : null,
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 下一帧
                        _ControlButton(
                          icon: Icons.skip_next,
                          tooltip: '下一帧',
                          onPressed: provider.isInitialized
                              ? () => provider.nextFrame()
                              : null,
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // 播放速度选择
                        _SpeedSelector(
                          currentSpeed: provider.playbackSpeed,
                          onSpeedChanged: provider.isInitialized
                              ? (speed) => provider.setPlaybackSpeed(speed)
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 控制按钮
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      color: onPressed != null ? Colors.white : Colors.white38,
      iconSize: 28,
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
    );
  }
}

/// 播放/暂停按钮
class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null ? Colors.amber : Colors.grey,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 32,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

/// 播放速度选择器
class _SpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double>? onSpeedChanged;

  const _SpeedSelector({
    required this.currentSpeed,
    this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      onSelected: onSpeedChanged,
      enabled: onSpeedChanged != null,
      tooltip: '播放速度',
      offset: const Offset(0, -200),
      color: const Color(0xFF2D2D2D),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3D3D3D),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              '${currentSpeed}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_up, color: Colors.white54, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => PlaybackSpeedOption.options.map((option) {
        final isSelected = option.speed == currentSpeed;
        return PopupMenuItem<double>(
          value: option.speed,
          child: Row(
            children: [
              if (isSelected)
                const Icon(Icons.check, color: Colors.amber, size: 18)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
