import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// A highly optimized rolling text widget specifically designed for POS systems
/// with heavy state management. This widget includes advanced performance optimizations:
///
/// 1. Isolate-based number formatting for heavy computations
/// 2. Smart caching and memoization
/// 3. Debouncing for rapid value changes
/// 4. RepaintBoundary for isolated repaints
/// 5. Memory-efficient animation handling
/// 6. Adaptive performance based on value complexity
class OptimizedRollingNumber extends StatefulWidget {
  /// The number value to display and animate.
  final num value;

  /// The text style to apply to the rolling number.
  final TextStyle? style;

  /// The duration of the rolling animation.
  final Duration duration;

  /// The curve to use for the rolling animation.
  final Curve curve;

  /// The curve to use for width changes during animation.
  final Curve? widthCurve;

  /// Whether to animate the number when it changes.
  final bool animate;

  /// The number of decimal places to show.
  final int decimalPlaces;

  /// Whether to include a thousands separator.
  final bool useThousandsSeparator;

  /// The prefix to add before the number (e.g., currency symbol).
  final String prefix;

  /// The suffix to add after the number (e.g., percentage symbol).
  final String suffix;

  /// Whether to use isolate for heavy computations (default: auto-detect).
  final bool? useIsolate;

  /// Debounce duration for rapid value changes (default: 30ms).
  final Duration debounceDuration;

  /// Creates an OptimizedRollingNumber widget.
  const OptimizedRollingNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.widthCurve,
    this.animate = true,
    this.decimalPlaces = 2,
    this.useThousandsSeparator = true,
    this.prefix = '',
    this.suffix = '',
    this.useIsolate,
    this.debounceDuration = const Duration(milliseconds: 30),
  });

  @override
  State<OptimizedRollingNumber> createState() => _OptimizedRollingNumberState();
}

/// Isolate entry point for number formatting
void _formatNumberIsolate(Map<String, dynamic> params) {
  final SendPort sendPort = params['sendPort'];
  final num value = params['value'];
  final int decimalPlaces = params['decimalPlaces'];
  final bool useThousandsSeparator = params['useThousandsSeparator'];
  final String prefix = params['prefix'];
  final String suffix = params['suffix'];

  try {
    final result = _formatNumberSync(
      value,
      decimalPlaces,
      useThousandsSeparator,
      prefix,
      suffix,
    );
    sendPort.send({'success': true, 'result': result});
  } catch (e) {
    sendPort.send({'success': false, 'error': e.toString()});
  }
}

