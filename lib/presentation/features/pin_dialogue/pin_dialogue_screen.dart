import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/presentation/features/pin_dialogue/components/num_pad_dialog_body.dart';

class PinDialogueScreen extends ConsumerStatefulWidget {
  final String permission;
  final Function() onSuccess;
  final Function(String message) onError;
  const PinDialogueScreen({
    super.key,
    required this.onSuccess,
    required this.onError,
    required this.permission,
  });

  @override
  ConsumerState<PinDialogueScreen> createState() => _PinDialogueScreenState();
}

class _PinDialogueScreenState extends ConsumerState<PinDialogueScreen> {
  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    double borderRadius = 20; // Adjust as needed
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius), //
      ),

      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 1.2,
          minHeight: availableHeight / 1.2,
          maxWidth: availableWidth / 2.5,
        ),
        child: Container(
          width: double.infinity,

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                offset: const Offset(8, 20),
                blurRadius: 25,
                color: Colors.black.withValues(alpha: 0.02),
              ),
              BoxShadow(
                offset: const Offset(0, 10),
                blurRadius: 10,
                color: Colors.black.withValues(alpha: 0.02),
              ),
            ],
          ),

          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                NumPadDialogBody(
                  onSuccess: widget.onSuccess,
                  permission: widget.permission,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
