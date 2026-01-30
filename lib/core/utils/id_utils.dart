import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:ulid/ulid.dart';

/// ID generation utility functions
class IdUtils {
  /// Generate a UUID
  static String generateUUID() {
    return Ulid().toString();
  }

  /// Generate a UUID for receipt
  static Future<String> generateReceiptId() async {
    final posDeviceFacade = ServiceLocator.get<DeviceFacade>();
    final posDeviceModel = await posDeviceFacade.getLatestDeviceModel();
    String codePosDevice = '0.00';
    int orderNumber = 0;

    if (posDeviceModel.id != null &&
        posDeviceModel.code != null &&
        posDeviceModel.nextRnReceipt != null) {
      codePosDevice = posDeviceModel.code!;
      orderNumber = posDeviceModel.nextRnReceipt!;

      // update nextRnNumber
      final updateDevice = posDeviceModel.copyWith(
        nextRnReceipt: posDeviceModel.nextRnReceipt! + 1,
      );
      await posDeviceFacade.update(updateDevice);

      return 'INV$codePosDevice-${formatWithLeadingZeros(orderNumber)}';
    }
    return 'NULL ERROR';
  }

  static String formatWithLeadingZeros(int number) {
    return number.toString().padLeft(6, '0');
  }

  /// Generate a hash ID for an item with variants and modifiers
  static String generateHashId(
    String? variantId,
    List<String> modifierOptionIds,
    String comments,
    String itemId, {
    double? qty,
    required double? cost,
    required double? variantPrice,
  }) {
    // Early buffer for faster string concatenation
    final StringBuffer buffer = StringBuffer();

    // Sort modifierOptionIds in-place
    modifierOptionIds.sort();

    if (variantId != null) buffer.write(variantId);

    for (final id in modifierOptionIds) {
      buffer.write(id);
    }

    buffer
      ..write(comments)
      ..write(itemId)
      ..write(cost?.toStringAsFixed(2) ?? '')
      ..write(variantPrice?.toStringAsFixed(2) ?? '')
      ..write(qty?.toStringAsFixed(3) ?? '');

    // Generate MD5 hash
    final hash = md5.convert(utf8.encode(buffer.toString())).toString();

    return hash.length >= 26 ? hash.substring(0, 26) : hash;
  }
}
