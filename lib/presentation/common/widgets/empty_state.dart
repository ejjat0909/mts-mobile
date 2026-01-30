import 'package:flutter/material.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class EmptyState extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyState({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kBg, size: 48),
          const Space(20),
          Text(text, style: textStyleGray(), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
