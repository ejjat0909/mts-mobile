import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for Permission Repository
abstract class PermissionRepository {
  Resource getAllPermissions();
}
