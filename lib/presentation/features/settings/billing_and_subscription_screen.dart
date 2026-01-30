import 'package:flutter/material.dart';

class BillingAndSubscriptionScreen extends StatefulWidget {
  const BillingAndSubscriptionScreen({super.key});

  @override
  State<BillingAndSubscriptionScreen> createState() =>
      _BillingAndSubscriptionScreenState();
}

class _BillingAndSubscriptionScreenState
    extends State<BillingAndSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Billing Subscription'));
  }
}
