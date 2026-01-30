import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enum/home_receipt_navigator_enum.dart';
import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/presentation/common/dialogs/theme_spinner.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/home_receipt/components/home_receipt_filter_dialogue.dart';
import 'package:mts/presentation/features/home_receipt/components/home_receipt_item.dart';
import 'package:mts/presentation/features/home_receipt/components/list_receipt_items_sidebar.dart';
import 'package:mts/presentation/common/widgets/no_permission.dart';
import 'package:mts/providers/my_navigator/my_navigator_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt/receipt_state.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';

class HomeReceiptSidebar extends ConsumerStatefulWidget {
  final Function(int) selectedIndexCallback;

  const HomeReceiptSidebar({super.key, required this.selectedIndexCallback});

  @override
  ConsumerState<HomeReceiptSidebar> createState() => _HomeReceiptSidebarState();
}

class _HomeReceiptSidebarState extends ConsumerState<HomeReceiptSidebar> {
  static const _pageSize = 10;
  final PagingController<int, ReceiptModel> _pagingController =
      PagingController(firstPageKey: 1);
  String searchText = '';
  int _selectedIndex = -1;

  // DateTimeRange? selectedDateRange;
  String dateTimeFilter = '';
  String? paymentType;
  String? orderOption;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptProvider.notifier).setPagingController(_pagingController);

      // int? selectedReceiptIndex =
      //     ref.read(receiptProvider).selectedReceiptIndex;

      // if (selectedReceiptIndex != null) {
      //   _selectedIndex = selectedReceiptIndex;
      // } else {
      //   prints("SELEXTED INDEX IS NULL");
      // }

      // ReceiptModel? receiptModel =
      //     ref.read(receiptProvider).tempReceiptModel;

      // prints("receiptModel: $receiptModel");
    });

    _pagingController.addPageRequestListener((pageKey) async {
      await Future.delayed(const Duration(milliseconds: 100));
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    final rn = ref.read(receiptProvider);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final newItems = await ref
          .read(receiptProvider.notifier)
          .searchReceiptIDFromDb(
            searchText,
            rn.lastSelectedDateRange,
            pageKey,
            _pageSize,
            rn.previousPaymentType,
            rn.previousOrderOption,
          );
      newItems.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      // prints(newItems.map((e) => e.updatedAt));
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  // Future<List<ReceiptModel>> searchReceipt(
  //     String query, DateTimeRange? dateRange, int page, int pageSize) async {

  //   final listReceiptModel = await ReceiptBloc.getListReceiptModel();
  //   var filtered = listReceiptModel.where((model) {
  //     final matchesQuery =
  //         model.id!.toString().toLowerCase().contains(query.toLowerCase());
  //     final matchesDateRange = dateRange == null ||
  //         (model.createdAt!.isAfter(dateRange.start) &&
  //             model.createdAt!.isBefore(dateRange.end));
  //     return matchesQuery && matchesDateRange;
  //   }).toList();

  //   final startIndex = (page - 1) * pageSize;
  //   final endIndex = startIndex + pageSize;
  //   return filtered.sublist(
  //       startIndex, endIndex > filtered.length ? filtered.length : endIndex);
  // }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      widget.selectedIndexCallback(index);
    });
    ref.read(receiptProvider.notifier).setSelectedReceiptIndex(index);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _selectedIndex =
        ref.watch(receiptProvider).selectedReceiptIndex ?? _selectedIndex;

    // prints('SELECTED INDEX: $_selectedIndex');

    return Consumer(
      builder: (context, ref, child) {
        final receiptState = ref.watch(receiptProvider);
        final permissionNotifier = ref.read(permissionProvider.notifier);
        final receiptNavigator = receiptState.pageIndex;

        if (receiptNavigator == HomeReceiptNavigatorEnum.receiptDetails) {
          return listReceipts(receiptState, permissionNotifier);
        } else if (receiptNavigator == HomeReceiptNavigatorEnum.receiptRefund) {
          // ListReceiptsItemSidebar still uses old ReceiptNotifier - hybrid approach
          final oldReceiptNotifier = ref.read(receiptProvider.notifier);
          return ListReceiptsItemSidebar(receiptNotifier: oldReceiptNotifier);
        } else {
          return Container();
        }
      },
    );
  }

  Widget listReceipts(
    ReceiptState receiptState,
    PermissionNotifier permissionNotifier,
  ) {
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MyTextFormField(
                trailingIcon: FontAwesomeIcons.filter,
                trailingIconColor: getTrailingIconColor(receiptState),
                trailingIconOnPress: () async {
                  ref
                      .read(receiptProvider.notifier)
                      .setReceiptDialogueNavigator(DialogNavigatorEnum.reset);
                  // rn.setIsApplyFilter(false);
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      return const HomeReceiptFilterDialogue();
                    },
                  );
                },
                labelText: 'search'.tr(),
                hintText: 'search'.tr(),
                leading: Padding(
                  padding: EdgeInsets.only(
                    top: 20.h,
                    left: 10.w,
                    right: 10.w,
                    bottom: 20.h,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: kBg,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    _pagingController.refresh();
                  });
                },
              ),
            ),
            Visibility(
              visible: dateTimeFilter != '',
              child: Text(dateTimeFilter, style: AppTheme.mediumTextStyle()),
            ),
            permissionNotifier.hasViewAllReceiptPermission()
                ? Expanded(
                  child: PagedListView<int, ReceiptModel>(
                    pagingController: _pagingController,
                    physics: const BouncingScrollPhysics(),
                    builderDelegate: PagedChildBuilderDelegate<ReceiptModel>(
                      animateTransitions: true,
                      itemBuilder: (context, item, index) {
                        // prints("SELECTEDDDDDD INDEX: $_selectedIndex");sd
                        if (receiptState.selectedReceiptIndex == null) {
                          _selectedIndex = -1;
                        }
                        return HomeReceiptItem(
                          receiptModel: item,
                          isSelected: _selectedIndex == index,
                          press: () {
                            onPress(index, context);
                          },
                        );
                      },
                      noItemsFoundIndicatorBuilder:
                          (context) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.receipt,
                                size: 100,
                                color: kTextGray.withValues(alpha: 0.5),
                              ),
                              Space(40.h),
                              Text(
                                'noReceipt'.tr(),
                                style: AppTheme.mediumTextStyle(),
                              ),
                            ],
                          ),
                      firstPageProgressIndicatorBuilder:
                          (context) => ThemeSpinner.spinner(),
                      newPageProgressIndicatorBuilder:
                          (context) => ThemeSpinner.spinner(),
                    ),
                  ),
                )
                : Expanded(child: NoPermission()),
          ],
        ),
      ),
    );
  }

  Color getTrailingIconColor(ReceiptState receiptState) {
    if (receiptState.lastSelectedDateRange != null) {
      return kPrimaryColor;
    }

    if (receiptState.previousPaymentType != null) {
      return kPrimaryColor;
    }

    if (receiptState.previousOrderOption != null) {
      return kPrimaryColor;
    }

    return kTextGray;
  }

  Future<void> onPress(int index, BuildContext context) async {
    int receiptStatusId = _pagingController.itemList![index].receiptStatus!;
    // to avoid lag while onPress after changing the index
    await Future.delayed(const Duration(milliseconds: 100));
    ReceiptModel receiptModel = _pagingController.itemList![index];
    String tabTitle =
        '${receiptModel.showUUID!} | ${DateTimeUtils.getDateTimeFormat(receiptModel.createdAt)}';
    List<ReceiptItemModel> listReceiptItemModel = await ref
        .read(receiptItemProvider.notifier)
        .getListReceiptItemsByReceiptId(receiptModel.id!);
    _onItemTapped(index);

    // clear temp receipt id
    ref.read(receiptProvider.notifier).clearTempReceiptId();
    // set receipt id
    prints(receiptModel.showUUID);
    ref.read(receiptProvider.notifier).setTempReceiptModel(receiptModel);

    ref
        .read(myNavigatorProvider.notifier)
        .setSelectedTab(receiptStatusId, tabTitle);
    // set home receipt navigator to receipt details
    ref
        .read(receiptProvider.notifier)
        .setPageIndex(HomeReceiptNavigatorEnum.receiptDetails);

    // set initial receipt item

    ref
        .read(receiptProvider.notifier)
        .addBulkInitialListReceiptItems(listReceiptItemModel);
  }

  void updateSearchController(List<DateTime> dateTimeList) {
    DateFormat formatter = DateFormat('dd MMM yyyy HH:mm', 'en_US');
    String formattedStart = formatter.format(dateTimeList[0]);
    String formattedEnd = formatter.format(dateTimeList[1]);

    dateTimeFilter = '$formattedStart - $formattedEnd';
  }
}
