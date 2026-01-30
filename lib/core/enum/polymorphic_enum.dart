class PolymorphicEnum {
  static const String item = 'App/Models/Item';
  static const String category = 'App/Models/Category';
  static const String page = 'App/Models/Page';
  static const String modifier = 'App/Models/Modifier';
  static const String modifierOption = 'App/Models/ModifierOption';
  static const String variant = 'App/Models/Variant';
  static const String variantOption = 'App/Models/VariantOption';
  static const String pageItem = 'App/Models/PageItem';
  static const String saleItem = 'App/Models/SaleItem';

  static List<String> get values => [
    item,
    category,
    page,
    modifier,
    modifierOption,
    variant,
    variantOption,
    pageItem,
    saleItem,
  ];
}
