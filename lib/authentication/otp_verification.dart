// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String emailOrPhone; // optional, to show where OTP was sent
  const OtpVerificationScreen({super.key, this.emailOrPhone = ''});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var ctrl in _otpControllers) ctrl.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter complete 4-digit OTP')),
      );
      return;
    }
    // For now just navigate to LoginScreen after verification
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    double spacing = height * 0.03;
    double fontTitle = width * 0.06;
    double fontField = width * 0.045;
    double buttonHeight = 50;

    if (width >= 1200) {
      fontTitle = width * 0.04;
      fontField = width * 0.025;
      buttonHeight = 60;
    } else if (width >= 800) {
      fontTitle = width * 0.05;
      fontField = width * 0.035;
      buttonHeight = 55;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'OTP Verification',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.08,
          vertical: spacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: spacing),
            Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: fontTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Text(
              'Enter the 4-digit code sent to ${widget.emailOrPhone}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontField,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: spacing),

            /// OTP Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            SizedBox(height: spacing),

            /// Resend OTP
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP resent successfully')),
                );
              },
              child: const Text(
                'Resend OTP',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: spacing),

            /// Verify Button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: fontField,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
