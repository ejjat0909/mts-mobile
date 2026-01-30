import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scale_tap/flutter_scale_tap.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/custom_variant_map_enum.dart';
import 'package:mts/core/enum/dialog_navigator_enum.dart';
import 'package:mts/core/enums/permission_enum.dart';
import 'package:mts/core/utils/dialog_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/customer/customer_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/dialogs/confirm_dialogue.dart';
import 'package:mts/presentation/common/dialogs/custom_dialog.dart';
import 'package:mts/presentation/common/dialogs/loading_dialogue.dart';
import 'package:mts/presentation/common/dialogs/theme_snack_bar.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/skeleton_card.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/open_and_move_order/components/open_order_item.dart';
import 'package:mts/presentation/features/open_and_move_order/components/search_by_order_option_section.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_providers.dart';
import 'package:mts/providers/customer/customer_providers.dart';
import 'package:mts/providers/dialog_navigator/dialog_navigator_providers.dart';
import 'package:mts/providers/permission/permission_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_item/sale_item_state.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/table_layout/table_layout_providers.dart';

class OpenOrderBody extends ConsumerStatefulWidget {
  final Function(bool) isLoading;
  final Function(Map<String, dynamic>) dataMap;
  final UserModel? userModel;

  const OpenOrderBody({
    super.key,

    required this.isLoading,
    required this.dataMap,
    required this.userModel,
  });

  @override
  ConsumerState<OpenOrderBody> createState() => _OpenOrderBodyState();
}

