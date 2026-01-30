import 'dart:convert';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/tax/tax_list_response_model.dart';
import 'package:mts/data/models/tax/tax_model.dart';
import 'package:mts/domain/repositories/remote/tax_repository.dart';

class TaxRepositoryImpl implements TaxRepository {
  @override
  Resource getTaxList(String page) {
    return Resource(
      modelName: TaxModel.modelName,
      url: 'taxes/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return TaxListResponseModel(json.decode(response.body));
      },
    );
  }
}
