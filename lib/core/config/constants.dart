import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const bool isDevelopment = false;
const bool isReleaseButDebugging = false;
const bool isStaging = false || kDebugMode || isReleaseButDebugging;
const bool isEnvWebsiteStaging = true;

const String take = '100';
const int isolateMaxConcurrent = 10;

/// API URLs

// const String originUrlStaging = 'https://mhub-mysztech.com/';
// const String originUrlDevelopment = 'http://192.168.0.21:8000/';
// const String originUrlProduction = 'https://mhub-mysztech.com/';
const String originUrlStaging =
    'https://mts-pos-system-staging-isnckb.laravel.cloud/';
const String originUrlDevelopment = 'http://192.168.0.21:8000/';
const String originUrlProduction = 'https://hub.mysztech.com/';
const String originUrl =
    isStaging
        ? (isDevelopment ? originUrlDevelopment : originUrlStaging)
        : originUrlProduction;
const String imageUrlReferer = originUrl;
const String apiUrl = '${originUrl}api/';

const String versionApiUrl = '${apiUrl}v1/';

const String qrLink = '${originUrl}e-invoice/';
// const String rootUrl = 'https://mts.mahirandigital.com/api/v1/';

// const String baseUrl = 'https://mts.mahirandigital.com/api/';
//const String originUrl = 'https://mts.mahirandigital.com/';

/// API Key
const String apiKeyStaging =
    'yQfdDuEW55yWdXsFIYPmIe1IXTIlbjgiIU9jiTlTxfgXfWTFtQ6qAR0Vwfh94142';
const String apiKeyDevelopment =
    'O3uso1acDIkPETiTFtae0QXzQt6xKOibXseQcck7k9tuNfPvaFydn6GCQ1WggUPc';
const String apiKeyProduction =
    'yQfdDuEW55yWdXsFIYPmIe1IXTIlbjgiIU9jiTlTxfgXfWTFtQ6qAR0Vwfh94142';
const String apiKey =
    isStaging
        ? (isDevelopment ? apiKeyDevelopment : apiKeyStaging)
        : apiKeyProduction;

/// Pusher details
const String pusherKeyStaging = '5d9509fb16c15cc074f3';
const String pusherKeyDevelopment = '57226b283b85decfbc86';
const String pusherKeyProduction = '72679204bcfae6b9a1cb';
const String pusherKey =
    isStaging
        ? (isDevelopment ? pusherKeyDevelopment : pusherKeyStaging)
        : pusherKeyProduction;

const String pusherCluster = isStaging ? 'ap1' : 'ap1';
const int pusherPeriodTime = 2; // 5 seconds
/// Primary color
const Color kPrimaryColor = Color.fromRGBO(0, 163, 216, 1);

/// Secondary color
const Color kSecondaryColor = Color(0xFF979797);

/// Canvas color
const Color canvasColor = Color(0xFF2E2E48);

/// Dark canvas color
const Color darkCanvasColor = Color.fromARGB(255, 30, 30, 46);

/// Accent canvas color
const Color accentCanvasColor = Color(0xFF3E3E61);

/// Selected color
const Color selectedColor = Color(0xFFCAFFC5);

/// Background color
const Color scaffoldBackgroundColor = Color.fromRGBO(244, 245, 250, 1.0);

/// Primary light color
const Color kPrimaryLightColor = Color.fromRGBO(241, 244, 250, 1.0);

/// White color
const Color white = Colors.white;

/// Black color
const Color kBlackColor = Colors.black;

/// Text color
const Color kTextColor = Color.fromRGBO(68, 75, 88, 1);

/// Text gray color
const Color kTextGray = Color.fromARGB(255, 164, 162, 180);

/// Text gray opaque color
const Color kTextGrayOpaque = Color(0xFF64748b);

/// Item color
const Color kItemColor = Color.fromRGBO(235, 235, 243, 1);

/// Success color
const Color kSuccessColor = Color.fromRGBO(100, 221, 23, 1.0);

/// Error color
const Color kErrorColor = Color(0xFFD32F2F);

/// Warning color
const Color kWarningColor = Color(0xFFFFA000);

/// Info color
const Color kInfoColor = Color(0xFF0288D1);

/// Background green
const Color kBgGreen = Color.fromRGBO(236, 253, 245, 1.0);

/// Text green
const Color kTextGreen = Color.fromRGBO(6, 95, 70, 1.0);

/// Background red
const Color kBgRed = Color.fromRGBO(254, 242, 242, 1.0);

/// Text red
const Color kTextRed = Colors.red;

/// Background yellow
const Color kBgYellow = Color.fromRGBO(255, 251, 235, 1.0);

/// Text yellow
const Color kTextYellow = Color.fromRGBO(146, 64, 14, 1.0);

/// Background blue
const Color kBgBlue = Color.fromRGBO(239, 246, 255, 1.0);

/// Text blue
const Color kTextBlue = Color.fromRGBO(30, 64, 175, 1.0);

/// Badge background yellow (Tailwind yellow-100)
const Color kBadgeBgYellow = Color(0xFFFEF3C7);

/// Badge text yellow (Tailwind yellow-800)
const Color kBadgeTextYellow = Color(0xFF854D0E);

/// Badge background red (Tailwind red-100)
const Color kBadgeBgRed = Color(0xFFFEE2E2);

