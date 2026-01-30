import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/receipt_printer_utils.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer_platform_interface.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';

class OtherPrinterManager {
  OtherPrinterManager._privateConstructor();

  static OtherPrinterManager? _instance;

  static OtherPrinterManager get instance {
    _instance ??= OtherPrinterManager._privateConstructor();
    return _instance!;
  }

  final StreamController<List<PrinterModel>> _devicesstream =
      StreamController<List<PrinterModel>>.broadcast();

  Stream<List<PrinterModel>> get devicesStream => _devicesstream.stream;
  StreamSubscription? subscription;

  static String channelName = 'flutter_thermal_printer/events';
  EventChannel eventChannel = EventChannel(channelName);
  bool get isIos => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  // Stop scanning for BLE devices
  Future<void> stopScan({bool stopBle = true, bool stopUsb = true}) async {
    try {
      if (stopBle) {
        try {
          await subscription?.cancel();
          subscription = null;
        } catch (e) {
          log('Failed to cancel BLE subscription: $e');
        }
        await FlutterBluePlus.stopScan();
      }
      if (stopUsb) {
        try {
          if (_usbSubscription != null) {
            await _usbSubscription?.cancel();
            _usbSubscription = null;
          }
        } catch (e) {
          log('Failed to cancel USB subscription: $e');
          _usbSubscription = null;
        }
      }
    } catch (e) {
      log('Failed to stop scanning for devices $e');
    }
  }

  Future<bool> connect(PrinterModel device) async {
    if (device.connectionType == ConnectionTypeEnum.USB) {
      return await FlutterThermalPrinterPlatform.instance.connect(device);
    } else {
      try {
        bool isConnected = false;
        prints('CONNECTING TO ${device.address}');
        final bt = BluetoothDevice.fromId(device.address!);
        final btName = bt.platformName;
        if (!ReceiptPrinterUtils.isIminPrinter(btName)) {
          await bt.connect();
        }

        final stream = bt.connectionState.listen((event) {
          prints('CONNECTION STATE $event');
          if (event == BluetoothConnectionState.connected) {
            isConnected = true;
          }
        });
        await Future.delayed(const Duration(milliseconds: 200));
        await stream.cancel();
        return isConnected;
      } catch (e) {
        prints('ERRRRORRRRR $e');
        return false;
      }
    }
  }

