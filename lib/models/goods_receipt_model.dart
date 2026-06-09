class GrnItemModel {
  final String itemName;
  final String? categoryName;
  final int quantity;
  final double purchasePrice;
  final double total;

  GrnItemModel({
    required this.itemName,
    this.categoryName,
    required this.quantity,
    required this.purchasePrice,
    required this.total,
  });

  factory GrnItemModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return GrnItemModel(
      itemName: json['item_name']?.toString() ?? '',
      categoryName: json['category_name']?.toString(),
      quantity: toInt(json['quantity'] ?? json['qty']),
      purchasePrice: toDouble(json['purchase_price'] ?? json['price']),
      total: toDouble(json['total']),
    );
  }
}

class PurchaseOrderModel {
  final int id;
  final String? grnNo;
  final String? invoiceNo;
  final String supplierName;
  final double payable;
  final String? createdAt;
  final List<GrnItemModel> items;

  PurchaseOrderModel({
    required this.id,
    this.grnNo,
    this.invoiceNo,
    required this.supplierName,
    required this.payable,
    this.createdAt,
    required this.items,
  });

  String get displayRef => grnNo ?? invoiceNo ?? 'PO-$id';

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawItems = json['items'];
    final List<GrnItemModel> itemList = rawItems is List
        ? rawItems.map((i) => GrnItemModel.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    return PurchaseOrderModel(
      id: toInt(json['id']),
      grnNo: json['grn_no']?.toString(),
      invoiceNo: json['invoice_no']?.toString(),
      supplierName: json['supplier_name']?.toString() ?? '',
      payable: toDouble(json['payable']),
      createdAt: json['created_at']?.toString(),
      items: itemList,
    );
  }
}
