import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_screen.dart';

const MethodChannel _widgetChannel = MethodChannel('esp_home/widget_actions');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for Mobile and Web. Use REST API for all Desktop platforms (Windows, macOS, Linux).
  final isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.macOS);

  String? initialWidgetAction;
  if (!isDesktop && defaultTargetPlatform == TargetPlatform.android) {
    try {
      initialWidgetAction =
          await _widgetChannel.invokeMethod<String>('consumeInitialAction');
    } catch (_) {
      initialWidgetAction = null;
    }
  }

  runApp(MyApp(initialWidgetAction: initialWidgetAction));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialWidgetAction});

  final String? initialWidgetAction;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        openTimeoutOnLaunch: initialWidgetAction == 'open_timeout',
      ),
      theme: ThemeData.dark(),
    );
  }
}
