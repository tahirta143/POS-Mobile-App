import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_head_provider.dart';
import '../../models/expense_head_model.dart';
import '../../utils/constants.dart';
import '../../widgets/access_denied_widget.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loader.dart';

class ExpenseHeadScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const ExpenseHeadScreen({super.key, this.onMenuPressed});

  @override
  State<ExpenseHeadScreen> createState() => _ExpenseHeadScreenState();
}

class _ExpenseHeadScreenState extends State<ExpenseHeadScreen> {
  final _searchController = TextEditingController();
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin || auth.canAccess('Expense Head')) {
      if (mounted) {
        setState(() {
          _isInitialLoading = true;
        });
      }
      await context.read<ExpenseHeadProvider>().fetchHeads();
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFormDialog(BuildContext context, ExpenseHeadModel? head, {bool canDelete = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: _ExpenseHeadFormDialog(
            editHead: head,
            canDelete: canDelete,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<ExpenseHeadProvider>(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppConstants.darkCard : Colors.white;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textSecondaryColor = isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;

    const moduleName = 'Expense Head';
    final canReadHead = auth.isAdmin || auth.can(moduleName, 'read');
    final canCreateHead = auth.isAdmin || auth.can(moduleName, 'create');
    final canUpdateHead = auth.isAdmin || auth.can(moduleName, 'update');
    final canDeleteHead = auth.isAdmin || auth.can(moduleName, 'delete');

    if (!canReadHead) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Expense Heads',
          leading: widget.onMenuPressed != null
              ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
              : null,
        ),
        body: const AccessDeniedWidget(module: moduleName, action: 'READ'),
      );
    }

    final searchQuery = _searchController.text.toLowerCase();
    final filteredHeads = provider.heads.where((h) {
      final name = h.head.toLowerCase();
      final desc = (h.description ?? '').toLowerCase();
      return name.contains(searchQuery) || desc.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Expense Heads',
        leading: widget.onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuPressed)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.fetchHeads(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Add Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                        hintText: 'Search by head name...',
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
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  ),
                ),
                if (canCreateHead) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _openFormDialog(context, null),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Add Head', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Count Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  'Expense Head Categories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredHeads.length}',
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

          // Heads List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.fetchHeads();
              },
              color: AppConstants.primaryTeal,
              child: _isInitialLoading
                  ? const CustomLoader()
                  : filteredHeads.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category_outlined, size: 64, color: textSecondaryColor),
                                const SizedBox(height: 12),
                                Text('No expense heads defined.', style: TextStyle(color: textSecondaryColor)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 90),
                          itemCount: filteredHeads.length,
                          itemBuilder: (context, index) {
                            final eh = filteredHeads[index];
                            final id = eh.id;
                            final name = eh.head;
                            final desc = eh.description ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium)),
                                onTap: (canUpdateHead || canDeleteHead)
                                    ? () => _openFormDialog(context, eh, canDelete: canDeleteHead)
                                    : null,
                                title: Row(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#$id',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: desc.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          desc,
                                          style: TextStyle(fontSize: 11, color: textSecondaryColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : null,
                                trailing: (canUpdateHead || canDeleteHead)
                                    ? Icon(Icons.chevron_right_rounded, size: 20, color: textSecondaryColor)
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseHeadFormDialog extends StatefulWidget {
  final ExpenseHeadModel? editHead;
  final bool canDelete;
  const _ExpenseHeadFormDialog({this.editHead, required this.canDelete});

  @override
  State<_ExpenseHeadFormDialog> createState() => _ExpenseHeadFormDialogState();
}

class _ExpenseHeadFormDialogState extends State<_ExpenseHeadFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _headCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final eh = widget.editHead;
    if (eh != null) {
      _headCtrl.text = eh.head;
      _descCtrl.text = eh.description ?? '';
    }
  }

  @override
  void dispose() {
    _headCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _headCtrl.text.trim();
    if (name.isEmpty) return;

    final headModel = ExpenseHeadModel(
      id: widget.editHead?.id,
      head: name,
      description: _descCtrl.text.trim(),
    );

    final provider = context.read<ExpenseHeadProvider>();
    final success = await provider.saveHead(headModel, editId: widget.editHead?.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editHead != null
                ? 'Expense Head updated successfully.'
                : 'Expense Head defined successfully.'),
            backgroundColor: AppConstants.primaryTeal,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Unable to save expense head.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Expense Head', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to delete this expense head?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final provider = context.read<ExpenseHeadProvider>();
      final success = await provider.deleteHead(widget.editHead!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Expense Head deleted successfully.' : 'Failed to delete expense head.'),
            backgroundColor: success ? AppConstants.primaryTeal : Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  InputDecoration _inputDecoration(bool isDark, Color borderColor, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: isDark ? AppConstants.darkCard : Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppConstants.primaryTeal, width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseHeadProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppConstants.darkBorder : AppConstants.lightBorder;
    final textPrimaryColor = isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary;
    final isEdit = widget.editHead != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.category_outlined, color: AppConstants.primaryTeal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Expense Head' : 'Add Expense Head',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimaryColor),
                    ),
                  ),
                  if (isEdit && widget.canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _confirmDelete,
                      tooltip: 'Delete Expense Head',
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Head Name Field
              Text('Head Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _headCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(isDark, borderColor, hint: 'e.g. Office Rent, Utility Bills, Salaries'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter head name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Field
              Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimaryColor)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(isDark, borderColor, hint: 'Details about this expense category'),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: provider.submitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      provider.submitting ? 'Saving...' : 'Save',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