/// Synchronous number formatting helper
String _formatNumberSync(
  num value,
  int decimalPlaces,
  bool useThousandsSeparator,
  String prefix,
  String suffix,
) {
  String formattedValue;

  if (useThousandsSeparator) {
    // Format with thousands separator
    final parts = value.toStringAsFixed(decimalPlaces).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Add thousands separator using efficient string building
    final buffer = StringBuffer();
    final intLength = integerPart.length;

    for (int i = 0; i < intLength; i++) {
      if (i > 0 && (intLength - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    final formattedIntegerPart = buffer.toString();

    // Combine integer and decimal parts
    if (decimalPlaces > 0) {
      formattedValue = '$formattedIntegerPart.$decimalPart';
    } else {
      formattedValue = formattedIntegerPart;
    }
  } else {
    // Format without thousands separator
    formattedValue = value.toStringAsFixed(decimalPlaces);
  }

  // Add prefix and suffix
  return '$prefix$formattedValue$suffix';
}

class _OptimizedRollingNumberState extends State<OptimizedRollingNumber>
    with SingleTickerProviderStateMixin {
  num? _previousValue;
  String _cachedFormattedValue = '';
  bool _isFormatting = false;
  Timer? _debounceTimer;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  late AnimationController _animationController;

  // Cache for formatted values to avoid recomputation
  final Map<String, String> _formatCache = {};
  static const int _maxCacheSize = 100;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    // Format initial value synchronously for immediate display
    _cachedFormattedValue = _formatValueSync(widget.value);
  }

  @override
  void didUpdateWidget(OptimizedRollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation duration if changed
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
    }

    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _handleValueChange();
    }
  }

  void _handleValueChange() {
    // Cancel any pending formatting
    _debounceTimer?.cancel();

    // Check cache first
    final cacheKey = _getCacheKey(widget.value);
    if (_formatCache.containsKey(cacheKey)) {
      _cachedFormattedValue = _formatCache[cacheKey]!;
      if (mounted) setState(() {});
      return;
    }

    // Determine if we should use isolate
    final shouldUseIsolate = _shouldUseIsolate();

    if (!shouldUseIsolate) {
      // Format synchronously for simple cases
      _cachedFormattedValue = _formatValueSync(widget.value);
      _cacheFormattedValue(cacheKey, _cachedFormattedValue);
      if (mounted) setState(() {});
      return;
    }

    // Debounce rapid value changes and use isolate for heavy formatting
    _debounceTimer = Timer(widget.debounceDuration, () {
      _formatValueAsync(widget.value);
    });
  }

  bool _shouldUseIsolate() {
    // Use isolate override if specified
    if (widget.useIsolate != null) {
      return widget.useIsolate!;
    }

    // Auto-detect: use isolate for large numbers with thousands separator
    return widget.value.abs() >= 1000000 && widget.useThousandsSeparator;
  }

  String _getCacheKey(num value) {
    return '${value}_${widget.decimalPlaces}_${widget.useThousandsSeparator}_${widget.prefix}_${widget.suffix}';
  }

  void _cacheFormattedValue(String key, String value) {
    // Implement LRU-like cache management
    if (_formatCache.length >= _maxCacheSize) {
      // Remove oldest entries (simple implementation)
      final keysToRemove = _formatCache.keys.take(_maxCacheSize ~/ 2).toList();
      for (final keyToRemove in keysToRemove) {
        _formatCache.remove(keyToRemove);
      }
    }
    _formatCache[key] = value;
  }

  /// Format value asynchronously using isolate for heavy computations
  Future<void> _formatValueAsync(num value) async {
    if (_isFormatting) return;

    _isFormatting = true;

    try {
      _receivePort = ReceivePort();

      final params = {
        'sendPort': _receivePort!.sendPort,
        'value': value,
        'decimalPlaces': widget.decimalPlaces,
        'useThousandsSeparator': widget.useThousandsSeparator,
        'prefix': widget.prefix,
        'suffix': widget.suffix,
      };

      _isolate = await Isolate.spawn(_formatNumberIsolate, params);

      _receivePort!.listen((data) {
        if (mounted) {
          if (data['success']) {
            final result = data['result'] as String;
            setState(() {
              _cachedFormattedValue = result;
            });
            // Cache the result
            _cacheFormattedValue(_getCacheKey(value), result);
          }
        }
        _cleanupIsolate();
      });
    } catch (e) {
      // Fallback to synchronous formatting
      _cachedFormattedValue = _formatValueSync(value);
      if (mounted) setState(() {});
      _cleanupIsolate();
    } finally {
      _isFormatting = false;
    }
  }

  /// Synchronous formatting for simple cases
  String _formatValueSync(num value) {
    return _formatNumberSync(
      value,
      widget.decimalPlaces,
      widget.useThousandsSeparator,
      widget.prefix,
      widget.suffix,
    );
  }

  void _cleanupIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _cleanupIsolate();
    _formatCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use cached formatted value for better performance
    final String formattedValue =
        _cachedFormattedValue.isNotEmpty
            ? _cachedFormattedValue
            : _formatValueSync(widget.value);

    // If animation is disabled, just show the text
    if (!widget.animate) {
      return Text(formattedValue, style: widget.style);
    }

    // Determine slide direction based on value change
    TextTapeSlideDirection slideDirection = TextTapeSlideDirection.up;
    if (_previousValue != null) {
      if (widget.value > _previousValue!) {
        slideDirection = TextTapeSlideDirection.up; // Increasing: slide up
      } else if (widget.value < _previousValue!) {
        slideDirection = TextTapeSlideDirection.down; // Decreasing: slide down
      }
    }

    // Use RepaintBoundary to isolate repaints and improve performance
    return RepaintBoundary(
      child: Text(formattedValue, style: widget.style)
          .roll(
            padding: EdgeInsets.zero,
            tapeStrategy: const ConsistentSymbolTapeStrategy(0),
            tapeSlideDirection: slideDirection,
            staggerTapes: true,
            widthCurve: widget.widthCurve,
          )
          .animate(
            trigger: widget.value,
            duration: widget.duration,
            curve: widget.curve,
          ),
    );
  }
}

/// A lightweight version of RollingNumber for simple use cases
/// This version skips isolate usage and focuses on minimal overhead
class LightweightRollingNumber extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool animate;
  final int decimalPlaces;
  final String prefix;
  final String suffix;

  const LightweightRollingNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
    this.animate = true,
    this.decimalPlaces = 2,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<LightweightRollingNumber> createState() =>
      _LightweightRollingNumberState();
}

class _LightweightRollingNumberState extends State<LightweightRollingNumber> {
  num? _previousValue;
  String _cachedValue = '';

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _cachedValue = _formatValue(widget.value);
  }

  @override
  void didUpdateWidget(LightweightRollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _cachedValue = _formatValue(widget.value);
    }
  }

  String _formatValue(num value) {
    final formatted = value.toStringAsFixed(widget.decimalPlaces);
    return '${widget.prefix}$formatted${widget.suffix}';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text(_cachedValue, style: widget.style);
    }

    // Determine slide direction
    TextTapeSlideDirection slideDirection = TextTapeSlideDirection.up;
    if (_previousValue != null) {
      if (widget.value > _previousValue!) {
        slideDirection = TextTapeSlideDirection.up;
      } else if (widget.value < _previousValue!) {
        slideDirection = TextTapeSlideDirection.down;
      }
    }

    return RepaintBoundary(
      child: Text(_cachedValue, style: widget.style)
          .roll(
            padding: EdgeInsets.zero,
            tapeStrategy: const ConsistentSymbolTapeStrategy(0),
            tapeSlideDirection: slideDirection,
            staggerTapes: false, // Disable staggering for better performance
          )
          .animate(
            trigger: widget.value,
            duration: widget.duration,
            curve: widget.curve,
          ),
    );
  }
}