class _OpenOrderBodyState extends ConsumerState<OpenOrderBody> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  late ScrollController _scrollController;
  bool isSelectAll = false; // Added for master checkbox state
  bool isShowAll = true;
  final bool _isLoadingList = false;
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
  late final SaleNotifier _saleNotifier;
  late final SaleItemNotifier _saleItemNotifier;
  late final SaleModifierNotifier _saleModifierNotifier;
  late final SaleModifierOptionNotifier _saleModifierOptionNotifier;
  late final BarcodeScannerNotifier _barcodeScannerNotifier;
  late final PredefinedOrderNotifier _predefinedOrderNotifier;
  
  Timer? _selectAllUpdateTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 100);

  // Cache for selection state to avoid frequent provider reads
  Set<SaleModel> _cachedSelectedOrders = {};
  bool _cacheValid = false;

  @override
  void initState() {
    super.initState();
    _predefinedOrderNotifier = ref.read(predefinedOrderProvider.notifier);
    _saleNotifier = ref.read(saleProvider.notifier);
    _saleItemNotifier = ref.read(saleItemProvider.notifier);
    _saleModifierNotifier = ref.read(saleModifierProvider.notifier);
    _saleModifierOptionNotifier = ref.read(saleModifierOptionProvider.notifier);

    // Initialize scroll controller for pagination
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _barcodeScannerNotifier = ref.read(barcodeScannerProvider.notifier);
    _barcodeScannerNotifier.initializeForOpenOrderBody();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      // _isLoadingList = false;
      setState(() {
        _currentPage = 0;
        _hasMorePages = true;
      });
      await getListSaleModel();

      // setState(() {
      //   _isLoadingList = false;
      // });
    });
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);
  //   if (state == AppLifecycleState.resumed) {
  //     // App resumed from background
  //     prints('App resumed');
  //   }
  // }

  Future<void> getListSaleModel() async {
    try {
      // Get first page of orders
      _originalList = await _saleNotifier.getListSavedOrdersPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Get total count of orders
      _totalCount = await _saleNotifier.getTotalSavedOrdersCount();

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

  /// Handle scroll events for lazy loading pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // User has scrolled near the bottom, load next page
      if (_hasMorePages && !_isLoadingMoreList) {
        _loadNextPage();
      }
    }
  }

  /// Load the next page of orders
  Future<void> _loadNextPage() async {
    if (_isLoadingMoreList || !_hasMorePages) return;

    setState(() {
      _isLoadingMoreList = true;
    });

    try {
      _currentPage++;
      final nextPageOrders = await _saleNotifier.getListSavedOrdersPaginated(
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

  void _updateSelectAllState() {
    final selectedOrdersProvider = ref.read(saleItemProvider.notifier);
    setState(() {
      isSelectAll = selectedOrdersProvider.isAllOpenOrderSelected(
        _filteredList,
      );
    });
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

      _updateSelectAllState(); // Reset master checkbox when filtering
    });
  }

  String? _lastProcessedBarcode;

  /// Handle barcode scanned event
  void _handleBarcodeScanned(String scannedBarcode) {
    prints('BARCODE SCANNNNEEEEEDDDD: $scannedBarcode');

    if (scannedBarcode.isEmpty) {
      prints('Barcode is empty');
      return;
    }

    // Prevent processing the same barcode multiple times
    if (_lastProcessedBarcode == scannedBarcode) {
      prints('Barcode already processed: $scannedBarcode');
      return;
    }

    _lastProcessedBarcode = scannedBarcode;
    prints('Processing barcode: $scannedBarcode');
    prints('Original list count: ${_originalList.length}');

    // Find matching orders by name or table name
    final matchingOrders = _barcodeScannerNotifier.findOrdersByNameOrTable(
      scannedBarcode,
      _originalList,
    );

    prints('Matching orders found: ${matchingOrders.length}');

    if (matchingOrders.isEmpty) {
      // No matching orders found, don't trigger openOrderOnPress
      prints('No matching orders found for barcode: $scannedBarcode');
      // Clear the scanned barcode to allow new scans
      _barcodeScannerNotifier.clearScannedItem();
      _lastProcessedBarcode = null;
      searchController.text = scannedBarcode;
      return;
    }

    if (matchingOrders.length == 1) {
      // Single match found, automatically open the order
      prints('Single match found, opening order automatically');
      final saleItemsNotifier = ref.read(saleItemProvider.notifier);
      final matchedOrder = matchingOrders.first;
      final index = _originalList.indexOf(matchedOrder);

      if (index != -1) {
        prints('Opening order: ${matchedOrder.name} at index: $index');
        searchController.text = scannedBarcode;
        // Clear the scanned barcode before opening order
        _barcodeScannerNotifier.clearScannedItem();
        _lastProcessedBarcode = null;

        // Trigger openOrderOnPress for the matched order
        openOrderOnPress(
          matchedOrder,
          saleItemsNotifier,
          index,
          context,
          matchedOrder.predefinedOrderId!,
        );
      }
    } else {
      // Multiple matches found, use search controller to filter
      prints('Multiple matches found, filtering search');
      searchController.text = scannedBarcode;
      // Clear the scanned barcode after setting search text
      _barcodeScannerNotifier.clearScannedItem();
      _lastProcessedBarcode = null;
      // The _filterOrders method will be called automatically due to the listener
    }
  }

  Future<void> printVoidAndDeleteSelectedOrders() async {
    final saleItemNotifier = ref.read(saleItemProvider.notifier);
    final customerNotifier = ref.read(customerProvider.notifier);

    // Show loading dialog immediately without delay
    LoadingDialog.show(context);

    try {
      // Batch all state resets together to minimize UI updates
      await _resetOrderState(saleItemNotifier, customerNotifier);

      // Execute print and delete operations
      await _executePrintAndDeleteOperations();
    } catch (e) {
      prints('Error in printVoidAndDeleteSelectedOrders: $e');
    } finally {
      // Ensure loading dialog is always hidden
      if (mounted) {
        LoadingDialog.hide(context);
      }
    }
  }

  /// Reset all order-related state in a single batch operation
  Future<void> _resetOrderState(
    dynamic saleItemNotifier,
    dynamic customerNotifier,
  ) async {
    // Use microtask to defer state updates and prevent blocking
    await Future.microtask(() {
      // Batch all state resets together
      saleItemNotifier.setPredefinedOrderModel(PredefinedOrderModel());
      saleItemNotifier.setSelectedTable(TableModel());
      saleItemNotifier.setCurrSaleModel(SaleModel());
      customerNotifier.setOrderCustomerModel(null);
    });
  }

  /// Execute print and delete operations with optimized error handling
  Future<void> _executePrintAndDeleteOperations() async {
    await _saleNotifier.printVoidForSelectedDeletedOrders(
      onSuccess: (saleModel) async {
        await _deleteOrdersAndRefreshList(saleModel);
      },
      onError: (message, ipAddress, saleModel) async {
        // Even if printing fails, still delete the selected orders
        prints('Print failed: $message, proceeding with deletion');
        await _deleteOrdersAndRefreshList(saleModel);
      },
    );
  }

  /// Delete orders and refresh the list with optimized performance
  Future<void> _deleteOrdersAndRefreshList(SaleModel saleModel) async {
    await _saleNotifier.deleteSelectedOrders(
      saleModel,
      onSuccess: () async {
        // Use compute or isolate for heavy list operations on low-spec devices
        await _refreshOrderListOptimized();
      },
    );
  }

  /// Optimized list refresh that minimizes main thread blocking
  Future<void> _refreshOrderListOptimized() async {
    try {
      // Reset pagination
      _currentPage = 0;
      _hasMorePages = true;

      // Fetch first page of new data
      final newOrderList = await _saleNotifier.getListSavedOrdersPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Get updated total count
      _totalCount = await _saleNotifier.getTotalSavedOrdersCount();

      if (!mounted) return;

      // Update state in a single batch operation
      await Future.microtask(() {
        _originalList = newOrderList;
        _allLoadedOrders = List.from(newOrderList);

        // Check if there are more pages
        _hasMorePages = (_currentPage + 1) * _pageSize < _totalCount;

        // Single setState call instead of multiple
        if (mounted) {
          setState(() {
            // All state updates happen here in one go
          });
        }
      });

      // Re-apply current filters to maintain filter state
      _filterOrders();
    } catch (e) {
      prints('Error refreshing order list: $e');
      // Fallback to original method if optimization fails
      if (mounted) {
        await getListSaleModel();
      }
    }
  }

  void _toggleSelectAll(SaleItemNotifier saleItemNotifier) {
    setState(() {
      isSelectAll = !isSelectAll;
      if (isSelectAll) {
        saleItemNotifier.selectAll(_filteredList);
      } else {
        saleItemNotifier.deselectAll();
      }
    });
  }

  @override
  void dispose() {
    _selectAllUpdateTimer?.cancel();
    searchController.removeListener(_filterOrders);
    searchController.dispose();
    searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Reinitialize to sales screen when dialog closes
    _barcodeScannerNotifier.reinitializeToSalesScreen();

    super.dispose();
  }

  void _updateCachedSelections() {
    final saleItemsState = ref.read(saleItemProvider);
    _cachedSelectedOrders = Set<SaleModel>.from(
      saleItemsState.selectedOpenOrders,
    );
    _cacheValid = true;
  }

  void _invalidateCache() {
    _cacheValid = false;
  }

  bool _isOrderSelectedCached(SaleModel order) {
    if (!_cacheValid) {
      _updateCachedSelections();
    }
    return _cachedSelectedOrders.contains(order);
  }

  void _updateSelectAllStateOptimized() {
    if (_filteredList.isEmpty) {
      if (isSelectAll) {
        setState(() => isSelectAll = false);
      }
      return;
    }

    if (!_cacheValid) {
      _updateCachedSelections();
    }

    final newSelectAllState =
        _filteredList.length == _cachedSelectedOrders.length &&
        _filteredList.every((order) => _cachedSelectedOrders.contains(order));

    if (isSelectAll != newSelectAllState) {
      setState(() => isSelectAll = newSelectAllState);
    }
  }

  void _updateSelectAllStateDebounced() {
    _selectAllUpdateTimer?.cancel();
    _selectAllUpdateTimer = Timer(_debounceDelay, () {
      if (mounted) {
        _updateSelectAllStateOptimized();
      }
    });
  }

  void _handleOrderSelectionToggle(SaleModel order) {
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);

    // Toggle selection immediately
    saleItemsNotifier.toggleOpenOrderSelection(order);

    // Update cache immediately for better UX
    if (_cacheValid) {
      if (_cachedSelectedOrders.contains(order)) {
        _cachedSelectedOrders.remove(order);
      } else {
        _cachedSelectedOrders.add(order);
      }
    } else {
      _invalidateCache();
    }

    // Use debounced update for select all state
    _updateSelectAllStateDebounced();
  }

  @override
  Widget build(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    final saleItemsNotifier = ref.read(saleItemProvider.notifier);
    final saleItemsState = ref.watch(saleItemProvider);
    final barcodeScannerState = ref.watch(barcodeScannerProvider);

    _invalidateCache();
    if (barcodeScannerState.openOrderBodyBarcode != null &&
        barcodeScannerState.openOrderBodyBarcode!.isNotEmpty) {
      prints(
        'BARCODE SCANNNNEEEEEDDDD: ${barcodeScannerState.openOrderBodyBarcode!}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleBarcodeScanned(barcodeScannerState.openOrderBodyBarcode!);
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Space(10),
        AppBar(
          elevation: 0,
          backgroundColor: white,
          title: Row(
            children: [
              Expanded(
                child: Text('openOrder'.tr(), style: AppTheme.h1TextStyle()),
              ),
              hasPermissionManageOrders
                  ? appBarActionButton(
                    icon: FontAwesomeIcons.trash,
                    iconColor: kTextRed,
                    bgColor: kBgRed,
                    press: () async {
                      await handleDeleteOpenOrder(
                        saleItemsState,
                        context,
                        _filteredList,
                      );
                    },
                  )
                  : const SizedBox.shrink(),
              hasPermissionManageOrders
                  ? SizedBox(width: 15)
                  : SizedBox.shrink(),
              hasPermissionManageOrders
                  ? appBarActionButton(
                    icon: FontAwesomeIcons.arrowRightFromBracket,
                    iconColor: kPrimaryColor,
                    bgColor: kPrimaryLightColor,
                    press: () {
                      // ThemeSnackBar.showSnackBar(
                      //   context,
                      //   'Not ready yet. Sorry :\'(',
                      // );
                      handleOnMergeOrder(context);
                    },
                  )
                  : const SizedBox.shrink(),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: canvasColor),
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(dialogNavigatorProvider.notifier)
                  .setPageIndex(DialogNavigatorEnum.reset);
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
              child: const Icon(FontAwesomeIcons.magnifyingGlass, color: kBg),
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
        _isLoadingList
            ? Expanded(child: SkeletonCard())
            : Expanded(
              child: Column(
                children: [
                  isShowAll && _filteredList.isNotEmpty
                      ? OpenOrderItem(
                        onPressed: null,
                        isHaveOrder: _filteredList.isNotEmpty,
                        isSelectSale: isSelectAll,
                        isHead: true,
                        onChanged: (value) {
                          _toggleSelectAll(saleItemsNotifier);
                        },
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
                          final isSelected = _isOrderSelectedCached(saleModel);

                          return RepaintBoundary(
                            // Isolate repaints
                            child: OpenOrderItem(
                              key: ValueKey(saleModel.id), // Add stable key
                              saleModel: saleModel,
                              isSelectSale: isSelected,
                              onChanged: (value) {
                                _handleOrderSelectionToggle(saleModel);
                              },
                              onPressed: () async {
                                await openOrderOnPress(
                                  saleModel,
                                  ref.read(saleItemProvider.notifier),
                                  index,
                                  context,
                                  saleModel.predefinedOrderId!,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  void handleOnMergeOrder(BuildContext context) {
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final newStateItems = ref.read(saleItemProvider);

    //check permission manage all open orders
    if (!permissionNotifier.hasManageAllOpenOrdersPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }
    bool isAnySelected = newStateItems.selectedOpenOrders.isNotEmpty;
    if (isAnySelected) {
      // set navigator
      ref
          .read(dialogNavigatorProvider.notifier)
          .setPageIndex(DialogNavigatorEnum.moveOrder);
      prints('MOVE ORDER DIALOG');
    } else {
      CustomDialog.show(
        context,
        description: 'selectOneOrderToMove'.tr(),
        dialogType: DialogType.info,
        icon: FontAwesomeIcons.receipt,
        title: 'selectOne'.tr(),
        btnOkText: 'OK',
        btnOkOnPress: () => NavigationUtils.pop(context),
      );
    }
  }

  Future<void> openOrderOnPress(
    SaleModel saleModel,
    SaleItemNotifier saleItemsNotifier,
    int index,
    BuildContext context,
    String predefinedOrderId,
  ) async {
    //prints('predID $predefinedOrderId');
    final customerNotifier = ref.read(customerProvider.notifier);
    final dialogueNav = ref.read(dialogNavigatorProvider.notifier);

    PredefinedOrderModel? pom = await _predefinedOrderNotifier
        .getPredefinedOrderById(predefinedOrderId);

    /// [close dialogue]
    // to avoid lag while transition closing the dialogue
    await Future.delayed(const Duration(milliseconds: 200));
    NavigationUtils.pop(context);
    // to avoid lag while transition closing the dialogue
    await Future.delayed(const Duration(milliseconds: 300));
    //  prints(pom);
    // set predefined order model
    saleItemsNotifier.setPredefinedOrderModel(pom ?? PredefinedOrderModel());
    // get list sale item model based on sale id

    // widget.isLoading(true);
    List<SaleItemModel> listSaleItem = await _saleItemNotifier
        .getListSaleItemByPredefinedOrderId(
          predefinedOrderId,
          isVoided: false,
          isPrintedKitchen: null,
          categoryIds: [],
        );
    List<SaleModifierModel> saleModifiers = await _saleModifierNotifier
        .getListSaleModifiersByPredefinedOrderId(
          predefinedOrderId,
          categoryIds: [],
        );

    List<SaleModifierOptionModel> saleModifierOptions =
        await _saleModifierOptionNotifier
            .getListSaleModifierOptionsByPredefinedOrderId(
              predefinedOrderId,
              categoryIds: [],
            );

    prints('open order on press');

    List<Map<String, dynamic>> listTotalDiscount = [];
    List<Map<String, dynamic>> listTaxAfterDiscount = [];
    List<Map<String, dynamic>> listTaxIncludedAfterDiscount = [];
    List<Map<String, dynamic>> listTotalAfterDiscountAndTax = [];
    List<Map<String, dynamic>> listCustomVariant = [];

    for (SaleItemModel saleItem in listSaleItem) {
      Map<String, dynamic> mapTotalAfterDiscountAndTax = {
        'totalAfterDiscAndTax': saleItem.totalAfterDiscAndTax,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTotalAfterDiscountAndTax.add(mapTotalAfterDiscountAndTax);

      Map<String, dynamic> mapTaxIncludedAfterDiscount = {
        'taxIncludedAfterDiscount': saleItem.taxIncludedAfterDiscount,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTaxIncludedAfterDiscount.add(mapTaxIncludedAfterDiscount);

      Map<String, dynamic> mapTaxAfterDiscount = {
        'taxAfterDiscount': saleItem.taxAfterDiscount,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTaxAfterDiscount.add(mapTaxAfterDiscount);

      Map<String, dynamic> mapDiscountTotal = {
        'discountTotal': saleItem.discountTotal,
        'saleItemId': saleItem.id,
        'updatedAt': saleItem.updatedAt!.toIso8601String(),
      };
      listTotalDiscount.add(mapDiscountTotal);

      dynamic customVariantJson = jsonDecode(
        saleItem.variantOptionJson ?? '{}',
      );
      VariantOptionModel? vom;
      if (saleItem.variantOptionJson != null) {
        vom = VariantOptionModel.fromJson(customVariantJson);
      }

      Map<String, dynamic> mapCustomVariant = {
        CustomVariantMap.saleItemId: saleItem.id,
        CustomVariantMap.variantOptionId: saleItem.variantOptionId,
        CustomVariantMap.isCustomVariant:
            vom != null ? vom.price == null : false,
        CustomVariantMap.variantOptionPrice:
            vom != null ? vom.price ?? 0.00 : 0.00,
        CustomVariantMap.updatedAt: saleItem.updatedAt!.toIso8601String(),
      };
      listCustomVariant.add(mapCustomVariant);
    }

    //get table model from sale item
    TableModel? tableModel = ref
        .read(tableLayoutProvider)
        .tableList
        .firstWhere(
          (table) => table.id == saleModel.tableId,
          orElse: () => TableModel(),
        );
    if (tableModel.id == null) tableModel = null;

    if (tableModel != null && tableModel.id != null) {
      CustomerModel customerModel = customerNotifier.getCustomerById(
        tableModel.customerId,
      );
      customerNotifier.setOrderCustomerModel(
        customerModel.id == null ? null : customerModel,
      );
    }
    saleItemsNotifier.setCurrSaleModel(saleModel);

    // // insert into sale item notifier
    //   prints("SM SM SM ${saleModifiers.map((e) => e.id!).toList()}");
    widget.dataMap({
      'listSaleItem': listSaleItem,
      'filteredSM': saleModifiers,
      'listCustomVariant': listCustomVariant,
      'listTotalAfterDiscountAndTax': listTotalAfterDiscountAndTax,
      'listTaxAfterDiscount': listTaxAfterDiscount,
      'listTaxIncludedAfterDiscount': listTaxIncludedAfterDiscount,
      'listTotalDiscount': listTotalDiscount,
      'filteredSMO': saleModifierOptions,
      'tableModel': tableModel?.id != null ? tableModel : TableModel(),
    });

    dialogueNav.setPageIndex(DialogNavigatorEnum.reset);
  }

  Future<void> handleDeleteOpenOrder(
    SaleItemState saleItemsState,
    BuildContext context,
    List<SaleModel> listSaleModel,
  ) async {
    bool isAnySelected = saleItemsState.selectedOpenOrders.isNotEmpty;
    final permissionNotifier = ref.read(permissionProvider.notifier);
    final hasPermissionManageOrders =
        permissionNotifier.hasManageAllOpenOrdersPermission();
    bool hasPermissionVoidOrders =
        permissionNotifier.hasVoidSavedItemsInOpenOrderPermission();

    if (!permissionNotifier.hasManageAllOpenOrdersPermission()) {
      DialogUtils.showNoPermissionDialogue(context);
      return;
    }

    if (!permissionNotifier.hasVoidSavedItemsInOpenOrderPermission()) {
      await DialogUtils.showPinDialog(
        context,
        permission: PermissionEnum.VOID_SAVED_ITEMS_IN_OPEN_ORDER,
        onSuccess: () {
          hasPermissionVoidOrders = true;
        },
        onError: (error) {
          ThemeSnackBar.showSnackBar(context, error);
          return;
        },
      );
      // DialogUtils.showNoPermissionDialogue(context);
    }

    if (!isAnySelected) {
      if (listSaleModel.isEmpty) {
        ConfirmDialog.show(
          context,
          description: 'noOrderToDelete'.tr().tr(), // please select one order
          onPressed: () async {
            if (hasPermissionManageOrders && hasPermissionVoidOrders) {
              NavigationUtils.pop(context);
              await printVoidAndDeleteSelectedOrders();
            } else {
              DialogUtils.showNoPermissionDialogue(context);
              return;
            }
          },
        );
      } else {
        ConfirmDialog.show(
          context,
          description: 'selectOneOrder'.tr(), // please select one order
          onPressed: () async {
            if (hasPermissionManageOrders && hasPermissionVoidOrders) {
              NavigationUtils.pop(context);
              await printVoidAndDeleteSelectedOrders();
            } else {
              DialogUtils.showNoPermissionDialogue(context);
              return;
            }
          },
        );
      }
    } else {
      if (isSelectAll) {
        ConfirmDialog.show(
          context,
          description: 'deleteAllOrderDescription'.tr(),
          onPressed: () async {
            if (hasPermissionManageOrders && hasPermissionVoidOrders) {
              NavigationUtils.pop(context);
              await printVoidAndDeleteSelectedOrders();
            } else {
              DialogUtils.showNoPermissionDialogue(context);
              return;
            }
          },
        );
      } else {
        ConfirmDialog.show(
          context,
          description: 'deleteOrderDescription'.tr(),
          onPressed: () async {
            if (hasPermissionManageOrders && hasPermissionVoidOrders) {
              NavigationUtils.pop(context);
              await printVoidAndDeleteSelectedOrders();
            } else {
              DialogUtils.showNoPermissionDialogue(context);
              return;
            }
          },
        );
      }
    }
  }

  Widget appBarActionButton({
    required Function() press,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
  }) {
    return ScaleTap(
      onPressed: press,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Center(child: Icon(icon, color: iconColor)),
      ),
    );
  }
}
