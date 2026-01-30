import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mts/core/utils/log_utils.dart';

/// Service for handling physical barcode scanner input
class BarcodeScannerService {
  static final BarcodeScannerService _instance =
      BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  // Stream controllers for barcode events for different screens
  final StreamController<String> _barcodeControllerForSalesScreen =
      StreamController<String>.broadcast();
  final StreamController<String> _barcodeControllerForOpenOrderBody =
      StreamController<String>.broadcast();
  final StreamController<String> _barcodeControllerForSaveOrderDialogue =
      StreamController<String>.broadcast();
  final StreamController<String> _barcodeControllerForSaveOrderCustom =
      StreamController<String>.broadcast();
  final StreamController<String> _barcodeControllerForEditTableDetailDialogue =
      StreamController<String>.broadcast();
  final StreamController<String> _barcodeControllerForTables =
      StreamController<String>.broadcast();
  final StreamController<String> _barcodeControllerForEditTables =
      StreamController<String>.broadcast();

  // Buffer to accumulate characters
  String _buffer = '';

  // Timer to detect end of barcode input
  Timer? _inputTimer;

  // Track timing between keystrokes to detect scanner vs manual input
  DateTime? _lastKeystroke;
  final List<Duration> _keystrokeIntervals = [];

  // Configuration
  static const Duration _inputTimeout = Duration(
    milliseconds: 100,
  ); // Adjust based on your scanner speed
  static const Duration _maxKeystrokeInterval = Duration(
    milliseconds: 50,
  ); // Max time between scanner keystrokes
  static const int _minBarcodeLength =
      1; // Minimum barcode length (Code 128 can be as short as 1 character)
  static const int _maxBarcodeLength = 50; // Maximum barcode length
  static const int _minKeystrokesForScanner =
      1; // Minimum keystrokes to consider it scanner input (adjusted for Code 128)

  // Characters that typically end barcode input (Enter, Tab)
  static const List<LogicalKeyboardKey> _endKeys = [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.tab,
  ];

  /// Streams of scanned barcodes for different screens
  Stream<String> get barcodeStreamForSalesScreen =>
      _barcodeControllerForSalesScreen.stream;
  Stream<String> get barcodeStreamForOpenOrderBody =>
      _barcodeControllerForOpenOrderBody.stream;
  Stream<String> get barcodeStreamForSaveOrderDialogue =>
      _barcodeControllerForSaveOrderDialogue.stream;
  Stream<String> get barcodeStreamForSaveOrderCustom =>
      _barcodeControllerForSaveOrderCustom.stream;
  Stream<String> get barcodeStreamForEditTableDetailDialogue =>
      _barcodeControllerForEditTableDetailDialogue.stream;
  Stream<String> get barcodeStreamForTables =>
      _barcodeControllerForTables.stream;
  Stream<String> get barcodeStreamForEditTables =>
      _barcodeControllerForEditTables.stream;

  /// Initialize the barcode scanner service for different screens
  void initializeForSalesScreen() {
    prints('Barcode Scanner Service initialized for Sales Screen');
  }

  void initializeForOpenOrderBody() {
    prints('Barcode Scanner Service initialized for Open Order Body');
  }

  void initializeForSaveOrderDialogue() {
    prints('Barcode Scanner Service initialized for Save Order Dialogue');
  }

  void initializeForSaveOrderCustom() {
    prints('Barcode Scanner Service initialized for Save Order Custom');
  }

  void initializeForEditTableDetailDialogue() {
    prints(
      'Barcode Scanner Service initialized for Edit Table Detail Dialogue',
    );
  }

  void initializeForTables() {
    prints('Barcode Scanner Service initialized for Tables');
  }

  void initializeForEditTables() {
    prints('Barcode Scanner Service initialized for Edit Tables');
  }

  /// Handle raw keyboard events
  bool handleKeyEvent(KeyEvent event) {
    // Only process key down events
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final now = DateTime.now();

    // Check if it's an end key (Enter, Tab)
    if (_endKeys.contains(key)) {
      final shouldConsume = _processBuffer();
      return shouldConsume;
    }

    // Check if it's a printable character
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      // Track keystroke timing
      if (_lastKeystroke != null) {
        final interval = now.difference(_lastKeystroke!);
        _keystrokeIntervals.add(interval);

        // Keep only recent intervals
        if (_keystrokeIntervals.length > 20) {
          _keystrokeIntervals.removeAt(0);
        }
      }
      _lastKeystroke = now;

      _addToBuffer(character);

      // Only consume if this looks like scanner input (fast, consistent timing)
      return _looksLikeScannerInput();
    }

