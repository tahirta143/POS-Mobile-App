import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../models/item.dart';
import '../../models/lookup_data.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/access_denied_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class ItemListScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const ItemListScreen({super.key, this.onMenuPressed});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final _searchController = TextEditingController();
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    await _refreshData();
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<ItemProvider>(context, listen: false);
    await Future.wait([
      provider.fetchItems(),
      provider.fetchLookups(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(
      BuildContext context,
      ItemProvider provider,
      int id,
      String itemName,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Delete "$itemName"? This cannot be undone.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // close form dialog too
              final success = await provider.deleteItem(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Item deleted.' : 'Failed to delete item.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openItemFormDialog(BuildContext context, ItemModel? editItem, {bool canDelete = false}) {
    final provider = Provider.of<ItemProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: _ItemFormDialog(
            editItem: editItem,
            canDelete: canDelete,
            onDeletePressed: editItem?.id != null
                ? () => _confirmDelete(context, provider, editItem!.id!, editItem.itemName)
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<ItemProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const moduleName = 'Items';
    final canReadItem = auth.isAdmin || auth.can(moduleName, 'read');
    final canCreateItem = auth.isAdmin || auth.can(moduleName, 'create');
    final canUpdateItem = auth.isAdmin || auth.can(moduleName, 'update');
    final canDeleteItem = auth.isAdmin || auth.can(moduleName, 'delete');

    if (!canReadItem) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Item Management'),
        body: const AccessDeniedWidget(module: 'Items', action: 'READ'),
      );
    }

    final searchQuery = _searchController.text.toLowerCase();
    final filteredItems = provider.items.where((item) {
      final name = item.itemName.toLowerCase();
      final barcode = (item.barCode ?? '').toLowerCase();
      return name.contains(searchQuery) || barcode.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Item Management',
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
        },
        color: AppConstants.primaryTeal,
        child: _isInitialLoading
            ? const CustomLoader()
            : Column(
        children: [
          // Search + Add row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by name or barcode...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (canCreateItem)
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _openItemFormDialog(context, null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),

          // Count label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Item Records',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredItems.length}',
                    style: const TextStyle(
                      color: AppConstants.primaryTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: filteredItems.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      alignment: Alignment.center,
                      child: const Text(
                        'No items found.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildItemCard(
                  context,
                  item,
                  canUpdateItem,
                  canDeleteItem,
                  isDark,
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildItemCard(
      BuildContext context,
      ItemModel item,
      bool canUpdate,
      bool canDelete,
      bool isDark,
      ) {
    final isLowStock = item.stock <= item.reorder;
    final stockColor = isLowStock ? Colors.red : (isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary);

    return GestureDetector(
      onTap: (canUpdate || canDelete)
          ? () => _openItemFormDialog(context, item, canDelete: canDelete)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppConstants.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image thumbnail
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? AppConstants.darkBg : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                ),
              ),
              alignment: Alignment.center,
              child: item.itemImage != null && item.itemImage!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  '${AppConstants.apiBaseUrl}/uploads/${item.itemImage}',
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_outlined, color: Colors.grey, size: 22),
                ),
              )
                  : const Icon(Icons.image_outlined, color: Colors.grey, size: 22),
            ),
            const SizedBox(width: 10),

            // Name + barcode + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.barCode ?? 'No barcode',
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _MiniChip(
                        label: item.categoryName ?? 'Uncategorized',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 5),
                      StatusChip(label: item.isEnable ? 'Active' : 'Inactive'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price + stock + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.salePrice.toStringAsFixed(0)} PKR',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryTeal,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Stock: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                      ),
                    ),
                    Text(
                      item.stock.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (canUpdate || canDelete)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini chip ────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _MiniChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkBorder : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
        ),
      ),
    );
  }
}

// ─── Form Dialog ──────────────────────────────────────────────────────────────

class _ItemFormDialog extends StatefulWidget {
  final ItemModel? editItem;
  final bool canDelete;
  final VoidCallback? onDeletePressed;

  const _ItemFormDialog({
    this.editItem,
    this.canDelete = false,
    this.onDeletePressed,
  });

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _itemNameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _perUnitController = TextEditingController();
  final _reorderController = TextEditingController();

  int? _selectedCategory;
  int? _selectedType;
  int? _selectedSubcategory;
  int? _selectedManufacturer;
  int? _selectedSupplier;
  int? _selectedLocation;
  int? _selectedUnit;

  bool _isEnable = true;
  File? _selectedImage;
  String? _existingImageName;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final item = widget.editItem;
    if (item != null) {
      _itemNameController.text = item.itemName;
      _barcodeController.text = item.barCode ?? '';
      _purchasePriceController.text = item.purchasePrice.toString();
      _salePriceController.text = item.salePrice.toString();
      _openingStockController.text = item.stock.toString();
      _descriptionController.text = item.description;
      _perUnitController.text = item.perUnit.toString();
      _reorderController.text = item.reorder.toString();

      _selectedCategory = item.itemCategoryId;
      _selectedType = item.itemTypeId;
      _selectedSubcategory = item.itemSubcategoryId;
      _selectedManufacturer = item.manufacturerId;
      _selectedSupplier = item.supplierId;
      _selectedLocation = item.shelveLocationId;
      _selectedUnit = item.itemUnitId;
      _isEnable = item.isEnable;
      _existingImageName = item.itemImage;
    } else {
      _perUnitController.text = '1';
      _openingStockController.text = '0';
      _purchasePriceController.text = '0';
      _salePriceController.text = '0';
      _reorderController.text = '0';
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _openingStockController.dispose();
    _descriptionController.dispose();
    _perUnitController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showError('Category is required.');
      return;
    }
    if (_selectedType == null) {
      _showError('Item Type is required.');
      return;
    }

    final provider = Provider.of<ItemProvider>(context, listen: false);

    final item = ItemModel(
      itemName: _itemNameController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
      salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
      stock: double.tryParse(_openingStockController.text) ?? 0.0,
      itemCategoryId: _selectedCategory!,
      itemTypeId: _selectedType,
      itemSubcategoryId: _selectedSubcategory,
      manufacturerId: _selectedManufacturer,
      supplierId: _selectedSupplier,
      shelveLocationId: _selectedLocation,
      itemUnitId: _selectedUnit,
      barCode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      description: _descriptionController.text.trim(),
      reorder: double.tryParse(_reorderController.text) ?? 0.0,
      perUnit: int.tryParse(_perUnitController.text) ?? 1,
      isEnable: _isEnable,
    );

    bool success;
    if (widget.editItem != null) {
      success = await provider.updateItem(widget.editItem!.id!, item, _selectedImage);
    } else {
      success = await provider.addItem(item, _selectedImage);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.editItem != null ? 'Item updated.' : 'Item added.'),
          backgroundColor: Colors.green,
        ));
      } else {
        _showError('Failed to save item.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editItem != null;

    final filteredSubcategories = _selectedCategory == null
        ? <SubcategoryModel>[]
        : provider.subcategories.where((sc) => sc.categoryId == _selectedCategory).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.darkCard : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit ? 'Update Item' : 'Add New Item',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
                      ),
                    ),
                  ),
                  // Delete button (only in edit mode)
                  if (isEdit && widget.canDelete && widget.onDeletePressed != null)
                    IconButton(
                      onPressed: widget.onDeletePressed,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red,
                      tooltip: 'Delete item',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // ── Scrollable body ─────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Basic Info
                    _SectionLabel(title: 'Basic Information'),
                    const SizedBox(height: 10),

                    // Category + Type row
                    Row(
                      children: [
                        Expanded(
                          child: _CompactDropdown<int>(
                            label: 'Category *',
                            placeholder: 'Select',
                            value: _selectedCategory,
                            items: provider.categories.map((c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.categoryName, style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (v) => setState(() {
                              _selectedCategory = v;
                              _selectedSubcategory = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactDropdown<int>(
                            label: 'Item Type *',
                            placeholder: 'Select',
                            value: _selectedType,
                            items: provider.itemTypes.map((t) => DropdownMenuItem<int>(
                              value: t.id,
                              child: Text(t.typeName, style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedType = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _CompactDropdown<int>(
                      label: 'Sub-category',
                      placeholder: _selectedCategory == null ? 'Select category first' : 'Select',
                      value: _selectedSubcategory,
                      items: filteredSubcategories.map((s) => DropdownMenuItem<int>(
                        value: s.id,
                        child: Text(s.subCategoryName, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedSubcategory = v),
                    ),
                    const SizedBox(height: 10),

                    _CompactTextField(
                      label: 'Item Name *',
                      placeholder: 'Enter item name',
                      controller: _itemNameController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 18),

                    // SECTION 2: Pricing
                    _SectionLabel(title: 'Supplier & Pricing'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _CompactDropdown<int>(
                            label: 'Manufacturer',
                            placeholder: 'Select',
                            value: _selectedManufacturer,
                            items: provider.manufacturers.map((m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.manufacturerName, style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedManufacturer = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactDropdown<int>(
                            label: 'Supplier',
                            placeholder: 'Select',
                            value: _selectedSupplier,
                            items: provider.suppliers.map((s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(s.supplierName, style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedSupplier = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _CompactTextField(
                      label: 'Barcode',
                      placeholder: 'Scan or enter barcode',
                      controller: _barcodeController,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _CompactTextField(
                            label: 'Purchase Price',
                            placeholder: '0.00',
                            controller: _purchasePriceController,
                            keyboardType: TextInputType.number,
                            suffix: 'PKR',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactTextField(
                            label: 'Sale Price',
                            placeholder: '0.00',
                            controller: _salePriceController,
                            keyboardType: TextInputType.number,
                            suffix: 'PKR',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _CompactTextField(
                      label: 'Opening Stock',
                      placeholder: '0',
                      controller: _openingStockController,
                      keyboardType: TextInputType.number,
                      suffix: 'units',
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: Details
                    _SectionLabel(title: 'Details'),
                    const SizedBox(height: 10),

                    _CompactTextField(
                      label: 'Description',
                      placeholder: 'Optional description...',
                      controller: _descriptionController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _CompactDropdown<int>(
                            label: 'Location',
                            placeholder: 'Select',
                            value: _selectedLocation,
                            items: provider.locations.map((loc) => DropdownMenuItem<int>(
                              value: loc.id,
                              child: Text('${loc.shelfNameCode} (${loc.description})', style: const TextStyle(fontSize: 11)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedLocation = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactDropdown<int>(
                            label: 'Unit',
                            placeholder: 'Select',
                            value: _selectedUnit,
                            items: provider.units.map((u) => DropdownMenuItem<int>(
                              value: u.id,
                              child: Text(u.unitName, style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedUnit = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _CompactTextField(
                            label: 'Per Unit',
                            placeholder: '1',
                            controller: _perUnitController,
                            keyboardType: TextInputType.number,
                            suffix: '/pack',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CompactTextField(
                            label: 'Reorder Level',
                            placeholder: '0',
                            controller: _reorderController,
                            keyboardType: TextInputType.number,
                            suffix: 'units',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SECTION 4: Image & Status
                    _SectionLabel(title: 'Image & Status'),
                    const SizedBox(height: 10),

                    // Image picker — compact tile
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppConstants.darkCard : Colors.grey[50],
                          border: Border.all(
                            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.cloud_upload_outlined, color: AppConstants.primaryTeal, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Upload image',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.primaryTeal,
                                    ),
                                  ),
                                  Text(
                                    _selectedImage != null
                                        ? _selectedImage!.path.split('/').last
                                        : _existingImageName ?? 'PNG, JPG up to 10 MB',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(_selectedImage!, width: 36, height: 36, fit: BoxFit.cover),
                              )
                            else if (_existingImageName != null && _existingImageName!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  '${AppConstants.apiBaseUrl}/uploads/$_existingImageName',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status toggle — compact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppConstants.darkCard : Colors.grey[50],
                        border: Border.all(
                          color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isEnable ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                            color: _isEnable ? AppConstants.primaryTeal : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isEnable ? 'Item is Active' : 'Item is Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isEnable
                                    ? AppConstants.primaryTeal
                                    : (isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: _isEnable,
                              activeColor: AppConstants.primaryTeal,
                              onChanged: (v) => setState(() => _isEnable = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Action Buttons ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: provider.submitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryTeal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppConstants.primaryTeal.withOpacity(0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: provider.submitting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                            : Text(
                          isEdit ? 'Update Item' : 'Save Item',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(
                            color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable compact field wrappers ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppConstants.primaryTeal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryTeal,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _CompactTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? suffix;
  final int maxLines;
  final String? Function(String?)? validator;

  const _CompactTextField({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12),
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(
                color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(
                color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppConstants.primaryTeal),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  final String label;
  final String placeholder;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _CompactDropdown({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: const TextStyle(fontSize: 12),
          hint: Text(placeholder, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(
                color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: BorderSide(
                color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: AppConstants.primaryTeal),
            ),
          ),
        ),
      ],
    );
  }
}