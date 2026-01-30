/// A class representing a key-value pair for pivot table operations.
///
/// This class is used to specify column name and value pairs when
/// performing operations on pivot tables in the database.
class PivotElement {
  final String columnName;
  final String value;

  PivotElement({required this.columnName, required this.value});
}
