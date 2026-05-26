// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:esp_home/home/home_controller.dart';
import 'package:esp_home/home/home_page.dart';
import 'package:esp_home/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Splash screen shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(preload: false, autoNavigate: false)),
    );
    await tester.pump();

    expect(find.text('ESP Home'), findsOneWidget);
  });

  testWidgets('Home page does not show circular loader route', (WidgetTester tester) async {
    final controller = HomeController();
    controller.loading = true;
    controller.relayStatus['relay1'] = true;
    controller.deviceNames['relay1'] = 'Relay 1';

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          controller: controller,
          initController: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Loading devices'), findsNothing);
  });
}
