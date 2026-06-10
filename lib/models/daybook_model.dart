class DaybookTransactionModel {
  final String? dateTime;
  final String? reference;
  final String type;
  final String description;
  final double cashIn;
  final double cashOut;

  DaybookTransactionModel({
    this.dateTime,
    this.reference,
    required this.type,
    required this.description,
    required this.cashIn,
    required this.cashOut,
  });

  factory DaybookTransactionModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return DaybookTransactionModel(
      dateTime: json['dateTime']?.toString() ?? json['date_time']?.toString(),
      reference: json['reference']?.toString(),
      type: json['type']?.toString() ?? 'OTHER',
      description: json['description']?.toString() ?? '',
      cashIn: toDouble(json['cashIn'] ?? json['cash_in']),
      cashOut: toDouble(json['cashOut'] ?? json['cash_out']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime,
      'reference': reference,
      'type': type,
      'description': description,
      'cashIn': cashIn,
      'cashOut': cashOut,
    };
  }
}

class DaybookResponseModel {
  final double openingBalance;
  final List<DaybookTransactionModel> transactions;

  DaybookResponseModel({
    required this.openingBalance,
    required this.transactions,
  });

  factory DaybookResponseModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final List rawTxns = json['transactions'] is List ? json['transactions'] : [];
    return DaybookResponseModel(
      openingBalance: toDouble(json['openingBalance'] ?? json['opening_balance']),
      transactions: rawTxns.map((e) => DaybookTransactionModel.fromJson(e)).toList(),
    );
  }
}
