import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/di/service_locator.dart';
import 'package:mts/core/services/barcode_scanner_service.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/data/models/item/item_model.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/providers/barcode_scanner/barcode_scanner_state.dart';
import 'package:mts/providers/item/item_providers.dart';

/// Notifier for handling barcode scanner events and item lookup
class BarcodeScannerNotifier extends StateNotifier<BarcodeScannerState> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  StreamSubscription<String>? _barcodeSubscription;
  final Ref _ref;

  // Track last processed barcode to prevent duplicates
  String? _lastProcessedBarcode;
  DateTime? _lastProcessedTime;

  // Callback functions for different screens
  Function(List<SaleModel>)? _onOrdersFound;

  BarcodeScannerNotifier({required Ref ref})
    : _ref = ref,
      super(const BarcodeScannerState());

  // Public getters
  ItemModel? get scannedItem => state.scannedItem;
  bool get isProcessing => state.isProcessing;
  String? get errorMessage => state.errorMessage;
  String? get currentActiveScreen => state.currentActiveScreen;
  String? get salesScreenBarcode => state.salesScreenBarcode;
  String? get openOrderBodyBarcode => state.openOrderBodyBarcode;
  String? get saveOrderDialogueBarcode => state.saveOrderDialogueBarcode;
  String? get saveOrderCustomBarcode => state.saveOrderCustomBarcode;
  String? get editTableDetailDialogueBarcode =>
      state.editTableDetailDialogueBarcode;
  String? get tablesBarcode => state.tablesBarcode;
  String? get editTablesBarcode => state.editTablesBarcode;

  /// Dispose previous barcode scanner subscription
  void _disposePreviousSubscription() {
    if (_barcodeSubscription != null) {
      prints(
        'Disposing previous barcode scanner subscription for: ${state.currentActiveScreen}',
      );
      _barcodeSubscription?.cancel();
      _barcodeSubscription = null;
    }
    _clearError();

    // Clear callbacks
    _onOrdersFound = null;

    // Clear screen-specific barcodes
    state = state.copyWith(
      salesScreenBarcode: null,
      openOrderBodyBarcode: null,
      saveOrderDialogueBarcode: null,
      saveOrderCustomBarcode: null,
      editTableDetailDialogueBarcode: null,
      tablesBarcode: null,
      editTablesBarcode: null,
    );
  }

  /// Initialize the barcode scanner notifier for different screens
  void initializeForSalesScreen() {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForSalesScreen();
    state = state.copyWith(currentActiveScreen: 'SalesScreen');

    // Listen to barcode events
    _barcodeSubscription = _scannerService.barcodeStreamForSalesScreen.listen(
      _handleBarcodeScanned,
      onError: (error) {
        prints('Barcode stream error: $error BarcodeScannerNotifier');
        _setError('Barcode scanner error: $error');
      },
    );

    prints(
      'Barcode Scanner Notifier initialized for Sales Screen BarcodeScannerNotifier',
    );
  }

  void initializeForOpenOrderBody({Function(List<SaleModel>)? onOrdersFound}) {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForOpenOrderBody();
    state = state.copyWith(currentActiveScreen: 'OpenOrderBody');
    _onOrdersFound = onOrdersFound;

    // Listen to barcode events
    _barcodeSubscription = _scannerService.barcodeStreamForOpenOrderBody.listen(
      _handleBarcodeScanned,
      onError: (error) {
        prints('Barcode stream error: $error');
        _setError('Barcode scanner error: $error');
      },
    );

    prints('Barcode Scanner Notifier initialized for Open Order Body');
  }

  void initializeForSaveOrderDialogue() {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForSaveOrderDialogue();
    state = state.copyWith(currentActiveScreen: 'SaveOrderDialogue');

    // Listen to barcode events
    _barcodeSubscription = _scannerService.barcodeStreamForSaveOrderDialogue
        .listen(
          _handleBarcodeScanned,
          onError: (error) {
            prints('Barcode stream error: $error');
            _setError('Barcode scanner error: $error');
          },
        );

    prints('Barcode Scanner Notifier initialized for Save Order Dialogue');
  }

  void initializeForSaveOrderCustom() {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForSaveOrderCustom();
    state = state.copyWith(currentActiveScreen: 'SaveOrderCustom');

    // Listen to barcode events
    _barcodeSubscription = _scannerService.barcodeStreamForSaveOrderCustom
        .listen(
          _handleBarcodeScanned,
          onError: (error) {
            prints('Barcode stream error: $error');
            _setError('Barcode scanner error: $error');
          },
        );

    prints('Barcode Scanner Notifier initialized for Save Order Custom');
  }

  void initializeForEditTableDetailDialogue() {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForEditTableDetailDialogue();
    state = state.copyWith(currentActiveScreen: 'EditTableDetailDialogue');

    // Listen to barcode events
    _barcodeSubscription = _scannerService
        .barcodeStreamForEditTableDetailDialogue
        .listen(
          _handleBarcodeScanned,
          onError: (error) {
            prints('Barcode stream error: $error');
            _setError('Barcode scanner error: $error');
          },
        );

    prints(
      'Barcode Scanner Notifier initialized for Edit Table Detail Dialogue',
    );
  }

  void initializeForTables() {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForTables();
    state = state.copyWith(currentActiveScreen: 'Tables');

    // Listen to barcode events
    _barcodeSubscription = _scannerService.barcodeStreamForTables.listen(
      _handleBarcodeScanned,
      onError: (error) {
        prints('Barcode stream error: $error');
        _setError('Barcode scanner error: $error');
      },
    );

    prints('Barcode Scanner Notifier initialized for Tables');
  }

  void initializeForEditTables() {
    // Dispose previous subscription if any
    _disposePreviousSubscription();

    _scannerService.initializeForEditTables();
    state = state.copyWith(currentActiveScreen: 'EditTables');

    // Listen to barcode events
    _barcodeSubscription = _scannerService.barcodeStreamForEditTables.listen(
      _handleBarcodeScanned,
      onError: (error) {
        prints('Barcode stream error: $error');
        _setError('Barcode scanner error: $error');
      },
    );

    prints('Barcode Scanner Notifier initialized for Edit Tables');
  }

  /// Dispose barcode scanner when leaving to payment screen
  void disposeScanner() {
    _disposePreviousSubscription();
    state = state.copyWith(
      currentActiveScreen: null,
      scannedItem: null,
      isProcessing: false,
    );

    prints('Barcode Scanner Notifier disposed for Payment Screen');
  }

  /// Handle scanned barcode based on current active screen
  void _handleBarcodeScanned(String barcode) async {
    // Extract multiple barcodes from concatenated string and process each one
    final extractedBarcodes = _extractMultipleBarcodes(barcode);

    for (final extractedBarcode in extractedBarcodes) {
      await _processBarcodeForCurrentScreen(extractedBarcode, barcode);

      // Small delay between processing multiple barcodes to prevent overwhelming the system
      if (extractedBarcodes.length > 1) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  /// Process barcode based on the current active screen
  Future<void> _processBarcodeForCurrentScreen(
    String cleanedBarcode,
    String originalBarcode,
  ) async {
    // Check for duplicate processing within a short time window (50ms)
    final now = DateTime.now();
    if (_lastProcessedBarcode == cleanedBarcode &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inMilliseconds < 50) {
      prints('Duplicate barcode detected, skipping: $cleanedBarcode');
      return;
    }

    prints(
      'Processing barcode: $cleanedBarcode for screen: ${state.currentActiveScreen}${cleanedBarcode != originalBarcode ? ' (cleaned from: $originalBarcode)' : ''}',
    );

    // Update tracking variables
    _lastProcessedBarcode = cleanedBarcode;
    _lastProcessedTime = now;

    _setProcessing(true);
    _clearError();
    //  _lastScannedBarcode = cleanedBarcode;

    // Handle barcode based on current active screen
    switch (state.currentActiveScreen) {
      case 'SalesScreen':
        await _handleBarcodeForSalesScreen(cleanedBarcode);
        break;
      case 'OpenOrderBody':
        await _handleBarcodeForOpenOrderBody(cleanedBarcode);
        break;
      case 'SaveOrderDialogue':
        await _handleBarcodeForSaveOrderDialogue(cleanedBarcode);
        break;
      case 'SaveOrderCustom':
        await _handleBarcodeForSaveOrderCustom(cleanedBarcode);
        break;
      case 'EditTableDetailDialogue':
        await _handleBarcodeForEditTableDetailDialogue(cleanedBarcode);
        break;
      case 'Tables':
        await _handleBarcodeForTables(cleanedBarcode);
        break;
      case 'EditTables':
        await _handleBarcodeForEditTables(cleanedBarcode);
        break;
      default:
        prints(
          'Unknown screen: ${state.currentActiveScreen}, defaulting to sales screen behavior',
        );
        await _handleBarcodeForSalesScreen(cleanedBarcode);
    }

    _setProcessing(false);
  }

  /// Handle barcode for Sales Screen (search and add items)
  Future<void> _handleBarcodeForSalesScreen(String barcode) async {
    prints(
      'Handling barcode for Sales Screen: $barcode - delegating to sales screen logic',
    );

    // Set the barcode for sales screen specifically and clear others
    state = state.copyWith(salesScreenBarcode: barcode);
    _clearAllScreenBarcodesExcept('SalesScreen');

    // The actual logic is implemented in sales_screen.dart
    // This method just ensures the barcode is processed for the sales screen context
    // The sales screen will listen to the salesScreenBarcode changes and handle the logic
  }

  /// Handle barcode for Open Order Body (search orders)
  Future<void> _handleBarcodeForOpenOrderBody(String barcode) async {
    prints(
      'Handling barcode for Open Order Body: $barcode - delegating to open order body logic',
    );

    // Set the barcode for open order body specifically and clear others
    state = state.copyWith(openOrderBodyBarcode: barcode);
    _clearAllScreenBarcodesExcept('OpenOrderBody');

    // The actual logic is implemented in open_order_body.dart
    // This method just ensures the barcode is processed for the open order body context
    // The open order body will listen to the openOrderBodyBarcode changes and handle the logic

    // Call the callback if provided
    if (_onOrdersFound != null) {
      // You can still use callbacks if needed, but the main logic is in the screen
      // _onOrdersFound!(matchingOrders);
    }
  }

  /// Handle barcode for Save Order Dialogue
  Future<void> _handleBarcodeForSaveOrderDialogue(String barcode) async {
    prints(
      'Handling barcode for Save Order Dialogue: $barcode - delegating to dialogue logic',
    );

    // Set the barcode for save order dialogue specifically and clear others
    state = state.copyWith(saveOrderDialogueBarcode: barcode);
    _clearAllScreenBarcodesExcept('SaveOrderDialogue');

    // The actual logic is implemented in the respective dialogue component
    // This method just ensures the barcode is processed for the save order dialogue context
  }

  /// Handle barcode for Save Order Custom
  Future<void> _handleBarcodeForSaveOrderCustom(String barcode) async {
    prints(
      'Handling barcode for Save Order Custom: $barcode - delegating to custom logic',
    );

    // Set the barcode for save order custom specifically and clear others
    state = state.copyWith(saveOrderCustomBarcode: barcode);
    _clearAllScreenBarcodesExcept('SaveOrderCustom');

    // The actual logic is implemented in the respective custom component
    // This method just ensures the barcode is processed for the save order custom context
  }

  /// Handle barcode for Edit Table Detail Dialogue
  Future<void> _handleBarcodeForEditTableDetailDialogue(String barcode) async {
    prints(
      'Handling barcode for Edit Table Detail Dialogue: $barcode - delegating to dialogue logic',
    );

    // Set the barcode for edit table detail dialogue specifically and clear others
    state = state.copyWith(editTableDetailDialogueBarcode: barcode);
    _clearAllScreenBarcodesExcept('EditTableDetailDialogue');

    // The actual logic is implemented in the respective dialogue component
    // This method just ensures the barcode is processed for the edit table detail dialogue context
  }

  /// Handle barcode for Tables
  Future<void> _handleBarcodeForTables(String barcode) async {
    prints(
      'Handling barcode for Tables: $barcode - delegating to tables logic',
    );

    // Set the barcode for tables specifically and clear others
    state = state.copyWith(tablesBarcode: barcode);
    _clearAllScreenBarcodesExcept('Tables');

    // The actual logic is implemented in the respective tables component
    // This method just ensures the barcode is processed for the tables context
  }

  /// Handle barcode for Edit Tables
  Future<void> _handleBarcodeForEditTables(String barcode) async {
    prints(
      'Handling barcode for Edit Tables: $barcode - delegating to edit tables logic',
    );

    // Set the barcode for edit tables specifically and clear others
    state = state.copyWith(editTablesBarcode: barcode);
    _clearAllScreenBarcodesExcept('EditTables');

    // The actual logic is implemented in the respective edit tables component
    // This method just ensures the barcode is processed for the edit tables context
  }

  /// Find single item by exact barcode match
  ItemModel? findItemByBarcode(String barcode) {
    try {
      final itemNotifier = ServiceLocator.get<ItemNotifier>();
      final items = itemNotifier.getListItems;

      final searchTerm = barcode.toLowerCase().trim();

      // Find first exact match using where method
      final exactMatch =
          items.where((item) {
            if (item.barcode == null) return false;
            final itemBarcode = item.barcode!.toLowerCase().trim();
            return itemBarcode == searchTerm;
          }).firstOrNull;

      prints(
        'Found exact match for barcode: $barcode - ${exactMatch?.name ?? 'None'}',
      );

      return exactMatch;
    } catch (error) {
      prints('Error finding item by barcode: $error');
      return null;
    }
  }

  /// Find items by barcode (exact and partial matches)
  List<ItemModel> findItemsByBarcode(String barcode) {
    try {
      final itemNotifier = ServiceLocator.get<ItemNotifier>();
      final items = itemNotifier.getListItems;

      final searchTerm = barcode.toLowerCase().trim();

      // Find all matches (exact and partial) in one go
      final allMatches =
          items
              .where(
                (item) =>
                    (item.barcode?.toLowerCase().trim().contains(searchTerm) ??
                        false),
              )
              .toList();

      prints('Found ${allMatches.length} items matching barcode: $barcode');

      return allMatches;
    } catch (error) {
      prints('Error finding items by barcode: $error');
      return [];
    }
  }

  /// Find item and variant option by variant barcode
  /// Returns a map with 'item' and 'variantOption' keys if found
  Map<String, dynamic>? findItemByVariantBarcode(String barcode) {
    try {
      final itemNotifier = ServiceLocator.get<ItemNotifier>();
      final items = itemNotifier.getListItems;

      final searchTerm = barcode.toLowerCase().trim();

      for (final item in items) {
        // Skip items without variant options
        if (item.variantOptionJson == null || item.variantOptionJson!.isEmpty) {
          continue;
        }

        // Get variant options for this item
        final variantOptions = itemNotifier.getListVariantOptionByItemId(
          item.id!,
        );

        // Search for matching barcode in variant options
        for (final variantOption in variantOptions) {
          if (variantOption.barcode != null &&
              variantOption.barcode!.toLowerCase().trim() == searchTerm) {
            prints(
              'Found variant barcode match: ${item.name} - ${variantOption.name}',
            );

            return {'item': item, 'variantOption': variantOption};
          }
        }
      }

      prints('No variant barcode match found for: $barcode');

      return null;
    } catch (error) {
      prints('Error finding item by variant barcode: $error');
      return null;
    }
  }

  /// Set processing state
  void _setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  /// Set error message
  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  /// Clear error message
  void _clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Clear scanned item and all screen-specific barcodes
  void clearScannedItem() {
    state = state.copyWith(scannedItem: null, errorMessage: null);

    // Clear all screen-specific barcodes
    _clearAllScreenBarcodesExcept(null);
  }

  /// Find orders by predefined order name or table name (case-insensitive)
  List<SaleModel> findOrdersByNameOrTable(
    String barcode,
    List<SaleModel> orders,
  ) {
    try {
      final searchTerm = barcode.toLowerCase().trim();

      if (searchTerm.isEmpty) {
        return [];
      }

      // Search for orders with matching name or table name (case-insensitive)
      final matchingOrders =
          orders.where((order) {
            final orderName = order.name?.toLowerCase().trim() ?? '';
            final tableName = order.tableName?.toLowerCase().trim() ?? '';

            return orderName == searchTerm || tableName == searchTerm;
          }).toList();

      prints(
        'Found ${matchingOrders.length} orders matching barcode: $barcode',
      );

      return matchingOrders;
    } catch (error) {
      prints('Error finding orders by name or table: $error');
      return [];
    }
  }

  /// Extract multiple barcodes from a concatenated string
  List<String> _extractMultipleBarcodes(String rawBarcode) {
    if (rawBarcode.length < 2) {
      return [rawBarcode];
    }

    prints(
      'Extracting barcodes from: $rawBarcode (length: ${rawBarcode.length})',
    );

    // For extreme concatenations like "A001A001A001A001A001A001A001A001A001"
    // Try to find the repeating pattern and extract individual barcodes
    for (int patternLength = 3; patternLength <= 12; patternLength++) {
      if (patternLength > rawBarcode.length) break;

      final pattern = rawBarcode.substring(0, patternLength);

      // Check if this pattern repeats throughout the string
      if (rawBarcode.length % patternLength == 0) {
        final expectedRepetitions = rawBarcode.length ~/ patternLength;
        final reconstructed = pattern * expectedRepetitions;

        if (reconstructed == rawBarcode && expectedRepetitions > 1) {
          prints(
            'Found repeating pattern: $pattern ($expectedRepetitions times)',
          );

          // Return multiple instances of the same barcode
          return List.filled(expectedRepetitions, pattern);
        }
      }
    }

    // If no repeating pattern found, try to clean as a single barcode
    final cleaned = _cleanConcatenatedBarcode(rawBarcode);
    return [cleaned];
  }

  /// Clean concatenated barcodes (e.g., "A001A001A001..." -> "A001", "01A001" -> "A001")
  String _cleanConcatenatedBarcode(String rawBarcode) {
    if (rawBarcode.length < 2) {
      return rawBarcode; // Too short to be concatenated
    }

    prints('Cleaning barcode: $rawBarcode (length: ${rawBarcode.length})');

    // Handle extreme concatenations (like A001A001A001A001A001A001A001A001A001)
    // Check if the barcode is a concatenation of identical parts
    for (int i = 3; i <= rawBarcode.length ~/ 2; i++) {
      final firstPart = rawBarcode.substring(0, i);

      // Check if the entire string can be made by repeating this part
      if (rawBarcode.length % firstPart.length == 0) {
        final repetitions = rawBarcode.length ~/ firstPart.length;
        final reconstructed = firstPart * repetitions;

        if (reconstructed == rawBarcode && repetitions > 1) {
          prints(
            'Detected concatenated barcode ($repetitions repetitions): $rawBarcode -> $firstPart',
          );
          return firstPart;
        }
      }
    }

    // Check for common concatenation patterns like "01A001" where "01" might be a prefix
    // Look for patterns where the barcode might have a short prefix followed by the actual barcode
    // BUT: Don't truncate valid EAN-13 barcodes (13 digits) or valid Code 128 barcodes
    if (rawBarcode.length >= 6) {
      // Skip prefix removal for potential EAN-13 barcodes (13 digits, all numeric)
      final ean13Pattern = RegExp(r'^\d{13}$');
      if (ean13Pattern.hasMatch(rawBarcode)) {
        prints(
          'Detected potential EAN-13 barcode, skipping prefix removal: $rawBarcode',
        );
        return rawBarcode; // Don't truncate EAN-13 barcodes
      }

      // Don't remove prefixes from valid Code 128 barcodes (4-50 chars, alphanumeric + special chars)
      final code128Pattern = RegExp(
        r'^[A-Za-z0-9\-_\.\s\+\*\$\%\/\(\)]{4,50}$',
      );
      if (code128Pattern.hasMatch(rawBarcode)) {
        prints(
          'Detected valid Code 128 barcode, skipping prefix removal: $rawBarcode',
        );
        return rawBarcode;
      }

      // Try different split points to find the actual barcode (only for non-EAN-13 and non-Code 128)
      for (int splitPoint = 2; splitPoint <= 4; splitPoint++) {
        if (splitPoint >= rawBarcode.length) break;

        final possibleBarcode = rawBarcode.substring(splitPoint);

        // Check if this looks like a valid barcode (alphanumeric, reasonable length)
        if (possibleBarcode.length >= 3 && possibleBarcode.length <= 20) {
          final alphanumericPattern = RegExp(r'^[A-Za-z0-9]+$');
          if (alphanumericPattern.hasMatch(possibleBarcode)) {
            // Additional check: see if removing the prefix gives us a more "standard" looking barcode
            final prefix = rawBarcode.substring(0, splitPoint);
            if (prefix.length <= 3 && RegExp(r'^\d+$').hasMatch(prefix)) {
              prints(
                'Detected prefixed barcode: $rawBarcode -> $possibleBarcode (removed prefix: $prefix)',
              );
              return possibleBarcode;
            }
          }
        }
      }
    }

    // If no pattern detected but the barcode is very long, try to extract a reasonable part
    if (rawBarcode.length > 20) {
      // Look for the first reasonable barcode-like substring
      for (int start = 0; start <= rawBarcode.length - 4; start++) {
        for (
          int length = 4;
          length <= 12 && start + length <= rawBarcode.length;
          length++
        ) {
          final candidate = rawBarcode.substring(start, start + length);
          final alphanumericPattern = RegExp(r'^[A-Za-z0-9]+$');

          if (alphanumericPattern.hasMatch(candidate)) {
            // Check if this candidate appears multiple times (indicating it's the repeated part)
            final candidateCount = rawBarcode.split(candidate).length - 1;
            if (candidateCount > 1) {
              prints(
                'Detected repeated pattern in long barcode: $rawBarcode -> $candidate (appears $candidateCount times)',
              );
              return candidate;
            }
          }
        }
      }

      // If no repeated pattern found, take the first reasonable part
      final firstPart = rawBarcode.substring(0, 8); // Take first 8 characters
      prints(
        'Long barcode detected, taking first part: $rawBarcode -> $firstPart',
      );
      return firstPart;
    }

    return rawBarcode; // No concatenation detected
  }

  /// Pause barcode scanner listener by canceling subscription
  void pauseScannerListener() {
    if (_barcodeSubscription != null) {
      prints(
        'Pausing barcode scanner listener for: ${state.currentActiveScreen}',
      );
      _barcodeSubscription?.cancel();
      _barcodeSubscription = null;
      _lastProcessedBarcode = null;
      _lastProcessedTime = null;
    }
  }

  /// Resume barcode scanner listener by reinitializing
  void resumeScannerListener() {
    prints(
      'Resuming barcode scanner listener for: ${state.currentActiveScreen}',
    );
    _clearAllScreenBarcodesExcept(null);

    switch (state.currentActiveScreen) {
      case 'EditTableDetailDialogue':
        initializeForEditTableDetailDialogue();
        break;
      default:
        break;
    }
  }

  /// Get the scanner service for direct access
  BarcodeScannerService get scannerService => _scannerService;

  /// Dispose all barcode scanner subscriptions
  void disposeAllSubscriptions() {
    prints('Disposing all barcode scanner subscriptions');
    _disposePreviousSubscription();
    state = state.copyWith(currentActiveScreen: null);
  }

  /// Reinitialize to sales screen (call this when closing dialogs)
  void reinitializeToSalesScreen() {
    prints('Reinitializing to Sales Screen from: ${state.currentActiveScreen}');
    initializeForSalesScreen();
  }

  /// Helper method to clear all screen-specific barcodes except the specified one
  void _clearAllScreenBarcodesExcept(String? keepScreen) {
    state = state.copyWith(
      salesScreenBarcode:
          keepScreen == 'SalesScreen' ? state.salesScreenBarcode : null,
      openOrderBodyBarcode:
          keepScreen == 'OpenOrderBody' ? state.openOrderBodyBarcode : null,
      saveOrderDialogueBarcode:
          keepScreen == 'SaveOrderDialogue'
              ? state.saveOrderDialogueBarcode
              : null,
      saveOrderCustomBarcode:
          keepScreen == 'SaveOrderCustom' ? state.saveOrderCustomBarcode : null,
      editTableDetailDialogueBarcode:
          keepScreen == 'EditTableDetailDialogue'
              ? state.editTableDetailDialogueBarcode
              : null,
      tablesBarcode: keepScreen == 'Tables' ? state.tablesBarcode : null,
      editTablesBarcode:
          keepScreen == 'EditTables' ? state.editTablesBarcode : null,
    );
  }

  /// Clear specific screen barcode
  void clearSalesScreenBarcode() {
    state = state.copyWith(salesScreenBarcode: null);
  }

  void clearOpenOrderBodyBarcode() {
    state = state.copyWith(openOrderBodyBarcode: null);
  }

  void clearSaveOrderDialogueBarcode() {
    state = state.copyWith(saveOrderDialogueBarcode: null);
  }

  void clearSaveOrderCustomBarcode() {
    state = state.copyWith(saveOrderCustomBarcode: null);
  }

  void clearEditTableDetailDialogueBarcode() {
    state = state.copyWith(editTableDetailDialogueBarcode: null);
  }

  void clearTablesBarcode() {
    state = state.copyWith(tablesBarcode: null);
  }

  void clearEditTablesBarcode() {
    state = state.copyWith(editTablesBarcode: null);
  }

  @override
  void dispose() {
    _barcodeSubscription?.cancel();
    _scannerService.dispose();
    super.dispose();
  }
}

// ===========================
// Provider Definitions
// ===========================

/// Main barcode scanner provider
final barcodeScannerProvider =
    StateNotifierProvider<BarcodeScannerNotifier, BarcodeScannerState>(
      (ref) => BarcodeScannerNotifier(ref: ref),
      name: 'BarcodeScannerProvider',
    );

/// Get scanned item
final scannedItemProvider = Provider<ItemModel?>(
  (ref) => ref.watch(barcodeScannerProvider).scannedItem,
  name: 'ScannedItemProvider',
);

/// Check if processing
final isProcessingBarcodeProvider = Provider<bool>(
  (ref) => ref.watch(barcodeScannerProvider).isProcessing,
  name: 'IsProcessingBarcodeProvider',
);

/// Get error message
final barcodeErrorProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).errorMessage,
  name: 'BarcodeErrorProvider',
);

