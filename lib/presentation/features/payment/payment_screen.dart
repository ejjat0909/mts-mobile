import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/payment_navigator_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';
import 'package:mts/presentation/features/home/home_screen.dart';
import 'package:mts/presentation/features/payment/components/app_bar_payment.dart';
import 'package:mts/presentation/features/payment/components/body.dart';
import 'package:mts/providers/payment/payment_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final BuildContext orderListContext;
  const PaymentScreen({super.key, required this.orderListContext});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  // Secondary display handled via secondDisplayProvider.notifier
  final UserModel userModel = ServiceLocator.get<UserModel>();
  @override
  void initState() {
    super.initState();

    // Ensure slideshow cache is available for consistent data across all screens
    // _ensureSlideshowCacheAvailable();

    // // only triggered when press charged from order list sales
    // // not triggered if user press split button from split payment details
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   final saleItemsNotifier = ref.read(saleItemsProvider.notifier);
    //   await Future.delayed(const Duration(milliseconds: 1000));
    //   getDataToTransferToSecondScreen(saleItemsNotifier);
    // });
  }

  /// Ensure slideshow cache is available for consistent data across all screens
  void _ensureSlideshowCacheAvailable() {
    // Use Future.microtask to avoid blocking initState
    Future.microtask(() async {
      if (!Home.isSlideshowCacheInitialized()) {
        prints(
          '🔄 Initializing slideshow cache from payment screen for consistency',
        );
        await Home.ensureSlideshowCacheInitialized();
      } else {
        prints('✅ Slideshow cache already available for payment screen');
      }
    });
  }

  Future<void> getDataToTransferToSecondScreen(
    SaleItemNotifier saleItemsNotifier,
  ) async {
    // Use cached slideshow model from home_screen.dart to avoid DB calls and ensure consistency
    SlideshowModel? currSdModel = Home.getCachedSlideshowModel();

    // If cache is not available, fallback to DB call (should be rare)
    if (currSdModel == null) {
      prints(
        '⚠️ Slideshow cache not available in payment screen, falling back to DB call',
      );
      final Map<String, dynamic> slideshowMap =
          await ref.read(slideshowProvider.notifier).getLatestModel();
      currSdModel = slideshowMap[DbResponseEnum.data];
    } else {
      prints(
        '✅ Using cached slideshow model in payment screen for consistency',
      );
    }

    final Map<String, dynamic> dataToTransfer =
        saleItemsNotifier.getMapDataToTransfer();
    dataToTransfer.addEntries([
      MapEntry(DataEnum.userModel, userModel.toJson()),
      MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
      const MapEntry(DataEnum.showThankYou, false),
      const MapEntry(DataEnum.isCharged, true),
    ]);

    /// [SHOW SECOND SCREEN: CUSTOMER SHOW RECEIPT SCREEN]
    await ref
        .read(secondDisplayProvider.notifier)
        .navigateSecondScreen(
          CustomerShowReceipt.routeName,
          data: dataToTransfer,
        );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final titleRightSide = paymentState.appBarTitle;
    final paymentNavigator = paymentState.paymentNavigator;
    return PopScope(
      canPop: false, // Prevent automatic back navigation

      child: Scaffold(
        resizeToAvoidBottomInset: false, // make the widgets behind the keyboard
        backgroundColor:
            paymentNavigator == PaymentNavigatorEnum.paymentScreen
                ? white
                : null,
        appBar: AppBarPayment(
          titleLeftSide: 'order'.tr(),
          titleRightSide: titleRightSide,
        ),
        body: Body(orderListContext: widget.orderListContext),
      ),
    );
  }
}
