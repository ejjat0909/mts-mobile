import 'package:flutter/material.dart';

class TaxesScreen extends StatefulWidget {
  const TaxesScreen({super.key});

  @override
  State<TaxesScreen> createState() => _TaxesScreenState();
}

class _TaxesScreenState extends State<TaxesScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Taxes'));
  }
}
