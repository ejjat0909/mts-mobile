import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/payment_type_enum.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class PaymentTypeDialogue extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function() onCallback;

  const PaymentTypeDialogue({
    super.key,
    required this.onClose,
    required this.onCallback,
  });

  @override
  ConsumerState<PaymentTypeDialogue> createState() =>
      _PaymentTypeDialogueState();
}

class _PaymentTypeDialogueState extends ConsumerState<PaymentTypeDialogue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  List<PaymentTypeModel> listPaymentTypes = [];

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
    getPaymentTypes();
  }

  Future<void> getPaymentTypes() async {
    listPaymentTypes = ref.read(paymentTypeProvider).items;
    setState(() {});
  }

  _setSelected(int newSelected) {
    ref
        .read(receiptProvider.notifier)
        .setTempPaymentType(listPaymentTypes[newSelected].name, newSelected);
    widget.onCallback();
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);

    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: availableHeight / 1.5,
            maxWidth: availableWidth / 2.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Space(10),
              AppBar(
                elevation: 0,
                backgroundColor: white,
                title: Text(
                  'selectPaymentType'.tr(),
                  style: AppTheme.h1TextStyle(),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: canvasColor),
                  onPressed: _closeWithAnimation,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Builder(
                    builder: (context) {
                      if (listPaymentTypes.isNotEmpty) {
                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Number of items per row
                                crossAxisSpacing: 10, // Horizontal spacing
                                mainAxisSpacing: 15, // Vertical spacing
                                childAspectRatio: 2,
                              ),
                          itemCount: listPaymentTypes.length,
                          itemBuilder: (context, index) {
                            final method = listPaymentTypes[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      receiptState.selectedPaymentTypeIndex ==
                                              index
                                          ? kPrimaryBgColor
                                          : null,
                                  minimumSize: const Size(160, 0),
                                  side: BorderSide(
                                    color:
                                        receiptState.selectedPaymentTypeIndex ==
                                                index
                                            ? kPrimaryColor
                                            : kTextGray.withValues(alpha: 0.5),
                                  ),
                                ),
                                onPressed: () => _setSelected(index),
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
                        );
                      } else {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FontAwesomeIcons.solidCreditCard,
                                color: kTextGray,
                                size: 50,
                              ),
                              Space(20.h),
                              Text(
                                'paymentTypeNotAvailable'.tr(),
                                style: AppTheme.mediumTextStyle(
                                  color: kTextGray.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
}
