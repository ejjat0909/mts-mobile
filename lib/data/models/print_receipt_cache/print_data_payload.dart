import 'package:mts/data/models/department_printer/department_printer_model.dart';
import 'package:mts/data/models/order_option/order_option_model.dart';
import 'package:mts/data/models/predefined_order/predefined_order_model.dart';
import 'package:mts/data/models/printer_setting/printer_setting_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/sale_item/sale_item_model.dart';
import 'package:mts/data/models/sale_modifier/sale_modifier_model.dart';
import 'package:mts/data/models/sale_modifier_option/sale_modifier_option_model.dart';

class PrintDataPayload {
  static const String modelName = 'PrintDataPayload';

  SaleModel? saleModel;
  List<SaleItemModel>? listSaleItems;
  List<SaleModifierModel>? listSM;
  List<SaleModifierOptionModel>? listSMO;
  OrderOptionModel? orderOptionModel;
  PrinterSettingModel? printerSettingModel;
  DepartmentPrinterModel? dpm;
  PredefinedOrderModel? predefinedOrderModel;

  PrintDataPayload({
    this.saleModel,
    this.listSaleItems,
    this.listSM,
    this.listSMO,
    this.orderOptionModel,
    this.printerSettingModel,
    this.dpm,
    this.predefinedOrderModel,
  });

  PrintDataPayload.fromJson(Map<String, dynamic> json) {
    saleModel =
        json['saleModel'] != null
            ? SaleModel.fromJson(json['saleModel'])
            : null;
    if (json['listSaleItems'] != null) {
      listSaleItems = [];
      json['listSaleItems'].forEach((v) {
        listSaleItems!.add(SaleItemModel.fromJson(v));
      });
    }
    if (json['listSM'] != null) {
      listSM = [];
      json['listSM'].forEach((v) {
        listSM!.add(SaleModifierModel.fromJson(v));
      });
    }
    if (json['listSMO'] != null) {
      listSMO = [];
      json['listSMO'].forEach((v) {
        listSMO!.add(SaleModifierOptionModel.fromJson(v));
      });
    }
    orderOptionModel =
        json['orderOptionModel'] != null
            ? OrderOptionModel.fromJson(json['orderOptionModel'])
            : null;
    printerSettingModel =
        json['printerSettingModel'] != null
            ? PrinterSettingModel.fromJson(json['printerSettingModel'])
            : null;

    dpm =
        json['dpm'] != null
            ? DepartmentPrinterModel.fromJson(json['dpm'])
            : null;

    predefinedOrderModel =
        json['predefinedOrderModel'] != null
            ? PredefinedOrderModel.fromJson(json['predefinedOrderModel'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (saleModel != null) {
      data['saleModel'] = saleModel!.toJson();
    }
    if (listSaleItems != null) {
      data['listSaleItems'] = listSaleItems!.map((v) => v.toJson()).toList();
    }
    if (listSM != null) {
      data['listSM'] = listSM!.map((v) => v.toJson()).toList();
    }
    if (listSMO != null) {
      data['listSMO'] = listSMO!.map((v) => v.toJson()).toList();
    }
    if (orderOptionModel != null) {
      data['orderOptionModel'] = orderOptionModel!.toJson();
    }
    if (printerSettingModel != null) {
      data['printerSettingModel'] = printerSettingModel!.toJson();
    }
    if (dpm != null) {
      data['dpm'] = dpm!.toJson();
    }
    if (predefinedOrderModel != null) {
      data['predefinedOrderModel'] = predefinedOrderModel!.toJson();
    }
    return data;
  }

  PrintDataPayload copyWith({
    SaleModel? saleModel,
    List<SaleItemModel>? listSaleItems,
    List<SaleModifierModel>? listSM,
    List<SaleModifierOptionModel>? listSMO,
    OrderOptionModel? orderOptionModel,
    PrinterSettingModel? printerSettingModel,
    DepartmentPrinterModel? dpm,
    PredefinedOrderModel? predefinedOrderModel,
  }) {
    return PrintDataPayload(
      saleModel: saleModel ?? this.saleModel,
      listSaleItems: listSaleItems ?? this.listSaleItems,
      listSM: listSM ?? this.listSM,
      listSMO: listSMO ?? this.listSMO,
      orderOptionModel: orderOptionModel ?? this.orderOptionModel,
      printerSettingModel: printerSettingModel ?? this.printerSettingModel,
      dpm: dpm ?? this.dpm,
      predefinedOrderModel: predefinedOrderModel ?? this.predefinedOrderModel,
    );
  }
}
