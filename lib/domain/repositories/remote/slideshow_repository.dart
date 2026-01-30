import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Remote Slideshow Repository
abstract class SlideshowRepository {
  /// Get list of slideshows
  Resource getSlideshows();
}
