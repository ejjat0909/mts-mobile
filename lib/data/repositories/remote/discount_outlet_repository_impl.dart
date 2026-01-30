import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_list_response_model.dart';
import 'package:mts/data/models/discount_outlet/discount_outlet_model.dart';
import 'package:mts/domain/repositories/remote/discount_outlet_repository.dart';

class DiscountOutletRepositoryImpl implements DiscountOutletRepository {
  // Local data source would be injected here
  // final DiscountOutletLocalDataSource localDataSource;

  // DiscountOutletRepositoryImpl(this.localDataSource);

  /// Get list of discount outlets from remote without pagination
  @override
  Resource getDiscountOutlet() {
    return Resource(
      modelName: DiscountOutletModel.modelName,
      url: 'discount-outlet/list',
      parse: (response) {
        return DiscountOutletListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Get list of discount outlets from remote with pagination
  @override
  Resource getDiscountOutletList(String page) {
    return Resource(
      modelName: DiscountOutletModel.modelName,
      url: 'discount-outlet/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return DiscountOutletListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Insert a new discount outlet
  @override
  Future<int> insert(DiscountOutletModel row) {
    // Implementation would use local data source
    throw UnimplementedError();
  }
}
