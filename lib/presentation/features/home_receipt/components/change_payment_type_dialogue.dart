import 'package:easy_localization/easy_localization.dart';
import 'package:fluid_dialog/fluid_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/payment_type_enum.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class ChangePaymentTypeDialogue extends ConsumerStatefulWidget {
  final ReceiptModel receiptModel;
  final Function(ReceiptModel) onUpdatePaymentMethod;

  const ChangePaymentTypeDialogue({
    super.key,
    required this.receiptModel,
    required this.onUpdatePaymentMethod,
  });

  @override
  ConsumerState<ChangePaymentTypeDialogue> createState() =>
      _ChangePaymentTypeDialogueState();
}

class _ChangePaymentTypeDialogueState
    extends ConsumerState<ChangePaymentTypeDialogue> {
  List<PaymentTypeModel> listPaymentTypes = [];
  PaymentTypeModel? selectedPaymentType;
  int? selectedPaymentTypeIndex;

  @override
  void initState() {
    getPaymentTypes();
    super.initState();
  }

  Future<void> getPaymentTypes() async {
    listPaymentTypes =
        await ref.read(paymentTypeProvider.notifier).getListPaymentType();
    setState(() {});
  }

  void _setSelected(int index, PaymentTypeModel? selectedPTM) {
    setState(() {
      selectedPaymentTypeIndex = index;
      selectedPaymentType = selectedPTM;
    });
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: availableWidth / 2,
      height: availableHeight / 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Space(10),
          AppBar(
            elevation: 0,
            backgroundColor: white,
            title: Row(
              children: [
                Text('changePaymentType'.tr(), style: AppTheme.h1TextStyle()),
                const Expanded(flex: 2, child: SizedBox()),
                ButtonTertiary(
                  text: 'save'.tr(),
                  icon: Icons.currency_exchange,
                  onPressed: () async {
                    await handleOnPressSave();
                  },
                ),
              ],
            ),

            // back button
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: canvasColor),
              onPressed: () {
                DialogNavigator.of(context).pop();
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child:
                  listPaymentTypes.isNotEmpty
                      ? GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 15,
                              childAspectRatio: 2,
                            ),
                        itemCount: listPaymentTypes.length,
                        itemBuilder: (context, index) {
                          PaymentTypeModel method = listPaymentTypes[index];
                          bool isSelected = selectedPaymentTypeIndex == index;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    isSelected ? kPrimaryBgColor : Colors.white,
                                minimumSize: const Size(160, 0),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? kPrimaryColor
                                          : kTextGray.withValues(alpha: 0.5),
                                ),
                              ),
                              onPressed: () => _setSelected(index, method),
                              icon: Icon(
                                getIcon(method),
                                color: getIconColor(method),
                              ),
                              label: Text(
                                method.name!,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          );
                        },
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              FontAwesomeIcons.solidCreditCard,
                              color: kTextGray,
                              size: 50,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'paymentTypeNotAvailable'.tr(),
                              style: AppTheme.mediumTextStyle(
                                color: kTextGray.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  IconData getIcon(PaymentTypeModel method) {
    if (method.name!.toLowerCase().contains('cash')) {
      return Icons.money;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.card) {
      return Icons.credit_card;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.cheque) {
      return FontAwesomeIcons.wallet;
    } else {
      return Icons.money;
    }
  }

  Color getIconColor(PaymentTypeModel method) {
    if (method.name!.toLowerCase().contains('cash')) {
      return Colors.green;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.card) {
      return Colors.red;
    } else if (method.paymentTypeCategory == PaymentTypeEnum.cheque) {
      return Colors.blue;
    } else {
      return Colors.black;
    }
  }

  Future<void> handleOnPressSave() async {
    if (selectedPaymentType == null) {
      ThemeSnackBar.showSnackBar(context, 'pleaseSelectPaymentType'.tr());
      return;
    }

    ReceiptModel newReceiptModel = widget.receiptModel.copyWith(
      paymentType: selectedPaymentType?.name,
      isChangePaymentType: true,
    );

    await ref.read(receiptProvider.notifier).update(newReceiptModel);
    widget.onUpdatePaymentMethod(newReceiptModel);
  }
}
