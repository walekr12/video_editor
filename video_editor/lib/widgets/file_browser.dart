import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/video_provider.dart';
import '../models/video_file.dart';

/// 左侧文件浏览器组件
class FileBrowser extends StatefulWidget {
  const FileBrowser({super.key});

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  /// 请求存储权限
  Future<bool> _requestPermission() async {
    // Android 13+ 需要特定的媒体权限
    if (await Permission.videos.request().isGranted) {
      return true;
    }
    
    // Android 12及以下使用存储权限
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    // 请求管理所有文件权限
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    return false;
  }

  /// 选择视频文件
  Future<void> _pickVideoFiles() async {
    if (!await _requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要存储权限才能选择视频文件')),
        );
      }
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && mounted) {
        final provider = context.read<VideoProvider>();
        for (var file in result.files) {
          if (file.path != null) {
            provider.addVideoFile(VideoFile.fromPath(file.path!));
          }
        }
      }
    } catch (e) {
      debugPrint('选择文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  /// 选择文件夹
  Future<void> _pickFolder() async {
    if (!await _requestPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要存储权限才能访问文件夹')),
        );
      }
      return;
    }

    try {
      final result = await FilePicker.platform.getDirectoryPath();

      if (result != null && mounted) {
        final provider = context.read<VideoProvider>();
        await provider.loadVideosFromFolder(result);
      }
    } catch (e) {
      debugPrint('选择文件夹失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件夹失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3D3D3D)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '本地资源',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // 选择文��按钮
                IconButton(
                  icon: const Icon(Icons.video_file, size: 20),
                  color: Colors.white70,
                  tooltip: '选择视频文件',
                  onPressed: _pickVideoFiles,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                // 选择文件夹按钮
                IconButton(
                  icon: const Icon(Icons.create_new_folder, size: 20),
                  color: Colors.white70,
                  tooltip: '选择文件夹',
                  onPressed: _pickFolder,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // 当前文件夹路径
          Consumer<VideoProvider>(
            builder: (context, provider, _) {
              if (provider.currentFolder != null) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: const Color(0xFF252525),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          provider.currentFolder!.split(RegExp(r'[/\\]')).last,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.white54,
                        onPressed: () => provider.clearAll(),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 视频列表
          Expanded(
            child: Consumer<VideoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                  );
                }

                if (provider.videoFiles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '暂无视频',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击上方按钮导入视频',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.videoFiles.length,
                  itemBuilder: (context, index) {
                    final video = provider.videoFiles[index];
                    final isSelected = video == provider.currentVideo;

                    return _VideoListItem(
                      video: video,
                      isSelected: isSelected,
                      onTap: () => provider.selectVideo(video),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 视频列表项
class _VideoListItem extends StatelessWidget {
  final VideoFile video;
  final bool isSelected;
  final VoidCallback onTap;

  const _VideoListItem({
    required this.video,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getVideoIcon() {
    switch (video.extension) {
      case 'mp4':
        return Icons.video_file;
      case 'avi':
        return Icons.movie;
      case 'mkv':
        return Icons.video_library;
      default:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF3D3D3D) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFF2D2D2D),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.amber : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getVideoIcon(),
                color: isSelected ? Colors.amber : Colors.white54,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${video.extension.toUpperCase()} • ${video.formattedDuration}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
