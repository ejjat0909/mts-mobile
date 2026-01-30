import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/ui_utils.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/presentation/features/tables/components/tables.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

class TablesViewBody extends ConsumerStatefulWidget {
  const TablesViewBody({super.key});

  @override
  ConsumerState<TablesViewBody> createState() => _TablesViewBodyState();
}

class _TablesViewBodyState extends ConsumerState<TablesViewBody> {
  List<PredefinedOrderModel> predefinedOrders = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<List<PredefinedOrderModel>> getAllPO() async {
    return await ref.read(predefinedOrderProvider.notifier).getListPredefinedOrder();
  }

  Future<void> _fetch() async {
    predefinedOrders = await getAllPO();

    if (mounted) {
      prints("MASUK FETCHHH");

      // Use Riverpod provider to initialize table view
      await ref.read(tableLayoutProvider.notifier).initTableView();
      prints("INIT TABLE VIEW");

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableLayoutState = ref.watch(tableLayoutProvider);

    return Material(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [UIUtils.itemShadow()],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        const Padding(padding: EdgeInsets.only(left: 3)),
                        Row(
                          children: List.generate(
                            tableLayoutState.sections.length,
                            (index) {
                              TableSectionModel currentSection =
                                  tableLayoutState.currSection ??
                                  TableSectionModel();
                              TableSectionModel indexSection =
                                  tableLayoutState.sections[index];
                              bool isSelected =
                                  currentSection.id == indexSection.id;
                              return InkWell(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 90,
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: white,
                                      border: Border(
                                        bottom: BorderSide(
                                          width: 3,
                                          color:
                                              isSelected //Selected section
                                                  ? Colors.blue
                                                  : Colors.white,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          tableLayoutState
                                              .sections[index]
                                              .name!,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color:
                                                isSelected
                                                    ? Colors.blue
                                                    : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  ref
                                      .read(tableLayoutProvider.notifier)
                                      .setCurrSection(
                                        tableLayoutState.sections[index],
                                      );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // main content show the tables selected
              Expanded(
                flex: 9,
                child: Tables(
                  //selected section will pass to Section class
                  sectionModel:
                      tableLayoutState.currSection ?? TableSectionModel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