/// Badge text red (Tailwind red-800)
const Color kBadgeTextRed = Color(0xFF991B1B);

/// Badge background green (Tailwind green-100)
const Color kBadgeBgGreen = Color(0xFFDCFCE7);

/// Badge text green (Tailwind green-800)
const Color kBadgeTextGreen = Color(0xFF166534);

/// Badge background gray (Tailwind gray-100)
const Color kBadgeBgGray = Color(0xFFF3F4F6);

/// Badge text gray (Tailwind gray-800)
const Color kBadgeTextGray = Color(0xFF1F2937);

/// Text form field
const Color kTextFormField = Colors.white;

/// Text hint
const Color kTextHint = Color.fromRGBO(113, 113, 113, 1.0);

/// Disabled background
const Color kDisabledBg = Color.fromRGBO(247, 247, 247, 1.0);

/// Disabled text
const Color kDisabledText = Color.fromRGBO(181, 181, 181, 1.0);

/// Light gray
const Color kLightGray = Color.fromRGBO(245, 245, 245, 1);

/// Header
const Color kHeader = Color.fromRGBO(47, 52, 71, 1);

/// Background
const Color kBg = Color.fromRGBO(244, 245, 250, 1);

/// Primary gradient color
const LinearGradient kPrimaryGradientColor = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color.fromRGBO(2, 62, 138, 1.0), kPrimaryColor],
);

/// Primary gradient color 2
const LinearGradient kPrimaryGradientColor2 = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kPrimaryColor, Color.fromRGBO(2, 62, 138, 1.0)],
);

/// Primary gradient red
const LinearGradient kPrimaryGradientRed = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color.fromRGBO(255, 33, 27, 1.0), Color.fromRGBO(255, 138, 74, 1.0)],
);

/// Primary gradient gray
const LinearGradient kPrimaryGradientGray = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.fromARGB(255, 217, 217, 217),
    Color.fromARGB(255, 128, 138, 154),
  ],
);

/// Primary background color
const Color kPrimaryBgColor = Color.fromRGBO(200, 243, 255, 1);

/// Default padding
const double kDefaultPadding = 16.0;

/// Default radius
const double kDefaultRadius = 8.0;

const kWhiteColor = Colors.white;

/// Default shadow
const List<BoxShadow> kDefaultShadow = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 8.0, offset: Offset(0, 2)),
];

// Success
const kBgSuccess = Color.fromRGBO(236, 253, 245, 1.0);
const kTextSuccess = kPrimaryColor;

// Danger
const kBgDanger = Color.fromRGBO(254, 242, 242, 1.0);
const kTextDanger = Color.fromRGBO(153, 27, 27, 1.0);

// Warning
const kBgWarning = Color.fromRGBO(255, 243, 185, 1.0);
const kTextWarning = Color.fromRGBO(230, 119, 94, 1.0);

// Info
const kBgInfo = Color.fromRGBO(236, 253, 245, 1.0);
const kTextInfo = kPrimaryColor;

/// Default animation duration
const Duration kDefaultDuration = Duration(milliseconds: 300);

/// Default page transition duration
const Duration kPageTransitionDuration = Duration(milliseconds: 200);

/// Default API timeout
const Duration kDefaultTimeout = Duration(seconds: 30);

/// Default timezone
const String kTimezone = 'Asia/Kuala_Lumpur';

/// Sidebar width
double sidebarWidth = 300.w;

/// Global keys
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Device types
class DeviceTypes {
  /// Admin device
  static const int admin = 1000;

  /// POS device
  static const int pos = 2000;
}

/// Business features
class BusinessFeatures {
  /// Shift feature
  static const int shift = 1;

  /// Time clock feature
  static const int timeClock = 2;

  /// Kitchen printer feature
  static const int kitchenPrinter = 3;
}

/// Dialog types
class DialogType {
  /// Info dialog
  static const int info = 1;

  /// Danger dialog
  static const int danger = 2;

  /// Warning dialog
  static const int warning = 3;

  /// Success dialog
  static const int success = 4;
}

/// Business constants
class BusinessConstants {
  /// Default row per page
  static const int defaultRowPerPage = 10;

  /// Discount by percentage
  static const int discountByPercentage = 0;

  /// Discount by amount
  static const int discountByAmount = 1;

  /// Sold by each
  static const int soldByEach = 0;

  /// Sold by weight
  static const int soldByWeight = 1;

  /// Payment type card
  static const int paymentTypeCard = 0;

  /// Payment type check
  static const int paymentTypeCheck = 1;

  /// Payment type other
  static const int paymentTypeOther = 2;

  /// Tax to new items
  static const int taxToNewItems = 0;

  /// Tax to existing items
  static const int taxToExistingItems = 1;

  /// Tax to new and existing items
  static const int taxToNewAndExistingItems = 2;

  /// Don't apply tax
  static const int dontApplyTax = 3;

  /// Tax included
  static const int taxIncluded = 0;

  /// Tax added
  static const int taxAdded = 1;

  /// Bluetooth printer
  static const int bluetoothPrinter = 0;

  /// Ethernet printer
  static const int ethernetPrinter = 1;

  /// Paper width 80mm
  static const int paperWidth80 = 80;

  /// Paper width 58mm
  static const int paperWidth58 = 58;
}
