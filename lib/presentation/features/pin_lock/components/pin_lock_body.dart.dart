import 'package:flutter/material.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/presentation/features/pin_lock/components/num_pad.dart';

class PinLockBody extends StatefulWidget {
  final int currentIndex;

  const PinLockBody({super.key, required this.currentIndex});

  @override
  State<PinLockBody> createState() => _PinLockBodyState();
}

class _PinLockBodyState extends State<PinLockBody> {
  final showSecondaryDisplayFacade =
      ServiceLocator.get<SecondaryDisplayService>();
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   prints('STOP SECONDARY DISPLAY');
    //   await showSecondaryDisplayFacade.stopSecondaryDisplay(displayManager);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(children: [NumPad(currentIndex: widget.currentIndex)]),
        ),
      ),
    );
  }
}
