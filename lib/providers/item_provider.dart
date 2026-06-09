import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/lookup_data.dart';
import '../services/api_service.dart';

class ItemProvider with ChangeNotifier {
  late final SharedPreferences _prefs;
  late final ApiService _apiService;

  bool _loading = false;
  bool _submitting = false;
  List<ItemModel> _items = [];

  // Lookups
  List<CategoryModel> _categories = [];
  List<ItemTypeModel> _itemTypes = [];
  List<ManufacturerModel> _manufacturers = [];
  List<SupplierModel> _suppliers = [];
  List<LocationModel> _locations = [];
  List<UnitModel> _units = [];
  List<SubcategoryModel> _subcategories = [];

  ItemProvider(this._prefs) {
    _apiService = ApiService(_prefs);
  }

  bool get loading => _loading;
  bool get submitting => _submitting;
  List<ItemModel> get items => _items;

  // Filtered Lookup lists
  List<CategoryModel> get categories => _categories;
  List<ItemTypeModel> get itemTypes => _itemTypes;
  List<ManufacturerModel> get manufacturers => _manufacturers;
  List<SupplierModel> get suppliers => _suppliers;
  List<LocationModel> get locations => _locations;
  List<UnitModel> get units => _units;
  List<SubcategoryModel> get subcategories => _subcategories;

  // Helper to safely fetch raw list from API response
  Future<List> _safeFetchList(String endpoint) async {
    try {
      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        return data['data'] ?? [];
      }
    } catch (e) {
      // Fail silently
    }
    return [];
  }

  // Fetch lookups (fired on create/edit initialization)
  Future<void> fetchLookups() async {
    final results = await Future.wait([
      _safeFetchList('/categories'),
      _safeFetchList('/item-types'),
      _safeFetchList('/manufacturers'),
      _safeFetchList('/suppliers'),
      _safeFetchList('/shelve-locations'),
      _safeFetchList('/item-units'),
      _safeFetchList('/sub-categories/list'),
    ]);

    _categories = results[0].map((c) => CategoryModel.fromJson(c)).toList();
    _itemTypes = results[1].map((t) => ItemTypeModel.fromJson(t)).toList();
    _manufacturers = results[2].map((m) => ManufacturerModel.fromJson(m)).toList();
    _suppliers = results[3].map((s) => SupplierModel.fromJson(s)).toList();
    _locations = results[4].map((l) => LocationModel.fromJson(l)).toList();
    _units = results[5].map((u) => UnitModel.fromJson(u)).toList();
    _subcategories = results[6].map((s) => SubcategoryModel.fromJson(s)).toList();

    notifyListeners();
  }

  // Fetch all items from API
  Future<void> fetchItems() async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/item-details');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data is List ? data : (data['data'] ?? []);
        _items = list.map((item) => ItemModel.fromJson(item)).toList();
      }
    } catch (e) {
      // Handle error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Add Item (POST)
  Future<bool> addItem(ItemModel item, File? imageFile) async {
    _submitting = true;
    notifyListeners();

    try {
      final fields = item.toFormFields();
      final response = await _apiService.multipart(
        method: 'POST',
        endpoint: '/item-details',
        fields: fields,
        file: imageFile,
      );

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchItems();
        return true;
      }
      return false;
    } catch (e) {
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  // Update Item (PUT)
  Future<bool> updateItem(int id, ItemModel item, File? imageFile) async {
    _submitting = true;
    notifyListeners();

    try {
      final fields = item.toFormFields();
      final response = await _apiService.multipart(
        method: 'PUT',
        endpoint: '/item-details/$id',
        fields: fields,
        file: imageFile,
      );

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchItems();
        return true;
      }
      return false;
    } catch (e) {
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  // Delete Item (DELETE)
  Future<bool> deleteItem(int id) async {
    try {
      final response = await _apiService.delete('/item-details/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _items.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
