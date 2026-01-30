import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/layouts/background.dart';
import 'package:mts/presentation/features/activate_license/components/body.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  static const routeName = '/license';

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //callback function when back button is pressed
        return NavigationUtils.showExitPopup(context);
      },
      child: const Scaffold(
        backgroundColor: kBg,
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
      ),
    );
  }
}
