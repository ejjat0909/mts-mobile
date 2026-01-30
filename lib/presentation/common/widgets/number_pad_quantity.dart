import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/presentation/common/dialogs/number_button_dialogue.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class NumberPadDialogue extends StatefulWidget {
  final ItemModel itemModel;
  final SaleItemModel? saleItemModel;
  final Function(ItemModel, SaleItemModel?, double) onSave;

  const NumberPadDialogue({
    super.key,
    required this.itemModel,
    required this.onSave,
    required this.saleItemModel,
  });

  @override
  State<NumberPadDialogue> createState() => _NumberPadDialogueState();
}

class _NumberPadDialogueState extends State<NumberPadDialogue> {
  String currentNumber = '0';

  // Function to handle number button press
  void handleNumberPress(String number) {
    setState(() {
      if (currentNumber == '0') {
        currentNumber = number;
      } else {
        currentNumber += number;
      }
    });
  }

  // Function to handle decimal button press
  void handleDecimalPress() {
    setState(() {
      if (!currentNumber.contains('.')) {
        currentNumber += '.';
      }
    });
  }

  // Function to handle delete button press
  void handleDeletePress() {
    setState(() {
      if (currentNumber.length > 1) {
        currentNumber = currentNumber.substring(0, currentNumber.length - 1);
      } else {
        currentNumber = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double availableWidth = MediaQuery.of(context).size.width;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: availableWidth / 1.5),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                  onPressed: () => Navigator.of(context).pop(),
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
                    Text('Quantity', style: AppTheme.h1TextStyle()),
                    Text(currentNumber, style: AppTheme.h1TextStyle()),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '1',
                                    press: () {
                                      handleNumberPress('1');
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '2',
                                    press: () {
                                      handleNumberPress('2');
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '3',
                                    press: () {
                                      handleNumberPress('3');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '4',
                                    press: () {
                                      handleNumberPress('4');
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '5',
                                    press: () {
                                      handleNumberPress('5');
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // delete
                    Expanded(
                      child: NumberButtonDialogue(
                        press: () {
                          handleDeletePress();
                          prints(
                            (double.parse(currentNumber.replaceAll('RM', ''))),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Space(10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '7',
                                    press: () {
                                      handleNumberPress('7');
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '8',
                                    press: () {
                                      handleNumberPress('8');
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '9',
                                    press: () {
                                      handleNumberPress('9');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: NumberButtonDialogue(
                                    number: '.',
                                    press: () {
                                      handleDecimalPress();
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  flex: 2,
                                  child: NumberButtonDialogue(
                                    number: '0',
                                    press: () {
                                      handleNumberPress('0');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // OK
                    Expanded(
                      child: NumberButtonDialogue(
                        isOkButton: true,
                        press: () {
                          prints(currentNumber);
                          widget.onSave(
                            widget.itemModel,
                            widget.saleItemModel,
                            double.parse(currentNumber),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
