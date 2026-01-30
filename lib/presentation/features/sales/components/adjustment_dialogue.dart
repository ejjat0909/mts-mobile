import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';
import 'package:mts/form_bloc/discount_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/mixins/barcode_scanner_aware_mixin.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display_show_receipt.dart';

import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/split_payment/split_payment_providers.dart';

class AdjustmentDialogue extends ConsumerStatefulWidget {
  const AdjustmentDialogue({super.key});

  @override
  ConsumerState<AdjustmentDialogue> createState() => _AdjustmentDialogueState();
}

class _AdjustmentDialogueState extends ConsumerState<AdjustmentDialogue>
    with BarcodeScannerAwareMixin {
  UserModel userModel = GetIt.instance<UserModel>();
  // Secondary display handled via secondDisplayProvider.notifier
  @override
  void initState() {
    super.initState();
    initScannerAware();
  }

  @override
  void dispose() {
    disposeScannerAware();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsState = ref.watch(saleItemProvider);
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);

    bool isSplit = saleItemsState.isSplitPayment;
    double totalAmountRemaining = saleItemsState.totalAmountRemaining;
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight / 2,
          maxWidth: availableWidth / 2,
        ),
        child: BlocProvider(
          create:
              (context) =>
                  DiscountFormBloc(context, isSplit, totalAmountRemaining),
          child: Builder(
            builder: (context) {
              final discountFormBloc = BlocProvider.of<DiscountFormBloc>(
                context,
              );

              return FormBlocListener<DiscountFormBloc, String, String>(
                onSubmitting: (context, state) {},
                onSuccess: (context, state) async {
                  await onSuccessSetAdjustment(
                    context,
                    state,
                    isSplit,
                    discountFormBloc,
                    saleItemsNotifier,
                    ref,
                  );
                },
                onFailure: (context, state) {},
                onSubmissionFailed: (context, state) {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Space(10),
                    AppBar(
                      elevation: 0,
                      backgroundColor: white,
                      title: Row(
                        children: [
                          Text(
                            'adjustments'.tr(),
                            style: AppTheme.h1TextStyle(),
                          ),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 1,
                            child: ButtonTertiary(
                              text: 'save'.tr(),
                              icon: FontAwesomeIcons.download,
                              onPressed: () async {
                                await Future.delayed(
                                  const Duration(milliseconds: 200),
                                );
                                discountFormBloc.submit();
                              },
                            ),
                          ),
                        ],
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: canvasColor),
                        onPressed: () {
                          NavigationUtils.pop(context);
                          ref
                              .read(dialogNavigatorProvider.notifier)
                              .setPageIndex(DialogNavigatorEnum.reset);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          MyTextFieldBlocBuilder(
                            keyboardType: TextInputType.number,
                            textFieldBloc: discountFormBloc.discount,
                            labelText: 'discount'.tr(),
                            hintText: '1.20',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> onSuccessSetAdjustment(
    BuildContext context,
    FormBlocSuccess<String, String> state,
    bool isSplit,
    DiscountFormBloc discountFormBloc,
    SaleItemNotifier saleItemsNotifier,
    WidgetRef ref,
  ) async {
    final splitPaymentNotifier = ref.read(splitPaymentProvider.notifier);
    discountFormBloc.discount.clear();
    NavigationUtils.pop(context);
    await Future.delayed(const Duration(milliseconds: 500));
    ref
        .read(dialogNavigatorProvider.notifier)
        .setPageIndex(DialogNavigatorEnum.reset);

    double adjustedPrice = double.tryParse(state.successResponse ?? '0') ?? 0;
    if (isSplit) {
      splitPaymentNotifier.setAdjustedPrice(adjustedPrice);
    } else {
      saleItemsNotifier.setAdjustedPrice(adjustedPrice);
    }
    saleItemsNotifier.reCalculateAllTotal(null, null);

    /// [SHOW SECOND DISPLAY]

    SlideshowModel? currSdModel = await getSlideShowModel();

    Map<String, dynamic> data = saleItemsNotifier.getMapDataToTransfer();
    data.addEntries([
      MapEntry(DataEnum.userModel, userModel.toJson()),
      MapEntry(DataEnum.slideshow, currSdModel?.toJson() ?? {}),
      const MapEntry(DataEnum.showThankYou, false),
      const MapEntry(DataEnum.isCharged, false),
    ]);

    await ref
        .read(secondDisplayProvider.notifier)
        .navigateSecondScreen(
          CustomerShowReceipt.routeName,
          data: data,
          isShowLoading: true,
        );
  }

  Future<SlideshowModel?> getSlideShowModel() async {
    final slideshowNotifier = ref.read(slideshowProvider.notifier);
    final Map<String, dynamic> slideshowMap =
        await slideshowNotifier.getLatestModel();

    final SlideshowModel? currSdModel = slideshowMap[DbResponseEnum.data];
    return currSdModel;
  }
}
