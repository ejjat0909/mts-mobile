import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:mts/app/theme/theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';

class SearchByOrderOptionSection extends ConsumerStatefulWidget {
  final Function(OrderOptionModel) onSelected;
  const SearchByOrderOptionSection({super.key, required this.onSelected});

  @override
  ConsumerState<SearchByOrderOptionSection> createState() =>
      _SearchByOrderOptionSectionState();
}

class _SearchByOrderOptionSectionState
    extends ConsumerState<SearchByOrderOptionSection> {
  // final OrderOptionNotifier orderOptionNotifier =
  //     ServiceLocator.get<OrderOptionNotifier>();
  OrderOptionModel allOrderOption = OrderOptionModel(id: '-1', name: 'All');
  // List<OrderOptionModel> listOrderOptions = [];
  late String selectedId = '-1';

  @override
  void initState() {
    super.initState();

    // listOrderOptions = [
    //   allOrderOption,
    //   ...orderOptionNotifier.getListOrderOption,
    // ];
  }

  @override
  Widget build(BuildContext context) {
    final orderOptionState = ref.watch(orderOptionProvider);
    List<OrderOptionModel> listOrderOptions = [
      allOrderOption,
      ...orderOptionState.items,
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              listOrderOptions.map((orderOption) {
                return _buildCardOrderOption(
                  orderOption,
                  isSelected: selectedId == orderOption.id,
                  onPress: () {
                    setState(() {
                      selectedId = orderOption.id ?? '';
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onSelected(orderOption);
                    });
                  },
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardOrderOption(
    OrderOptionModel orderOption, {
    required bool isSelected,
    required Function() onPress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ScaleTap(
        onPressed: onPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? kBadgeBgYellow : kBadgeBgGray,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            style: textStyleNormal(
              color: isSelected ? kBadgeTextYellow : kBadgeTextGray,
            ),
            child: Text(
              orderOption.name ?? 'null',
              style: textStyleNormal(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? kBadgeTextYellow : kBadgeTextGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
