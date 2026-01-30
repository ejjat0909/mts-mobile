import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/form_bloc/edit_tab_form_bloc.dart';
import 'package:mts/plugins/flutter_form_bloc/flutter_form_bloc.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_field_bloc_builder.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';

class RenameTabDialogue extends ConsumerStatefulWidget {
  final PageModel pageModel;

  const RenameTabDialogue({super.key, required this.pageModel});

  @override
  ConsumerState<RenameTabDialogue> createState() => _RenameTabDialogueState();
}

class _RenameTabDialogueState extends ConsumerState<RenameTabDialogue> {
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
          create: (context) => EditTabFormBloc(widget.pageModel),
          child: Builder(
            builder: (context) {
              final editTabFormbloc = BlocProvider.of<EditTabFormBloc>(context);
              return FormBlocListener<EditTabFormBloc, String, String>(
                onSubmitting: (context, state) {},
                onSuccess: (context, state) async {
                  final name = state.successResponse;
                  widget.pageModel.pageName = name ?? '';
                  await ref.read(pageItemProvider.notifier).updatePageModel(
                    widget.pageModel,
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
                            'editPageName'.tr(),
                            style: AppTheme.h1TextStyle(),
                          ),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 1,
                            child: ButtonTertiary(
                              text: 'save'.tr(),
                              icon: FontAwesomeIcons.download,
                              onPressed: () {
                                editTabFormbloc.submit();
                                NavigationUtils.pop(context);
                                ref
                                    .read(dialogNavigatorProvider.notifier)
                                    .setPageIndex(DialogNavigatorEnum.reset);
                              },
                            ),
                          ),
                        ],
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: canvasColor),
                        onPressed: () {
                          ref
                              .read(dialogNavigatorProvider.notifier)
                              .setPageIndex(DialogNavigatorEnum.reset);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: StreamBuilder<TextFieldBlocState<dynamic>>(
                        stream: editTabFormbloc.name.stream,
                        initialData: editTabFormbloc.name.state,
                        builder: (context, snapshot) {
                          final value = snapshot.data?.value ?? '';
                          bool isInitialValue =
                              value == editTabFormbloc.initialNameValue;
                          bool isManuallyEdited =
                              editTabFormbloc.hasManuallyEdited;
                          return Column(
                            children: [
                              MyTextFieldBlocBuilder(
                                textFieldBloc: editTabFormbloc.name,
                                labelText: 'name'.tr(),
                                hintText: '',
                                isHighlightValue: isInitialValue,
                                isManuallyEdited: isManuallyEdited,
                                onChanged: (value) {
                                  // Check if the value has changed
                                  // Value changed, mark as manually edited
                                  editTabFormbloc.hasManuallyEdited = true;
                                },
                              ),
                              const Space(20),
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
}
