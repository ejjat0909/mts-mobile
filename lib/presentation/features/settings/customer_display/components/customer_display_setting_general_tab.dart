import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/db_response_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/core/services/secondary_display_service.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/form_bloc/customer_display_form_bloc.dart';
import 'package:mts/main.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/button_bottom.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/customer_display_preview/main_customer_display.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/second_display/second_display_providers.dart';

class CustomerDisplaySettingGeneralTab extends ConsumerStatefulWidget {
  const CustomerDisplaySettingGeneralTab({super.key});

  @override
  ConsumerState<CustomerDisplaySettingGeneralTab> createState() =>
      _CustomerDisplaySettingGeneralTabState();
}

class _CustomerDisplaySettingGeneralTabState
    extends ConsumerState<CustomerDisplaySettingGeneralTab> {
  final SecondaryDisplayService _showSecondaryDisplayFacade =
      ServiceLocator.get<SecondaryDisplayService>();
  bool hasPermissionSettings = true;
  @override
  void initState() {
    // displayManager.connectedDisplaysChangedStream?.listen(
    //   (event) {
    //     prints("connected displays changed: $event");
    //   },
    // );

    super.initState();
  }

  Future<SlideshowModel> getData() async {
    Map<String, dynamic> response =
        await ref.read(slideshowProvider.notifier).getLatestModel();

    if (response[DbResponseEnum.isSuccess]) {
      return response[DbResponseEnum.data];
    } else {
      return SlideshowModel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    hasPermissionSettings = permissionNotifier.hasChangeSettingsPermission();
    return FutureBuilder(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return Center(child: ThemeSpinner.spinner());
        }

        SlideshowModel sdModel = snapshot.data!;
        if (sdModel.id == null) {
          return Center(child: Text('No Data Found'));
        }
        // if (sdModel.id != null && sdModel.outletId != null)
        return BlocProvider(
          create: (context) {
            return CustomerDisplayFormBloc(
              snapshot.data!,
              ref.read(slideshowProvider.notifier),
            );
          },
          child: Builder(
            builder: ((context) {
              final customerDisplayFormBloc =
                  context.read<CustomerDisplayFormBloc>();

              return FormBlocListener<
                CustomerDisplayFormBloc,
                Map<String, dynamic>,
                String
              >(
                onSubmitting: (context, state) {
                  FocusScope.of(context).unfocus();
                },
                onSuccess: (context, state) async {
                  // dont clear the form
                  Map<String, dynamic> data = state.successResponse!;
                  String message = data['message'];
                  SlideshowModel sdModel = data['data'] as SlideshowModel;
                  context.read<SecondDisplayNotifier>().setCurrSdModel(sdModel);
                  ThemeSnackBar.showSnackBar(context, message);
                  setState(() {});
                },
                onFailure: (context, state) {
                  ThemeSnackBar.showSnackBar(context, state.failureResponse!);
                },
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            MyTextFieldBlocBuilder(
                              isEnabled: true,
                              textFieldBloc: customerDisplayFormBloc.title,
                              labelText: 'title'.tr(),
                              hintText: 'ex: Cafe XYZ',
                            ),
                            MyTextFieldBlocBuilder(
                              isEnabled: true,
                              textFieldBloc:
                                  customerDisplayFormBloc.description,
                              labelText: 'description'.tr(),
                              hintText: 'ex: We provide delicious food',
                            ),
                            MyTextFieldBlocBuilder(
                              isEnabled: true,
                              textFieldBloc: customerDisplayFormBloc.greeting,
                              labelText: 'greeting'.tr(),
                              hintText: 'ex: Nice to meet you',
                            ),
                            MyTextFieldBlocBuilder(
                              isEnabled: true,
                              textFieldBloc:
                                  customerDisplayFormBloc.feedbackDescription,
                              labelText: 'feedbackDescription'.tr(),
                              hintText: 'ex: We look foward',
                            ),
                            MyTextFieldBlocBuilder(
                              isEnabled: true,
                              textFieldBloc:
                                  customerDisplayFormBloc.promotionLink,
                              labelText: 'promotionLink'.tr(),
                              hintText: 'ex: Visit us at www.mts.com',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Expanded(
                          //   child: ButtonBottom(
                          //     "Show 2nd screen",
                          //     press: () async {
                          //       await SecondaryDisplayBloc.navigateSecondScreen(
                          //         context,
                          //         MainCustomerDisplay.routeName,
                          //       );
                          //     },
                          //   ),
                          // ),
                          // SizedBox(width: 10.w),
                          Expanded(
                            flex: 3,
                            child: ButtonTertiary(
                              text: 'showWelcomeDisplay'.tr(),
                              onPressed: () async {
                                if (sdModel.id == null) {
                                  checkingBloc(customerDisplayFormBloc);
                                  ThemeSnackBar.showSnackBar(
                                    context,
                                    'pleaseFillInTheForm'.tr(),
                                  );
                                  return;
                                }

                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );

                                SlideshowModel? sdm = await ref
                                    .read(slideshowProvider.notifier)
                                    .getModelById(sdModel.id ?? '');
                                // SlideshowModel sdModelL = SlideshowModel(
                                //   id: "01jsk2xzg94hb5rwahxsrez2e0",
                                //   title: "DSDSDSDSDSDSDSDSDSDSD",
                                //   outletId: null,
                                //   description: "hgfhgdgfd",
                                //   greetings: "bfcbfcbfd",
                                //   feedbackDescription: "bfcbfcbfc",
                                //   promotionlink: "gfdgfcbfdbfc",
                                //   createdAt: DateTime.now(),
                                //   updatedAt: DateTime.now(),
                                // );
                                Map<String, dynamic> dataWelcome = {};
                                dataWelcome.addEntries([
                                  MapEntry(DataEnum.slideshow, sdm.toJson()),
                                ]);

                                // Stop the secondary display

                                // If stopping failed, we can try to navigate to a new screen
                                // This code is currently unreachable due to the return statement above
                                // Keeping it commented for future reference

                                await _showSecondaryDisplayFacade
                                    .navigateSecondScreen(
                                      MainCustomerDisplay.routeName,
                                      displayManager,
                                      data: dataWelcome,
                                    );

                                // Navigator.push(
                                //   context,
                                //   CupertinoPageRoute(
                                //     builder: (context) {
                                //       return const MainCustomerDisplay();
                                //     },
                                //   ),
                                // );
                              },
                            ),
                          ),
                          10.widthBox,
                          Expanded(
                            flex: 1,
                            child: ButtonBottom(
                              'save'.tr(),
                              press: () async {
                                await onPressSave(
                                  customerDisplayFormBloc,
                                  hasPermissionSettings,
                                );
                              },
                            ),
                          ),
                          // Expanded(
                          //   child: ButtonBottom(
                          //     " Receipt",
                          //     press: () async {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) =>
                          //               const MainCustomerDisplay(),
                          //         ),
                          //       );
                          //     },
                          //   ),
                          // ),
                          // SizedBox(width: 10.w),
                          // Expanded(
                          //   child: ButtonBottom(
                          //     "Show Display Feedback",
                          //     press: () async {
                          //       await SecondaryDisplayBloc.navigateSecondScreen(
                          //         context,
                          //         CustomerFeedback.routeName,
                          //         displayManager,
                          //       );

                          //       // Navigator.push(
                          //       //   context,
                          //       //   MaterialPageRoute(
                          //       //     builder: (context) => const CustomerFeedback(),
                          //       //   ),
                          //       // );
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> onPressSave(
    CustomerDisplayFormBloc customerDisplayFormBloc,
    bool hasSettingPermission,
  ) async {
    if (!hasSettingPermission) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.CHANGE_SETTINGS,
        onSuccess: () async {
          customerDisplayFormBloc.submit();
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
    }

    if (hasSettingPermission) {
      customerDisplayFormBloc.submit();
    }
  }

  void checkingBloc(CustomerDisplayFormBloc customerDisplayFormBloc) {
    if (customerDisplayFormBloc.title.value.isEmpty) {
      customerDisplayFormBloc.title.addFieldError('thisFieldIsRequired'.tr());
    }
    if (customerDisplayFormBloc.description.value.isEmpty) {
      customerDisplayFormBloc.description.addFieldError(
        'thisFieldIsRequired'.tr(),
      );
    }
    if (customerDisplayFormBloc.greeting.value.isEmpty) {
      customerDisplayFormBloc.greeting.addFieldError(
        'thisFieldIsRequired'.tr(),
      );
    }
    if (customerDisplayFormBloc.feedbackDescription.value.isEmpty) {
      customerDisplayFormBloc.feedbackDescription.addFieldError(
        'thisFieldIsRequired'.tr(),
      );
    }
    if (customerDisplayFormBloc.promotionLink.value.isEmpty) {
      customerDisplayFormBloc.promotionLink.addFieldError(
        'thisFieldIsRequired'.tr(),
      );
    }
  }
}
