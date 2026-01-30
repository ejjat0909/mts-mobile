import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';

class Numpad extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const Numpad({super.key, required this.controller});

  @override
  ConsumerState<Numpad> createState() => _NumpadState();
}

class _NumpadState extends ConsumerState<Numpad> {
  bool _isUpdating = false;

  void _scheduleUpdate() {
    if (_isUpdating) return;
    _isUpdating = true;

    Future.microtask(() {
      if (mounted) {
        setState(() {});
        _isUpdating = false;
      }
    });
  }

  void appendText(String val) {
    if (val == '.' && widget.controller.text.contains('.')) {
      return;
    }

    if (widget.controller.text.contains('.')) {
      String decimalPart = widget.controller.text.split('.').last;
      if (decimalPart.length >= 2) {
        return;
      }
    }

    widget.controller.text += val;
    _scheduleUpdate();
  }

  void replaceValue(String val) {
    // widget.controller.text == ''
    //     ? widget.controller.text = val
    //     : widget.controller.text = (double.parse(val) +
    //             double.parse(widget.controller.text))
    //         .toStringAsFixed(2);

    // Dekat page charge, bila tekan jumlah yang dekat kiri tu takyah tambah, tukar terus je
    widget.controller.text = val;

    _scheduleUpdate();
  }

  @override
  Widget build(BuildContext context) {
    const BorderSide borderSide = BorderSide(color: kLightGray);

    // Cache provider reads to avoid multiple calls
    final saleItemsState = ref.watch(saleItemProvider);
    final spn = ref.watch(splitPaymentProvider);

    // Cache heavy computations
    final double totalAmountRemaining =
        saleItemsState.isSplitPayment
            ? double.parse(spn.totalAmountRemaining.toStringAsFixed(2))
            : double.parse(
              saleItemsState.totalAmountRemaining.toStringAsFixed(2),
            );

    // Cache the prediction list to avoid recalculating on every rebuild
    final List<String> listAmountPrediction = ref
        .read(saleProvider.notifier)
        .getPossiblePaymentAmounts(totalAmountRemaining);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children:
                    listAmountPrediction.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: LeftPad(
                          value: e,
                          onPressed: () => replaceValue(e),
                        ),
                      );
                    }).toList(),
                // children: [
                //   LeftPad(
                //     value: '30.00',
                //     onPressed: () => sumText('30.00'),
                //   ),
                //   const SizedBox(height: 10),
                //   LeftPad(
                //     value: '40.00',
                //     onPressed: () => sumText('40.00'),
                //   ),
                //   const SizedBox(height: 10),
                //   LeftPad(
                //     value: '50.00',
                //     onPressed: () => sumText('50.00'),
                //   ),
                //   const SizedBox(height: 10),
                //   LeftPad(
                //     value: '60.00',
                //     onPressed: () => sumText('60.00'),
                //   ),
                //   const SizedBox(height: 10),
                //   LeftPad(
                //     value: '60.00',
                //     onPressed: () => sumText('60.00'),
                //   ),
                //   const SizedBox(height: 10),
                //   LeftPad(
                //     value: '60.00',
                //     onPressed: () => sumText('60.00'),
                //   ),
                //   const SizedBox(height: 10),
                //   LeftPad(
                //     value: '60.00',
                //     onPressed: () => sumText('60.00'),
                //   ),
                // ],
              ),
            ),
          ),
          // num pad
          Expanded(
            flex: 3,
            child: Column(
              children: [
                buildNumKeyRow(
                  ['1', '2', '3'],
                  [
                    () => appendText('1'),
                    () => appendText('2'),
                    () => appendText('3'),
                  ],
                  [
                    const BorderDirectional(
                      bottom: borderSide,
                      end: borderSide,
                    ),
                    const BorderDirectional(
                      bottom: borderSide,
                      end: borderSide,
                    ),
                    const BorderDirectional(bottom: borderSide),
                  ],
                ),
                buildNumKeyRow(
                  ['4', '5', '6'],
                  [
                    () => appendText('4'),
                    () => appendText('5'),
                    () => appendText('6'),
                  ],
                  [
                    const BorderDirectional(
                      bottom: borderSide,
                      end: borderSide,
                    ),
                    const BorderDirectional(
                      bottom: borderSide,
                      end: borderSide,
                    ),
                    const BorderDirectional(bottom: borderSide),
                  ],
                ),
                buildNumKeyRow(
                  ['7', '8', '9'],
                  [
                    () => appendText('7'),
                    () => appendText('8'),
                    () => appendText('9'),
                  ],
                  [
                    const BorderDirectional(
                      bottom: borderSide,
                      end: borderSide,
                    ),
                    const BorderDirectional(
                      bottom: borderSide,
                      end: borderSide,
                    ),
                    const BorderDirectional(bottom: borderSide),
                  ],
                ),
                buildNumKeyRow(
                  ['.', '0', 'backspace'],
                  [
                    () => appendText('.'),
                    () => appendText('0'),
                    () {
                      if (widget.controller.text.isNotEmpty) {
                        widget.controller.text = widget.controller.text
                            .substring(0, widget.controller.text.length - 1);

                        _scheduleUpdate();
                      }
                    },
                  ],
                  [
                    const BorderDirectional(end: borderSide),
                    const BorderDirectional(end: borderSide),
                    const BorderDirectional(),
                  ],
                  onLongPress: () {
                    widget.controller.clear();

                    _scheduleUpdate();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row of `NumKey` widgets with specified labels and actions.
  ///
  /// The `labels` parameter is a list of strings representing the labels for the `NumKey` widgets.
  /// The `actions` parameter is a list of functions to be executed when the `NumKey` widgets are pressed.
  /// The `borderStyles` parameter is a list of `BorderDirectional` styles for the `NumKey` widgets.
  Widget buildNumKeyRow(
    List<String> labels,
    List<VoidCallback> actions,
    List<BorderDirectional> borderStyles, {
    VoidCallback? onLongPress,
  }) {
    return Expanded(
      child: Row(
        children: List.generate(labels.length, (index) {
          return Expanded(
            child: NumKey(
              borderDirectional: borderStyles[index],
              onPressed: actions[index],
              onLongPressed: labels[index] == 'backspace' ? onLongPress : null,
              child:
                  labels[index] == 'backspace'
                      ? const Icon(Icons.backspace_outlined)
                      : Text(labels[index], style: AppTheme.h1TextStyle()),
            ),
          );
        }),
      ),
    );
  }
}

class LeftPad extends StatelessWidget {
  final String value;
  final Function() onPressed;

  const LeftPad({super.key, required this.value, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        fixedSize: const Size(200, 60),
        backgroundColor: kLightGray,
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(FormatUtils.formatNumber(value)),
    );
  }
}

class NumKey extends StatelessWidget {
  final BorderDirectional? borderDirectional;
  final Function() onPressed;
  final Function()? onLongPressed;
  final Widget child;

  const NumKey({
    super.key,
    this.borderDirectional,
    this.onLongPressed,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: InkWell(
          onLongPress: onLongPressed,
          onTap: onPressed,
          splashColor: kPrimaryLightColor,
          highlightColor: kPrimaryLightColor,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(border: borderDirectional),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
