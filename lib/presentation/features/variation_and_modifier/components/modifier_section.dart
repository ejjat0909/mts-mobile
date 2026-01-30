import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/variation_and_modifier/components/modifier_option_item.dart';
import 'package:mts/providers/item_modifier/item_modifier_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';

class ModifierSection extends ConsumerStatefulWidget {
  final ModifierModel modifierModel;
  final List<String> selectedModifierOptionIds;
  final List<ModifierOptionModel> selectedModifierOptions;
  final List<ModifierModel> listModifiers;
  final int? totalRequiredModifier;
  final bool isModifierRequired;
  final bool isFromOrderListSales;
  final Function(bool isSectionSelected, String? modifierId)? onSectionSelected;

  const ModifierSection({
    super.key,
    required this.modifierModel,
    required this.selectedModifierOptionIds,
    required this.listModifiers,
    required this.isModifierRequired,
    required this.totalRequiredModifier,
    required this.onSectionSelected,
    required this.isFromOrderListSales,
    required this.selectedModifierOptions,
  });

  @override
  ConsumerState<ModifierSection> createState() => _ModifierSectionState();
}

class _ModifierSectionState extends ConsumerState<ModifierSection> {
  List<ModifierModel> listSelectedModifiers = [];
  Set<String> selectedMoIds = {}; // Set to hold selected modifier option ids
  bool _wasSelected = false;
  ModifierModel selectedModifierModel = ModifierModel();
  List<ModifierOptionModel> currSelectedModifierOptions = [];

  getSelectedModifier(ItemModifierNotifier itemModifierNotifier) {
    // to get the selected modifier option
    selectedMoIds = widget.selectedModifierOptionIds.toSet();
    listSelectedModifiers = itemModifierNotifier
        .getModifierListFromListModifierOptionIds(selectedMoIds.toList());
    setState(() {});
  }

  // @override
  // void initState() {
  //   super.initState();
  //   getSelectedModifier();

  // // to get the selected modifier because item have minimum required modifier
  // selectedModifierModel = listSelectedModifiers.firstWhere(
  //     (element) => element.id == widget.modifierModel.id,
  //     orElse: () => ModifierModel());
  //   bool isSelected = selectedMoIds.isNotEmpty;

  //   if (selectedModifierModel.id != null) {
  //     if (isSelected) {
  //       _wasSelected = true; // ✅ Reset _wasSelected correctly
  //       prints('Child InitState Triggered with TRUE');
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         widget.onSectionSelected?.call(true, widget.modifierModel.id);
  //       });
  //     } else {
  //       _wasSelected = false; // ✅ Reset _wasSelected correctly
  //     }
  //   }
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemModifierNotifier = ref.read(itemModifierProvider.notifier);
      getSelectedModifier(itemModifierNotifier);
      _wasSelected = selectedMoIds.isNotEmpty;
      // to get the selected modifier because item have minimum required modifier
      selectedModifierModel = listSelectedModifiers.firstWhere(
        (element) => element.id == widget.modifierModel.id,
        orElse: () => ModifierModel(),
      );

      currSelectedModifierOptions =
          widget.selectedModifierOptions
              .where(
                (element) => element.modifierId == selectedModifierModel.id,
              )
              .toList();

