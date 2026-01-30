import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/form_bloc/edit_order_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/custom_my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';

class EditOrderDialogue extends ConsumerStatefulWidget {
  final Function(PredefinedOrderModel) onSuccessForm;
  final Function(String errorMessage) onErrorForm;
  final PredefinedOrderModel currentPOM;
  const EditOrderDialogue({
    super.key,
    required this.onSuccessForm,
    required this.onErrorForm,
    required this.currentPOM,
  });

  @override
  ConsumerState<EditOrderDialogue> createState() => _EditOrderDialogueState();
}

class _EditOrderDialogueState extends ConsumerState<EditOrderDialogue> {
  @override
  Widget build(BuildContext context) {
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
              (context) => EditOrderFormBloc(
                currentPOM: widget.currentPOM,
                predefinedOrderNotifier: ref.read(
                  predefinedOrderProvider.notifier,
                ),
              ),
          child: Builder(
            builder: (context) {
              final editOrderFormBloc = BlocProvider.of<EditOrderFormBloc>(
                context,
              );

              editOrderFormBloc.name.stream.listen((state) {
                // If the field is empty and hasn't been manually edited yet,
                // we want to show the initial value but select it all on focus
                if (state.value.isEmpty &&
                    !editOrderFormBloc.hasManuallyEdited) {
                  editOrderFormBloc.name.updateValue(
                    editOrderFormBloc.initialNameValue,
                  );
                }

                // We don't need to handle the built-in clear button anymore
                // since we're using our custom trailing icon
              });

              return FormBlocListener<
                EditOrderFormBloc,
                PredefinedOrderModel,
                String
              >(
                onSubmitting: (context, state) {},
                onSuccess: (context, state) {
                  final updatedPOM = state.successResponse;
                  widget.onSuccessForm(updatedPOM!);
                },
                onFailure: (context, state) {
                  widget.onErrorForm(state.failureResponse!);
                },
                onSubmissionFailed: (context, state) {
                  widget.onErrorForm('somethingWentWrong'.tr());
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Space(10),
                    AppBar(
                      elevation: 0,
                      backgroundColor: white,
                      title: Row(
                        children: [
                          Text('editOrder'.tr(), style: AppTheme.h1TextStyle()),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 1,
                            child: ButtonTertiary(
                              text: 'save'.tr(),
                              icon: FontAwesomeIcons.download,
                              onPressed: () {
                                onPressSave(editOrderFormBloc);
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
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: StreamBuilder<TextFieldBlocState<dynamic>>(
                        stream: editOrderFormBloc.name.stream,
                        initialData: editOrderFormBloc.name.state,
                        builder: (context, snapshot) {
                          final value = snapshot.data?.value ?? '';
                          bool isInitialValue =
                              value == editOrderFormBloc.initialNameValue;
                          bool isManuallyEdited =
                              editOrderFormBloc.hasManuallyEdited;

                          final nameFocusNode = FocusNode();
                          final commentFocusNode = FocusNode();

                          // Dispose the focus node when the widget is removed
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Add a callback to dispose the focus node when the widget is removed
                            // This is a workaround since we can't use dispose() with StatefulBuilder
                            ModalRoute.of(context)?.addScopedWillPopCallback(
                              () {
                                nameFocusNode.dispose();
                                commentFocusNode.dispose();
                                return Future.value(true);
                              },
                            );
                          });
                          return Column(
                            children: [
                              CustomMyTextFieldBlocBuilder(
                                focusNode: nameFocusNode,
                                textFieldBloc: editOrderFormBloc.name,
                                labelText: 'name'.tr(),
                                hintText: '',
                                isHighlightValue: isInitialValue,
                                isManuallyEdited: isManuallyEdited,
                                onChanged: (value) {
                                  // If this is the first edit
                                  if (!editOrderFormBloc.hasManuallyEdited) {
                                    // Mark as manually edited
                                    editOrderFormBloc.hasManuallyEdited = true;

                                    // If the user is just starting to type (adding to the initial value)
                                    // and the value starts with the initial value, we want to replace it
                                    if (value.startsWith(
                                          editOrderFormBloc.initialNameValue,
                                        ) &&
                                        value.length >
                                            editOrderFormBloc
                                                .initialNameValue
                                                .length) {
                                      // Get just the new character(s) the user typed
                                      String newText = value.substring(
                                        editOrderFormBloc
                                            .initialNameValue
                                            .length,
                                      );
                                      // Replace the initial value with just what the user typed
                                      Future.microtask(() {
                                        editOrderFormBloc.name.updateValue(
                                          newText,
                                        );
                                      });
                                    }
                                  }
                                },
                                // Use a custom trailing icon that's always visible
                                trailingIcon: IconButton(
                                  icon: Icon(
                                    FontAwesomeIcons.xmark,
                                    color: canvasColor,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    // Clear the field and mark as manually edited
                                    editOrderFormBloc.name.updateValue("");
                                    editOrderFormBloc.hasManuallyEdited = true;

                                    // Request focus directly using the focus node
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(nameFocusNode);
                                  },
                                ),
                              ),

                              // comment Input Field
                              MyTextFieldBlocBuilder(
                                textFieldBloc: editOrderFormBloc.comment,
                                labelText: 'comment'.tr(),
                                hintText: '',
                                trailingIcon: IconButton(
                                  icon: Icon(
                                    FontAwesomeIcons.xmark,
                                    color: canvasColor,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    // Clear the field and mark as manually edited
                                    editOrderFormBloc.comment.updateValue("");

                                    // Request focus directly using the focus node
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(commentFocusNode);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
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

  void onPressSave(EditOrderFormBloc editOrderFormBloc) {
    final isFeatureActive =
        ref.read(featureCompanyProvider.notifier).isOpenOrdersActive();

    if (!isFeatureActive) {
      DialogUtils.showFeatureNotAvailable(context);
      return;
    }
    editOrderFormBloc.submit();
  }
}
