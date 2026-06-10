class CustomerPaymentModel {
  final int? id;
  final int customerId;
  final String? customerName;
  final int? invoiceId;
  final String? receiptNo;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String remarks;

  CustomerPaymentModel({
    this.id,
    required this.customerId,
    this.customerName,
    this.invoiceId,
    this.receiptNo,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.remarks,
  });

  factory CustomerPaymentModel.fromJson(Map<String, dynamic> json) {
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

    return CustomerPaymentModel(
      id: json['id'] != null ? toInt(json['id']) : null,
      customerId: toInt(json['customer_id'] ?? json['customerId']),
      customerName: json['customer_name']?.toString() ?? json['customer']?.toString(),
      invoiceId: json['invoice_id'] != null ? toInt(json['invoice_id']) : (json['invoiceId'] != null ? toInt(json['invoiceId']) : null),
      receiptNo: json['receipt_no']?.toString(),
      amount: toDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString() ?? 'Cash',
      paymentDate: json['payment_date']?.toString() ?? json['paymentDate']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'remarks': remarks,
    };
  }
}

class BookingModel {
  final int id;
  final String bookingDate;
  final int customerId;
  final String? customerName;
  final double toBePaid;
  final String? mobileNumber;

  BookingModel({
    required this.id,
    required this.bookingDate,
    required this.customerId,
    this.customerName,
    required this.toBePaid,
    this.mobileNumber,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
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

    return BookingModel(
      id: toInt(json['id']),
      bookingDate: json['booking_date']?.toString() ?? '',
      customerId: toInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      toBePaid: toDouble(json['to_be_paid'] ?? json['toBePaid']),
      mobileNumber: json['mobile']?.toString() ?? json['mobile_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_date': bookingDate,
      'customer_id': customerId,
      'to_be_paid': toBePaid,
      'mobile_number': mobileNumber,
    };
  }
}

class BookingPaymentModel {
  final int id;
  final int bookingId;
  final int? customerId;
  final String? customerName;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String remarks;

  BookingPaymentModel({
    required this.id,
    required this.bookingId,
    this.customerId,
    this.customerName,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.remarks,
  });

  factory BookingPaymentModel.fromJson(Map<String, dynamic> json) {
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

    return BookingPaymentModel(
      id: toInt(json['id']),
      bookingId: toInt(json['booking_id'] ?? json['bookingId']),
      customerId: json['customer_id'] != null ? toInt(json['customer_id']) : null,
      customerName: json['customer_name']?.toString() ?? json['customer']?.toString(),
      amount: toDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? json['paymentMethod']?.toString() ?? 'Cash',
      paymentDate: json['payment_date']?.toString() ?? json['paymentDate']?.toString() ?? '',
      remarks: json['remarks'] ?? json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'remarks': remarks,
    };
  }
}
