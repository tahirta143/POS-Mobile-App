class PurchaseModel {
  final int id;
  final String? grnNo;
  final String? invoiceNo;
  final String supplierName;
  final int? supplierId;
  final List<PurchaseItemModel> items;

  PurchaseModel({
    required this.id,
    this.grnNo,
    this.invoiceNo,
    required this.supplierName,
    this.supplierId,
    required this.items,
  });

  String get displayRef => grnNo ?? invoiceNo ?? 'PUR-$id';

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final rawItems = json['items'];
    final List<PurchaseItemModel> itemList = rawItems is List
        ? rawItems.map((i) => PurchaseItemModel.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    return PurchaseModel(
      id: toInt(json['id']),
      grnNo: json['grn_no']?.toString(),
      invoiceNo: json['invoice_no']?.toString(),
      supplierName: json['supplier_name']?.toString() ?? '',
      supplierId: json['supplier_id'] == null ? null : toInt(json['supplier_id']),
      items: itemList,
    );
  }
}

class PurchaseItemModel {
  final int itemId;
  final String itemName;
  final double purchasePrice;
  final int quantity; // inward qty
  double returnQty;

  PurchaseItemModel({
    required this.itemId,
    required this.itemName,
    required this.purchasePrice,
    required this.quantity,
    this.returnQty = 0,
  });

  double get returnTotal => returnQty * purchasePrice;

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
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

    return PurchaseItemModel(
      itemId: toInt(json['item_id'] ?? json['id']),
      itemName: json['item_name']?.toString() ?? '',
      purchasePrice: toDouble(json['purchase_price'] ?? json['price']),
      quantity: toInt(json['qty'] ?? json['quantity']),
    );
  }
}

class PurchaseReturnModel {
  final int id;
  final int? purchaseId;
  final String supplierName;
  final double totalAmount;
  final String? returnDate;

  PurchaseReturnModel({
    required this.id,
    this.purchaseId,
    required this.supplierName,
    required this.totalAmount,
    this.returnDate,
  });

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) {
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

    return PurchaseReturnModel(
      id: toInt(json['id']),
      purchaseId: json['purchase_id'] == null ? null : toInt(json['purchase_id']),
      supplierName: json['supplier_name']?.toString() ?? 'Generic Supplier',
      totalAmount: toDouble(json['total_amount']),
      returnDate: json['return_date']?.toString(),
    );
  }
}
