import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/layouts/background.dart';
import 'package:mts/presentation/features/login/components/body.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //callback function when back button is pressed
        return NavigationUtils.showExitPopup(context);
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            const Positioned(
              top: 0.0,
              bottom: 0.0,
              right: 0.0,
              left: 0.0,
              child: Background(),
            ),
           
            const Positioned(child: Body()),
          ],
        ),
      ),
    );
  }
}
