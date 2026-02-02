import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fun_fit/main.dart';

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
          body: Container(
            height: height,
            width: width,

            /// 🎨 Gradient Background
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),

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
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Get.toNamed(Routes.gender),
                      child: Text(
                        "I'm Ready",
                        style: TextStyle(
                          fontSize: buttonFont,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
