import 'package:flutter/material.dart';
import 'package:expense_tracker_app/database_helper.dart';
import 'package:expense_tracker_app/models/item_model.dart';
import 'dart:ui';

class AddEditScreen extends StatefulWidget {
  final Item? item;
  AddEditScreen({this.item});

  @override
  _AddEditScreenState createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String? _description;
  String _selectedCategory = 'Food';
  double _amount = 0.0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Others'
  ];

  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Others': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _title = widget.item!.title;
      _description = widget.item!.description;
      _amount = double.tryParse(widget.item!.description ?? '0') ?? 0.0;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Item newItem = Item(
        id: widget.item?.id,
        title: _title,
        description: _amount.toString(),
      );

      if (widget.item == null) {
        await _dbHelper.insertItem(newItem);
      } else {
        await _dbHelper.updateItem(newItem);
      }

      Navigator.pop(context);
    }
  }

  Widget _buildCategoryIcon(String category) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _categoryIcons[category] ?? Icons.more_horiz,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add Expense' : 'Edit Expense',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Text(
                  widget.item == null
                      ? 'New Expense Details'
                      : 'Update Expense',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please fill in the details below',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Form Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueGrey[800]!.withOpacity(0.9),
                        Colors.blueGrey[900]!.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Input
                              TextFormField(
                                initialValue: _title,
                                decoration:
                                    _inputDecoration('Title', Icons.title),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Title is required'
                                        : null,
                                onSaved: (value) => _title = value!,
                              ),
                              const SizedBox(height: 20),

                              // Category Dropdown
                              Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.blueGrey[800],
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  decoration: _inputDecoration(
                                    'Category',
                                    _categoryIcons[_selectedCategory]!,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  items: _categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Row(
                                        children: [
                                          _buildCategoryIcon(category),
                                          const SizedBox(width: 12),
                                          Text(category),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(
                                      () => _selectedCategory = value!),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Amount Input
                              TextFormField(
                                initialValue: _amount.toString(),
                                decoration: _inputDecoration(
                                  'Amount',
                                  Icons.attach_money,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Enter amount'
                                        : null,
                                onSaved: (value) =>
                                    _amount = double.tryParse(value!) ?? 0.0,
                              ),
                              const SizedBox(height: 32),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saveItem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor:
                                        Colors.blueAccent.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.item == null
                                            ? Icons.add_circle
                                            : Icons.save,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.item == null
                                            ? 'Add Expense'
                                            : 'Update Expense',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.blueGrey[800]!.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.blueAccent.withOpacity(0.5),
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.blueAccent.withOpacity(0.3),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.blueAccent,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
    );
  }
}
