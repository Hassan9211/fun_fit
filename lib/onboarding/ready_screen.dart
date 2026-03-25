import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';

import '../widget/app_button.dart';
import '../widget/responsive_layout.dart';

class AreYouReadyScreen extends StatelessWidget {
  const AreYouReadyScreen({super.key});

  Map<String, dynamic> _readArgs() {
    final args = Get.arguments;
    if (args is! Map) return <String, dynamic>{};
    return args.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingData = _readArgs();
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final titleSize = info.value(mobile: 32, tablet: 38, desktop: 44);
        final buttonFont = info.value(mobile: 15, tablet: 16, desktop: 17);
        final buttonHeight = info.value(mobile: 52, tablet: 54, desktop: 56);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: ResponsiveContent(
                info: info,
                mobileMaxWidth: 420,
                tabletMaxWidth: 480,
                desktopMaxWidth: 520,
                padding: info.pagePadding(
                  mobileHorizontal: 20,
                  tabletHorizontal: 28,
                  desktopHorizontal: 36,
                  mobileVertical: 24,
                  tabletVertical: 32,
                  desktopVertical: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you ready?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: info.value(mobile: 28, tablet: 32, desktop: 36),
                    ),
                    AppButton(
                      label: "I'm Ready",
                      onPressed: () =>
                          Get.toNamed(Routes.gender, arguments: onboardingData),
                      width: double.infinity,
                      height: buttonHeight,
                      backgroundColor: Colors.black,
                      borderRadius: 8,
                      fontSize: buttonFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
