import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:fun_fit/main.dart';
import 'package:fun_fit/widget/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots and shows splash branding', (WidgetTester tester) async {
    Get.testMode = true;
    Get.reset();
    Get.put(ThemeController(), permanent: true);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ModivFit'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    Get.reset();
  });
}
