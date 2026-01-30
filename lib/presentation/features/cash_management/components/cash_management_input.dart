import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/cash_management_type_enum.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/form_bloc/cash_management_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class CashManagementInput extends ConsumerStatefulWidget {
  final Function(List<CashManagementModel>) onRefreshListCMM;

  const CashManagementInput({super.key, required this.onRefreshListCMM});

  @override
  ConsumerState<CashManagementInput> createState() =>
      _CashManagementInputState();
}

class _CashManagementInputState extends ConsumerState<CashManagementInput> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 5,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            top: 50,
            left: 100,
            right: 100,
            bottom: 300,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(10.sp),
          ),
          child: input(),
        ),
      ),
    );
  }

  BlocProvider<CashManagementFormBloc> input() {
    return BlocProvider(
      create:
          (context) => CashManagementFormBloc(ref.read(shiftProvider.notifier)),
      child: Builder(
        builder: (context) {
          final cashManagementFormBloc = context.read<CashManagementFormBloc>();
          return FormBlocListener<
            CashManagementFormBloc,
            Map<String, dynamic>,
            String
          >(
            onSubmitting: (context, state) async {
              final cashManagementFormBloc =
                  context.read<CashManagementFormBloc>();
              String type = cashManagementFormBloc.type.value;
              if (cashManagementFormBloc.amount.value != '') {
                await ref
                    .read(printerSettingProvider.notifier)
                    .openCashDrawerManually(
                      (errorMessage) {
                        ThemeSnackBar.showSnackBar(context, errorMessage);
                      },
                      activityFrom:
                          "Cash Management - ${type.isNotEmpty ? type : 'Unknown'}",
                    );
              }
            },
            onSuccess: (context, state) async {
              Map<String, dynamic> dataSuccess = state.successResponse!;
              cashManagementFormBloc.clear();
              await handleOnSuccess(dataSuccess, context);
            },
            onFailure: (context, state) {},
            onSubmissionFailed: (context, state) {},
            child: Column(
              children: [
                MyTextFieldBlocBuilder(
                  textFieldBloc: cashManagementFormBloc.amount,
                  keyboardType: TextInputType.number,
                  labelText: 'amount'.tr(),
                  leading: Padding(
                    padding: EdgeInsets.only(
                      top: 20.h,
                      left: 10.w,
                      right: 10.w,
                      bottom: 20.h,
                    ),
                    child: Text(
                      'RM'.tr(args: ['']),
                      style: AppTheme.mediumTextStyle(color: canvasColor),
                    ),
                  ),
                  hintText: '0.00',
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {},
                ),
                MyTextFieldBlocBuilder(
                  textFieldBloc: cashManagementFormBloc.comment,
                  keyboardType: TextInputType.name,
                  labelText: 'comment'.tr(),
                  hintText: 'comment'.tr(),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {},
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: ButtonBottom(
                        'payIn'.tr(),
                        press: () {
                          cashManagementFormBloc.type.updateValue(
                            CashManagementTypeEnum.payIn.toString(),
                          );
                          cashManagementFormBloc.submit();
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ButtonTertiary(
                        text: 'payOut'.tr(),
                        onPressed: () {
                          cashManagementFormBloc.type.updateValue(
                            CashManagementTypeEnum.payOut.toString(),
                          );
                          cashManagementFormBloc.submit();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> handleOnSuccess(
    Map<String, dynamic> dataSuccess,
    BuildContext handleContext,
  ) async {
    CashManagementModel cmm =
        dataSuccess['cashManagementModel'] as CashManagementModel;
    ShiftModel sm = dataSuccess['shiftModel'] as ShiftModel;
    LoadingDialog.show(handleContext);

    // Use providers instead of facades
    final cashManagementNotifier = ref.read(cashManagementProvider.notifier);
    final shiftNotifier = ref.read(shiftProvider.notifier);

    int result = await cashManagementNotifier.insert(cmm);
    if (result != 0) {
      await shiftNotifier.update(sm);
      LoadingDialog.hide(handleContext);
      ThemeSnackBar.showSnackBar(context, 'successUpdateCashManagement'.tr());
    } else {
      LoadingDialog.hide(handleContext);
      ThemeSnackBar.showSnackBar(context, 'failToUpdateCashManagement'.tr());
    }

    // Get list of cash management models using provider
    List<CashManagementModel> listCMM =
        await cashManagementNotifier.getListCashManagementModel();
    widget.onRefreshListCMM(listCMM);
  }
}
