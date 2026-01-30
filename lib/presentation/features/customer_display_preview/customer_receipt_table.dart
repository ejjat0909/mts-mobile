import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/enum/data_enum.dart';
import 'package:mts/core/enum/item_sold_by_enum.dart';
import 'package:mts/core/utils/format_utils.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/modifier_option/modifier_option_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/variant_option/variant_option_model.dart';
import 'package:mts/presentation/common/widgets/live_time.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/modifier_option/modifier_option_providers.dart';

class CustomerReceiptTable extends ConsumerStatefulWidget {
  final Map<Object?, Object?>? acceptedData;

  const CustomerReceiptTable({super.key, required this.acceptedData});

  @override
  ConsumerState<CustomerReceiptTable> createState() =>
      _CustomerReceiptTableState();
}

class _CustomerReceiptTableState extends ConsumerState<CustomerReceiptTable> {
  DateTime now = DateTime.now();
  String formattedData = '';
  final ScrollController _scrollController = ScrollController();
  String totalAmountRemaining = '0.00';
  String totalAfterDiscAndTax = '0.00';
  List<dynamic> saleItemMap = [];
  List<SaleItemModel> saleItemList = [];

  List<dynamic> saleModifierMap = [];
  List<SaleModifierModel> saleModifierList = [];

  List<dynamic> saleModifierOptionMap = [];
  List<SaleModifierOptionModel> saleModifierOptionList = [];

  List<dynamic> itemMap = [];
  List<ItemModel> itemList = [];

  List<dynamic> modifierOptionMap = [];
  List<ModifierOptionModel> modifierOptionList = [];

  String totalDiscount = '0.00';
  String totalTax = '0.00';
  String totalTaxIncluded = '0.00';
  String totalAdjustment = '0.00';
  String totalWithAdjustedPrice = '0.00';

  @override
  void initState() {
    // Auto-scroll to the bottom when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    super.initState();
  }

