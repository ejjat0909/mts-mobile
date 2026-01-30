import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/network/web_service.dart';
import 'package:mts/data/datasources/remote/resource.dart';
import 'package:mts/data/models/cash_management/cash_management_list_response_model.dart';
import 'package:mts/data/models/cash_management/cash_management_model.dart';
import 'package:mts/data/services/remote_pagination_service.dart';
import 'package:mts/domain/repositories/remote/cash_management_repository.dart';
import 'package:mts/providers/core/core_providers.dart';
import 'package:mts/providers/services/service_providers.dart';

/// ================================
/// Provider for Remote Repository
/// ================================
final cashManagementRemoteRepoProvider =
    Provider<RemoteCashManagementRepository>((ref) {
      return RemoteCashManagementRepositoryImpl(
        webService: ref.read(webServiceProvider),
        paginationService: ref.read(remotePaginationServiceProvider),
      );
    });

/// Implementation of the Remote Cash Management Repository
class RemoteCashManagementRepositoryImpl
    implements RemoteCashManagementRepository {
  final RemotePaginationService _paginationService;

  RemoteCashManagementRepositoryImpl({
    required IWebService webService,
    required RemotePaginationService paginationService,
  }) : _paginationService = paginationService;

  /// Get list of cash management records with pagination
  ///
  /// This method returns a Resource object that can be used to fetch
  /// cash management records from the API with pagination.
  ///
  /// @param page The page number to fetch
  @override
  Resource getCashManagementListPaginated(String page) {
    return Resource(
      modelName: CashManagementModel.modelName,
      url: 'cash-managements/list',
      params: {'page': page, 'take': take},
      parse: (response) {
        return CashManagementListResponseModel(json.decode(response.body));
      },
    );
  }

  /// Fetch all cash management records from all pages
  ///
  /// This method handles pagination internally and returns all records.
  /// Follows Clean Architecture: repository layer owns data fetching logic.
  @override
  Future<List<CashManagementModel>> fetchAllPaginated() async {
    return await _paginationService.fetchAllPaginated<
      CashManagementModel,
      CashManagementListResponseModel
    >(
      getPagedResource: (page) => getCashManagementListPaginated(page),
      extractData: (response) => response.data,
      extractPaginator: (response) => response.paginator,
      extractMessage: (response) => response.message,
      checkSuccess: (response) => response.isSuccess,
      entityName: CashManagementModel.modelName,
    );
  }
}
