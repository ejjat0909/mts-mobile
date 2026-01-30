import 'dart:convert';

import 'package:mts/core/utils/date_time_utils.dart';
import 'package:mts/core/utils/format_utils.dart';

class SlideshowModel {
  /// Model name for sync handler registry
  static const String modelName = 'Slideshow';
  static const String modelBoxName = 'slideshow_box';
  String? id;
  String? title;
  String? description;
  String? greetings;
  String? feedbackDescription;
  String? outletId;
  List<String>? images;
  List<String>? imageNames;
  String? promotionlink;
  List<String>? downloadUrls;
  String? qrPaymentPath;
  String? qrPaymentUrl;
  DateTime? createdAt;
  DateTime? updatedAt;

  SlideshowModel({
    this.id,
    this.title,
    this.outletId,
    this.description,
    this.greetings,
    this.feedbackDescription,
    this.images,
    this.imageNames,
    this.promotionlink,
    this.downloadUrls,
    this.qrPaymentPath,
    this.qrPaymentUrl,
    this.createdAt,
    this.updatedAt,
  });

  SlideshowModel.fromJson(Map<String, dynamic> json) {
    id = FormatUtils.parseToString(json['id']);
    title = FormatUtils.parseToString(json['title']);
    outletId = FormatUtils.parseToString(json['outlet_id']);
    description = FormatUtils.parseToString(json['description']);
    greetings = FormatUtils.parseToString(json['greetings']);
    feedbackDescription = FormatUtils.parseToString(
      json['feedback_description'],
    );
    promotionlink = FormatUtils.parseToString(json['promotion_link']);
    qrPaymentPath = FormatUtils.parseToString(json['qr_payment_path']);
    qrPaymentUrl = FormatUtils.parseToString(json['qr_payment_url']);

    // Use the helper method for both fields
    images = parseStringList(json['images']);
    imageNames = parseStringList(json['image_names']);
    downloadUrls = parseStringList(json['download_urls']);

    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['outlet_id'] = outletId;
    data['description'] = description;
    data['greetings'] = greetings;
    data['feedback_description'] = feedbackDescription;
    data['qr_payment_path'] = qrPaymentPath;
    if (qrPaymentUrl != null) {
      data['qr_payment_url'] = qrPaymentUrl;
    }

    // Convert lists to JSON strings for storage
    if (images != null) {
      data['images'] = jsonEncode(images);
    }

    if (imageNames != null) {
      data['image_names'] = jsonEncode(imageNames);
    }

    data['promotion_link'] = promotionlink;

    if (downloadUrls != null) {
      data['download_urls'] = jsonEncode(downloadUrls);
    }

    if (createdAt != null) {
      data['created_at'] = DateTimeUtils.getDateTimeFormat(createdAt);
    }
    if (updatedAt != null) {
      data['updated_at'] = DateTimeUtils.getDateTimeFormat(updatedAt);
    }

    return data;
  }

  // copy with
  SlideshowModel copyWith({
    String? id,
    String? title,
    String? outletId,
    String? description,
    String? greetings,
    String? feedbackDescription,
    List<String>? images,
    List<String>? imageNames,
    String? promotionlink,
    List<String>? downloadUrls,
    String? qrPaymentPath,
    String? qrPaymentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SlideshowModel(
      id: id ?? this.id,
      title: title ?? this.title,
      outletId: outletId ?? this.outletId,
      description: description ?? this.description,
      greetings: greetings ?? this.greetings,
      feedbackDescription: feedbackDescription ?? this.feedbackDescription,
      images: images ?? this.images,
      imageNames: imageNames ?? this.imageNames,
      promotionlink: promotionlink ?? this.promotionlink,
      qrPaymentPath: qrPaymentPath ?? this.qrPaymentPath,
      qrPaymentUrl: qrPaymentUrl ?? this.qrPaymentUrl,
      downloadUrls: downloadUrls ?? this.downloadUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to parse a field that can be either a List<String> or a String
  /// Returns a List<String> in either case
  static List<String>? parseStringList(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is List) {
      // If it's already a list, use it directly
      return List<String>.from(value);
    } else if (value is String) {
      // If it's a string, try to parse it as JSON
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return List<String>.from(decoded);
        } else {
          // If it's not a valid JSON list, store as a single-item list
          return [value];
        }
      } catch (e) {
        // If parsing fails, store as a single-item list
        return [value];
      }
    }

    // For any other type, return null
    return null;
  }
}
