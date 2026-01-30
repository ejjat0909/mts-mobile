import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mts/core/enum/paper_width_enum.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/receipt_printer_utils.dart';
import 'package:mts/plugins/flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/network/network_print_result.dart';
import 'package:mts/plugins/flutter_thermal_printer/network/network_printer.dart';
import 'package:mts/plugins/flutter_thermal_printer/utils/printer.dart';
import 'package:mts/plugins/imin_printer/column_maker.dart';
import 'package:mts/plugins/imin_printer/enums.dart';
import 'package:mts/plugins/imin_printer/imin_printer.dart';
import 'package:mts/plugins/imin_printer/imin_style.dart';
import 'package:mts/providers/cash_drawer_log/cash_drawer_log_providers.dart';

/// Utility class containing common functions for receipt printing
class ReceiptPrinterService {
  // Optional configuration parameters that could be set during initialization
  final int defaultTotalWidth;
  final int defaultRightColumnWidth;
  final String paperWidth;
  final Duration networkTimeout;
  final int networkPort;
  final PrinterModel printer;
  IminPrinter? iminPrinter;
  bool _isIminPrinter = false;
  List<int> _bytes = [];

  // Generator instance that will be created during initialization
  Generator? _generator;

  // Flag to track if generator initialization is in progress
  bool _isGeneratorInitializing = false;

  /// Constructor for ReceiptPrintUtils
  ///
  /// Allows customization of default values used throughout the utility methods
  ReceiptPrinterService({
    this.defaultTotalWidth = 12,
    this.defaultRightColumnWidth = 4,
    required this.paperWidth,
    this.networkTimeout = const Duration(seconds: 30),
    this.networkPort = 9100,
    required this.printer,
  });

  Future<void> init() async {
    await _initGenerator(); // Wait for generator initialization
    _isIminPrinter = isIminPrinter(printer);
    if (_isIminPrinter) {
      iminPrinter = IminPrinter();
      // await iminPrinter!.initPrinter();
      await iminPrinter!.setPrinterDensity(
        IminPrinterDensity.oneHundredAndTwenty,
      );
    } else {}
  }

  /// Initialize the generator asynchronously
  Future<void> _initGenerator() async {
    if (_generator != null || _isGeneratorInitializing) return;

    _isGeneratorInitializing = true;
    try {
      _generator = await createGenerator();
    } finally {
      _isGeneratorInitializing = false;
    }
  }

  /// Checks if the printer is an Imin brand printer
  static bool isIminPrinter(PrinterModel printer) {
    // compare this name
    // imin, iner, swan
    final name = printer.name?.toLowerCase() ?? '';

    final iminPattern = RegExp(r'i+ *m+ *i+ *n+', caseSensitive: false);
    final inerPattern = RegExp(r'i+ *n+ *e+ *r+', caseSensitive: false);
    final swanPattern = RegExp(r's+ *w+ *a+ *n+', caseSensitive: false);

    return iminPattern.hasMatch(name) ||
        inerPattern.hasMatch(name) ||
        swanPattern.hasMatch(name) ||
        name.contains('imin') ||
        name.contains('iner') ||
        name.contains('swan');
  }

  static List<int> convertCustomCommand(String customCommand) {
    return customCommand
        .toUpperCase()
        .split(',')
        .map((hex) => int.parse(hex, radix: 16))
        .toList();
  }

  Future<void> drawer({
    String? customCommand,
    required String activityFrom,
    required Ref ref,
  }) async {
    final cashDrawerLogNotifier = ref.read(cashDrawerLogProvider.notifier);

    if (_generator != null) {
      if (_isIminPrinter) {
        if (customCommand != null) {
          await iminPrinter!.sendRAWData(
            Uint8List.fromList(convertCustomCommand(customCommand)),
          );
        } else {
          // CRITICAL: Delay required to prevent race conditions in IMIN firmware
          // The IMIN hardware needs settling time between drawer commands:
          // 1. GPIO signals require time to stabilize and propagate through hardware layers
          // 2. Firmware command queue needs processing time before accepting new commands
          // 3. Solenoid motor requires time to complete mechanical actuation and reset
          // 4. Prevents rapid-fire commands from corrupting/dropping in firmware buffer
          // Without this delay, rapid successive calls cause intermittent failures
          await Future.delayed(const Duration(milliseconds: 1000));
          await iminPrinter!.openCashBox();
        }
      } else {
        if (customCommand != null) {
          _bytes += convertCustomCommand(customCommand);
        } else {
          _bytes += _generator!.drawer();
        }
      }

      String activity = activityFrom;
      if (activity.isEmpty) {
        activity = 'Open Drawer';
      }

      await cashDrawerLogNotifier.createAndInsertLog(activity);
    }
  }

  Future<void> printQRCode(String data) async {
    if (_generator != null) {
      if (_isIminPrinter) {
        await iminPrinter!.printQrCode(
          data,
          qrCodeStyle: IminQrCodeStyle(
            errorCorrectionLevel: IminQrcodeCorrectionLevel.levelH,
            qrSize: 5,
            align: IminPrintAlign.center,
          ),
        );
      } else {
        _bytes += _generator!.qrcode(
          data,
          size: QRSize.size5,
          cor: QRCorrection.H,
        );
      }
    }
  }

