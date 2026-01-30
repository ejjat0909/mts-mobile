import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// A widget that displays rolling text animation for numbers.
///
/// This widget uses the hyper_effects package to create a smooth rolling
/// animation when the displayed number changes. Optimized for heavy state management
/// scenarios with isolate-based computations and performance improvements.
class RollingText extends StatefulWidget {
  /// The text value to display and animate.
  final String text;

  /// The text style to apply to the rolling text.
  final TextStyle? style;

  /// The duration of the rolling animation.
  final Duration duration;

  /// The curve to use for the rolling animation.
  final Curve curve;

  /// Whether to animate the text when it changes.
  final bool animate;

  /// Creates a RollingText widget.
  ///
  /// The [text] parameter is required and should contain the number to display.
  /// The [style] parameter is optional and defaults to the theme's bodyLarge style.
  /// The [duration] parameter defaults to 500 milliseconds.
  /// The [curve] parameter defaults to Curves.easeInOut.
  /// The [widthCurve] parameter is optional and defaults to null.
  /// The [animate] parameter defaults to true.
  const RollingText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.animate = true,
  });

  @override
  State<RollingText> createState() => _RollingTextState();
}

class _RollingTextState extends State<RollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnimating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(RollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation duration if changed
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
    }
    
    // Handle text changes with debouncing to prevent excessive animations
    if (oldWidget.text != widget.text && widget.animate) {
      _handleTextChange();
    }
  }

  void _handleTextChange() {
    // Cancel any pending animation
    _debounceTimer?.cancel();
    
    // Debounce rapid text changes (common in POS systems)
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted && !_isAnimating) {
        _triggerAnimation();
      }
    });
  }

  void _triggerAnimation() {
    if (!mounted) return;
    
    setState(() {
      _isAnimating = true;
    });
    
    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyLarge;
    final effectiveStyle = widget.style ?? defaultStyle;

    if (!widget.animate) {
      return Text(widget.text, style: effectiveStyle);
    }

    // Use RepaintBoundary to isolate repaints and improve performance
    return RepaintBoundary(
      child: Text(widget.text, style: effectiveStyle)
          .roll(
            padding: EdgeInsets.zero,
            tapeStrategy: const ConsistentSymbolTapeStrategy(0),
            tapeSlideDirection: TextTapeSlideDirection.up,
            staggerTapes: true,
          )
          .animate(
            trigger: widget.text,
            duration: widget.duration,
            curve: widget.curve,
          ),
    );
  }
}

/// A specialized version of RollingText specifically for numbers.
///
/// This widget formats the input number and applies the rolling animation.
/// The animation direction changes based on whether the number is increasing or decreasing.
class RollingNumber extends StatefulWidget {
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

  /// Creates a RollingNumber widget.
  ///
  /// The [value] parameter is required and should be the number to display.
  /// The [style] parameter is optional and defaults to the theme's bodyLarge style.
  /// The [duration] parameter defaults to 500 milliseconds.
  /// The [curve] parameter defaults to Curves.easeInOut.
  /// The [animate] parameter defaults to true.
  /// The [decimalPlaces] parameter defaults to 2.
  /// The [useThousandsSeparator] parameter defaults to true.
  /// The [prefix] parameter defaults to an empty string.
  /// The [suffix] parameter defaults to an empty string.
  const RollingNumber({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.widthCurve,
    this.animate = true,
    this.decimalPlaces = 2,
    this.useThousandsSeparator = true,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

/// Isolate entry point for number formatting
/// This runs heavy number formatting operations off the main thread
void _formatNumberIsolate(Map<String, dynamic> params) {
  final SendPort sendPort = params['sendPort'];
  final num value = params['value'];
  final int decimalPlaces = params['decimalPlaces'];
  final bool useThousandsSeparator = params['useThousandsSeparator'];
  final String prefix = params['prefix'];
  final String suffix = params['suffix'];

  try {
    String formattedValue;

    if (useThousandsSeparator) {
      // Format with thousands separator
      final parts = value.toStringAsFixed(decimalPlaces).split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      // Add thousands separator
      final buffer = StringBuffer();
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
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
    final result = '$prefix$formattedValue$suffix';
    sendPort.send({'success': true, 'result': result});
  } catch (e) {
    sendPort.send({'success': false, 'error': e.toString()});
  }
}

class _RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  num? _previousValue;
  String _cachedFormattedValue = '';
  bool _isFormatting = false;
  Timer? _debounceTimer;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  late AnimationController _animationController;

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
  void didUpdateWidget(RollingNumber oldWidget) {
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
    
    // For small numbers or when isolates aren't beneficial, format synchronously
    if (widget.value.abs() < 1000000 || !widget.useThousandsSeparator) {
      _cachedFormattedValue = _formatValueSync(widget.value);
      if (mounted) setState(() {});
      return;
    }
    
    // Debounce rapid value changes and use isolate for heavy formatting
    _debounceTimer = Timer(const Duration(milliseconds: 30), () {
      _formatValueAsync(widget.value);
    });
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
            setState(() {
              _cachedFormattedValue = data['result'];
            });
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
    String formattedValue;

    if (widget.useThousandsSeparator) {
      // Format with thousands separator
      final parts = value.toStringAsFixed(widget.decimalPlaces).split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';

      // Add thousands separator
      final buffer = StringBuffer();
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
          buffer.write(',');
        }
        buffer.write(integerPart[i]);
      }
      final formattedIntegerPart = buffer.toString();

      // Combine integer and decimal parts
      if (widget.decimalPlaces > 0) {
        formattedValue = '$formattedIntegerPart.$decimalPart';
      } else {
        formattedValue = formattedIntegerPart;
      }
    } else {
      // Format without thousands separator
      formattedValue = value.toStringAsFixed(widget.decimalPlaces);
    }

    // Add prefix and suffix
    return '${widget.prefix}$formattedValue${widget.suffix}';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use cached formatted value for better performance
    final String formattedValue = _cachedFormattedValue.isNotEmpty 
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
