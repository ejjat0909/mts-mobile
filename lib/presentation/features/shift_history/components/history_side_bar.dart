import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/presentation/common/widgets/no_permission.dart';
import 'package:mts/presentation/features/shift_history/components/history_item.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';

class HistorySidebar extends ConsumerStatefulWidget {
  const HistorySidebar({super.key});

  @override
  ConsumerState<HistorySidebar> createState() => _HistorySidebarState();
}

class _HistorySidebarState extends ConsumerState<HistorySidebar> {
  List<ShiftModel> allItems = [];
  List<ShiftModel> filteredItems = [];
  String searchText = '';
  int _selectedIndex = -1;

  // Initially, display all items

  List<ShiftModel> searchItems(String query) {
    // Filter the items based on the search query
    return allItems
        .where(
          (model) => DateTimeUtils.getDateFormat(model.createdAt!) == query,
        )
        .toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(shiftProvider.notifier).setShiftHistoryTitle('', null);
    });
    initData();
  }

  Future<void> initData() async {
    await getListShiftModel();
  }

  Future<void> getListShiftModel() async {
    allItems = await ref.read(shiftProvider.notifier).getListShiftForHistory();
    filteredItems = allItems;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermission = permissionNotifier.hasViewShiftReportsPermission();
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: kPrimaryColor.withValues(alpha: 1),
              width: 0.05,
            ),
          ),
          boxShadow: [
            BoxShadow(
              offset: const Offset(1, 4),
              blurRadius: 10,
              spreadRadius: 0,
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: MyTextFormField(
            //     labelText: 'search'.tr(),
            //     hintText: 'search'.tr(),
            //     leading: Padding(
            //       padding: EdgeInsets.only(
            //         top: 20.h,
            //         left: 10.w,
            //         right: 10.w,
            //         bottom: 20.h,
            //       ),
            //       child: const Icon(
            //         FontAwesomeIcons.magnifyingGlass,
            //         color: kBg,
            //       ),
            //     ),
            //     onChanged: (value) {
            //       setState(() {
            //         searchText = value;
            //         filteredItems = searchItems(value);
            //       });
            //     },
            //   ),
            // ),
            hasPermission
                ? Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      return HistoryItem(
                        shiftModel: filteredItems[index],
                        press: () {
                          String title = '';
                          // isSynced property removed
                          title = DateTimeUtils.getDateTimeFormat(
                            filteredItems[index].createdAt!,
                          );
                          _onItemTapped(
                            filteredItems.indexOf(filteredItems[index]),
                          );
                          // this will also set the current shift to show the shift details
                          // that used in Header in shift details
                          ref
                              .read(shiftProvider.notifier)
                              .setShiftHistoryTitle(
                                title,
                                filteredItems[index],
                              );
                        },
                        isSelected:
                            _selectedIndex ==
                            filteredItems.indexOf(filteredItems[index]),
                      );
                    },
                  ),
                )
                : Expanded(child: NoPermission()),
          ],
        ),
      ),
    );
  }
}
