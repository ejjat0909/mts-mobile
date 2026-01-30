import 'package:flutter/material.dart';
import 'package:mts/presentation/features/shift_history/components/history_details.dart';
import 'package:mts/presentation/features/shift_history/components/history_side_bar.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.max,
      children: [HistorySidebar(), HistoryDetails()],
    );
  }
}