  Future<bool> isConnected(PrinterModel device) async {
    if (device.connectionType == ConnectionTypeEnum.USB) {
      return await FlutterThermalPrinterPlatform.instance.isConnected(device);
    } else {
      try {
        final bt = BluetoothDevice.fromId(device.address!);
        return bt.isConnected;
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> disconnect(PrinterModel device) async {
    if (device.connectionType == ConnectionTypeEnum.BLE) {
      try {
        final bt = BluetoothDevice.fromId(device.address!);
        await bt.disconnect();
      } catch (e) {
        log('Failed to disconnect device');
      }
    }
  }

  // Print data to BLE device
  Future<void> printData(
    PrinterModel printer,
    List<int> bytes, {
    bool longData = false,
  }) async {
    if (printer.connectionType == ConnectionTypeEnum.USB) {
      try {
        prints(
          "USB PRINT: Starting print for ${printer.name} (${printer.address})",
        );
        prints("USB PRINT: Data length: ${bytes.length} bytes");
        prints(
          "USB PRINT: Calling FlutterThermalPrinterPlatform.instance.printText...",
        );
        await FlutterThermalPrinterPlatform.instance.printText(
          printer,
          Uint8List.fromList(bytes),
          path: printer.address,
        );
        prints("USB PRINT: Print command completed successfully");
      } catch (e) {
        prints("USB PRINT ERROR: Unable to Print Data - $e");
        log("FlutterThermalPrinter: Unable to Print Data $e");
        rethrow; // Re-throw the error so it can be caught by the calling code
      }
    } else {
      try {
        final device = BluetoothDevice.fromId(printer.address!);
        if (!device.isConnected) {
          log('Device is not connected, attempting to connect...');
          final btName = device.platformName;
          if (!ReceiptPrinterUtils.isIminPrinter(btName)) {
            await device.connect();
          }

          bool isConnected = false;
          final stream = device.connectionState.listen((event) {
            if (event == BluetoothConnectionState.connected) {
              isConnected = true;
            }
          });
          await Future.delayed(const Duration(seconds: 3));
          await stream.cancel();

          if (!isConnected) {
            log('Failed to connect to device before printing');
            return;
          }
        }

        final services = (await device.discoverServices()).skipWhile(
          (value) =>
              value.characteristics
                  .where((element) => element.properties.write)
                  .isEmpty,
        );

        BluetoothCharacteristic? writeCharacteristic;
        for (var service in services) {
          for (var characteristic in service.characteristics) {
            if (characteristic.properties.write) {
              writeCharacteristic = characteristic;
              break;
            }
          }
        }

        if (writeCharacteristic == null) {
          log('No write characteristic found');
          return;
        }

        // Reduce chunk size to avoid BLE packet size limitations
        // The error shows max size is 182 bytes, so we'll use 160 to be safe
        const maxChunkSize = 160;
        for (var i = 0; i < bytes.length; i += maxChunkSize) {
          final chunk = bytes.sublist(
            i,
            i + maxChunkSize > bytes.length ? bytes.length : i + maxChunkSize,
          );

          await writeCharacteristic.write(
            Uint8List.fromList(chunk),
            withoutResponse: true,
          );

          // Add a small delay between chunks to avoid overwhelming the BLE device
          await Future.delayed(const Duration(milliseconds: 20));
        }

        return;
      } catch (e) {
        log('Failed to print data to device $e');
      }
    }
  }

  StreamSubscription? refresher;

  final List<PrinterModel> _devices = [];
  StreamSubscription? _usbSubscription;

  // Get Printers from BT and USB
  Future<void> getPrinters({
    List<ConnectionTypeEnum> connectionTypes = const [
      ConnectionTypeEnum.BLE,
      ConnectionTypeEnum.USB,
    ],
    bool androidUsesFineLocation = false,
  }) async {
    if (connectionTypes.isEmpty) {
      throw Exception('No connection type provided');
    }

    if (connectionTypes.contains(ConnectionTypeEnum.USB)) {
      await _getUSBPrinters();
    }

    if (connectionTypes.contains(ConnectionTypeEnum.BLE)) {
      await _getBLEPrinters(androidUsesFineLocation);
    }
  }

  Future<void> _getUSBPrinters() async {
    try {
      final devices =
          await FlutterThermalPrinterPlatform.instance.startUsbScan();

      List<PrinterModel> usbPrinters = [];
      for (var map in devices) {
        final printer = PrinterModel(
          vendorId: map['vendorId'].toString(),
          productId: map['productId'].toString(),
          name: map['name'],
          connectionType: ConnectionTypeEnum.USB,
          address: map['vendorId'].toString(),
          isConnected: map['connected'] ?? false,
        );
        // Don't override the connection status - trust the Android response
        // printer.isConnected = await FlutterThermalPrinterPlatform.instance
        //     .isConnected(printer);
        usbPrinters.add(printer);
      }

      _devices.addAll(usbPrinters);

      // Safely handle subscription cancellation
      if (_usbSubscription != null) {
        try {
          await _usbSubscription?.cancel();
        } catch (e) {
          log("Error cancelling USB subscription: $e");
          // Set to null even if cancellation fails
          _usbSubscription = null;
        }
      }

      // Create new subscription
      try {
        _usbSubscription = eventChannel.receiveBroadcastStream().listen(
          (event) {
            final map = Map<String, dynamic>.from(event);
            _updateOrAddPrinter(
              PrinterModel(
                vendorId: map['vendorId'].toString(),
                productId: map['productId'].toString(),
                name: map['name'],
                connectionType: ConnectionTypeEnum.USB,
                address: map['vendorId'].toString(),
                isConnected: map['connected'] ?? false,
              ),
            );
          },
          onError: (error) {
            log("Error in USB event stream: $error");
          },
        );
      } catch (e) {
        log("Failed to create USB event subscription: $e");
      }

      sortDevices();
    } catch (e) {
      log("$e [USB Connection]");
    }
  }

  Future<void> _getBLEPrinters(bool androidUsesFineLocation) async {
    try {
      subscription?.cancel();
      subscription = null;
      if (isIos == false) {
        if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
          await FlutterBluePlus.turnOn();
        }
      } else {
        BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
        if (state == BluetoothAdapterState.off) {
          log('Bluetooth is off, turning on.');
          return;
        }
      }

      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        androidUsesFineLocation: androidUsesFineLocation,
      );

      // Get system devices
      final systemDevices = await _getBLESystemDevices();
      _devices.addAll(systemDevices);

      // Get bonded devices (Android only)
      if (Platform.isAndroid) {
        final bondedDevices = await _getBLEBondedDevices();
        _devices.addAll(bondedDevices);
      }

      sortDevices();

      // Listen to scan results
      subscription = FlutterBluePlus.scanResults.listen((result) {
        final devices =
            result
                .map((e) {
                  return PrinterModel(
                    address: e.device.remoteId.str,
                    name: e.device.platformName,
                    connectionType: ConnectionTypeEnum.BLE,
                    isConnected: e.device.isConnected,
                  );
                })
                .where((device) => device.name?.isNotEmpty ?? false)
                .toList();

        for (var device in devices) {
          _updateOrAddPrinter(device);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PrinterModel>> _getBLESystemDevices() async {
    return (await FlutterBluePlus.systemDevices([]))
        .map(
          (device) => PrinterModel(
            address: device.remoteId.str,
            name: device.platformName,
            connectionType: ConnectionTypeEnum.BLE,
            isConnected: device.isConnected,
          ),
        )
        .toList();
  }

  Future<List<PrinterModel>> _getBLEBondedDevices() async {
    return (await FlutterBluePlus.bondedDevices)
        .map(
          (device) => PrinterModel(
            address: device.remoteId.str,
            name: device.platformName,
            connectionType: ConnectionTypeEnum.BLE,
            isConnected: device.isConnected,
          ),
        )
        .toList();
  }

  void _updateOrAddPrinter(PrinterModel printer) {
    final index = _devices.indexWhere(
      (device) => device.address == printer.address,
    );
    if (index == -1) {
      _devices.add(printer);
    } else {
      _devices[index] = printer;
    }
    sortDevices();
  }

  void sortDevices() {
    _devices.removeWhere(
      (element) => element.name == null || element.name == '',
    );
    // remove items having same vendorId
    Set<String> seen = {};
    _devices.retainWhere((element) {
      String uniqueKey = '${element.vendorId}_${element.address}';
      if (seen.contains(uniqueKey)) {
        return false; // Remove duplicate
      } else {
        seen.add(uniqueKey); // Mark as seen
        return true; // Keep
      }
    });
    _devicesstream.add(_devices);
  }

  Future<void> turnOnBluetooth() async {
    await FlutterBluePlus.turnOn();
  }

  Stream<bool> get isBleTurnedOnStream {
    return FlutterBluePlus.adapterState.map((event) {
      return event == BluetoothAdapterState.on;
    });
  }

  Future<bool> requestUsbPermission(PrinterModel device) async {
    return await FlutterThermalPrinterPlatform.instance.requestUsbPermission(
      device,
    );
  }
}
