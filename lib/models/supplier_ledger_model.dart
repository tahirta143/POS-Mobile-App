import 'lookup_data.dart';

class LedgerTransactionModel {
  final String? date;
  final String reference;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  LedgerTransactionModel({
    this.date,
    required this.reference,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  factory LedgerTransactionModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return LedgerTransactionModel(
      date: json['date']?.toString(),
      reference: json['reference']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      debit: toDouble(json['debit']),
      credit: toDouble(json['credit']),
      balance: toDouble(json['balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'reference': reference,
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance': balance,
    };
  }
}

class SupplierLedgerResponseModel {
  final SupplierModel? supplier;
  final List<LedgerTransactionModel> ledger;
  final double closingBalance;

  SupplierLedgerResponseModel({
    this.supplier,
    required this.ledger,
    required this.closingBalance,
  });

  factory SupplierLedgerResponseModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final List rawLedger = json['ledger'] is List ? json['ledger'] : [];
    return SupplierLedgerResponseModel(
      supplier: json['supplier'] != null ? SupplierModel.fromJson(json['supplier']) : null,
      ledger: rawLedger.map((e) => LedgerTransactionModel.fromJson(e)).toList(),
      closingBalance: toDouble(json['closingBalance'] ?? json['closing_balance']),
    );
  }
}
