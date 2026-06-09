// Model for a sale invoice record from the API
class SaleInvoiceListModel {
  final int id;
  final String? receiptNo;
  final String? customerName;
  final int? customerId;
  final String? mobileNumber;
  final String? description;
  final double discount;
  final double givenAmount;
  final double subTotal;
  final double payable;
  final double toBePaid;
  final String? status;
  final List<SaleInvoiceItemModel> items;

  SaleInvoiceListModel({
    required this.id,
    this.receiptNo,
    this.customerName,
    this.customerId,
    this.mobileNumber,
    this.description,
    required this.discount,
    required this.givenAmount,
    required this.subTotal,
    required this.payable,
    required this.toBePaid,
    this.status,
    required this.items,
  });

  String get displayRef => receiptNo ?? 'INV-$id';

  String get paymentStatus {
    if (toBePaid <= 0) return 'Paid';
    if (givenAmount > 0) return 'Partial';
    return 'Unpaid';
  }

  factory SaleInvoiceListModel.fromJson(Map<String, dynamic> json) {
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
    final List<SaleInvoiceItemModel> itemList = rawItems is List
        ? rawItems
            .map((i) => SaleInvoiceItemModel.fromJson(i as Map<String, dynamic>))
            .toList()
        : [];

    return SaleInvoiceListModel(
      id: toInt(json['id']),
      receiptNo: json['receipt_no']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerId:
          json['customer_id'] == null ? null : toInt(json['customer_id']),
      mobileNumber: json['mobile']?.toString() ?? json['mobile_number']?.toString(),
      description: json['description']?.toString(),
      discount: toDouble(json['discount']),
      givenAmount: toDouble(json['paid'] ?? json['given_amount']),
      subTotal: toDouble(json['sub_total'] ?? json['subTotal']),
      payable: toDouble(json['payable']),
      toBePaid: toDouble(json['to_be_paid'] ?? json['toBePaid']),
      status: json['status']?.toString(),
      items: itemList,
    );
  }
}

// Model for an item within a sale invoice
class SaleInvoiceItemModel {
  final int itemId;
  final String itemName;
  final int? categoryId;
  final double salePrice;
  final int qty;
  final double total;

  SaleInvoiceItemModel({
    required this.itemId,
    required this.itemName,
    this.categoryId,
    required this.salePrice,
    required this.qty,
    required this.total,
  });

  factory SaleInvoiceItemModel.fromJson(Map<String, dynamic> json) {
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

    return SaleInvoiceItemModel(
      itemId: toInt(json['item_id'] ?? json['id']),
      itemName: json['item_name']?.toString() ?? '',
      categoryId:
          json['category_id'] == null ? null : toInt(json['category_id']),
      salePrice: toDouble(json['sale_price'] ?? json['price']),
      qty: toInt(json['qty'] ?? json['quantity']),
      total: toDouble(json['total']),
    );
  }
}

// Transient UI model for a cart row in the invoice form
class CartRowModel {
  final String id; // local unique id for list key
  int? categoryId;
  int? itemId;
  double price;
  int quantity;
  double total;

  CartRowModel({
    required this.id,
    this.categoryId,
    this.itemId,
    this.price = 0.0,
    this.quantity = 1,
    this.total = 0.0,
  });

  void recalculate() {
    total = price * quantity;
  }

  CartRowModel copyWith({
    int? categoryId,
    int? itemId,
    double? price,
    int? quantity,
  }) {
    final row = CartRowModel(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
    row.total = row.price * row.quantity;
    return row;
  }
}
