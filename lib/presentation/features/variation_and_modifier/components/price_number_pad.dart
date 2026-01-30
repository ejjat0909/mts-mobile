import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/presentation/common/dialogs/number_button_dialogue.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PriceNumberPad extends ConsumerStatefulWidget {
  final ItemModel itemModel;
  final Function(double) onOkPress;
  final Function() onClose;

  const PriceNumberPad({
    super.key,
    required this.itemModel,
    required this.onOkPress,
    required this.onClose,
  });

  @override
  ConsumerState<PriceNumberPad> createState() => _PriceNumberPadState();
}

class _PriceNumberPadState extends ConsumerState<PriceNumberPad>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linearToEaseOut,
    );
    _controller.forward(); // Start the animation when the dialog appears

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemState = ref.read(itemProvider);
      currentPrice = itemState.tempPrice ?? '${'RM'.tr(args: [''])}0.00';
      setState(() {});
    });
  }

  // _setSelected(int newSelected, ReceiptNotifier rn) {

  //   widget.onCallback();
  //   setState(() {});
  // }

  Future<void> _closeWithAnimation() async {
    await _controller.reverse(); // Reverse the animation
    widget.onClose(); // Close the dialog
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the animation controller
    super.dispose();
  }

  String currentPrice = '${'RM'.tr(args: [''])}0.00';

  void handleNumberPress(String number) {
    setState(() {
      // Remove the "RM" prefix and the decimal point for calculation
      String cleanNumber = currentPrice
          .replaceAll('RM'.tr(args: ['']), '')
          .replaceAll('.', '');

      // Append the new number
      cleanNumber = (cleanNumber + number).replaceAll(RegExp(r'^0+'), '');

      // Limit the length to a reasonable maximum (e.g., 12 digits for safety)
      const int maxLength = 14;
      if (cleanNumber.length > maxLength) {
        cleanNumber = cleanNumber.substring(0, maxLength);
      }

      // Ensure the clean number is at least "0" if it's empty
      if (cleanNumber.isEmpty) cleanNumber = '0';

      // Reformat with two decimal places and add the "RM" prefix
      double value = int.parse(cleanNumber) / 100;
      currentPrice = 'RM'.tr(args: ['']) + value.toStringAsFixed(2);
    });
    ref.read(itemProvider.notifier).setTempPrice(currentPrice);
  }

  void handleDeletePress() {
    setState(() {
      // Remove the "RM" prefix and the decimal point for calculation
      String cleanNumber = currentPrice
          .replaceAll('RM'.tr(args: ['']), '')
          .replaceAll('.', '');

      // Remove the last character (digit)
      if (cleanNumber.isNotEmpty) {
        cleanNumber = cleanNumber.substring(0, cleanNumber.length - 1);
      }

      // Ensure the clean number is at least "0" if it's empty
      if (cleanNumber.isEmpty) cleanNumber = '0';

      // Reformat with two decimal places and add the "RM" prefix
      double value = int.parse(cleanNumber) / 100;
      currentPrice = 'RM'.tr(args: ['']) + value.toStringAsFixed(2);
    });
    ref.read(itemProvider.notifier).setTempPrice(currentPrice);
  }

  void handleDeleteAllPress() {
    setState(() {
      currentPrice = 'RM'.tr(args: ['0.00']);
    });
    ref.read(itemProvider.notifier).setTempPrice(currentPrice);
  }

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SafeArea(
        child: Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: availableWidth / 3.3),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              // child: Row(
              //   children: [Expanded(child: Text(""))],
              // ),
              child: Column(
                children: [
                  const Space(15),
                  AppBar(
                    elevation: 0,
                    backgroundColor: white,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.itemModel.name ?? 'null',
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.h1TextStyle(),
                          ),
                        ),
                      ],
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: canvasColor),
                      onPressed: () {
                        _closeWithAnimation();
                      },
                    ),
                  ),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('price'.tr(), style: AppTheme.h1TextStyle()),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: AutoSizeText(
                            currentPrice,
                            style: AppTheme.h1TextStyle(),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            maxFontSize: 20,
                            minFontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // 1, 2
                  Row(
                    children: [
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '1',
                          press: () {
                            handleNumberPress('1');
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '2',
                          press: () {
                            handleNumberPress('2');
                          },
                        ),
                      ),
                    ],
                  ),
                  const Space(5),
                  // 3, 4
                  Row(
                    children: [
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '3',
                          press: () {
                            handleNumberPress('3');
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '4',
                          press: () {
                            handleNumberPress('4');
                          },
                        ),
                      ),
                    ],
                  ),
                  // 5, 6
                  const Space(5),
                  Row(
                    children: [
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '5',
                          press: () {
                            handleNumberPress('5');
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '6',
                          press: () {
                            handleNumberPress('6');
                          },
                        ),
                      ),
                    ],
                  ),
                  // 7, 8
                  const Space(5),
                  Row(
                    children: [
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '7',
                          press: () {
                            handleNumberPress('7');
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '8',
                          press: () {
                            handleNumberPress('8');
                          },
                        ),
                      ),
                    ],
                  ),
                  const Space(5),
                  // 9, 0
                  Row(
                    children: [
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '9',
                          press: () {
                            handleNumberPress('9');
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: NumberButtonDialogue(
                          number: '0',
                          press: () {
                            handleNumberPress('0');
                          },
                        ),
                      ),
                    ],
                  ),
                  const Space(5),
                  // delete, ok
                  Row(
                    children: [
                      Expanded(
                        child: NumberButtonDialogue(
                          isOkButton: false,
                          press: () {
                            handleDeletePress();
                          },
                          onLongPress: () {
                            handleDeleteAllPress();
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: NumberButtonDialogue(
                          isOkButton: true,
                          isEnabled: currentPrice != 'RM'.tr(args: ['0.00']),
                          press:
                              currentPrice != 'RM'.tr(args: ['0.00'])
                                  ? () {
                                    double cost = (double.parse(
                                      currentPrice.replaceAll(
                                        'RM'.tr(args: ['']),
                                        '',
                                      ),
                                    ));
                                    // prints(result.toStringAsFixed(2));
                                    ref
                                        .read(itemProvider.notifier)
                                        .setTempPrice(cost.toStringAsFixed(2));

                                    if (cost != 0.0) {
                                      widget.onOkPress(cost);
                                    }
                                  }
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
