import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Payment Type Repository
abstract class PaymentTypeRepository {
  Resource getPaymentType();

  Resource getPaymentTypeWithPagination(String page);
}
