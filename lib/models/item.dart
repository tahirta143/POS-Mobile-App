class ItemModel {
  final int? id;
  final String itemName;
  final double purchasePrice;
  final double salePrice;
  final double stock;
  final int itemCategoryId;
  final int? itemTypeId;
  final int? itemSubcategoryId;
  final int? manufacturerId;
  final int? supplierId;
  final int? shelveLocationId;
  final int? itemUnitId;
  final String? barCode;
  final String description;
  final double reorder;
  final int perUnit;
  final bool isEnable;
  final String? itemImage;

  // View properties returned by GET APIs
  final String? categoryName;
  final String? typeName;
  final String? manufacturerName;
  final String? supplierName;
  final String? subcategoryName;
  final String? locationName;
  final String? unitName;

  ItemModel({
    this.id,
    required this.itemName,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    required this.itemCategoryId,
    this.itemTypeId,
    this.itemSubcategoryId,
    this.manufacturerId,
    this.supplierId,
    this.shelveLocationId,
    this.itemUnitId,
    this.barCode,
    required this.description,
    required this.reorder,
    required this.perUnit,
    required this.isEnable,
    this.itemImage,
    this.categoryName,
    this.typeName,
    this.manufacturerName,
    this.supplierName,
    this.subcategoryName,
    this.locationName,
    this.unitName,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numbers
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int? toInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    bool toBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      return val.toString() == '1' || val.toString().toLowerCase() == 'true';
    }

    return ItemModel(
      id: json['id'],
      itemName: json['itemName'] ?? json['item_name'] ?? '',
      purchasePrice: toDouble(json['purchasePrice'] ?? json['purchase_price']),
      salePrice: toDouble(json['salePrice'] ?? json['sale_price']),
      stock: toDouble(json['stock'] ?? json['opening_stock']),
      itemCategoryId: toInt(json['itemCategoryId'] ?? json['item_category_id'] ?? json['category_id']) ?? 0,
      itemTypeId: toInt(json['itemTypeId'] ?? json['item_type_id']),
      itemSubcategoryId: toInt(json['itemSubcategoryId'] ?? json['item_subcategory_id'] ?? json['subcategory_id']),
      manufacturerId: toInt(json['manufacturerId'] ?? json['manufacturer_id'] ?? json['manufacturer']),
      supplierId: toInt(json['supplierId'] ?? json['supplier_id'] ?? json['supplier']),
      shelveLocationId: toInt(json['shelveLocationId'] ?? json['shelve_location_id'] ?? json['store_location']),
      itemUnitId: toInt(json['itemUnitId'] ?? json['item_unit_id'] ?? json['item_unit']),
      barCode: json['barCode'] ?? json['label_barcode'] ?? json['barcode'],
      description: json['description'] ?? json['details'] ?? '',
      reorder: toDouble(json['reorder'] ?? json['reorder_level']),
      perUnit: toInt(json['perUnit'] ?? json['per_unit']) ?? 1,
      isEnable: toBool(json['isEnable'] ?? json['is_enable']),
      itemImage: json['itemImage'] ?? json['image_name'],
      categoryName: json['category_name'],
      typeName: json['type_name'],
      manufacturerName: json['manufacturer_name'],
      supplierName: json['supplier_name'],
      subcategoryName: json['sub_category_name'],
      locationName: json['shelf_name_code'] ?? json['store_location_name'],
      unitName: json['unit_name'],
    );
  }

  Map<String, String> toFormFields() {
    return {
      if (id != null) 'id': id.toString(),
      'itemName': itemName,
      'purchasePrice': purchasePrice.toString(),
      'salePrice': salePrice.toString(),
      'stock': stock.toString(),
      'itemCategoryId': itemCategoryId.toString(),
      if (itemTypeId != null) 'itemTypeId': itemTypeId!.toString(),
      if (itemSubcategoryId != null) 'itemSubcategoryId': itemSubcategoryId!.toString(),
      if (manufacturerId != null) 'manufacturerId': manufacturerId!.toString(),
      if (supplierId != null) 'supplierId': supplierId!.toString(),
      if (shelveLocationId != null) 'shelveLocationId': shelveLocationId!.toString(),
      if (itemUnitId != null) 'itemUnitId': itemUnitId!.toString(),
      if (barCode != null && barCode!.isNotEmpty) 'barCode': barCode!,
      'description': description,
      'reorder': reorder.toString(),
      'perUnit': perUnit.toString(),
      'isEnable': (isEnable ? 1 : 0).toString(),
    };
  }
}
