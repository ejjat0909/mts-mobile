/// String utility functions
class StringUtils {
  /// Check if a string is numeric
  static bool isNumeric(String s) {
    return double.tryParse(s) != null;
  }

  /// Check if a string is empty or null
  static bool isNullOrEmpty(String? s) {
    return s == null || s.isEmpty;
  }

  /// Check if a string is not empty and not null
  static bool isNotNullOrEmpty(String? s) {
    return s != null && s.isNotEmpty;
  }

  /// Capitalize first letter of a string
  static String capitalizeFirstLetter(String s) {
    if (isNullOrEmpty(s)) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Capitalize each word in a string
  static String capitalizeEachWord(String s) {
    if (isNullOrEmpty(s)) return '';
    return s.split(' ').map((word) => capitalizeFirstLetter(word)).join(' ');
  }

  /// Truncate a string to a maximum length
  static String truncate(String s, int maxLength, {String suffix = '...'}) {
    if (isNullOrEmpty(s) || s.length <= maxLength) return s;
    return s.substring(0, maxLength) + suffix;
  }

  /// Remove all whitespace from a string
  static String removeWhitespace(String s) {
    return s.replaceAll(RegExp(r'\s+'), '');
  }

  /// Remove all non-alphanumeric characters from a string
  static String removeNonAlphanumeric(String s) {
    return s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Remove all non-numeric characters from a string
  static String removeNonNumeric(String s) {
    return s.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Remove all non-alphabetic characters from a string
  static String removeNonAlphabetic(String s) {
    return s.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  /// Convert a string to snake_case
  static String toSnakeCase(String s) {
    return s
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  /// Convert a string to camelCase
  static String toCamelCase(String s) {
    return s
        .replaceAllMapped(
          RegExp(r'_([a-z])'),
          (match) => match.group(1)!.toUpperCase(),
        )
        .replaceAllMapped(
          RegExp(r' ([a-z])'),
          (match) => match.group(1)!.toUpperCase(),
        );
  }

  /// Convert a string to PascalCase
  static String toPascalCase(String s) {
    String camelCase = toCamelCase(s);
    return capitalizeFirstLetter(camelCase);
  }

  /// Convert a string to kebab-case
  static String toKebabCase(String s) {
    return toSnakeCase(s).replaceAll('_', '-');
  }

  static String convertPermissionNameToDesc(String input) {
    // Split by '::' and take the last part
    String part = input.split('::').last;

    // Replace underscores with spaces
    part = part.replaceAll('_', ' ');

    // Capitalize each word
    part = part
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : '',
        )
        .join(' ');

    return part;
  }
}
