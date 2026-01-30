import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/staff/staff_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/common/widgets/table_name_row.dart';
import 'package:mts/presentation/features/assign_order_table/components/assign_order_table_item.dart';
import 'package:mts/presentation/features/open_and_move_order/components/search_by_order_option_section.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';

class AssignOrderTableDialogue extends ConsumerStatefulWidget {
  final TableModel tableModel;
  const AssignOrderTableDialogue({super.key, required this.tableModel});

  @override
  ConsumerState<AssignOrderTableDialogue> createState() =>
      _AssignOrderTableDialogueState();
}

class _AssignOrderTableDialogueState
    extends ConsumerState<AssignOrderTableDialogue> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  late ScrollController _scrollController;
  bool isSelectAll = false; // Added for master checkbox state
  bool isShowAll = true;

  bool _isLoadingMoreList = false;

  // Pagination variables
  static const int _pageSize = 20;
  int _currentPage = 0;
  int _totalCount = 0;
  bool _hasMorePages = true;

  List<SaleModel> _originalList =
      []; // The original list of orders (first page)
  List<SaleModel> _allLoadedOrders = []; // All loaded orders for filtering
  List<SaleModel> _filteredList = [];
  List<bool> selectedOrders = [];
  String _selectedOrderOptionId = '-1';

  UserModel userModel = ServiceLocator.get<UserModel>();
  StaffModel staffModel = ServiceLocator.get<StaffModel>();

  Future<void> getListSaleModel() async {
    try {
      final saleNotifier = ref.read(saleProvider.notifier);
      // Get first page of orders
      _originalList = await saleNotifier.getListSavedOrdersPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Get total count of orders
      _totalCount = await saleNotifier.getTotalSavedOrdersCount();

      // Update loaded orders list
      _allLoadedOrders = List.from(_originalList);
      _filteredList = List.from(_originalList);

      // Check if there are more pages
      _hasMorePages = (_currentPage + 1) * _pageSize < _totalCount;

      selectedOrders = List.generate(_filteredList.length, (index) => false);
      if (mounted) {
        searchController.addListener(_filterOrders);
        setState(() {});
      }
    } catch (e) {
      prints('Error loading initial orders: $e');
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMoreList || !_hasMorePages) return;

    setState(() {
      _isLoadingMoreList = true;
    });

    try {
      _currentPage++;
      final saleNotifier = ref.read(saleProvider.notifier);
      // guna ni jer sebab boleh tukar2 meja
      final nextPageOrders = await saleNotifier.getListSavedOrdersPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          // Append new orders to the loaded list
          _allLoadedOrders.addAll(nextPageOrders);

          // Re-apply filter if search is active
          if (searchController.text.isEmpty) {
            _filteredList = List.from(_allLoadedOrders);
          } else {
            _filterOrders();
          }

          // Update selection state tracking
          selectedOrders = List.generate(
            _filteredList.length,
            (index) => false,
          );

          // Check if there are more pages
          _hasMorePages = (_currentPage + 1) * _pageSize < _totalCount;
          _isLoadingMoreList = false;
        });
      }
    } catch (e) {
      prints('Error loading next page: $e');
      if (mounted) {
        setState(() {
          _isLoadingMoreList = false;
          _currentPage--; // Revert page number on error
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // User has scrolled near the bottom, load next page
      if (_hasMorePages && !_isLoadingMoreList) {
        _loadNextPage();
      }
    }
  }

  void _filterOrders() {
    String query = searchController.text.toLowerCase();
    setState(() {
      _filteredList =
          _allLoadedOrders.where((order) {
            // Filter by order option
            if (_selectedOrderOptionId != '-1' &&
                order.orderOptionId != _selectedOrderOptionId) {
              return false;
            }

            // Filter by search query
            if (query.isEmpty) {
              return true;
            }

            final nameMatch =
                order.name?.toLowerCase().contains(query) ?? false;
            final remarksMatch =
                order.remarks?.toLowerCase().contains(query) ?? false;
            final tableNameMatch = order.tableName?.toLowerCase() == query;
            final runningNumber =
                order.runningNumber?.toString().toLowerCase().contains(query) ??
                false;
            return nameMatch || tableNameMatch || remarksMatch || runningNumber;
          }).toList();

      selectedOrders = List.generate(_filteredList.length, (index) => false);

      // _updateSelectAllState(); // Reset master checkbox when filtering
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize scroll controller for pagination
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // _barcodeScannerNotifier = ServiceLocator.get<BarcodeScannerNotifier>();
    // // _barcodeScannerNotifier.initialize();
    // _barcodeScannerNotifier.initializeForOpenOrderBody();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      // _isLoadingList = false;
      setState(() {
        _currentPage = 0;
        _hasMorePages = true;
      });
      await Future.wait([getListSaleModel()]);

      // setState(() {
      //   _isLoadingList = false;
      // });
    });
  }

  @override
  void dispose() {
    // _selectAllUpdateTimer?.cancel();
    searchController.removeListener(_filterOrders);
    searchController.dispose();
    searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Reinitialize to sales screen when dialog closes
    // _barcodeScannerNotifier.reinitializeToSalesScreen();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.watch(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    // final hasPermissionVoidOrders =
    //     permissionNotifier.hasVoidSavedItemsInOpenOrderPermission();
    // final saleItemsNotifier = ref.read(saleItemsProvider.notifier);
    // final saleItemsState = ref.watch(saleItemsProvider);
    // final saleNotifier = context.watch<SaleNotifier>();
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          minHeight: availableHeight,
          maxWidth: availableWidth / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Space(10),
            AppBar(
              elevation: 0,
              backgroundColor: white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('assignOrderTo'.tr(), style: AppTheme.h1TextStyle()),
                  10.widthBox,
                  Flexible(
                    child: TableNameRow(
                      tableName: widget.tableModel.name ?? '',
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: canvasColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: MyTextFormField(
                focusNode: searchFocusNode,
                trailingIcon: FontAwesomeIcons.xmark,
                onChanged: (value) {
                  setState(() {
                    if (value != '') {
                      isShowAll = false;
                    } else {
                      isShowAll = true;
                    }
                  });
                },
                trailingIconOnPress: () {
                  setState(() {
                    searchController.clear();
                    isShowAll = true;
                  });
                },
                controller: searchController,
                labelText: 'searchOrderNumberOrTableNumber'.tr(),
                hintText: 'search'.tr(),
                leading: Padding(
                  padding: EdgeInsets.only(
                    top: 10.h,
                    left: 10.w,
                    right: 10.w,
                    bottom: 10.h,
                  ),
                  child: const Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: kBg,
                  ),
                ),
              ),
            ),
            SearchByOrderOptionSection(
              onSelected: (orderOptionModel) {
                setState(() {
                  _selectedOrderOptionId = orderOptionModel.id ?? '-1';
                });
                _filterOrders();
              },
            ),
            const Divider(),
            Expanded(
              child: Column(
                children: [
                  isShowAll && _filteredList.isNotEmpty
                      ? AssignOrderTableItem(
                        isHaveOrder: _filteredList.isNotEmpty,
                        saleModel: null,
                        isHead: true,
                        onAssign: () {},
                      )
                      : const Space(0),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount:
                            _filteredList.length + (_isLoadingMoreList ? 1 : 0),
                        // Add these optimizations:
                        addRepaintBoundaries: true,
                        cacheExtent: 1000, // Cache more items off-screen
                        itemBuilder: (context, index) {
                          // Show loading indicator at the end
                          if (index == _filteredList.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final saleModel = _filteredList[index];

                          return AssignOrderTableItem(
                            key: ValueKey(saleModel.id), // Add stable key
                            saleModel: saleModel,

                            onAssign: () async {
                              NavigationUtils.pop(context);
                              if (!hasPermissionManageOrders) {
                                DialogUtils.showNoPermissionDialogue(
                                  navigatorKey.currentContext,
                                );
                                return;
                              }

                              await ref
                                  .read(saleProvider.notifier)
                                  .assignOrderToThatTable(
                                    incomingSaleModel: saleModel,
                                    incomingTableModel: widget.tableModel,
                                    onSuccess: () {
                                      ThemeSnackBar.showSnackBar(
                                        navigatorKey.currentContext!,
                                        "${'successAssign'.tr()} ${widget.tableModel.name}",
                                      );
                                    },
                                    onError: (message) {
                                      ThemeSnackBar.showSnackBar(
                                        navigatorKey.currentContext!,
                                        message,
                                      );
                                    },
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
