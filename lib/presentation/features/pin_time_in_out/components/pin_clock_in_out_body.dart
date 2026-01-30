import 'package:flutter/material.dart';
import 'package:mts/presentation/features/pin_time_in_out/components/num_pad_clock_in_out.dart';

class PinClockInOutBody extends StatefulWidget {
  final int currentIndex;

  const PinClockInOutBody({super.key, required this.currentIndex});

  @override
  State<PinClockInOutBody> createState() => _PinClockInOutBodyState();
}

class _PinClockInOutBodyState extends State<PinClockInOutBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [NumPadClockInOut(currentIndex: widget.currentIndex)],
          ),
        ),
      ),
    );
  }
}
