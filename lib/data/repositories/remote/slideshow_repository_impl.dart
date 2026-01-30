import 'dart:convert';

import 'package:mts/app/di/service_locator.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/outlet/outlet_model.dart';
import 'package:mts/data/models/slideshow/slideshow_list_response_model.dart';
import 'package:mts/data/models/slideshow/slideshow_model.dart';
import 'package:mts/domain/repositories/remote/slideshow_repository.dart';

/// Implementation of [SlideshowRepository]
class SlideshowRepositoryImpl implements SlideshowRepository {
  /// Get list of slideshows
  @override
  Resource getSlideshows() {
    final OutletModel outletModel = ServiceLocator.get<OutletModel>();

    return Resource(
      modelName: SlideshowModel.modelName,
      url: 'slideshows/list',
      params: {'outlet': outletModel.id},
      parse: (response) {
        return SlideshowListResponseModel(json.decode(response.body));
      },
    );
  }
}
