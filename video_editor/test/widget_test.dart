// 视频编辑器基本测试

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:video_editor/main.dart';

void main() {
  testWidgets('App should start without crashing', (WidgetTester tester) async {
    // 验证应用可以正常启动
    await tester.pumpWidget(const VideoEditorApp());
    
    // 验证编辑器界面存在
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
