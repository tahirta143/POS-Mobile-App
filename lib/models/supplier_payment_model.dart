class SupplierPurchaseModel {
  final int id;
  final String? invoiceNo;
  final int supplierId;
  final double toBePaid;
  final String? supplierName;
  final String? phone;

  SupplierPurchaseModel({
    required this.id,
    this.invoiceNo,
    required this.supplierId,
    required this.toBePaid,
    this.supplierName,
    this.phone,
  });

  String get displayRef => invoiceNo != null && invoiceNo!.isNotEmpty ? 'INV-$invoiceNo' : 'PO-$id';

  factory SupplierPurchaseModel.fromJson(Map<String, dynamic> json) {
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

    return SupplierPurchaseModel(
      id: toInt(json['id']),
      invoiceNo: json['invoice_no']?.toString(),
      supplierId: toInt(json['supplier_id'] ?? json['supplierId']),
      toBePaid: toDouble(json['to_be_paid'] ?? json['toBePaid']),
      supplierName: json['supplier_name']?.toString() ?? json['supplier']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString() ?? json['mobile_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_no': invoiceNo,
      'supplier_id': supplierId,
      'to_be_paid': toBePaid,
      'supplier_name': supplierName,
      'phone': phone,
    };
  }
}

class SupplierPaymentModel {
  final int? id;
  final int supplierId;
  final String? supplierName;
  final int? purchaseId;
  final String? invoiceNo;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String note;

  SupplierPaymentModel({
    this.id,
    required this.supplierId,
    this.supplierName,
    this.purchaseId,
    this.invoiceNo,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.note,
  });

  factory SupplierPaymentModel.fromJson(Map<String, dynamic> json) {
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

    return SupplierPaymentModel(
      id: json['id'] != null ? toInt(json['id']) : null,
      supplierId: toInt(json['supplier_id'] ?? json['supplierId']),
      supplierName: json['supplier_name']?.toString() ?? json['supplier']?.toString(),
      purchaseId: json['purchase_id'] != null ? toInt(json['purchase_id']) : (json['purchaseId'] != null ? toInt(json['purchaseId']) : null),
      invoiceNo: json['invoice_no']?.toString(),
      amount: toDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString() ?? 'Cash',
      paymentDate: json['payment_date']?.toString() ?? json['paymentDate']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'purchaseId': purchaseId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'note': note,
    };
  }
}
