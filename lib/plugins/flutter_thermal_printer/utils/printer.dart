// ignore_for_file: constant_identifier_names

 

import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';

class PrinterModel {
  String? address;
  String? name;
  ConnectionTypeEnum? connectionType;
  bool? isConnected;
  String? vendorId;
  String? productId;

  PrinterModel({
    this.address,
    this.name,
    this.connectionType,
    this.isConnected,
    this.vendorId,
    this.productId,
  });

  PrinterModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    name = json['connectionType'] == 'BLE' ? json['platformName'] : json['name'];
    connectionType = _getConnectionTypeFromString(json['connectionType']);
    isConnected = json['isConnected'];
    vendorId = json['vendorId'];
    productId = json['productId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    if (connectionType == ConnectionTypeEnum.BLE) {
      data['platformName'] = name;
    } else {
      data['name'] = name;
    }
    data['connectionType'] = connectionTypeString;
    data['isConnected'] = isConnected;
    data['vendorId'] = vendorId;
    data['productId'] = productId;
    return data;
  }

  // copyWith
  PrinterModel copyWith({
    String? address,
    String? name,
    ConnectionTypeEnum? connectionType,
    bool? isConnected,
    String? vendorId,
    String? productId,
  }) {
    return PrinterModel(
      address: address ?? this.address,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
    );
  } 

  ConnectionTypeEnum _getConnectionTypeFromString(String? connectionType) {
    switch (connectionType) {
      case 'BLE':
        return ConnectionTypeEnum.BLE;
      case 'USB':
        return ConnectionTypeEnum.USB;
      case 'NETWORK':
        return ConnectionTypeEnum.NETWORK;
      default:
        throw ArgumentError('Invalid connection type');
    }
  }
}

enum ConnectionTypeEnum {
  BLE,
  USB,
  NETWORK,
}

extension PrinterExtension on PrinterModel {
  String get connectionTypeString {
    switch (connectionType) {
      case ConnectionTypeEnum.BLE:
        return 'BLE';
      case ConnectionTypeEnum.USB:
        return 'USB';
      case ConnectionTypeEnum.NETWORK:
        return 'NETWORK';
      default:
        return '';
    }
  }

  Stream<BluetoothConnectionState> get connectionState {
    if (connectionType != ConnectionTypeEnum.BLE) {
      throw UnsupportedError('Only BLE printers are supported');
    }
    if (address == null) {
      throw ArgumentError('Address is required for BLE printers');
    }
    return BluetoothDevice.fromId(address!).connectionState;
  }
}
