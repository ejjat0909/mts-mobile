import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/enum/polymorphic_enum.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/models/category/category_model.dart';
import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/discount/discount_model.dart';
import 'package:mts/data/models/feature/feature_company_model.dart';
import 'package:mts/data/models/feature/feature_model.dart';
import 'package:mts/data/models/inventory/inventory_model.dart';
import 'package:mts/data/models/inventory_outlet/inventory_outlet_model.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/item_representation/item_representation_model.dart';
import 'package:mts/data/models/modifier/modifier_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/page/page_model.dart';
import 'package:mts/data/models/page_item/page_item_model.dart';
import 'package:mts/data/models/payment_type/payment_type_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/receipt/receipt_model.dart';
import 'package:mts/data/models/receipt_item/receipt_item_model.dart';
import 'package:mts/data/models/receipt_setting/receipt_settings_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';
import 'package:mts/data/models/shift/shift_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/data/models/table/table_model.dart';
import 'package:mts/data/models/table_section/table_section_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/data/models/time_card/timecard_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/data/repositories/local/local_category_discount_repository_impl.dart';
import 'package:mts/data/repositories/local/local_category_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_discount_outlet_repository_impl.dart';
import 'package:mts/data/repositories/local/local_item_modifier_repository_impl.dart';
import 'package:mts/data/repositories/local/local_order_option_tax_repository_impl.dart';
import 'package:mts/data/repositories/local/local_outlet_payment_type_repository_impl.dart';
import 'package:mts/data/repositories/local/local_page_item_repository_impl.dart';
import 'package:mts/providers/cash_management/cash_management_providers.dart';
import 'package:mts/providers/category/category_providers.dart';
import 'package:mts/providers/category_discount/category_discount_providers.dart';
import 'package:mts/providers/category_tax/category_tax_providers.dart';
import 'package:mts/providers/department_printer/department_printer_providers.dart';
import 'package:mts/providers/discount/discount_providers.dart';
import 'package:mts/providers/discount_item/discount_item_providers.dart';
import 'package:mts/providers/discount_outlet/discount_outlet_providers.dart';
import 'package:mts/providers/feature/feature_providers.dart';
import 'package:mts/providers/inventory/inventory_providers.dart';
import 'package:mts/providers/inventory_outlet/inventory_outlet_providers.dart';
import 'package:mts/providers/item/item_providers.dart';
import 'package:mts/providers/item_modifier/item_modifier_providers.dart';
import 'package:mts/providers/item_tax/item_tax_providers.dart';
import 'package:mts/providers/modifier/modifier_providers.dart';
import 'package:mts/providers/order_option/order_option_providers.dart';
import 'package:mts/providers/order_option_tax/order_option_tax_providers.dart';
import 'package:mts/providers/outlet/outlet_providers.dart';
import 'package:mts/providers/outlet_payment_type/outlet_payment_type_providers.dart';
import 'package:mts/providers/outlet_tax/outlet_tax_providers.dart';
import 'package:mts/providers/page/page_providers.dart';
import 'package:mts/providers/page_item/page_item_providers.dart';
import 'package:mts/providers/payment_type/payment_type_providers.dart';
import 'package:mts/providers/predefined_order/predefined_order_providers.dart';
import 'package:mts/providers/printer_setting/printer_setting_providers.dart';
import 'package:mts/providers/receipt/receipt_providers.dart';
import 'package:mts/providers/receipt_item/receipt_item_providers.dart';
import 'package:mts/providers/receipt_settings/receipt_settings_providers.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/sale_item/sale_item_providers.dart';
import 'package:mts/providers/sale_modifier/sale_modifier_providers.dart';
import 'package:mts/providers/sale_modifier_option/sale_modifier_option_providers.dart';
import 'package:mts/providers/shift/shift_providers.dart';
import 'package:mts/providers/slideshow/slideshow_providers.dart';
import 'package:mts/providers/table/table_providers.dart';
import 'package:mts/providers/table_section/table_section_providers.dart';
import 'package:mts/providers/tax/tax_providers.dart';
import 'package:mts/providers/timecard/timecard_providers.dart';
import 'package:mts/providers/user/user_providers.dart';

