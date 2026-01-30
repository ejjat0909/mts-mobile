import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/presentation/common/widgets/styled_dropdown.dart';
import 'package:mts/providers/feature_company/feature_company_providers.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';

class ChooseOrderOption extends ConsumerStatefulWidget {
  final Function() chooseCallback;

  const ChooseOrderOption({super.key, required this.chooseCallback});

  @override
  ConsumerState<ChooseOrderOption> createState() => _ChooseCategoryState();
}

class _ChooseCategoryState extends ConsumerState<ChooseOrderOption> {
  late OrderOptionModel? selectedOrderOption;
  late OrderOptionModel? model;
  OrderOptionModel? previousSelectedOption;

  OrderOptionModel defaultOrderOptionModel = OrderOptionModel(
    id: '-1',
    name: '',
  );

  @override
  void initState() {
    model = ref.read(orderOptionProvider.notifier).getOrderOptionModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saleItemsNotifier = ref.read(saleItemProvider.notifier);
      final saleItemsState = ref.read(saleItemProvider);
      final OrderOptionModel? orderOptionModel =
          saleItemsState.orderOptionModel;
      if (orderOptionModel?.id != null) {
        selectedOrderOption = orderOptionModel;
        saleItemsNotifier.setOrderOptionModel(orderOptionModel!);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final featureCompNotifier = ref.read(featureCompanyProvider.notifier);
    final isFeatureActive = featureCompNotifier.isOrderOptionActive();
    final orderOptionNotifier = ref.watch(orderOptionProvider.notifier);
    final saleItemNotifier = ref.read(saleItemProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);
    final listOrderOptionModel = orderOptionNotifier.getListOrderOption();

    if (!isFeatureActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // onSelectOrderOption(
        //   saleItemNotifier,
        //   defaultOrderOptionModel,
        //   isFeatureActive,
        // );
      });
      return SizedBox.shrink();
    }

    // untuk handle bila sync real time
    bool shouldAutoSelect = false;

    if (saleItemsState.orderOptionModel?.id != null) {
      // Check if selected item exists in list
      final itemExists = listOrderOptionModel.any(
        (e) => e.id == saleItemsState.orderOptionModel?.id,
      );

      if (itemExists) {
        selectedOrderOption = listOrderOptionModel.firstWhere(
          (e) => e.id == saleItemsState.orderOptionModel?.id,
        );
      } else {
        // If selected item is deleted from list, use first item or '-1'
        selectedOrderOption =
            listOrderOptionModel.isNotEmpty
                ? listOrderOptionModel.first
                : OrderOptionModel(id: '-1', name: '');
        shouldAutoSelect = true;
      }
    } else {
      final itemExists = listOrderOptionModel.any((e) => e.id == model?.id);

      selectedOrderOption =
          itemExists
              ? listOrderOptionModel.firstWhere((e) => e.id == model?.id)
              : (listOrderOptionModel.isNotEmpty
                  ? listOrderOptionModel.first
                  : defaultOrderOptionModel);
    }

    // Auto-select if item was deleted from list
    if (shouldAutoSelect && selectedOrderOption != previousSelectedOption) {
      previousSelectedOption = selectedOrderOption;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSelectOrderOption(
          saleItemNotifier,
          selectedOrderOption ?? defaultOrderOptionModel,
          isFeatureActive,
        );
      });
    }

    if (selectedOrderOption?.id != null) {
      return StyledDropdown<OrderOptionModel>(
        isHaveBorder: false,
        items:
            listOrderOptionModel.map<DropdownMenuItem<OrderOptionModel>>((
              OrderOptionModel model,
            ) {
              return DropdownMenuItem<OrderOptionModel>(
                value: model, // Set the value to the ID
                child: Text(
                  model.name.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
        selected: selectedOrderOption,
        list: listOrderOptionModel,
        setDropdownValue: (value) async {
          await onSelectOrderOption(saleItemNotifier, value, isFeatureActive);
        },
      );
    } else {
      return Container();
    }
  }

  Future<void> onSelectOrderOption(
    SaleItemNotifier saleItemNotifier,
    OrderOptionModel value,
    bool isFeatureActive,
  ) async {
    saleItemNotifier.setOrderOptionModel(
      isFeatureActive ? value : defaultOrderOptionModel,
      // false sebab just tukar order option, tak perlu recalculate sebab calculate kalau melibatkan order option tax
      reCalculate: false,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    // kira asing sebabtu pilih false

    Map<String, dynamic> dataToTransfer =
        saleItemNotifier.getMapDataToTransfer();

    /// [SHOW SECOND DISPLAY]
    await ref
        .read(slideshowProvider.notifier)
        .showOptimizedSecondDisplay(dataToTransfer);
  }
}
