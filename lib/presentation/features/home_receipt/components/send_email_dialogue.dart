import 'package:easy_localization/easy_localization.dart';
import 'package:fluid_dialog/fluid_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/core/utils/network_utils.dart';
import 'package:mts/data/models/default_response_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/form_bloc/send_email_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/widgets/button_primary.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';

import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';

class SendEmailDialogue extends ConsumerStatefulWidget {
  final bool isFluidDialogue;
  final Function(DefaultResponseModel response) onSuccess;
  final Function(String message) onError;

  const SendEmailDialogue({
    super.key,
    required this.isFluidDialogue,
    required this.onSuccess,
    required this.onError,
  });

  @override
  ConsumerState<SendEmailDialogue> createState() => _SendEmailDialogueState();
}

class _SendEmailDialogueState extends ConsumerState<SendEmailDialogue> {
  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    final receiptState = ref.watch(receiptProvider);
    final rm = receiptState.tempReceiptModel;

    if (kDebugMode && rm != null) {
      prints('TEMP RECEIPT MODEL ${rm.id}');
    }
    if (widget.isFluidDialogue) {
      return fluidDialogue(availableWidth, rm);
    } else {
      return notFluidDialogue(availableWidth, availableHeight, rm);
    }
  }

  Widget notFluidDialogue(
    double availableWidth,
    double availableHeight,
    ReceiptModel? rm,
  ) {
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
              (context) => SendEmailFormBloc(
                receiptId: rm?.id,
                receiptNotifier: ref.read(receiptProvider.notifier),
                receiptItemNotifier: ref.read(receiptItemProvider.notifier),
              ),
          child: Builder(
            builder: (context) {
              final sendEmailFormBloc = BlocProvider.of<SendEmailFormBloc>(
                context,
              );
              return FormBlocListener<
                SendEmailFormBloc,
                DefaultResponseModel,
                String
              >(
                onSubmitting: (context, state) {
                  LoadingDialog.show(context);
                },
                onSuccess: (context, state) {
                  NavigationUtils.pop(context);
                  ref
                      .read(dialogNavigatorProvider.notifier)
                      .setPageIndex(DialogNavigatorEnum.reset);
                  widget.onSuccess(state.successResponse!);
                },
                onFailure: (context, state) {
                  NavigationUtils.pop(context);
                  widget.onError(state.failureResponse ?? '');
                },
                onSubmissionFailed: (context, state) {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Space(10),
                    AppBar(
                      elevation: 0,
                      backgroundColor: white,
                      // title: Text(
                      //   'sendReceiptToEmail'.tr(),
                      //   style: AppTheme.h1TextStyle(),
                      automaticallyImplyLeading: false,
                      title: Row(
                        children: [
                          Text(
                            'sendReceiptToEmail'.tr(),
                            style: AppTheme.h1TextStyle(),
                          ),
                          const Expanded(flex: 2, child: SizedBox()),
                          IconButton(
                            icon: const Icon(Icons.close, color: canvasColor),
                            onPressed: () {
                              NavigationUtils.pop(context);
                              ref
                                  .read(dialogNavigatorProvider.notifier)
                                  .setPageIndex(DialogNavigatorEnum.reset);
                            },
                          ),
                        ],
                      ),
                      // back button

                      // leading: IconButton(
                      //   icon: const Icon(
                      //     Icons.arrow_back,
                      //     color: canvasColor,
                      //   ),
                      //   onPressed: () {
                      //     DialogNavigator.of(context).pop();
                      //   },
                      // ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: MyTextFieldBlocBuilder(
                                  keyboardType: TextInputType.emailAddress,
                                  textFieldBloc: sendEmailFormBloc.email,
                                  labelText: 'email'.tr(),
                                  hintText: 'ex: human@example.com',
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(''),
                                    ButtonPrimary(
                                      text: 'send'.tr(),
                                      icon: FontAwesomeIcons.paperPlane,
                                      onPressed: () async {
                                        if (await NetworkUtils.hasInternetConnection()) {
                                          sendEmailFormBloc.submit();
                                        } else {
                                          if (mounted) {
                                            NetworkUtils.noInternetDialog(
                                              context,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Space(10),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget fluidDialogue(double availableWidth, ReceiptModel? rm) {
    return SizedBox(
      width: availableWidth / 2,
      child: BlocProvider(
        create:
            (context) => SendEmailFormBloc(
              receiptId: rm?.id,
              receiptNotifier: ref.read(receiptProvider.notifier),
              receiptItemNotifier: ref.read(receiptItemProvider.notifier),
            ),
        child: Builder(
          builder: (context) {
            final sendEmailFormBloc = BlocProvider.of<SendEmailFormBloc>(
              context,
            );
            final FocusNode emailFocusNode = FocusNode();
            return FormBlocListener<
              SendEmailFormBloc,
              DefaultResponseModel,
              String
            >(
              onSubmitting: (context, state) {},
              onSuccess: (context, state) {
                NavigationUtils.pop(context);
                ref
                    .read(dialogNavigatorProvider.notifier)
                    .setPageIndex(DialogNavigatorEnum.reset);
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
                          'sendReceiptToEmail'.tr(),
                          style: AppTheme.h1TextStyle(),
                        ),
                        const Expanded(flex: 2, child: SizedBox()),
                        IconButton(
                          icon: const Icon(Icons.close, color: canvasColor),
                          onPressed: () {
                            NavigationUtils.pop(context);
                            ref
                                .read(dialogNavigatorProvider.notifier)
                                .setPageIndex(DialogNavigatorEnum.reset);
                          },
                        ),
                      ],
                    ),
                    // back button
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: canvasColor),
                      onPressed: () {
                        if (FocusScope.of(context).hasFocus) {
                          FocusScope.of(context).unfocus();
                        } else {
                          DialogNavigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MyTextFieldBlocBuilder(
                                focusNode: emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textFieldBloc: sendEmailFormBloc.email,
                                labelText: 'email'.tr(),
                                hintText: 'ex: human@example.com',
                                onTap: () {
                                  emailFocusNode.requestFocus();
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Column(
                              children: [
                                const Text(''),
                                ButtonTertiary(
                                  text: 'send'.tr(),
                                  icon: FontAwesomeIcons.paperPlane,
                                  onPressed: () {
                                    sendEmailFormBloc.submit();
                                  },
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
