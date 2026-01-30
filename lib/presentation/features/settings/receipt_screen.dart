import 'package:flutter/material.dart';

class SettingsReceiptScreen extends StatefulWidget {
  const SettingsReceiptScreen({super.key});

  @override
  State<SettingsReceiptScreen> createState() => _SettingsReceiptScreenState();
}

class _SettingsReceiptScreenState extends State<SettingsReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Receipt'));
  }
}
