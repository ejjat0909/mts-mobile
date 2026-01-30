import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/presentation/common/widgets/optimized_rolling_text.dart';

/// Example showing how to migrate from RollingNumber to OptimizedRollingNumber
/// in the order_item.dart component for better performance during heavy state management

class OrderItemPriceExample extends StatelessWidget {
  final num saleItemPrice;
  final bool isHeavyStateManagement;

  const OrderItemPriceExample({
    super.key,
    required this.saleItemPrice,
    this.isHeavyStateManagement = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // BEFORE: Original RollingNumber (can lag during heavy state management)
        // RollingNumber(
        //   value: saleItemPrice.abs(),
        //   prefix: "${'rm'.tr()} ",
        //   style: AppTheme.normalTextStyle(
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),

        // AFTER: Optimized version for POS systems
        OptimizedRollingNumber(
          value: saleItemPrice.abs(),
          prefix: "${'rm'.tr()} ",
          decimalPlaces: 2,
          useThousandsSeparator: true,
          // Adjust debounce based on how frequently the price changes
          debounceDuration: isHeavyStateManagement 
              ? const Duration(milliseconds: 100) // Longer debounce for heavy operations
              : const Duration(milliseconds: 50),  // Standard debounce
          // Shorter animation for better responsiveness
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          style: AppTheme.normalTextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Example for order total in order_list_sales.dart
class OrderTotalExample extends StatelessWidget {
  final num totalAfterDiscountAndTax;

  const OrderTotalExample({
    super.key,
    required this.totalAfterDiscountAndTax,
  });

  @override
  Widget build(BuildContext context) {
    final displayTotal = totalAfterDiscountAndTax <= 0 ? 0 : totalAfterDiscountAndTax;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'total'.tr(),
            style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(
                'rm'.tr(),
                style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 2.5),
              
              // BEFORE: Original RollingNumber
              // RollingNumber(
              //   value: displayTotal.abs(),
              //   style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
              // ),

              // AFTER: Optimized for large totals
              OptimizedRollingNumber(
                value: displayTotal.abs(),
                decimalPlaces: 2,
                useThousandsSeparator: true,
                // Force isolate usage for large totals
                useIsolate: displayTotal.abs() > 10000,
                // Longer debounce for totals (they change less frequently)
                debounceDuration: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Example for quantity or simple counters
class QuantityCounterExample extends StatelessWidget {
  final int quantity;

  const QuantityCounterExample({
    super.key,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: 
        // Use lightweight version for simple counters
        LightweightRollingNumber(
          value: quantity,
          decimalPlaces: 0,
          duration: const Duration(milliseconds: 150), // Fast animation
          curve: Curves.easeOut,
          style: AppTheme.normalTextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
    );
  }
}

/// Example showing conditional optimization based on system load
class AdaptiveRollingPriceExample extends StatelessWidget {
  final num price;
  final bool isSystemUnderHeavyLoad;

  const AdaptiveRollingPriceExample({
    super.key,
    required this.price,
    required this.isSystemUnderHeavyLoad,
  });

  @override
  Widget build(BuildContext context) {
    // Choose widget based on system performance
    if (isSystemUnderHeavyLoad) {
      // Use lightweight version when system is under heavy load
      return LightweightRollingNumber(
        value: price,
        prefix: "${'rm'.tr()} ",
        decimalPlaces: 2,
        duration: const Duration(milliseconds: 100), // Very fast
        style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
      );
    } else {
      // Use full-featured version when system can handle it
      return OptimizedRollingNumber(
        value: price,
        prefix: "${'rm'.tr()} ",
        decimalPlaces: 2,
        useThousandsSeparator: true,
        debounceDuration: const Duration(milliseconds: 50),
        duration: const Duration(milliseconds: 250),
        style: AppTheme.normalTextStyle(fontWeight: FontWeight.bold),
      );
    }
  }
}

/// Performance monitoring widget that can help identify when to use different optimizations
class PerformanceAwareRollingNumber extends StatefulWidget {
  final num value;
  final String prefix;
  final TextStyle? style;

  const PerformanceAwareRollingNumber({
    super.key,
    required this.value,
    this.prefix = '',
    this.style,
  });

  @override
  State<PerformanceAwareRollingNumber> createState() => _PerformanceAwareRollingNumberState();
}

class _PerformanceAwareRollingNumberState extends State<PerformanceAwareRollingNumber> {
  DateTime _lastUpdate = DateTime.now();
  bool _isHighFrequencyUpdates = false;

  @override
  void didUpdateWidget(PerformanceAwareRollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      final now = DateTime.now();
      final timeSinceLastUpdate = now.difference(_lastUpdate).inMilliseconds;
      
      // Detect high-frequency updates (more than 10 updates per second)
      if (timeSinceLastUpdate < 100) {
        _isHighFrequencyUpdates = true;
      } else if (timeSinceLastUpdate > 1000) {
        _isHighFrequencyUpdates = false;
      }
      
      _lastUpdate = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adapt based on update frequency
    if (_isHighFrequencyUpdates) {
      return LightweightRollingNumber(
        value: widget.value,
        prefix: widget.prefix,
        decimalPlaces: 2,
        duration: const Duration(milliseconds: 100),
        style: widget.style,
      );
    } else {
      return OptimizedRollingNumber(
        value: widget.value,
        prefix: widget.prefix,
        decimalPlaces: 2,
        useThousandsSeparator: true,
        debounceDuration: const Duration(milliseconds: 50),
        duration: const Duration(milliseconds: 250),
        style: widget.style,
      );
    }
  }
}