import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loadingHeads = false;
  bool _loadingVouchers = false;
  bool _submitting = false;
  String? _error;
  List<ExpenseHeadModel> _heads = [];
  List<ExpenseVoucherModel> _vouchers = [];

  bool get loadingHeads => _loadingHeads;
  bool get loadingVouchers => _loadingVouchers;
  bool get loading => _loadingHeads || _loadingVouchers;
  bool get submitting => _submitting;
  String? get error => _error;
  List<ExpenseHeadModel> get heads => _heads;
  List<ExpenseVoucherModel> get vouchers => _vouchers;

  ExpenseProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchHeads() async {
    _loadingHeads = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/expense-heads');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _heads = raw.map((e) => ExpenseHeadModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load expense heads.';
      }
    } catch (_) {
      _error = 'Failed to load expense heads.';
    } finally {
      _loadingHeads = false;
      notifyListeners();
    }
  }

  Future<void> fetchVouchers() async {
    _loadingVouchers = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/expense-vouchers');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _vouchers = raw.map((e) => ExpenseVoucherModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load expense vouchers.';
      }
    } catch (_) {
      _error = 'Failed to load expense vouchers.';
    } finally {
      _loadingVouchers = false;
      notifyListeners();
    }
  }

  Future<bool> saveVoucher(ExpenseVoucherModel voucher, {int? editId}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = editId != null
          ? await _api.put('/expense-vouchers/$editId', voucher.toJson())
          : await _api.post('/expense-vouchers', voucher.toJson());

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchVouchers();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Unable to save voucher.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to save voucher.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVoucher(int id) async {
    try {
      final response = await _api.delete('/expense-vouchers/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _vouchers.removeWhere((v) => v.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