      if (_wasSelected) {
        prints('Child InitState Triggered with TRUE');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onSectionSelected?.call(true, selectedModifierModel.id);
        });
      }
    });
  }

  void handleOnPressMOItem(
    String index,
    ModifierOptionModel modOptModel,
    SaleItemNotifier saleItemsNotifier,
  ) {
    setState(() {});
    if (modOptModel.id != null) {
      // Use the selected modifier options from the widget
      List<ModifierOptionModel> listModOpt = List.from(
        widget.selectedModifierOptions,
      );

      setState(() {
        if (selectedMoIds.contains(index)) {
          selectedMoIds.remove(index);
          listModOpt.removeWhere((element) => element.id == modOptModel.id);

          if (selectedMoIds.isEmpty) {
            if (_wasSelected) {
              _wasSelected = false;
              widget.onSectionSelected?.call(false, widget.modifierModel.id);
              // prints('💀 Modifier Deselected: ${widget.modifierModel.id!}');
            }
          } // Handle bila reopen isFromOrderListSales = true
          else if (widget.isFromOrderListSales) {
            // prints('widget.selectedModifierOptionIds');
            // prints(widget.selectedModifierOptionIds);
            // prints(selectedMoIds);
            currSelectedModifierOptions.removeWhere(
              (element) => element.id == modOptModel.id,
            );
            if (currSelectedModifierOptions.isEmpty) {
              _wasSelected = false;
              widget.onSectionSelected?.call(false, widget.modifierModel.id);
            }
            // prints(
            //     '💀 Modifier Deselected (From Order List Sales): ${widget.modifierModel.id!}');
          }
        } else {
          selectedMoIds.add(index);
          listModOpt.add(modOptModel);

          /// [DO NOT CHANGE THE POSITION OF THIS IF ELSE BLOCK]
          if (widget.isFromOrderListSales) {
            // Kalau reopen dari order list
            // prints('add sini');
            currSelectedModifierOptions.add(modOptModel);
            widget.onSectionSelected?.call(true, widget.modifierModel.id);
            // prints(
            //     '🔥 Modifier Selected (From Order List Sales): ${widget.modifierModel.id!}');
          } else if (!_wasSelected) {
            _wasSelected = true;
            widget.onSectionSelected?.call(true, widget.modifierModel.id);
            //  prints('🔥 Modifier Selected: ${widget.modifierModel.id!}');
          }
        }

        saleItemsNotifier.setSelectedModifierOptionList(listModOpt);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsNotifier = ref.watch(saleItemProvider.notifier);
    if (widget.modifierModel.id != null) {
      final listModifierOption = ref.watch(
        modifierOptionsByModifierIdProvider(widget.modifierModel.id!),
      );

      if (listModifierOption.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Space(20),
              Text(
                widget.modifierModel.name!,
                style: AppTheme.normalTextStyle(
                  color: kBlackColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Space(10),
              GridView.count(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                // Two columns per row
                childAspectRatio: 10,
                // resize the children, dont remove this or ui will mess up
                crossAxisSpacing: 10,
                // space between row
                mainAxisSpacing: 10,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                children: [
                  ..._getModifierOptionItem(
                    context,
                    listModifierOption,
                    saleItemsNotifier,
                  ),
                ],
              ),
              widget.listModifiers.isNotEmpty &&
                      widget.listModifiers.last == widget.modifierModel &&
                      widget.totalRequiredModifier != null
                  ? const Space(10)
                  : const SizedBox.shrink(),
              widget.listModifiers.isNotEmpty &&
                      widget.listModifiers.last == widget.modifierModel &&
                      widget.totalRequiredModifier != null &&
                      widget.isModifierRequired
                  ? Text(
                    'pleaseAtLeastChooseModifier'.tr(
                      args: [widget.totalRequiredModifier.toString()],
                    ),
                    style: AppTheme.normalTextStyle(
                      color: kTextRed,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      }
      // Show loading indicator while waiting for data
      return const Center(child: CircularProgressIndicator());
    }
    return Container();
  }

  List<Widget> _getModifierOptionItem(
    BuildContext context,
    List<ModifierOptionModel> listModifierOptionModel,
    SaleItemNotifier saleItemsNotifier,
  ) {
    List<Widget> listModOpt = [];
    for (var element in listModifierOptionModel) {
      if (element.id != null) {
        listModOpt.add(
          ModifierOptionItem(
            element: element,
            onPressed: () async {
              // avoid lag
              await Future.delayed(const Duration(milliseconds: 100));
              handleOnPressMOItem(element.id!, element, saleItemsNotifier);
            },
            isSelected: selectedMoIds.contains(element.id),
          ),
        );
      }
    }
    return listModOpt;
  }
}
