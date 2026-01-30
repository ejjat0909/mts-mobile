import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/home_receipt_navigator_enum.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/refund/refund_providers.dart';

class CustomAppBarReceipt extends ConsumerWidget
    implements PreferredSizeWidget {
  final String titleLeftSide;
  final String titleRightSide;
  final Function() leftSidePress;

  const CustomAppBarReceipt({
    super.key,
    required this.titleLeftSide,
    required this.titleRightSide,
    required this.leftSidePress,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptState = ref.watch(receiptProvider);
    final receiptNotifier = ref.watch(receiptProvider.notifier);
    final refundNotifier = ref.watch(refundProvider.notifier);
    final navigator = receiptState.pageIndex;
    return AppBar(
      automaticallyImplyLeading: false,
      // Disable the default leading icon
      backgroundColor:
          navigator == HomeReceiptNavigatorEnum.receiptDetails
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
                  SizedBox(
                    width:
                        navigator == HomeReceiptNavigatorEnum.receiptRefund
                            ? 0
                            : 15,
                  ),
                  navigator == HomeReceiptNavigatorEnum.receiptRefund
                      ? Container()
                      : IconButton(
                        icon: const Icon(
                          FontAwesomeIcons.bars,
                          color: canvasColor,
                        ),
                        onPressed: leftSidePress,
                      ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      titleLeftSide,
                      textAlign: TextAlign.left,
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
                  receiptState.pageIndex !=
                          HomeReceiptNavigatorEnum.receiptDetails
                      ? Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () {
                            receiptNotifier.setPageIndex(
                              HomeReceiptNavigatorEnum.receiptDetails,
                            );

                            receiptNotifier.clearAll();
                            refundNotifier.clearAll();
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
}
