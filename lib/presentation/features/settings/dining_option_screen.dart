import 'package:flutter/material.dart';

class DiningOptionScreen extends StatefulWidget {
  const DiningOptionScreen({super.key});

  @override
  State<DiningOptionScreen> createState() => _DiningOptionScreenState();
}

class _DiningOptionScreenState extends State<DiningOptionScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dining Option'));
  }
}
