import 'package:flutter/material.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/presentation/common/layouts/background.dart';
import 'package:mts/presentation/features/pin_lock/components/pin_lock_body.dart.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  static const routeName = '/pin_lock';

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //callback function when back button is pressed
        return NavigationUtils.showExitPopup(context);
      },
      child: const Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0.0,
              bottom: 0.0,
              right: 0.0,
              left: 0.0,
              child: Background(),
            ),
            // Positioned(
            //   top: 0.0,
            //   bottom: 0.0,
            //   right: 0.0,
            //   left: 0.0,
            //   child: RotatedBox(quarterTurns: 2, child: Background()),
            // ),
            Positioned(child: PinLockBody(currentIndex: 0)),
          ],
        ),
      ),
    );
  }
}
