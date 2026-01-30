/// Validation utility functions
class ValidationUtils {
  /// Validate required field
  static String? validateRequired(dynamic value) {
    if (value == null ||
        value == false ||
        ((value is Iterable || value is String || value is Map) &&
            value.length == 0)) {
      return 'Please fill in this field';
    } else if (value is String && value.length >= 255) {
      return 'Too Long (Max 255 Characters)';
    }
    return null;
  }

  /// Validate numeric field
  static String? validateNumeric(String number) {
    if (int.tryParse(number) == null) {
      return 'Must be numeric character';
    }
    return null;
  }

  /// Validate decimal point
  static String? validateDecimalPoint(String input) {
    if (input.contains('.')) {
      if (input.split('.').last.length > 2) {
        return 'Must have only two decimals point';
      }
    }

    return null;
  }

  /// Validate double field
  static String? validateDouble(String number) {
    if (double.tryParse(number) == null) {
      return 'Must be numeric character';
    }
    return null;
  }

  static String? numberCannotNegative(String number) {
    if (double.tryParse(number) == null) {
      return 'Must be numeric character';
    }
    if (double.parse(number) < 0) {
      return 'Value cannot be less than zero';
    }
    return null;
  }

  /// Validate username
  static String? validateUsername(String username) {
    // lower case
    if (!RegExp(r'^[a-z0-9_\(\)\|]+$').hasMatch(username.trim())) {
      return 'Only lowercase and ( , ) , _ , | are allowed';
    } else if (username.trim().length > 15) {
      return 'The username you enter is too long';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'The password must have at least 8 characters';
    } else if (password.length > 40) {
      return 'The password you enter is too long';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String name) {
    if (name.trim().length < 4) {
      return 'The name must have at least 4 characters';
    } else if (name.trim().length > 255) {
      return 'The name you enter is too long';
    }
    return null;
  }

  /// Validate email
  static String? validateEmail(String email) {
    if (email.isNotEmpty) {
      if (email.trim().length < 4 ||
          email.trim().length > 40 ||
          !RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
          ).hasMatch(email.trim())) {
        return 'Invalid Email';
      }
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String phoneNo) {
    if (phoneNo.length < 10) {
      return 'Invalid Phone Number';
    } else if (phoneNo.length > 11) {
      return 'Invalid Phone Number';
    }
    return null;
  }

  /// Validate NRIC
  static String? validateNRIC(String nric) {
    if (nric.length != 12) {
      return 'Must 12 numeric characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(
    String password,
    String confirmPassword,
  ) {
    if (password != confirmPassword) {
      return "Passwords doesn't match!";
    }
    return null;
  }

  /// Validate OTP
  static String? validateOTP(String otp, String serverOTP) {
    if (otp != serverOTP) {
      return 'OTP is not correct!';
    }
    return null;
  }

  /// Validate comma-separated values for cash drawer
  ///
  /// Validates that the input string contains only comma-separated values
  /// where each value can contain alphanumeric characters (0-9, A-Z) and minus signs
  /// Example valid format: "10,90,80" or "-10,90,-80" or "1B,70,00,19,FA"
  /// Example invalid format: "10, 90, 80" or "10.5,90,80"
  static String? validateCashDrawer(String input) {
    if (input.isEmpty) {
      return null;
    }

    // Check if the input contains only alphanumeric characters (0-9, A-Z), commas, and minus signs
    if (!RegExp(r'^-?[0-9A-Z]+(,-?[0-9A-Z]+)*$').hasMatch(input)) {
      return 'Must contain only comma-separated values with alphanumeric characters (0-9, A-Z)';
    }

    return null;
  }
}
