import 'package:flutter/material.dart';

class ButtonCircleDelete extends StatelessWidget {
  final Function()? onPressed;

  const ButtonCircleDelete({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.red.withValues(alpha: .1),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        backgroundColor: Colors.red.withValues(alpha: .1), // <-- Button color
      ),
      child: const Icon(Icons.delete_outline, color: Colors.red),
    );
  }
}
