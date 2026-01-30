import 'package:flutter/material.dart';
import 'package:mts/presentation/common/layouts/background.dart';
import 'package:mts/presentation/features/forgot_password/components/body.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0.0,
            bottom: 0.0,
            right: 0.0,
            left: 0.0,
            child: Background(),
          ),
          Positioned(child: Body()),
        ],
      ),
    );
  }
}
