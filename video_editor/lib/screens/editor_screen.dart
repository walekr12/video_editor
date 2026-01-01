import 'package:flutter/material.dart';
import '../widgets/file_browser.dart';
import '../widgets/video_monitor.dart';
import '../widgets/control_panel.dart';

/// 主编辑器界面 - 采用经典NLE三栏布局
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    // 根据屏幕方向调整布局
    if (isLandscape) {
      return _buildLandscapeLayout(context);
    } else {
      return _buildPortraitLayout(context);
    }
  }

  /// 横屏布局：左侧资源管理器 + 中间监视器 + 右侧控制面板
  Widget _buildLandscapeLayout(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        toolbarHeight: 40, // 横屏时缩小标题栏
        title: const Row(
          children: [
            Icon(Icons.movie_edit, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              '视频编辑器',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // 帮助按钮
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white54, size: 20),
            tooltip: '使用帮助',
            onPressed: () => _showHelpDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          // 左侧资源管理器（较窄）
          const SizedBox(
            width: 180,
            child: FileBrowser(),
          ),
          
          // 分隔线
          Container(
            width: 1,
            color: const Color(0xFF3D3D3D),
          ),
          
          // 中间监视器（视频播放区域）- 可以较小
          const Expanded(
            flex: 5,
            child: VideoMonitor(),
          ),
          
          // 分隔线
          Container(
            width: 1,
            color: const Color(0xFF3D3D3D),
          ),
          
          // 右侧控制面板 - 更大空间
          SizedBox(
            width: screenHeight > 400 ? 280 : 240,
            child: const ControlPanel(isLandscape: true),
          ),
        ],
      ),
    );
  }

  /// 竖屏布局：上部监视器 + 中部资源列表 + 底部控制面板
  Widget _buildPortraitLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.movie_edit, color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Text(
              '视频编辑器',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white54),
            tooltip: '使用帮助',
            onPressed: () => _showHelpDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 监视器区域（占40%）
          const Expanded(
            flex: 4,
            child: VideoMonitor(),
          ),
          
          // 分隔线
          Container(
            height: 1,
            color: const Color(0xFF3D3D3D),
          ),
          
          // 资源列表（占30%）
          const Expanded(
            flex: 3,
            child: FileBrowser(),
          ),
          
          // 底部控制面板
          const SizedBox(
            height: 160,
            child: ControlPanel(),
          ),
        ],
      ),
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.amber),
            SizedBox(width: 12),
            Text(
              '使用帮助',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(
                icon: Icons.folder_open,
                title: '导入视频',
                description: '点击左上角的文件夹图标选择视频文件或文件夹',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.skip_previous,
                title: '帧级控制',
                description: '使用上一帧/下一帧按钮进行精确定位',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.speed,
                title: '变速播放',
                description: '支持0.25x到3x的播放速度调节',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.timer,
                title: '设置裁剪点',
                description: '点击时钟图标将当前位置设为开始时间',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.flag,
                title: '设置结束点',
                description: '点击旗帜图标将当前位置设为结束时间',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.file_upload,
                title: '导出视频',
                description: '设置好裁剪区间后点击导出按钮',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

/// 帮助项
class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
