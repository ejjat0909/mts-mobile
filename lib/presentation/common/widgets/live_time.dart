import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LiveTime extends StatefulWidget {
  const LiveTime({super.key});

  @override
  State<LiveTime> createState() => _LiveTimeState();
}

class _LiveTimeState extends State<LiveTime> {
  late Timer _timer;
  late String _formattedTime;

  @override
  void initState() {
    super.initState();
    _updateTime(); // Initialize the time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime(); // Update time every second
    });
  }

  void _updateTime() {
    setState(() {
      DateTime now = DateTime.now();
      _formattedTime = DateFormat('d MMMM yyyy - h:mm a', 'en_US').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formattedTime,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
  }
}
