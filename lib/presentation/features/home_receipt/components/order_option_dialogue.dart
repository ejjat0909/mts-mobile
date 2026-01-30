import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';

class OrderOptionDialogue extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function() onCallback;

  const OrderOptionDialogue({
    super.key,
    required this.onClose,
    required this.onCallback,
  });

  @override
  ConsumerState<OrderOptionDialogue> createState() =>
      _OrderOptionDialogueState();
}

class _OrderOptionDialogueState extends ConsumerState<OrderOptionDialogue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  List<OrderOptionModel> listOrderOption = [];

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
    getOrderOption();
  }

  Future<void> getOrderOption() async {
    listOrderOption = ref.read(orderOptionProvider).items;
    setState(() {});
  }

  _setSelected(int newSelected) {
    ref
        .read(receiptProvider.notifier)
        .setTempOrderOption(listOrderOption[newSelected].name, newSelected);
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
                  'selectOrderOption'.tr(),
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
                      if (listOrderOption.isNotEmpty) {
                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Number of items per row
                                crossAxisSpacing: 10, // Horizontal spacing
                                mainAxisSpacing: 15, // Vertical spacing
                                childAspectRatio: 2.0,
                              ),
                          itemCount: listOrderOption.length,
                          itemBuilder: (context, index) {
                            final method = listOrderOption[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      receiptState.selectedOrderOptionIndex ==
                                              index
                                          ? kPrimaryBgColor
                                          : null,
                                  minimumSize: const Size(160, 0),
                                  side: BorderSide(
                                    color:
                                        receiptState.selectedOrderOptionIndex ==
                                                index
                                            ? kPrimaryColor
                                            : kTextGray.withValues(alpha: 0.5),
                                  ),
                                ),
                                onPressed: () => _setSelected(index),
                                child: Center(
                                  child: Text(
                                    method.name!,
                                    style: const TextStyle(color: Colors.black),
                                  ),
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
                                Icons.delivery_dining,
                                color: kTextGray,
                                size: 50,
                              ),
                              Space(20.h),
                              Text(
                                'orderOptionNotAvailable'.tr(),
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
}
