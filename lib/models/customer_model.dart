class CustomerModel {
  final int? id;
  final String customerName;
  final String address;
  final String mobileNumber;
  final double previousBalance;
  final String nearby;
  final String paymentMethod;

  CustomerModel({
    this.id,
    required this.customerName,
    required this.address,
    required this.mobileNumber,
    required this.previousBalance,
    required this.nearby,
    required this.paymentMethod,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return CustomerModel(
      id: toInt(json['id']),
      customerName: json['customer_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      previousBalance: toDouble(json['previous_balance']),
      nearby: json['nearby']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'address': address,
      'mobileNumber': mobileNumber,
      'previousBalance': previousBalance,
      'nearby': nearby,
      'paymentMethod': paymentMethod,
    };
  }

  CustomerModel copyWith({
    int? id,
    String? customerName,
    String? address,
    String? mobileNumber,
    double? previousBalance,
    String? nearby,
    String? paymentMethod,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      previousBalance: previousBalance ?? this.previousBalance,
      nearby: nearby ?? this.nearby,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
