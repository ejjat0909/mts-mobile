import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/features/sales/components/rename_tab_dialogue.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabItem extends ConsumerStatefulWidget {
  final bool isSelected;
  final Function() onPressed;

  final PageModel? pageModel;
  final bool isIcon;
  final bool isEditMode;
  final int totalPages;
  final int index;

  const TabItem({
    super.key,
    this.pageModel,
    required this.isSelected,
    required this.onPressed,
    this.isIcon = false,
    this.isEditMode = false,
    required this.totalPages,
    required this.index,
  });

  @override
  ConsumerState<TabItem> createState() => _TabItemState();
}

class _TabItemState extends ConsumerState<TabItem> {
  String getPageName() {
    return widget.pageModel!.pageName ?? 'Page ${widget.index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return getBody();
  }

  Expanded getBody() {
    if (widget.isEditMode && widget.isSelected && !widget.isIcon) {
      return Expanded(
        child: PopupMenuButton<int>(
          position: PopupMenuPosition.over,
          tooltip: 'showMenu'.tr(),
          onSelected: (result) {
            // Handle the selected option here
            switch (result) {
              case DialogNavigatorEnum.moveRight:
                ThemeSnackBar.showSnackBar(context, 'Coming Soon');
                break;
              case DialogNavigatorEnum.moveLeft:
                ThemeSnackBar.showSnackBar(context, 'Coming Soon');
                break;
              case DialogNavigatorEnum.rename:
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return RenameTabDialogue(pageModel: widget.pageModel!);
                  },
                );
                break;
              case DialogNavigatorEnum.delete:
                // ThemeSnackBar.showSnackBar(context, "Coming Soon");
                if (widget.pageModel != null) {
                  ConfirmDialog.show(
                    context,
                    description: 'deletePageDesc'.tr(),
                    onPressed: () async {
                      await ref
                          .read(pageItemProvider.notifier)
                          .removePage(widget.pageModel!);
                      NavigationUtils.pop(context);
                    },
                  );
                }

                break;
            }
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<int>>[
                // tutup sebab coming soon
                // PopupMenuItem<int>(
                //   value: DialogueNaviagtorEnum.MOVE_RIGHT,
                //   child: Row(
                //     children: [
                //       const Icon(Icons.arrow_forward),
                //       const SizedBox(width: 10),
                //       Text('moveRight'.tr()),
                //     ],
                //   ),
                // ),
                // tutup sebab coming soon
                // PopupMenuItem<int>(
                //   value: DialogueNaviagtorEnum.MOVE_LEFT,
                //   child: Row(
                //     children: [
                //       const Icon(Icons.arrow_back),
                //       const SizedBox(width: 10),
                //       Text('moveLeft'.tr()),
                //     ],
                //   ),
                // ),
                PopupMenuItem<int>(
                  value: DialogNavigatorEnum.rename,
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 10),
                      Text('rename'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem<int>(
                  value: DialogNavigatorEnum.delete,
                  child: Row(
                    children: [
                      const Icon(Icons.delete),
                      const SizedBox(width: 10),
                      Text('delete'.tr()),
                    ],
                  ),
                ),
              ],
          child: Container(
            padding: EdgeInsets.all(widget.isIcon ? 12 : 15),
            decoration: BoxDecoration(
              color: widget.isSelected ? kPrimaryLightColor : white,
              border: Border(
                top: BorderSide(
                  color: widget.isSelected ? kPrimaryColor : kPrimaryLightColor,
                ),
              ),
            ),
            child: Center(
              child:
                  widget.isIcon
                      ? widget.isEditMode && widget.totalPages < 5
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'addPages'.tr(),
                                style: AppTheme.normalTextStyle(
                                  color:
                                      widget.isSelected
                                          ? kPrimaryColor
                                          : kBlackColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              const Icon(
                                FontAwesomeIcons.folderPlus,
                                size: 20,
                                color: kPrimaryColor,
                              ),
                            ],
                          )
                          : Icon(
                            TableModel.getIcon(),
                            color: kTextGray,
                            size: 24,
                          )
                      : widget.pageModel != null
                      ? widget.isEditMode && widget.isSelected
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getPageName(),
                                style: AppTheme.normalTextStyle(
                                  color:
                                      widget.isSelected
                                          ? kPrimaryColor
                                          : kBlackColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              const Icon(
                                FontAwesomeIcons.solidCircleUp,
                                size: 20,
                                color: kPrimaryColor,
                              ),
                            ],
                          )
                          : Text(
                            getPageName(),
                            style: AppTheme.normalTextStyle(
                              color:
                                  widget.isSelected
                                      ? kPrimaryColor
                                      : kBlackColor,
                            ),
                          )
                      : const Text('Error'),
            ),
          ),
        ),
      );
    } else {
      return Expanded(
        child: ScaleTap(
          onPressed: widget.onPressed,
          child: Container(
            padding: EdgeInsets.all(widget.isIcon ? 12 : 15),
            decoration: BoxDecoration(
              color: widget.isSelected ? kPrimaryLightColor : white,
              border: Border(
                top: BorderSide(
                  color: widget.isSelected ? kPrimaryColor : kPrimaryLightColor,
                ),
              ),
            ),
            child: Center(
              child:
                  widget.isIcon
                      ? widget.isEditMode && widget.totalPages < 5
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'addPages'.tr(),
                                style: AppTheme.normalTextStyle(
                                  color:
                                      widget.isSelected
                                          ? kPrimaryColor
                                          : kBlackColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              const Icon(
                                FontAwesomeIcons.folderPlus,
                                size: 20,
                                color: kPrimaryColor,
                              ),
                            ],
                          )
                          : Icon(
                            TableModel.getIcon(),
                            color: kTextGray,
                            size: 24,
                          )
                      : widget.pageModel != null
                      ? widget.isEditMode && widget.isSelected
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getPageName(),
                                style: AppTheme.normalTextStyle(
                                  color:
                                      widget.isSelected
                                          ? kPrimaryColor
                                          : kBlackColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              const Icon(
                                FontAwesomeIcons.solidCircleUp,
                                size: 20,
                                color: kPrimaryColor,
                              ),
                            ],
                          )
                          : Text(
                            getPageName(),
                            style: AppTheme.normalTextStyle(
                              color:
                                  widget.isSelected
                                      ? kPrimaryColor
                                      : kBlackColor,
                            ),
                          )
                      : const Text('Error'),
            ),
          ),
        ),
      );
    }
  }
}