  void getData(Map<String, dynamic>? data) {
    prints("😊😊😊😊😊😊✅✅✅");
    if (data != null) {
      /// [for sale items]
      if (data[DataEnum.listSaleItems] != null) {
        saleItemMap = data[DataEnum.listSaleItems];
        saleItemList = List.generate(saleItemMap.length, (index) {
          final item = saleItemMap[index];
          if (item is Map) {
            return SaleItemModel.fromJson(Map<String, dynamic>.from(item));
          }
          return SaleItemModel(); // or handle error
        });
      }

      /// [list sale modifier model]
      if (data[DataEnum.listSM] != null) {
        saleModifierMap = data[DataEnum.listSM];
        saleModifierList = List.generate(saleModifierMap.length, (index) {
          final item = saleModifierMap[index];
          if (item is Map) {
            return SaleModifierModel.fromJson(Map<String, dynamic>.from(item));
          }
          return SaleModifierModel(); // or handle error
        });
      }

      /// [list sale modifier option model]
      if (data[DataEnum.listSMO] != null) {
        saleModifierOptionMap = data[DataEnum.listSMO];
        saleModifierOptionList = List.generate(saleModifierOptionMap.length, (
          index,
        ) {
          final item = saleModifierOptionMap[index];
          if (item is Map) {
            return SaleModifierOptionModel.fromJson(
              Map<String, dynamic>.from(item),
            );
          }
          return SaleModifierOptionModel(); // or handle error
        });
      }

      /// [list item]
      if (data[DataEnum.listItems] != null) {
        itemMap = data[DataEnum.listItems];
        itemList = List.generate(itemMap.length, (index) {
          final item = itemMap[index];

          if (item is Map) {
            return ItemModel.fromJson(Map<String, dynamic>.from(item));
          }
          return ItemModel(); // or handle error
        });
      }

      /// [list modifier option]
      if (data[DataEnum.listMO] != null) {
        modifierOptionMap = data[DataEnum.listMO];
        modifierOptionList = List.generate(modifierOptionMap.length, (index) {
          final item = modifierOptionMap[index];
          if (item is Map) {
            return ModifierOptionModel.fromJson(
              Map<String, dynamic>.from(item),
            );
          }
          return ModifierOptionModel(); // or handle error
        });
      }

      if (data[DataEnum.totalAfterDiscAndTax] != null) {
        totalAfterDiscAndTax = (data[DataEnum.totalAfterDiscAndTax] as num)
            .toStringAsFixed(2);
      }

      if (data[DataEnum.totalAmountRemaining] != null) {
        totalAmountRemaining = (data[DataEnum.totalAmountRemaining] as num)
            .toStringAsFixed(2);
      }

      if (data[DataEnum.totalDiscount] != null) {
        totalDiscount = (data[DataEnum.totalDiscount] as num).toStringAsFixed(
          2,
        );
      }

      if (data[DataEnum.totalTax] != null) {
        totalTax = (data[DataEnum.totalTax] as num).toStringAsFixed(2);
      }

      if (data[DataEnum.totalTaxIncluded] != null) {
        totalTaxIncluded = (data[DataEnum.totalTaxIncluded] as num)
            .toStringAsFixed(2);
      }

      if (data[DataEnum.totalAdjustment] != null) {
        totalAdjustment = (data[DataEnum.totalAdjustment] as num)
            .toStringAsFixed(2);
      }

      if (data[DataEnum.totalWithAdjustedPrice] != null) {
        totalWithAdjustedPrice = (data[DataEnum.totalWithAdjustedPrice] as num)
            .toStringAsFixed(2);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Add a small delay to ensure all content is properly laid out
      Future.delayed(const Duration(milliseconds: 100), () {
        // Check if there's content to scroll to
        if (_scrollController.position.maxScrollExtent > 0) {
          // Use jumpTo first to ensure we're at the bottom
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

          // Then animate for a smoother experience
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // TableRow _generateRow(String quantity, String items, String price,
  //     {String? variants, String? modifier}) {
  //   return ;
  // }

  String getTotalPrice(Map<Object?, Object?>? data) {
    String afterCashRounding = '0.00';

    if (data != null) {
      final map = Map.fromEntries(
        data.entries
            .where((e) => e.key is String)
            .map((e) => MapEntry(e.key as String, e.value)),
      );

      final isCharged = map[DataEnum.isCharged] as bool?;
      if (isCharged == null || !isCharged) {
        final totalWithAdjustedPrice =
            map[DataEnum.totalWithAdjustedPrice] as double?;
        final total = map[DataEnum.totalAfterDiscAndTax] as double?;
        if (totalWithAdjustedPrice == 0.00) {
          if (total != null && total >= 0.00) {
            // use value from totalAfterDiscAndTax
            afterCashRounding = total.toStringAsFixed(2);
          }
        } else {
          if (totalWithAdjustedPrice != null &&
              totalWithAdjustedPrice >= 0.00) {
            afterCashRounding = totalWithAdjustedPrice.toStringAsFixed(2);
          }
        }
      } else {
        final remaining = map[DataEnum.totalAmountRemaining] as double?;
        if (remaining != null) {
          afterCashRounding = remaining.toStringAsFixed(2);
        }
      }
    }
    prints(FormatUtils.formatNumber('RM'.tr(args: [afterCashRounding])));
    return FormatUtils.formatNumber('RM'.tr(args: [afterCashRounding]));
  }

  @override
  Widget build(BuildContext context) {
    final data =
        widget.acceptedData == null
            ? null
            : Map.fromEntries(
              widget.acceptedData!.entries
                  .where((e) => e.key is String)
                  .map((e) => MapEntry(e.key as String, e.value)),
            );

    getData(data);

    //  prints("ORRRDERRR OPTION ${orderOption?.name}");

    return Column(
      children: [
        Container(
          // margin: const EdgeInsets.symmetric(
          //   horizontal: 20,
          //   vertical: 20,
          // ),
          // padding: const EdgeInsets.symmetric(
          //   horizontal: 10,
          //   vertical: 10,
          // ),
          child: Text(
            getTotalPrice(widget.acceptedData),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 0),
              child: Row(children: [Expanded(child: LiveTime())]),
            ),
            Text(
              //'Order: Dine In',
              '${"order".tr()} : ${getOrderOption(widget.acceptedData)}',
              style: const TextStyle(fontSize: 15),
            ),
            // Text(
            //   //'Payment Type: Cash',
            //   "customerPaymentType".tr(),
            //   style: const TextStyle(
            //     fontSize: 15,
            //   ),
            // ),
          ],
        ),
        const Divider(),
        // column for table and show total
        buildTable(),
        const Divider(),
        priceSummary(),
      ],
    );
  }

  Widget priceSummary() {
    return Expanded(
      flex: 2,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          //    crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    //'Tax',
                    'tax'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    FormatUtils.formatNumber('RM'.tr(args: [totalTax])),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    //'Tax',
                    "${'tax'.tr()} (Included)",
                    style: textStyleNormal(color: kTextGray, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    FormatUtils.formatNumber('RM'.tr(args: [totalTaxIncluded])),
                    style: textStyleNormal(color: kTextGray, fontSize: 12),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    //'Discount',
                    'discount'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    '-${FormatUtils.formatNumber("RM".tr(args: [totalDiscount]))}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            totalAdjustment != "0.00" ? 5.heightBox : const SizedBox.shrink(),
            totalAdjustment != "0.00"
                ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        //'Discount',
                        'adjustment'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '-${FormatUtils.formatNumber("RM".tr(args: [totalAdjustment]))}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                )
                : const SizedBox.shrink(),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    //'Sub Total',
                    'subtotal'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    getTotalPrice(widget.acceptedData),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String getOrderOption(Map<Object?, Object?>? data) {
    if (data == null) return '';

    // Safely convert map keys to String
    final map = Map.fromEntries(
      data.entries
          .where((e) => e.key is String)
          .map((e) => MapEntry(e.key as String, e.value)),
    );

    final rawOrderOption = map[DataEnum.orderOptionModel];
    if (rawOrderOption is Map) {
      final json = Map<String, dynamic>.from(rawOrderOption);
      final orderOptionModel = OrderOptionModel.fromJson(json);
      return orderOptionModel.name ?? '';
    }

    return '';
  }

  Widget buildTable() {
    return FutureBuilder(
      future: generateTableRows(
        context,
        saleItemList,
        saleModifierList,
        saleModifierOptionList,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Expanded(
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Expanded(
            child: Center(child: Text('No data available')),
          );
        }
        List<TableRow> listTableRow = snapshot.data!;
        // Schedule scroll to bottom after the frame is rendered
        // This ensures we scroll after the content is fully loaded and rendered
        if (listTableRow.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        return Expanded(
          flex: 5,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(5),
                    2: FlexColumnWidth(2.1),
                  },
                  children: [
                    //Header
                    TableRow(
                      decoration: const BoxDecoration(
                        color: kLightGray,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              //'Qty',
                              'quantity'.tr(),
                              style: AppTheme.normalTextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            //'Items',
                            'customerItem'.tr(),
                            style: AppTheme.normalTextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            //'Price',
                            'customerPrice'.tr(),
                            style: AppTheme.normalTextStyle(fontSize: 12),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      // decoration: const BoxDecoration(color: kLightGray),
                      children: [
                        Padding(padding: const EdgeInsets.all(5.0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                        ),
                        Padding(padding: const EdgeInsets.all(5.0)),
                      ],
                    ),
                    ...listTableRow,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<TableRow>> generateTableRows(
    BuildContext context,
    List<SaleItemModel> saleItemList,
    List<SaleModifierModel> listSM,
    List<SaleModifierOptionModel> listSMO,
  ) async {
    return await Future.wait(
      saleItemList.map((saleItem) async {
        // Fetch saleModifierModels
        List<SaleModifierModel> saleModifierModels = listSM;

        // Get saleModifierIds

        List<String> saleModifierIds =
            saleModifierModels
                .where((element) => element.saleItemId == saleItem.id)
                .map((e) => e.id!)
                .toList();

        // Fetch saleModifierOptionModels
        List<SaleModifierOptionModel> saleModifierOptionModels = listSMO;

        // Get modifierOptionIds
        List<String> modifierOptionIds = [];

        saleModifierIds.asMap().forEach((index, saleModifierId) {
          List<String> matchingSaleModifierIds =
              saleModifierOptionModels
                  .where((element) => element.saleModifierId == saleModifierId)
                  .map((e) => e.modifierOptionId!)
                  .toList();

          modifierOptionIds.addAll(matchingSaleModifierIds);
        });

        // Find or create usedSaleItemModel
        final usedSaleItemModel = saleItemList.firstWhere(
          (element) =>
              element.id == saleItem.id &&
              element.variantOptionId == saleItem.variantOptionId &&
              element.comments == saleItem.comments &&
              element.updatedAt == saleItem.updatedAt,
          orElse: () => SaleItemModel(),
        );

        final itemId = usedSaleItemModel.itemId;

        /// [Fetch item model, modifier option name, variant option name]
        ItemModel? itemModel = ref
            .read(itemProvider.notifier)
            .getItemModelByIdForTransfer(itemId!, itemList);

        String allModifierOptionName = ref
            .read(modifierOptionProvider.notifier)
            .getModifierOptionNameFromListIdsForTransfer(
              modifierOptionIds,
              modifierOptionList,
            );

        VariantOptionModel? variantOption = ref
            .read(itemProvider.notifier)
            .getVariantOptionModelByIdForTransfer(
              usedSaleItemModel.variantOptionId,
              itemModel?.id ?? itemId,
              itemList,
            );

        String variantOptionName = variantOption?.name ?? '';

        // Generate TableRow

        if (itemModel == null) {
          return const TableRow(
            children: [
              Padding(padding: EdgeInsets.zero),
              Padding(padding: EdgeInsets.zero),
              Padding(padding: EdgeInsets.zero),
            ],
          );
        }
        return buildSoldByItem(
          usedSaleItemModel,
          itemModel,
          variantOptionName,
          allModifierOptionName,
          saleItem,
        );
      }).toList(),
    );
  }

  TableRow buildSoldByItem(
    SaleItemModel usedSaleItemModel,
    ItemModel? itemModel,
    String variantOptionName,
    String allModifierOptionName,
    SaleItemModel saleItem,
  ) {
    const double padding = 2.5;
    const double fontSize = 10;
    String qty =
        itemModel!.soldBy == ItemSoldByEnum.item
            ? usedSaleItemModel.quantity?.toStringAsFixed(0) ?? '0'
            : usedSaleItemModel.quantity?.toStringAsFixed(3) ?? '0.000';

    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: Text(
              qty,
              style: AppTheme.normalTextStyle(fontSize: fontSize),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemModel.name ?? 'No Name',
                style: AppTheme.normalTextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),

              variantOptionName != ''
                  ? Text(
                    variantOptionName,
                    style: AppTheme.normalTextStyle(fontSize: fontSize - 2),
                  )
                  : const SizedBox.shrink(),
              allModifierOptionName != ''
                  ? Text(
                    allModifierOptionName,
                    style: AppTheme.normalTextStyle(fontSize: fontSize - 2),
                  )
                  : const SizedBox.shrink(),
              saleItem.comments!.trim() != ''
                  ? Text(
                    saleItem.comments!,
                    style: AppTheme.normalTextStyle(fontSize: fontSize - 2),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(padding),
          child: Text(
            FormatUtils.formatNumber(saleItem.price!.toStringAsFixed(2)),
            style: AppTheme.normalTextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  TableRow buildSoldByCustomPrice(
    SaleItemModel usedSaleItemModel,
    ItemModel? itemModel,
    String variantOptionName,
    String allModifierOptionName,
    SaleItemModel saleItem,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('C', style: AppTheme.normalTextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      itemModel?.name ?? 'No Name',
                      style: AppTheme.normalTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  5.widthBox,
                  Text(
                    itemModel!.soldBy == ItemSoldByEnum.measurement
                        ? 'x ${usedSaleItemModel.quantity!.toStringAsFixed(3)}'
                        : 'x ${usedSaleItemModel.quantity!.toStringAsFixed(0)}',
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 10,
                      color: kTextGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              variantOptionName != ''
                  ? Text(
                    variantOptionName,
                    style: AppTheme.normalTextStyle(fontSize: 11),
                  )
                  : const SizedBox.shrink(),
              allModifierOptionName != ''
                  ? Text(
                    allModifierOptionName,
                    style: AppTheme.normalTextStyle(fontSize: 11),
                  )
                  : const SizedBox.shrink(),
              saleItem.comments!.trim() != ''
                  ? Text(
                    saleItem.comments!,
                    style: AppTheme.normalTextStyle(fontSize: 11),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            saleItem.price!.toStringAsFixed(2),
            style: AppTheme.normalTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  TableRow buildSoldByMeasurement(
    SaleItemModel usedSaleItemModel,
    ItemModel? itemModel,
    String variantOptionName,
    String allModifierOptionName,
    SaleItemModel saleItem,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('M', style: AppTheme.normalTextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      itemModel?.name ?? 'No Name',
                      style: AppTheme.normalTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  5.widthBox,
                  Text(
                    'x ${usedSaleItemModel.quantity!.toStringAsFixed(3)}',
                    style: AppTheme.normalTextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 10,
                      color: kTextGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              variantOptionName != ''
                  ? Text(
                    variantOptionName,
                    style: AppTheme.normalTextStyle(fontSize: 11),
                  )
                  : const SizedBox.shrink(),
              allModifierOptionName != ''
                  ? Text(
                    allModifierOptionName,
                    style: AppTheme.normalTextStyle(fontSize: 11),
                  )
                  : const SizedBox.shrink(),
              saleItem.comments!.trim() != ''
                  ? Text(
                    saleItem.comments!,
                    style: AppTheme.normalTextStyle(fontSize: 11),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            FormatUtils.formatNumber(saleItem.price!.toStringAsFixed(2)),
            style: AppTheme.normalTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
