import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';

class AddPaymentTypeButton extends StatelessWidget {
  const AddPaymentTypeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: canvasColor,
      ),
      child: const Row(
        children: [
          Icon(Icons.add_rounded, color: white),
          SizedBox(width: 10),
          Text('Add Payment Type', style: TextStyle(color: white)),
        ],
      ),
    );
  }
}
