import 'package:mts/data/datasources/remote/resource.dart';

/// Interface for User Repository
abstract class UserRepository {
  /// Validate license key
  Resource validateLicense(String licenseKey);

  /// Get list of users
  Resource getListUsers();
  
  /// Get list of users with pagination
  Resource getListUsersWithPagination(String page);

  /// Get current user data
  Resource me();

  /// Logout user and revoke token
  Resource logout();

  /// Login with email and password
  Resource login(String email, String password, String licenseKey);

  /// Login using PIN
  Resource loginUsingPin(String pin);

  /// Verify email with OTP
  Resource verifyEmail(String username, String otp);

  /// Resend email verification
  Resource resendEmail(String username);

  /// Get user details by user ID
  Resource userDetails(int userId);
}
