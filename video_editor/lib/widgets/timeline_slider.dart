import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';

/// 自定义时间轴进度条 - 带裁剪区间标记
class TimelineSlider extends StatefulWidget {
  const TimelineSlider({super.key});

  @override
  State<TimelineSlider> createState() => _TimelineSliderState();
}

class _TimelineSliderState extends State<TimelineSlider> {
  bool _isDragging = false;
  double _dragValue = 0;

  /// 格式化时间
  String _formatTime(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final millis = duration.inMilliseconds.remainder(1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, provider, _) {
        final durationMs = provider.durationMs;
        final positionMs = _isDragging ? (_dragValue * durationMs).toInt() : provider.positionMs;
        final clipSettings = provider.clipSettings;
        
        // 计算裁剪区间位置
        final clipStartRatio = durationMs > 0 ? clipSettings.startMs / durationMs : 0.0;
        final clipEndRatio = durationMs > 0 ? clipSettings.endMs / durationMs : 0.0;
        final currentRatio = durationMs > 0 ? positionMs / durationMs : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 时间显示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(positionMs),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    _formatTime(durationMs),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 自定义进度条
            GestureDetector(
              onHorizontalDragStart: (details) {
                _isDragging = true;
                _updateDragValue(details.localPosition.dx, context);
              },
              onHorizontalDragUpdate: (details) {
                _updateDragValue(details.localPosition.dx, context);
              },
              onHorizontalDragEnd: (details) {
                _isDragging = false;
                // 拖动结束时，更新开始时间（保持持续时间不变）
                provider.seekToRatioAndUpdateClipStart(_dragValue);
              },
              onTapUp: (details) {
                final box = context.findRenderObject() as RenderBox;
                final ratio = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                // 点击时也更新开始时间（保持持续时间不变）
                provider.seekToRatioAndUpdateClipStart(ratio);
              },
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomPaint(
                  painter: _TimelinePainter(
                    currentRatio: currentRatio,
                    clipStartRatio: clipStartRatio,
                    clipEndRatio: clipEndRatio,
                    isDragging: _isDragging,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
            
            // 裁剪区间时间
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '开始: ${clipSettings.formattedStart}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '结束: ${clipSettings.formattedEnd}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateDragValue(double dx, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final width = box.size.width - 32; // 减去左右边距
    setState(() {
      _dragValue = ((dx - 16) / width).clamp(0.0, 1.0);
    });
  }
}

/// 时间轴绘制器
class _TimelinePainter extends CustomPainter {
  final double currentRatio;
  final double clipStartRatio;
  final double clipEndRatio;
  final bool isDragging;

  _TimelinePainter({
    required this.currentRatio,
    required this.clipStartRatio,
    required this.clipEndRatio,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height / 2;
    const trackHeight = 6.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackY - trackHeight / 2, size.width, trackHeight),
      const Radius.circular(3),
    );

    // 绘制背景轨道
    final bgPaint = Paint()
      ..color = const Color(0xFF3D3D3D);
    canvas.drawRRect(trackRect, bgPaint);

    // 绘制裁剪区间
    final clipStartX = clipStartRatio * size.width;
    final clipEndX = clipEndRatio * size.width;
    final clipWidth = clipEndX - clipStartX;
    
    if (clipWidth > 0) {
      // 裁剪区间背景
      final clipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clipStartX, trackY - trackHeight / 2, clipWidth, trackHeight),
        const Radius.circular(3),
      );
      final clipPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.3);
      canvas.drawRRect(clipRect, clipPaint);

      // 裁剪区间边框
      final clipBorderPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(clipRect, clipBorderPaint);

      // 开始标记线
      final startLinePaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(clipStartX, trackY - 12),
        Offset(clipStartX, trackY + 12),
        startLinePaint,
      );

      // 结束标记线
      final endLinePaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(clipEndX, trackY - 12),
        Offset(clipEndX, trackY + 12),
        endLinePaint,
      );
    }

    // 绘制已播放进度
    final progressX = currentRatio * size.width;
    if (progressX > 0) {
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackY - trackHeight / 2, progressX, trackHeight),
        const Radius.circular(3),
      );
      final progressPaint = Paint()
        ..color = Colors.amber;
      canvas.drawRRect(progressRect, progressPaint);
    }

    // 绘制播放头
    final thumbRadius = isDragging ? 10.0 : 8.0;
    final thumbPaint = Paint()
      ..color = Colors.white;
    canvas.drawCircle(Offset(progressX, trackY), thumbRadius, thumbPaint);

    // 播放头边框
    final thumbBorderPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(progressX, trackY), thumbRadius, thumbBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return currentRatio != oldDelegate.currentRatio ||
        clipStartRatio != oldDelegate.clipStartRatio ||
        clipEndRatio != oldDelegate.clipEndRatio ||
        isDragging != oldDelegate.isDragging;
  }
}
