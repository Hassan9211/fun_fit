import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_button.dart';

class AreYouReadyScreen extends StatelessWidget {
  const AreYouReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double titleSize = width * 0.08;
        double buttonFont = width * 0.045;
        double buttonHeight = 52;
        double paddingH = width * 0.08;

        if (width >= 1200) {
          titleSize = width * 0.045;
          buttonFont = width * 0.025;
          paddingH = width * 0.3;
        } else if (width >= 800) {
          titleSize = width * 0.055;
          buttonFont = width * 0.035;
          paddingH = width * 0.2;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            height: height,
            width: width,

            /// 🎨 Gradient Background
            color: Colors.white,

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Title
                  Text(
                    'Are you ready?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: height * 0.06),

                  /// Button
                  AppButton(
                    label: "I'm Ready",
                    onPressed: () => Get.toNamed(Routes.gender),
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
        );
      },
    );
  }

  /// 🎬 Custom animation can be reintroduced later using GetX transitions if needed.
}
