import 'package:easy_localization/easy_localization.dart';
import 'package:mts/core/config/constants.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Date and time utility functions
class DateTimeUtils {
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Get end of week
  static DateTime endOfWeek(DateTime date) {
    return endOfDay(date.add(Duration(days: 7 - date.weekday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return endOfDay(DateTime(date.year, date.month + 1, 0));
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return endOfDay(DateTime(date.year, 12, 31));
  }

  /// Format date to yyyy-MM-dd
  static String formatToYMD(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd', 'en_US');
    return formatter.format(date);
  }

  /// Format date to dd/MM/yyyy
  static String formatToDMY(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'en_US');
    return formatter.format(date);
  }

  /// Format date to yyyy-MM-dd HH:mm:ss
  static String formatToYMDHMS(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US');
    return formatter.format(date);
  }

  /// Format date to ISO 8601 format (yyyy-MM-ddTHH:mm:ssZ)
  static String formatToISO8601(DateTime date) {
    final utcDate = date.toUtc();
    final formatter = DateFormat('yyyy-MM-ddTHH:mm:ss', 'en_US');
    return '${formatter.format(utcDate)}Z';
  }

  /// Format date to dd/MM/yyyy HH:mm
  static String formatToDMYHM(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'en_US');
    return formatter.format(date);
  }

  /// Get formatted date and time with timezone
  static String getDateTimeFormat(DateTime? dateTime) {
    if (dateTime == null) {
      return 'noDate'.tr();
    }

    // Initialize timezone data
    tz.initializeTimeZones();

    // Get the timezone
    final timezone = tz.getLocation(kTimezone);

    // Convert the DateTime to the desired timezone
    final localDateTime = tz.TZDateTime.from(dateTime, timezone);

    // Format the date with explicit locale to avoid locale-related errors
    return DateFormat('yyyy-MM-dd HH:mm:ss', 'en_US').format(localDateTime);
  }

  /// Get formatted date with timezone
  static String getDateFormat(DateTime? dateTime) {
    if (dateTime == null) {
      return 'noDate'.tr();
    }

    // Initialize timezone data
    tz.initializeTimeZones();

    // Get the timezone
    final timezone = tz.getLocation(kTimezone);

    // Convert the DateTime to the desired timezone
    final localDateTime = tz.TZDateTime.from(dateTime, timezone);

    // Format the date with explicit locale to avoid locale-related errors
    return DateFormat('dd MMM yyyy', 'en_US').format(localDateTime);
  }

  /// Get formatted time with timezone
  static String getTimeFormat(DateTime? dateTime) {
    if (dateTime == null) {
      return 'noDate'.tr();
    }

    // Initialize timezone data
    tz.initializeTimeZones();

    // Get the timezone
    final timezone = tz.getLocation(kTimezone);

    // Convert the DateTime to the desired timezone
    final localDateTime = tz.TZDateTime.from(dateTime, timezone);

    // Format the time with explicit locale to avoid locale-related errors
    return DateFormat('hh:mm a', 'en_US').format(localDateTime);
  }

  /// Calculate time difference in days and hours
  static String getTimeDifferenceInDaysHours(DateTime value) {
    DateTime now = DateTime.now();
    Duration duration = value.difference(now);
    int dayCount = duration.inDays.abs();
    int hourCount = duration.inHours.remainder(24).abs();

    if (hourCount != 0) {
      return '$dayCount days $hourCount hours';
    } else {
      return '$dayCount days';
    }
  }

  /// Calculate time difference in days
  static String getTimeDifferenceInDays(DateTime value) {
    DateTime now = DateTime.now();
    int count = value.difference(now).inDays.abs();
    return '$count days';
  }

  /// Calculate time difference in hours and minutes
  static String getTimeDifferenceInHoursMinutes(DateTime value) {
    DateTime now = DateTime.now();
    Duration duration = value.difference(now);
    int hourCount = duration.inHours.abs();
    int minuteCount = duration.inMinutes.remainder(60).abs();

    if (minuteCount != 0) {
      return '$hourCount hours $minuteCount minutes';
    } else {
      return '$hourCount hours';
    }
  }

  /// Calculate time difference in minutes
  static String getTimeDifferenceInMinutes(DateTime value) {
    DateTime now = DateTime.now();
    int count = value.difference(now).inMinutes.abs();
    return '$count minutes';
  }

  /// Convert DateTime to system timezone (returns DateTime object)
  static DateTime convertToTimezone(DateTime dateTime) {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Get the timezone
    final timezone = tz.getLocation(kTimezone);

    // Convert the DateTime to the desired timezone
    final localDateTime = tz.TZDateTime.from(dateTime, timezone);

    // Return as regular DateTime
    return DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
      localDateTime.hour,
      localDateTime.minute,
      localDateTime.second,
      localDateTime.millisecond,
    );
  }
}
