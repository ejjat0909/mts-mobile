import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/presentation/common/dialogs/number_button_dialogue.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuantityNumberPad extends ConsumerStatefulWidget {
  final ItemModel itemModel;
  final Function(double) onOkPress;
  final Function() onClose;

  const QuantityNumberPad({
    super.key,
    required this.itemModel,
    required this.onOkPress,
    required this.onClose,
  });

  @override
  ConsumerState<QuantityNumberPad> createState() => _QuantityNumberPadState();
}

class _QuantityNumberPadState extends ConsumerState<QuantityNumberPad>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  String currentQty = '0';

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
      currentQty = itemState.tempQty ?? '0';
      setState(() {});
    });
  }

  int getDecimalPlaces() {
    return widget.itemModel.soldBy == ItemSoldByEnum.measurement ? 3 : 0;
  }

  Future<void> _closeWithAnimation() async {
    await _controller.reverse(); // Reverse the animation
    widget.onClose(); // Close the dialog
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the animation controller
    super.dispose();
  }

  // Function to handle number button press
  void handleNumberPress(String number) {
    setState(() {
      String cleanNumber = currentQty.replaceAll('.', '');
      cleanNumber = (cleanNumber + number).replaceAll(RegExp(r'^0+'), '');

      const int maxLength = 14;
      if (cleanNumber.length > maxLength) {
        cleanNumber = cleanNumber.substring(0, maxLength);
      }

      if (cleanNumber.isEmpty) cleanNumber = '0';

      int decimalPlaces = getDecimalPlaces();
      double value = int.parse(cleanNumber) / (decimalPlaces == 3 ? 1000 : 1);
      currentQty =
          decimalPlaces == 3
              ? value.toStringAsFixed(3)
              : value.toStringAsFixed(0);
    });
    ref.read(itemProvider.notifier).setTempQty(currentQty);
  }

  void handleDeletePress() {
    setState(() {
      String cleanNumber = currentQty.replaceAll('.', '');
      if (cleanNumber.isNotEmpty) {
        cleanNumber = cleanNumber.substring(0, cleanNumber.length - 1);
      }
      if (cleanNumber.isEmpty) cleanNumber = '0';

      int decimalPlaces = getDecimalPlaces();
      double value = int.parse(cleanNumber) / (decimalPlaces == 3 ? 1000 : 1);
      currentQty =
          decimalPlaces == 3
              ? value.toStringAsFixed(3)
              : value.toStringAsFixed(0);
    });
    ref.read(itemProvider.notifier).setTempQty(currentQty);
  }

  void handleDeleteAllPress() {
    setState(() {
      currentQty = getDecimalPlaces() == 3 ? '0.000' : '0';
    });
    ref.read(itemProvider.notifier).setTempQty(currentQty);
  }

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      Text('quantity'.tr(), style: AppTheme.h1TextStyle()),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: AutoSizeText(
                          currentQty,
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
                        onLongPress: () {
                          handleDeleteAllPress();
                        },
                        press: () {
                          handleDeletePress();
                        },
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: NumberButtonDialogue(
                        isOkButton: true,
                        isEnabled:
                            currentQty !=
                            (getDecimalPlaces() == 3 ? '0.000' : '0'),
                        press:
                            currentQty !=
                                    (getDecimalPlaces() == 3 ? '0.000' : '0')
                                ? () {
                                  double result = double.parse(currentQty);
                                  widget.onOkPress(result);
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
    );
  }
}