/// Service that handles model deletion with cascading relationships
///
/// This service centralizes all deletion logic that involves cascading deletes
/// across multiple models. It follows Clean Architecture by keeping business
/// rules separate from data access logic.
class ModelDeletionService {
  final Ref _ref;

  ModelDeletionService(this._ref);

  /// Execute deletion by model name and ID
  ///
  /// This method routes to the appropriate cascading deletion method
  /// based on the model name.
  Future<void> deleteByModelName(String modelName, String modelId) async {
    switch (modelName) {
      case CashManagementModel.modelName:
        await deleteCashManagement(modelId);
        break;
      case CategoryModel.modelName:
        await deleteCategoryWithCascade(modelId);
        break;
      case DepartmentPrinterModel.modelName:
        await deleteDepartmentPrinter(modelId);
        break;
      case DiscountModel.modelName:
        await deleteDiscountWithCascade(modelId);
        break;
      case FeatureModel.modelName:
        await deleteFeature(modelId);
        break;
      case FeatureCompanyModel.modelName:
        await deleteFeatureCompany(modelId);
        break;
      case InventoryModel.modelName:
        await deleteInventory(modelId);
        break;
      case InventoryOutletModel.modelName:
        await deleteInventoryOutlet(modelId);
        break;
      case ItemModel.modelName:
        await deleteItemWithCascade(modelId);
        break;
      case ItemRepresentationModel.modelName:
        await deleteItemRepresentation(modelId);
        break;
      case ModifierModel.modelName:
        await deleteModifierWithCascade(modelId);
        break;
      case OrderOptionModel.modelName:
        await deleteOrderOptionWithCascade(modelId);
        break;
      case OutletModel.modelName:
        await deleteOutletWithCascade(modelId);
        break;
      case PageModel.modelName:
        await deletePage(modelId);
        break;
      case PageItemModel.modelName:
        await deletePageItem(modelId);
        break;
      case PaymentTypeModel.modelName:
        await deletePaymentTypeWithCascade(modelId);
        break;
      case PredefinedOrderModel.modelName:
        await deletePredefinedOrder(modelId);
        break;
      case PrinterSettingModel.modelName:
        await deletePrinterSetting(modelId);
        break;
      case ReceiptModel.modelName:
        await deleteReceipt(modelId);
        break;
      case ReceiptItemModel.modelName:
        await deleteReceiptItem(modelId);
        break;
      case ReceiptSettingsModel.modelName:
        await deleteReceiptSettings(modelId);
        break;
      case SaleModel.modelName:
        await deleteSale(modelId);
        break;
      case SaleItemModel.modelName:
        await deleteSaleItem(modelId);
        break;
      case SaleModifierModel.modelName:
        await deleteSaleModifier(modelId);
        break;
      case SaleModifierOptionModel.modelName:
        await deleteSaleModifierOption(modelId);
        break;
      case ShiftModel.modelName:
        await deleteShift(modelId);
        break;
      case SlideshowModel.modelName:
        await deleteSlideshow(modelId);
        break;
      case TableModel.modelName:
        await deleteTable(modelId);
        break;
      case TableSectionModel.modelName:
        await deleteTableSection(modelId);
        break;
      case TaxModel.modelName:
        await deleteTaxWithCascade(modelId);
        break;
      case TimecardModel.modelName:
        await deleteTimecard(modelId);
        break;
      case UserModel.modelName:
        await deleteUser(modelId);
        break;
      default:
        throw Exception('Unknown model name: $modelName');
    }
  }

  // ========== Simple Deletions (No Cascade) ==========

