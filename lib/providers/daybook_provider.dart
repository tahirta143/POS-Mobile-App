import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daybook_model.dart';
import '../services/api_service.dart';

class DaybookProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;
  double _openingBalance = 0.0;
  List<DaybookTransactionModel> _transactions = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  double get openingBalance => _openingBalance;
  List<DaybookTransactionModel> get transactions => _transactions;

  DaybookProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchDaybook(String date) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/daybook?date=$date');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parsed = DaybookResponseModel.fromJson(data);
        _openingBalance = parsed.openingBalance;
        _transactions = parsed.transactions;
      } else {
        _error = 'Failed to load daybook data.';
        _transactions = [];
        _openingBalance = 0.0;
      }
    } catch (_) {
      _error = 'Failed to load daybook data.';
      _transactions = [];
      _openingBalance = 0.0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> setOpeningBalance(double amount, String date) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/daybook/opening-balance', {
        'amount': amount,
        'date': date,
      });

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchDaybook(date);
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Failed to update opening balance.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to update opening balance.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}
