import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';
import 'package:mts/presentation/features/payment/components/payment_details.dart';

class AppBarPayment extends ConsumerWidget implements PreferredSizeWidget {
  final String titleLeftSide;
  final String titleRightSide;

  const AppBarPayment({
    super.key,
    required this.titleLeftSide,
    required this.titleRightSide,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    final canBackToSalesPage = saleItemsState.canBackToSalesPage;

    final paymentState = ref.watch(paymentProvider);
    final paymentNotifier = ref.read(paymentProvider.notifier);
    final splitPaymentState = ref.watch(splitPaymentProvider);

    final navigator = paymentState.paymentNavigator;
    return AppBar(
      automaticallyImplyLeading: false,
      // Disable the default leading icon
      backgroundColor:
          navigator == PaymentNavigatorEnum.paymentScreen &&
                  (paymentState.paymentNavigator !=
                          PaymentNavigatorEnum.saleSummary &&
                      splitPaymentState.saleItems.isEmpty)
              ? canvasColor
              : darkCanvasColor,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          // left side of the app bar
          Expanded(
            flex: 2,
            child: Container(
              height: kToolbarHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topRight: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  canBackToSalesPage
                      ? SizedBox(
                        width:
                            navigator == PaymentNavigatorEnum.splitPayment
                                ? 0
                                : 15,
                      )
                      : Container(),
                  canBackToSalesPage
                      ? navigator == PaymentNavigatorEnum.splitPayment
                          ? Container()
                          : IconButton(
                            onPressed: () {
                              // back to sales page
                              onPressBackToSalesScreen(
                                context,
                                saleItemsNotifier,
                                ref,
                              );
                            },
                            icon: const Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Icon(
                                FontAwesomeIcons.arrowLeft,
                                color: canvasColor,
                              ),
                            ),
                          )
                      : Container(),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      titleLeftSide,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: canvasColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // right side of the app bar
          Expanded(
            flex: 5,
            child: Container(
              color: canvasColor,
              height: kToolbarHeight,
              child: Row(
                children: [
                  paymentNotifier.getCurrentPaymentNavigator !=
                              PaymentNavigatorEnum.paymentScreen &&
                          (paymentNotifier.getCurrentPaymentNavigator !=
                                  PaymentNavigatorEnum.saleSummary &&
                              splitPaymentState.saleItems.isEmpty)
                      ? Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () {
                            onTapBackFromSplit(
                              context,
                              paymentNotifier,
                              saleItemsNotifier,
                              saleItemsState,
                            );
                          },
                          child: Container(
                            height: kToolbarHeight,
                            padding: const EdgeInsets.all(8),
                            color: darkCanvasColor,
                            child: const Icon(
                              FontAwesomeIcons.arrowLeft,
                              color: kWhiteColor,
                            ),
                          ),
                        ),
                      )
                      : Container(),
                  Expanded(
                    flex: 11,
                    child: Text(
                      titleRightSide,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kWhiteColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onTapBackFromSplit(
    BuildContext context,
    PaymentNotifier paymentNotifier,
    SaleItemNotifier saleItemsNotifier,
    SaleItemState saleItemsState,
  ) {
    saleItemsNotifier.setIsSplitPayment(false);
    // set can go back to sales page or cancel this ticket
    saleItemsNotifier.setCanBackToSalesPage(true);
    paymentNotifier.setNewPaymentNavigator(PaymentNavigatorEnum.paymentScreen);
  }

  void onPressBackToSalesScreen(
    BuildContext context,
    SaleItemNotifier saleItemsNotifier,
    WidgetRef ref,
  ) {
    // Cancel all pending payment operations to prevent UI blocking during navigation
    _cancelPaymentOperationsForNavigation();

    // back  to sales page
    NavigationUtils.pop(context);
    ref.read(paymentProvider.notifier).setChangeToPaymentScreen(false);
    // set is split payment to false
    saleItemsNotifier.setIsSplitPayment(false);
  }

  /// Cancel all payment operations that could block navigation
  void _cancelPaymentOperationsForNavigation() {
    try {
      // Import PaymentDetails class to access its static methods
      // Cancel any pending second display updates
      PaymentDetails.cancelPendingSecondDisplayUpdates();

      // Clear initialization queue to prevent blocking operations
      PaymentDetails.clearInitializationQueue();

      // Mark that we're navigating away to prevent new operations
      PaymentDetails.setNavigatingAway(true);

      prints('🚫 Cancelled payment operations for smooth navigation');
    } catch (e) {
      prints('⚠️ Error cancelling payment operations: $e');
      // Continue with navigation even if cancellation fails
    }
  }
}