    return false; // Don't consume other keys
  }

  /// Add character to buffer and reset timer
  void _addToBuffer(String character) {
    _buffer += character;

    // Reset the input timer
    _inputTimer?.cancel();
    _inputTimer = Timer(_inputTimeout, () {
      _processBuffer();
    });

    // Prevent buffer overflow
    if (_buffer.length > _maxBarcodeLength) {
      _clearBuffer();
    }
  }

  /// Check if the current input pattern looks like scanner input
  bool _looksLikeScannerInput() {
    // Need at least a few keystrokes to determine (at least 2 intervals = 3 keystrokes)
    if (_keystrokeIntervals.isEmpty) {
      return false;
    }

    // Check if most recent intervals are fast and consistent (typical of scanner)
    final recentIntervals =
        _keystrokeIntervals.length > 5
            ? _keystrokeIntervals.sublist(_keystrokeIntervals.length - 5)
            : _keystrokeIntervals;

    // All intervals should be fast (under max threshold)
    final allFast = recentIntervals.every(
      (interval) => interval <= _maxKeystrokeInterval,
    );

    return allFast && _buffer.length >= _minKeystrokesForScanner;
  }

  /// Process the accumulated buffer as a potential barcode
  bool _processBuffer() {
    _inputTimer?.cancel();

    final barcode = _buffer.trim();
    bool shouldConsume = false;

    prints('Processing buffer: "$barcode" (length: ${barcode.length})');

    // Only process if it looks like scanner input or has minimum length
    if (_looksLikeScannerInput() || barcode.length >= _minBarcodeLength) {
      prints(
        'Passed scanner input check. Looks like scanner: ${_looksLikeScannerInput()}, Length: ${barcode.length}',
      );

      // Validate barcode length
      if (barcode.length >= _minBarcodeLength &&
          barcode.length <= _maxBarcodeLength) {
        prints('Passed length check. Validating pattern...');

        // Check EAN-13 first, then Code 128
        final isEan13 = _isValidBarcodeEan13Pattern(barcode);
        final isCode128 = _isValidBarcode128Pattern(barcode);

        prints('Validation results - EAN-13: $isEan13, Code 128: $isCode128');

        if (isEan13 || isCode128) {
          prints(
            '🕵️🕵️🕵️🕵️🕵️🕵️🕵️🕵️Barcode scanned: $barcode (Type: ${isEan13 ? "EAN-13" : "Code 128"})',
          );
          // Broadcast to all stream controllers
          _barcodeControllerForSalesScreen.add(barcode);
          _barcodeControllerForOpenOrderBody.add(barcode);
          _barcodeControllerForSaveOrderDialogue.add(barcode);
          _barcodeControllerForSaveOrderCustom.add(barcode);
          _barcodeControllerForEditTableDetailDialogue.add(barcode);
          _barcodeControllerForTables.add(barcode);
          _barcodeControllerForEditTables.add(barcode);
          shouldConsume = true;
        } else {
          prints(
            '🕵🏿🕵🏿🕵🏿🕵🏿🕵🏿🕵🏿🕵🏿🕵🏿Barcode validation failed for: $barcode',
          );
        }
      } else {
        prints(
          'Failed length check. Length: ${barcode.length} (min: $_minBarcodeLength, max: $_maxBarcodeLength)',
        );
      }
    } else {
      prints(
        'Failed scanner input check. Looks like scanner: ${_looksLikeScannerInput()}, Length: ${barcode.length}',
      );
    }

    _clearBuffer();
    return shouldConsume;
  }

  /// Clear the input buffer
  void _clearBuffer() {
    _buffer = '';
    _inputTimer?.cancel();
    _keystrokeIntervals.clear();
    _lastKeystroke = null;
  }

  /// Validate if the scanned string is a valid barcode
  bool _isValidBarcode128Pattern(String barcode) {
    // Basic validation - you can enhance this based on your needs
    // Code 128 can contain alphanumeric characters and some special characters
    final code128Pattern = RegExp(r'^[A-Za-z0-9\-_\.\s\+\*\$\%\/\(\)]+$');
    final isValid = code128Pattern.hasMatch(barcode);

    if (isValid) {
      prints('Valid Code 128 barcode: $barcode');
    } else {
      prints('Invalid Code 128 format: $barcode');
    }

    return isValid;
  }

  bool _isValidBarcodeEan13Pattern(String barcode) {
    // EAN-13 must be exactly 13 digits
    if (barcode.length != 13) {
      prints(
        'Invalid EAN-13 length: $barcode (length: ${barcode.length}), expected 13 digits',
      );
      return false;
    }

    // EAN-13 must contain only numeric characters
    final numericPattern = RegExp(r'^\d{13}$');
    if (!numericPattern.hasMatch(barcode)) {
      prints('Invalid EAN-13 format: $barcode, must contain only digits');
      return false;
    }

    // Validate check digit using EAN-13 algorithm
    final isValid = _validateEan13CheckDigit(barcode);
    if (!isValid) {
      prints('Invalid EAN-13 check digit: $barcode');
    } else {
      prints('Valid EAN-13 barcode: $barcode');
    }
    return isValid;
  }

  /// Validate EAN-13 check digit using the standard algorithm
  bool _validateEan13CheckDigit(String barcode) {
    // Convert string to list of integers
    final digits = barcode.split('').map(int.parse).toList();

    // Calculate check digit
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      if (i % 2 == 0) {
        // Odd positions (1st, 3rd, 5th, etc.) - multiply by 1
        sum += digits[i];
      } else {
        // Even positions (2nd, 4th, 6th, etc.) - multiply by 3
        sum += digits[i] * 3;
      }
    }

    // Calculate check digit
    int checkDigit = (10 - (sum % 10)) % 10;

    // Compare with the last digit of the barcode
    return checkDigit == digits[12];
  }

  /// Dispose resources
  void dispose() {
    _inputTimer?.cancel();
    _barcodeControllerForSalesScreen.close();
    _barcodeControllerForOpenOrderBody.close();
    _barcodeControllerForSaveOrderDialogue.close();
    _barcodeControllerForSaveOrderCustom.close();
    _barcodeControllerForEditTableDetailDialogue.close();
    _barcodeControllerForTables.close();
    _barcodeControllerForEditTables.close();
  }
}
