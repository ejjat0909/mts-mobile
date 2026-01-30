import 'dart:math';

class CalcUtils {
  static double round(double value, int places) {
    num factor = pow(10.0, places);
    return ((value * factor).round().toDouble() / factor);
  }

  static double calcCashRounding(double amount) {
    // Find the decimal part by taking the remainder of dividing by 0.10
    double remainder = double.parse((amount % 0.10).toStringAsFixed(2));

    if (remainder < 0.05) {
      // Round down if the remainder is 0.05 or below
      return amount - remainder;
    } else {
      // Round up if the remainder is above 0.05
      return amount - remainder + 0.10;
    }
  }
}
