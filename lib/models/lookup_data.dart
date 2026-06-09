class LookupModel {
  final int id;
  final String name;
  final bool isEnabled;
  final int? parentId; // used for subcategories linking to category

  LookupModel({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.parentId,
  });
}

class CategoryModel {
  final int id;
  final String categoryName;
  final bool isEnable;

  CategoryModel({
    required this.id,
    required this.categoryName,
    required this.isEnable,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      categoryName: json['category_name'] ?? '',
      isEnable: json['is_enable'] == 1 || json['is_enable'] == true,
    );
  }
}

class ItemTypeModel {
  final int id;
  final String typeName;
  final bool isEnable;

  ItemTypeModel({
    required this.id,
    required this.typeName,
    required this.isEnable,
  });

  factory ItemTypeModel.fromJson(Map<String, dynamic> json) {
    return ItemTypeModel(
      id: json['id'],
      typeName: json['type_name'] ?? '',
      isEnable: json['is_enable'] == 1 || json['is_enable'] == true,
    );
  }
}

class ManufacturerModel {
  final int id;
  final String manufacturerName;
  final bool status;

  ManufacturerModel({
    required this.id,
    required this.manufacturerName,
    required this.status,
  });

  factory ManufacturerModel.fromJson(Map<String, dynamic> json) {
    return ManufacturerModel(
      id: json['id'],
      manufacturerName: json['manufacturer_name'] ?? '',
      status: json['status'] == 1 || json['status'] == true,
    );
  }
}

class SupplierModel {
  final int id;
  final String supplierName;
  final bool status;

  SupplierModel({
    required this.id,
    required this.supplierName,
    required this.status,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      supplierName: json['supplier_name'] ?? '',
      status: json['status'] == 1 || json['status'] == true,
    );
  }
}

class LocationModel {
  final int id;
  final String shelfNameCode;
  final String description;

  LocationModel({
    required this.id,
    required this.shelfNameCode,
    required this.description,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      shelfNameCode: json['shelf_name_code'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class UnitModel {
  final int id;
  final String unitName;

  UnitModel({
    required this.id,
    required this.unitName,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'],
      unitName: json['unit_name'] ?? '',
    );
  }
}

class SubcategoryModel {
  final int id;
  final String subCategoryName;
  final int categoryId;

  SubcategoryModel({
    required this.id,
    required this.subCategoryName,
    required this.categoryId,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'],
      subCategoryName: json['sub_category_name'] ?? '',
      categoryId: json['category_id'] is int ? json['category_id'] : int.parse(json['category_id'].toString()),
    );
  }
}
