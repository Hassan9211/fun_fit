// ignore_for_file: unused_local_variable, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double fontSizeTitle = width * 0.06;
        if (width >= 1200)
          fontSizeTitle = width * 0.04;
        else if (width >= 800)
          fontSizeTitle = width * 0.05;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Login', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.blue.shade900,
          ),
          body: Center(
            child: Text(
              'Login Screen',
              style: TextStyle(
                fontSize: fontSizeTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