/// Get current active screen
final currentActiveScreenProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).currentActiveScreen,
  name: 'CurrentActiveScreenProvider',
);

/// Get sales screen barcode
final salesScreenBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).salesScreenBarcode,
  name: 'SalesScreenBarcodeProvider',
);

/// Get open order body barcode
final openOrderBodyBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).openOrderBodyBarcode,
  name: 'OpenOrderBodyBarcodeProvider',
);

/// Get save order dialogue barcode
final saveOrderDialogueBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).saveOrderDialogueBarcode,
  name: 'SaveOrderDialogueBarcodeProvider',
);

/// Get save order custom barcode
final saveOrderCustomBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).saveOrderCustomBarcode,
  name: 'SaveOrderCustomBarcodeProvider',
);

/// Get edit table detail dialogue barcode
final editTableDetailDialogueBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).editTableDetailDialogueBarcode,
  name: 'EditTableDetailDialogueBarcodeProvider',
);

/// Get tables barcode
final tablesBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).tablesBarcode,
  name: 'TablesBarcodeProvider',
);

/// Get edit tables barcode
final editTablesBarcodeProvider = Provider<String?>(
  (ref) => ref.watch(barcodeScannerProvider).editTablesBarcode,
  name: 'EditTablesBarcodeProvider',
);
