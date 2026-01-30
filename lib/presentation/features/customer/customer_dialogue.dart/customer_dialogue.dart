import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/form_bloc/add_customer_form_bloc.dart';
import 'package:mts/form_bloc/edit_customer_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/customer/customer_dialogue.dart/add_customer_body.dart';
import 'package:mts/presentation/features/customer/customer_dialogue.dart/edit_customer_body.dart';
import 'package:mts/presentation/features/customer/customer_dialogue.dart/list_customer_body.dart';
import 'package:mts/presentation/features/customer/customer_dialogue.dart/view_customer_body.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';

class CustomerDialogue extends ConsumerStatefulWidget {
  const CustomerDialogue({super.key});

  @override
  ConsumerState<CustomerDialogue> createState() => _CustomerDialogueState();
}

class _CustomerDialogueState extends ConsumerState<CustomerDialogue> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;

    final page = ref.watch(dialogNavigatorProvider).pageIndex;
    final customerNotifier = ref.read(customerProvider.notifier);

    return FractionallySizedBox(
      heightFactor: 1,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: availableHeight,
            minHeight: availableHeight,
            maxWidth: availableWidth / 1.5,
            minWidth: availableWidth / 1.5,
          ),
          child: Builder(
            builder: (context) {
              final addCustomerFormBloc = BlocProvider.of<AddCustomerFormBloc>(
                context,
              );

              return FormBlocListener<
                AddCustomerFormBloc,
                CustomerModel,
                String
              >(
                onSubmitting: (context, state) {},
                onSuccess: (context, state) {
                  addCustomerFormBloc.clear();
                  final newCustomerModel = state.successResponse;
                  // navigate to view customer
                  ref
                      .read(dialogNavigatorProvider.notifier)
                      .setPageIndex(DialogNavigatorEnum.viewCustomer);
                  ref
                      .read(customerProvider.notifier)
                      .setCurrentCustomerModel(newCustomerModel);
                },
                onFailure: (context, state) {
                  ThemeSnackBar.showSnackBar(context, "Something went wrong");
                },
                onSubmissionFailed: (context, state) {
                  ThemeSnackBar.showSnackBar(context, "Submit failed");
                },
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Space(10),
                    AppBar(
                      elevation: 0,
                      backgroundColor: white,
                      title: Row(
                        children: [
                          getTitle(page),
                          Expanded(
                            flex:
                                page == DialogNavigatorEnum.viewCustomer
                                    ? 1
                                    : 2,
                            child: const SizedBox(),
                          ),
                          getTrailingButton(
                            context,
                            page,
                            addCustomerFormBloc,
                            customerNotifier,
                          ),
                          page == DialogNavigatorEnum.viewCustomer
                              ? editProfileButton()
                              : Container(),
                        ],
                      ),
                      leading: getIconLeading(
                        context,
                        page,
                        addCustomerFormBloc,
                        customerNotifier,
                      ),
                    ),
                    getBody(
                      page,
                      addCustomerFormBloc,
                      customerNotifier,
                      context,
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

  Widget editProfileButton() {
    return ScaleTap(
      onPressed: () {
        ref
            .read(dialogNavigatorProvider.notifier)
            .setPageIndex(DialogNavigatorEnum.editCustomer);
      },
      child: Tooltip(
        message: 'editProfile'.tr(),
        child: Container(
          margin: EdgeInsets.only(left: 10.w),
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(FontAwesomeIcons.pencil, color: white, size: 20),
        ),
      ),
    );
  }

  Text getTitle(int page) {
    if (page == DialogNavigatorEnum.viewCustomer) {
      return Text('customerProfile'.tr(), style: AppTheme.h1TextStyle());
    } else if (page == DialogNavigatorEnum.editCustomer) {
      return Text('editProfile'.tr(), style: AppTheme.h1TextStyle());
    }
    return Text('addCustomerToOrder'.tr(), style: AppTheme.h1TextStyle());
  }

  Widget getTrailingButton(
    BuildContext context,
    int page,
    AddCustomerFormBloc addCustomerFormBloc,
    CustomerNotifier customerNotifier,
  ) {
    if (page == DialogNavigatorEnum.listCustomer) {
      return Expanded(
        flex: 2,
        child: ButtonTertiary(
          icon: FontAwesomeIcons.userPlus,
          text: 'add'.tr(),
          onPressed: () {
            ref
                .read(dialogNavigatorProvider.notifier)
                .setPageIndex(DialogNavigatorEnum.addCustomer);
          },
        ),
      );
    } else if (page == DialogNavigatorEnum.addCustomer ||
        page == DialogNavigatorEnum.editCustomer) {
      return Expanded(
        flex: 1,
        child: ButtonTertiary(
          icon: FontAwesomeIcons.download,
          text: 'save'.tr(),
          onPressed: () {
            if (page == DialogNavigatorEnum.addCustomer) {
              addCustomerFormBloc.submit();
            } else if (page == DialogNavigatorEnum.editCustomer) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final editCustomerFormBloc =
                    customerNotifier.getEditCustomerFormBloc;

                if (editCustomerFormBloc != null) {
                  editCustomerFormBloc.submit();
                } else {
                  prints('edit customer form bloc is null');
                }
              });
            }
          },
        ),
      );
    } else if (page == DialogNavigatorEnum.viewCustomer) {
      CustomerModel? orderCustomerModel =
          customerNotifier.getOrderCustomerModel;
      return Expanded(
        flex: 1,
        child: ButtonTertiary(
          icon: FontAwesomeIcons.fileCirclePlus,
          text:
              orderCustomerModel == null
                  ? 'addToOrder'.tr()
                  : 'removeFromOrder'.tr(),
          onPressed: () async {
            CustomerModel currentCustomerModel =
                customerNotifier.getCurrentCustomerModel!;
            ref
                .read(dialogNavigatorProvider.notifier)
                .setPageIndex(DialogNavigatorEnum.listCustomer);
            addCustomerFormBloc.clear();
            if (orderCustomerModel == null) {
              // add customer to order or ticket
              final updateCustomer = currentCustomerModel.copyWith(
                updatedAt: DateTime.now(),
              );
              customerNotifier.setOrderCustomerModel(updateCustomer);
              NavigationUtils.pop(context);
              await ref.read(customerProvider.notifier).update(updateCustomer);
            } else {
              customerNotifier.setOrderCustomerModel(null);
              NavigationUtils.pop(context);
              final updateCustomer = currentCustomerModel.copyWith(
                updatedAt: DateTime.now(),
              );
              await ref.read(customerProvider.notifier).update(updateCustomer);
            }
          },
        ),
      );
    } else {
      return Container();
    }
  }

  IconButton getIconLeading(
    BuildContext context,
    int page,
    AddCustomerFormBloc addCustomerFormBloc,
    CustomerNotifier customerNotifier,
  ) {
    CustomerModel? orderCustomerModel = customerNotifier.getOrderCustomerModel;
    if (page == DialogNavigatorEnum.listCustomer) {
      return IconButton(
        icon: const Icon(Icons.close, color: canvasColor),
        onPressed: () {
          ref
              .read(dialogNavigatorProvider.notifier)
              .setPageIndex(DialogNavigatorEnum.reset);
          addCustomerFormBloc.clear();
          Navigator.of(context).pop();
        },
      );
    } else if (page == DialogNavigatorEnum.addCustomer ||
        page == DialogNavigatorEnum.viewCustomer ||
        page == DialogNavigatorEnum.editCustomer) {
      return IconButton(
        icon: Icon(
          orderCustomerModel != null && page == DialogNavigatorEnum.viewCustomer
              ? Icons.close
              : Icons.arrow_back,
          color: canvasColor,
        ),
        onPressed: () {
          if (page == DialogNavigatorEnum.editCustomer) {
            prints('masuk sini');
            ref
                .read(dialogNavigatorProvider.notifier)
                .setPageIndex(DialogNavigatorEnum.viewCustomer);
          } else if (page == DialogNavigatorEnum.addCustomer ||
              page == DialogNavigatorEnum.viewCustomer) {
            // for add and view customer
            if (orderCustomerModel != null) {
              ref
                  .read(dialogNavigatorProvider.notifier)
                  .setPageIndex(DialogNavigatorEnum.reset);
              addCustomerFormBloc.clear();
              Navigator.of(context).pop();
            } else {
              ref
                  .read(dialogNavigatorProvider.notifier)
                  .setPageIndex(DialogNavigatorEnum.listCustomer);
              addCustomerFormBloc.clear();
            }
          }
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.close, color: canvasColor),
        onPressed: () {
          ref
              .read(dialogNavigatorProvider.notifier)
              .setPageIndex(DialogNavigatorEnum.reset);
          Navigator.of(context).pop();
        },
      );
    }
  }

  Widget getBody(
    int page,
    AddCustomerFormBloc addCustomerFormBloc,
    CustomerNotifier customerNotifier,
    BuildContext context,
  ) {
    switch (page) {
      case DialogNavigatorEnum.listCustomer:
        return const ListCustomerBody();

      case DialogNavigatorEnum.addCustomer:
        return AddCustomerBody(addCustomerFormBloc: addCustomerFormBloc);

      case DialogNavigatorEnum.viewCustomer:
        return const ViewCustomerBody();

      case DialogNavigatorEnum.editCustomer:
        final currentCustomerModel = customerNotifier.getCurrentCustomerModel;
        final orderCustomerModel = customerNotifier.getOrderCustomerModel;
        EditCustomerFormBloc formBloc = EditCustomerFormBloc(
          context,
          orderCustomerModel ?? currentCustomerModel ?? CustomerModel(),
          ref.read(customerProvider.notifier),
        );
        return EditCustomerBody(formBloc: formBloc);

      default:
        return Container();
    }
  }
}
