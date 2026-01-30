import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Receipt Settings Repository
abstract class ReceiptSettingsRepository {
  Resource getListReceiptSettings();
}
