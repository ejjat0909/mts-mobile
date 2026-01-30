import 'package:flutter/material.dart';
import 'package:mts/presentation/common/layouts/background.dart';
import 'package:mts/presentation/features/new_password/components/body.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  static const routeName = '/new-password';

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: 0.0,
            bottom: 0.0,
            right: 0.0,
            left: 0.0,
            child: Background(),
          ),
          Positioned(child: Body(email: widget.email)),
        ],
      ),
    );
  }
}