  Future<void> printImage(Uint8List imageBytes) async {
    if (_generator != null) {
      if (_isIminPrinter) {
        // Resize image for Imin printer before printing
        img.Image? decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null) {
          // Calculate target width based on paper size (similar to non-Imin printers)
          final int targetWidth = paperWidth == 'mm58'.tr() ? 192 : 288;

          // Resize image to fit printer width while maintaining aspect ratio
          img.Image resizedImage = img.copyResize(
            decodedImage,
            width: targetWidth,
          );

          // Encode back to PNG
          Uint8List resizedBytes = Uint8List.fromList(
            img.encodePng(resizedImage),
          );

          // Print without specifying width/height to use actual image dimensions
          await iminPrinter!.printSingleBitmap(
            resizedBytes,
            pictureStyle: IminPictureStyle(alignment: IminPrintAlign.center),
          );
        } else {
          // Fallback: print original if decode fails
          await iminPrinter!.printSingleBitmap(
            imageBytes,
            pictureStyle: IminPictureStyle(alignment: IminPrintAlign.center),
          );
        }
      } else {
        try {
          prints('=== IMAGE PRINTING DEBUG START ===');
          prints('Input image bytes length: ${imageBytes.length}');
          prints('Current buffer size before image: ${_bytes.length}');

          // Decode the image
          img.Image? decodedImage = img.decodeImage(imageBytes);

          if (decodedImage == null) {
            prints('ERROR: Failed to decode image');
            return;
          }

          prints(
            'Original image size: ${decodedImage.width}x${decodedImage.height}',
          );
          prints('Original image format: ${decodedImage.format}');
          prints('Original image numChannels: ${decodedImage.numChannels}');

          // Convert to RGB if image has alpha channel (4 channels)
          // Thermal printers work better with RGB or grayscale
          if (decodedImage.numChannels == 4) {
            prints('Image has alpha channel, removing it...');

            // Sample some pixels to see what we're working with
            prints('Sampling original RGBA pixels:');
            for (int i = 0; i < math.min(10, decodedImage.width); i++) {
              final pixel = decodedImage.getPixel(i, 0);
              prints(
                '  Pixel[$i,0]: R=${pixel.r.toInt()}, G=${pixel.g.toInt()}, B=${pixel.b.toInt()}, A=${pixel.a.toInt()}',
              );
            }

            // Sample center pixels
            final centerY = decodedImage.height ~/ 2;
            final centerX = decodedImage.width ~/ 2;
            prints('Sampling center pixels:');
            for (int i = -5; i <= 5; i++) {
              final x = centerX + i;
              if (x >= 0 && x < decodedImage.width) {
                final pixel = decodedImage.getPixel(x, centerY);
                prints(
                  '  Pixel[$x,$centerY]: R=${pixel.r.toInt()}, G=${pixel.g.toInt()}, B=${pixel.b.toInt()}, A=${pixel.a.toInt()}',
                );
              }
            }

            // Create new RGB image by removing alpha channel
            // Keep the RGB values as-is, ignore alpha
            final img.Image rgbImage = img.Image(
              width: decodedImage.width,
              height: decodedImage.height,
            );

            int transparentPixels = 0;
            int opaquePixels = 0;
            int darkRgbPixels = 0;

            for (int y = 0; y < decodedImage.height; y++) {
              for (int x = 0; x < decodedImage.width; x++) {
                final pixel = decodedImage.getPixel(x, y);
                // Extract RGB values
                final r = pixel.r.toInt();
                final g = pixel.g.toInt();
                final b = pixel.b.toInt();
                final a = pixel.a.toInt();

                // ALWAYS use RGB values, ignore alpha completely
                // This handles images where content is transparent but has RGB data
                rgbImage.setPixelRgb(x, y, r, g, b);

                // Track statistics
                if (a < 128) {
                  transparentPixels++;
                } else {
                  opaquePixels++;
                }

                // Check if RGB values are dark (regardless of alpha)
                final luminance = (r + g + b) ~/ 3;
                if (luminance < 128) {
                  darkRgbPixels++;
                }
              }
            }

            prints('Alpha channel statistics:');
            prints('  Transparent pixels (alpha < 128): $transparentPixels');
            prints('  Opaque pixels (alpha >= 128): $opaquePixels');
            prints('  Dark RGB pixels (luminance < 128): $darkRgbPixels');

            decodedImage = rgbImage;
            prints(
              'Alpha channel removed, numChannels: ${decodedImage.numChannels}',
            );
          }

          // Calculate paper width in pixels
          // Use smaller width to ensure compatibility
          final int paperWidthPixels = paperWidth == 'mm58'.tr() ? 192 : 288;
          prints('Target paper width: $paperWidthPixels pixels');

          // Resize image to fit printer width while maintaining aspect ratio
          img.Image resizedImage = img.copyResize(
            decodedImage,
            width: paperWidthPixels,
          );

          prints(
            'Resized image size: ${resizedImage.width}x${resizedImage.height}',
          );
          prints('Resized image format: ${resizedImage.format}');

          // Convert to grayscale first (thermal printers work with grayscale/BW)
          prints('Converting to grayscale...');
          img.Image grayscaleImage = img.grayscale(resizedImage);
          prints('Converted to grayscale');

          // Analyze pixel distribution before threshold
          int blackPixels = 0;
          int whitePixels = 0;
          int grayPixels = 0;

          for (int y = 0; y < grayscaleImage.height; y++) {
            for (int x = 0; x < grayscaleImage.width; x++) {
              final pixel = grayscaleImage.getPixel(x, y);
              final luminance = pixel.r.toInt();
              if (luminance < 85) {
                blackPixels++;
              } else if (luminance > 170) {
                whitePixels++;
              } else {
                grayPixels++;
              }
            }
          }

          final totalPixels = grayscaleImage.width * grayscaleImage.height;
          prints('Pixel analysis BEFORE threshold:');
          prints(
            '  Black pixels (<85): $blackPixels (${(blackPixels * 100 / totalPixels).toStringAsFixed(1)}%)',
          );
          prints(
            '  Gray pixels (85-170): $grayPixels (${(grayPixels * 100 / totalPixels).toStringAsFixed(1)}%)',
          );
          prints(
            '  White pixels (>170): $whitePixels (${(whitePixels * 100 / totalPixels).toStringAsFixed(1)}%)',
          );

          // Apply threshold to convert to pure black and white (1-bit)
          // This is critical for thermal printers
          prints('Applying threshold for black/white conversion...');
          // Use high threshold: only very bright pixels (near white) stay white
          // Everything else becomes black
          final int threshold = 240; // Only pixels > 240 stay white

          int blackPixelsAfter = 0;
          int whitePixelsAfter = 0;

          for (int y = 0; y < grayscaleImage.height; y++) {
            for (int x = 0; x < grayscaleImage.width; x++) {
              final pixel = grayscaleImage.getPixel(x, y);
              final luminance = pixel.r.toInt(); // In grayscale, r=g=b

              // Set pixel to pure white (255) or pure black (0)
              // Only very bright pixels (>240) stay white, everything else becomes black
              if (luminance > threshold) {
                grayscaleImage.setPixelRgb(x, y, 255, 255, 255); // White
                whitePixelsAfter++;
              } else {
                grayscaleImage.setPixelRgb(x, y, 0, 0, 0); // Black
                blackPixelsAfter++;
              }
            }
          }
          prints('Threshold applied, image is now pure black and white');
          prints('Pixel analysis AFTER threshold:');
          prints(
            '  Black pixels: $blackPixelsAfter (${(blackPixelsAfter * 100 / totalPixels).toStringAsFixed(1)}%)',
          );
          prints(
            '  White pixels: $whitePixelsAfter (${(whitePixelsAfter * 100 / totalPixels).toStringAsFixed(1)}%)',
          );

          // Store buffer size before adding image
          final int bufferSizeBefore = _bytes.length;

          // Try different image printing methods
          bool success = false;

          // Method 1: Try image() method (ESC * command)
          if (!success) {
            try {
              prints('Trying image() method...');
              final List<int> imageBytes = _generator!.image(
                grayscaleImage,
                align: PosAlign.center,
              );
              prints('image() generated ${imageBytes.length} bytes');
              _bytes += imageBytes;
              prints('Image bytes added using image() method');
              success = true;
            } catch (e) {
              prints('image() method failed: $e');
            }
          }

          // Method 2: Try imageRaster with bitImageRaster
          if (!success) {
            try {
              prints('Trying imageRaster() with bitImageRaster...');
              final List<int> imageBytes = _generator!.imageRaster(
                grayscaleImage,
                align: PosAlign.center,
                imageFn: PosImageFn.bitImageRaster,
              );
              prints(
                'imageRaster(bitImageRaster) generated ${imageBytes.length} bytes',
              );
              _bytes += imageBytes;
              prints('Image bytes added using imageRaster(bitImageRaster)');
              success = true;
            } catch (e) {
              prints('imageRaster(bitImageRaster) failed: $e');
            }
          }

          // Method 3: Try imageRaster with graphics
          if (!success) {
            try {
              prints('Trying imageRaster() with graphics...');
              final List<int> imageBytes = _generator!.imageRaster(
                grayscaleImage,
                align: PosAlign.center,
                imageFn: PosImageFn.graphics,
              );
              prints(
                'imageRaster(graphics) generated ${imageBytes.length} bytes',
              );
              _bytes += imageBytes;
              prints('Image bytes added using imageRaster(graphics)');
              success = true;
            } catch (e) {
              prints('imageRaster(graphics) failed: $e');
            }
          }

          if (!success) {
            prints('ERROR: All image printing methods failed!');
          }

          final int bufferSizeAfter = _bytes.length;
          prints(
            'Buffer size increased by: ${bufferSizeAfter - bufferSizeBefore} bytes',
          );
          prints('Total buffer size after image: $bufferSizeAfter');
          prints('=== IMAGE PRINTING DEBUG END ===');
        } catch (e) {
          prints('ERROR processing image for printing: $e');
          prints('Stack trace: ${StackTrace.current}');
        }
      }
    }
  }

  /// Converts text to an image and prints it, providing similar functionality to
  /// Imin's printTextBitmap for non-Imin printers
  Future<void> printTextAsBitmap(
    String text, {
    int fontSize = 24,
    bool wordWrap = true,
    PosAlign align = PosAlign.center,
    bool bold = false,
    bool underline = false,
    double? letterSpacing,
    double? lineHeight,
    bool reverseWhite = false,
  }) async {
    if (_generator == null) return;

    if (_isIminPrinter) {
      // For Imin printers, use the native printTextBitmap method
      await iminPrinter!.printTextBitmap(
        text,
        style: IminTextPictureStyle(
          fontSize: fontSize,
          wordWrap: wordWrap,
          align: _convertPosAlignToIminAlign(align),
          fontStyle: bold ? IminFontStyle.bold : IminFontStyle.normal,
          typeface: IminTypeface.typefaceDefault,
          underline: underline,
          throughline: false,
          reverseWhite: reverseWhite,
        ),
      );
    } else {
      // For non-Imin printers, convert text to image and print
      try {
        // Calculate paper width in pixels

        final int paperWidthPixels = paperWidth == 'mm58'.tr() ? 384 : 576;

        // Create a text style with the specified properties
        final TextStyle textStyle = TextStyle(
          fontSize: fontSize.toDouble(),
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: reverseWhite ? Colors.white : Colors.black,
          decoration:
              underline
                  ? TextDecoration.underline
                  : TextDecoration
                      .none, // Explicitly set to none when not underlined
          letterSpacing: letterSpacing,
          // Use provided lineHeight or set to 1.0 to avoid extra spacing
          height: lineHeight ?? 1.0,
          fontFamily: 'Roboto',
          fontFamilyFallback: [],
          decorationThickness:
              underline ? 1.0 : 0.0, // Set thickness to 0 when not underlined
        );

        // Create a text painter to measure and layout the text
        final TextPainter textPainter = TextPainter(
          text: TextSpan(text: text, style: textStyle),
          textDirection: ui.TextDirection.ltr,
          textAlign: _convertPosAlignToTextAlign(align),
        );

        // Layout the text with the available width
        textPainter.layout(maxWidth: paperWidthPixels.toDouble());

        // Create a picture recorder to draw the text
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);

        // Draw background if reverse white is enabled
        if (reverseWhite) {
          canvas.drawRect(
            Rect.fromLTWH(
              0,
              0,
              paperWidthPixels.toDouble(),
              textPainter.height,
            ),
            Paint()..color = Colors.black,
          );
        }

        // Calculate x position based on alignment
        double x = 0;
        switch (align) {
          case PosAlign.left:
            x = 0;
            break;
          case PosAlign.center:
            x = (paperWidthPixels - textPainter.width) / 2;
            break;
          case PosAlign.right:
            x = paperWidthPixels - textPainter.width;
            break;
        }

        // Draw the text on the canvas
        textPainter.paint(canvas, Offset(x, 0));

        // Convert the picture to an image - use exact height without rounding up
        final ui.Picture picture = recorder.endRecording();

        // Calculate the exact height needed for the text
        // Get the actual text height without any extra space
        final double textHeight = textPainter.height;

        // For text without underline, we can trim the height even more precisely
        // to avoid any extra space that might appear as a line
        final double adjustedHeight =
            underline ? textHeight : textHeight * 0.97;

        // Add a very small amount (0.1) to prevent text from being cut off
        // without creating excessive space
        final double slightlyAdjustedHeight = adjustedHeight + 0.7;
        // prints('slightlyAdjustedHeight: $slightlyAdjustedHeight');

        // If height is less than 1 pixel, use 1 to avoid errors
        final int imageHeight = math.max(1, slightlyAdjustedHeight.floor());

        final ui.Image uiImage = await picture.toImage(
          paperWidthPixels,
          imageHeight,
        );

        // Convert the UI image to bytes
        final ByteData? byteData = await uiImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData != null) {
          final Uint8List pngBytes = byteData.buffer.asUint8List();

          // Convert PNG to the format needed by the printer
          final img.Image image = img.decodeImage(pngBytes)!;

          // Add the image to the print buffer
          _bytes += _generator!.image(image);
        }
      } catch (e) {
        prints("Error converting text to image: $e");
        // Fallback to regular text printing if image conversion fails
        _bytes += _generator!.text(
          text,
          styles: PosStyles(
            align: align,
            bold: bold,
            underline: underline,
            reverse: reverseWhite,
          ),
        );
      }
    }
  }

  // Helper method to convert PosAlign to IminPrintAlign
  IminPrintAlign _convertPosAlignToIminAlign(PosAlign align) {
    switch (align) {
      case PosAlign.left:
        return IminPrintAlign.left;
      case PosAlign.center:
        return IminPrintAlign.center;
      case PosAlign.right:
        return IminPrintAlign.right;
    }
  }

  // Helper method to convert PosAlign to TextAlign
  TextAlign _convertPosAlignToTextAlign(PosAlign align) {
    switch (align) {
      case PosAlign.left:
        return TextAlign.left;
      case PosAlign.center:
        return TextAlign.center;
      case PosAlign.right:
        return TextAlign.right;
    }
  }

  Future<void> printTextCenter(String text, {bool isBold = false}) async {
    if (_generator != null) {
      // Use the new printTextAsBitmap method for both printer types
      await printTextAsBitmap(
        text,
        fontSize: 24,
        wordWrap: true,
        align: PosAlign.center,
        bold: isBold,
      );
    }
  }

  /// Formats a DateTime object into a standard receipt date/time format
  String formatDateTime({DateTime? receivedDateTime}) {
    DateTime dateTime = receivedDateTime ?? DateTime.now();
    String formattedDateTime = DateFormat(
      'dd/MM/yyyy h:mm a',
      'en_US',
    ).format(dateTime);
    return formattedDateTime;
  }

  /// Formats a DateTime object into a standard receipt date format
  String formatDate({DateTime? receivedDateTime}) {
    DateTime dateTime = receivedDateTime ?? DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy', 'en_US').format(dateTime);
    return formattedDate;
  }

  /// Formats a DateTime object into a standard receipt time format
  String formatTime({DateTime? receivedDateTime}) {
    DateTime dateTime = receivedDateTime ?? DateTime.now();
    String formattedTime = DateFormat('HH:mm', 'en_US').format(dateTime);
    return formattedTime;
  }

  Future<void> feed() async {
    if (_generator != null) {
      if (_isIminPrinter) {
        await iminPrinter!.printAndLineFeed();
      } else {
        _bytes += _generator!.feed(1);
      }
    }
  }

  Future<void> cut() async {
    if (_generator != null) {
      if (_isIminPrinter) {
        await iminPrinter!.partialCut();
      } else {
        // _bytes += _generator!.cut();
        _bytes += _generator!.cut(mode: PosCutMode.full);
      }
    }
  }

  /// Prints text with wrapping, handling left and right alignment
  /// This is commonly used for printing items with prices
  Future<void> printTextWithWrap(
    String text, {
    int? rightColumnWidth,
    String? rightText,
    PosTextSize textSizeLeft = PosTextSize.size1,
    PosTextSize textSizeRight = PosTextSize.size1,
    bool isBoldLeft = false,
    bool isBoldRight = false,
  }) async {
    // Generate commands for printing

    // Default total width for the row
    int totalWidth = defaultTotalWidth; // Total width for both columns combined
    int leftColumnWidth =
        totalWidth; // Default to full width when no right text

    if (rightText != null && rightText.isNotEmpty) {
      // If right text exists, use provided rightColumnWidth or default
      rightColumnWidth = rightColumnWidth ?? defaultRightColumnWidth;

      // Ensure rightColumnWidth doesn't exceed total width
      rightColumnWidth =
          rightColumnWidth > totalWidth ? totalWidth : rightColumnWidth;

      // Calculate leftColumnWidth as remaining space
      leftColumnWidth = totalWidth - rightColumnWidth;

      // Ensure leftColumnWidth is at least 1
      leftColumnWidth = leftColumnWidth < 1 ? 1 : leftColumnWidth;
    }

    if (_isIminPrinter) {
      // total width 575
      List<ColumnMaker> cols = [
        ColumnMaker(
          text: text,
          width: leftColumnWidth * 47,
          fontSize: ReceiptPrinterUtils.getFontSize(textSizeLeft),
          align: IminPrintAlign.left,
        ),
      ];

      if (rightText != null && rightText.isNotEmpty) {
        cols.add(
          ColumnMaker(
            text: rightText,
            width: rightColumnWidth! * 47,
            fontSize: ReceiptPrinterUtils.getFontSize(textSizeRight),
            align: IminPrintAlign.right,
          ),
        );
      }
      await iminPrinter!.printColumnsText(cols: cols);
    } else {
      // For non-Imin printers, use the bitmap approach for better formatting
      await _printTextWithWrapAsBitmap(
        text,
        rightText: rightText,
        leftColumnWidth: leftColumnWidth,
        rightColumnWidth: rightColumnWidth,
        fontSizeLeft: ReceiptPrinterUtils.getFontSize(textSizeLeft),
        fontSizeRight: ReceiptPrinterUtils.getFontSize(textSizeRight),
        isBoldLeft: isBoldLeft,
        isBoldRight: isBoldRight,
      );
    }
  }

  Future<void> printTextThreeColumn(
    String firstColumnText, // 3 characters max
    String secondColumnText,
    String thirdColumnText, {
    int thirdColumnWidth = 4,
    PosTextSize textSizeFirst = PosTextSize.size1,
    PosTextSize textSizeSecond = PosTextSize.size1,
    PosTextSize textSizeThird = PosTextSize.size1,
    bool isBoldFirst = false,
    bool isBoldSecond = false,
    bool isBoldThird = false,
  }) async {
    // Generate commands for printing

    // Default total width for the row
    int totalWidth = defaultTotalWidth;
    int firstColumnWidth = 4;

    // Use provided thirdColumnWidth or default
    thirdColumnWidth = thirdColumnWidth;

    // Ensure thirdColumnWidth doesn't exceed available space
    int availableWidth = totalWidth - firstColumnWidth;
    thirdColumnWidth =
        thirdColumnWidth > availableWidth ? availableWidth : thirdColumnWidth;

    // Calculate secondColumnWidth as remaining space
    int secondColumnWidth = totalWidth - firstColumnWidth - thirdColumnWidth;

    // Ensure secondColumnWidth is at least 1
    secondColumnWidth = secondColumnWidth < 1 ? 1 : secondColumnWidth;

    // Truncate first column text to 3 characters if needed
    // String truncatedFirstText =
    //     firstColumnText.length > 3
    //         ? firstColumnText.substring(0, 3)
    //         : firstColumnText;
    String truncatedFirstText = firstColumnText;

    if (_isIminPrinter) {
      // total width 575
      List<ColumnMaker> cols = [
        ColumnMaker(
          text: truncatedFirstText,
          width: firstColumnWidth * 47,
          fontSize: ReceiptPrinterUtils.getFontSize(textSizeFirst),
          align: IminPrintAlign.left,
        ),
        ColumnMaker(
          text: secondColumnText,
          width: secondColumnWidth * 47,
          fontSize: ReceiptPrinterUtils.getFontSize(textSizeSecond),
          align: IminPrintAlign.left,
        ),
        ColumnMaker(
          text: thirdColumnText,
          width: thirdColumnWidth * 47,
          fontSize: ReceiptPrinterUtils.getFontSize(textSizeThird),
          align: IminPrintAlign.right,
        ),
      ];

      await iminPrinter!.printColumnsText(cols: cols);
    } else {
      // For non-Imin printers, use the bitmap approach for better formatting
      prints("First column width $firstColumnWidth");
      prints("Second column width $secondColumnWidth");
      prints("Third column width $thirdColumnWidth");
      await _printTextThreeColumnAsBitmap(
        truncatedFirstText,
        secondColumnText,
        thirdColumnText,
        firstColumnWidth: firstColumnWidth,
        secondColumnWidth: secondColumnWidth,
        thirdColumnWidth: thirdColumnWidth,
        fontSizeFirst: ReceiptPrinterUtils.getFontSize(textSizeFirst),
        fontSizeSecond: ReceiptPrinterUtils.getFontSize(textSizeSecond),
        fontSizeThird: ReceiptPrinterUtils.getFontSize(textSizeThird),
        isBoldFirst: isBoldFirst,
        isBoldSecond: isBoldSecond,
        isBoldThird: isBoldThird,
      );
    }
  }

  /// Helper method to print two-column text as bitmap for non-Imin printers
  /// This provides better formatting and font consistency
  Future<void> _printTextWithWrapAsBitmap(
    String leftText, {
    String? rightText,
    required int leftColumnWidth,
    int? rightColumnWidth,
    int fontSizeLeft = 24,
    int fontSizeRight = 24,
    bool isBoldLeft = false,
    bool isBoldRight = false,
  }) async {
    if (_generator == null) return;

    try {
      // Calculate paper width in pixels
      final int paperWidthPixels = paperWidth == 'mm58'.tr() ? 384 : 576;

      // Calculate column widths in pixels
      final double pixelsPerColumn = paperWidthPixels / defaultTotalWidth;
      final double leftWidthPixels = leftColumnWidth * pixelsPerColumn;
      final double rightWidthPixels =
          rightColumnWidth != null ? rightColumnWidth * pixelsPerColumn : 0;

      // Create text styles for left and right columns
      final TextStyle leftStyle = TextStyle(
        fontSize: fontSizeLeft.toDouble(),
        fontWeight: isBoldLeft ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
        fontFamilyFallback: [],
        height: 1.0, // Set exact line height to avoid extra spacing
        decoration:
            TextDecoration.none, // Explicitly set to none to prevent underline
        decorationThickness: 0.0, // Set thickness to 0
      );

      final TextStyle rightStyle = TextStyle(
        fontSize: fontSizeRight.toDouble(),
        fontWeight: isBoldRight ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
        fontFamilyFallback: [],
        height: 1.0, // Set exact line height to avoid extra spacing
        decoration:
            TextDecoration.none, // Explicitly set to none to prevent underline
        decorationThickness: 0.0, // Set thickness to 0
      );

      // Create text painters for measuring and layout
      final TextPainter leftPainter = TextPainter(
        text: TextSpan(text: leftText, style: leftStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      // Layout the left text with its available width
      leftPainter.layout(maxWidth: leftWidthPixels);

      // Create a right painter if right text exists
      TextPainter? rightPainter;
      if (rightText != null && rightText.isNotEmpty) {
        rightPainter = TextPainter(
          text: TextSpan(text: rightText, style: rightStyle),
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.right,
        );

        // Layout the right text with its available width
        rightPainter.layout(maxWidth: rightWidthPixels);
      }

      // Determine the height of the row (use the taller of the two columns)
      final double rowHeight =
          rightPainter != null
              ? math.max(leftPainter.height, rightPainter.height)
              : leftPainter.height;

      // Create a picture recorder to draw the text
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the left text
      leftPainter.paint(canvas, Offset(0, 0));

      // Draw the right text if it exists
      if (rightPainter != null) {
        // Position the right text at the right edge of the paper
        final double rightX = paperWidthPixels - rightPainter.width;
        rightPainter.paint(canvas, Offset(rightX, 0));
      }

      // Convert the picture to an image - use exact height without rounding up
      final ui.Picture picture = recorder.endRecording();

      // Calculate the exact height needed for the text
      // For text without underline, we can trim the height slightly
      // to avoid any extra space that might appear as a line
      final double adjustedHeight = rowHeight * 0.95;

      // If height is less than 1 pixel, use 1 to avoid errors
      final int imageHeight = math.max(1, adjustedHeight.floor());

      final ui.Image uiImage = await picture.toImage(
        paperWidthPixels,
        imageHeight,
      );

      // Convert the UI image to bytes
      final ByteData? byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Convert PNG to the format needed by the printer
        final img.Image image = img.decodeImage(pngBytes)!;

        // Add the image to the print buffer
        _bytes += _generator!.image(image);
      }
    } catch (e) {
      prints("Error converting two-column text to image: $e");

      // Fallback to regular row printing if image conversion fails
      List<PosColumn> columns = [
        PosColumn(
          text: leftText,
          width: leftColumnWidth,
          styles: PosStyles(align: PosAlign.left, bold: isBoldLeft),
        ),
      ];

      if (rightText != null &&
          rightText.isNotEmpty &&
          rightColumnWidth != null) {
        columns.add(
          PosColumn(
            text: rightText,
            width: rightColumnWidth,
            styles: PosStyles(align: PosAlign.right, bold: isBoldRight),
          ),
        );
      }

      _bytes += _generator!.row(columns);
    }
  }

  /// Helper method to print three-column text as bitmap for non-Imin printers
  /// This provides better formatting and font consistency
  /// Helper method to print three-column text as bitmap for non-Imin printers
  /// This provides better formatting and font consistency
  /// Helper method to print three-column text as bitmap for non-Imin printers
  /// This provides better formatting and font consistency
  /// Helper method to print three-column text as bitmap for non-Imin printers
  /// This provides better formatting and font consistency
  Future<void> _printTextThreeColumnAsBitmap(
    String firstText,
    String secondText,
    String thirdText, {
    required int firstColumnWidth,
    required int secondColumnWidth,
    required int thirdColumnWidth,
    int fontSizeFirst = 24,
    int fontSizeSecond = 24,
    int fontSizeThird = 24,
    bool isBoldFirst = false,
    bool isBoldSecond = false,
    bool isBoldThird = false,
  }) async {
    if (_generator == null) return;

    try {
      // Calculate paper width in pixels
      final int paperWidthPixels = paperWidth == 'mm58'.tr() ? 384 : 576;

      // Calculate column widths in pixels
      final double pixelsPerColumn = paperWidthPixels / defaultTotalWidth;
      final double firstWidthPixels = firstColumnWidth * pixelsPerColumn;
      final double secondWidthPixels = secondColumnWidth * pixelsPerColumn;
      final double thirdWidthPixels = thirdColumnWidth * pixelsPerColumn;

      // Create text styles for all three columns
      final TextStyle firstStyle = TextStyle(
        fontSize: fontSizeFirst.toDouble(),
        fontWeight: isBoldFirst ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
        fontFamilyFallback: [],
        height: 1.0, // Set exact line height to avoid extra spacing
        decoration:
            TextDecoration.none, // Explicitly set to none to prevent underline
        decorationThickness: 0.0, // Set thickness to 0
      );

      final TextStyle secondStyle = TextStyle(
        fontSize: fontSizeSecond.toDouble(),
        fontWeight: isBoldSecond ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
        fontFamilyFallback: [],
        height: 1.0, // Set exact line height to avoid extra spacing
        decoration:
            TextDecoration.none, // Explicitly set to none to prevent underline
        decorationThickness: 0.0, // Set thickness to 0
      );

      final TextStyle thirdStyle = TextStyle(
        fontSize: fontSizeThird.toDouble(),
        fontWeight: isBoldThird ? FontWeight.bold : FontWeight.normal,
        color: Colors.black,
        fontFamily: 'Roboto',
        fontFamilyFallback: [],
        height: 1.0, // Set exact line height to avoid extra spacing
        decoration:
            TextDecoration.none, // Explicitly set to none to prevent underline
        decorationThickness: 0.0, // Set thickness to 0
      );

      // Create text painters for measuring and layout
      final TextPainter firstPainter = TextPainter(
        text: TextSpan(text: firstText, style: firstStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      final TextPainter secondPainter = TextPainter(
        text: TextSpan(text: secondText, style: secondStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      final TextPainter thirdPainter = TextPainter(
        text: TextSpan(text: thirdText, style: thirdStyle),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.right,
      );

      // Layout all text painters with their available widths
      firstPainter.layout(maxWidth: firstWidthPixels);
      secondPainter.layout(maxWidth: secondWidthPixels);
      thirdPainter.layout(maxWidth: thirdWidthPixels);

      // Determine the height of the row (use the tallest of the three columns)
      final double rowHeight = math.max(
        firstPainter.height,
        math.max(secondPainter.height, thirdPainter.height),
      );

      // Create a picture recorder to draw the text
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the first column (left-aligned at start)
      firstPainter.paint(canvas, Offset(0, 0));

      // Draw the second column (left-aligned after first column with some spacing)
      // Add spacing equivalent to about 2 characters after the first column
      final double spacingPixels = 2 * (pixelsPerColumn);
      final double secondX = firstWidthPixels + spacingPixels;
      secondPainter.paint(canvas, Offset(secondX, 0));

      // Draw the third column (right-aligned at the right edge of the paper)
      final double thirdX = paperWidthPixels - thirdPainter.width;
      thirdPainter.paint(canvas, Offset(thirdX, 0));

      // Convert the picture to an image - use exact height without rounding up
      final ui.Picture picture = recorder.endRecording();

      // Calculate the exact height needed for the text
      // For text without underline, we can trim the height slightly
      // to avoid any extra space that might appear as a line
      final double adjustedHeight = rowHeight * 0.95;

      // If height is less than 1 pixel, use 1 to avoid errors
      final int imageHeight = math.max(1, adjustedHeight.floor());

      final ui.Image uiImage = await picture.toImage(
        paperWidthPixels,
        imageHeight,
      );

      // Convert the UI image to bytes
      final ByteData? byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Convert PNG to the format needed by the printer
        final img.Image image = img.decodeImage(pngBytes)!;

        // Add the image to the print buffer
        _bytes += _generator!.image(image);
      }
    } catch (e) {
      prints("Error converting three-column text to image: $e");

      // Fallback to regular row printing if image conversion fails
      List<PosColumn> columns = [
        PosColumn(
          text: firstText,
          width: firstColumnWidth,
          styles: PosStyles(align: PosAlign.left, bold: isBoldFirst),
        ),
        PosColumn(
          text: secondText,
          width: secondColumnWidth,
          styles: PosStyles(align: PosAlign.left, bold: isBoldSecond),
        ),
        PosColumn(
          text: thirdText,
          width: thirdColumnWidth,
          styles: PosStyles(align: PosAlign.right, bold: isBoldThird),
        ),
      ];

      _bytes += _generator!.row(columns);
    }
  }

  /// Generates a line of characters (e.g., dashes) for visual separation in receipts
  String generateLine(String character, bool isHaveSpace) {
    final buffer = StringBuffer();
    // 32 if 58mm
    // 48 if 80mm
    int totalLength = paperWidth == 'mm58'.tr() ? 32 : 48;

    // Calculate the pattern to repeat, either with or without spaces
    String pattern = isHaveSpace ? '$character ' : character;

    // Repeat the pattern until it fills up to the total length
    while (buffer.length + pattern.length <= totalLength) {
      buffer.write(pattern);
    }

    // Trim to exactly the total length if necessary
    return buffer.toString().substring(0, totalLength);
  }

  /// Prints a dashed line for visual separation in receipts
  Future<void> printDashedLine({
    String character = '-',
    bool isHaveSpace = false,
  }) async {
    // Generate the line with exactly the right number of characters
    final line = generateLine(character, isHaveSpace);

    // Use the new printTextAsBitmap method for both printer types
    await printTextAsBitmap(
      line,
      fontSize: 43, // Adjust font size as needed
      wordWrap: true,
      align: PosAlign.center,
    );
  }

  /// Prints a centered title with optional styling
  Future<void> printTitle(
    String text, {
    bool bold = true,
    PosTextSize textSize = PosTextSize.size2,
  }) async {
    // Use the new printTextAsBitmap method for both printer types
    await printTextAsBitmap(
      text,
      fontSize: ReceiptPrinterUtils.getFontSize(textSize),
      wordWrap: true,
      align: PosAlign.center,
      bold: bold,
    );
  }

  void resetBytes() {
    _bytes = [];
  }

  /// Sends print data to the printer with error handling
  Future<bool> sendPrintData(
    Function(String message, String ipAddress) onError, {
    bool haveCut = true,
  }) async {
    // final List<int> escPos = await customEscPos(isCustom: true);
    // await iminPrinter!.sendRAWData(Uint8List.fromList(_bytes));

    // return true;
    if (haveCut) {
      await cut();
    }
    _bytes += _generator!.reset();
    if (!_isIminPrinter) {
      try {
        if (printer.connectionType == ConnectionTypeEnum.NETWORK) {
          // For network printers
          prints("Printing to network printer at ${printer.address}");
          final service = FlutterThermalPrinterNetwork(
            printer.address!,
            port: networkPort,
            timeout: networkTimeout,
          );

          try {
            prints("Connected to network printer, sending data...");
            prints(_bytes);
            NetworkPrintResult result = await service.printTicket(_bytes);

            if (result.value == NetworkPrintResult.success.value) {
              prints("Data sent to network printer");
              return true;
            } else {
              prints("Failed to send data to network printer. ${result.msg}");
              onError(result.msg, printer.address!);
              return false;
            }
          } catch (e) {
            prints("Error with network printer: $e");
            onError(e.toString(), printer.address!);
            return false;
          }
        } else {
          // For USB/BLE printers
          prints(
            "Printing to Bluetooth/USB printer ${printer.name} (${printer.address})",
          );
          prints("Print data bytes length: ${_bytes.length}");
          prints("Printer connection status: ${printer.isConnected}");
          try {
            prints("Calling FlutterThermalPrinter.instance.printData...");
            await FlutterThermalPrinter.instance.printData(printer, _bytes);
            prints("Data sent to Bluetooth/USB printer successfully");
            return true;
          } catch (e) {
            prints("Error sending data to Bluetooth/USB printer: $e");

            // Try reconnecting and printing again
            prints("Attempting to reconnect and print again...");
            try {
              await FlutterThermalPrinter.instance.connect(printer);
              prints("Reconnected to printer, sending data again...");
              await FlutterThermalPrinter.instance.printData(printer, _bytes);
              prints("Data sent to printer after reconnection");
              return true;
            } catch (e2) {
              prints("Error after reconnection attempt: $e2");
              if (e2.toString().contains('DEVICE_NOT_FOUND')) {
                onError('Device Not Found', printer.address!);
              } else {
                onError(e2.toString(), printer.address!);
              }

              return false;
            }
          }
        }
      } catch (e) {
        prints("Unexpected error during printing: $e");
        onError(e.toString(), printer.address!);
        return false;
      }
    } else {
      await iminPrinter!.resetDevice();
    }

    return true;
  }

  /// Creates a printer generator with the appropriate paper size
  Future<Generator> createGenerator() async {
    // Get the profile for the printer
    final profile = await CapabilityProfile.load();

    // Create a generator for the printer
    final paperSize =
        paperWidth == 'mm58'.tr() ? PaperSize.mm58 : PaperSize.mm80;
    prints("paperSize: ${paperWidth == 'mm58'.tr()}");

    return Generator(paperSize, profile);
  }

  /// Convert paper width enum to string representation
  static String getPaperWidth(String? paperWidth) {
    // must receive 1 or 2
    if (paperWidth != null) {
      if (paperWidth == PaperWidthEnum.paperWidth80mm) {
        return 'mm80'.tr();
      } else {
        return 'mm58'.tr();
      }
    }
    return 'mm58'.tr();
  }

  // // Static methods for backward compatibility

  // /// Static method for backward compatibility
  // static bool isIminPrinterStatic(PrinterModel printer) {
  //   return instance.isIminPrinter(printer);
  // }

  // /// Static method for backward compatibility
  // static String formatDateTimeStatic({DateTime? receivedDateTime}) {
  //   return instance.formatDateTime(receivedDateTime: receivedDateTime);
  // }

  // /// Static method for backward compatibility
  // static String formatDateStatic({DateTime? receivedDateTime}) {
  //   return instance.formatDate(receivedDateTime: receivedDateTime);
  // }

  // /// Static method for backward compatibility
  // static String formatTimeStatic({DateTime? receivedDateTime}) {
  //   return instance.formatTime(receivedDateTime: receivedDateTime);
  // }

  // /// Static method for backward compatibility
  // static List<int> printTextWithWrapStatic(
  //   Generator generator,
  //   String text, {
  //   int? rightColumnWidth,
  //   String? rightText,
  //   PosTextSize textSizeLeft = PosTextSize.size1,
  //   PosTextSize textSizeRight = PosTextSize.size1,
  //   bool isBoldLeft = false,
  //   bool isBoldRight = false,
  // }) {
  //   return instance.printTextWithWrap(
  //     generator,
  //     text,
  //     rightColumnWidth: rightColumnWidth,
  //     rightText: rightText,
  //     textSizeLeft: textSizeLeft,
  //     textSizeRight: textSizeRight,
  //     isBoldLeft: isBoldLeft,
  //     isBoldRight: isBoldRight,
  //   );
  // }

  // /// Static method for backward compatibility
  // static String generateLineStatic(
  //   String character,
  //   bool isHaveSpace,
  //   String paperWidth,
  // ) {
  //   return instance.generateLine(character, isHaveSpace, paperWidth);
  // }

  // /// Static method for backward compatibility
  // static List<int> printDashedLineStatic(
  //   Generator generator,
  //   String paperWidth, {
  //   String character = '-',
  //   bool isHaveSpace = false,
  // }) {
  //   return instance.printDashedLine(
  //     generator,
  //     paperWidth,
  //     character: character,
  //     isHaveSpace: isHaveSpace,
  //   );
  // }

  // /// Static method for backward compatibility
  // static List<int> printTitleStatic(
  //   Generator generator,
  //   String text, {
  //   bool bold = true,
  //   PosTextSize textSize = PosTextSize.size2,
  // }) {
  //   return instance.printTitle(generator, text, bold: bold, textSize: textSize);
  // }

  // /// Static method for backward compatibility
  // static Future<bool> sendPrintDataStatic(
  //   PrinterModel printer,
  //   List<int> bytes,
  //   Function(String message, String ipAddress) onError,
  // ) {
  //   return instance.sendPrintData(printer, bytes, onError);
  // }

  // /// Static method for backward compatibility
  // static Future<Generator> createGeneratorStatic(String paperWidth) {
  //   return instance.createGenerator(paperWidth);
  // }

  // /// Static method for backward compatibility
  // static String getPaperWidthStatic(String? paperWidth) {
  //   return instance.getPaperWidth(paperWidth);
  // }

  // // For backward compatibility with existing code
  // static bool isIminPrinter(PrinterModel printer) {
  //   return instance.isIminPrinter(printer);
  // }

  // static String formatDateTime({DateTime? receivedDateTime}) {
  //   return instance.formatDateTime(receivedDateTime: receivedDateTime);
  // }

  // static String formatDate({DateTime? receivedDateTime}) {
  //   return instance.formatDate(receivedDateTime: receivedDateTime);
  // }

  // static String formatTime({DateTime? receivedDateTime}) {
  //   return instance.formatTime(receivedDateTime: receivedDateTime);
  // }

  // static List<int> printTextWithWrap(
  //   Generator generator,
  //   String text, {
  //   int? rightColumnWidth,
  //   String? rightText,
  //   PosTextSize textSizeLeft = PosTextSize.size1,
  //   PosTextSize textSizeRight = PosTextSize.size1,
  //   bool isBoldLeft = false,
  //   bool isBoldRight = false,
  // }) {
  //   return instance.printTextWithWrap(
  //     generator,
  //     text,
  //     rightColumnWidth: rightColumnWidth,
  //     rightText: rightText,
  //     textSizeLeft: textSizeLeft,
  //     textSizeRight: textSizeRight,
  //     isBoldLeft: isBoldLeft,
  //     isBoldRight: isBoldRight,
  //   );
  // }

  // static String generateLine(
  //   String character,
  //   bool isHaveSpace,
  //   String paperWidth,
  // ) {
  //   return instance.generateLine(character, isHaveSpace, paperWidth);
  // }

  // static List<int> printDashedLine(
  //   Generator generator,
  //   String paperWidth, {
  //   String character = '-',
  //   bool isHaveSpace = false,
  // }) {
  //   return instance.printDashedLine(
  //     generator,
  //     paperWidth,
  //     character: character,
  //     isHaveSpace: isHaveSpace,
  //   );
  // }

  // static List<int> printTitle(
  //   Generator generator,
  //   String text, {
  //   bool bold = true,
  //   PosTextSize textSize = PosTextSize.size2,
  // }) {
  //   return instance.printTitle(generator, text, bold: bold, textSize: textSize);
  // }

  // static Future<bool> sendPrintData(
  //   PrinterModel printer,
  //   List<int> bytes,
  //   Function(String message, String ipAddress) onError,
  // ) {
  //   return instance.sendPrintData(printer, bytes, onError);
  // }

  // static Future<Generator> createGenerator(String paperWidth) {
  //   return instance.createGenerator(paperWidth);
  // }

  // static String getPaperWidth(String? paperWidth) {
  //   return instance.getPaperWidth(paperWidth);
  // }
}
