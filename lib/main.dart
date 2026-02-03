import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fun_fit/widget/getx.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash,
      getPages: Routes.pages,
    );
  }
}