  Future<void> deleteCashManagement(String modelId) async {
    final notifier = _ref.read(cashManagementProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteDepartmentPrinter(String modelId) async {
    final notifier = _ref.read(departmentPrinterProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteFeature(String modelId) async {
    final notifier = _ref.read(featureProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteFeatureCompany(String modelId) async {
    // FeatureCompany is a pivot table, deletion not implemented
    // Skip or throw an exception
    throw UnimplementedError(
      'FeatureCompany deletion not implemented - it is a pivot table',
    );
  }

  Future<void> deleteInventory(String modelId) async {
    final notifier = _ref.read(inventoryProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteInventoryOutlet(String modelId) async {
    final notifier = _ref.read(inventoryOutletProvider.notifier);
    await notifier.delete(modelId);
  }

  Future<void> deleteItemRepresentation(String modelId) async {
    // ItemRepresentation uses AsyncNotifier with different delete signature
    // Skip or handle separately if needed
    throw UnimplementedError(
      'ItemRepresentation deletion not implemented in this service',
    );
  }

  Future<void> deletePage(String modelId) async {
    final notifier = _ref.read(pageProvider.notifier);
    await notifier.delete(modelId);
  }

  Future<void> deletePageItem(String modelId) async {
    final notifier = _ref.read(pageItemProvider.notifier);
    await notifier.delete(modelId);
  }

  Future<void> deletePredefinedOrder(String modelId) async {
    final notifier = _ref.read(predefinedOrderProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deletePrinterSetting(String modelId) async {
    final notifier = _ref.read(printerSettingProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteReceipt(String modelId) async {
    final notifier = _ref.read(receiptProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteReceiptItem(String modelId) async {
    final notifier = _ref.read(receiptItemProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteReceiptSettings(String modelId) async {
    final notifier = _ref.read(receiptSettingsProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteSale(String modelId) async {
    final notifier = _ref.read(saleProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteSaleItem(String modelId) async {
    final notifier = _ref.read(saleItemProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteSaleModifier(String modelId) async {
    final notifier = _ref.read(saleModifierProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteSaleModifierOption(String modelId) async {
    final notifier = _ref.read(saleModifierOptionProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteShift(String modelId) async {
    final notifier = _ref.read(shiftProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteSlideshow(String modelId) async {
    final notifier = _ref.read(slideshowProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteTable(String modelId) async {
    final notifier = _ref.read(tableProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteTableSection(String modelId) async {
    final notifier = _ref.read(tableSectionProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteTimecard(String modelId) async {
    final notifier = _ref.read(timecardProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  Future<void> deleteUser(String modelId) async {
    final notifier = _ref.read(userProvider.notifier);
    await notifier.delete(modelId, isInsertToPending: false);
  }

  // ========== Cascading Deletions ==========

  /// Delete a Category and all related data
  ///
  /// Cascades to:
  /// - CategoryDiscount (by category_id)
  /// - CategoryTax (by category_id)
  /// - PageItem (where type = category and id = categoryId)
  Future<void> deleteCategoryWithCascade(String categoryId) async {
    final categoryNotifier = _ref.read(categoryProvider.notifier);
    final categoryDiscountNotifier = _ref.read(
      categoryDiscountProvider.notifier,
    );
    final categoryTaxNotifier = _ref.read(categoryTaxProvider.notifier);
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);

    // Column names
    const cCategoryId = LocalCategoryDiscountRepositoryImpl.categoryId;

    // Delete main record
    await categoryNotifier.delete(categoryId, isInsertToPending: false);

    // Delete related records
    await categoryDiscountNotifier.deleteByColumnName(
      cCategoryId,
      categoryId,
      false,
    );
    await categoryTaxNotifier.deleteByColumnName(
      cCategoryId,
      categoryId,
      false,
    );

    // Delete page items
    final conditions = {
      LocalPageItemRepositoryImpl.pageItemableType: PolymorphicEnum.category,
      LocalPageItemRepositoryImpl.pageItemableId: categoryId,
    };
    await pageItemNotifier.deleteDbWithConditions(
      LocalPageItemRepositoryImpl.tableName,
      conditions,
      isInsertToPending: false,
    );
  }

  /// Delete a Discount and all related data
  ///
  /// Cascades to:
  /// - CategoryDiscount (by discount_id)
  /// - DiscountItem (by discount_id)
  /// - DiscountOutlet (by discount_id)
  Future<void> deleteDiscountWithCascade(String discountId) async {
    final discountNotifier = _ref.read(discountProvider.notifier);
    final categoryDiscountNotifier = _ref.read(
      categoryDiscountProvider.notifier,
    );
    final discountItemNotifier = _ref.read(discountItemProvider.notifier);
    final discountOutletNotifier = _ref.read(discountOutletProvider.notifier);

    // Column names
    const cDiscountId = LocalCategoryDiscountRepositoryImpl.discountId;

    // Delete main record
    await discountNotifier.delete(discountId, isInsertToPending: false);

    // Delete related records
    await categoryDiscountNotifier.deleteByColumnName(
      cDiscountId,
      discountId,
      false,
    );
    await discountItemNotifier.deleteByColumnName(
      cDiscountId,
      discountId,
      isInsertToPending: false,
    );
    await discountOutletNotifier.deleteByColumnName(
      cDiscountId,
      discountId,
      isInsertToPending: false,
    );
  }

  /// Delete an Item and all related data
  ///
  /// Cascades to:
  /// - DiscountItem (by item_id)
  /// - ItemModifier (by item_id)
  /// - ItemTax (by item_id)
  /// - PageItem (where type = item and id = itemId)
  Future<void> deleteItemWithCascade(String itemId) async {
    final itemNotifier = _ref.read(itemProvider.notifier);
    final discountItemNotifier = _ref.read(discountItemProvider.notifier);
    final itemModifierNotifier = _ref.read(itemModifierProvider.notifier);
    final itemTaxNotifier = _ref.read(itemTaxProvider.notifier);
    final pageItemNotifier = _ref.read(pageItemProvider.notifier);

    // Column names
    const cItemId = LocalItemModifierRepositoryImpl.itemId;

    // Delete main record
    await itemNotifier.delete(itemId, isInsertToPending: false);

    // Delete related records
    await discountItemNotifier.deleteByColumnName(
      cItemId,
      itemId,
      isInsertToPending: false,
    );
    await itemModifierNotifier.deleteByItemId(itemId, isInsertToPending: false);
    await itemTaxNotifier.deleteByColumnName(
      cItemId,
      itemId,
      isInsertToPending: false,
    );

    // Delete page items
    final conditions = {
      LocalPageItemRepositoryImpl.pageItemableType: PolymorphicEnum.item,
      LocalPageItemRepositoryImpl.pageItemableId: itemId,
    };
    await pageItemNotifier.deleteDbWithConditions(
      LocalPageItemRepositoryImpl.tableName,
      conditions,
      isInsertToPending: false,
    );
  }

  /// Delete a Modifier and all related data
  ///
  /// Cascades to:
  /// - ItemModifier (by modifier_id)
  Future<void> deleteModifierWithCascade(String modifierId) async {
    final modifierNotifier = _ref.read(modifierProvider.notifier);
    final itemModifierNotifier = _ref.read(itemModifierProvider.notifier);

    // Delete main record
    await modifierNotifier.delete(modifierId, isInsertToPending: false);

    // Delete related records - remove items matching this modifier
    final currentItems = _ref.read(itemModifierProvider).items;
    final itemsToDelete =
        currentItems.where((im) => im.modifierId == modifierId).toList();

    // Delete each relationship
    for (final item in itemsToDelete) {
      if (item.itemId != null) {
        // Just remove from state, deletion is already handled by the database
        itemModifierNotifier.remove(item.itemId!, modifierId);
      }
    }
  }

  /// Delete an OrderOption and all related data
  ///
  /// Cascades to:
  /// - OrderOptionTax (by order_option_id)
  Future<void> deleteOrderOptionWithCascade(String orderOptionId) async {
    final orderOptionNotifier = _ref.read(orderOptionProvider.notifier);
    final orderOptionTaxNotifier = _ref.read(orderOptionTaxProvider.notifier);

    // Column names
    const cOrderOptionId = LocalOrderOptionTaxRepositoryImpl.cOrderOptionId;

    // Delete main record
    await orderOptionNotifier.delete(orderOptionId, isInsertToPending: false);

    // Delete related records
    await orderOptionTaxNotifier.deleteByColumnName(
      cOrderOptionId,
      orderOptionId,
      isInsertToPending: false,
    );
  }

  /// Delete an Outlet and all related data
  ///
  /// Cascades to:
  /// - DiscountOutlet (by outlet_id)
  /// - OutletPaymentType (by outlet_id)
  /// - OutletTax (by outlet_id)
  Future<void> deleteOutletWithCascade(String outletId) async {
    final outletNotifier = _ref.read(outletProvider.notifier);
    final discountOutletNotifier = _ref.read(discountOutletProvider.notifier);
    final outletPaymentTypeNotifier = _ref.read(
      outletPaymentTypeProvider.notifier,
    );
    final outletTaxNotifier = _ref.read(outletTaxProvider.notifier);

    // Column names
    const cOutletId = LocalDiscountOutletRepositoryImpl.outletId;

    // Delete main record
    await outletNotifier.delete(outletId, isInsertToPending: false);

    // Delete related records
    await discountOutletNotifier.deleteByColumnName(
      cOutletId,
      outletId,
      isInsertToPending: false,
    );
    await outletPaymentTypeNotifier.deleteByColumnName(
      cOutletId,
      outletId,
      isInsertToPending: false,
    );
    await outletTaxNotifier.deleteByColumnName(
      cOutletId,
      outletId,
      isInsertToPending: false,
    );
  }

  /// Delete a PaymentType and all related data
  ///
  /// Cascades to:
  /// - OutletPaymentType (by payment_type_id)
  Future<void> deletePaymentTypeWithCascade(String paymentTypeId) async {
    final paymentTypeNotifier = _ref.read(paymentTypeProvider.notifier);
    final outletPaymentTypeNotifier = _ref.read(
      outletPaymentTypeProvider.notifier,
    );

    // Column names
    const cPaymentTypeId = LocalOutletPaymentTypeRepositoryImpl.paymentTypeId;

    // Delete main record
    await paymentTypeNotifier.delete(paymentTypeId, isInsertToPending: false);

    // Delete related records
    await outletPaymentTypeNotifier.deleteByColumnName(
      cPaymentTypeId,
      paymentTypeId,
      isInsertToPending: false,
    );
  }

  /// Delete a Tax and all related data
  ///
  /// Cascades to:
  /// - CategoryTax (by tax_id)
  /// - ItemTax (by tax_id)
  /// - OrderOptionTax (by tax_id)
  /// - OutletTax (by tax_id)
  Future<void> deleteTaxWithCascade(String taxId) async {
    final taxNotifier = _ref.read(taxProvider.notifier);
    final categoryTaxNotifier = _ref.read(categoryTaxProvider.notifier);
    final itemTaxNotifier = _ref.read(itemTaxProvider.notifier);
    final orderOptionTaxNotifier = _ref.read(orderOptionTaxProvider.notifier);
    final outletTaxNotifier = _ref.read(outletTaxProvider.notifier);

    // Column names
    const cTaxId = LocalCategoryTaxRepositoryImpl.taxId;

    // Delete main record
    await taxNotifier.delete(taxId, isInsertToPending: false);

    // Delete related records
    await categoryTaxNotifier.deleteByColumnName(cTaxId, taxId, false);
    await itemTaxNotifier.deleteByColumnName(
      cTaxId,
      taxId,
      isInsertToPending: false,
    );
    await orderOptionTaxNotifier.deleteByColumnName(
      cTaxId,
      taxId,
      isInsertToPending: false,
    );
    await outletTaxNotifier.deleteByColumnName(
      cTaxId,
      taxId,
      isInsertToPending: false,
    );
  }
}

/// Provider for ModelDeletionService
///
/// This service handles all cascading deletion logic across models
final modelDeletionServiceProvider = Provider<ModelDeletionService>((ref) {
  return ModelDeletionService(ref);
});
