class SaleInvoiceModel {
  final int id;
  final String? receiptNo;
  final String? customerName;
  final int? customerId;
  final double paid;
  final List<SaleItemModel> items;

  SaleInvoiceModel({
    required this.id,
    this.receiptNo,
    this.customerName,
    this.customerId,
    required this.paid,
    required this.items,
  });

  String get displayRef => receiptNo ?? 'INV-$id';

  factory SaleInvoiceModel.fromJson(Map<String, dynamic> json) {
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
    final List<SaleItemModel> itemList = rawItems is List
        ? rawItems.map((i) => SaleItemModel.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    return SaleInvoiceModel(
      id: toInt(json['id']),
      receiptNo: json['receipt_no']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerId: json['customer_id'] == null ? null : toInt(json['customer_id']),
      paid: toDouble(json['paid'] ?? json['paid_amount']),
      items: itemList,
    );
  }
}

class SaleItemModel {
  final int itemId;
  final String itemName;
  final double price;
  final double total;
  final int qty;
  double returnQty;

  SaleItemModel({
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.total,
    required this.qty,
    this.returnQty = 0,
  });

  double get unitRate => qty > 0 ? total / qty : price;
  double get creditAmount => returnQty * unitRate;

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
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

    return SaleItemModel(
      itemId: toInt(json['item_id'] ?? json['id']),
      itemName: json['item_name']?.toString() ?? '',
      price: toDouble(json['sale_price'] ?? json['price']),
      total: toDouble(json['total']),
      qty: toInt(json['qty'] ?? json['quantity']),
    );
  }
}

class SalesReturnModel {
  final int id;
  final String? customerName;
  final String? invoiceRef;
  final int? saleInvoiceId;
  final double discount;
  final double totalAmount;
  final String? returnDate;

  SalesReturnModel({
    required this.id,
    this.customerName,
    this.invoiceRef,
    this.saleInvoiceId,
    required this.discount,
    required this.totalAmount,
    this.returnDate,
  });

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) {
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

    return SalesReturnModel(
      id: toInt(json['id']),
      customerName: json['customer_name']?.toString(),
      invoiceRef: json['invoice_ref']?.toString() ?? json['receipt_no']?.toString(),
      saleInvoiceId: json['sale_invoice_id'] == null ? null : toInt(json['sale_invoice_id']),
      discount: toDouble(json['discount']),
      totalAmount: toDouble(json['total_amount']),
      returnDate: json['return_date']?.toString(),
    );
  }
}
