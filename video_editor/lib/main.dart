import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/video_provider.dart';
import 'providers/export_provider.dart';
import 'screens/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置全屏沉浸模式
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // 设置状态栏和导航栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // 支持横竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const VideoEditorApp());
}

/// 视频编辑器应用
class VideoEditorApp extends StatelessWidget {
  const VideoEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => ExportProvider()),
      ],
      child: MaterialApp(
        title: '视频编辑器',
        debugShowCheckedModeBanner: false,
        
        // 深色主题配置
        theme: ThemeData.dark().copyWith(
          // 主色调
          primaryColor: Colors.amber,
          
          // 颜色方案
          colorScheme: const ColorScheme.dark(
            primary: Colors.amber,
            secondary: Colors.amberAccent,
            surface: Color(0xFF1E1E1E),
            error: Colors.redAccent,
          ),
          
          // 脚手架背景色
          scaffoldBackgroundColor: const Color(0xFF121212),
          
          // AppBar主题
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          
          // 卡片主题
          cardTheme: const CardThemeData(
            color: Color(0xFF2D2D2D),
            elevation: 0,
          ),
          
          // 对话框主题
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF2D2D2D),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // 按钮主题
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // 文本按钮主题
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
            ),
          ),
          
          // 图标主题
          iconTheme: const IconThemeData(
            color: Colors.white70,
          ),
          
          // 进度指示器主题
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.amber,
          ),
          
          // Slider主题
          sliderTheme: SliderThemeData(
            activeTrackColor: Colors.amber,
            inactiveTrackColor: Colors.grey.shade700,
            thumbColor: Colors.white,
            overlayColor: Colors.amber.withValues(alpha: 0.2),
          ),
          
          // SnackBar主题
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF2D2D2D),
            contentTextStyle: const TextStyle(color: Colors.white),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          
          // 输入框主题
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          
          // 分隔线主题
          dividerTheme: const DividerThemeData(
            color: Color(0xFF3D3D3D),
            thickness: 1,
          ),
        ),
        
        home: const EditorScreen(),
      ),
    );
  }
}
