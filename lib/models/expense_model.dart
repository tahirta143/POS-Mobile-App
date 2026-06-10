export 'expense_head_model.dart';


class ExpenseVoucherModel {
  final int? id;
  final String voucherDate;
  final int headId;
  final String? headName;
  final String details;
  final double amount;

  ExpenseVoucherModel({
    this.id,
    required this.voucherDate,
    required this.headId,
    this.headName,
    required this.details,
    required this.amount,
  });

  factory ExpenseVoucherModel.fromJson(Map<String, dynamic> json) {
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

    // head can be an object or a nested field
    String? headNameVal;
    if (json['head'] is Map) {
      headNameVal = json['head']['name']?.toString() ?? json['head']['head']?.toString();
    }
    headNameVal ??= json['head_name']?.toString() ?? json['head_head']?.toString();

    return ExpenseVoucherModel(
      id: json['id'] != null ? toInt(json['id']) : null,
      voucherDate: json['voucher_date']?.toString() ?? '',
      headId: toInt(json['head_id']),
      headName: headNameVal,
      details: json['details']?.toString() ?? '',
      amount: toDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voucher_date': voucherDate,
      'head_id': headId,
      'details': details,
      'amount': amount,
    };
  }
}
