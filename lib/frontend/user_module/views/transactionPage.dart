import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/transaction_controllers/transaction_controller.dart';
import '../models/transaction_model.dart';
import '../services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddTransactionPage extends StatefulWidget {
  final String currentUserId;
  final TransactionController controller;
  final bool initialIsExpense;

  const AddTransactionPage({
    super.key,
    required this.currentUserId,
    required this.controller,
    this.initialIsExpense = true,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final RxBool _isExpense = true.obs;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String _responseText = '';
  bool _isUploading = false;
  bool _hasProcessedReceipt = false; // Track if receipt was processed
  
  // Recurring transaction fields
  final RxBool _isRecurring = false.obs;
  final TextEditingController _recurringDurationController = TextEditingController();
  
  // Use doubles for duration and add 1 minute option (as minutes rather than fraction of days)
  final List<int> _durationOptions = [1, 7, 14, 30, 90, 180, 365]; // Days, with 1 = 1 minute for testing
  int _selectedDuration = 30; // Default is monthly

  // Categories and icons (your existing lists)
  final List<String> _categoriesIncome = [
    'allowance', 'award', 'bonus', 'dividend', 'investment',
    'lottery', 'salary', 'tips', 'others'
  ];

  final List<String> _categoriesExpense = [
    'bills', 'clothing', 'education', 'entertainment', 'fitness', 'food',
    'gifts', 'healthcare', 'home & furniture', 'pets', 'shopping',
    'transportation & fuel', 'travel', 'other'
  ];

  final List<IconData> _categoryIconsIncome = [
    Icons.wallet_giftcard, Icons.emoji_events, Icons.card_giftcard,
    Icons.stacked_line_chart, Icons.trending_up, Icons.casino,
    Icons.account_balance_wallet, Icons.attach_money, Icons.more_horiz,
  ];

  final List<IconData> _categoryIconsExpense = [
    Icons.receipt_long, Icons.checkroom, Icons.school, Icons.movie,
    Icons.fitness_center, Icons.fastfood, Icons.card_giftcard,
    Icons.local_hospital, Icons.chair_alt, Icons.pets,
    Icons.shopping_bag, Icons.directions_car, Icons.flight, Icons.more_horiz,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isExpense.value = widget.initialIsExpense;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _recurringDurationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _responseText = '';
          _hasProcessedReceipt = false;
        });
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
      _responseText = 'Processing receipt...';
    });

    final uri = Uri.parse('https://test-api-udkm.onrender.com/extract-receipt');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isUploading = false;
        if (response.statusCode == 200) {
          _responseText = _prettyJson(response.body);
          _parseReceiptDataAndAddTransactions(response.body);
        } else {
          _responseText = 'Upload failed (status ${response.statusCode}): ${response.body}';
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _responseText = 'Error: $e';
      });
    }
  }

  String _prettyJson(String rawJson) {
    try {
      final jsonObj = json.decode(rawJson);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObj);
    } catch (_) {
      return rawJson;
    }
  }

  // New method to parse receipt data and automatically add transactions
  Future<void> _parseReceiptDataAndAddTransactions(String responseBody) async {
    try {
      final jsonData = json.decode(responseBody);

      if (jsonData == null || jsonData is! Map) {
        Get.snackbar('Error', 'Invalid receipt data format');
        return;
      }

      // Check if categorizedItems exists and is not empty
      if (jsonData['categorizedItems'] != null &&
          jsonData['categorizedItems'] is List &&
          jsonData['categorizedItems'].isNotEmpty) {

        final String date = jsonData['date'] ?? DateTime.now().toIso8601String().substring(0, 10);
        final String merchantName = jsonData['merchantName'] ?? 'Receipt Purchase';

        List<TransactionModel> transactionsToAdd = [];

        // Process each category
        for (var categoryGroup in jsonData['categorizedItems']) {
          if (categoryGroup is Map) {
            String category = _mapCategoryToAppCategory(categoryGroup['category'] ?? 'other');
            double subtotal = (categoryGroup['subtotal'] ?? 0.0).toDouble();

            // Build description from items
            String itemsDescription = '';
            if (categoryGroup['items'] != null && categoryGroup['items'] is List) {
              List<String> itemNames = [];
              for (var item in categoryGroup['items']) {
                if (item is Map && item['name'] != null) {
                  itemNames.add("${item['name']} (₹${item['price']})");
                }
              }
              itemsDescription = itemNames.join(', ');
            }

            if (itemsDescription.isEmpty) {
              itemsDescription = '$merchantName - ${category.toLowerCase()} items';
            }

            // Create transaction model
            final transaction = TransactionModel(
              userId: widget.currentUserId,
              amount: subtotal,
              description: itemsDescription,
              category: category,
              isExpense: true, // Receipts are always expenses
              transactionDate: DateTime.tryParse(date) ?? DateTime.now(),
            );

            transactionsToAdd.add(transaction);
          }
        }

        // Add all transactions to database
        if (transactionsToAdd.isNotEmpty) {
          await _addMultipleTransactions(transactionsToAdd);
          setState(() {
            _hasProcessedReceipt = true;
          });

          Get.snackbar(
            'Success',
            'Receipt processed! ${transactionsToAdd.length} transactions added automatically.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          // Navigate back to home page after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context);
          });
        }
      } else {
        // Handle old format or single transaction
        _handleSingleTransactionFormat(jsonData);
      }
    } catch (e) {
      print('Error parsing receipt data: $e');
      Get.snackbar('Error', 'Failed to process receipt data: $e');
    }
  }

  // Method to add multiple transactions
  Future<void> _addMultipleTransactions(List<TransactionModel> transactions) async {
    try {
      for (var transaction in transactions) {
        await widget.controller.addTransaction(transaction);
        // Small delay between transactions to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add some transactions: $e');
    }
  }

  // Handle old single transaction format for backward compatibility
  void _handleSingleTransactionFormat(Map<dynamic, dynamic> jsonData) {
    if (jsonData['amount'] != null) {
      _amountController.text = jsonData['amount'].toString();
    }
    if (jsonData['description'] != null) {
      _descriptionController.text = jsonData['description'];
    }
    if (jsonData['category'] != null) {
      String category = jsonData['category'];
      String matchedCategory = _mapCategoryToAppCategory(category);
      _categoryController.text = matchedCategory;
    }
    _isExpense.value = true;

    Get.snackbar(
      'Info',
      'Receipt data loaded. Please review and save manually.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // Map server categories to app categories
  String _mapCategoryToAppCategory(String serverCategory) {
    final Map<String, String> categoryMapping = {
      'food': 'food',
      'grocery': 'food',
      'groceries': 'food',
      'household': 'shopping',
      'personal care': 'shopping',
      'health': 'healthcare',
      'medical': 'healthcare',
      'transport': 'transportation & fuel',
      'transportation': 'transportation & fuel',
      'entertainment': 'entertainment',
      'clothing': 'clothing',
      'education': 'education',
      'fitness': 'fitness',
      'utilities': 'bills',
      'bills': 'bills',
      'home': 'home & furniture',
      'furniture': 'home & furniture',
      'pets': 'pets',
      'gifts': 'gifts',
      'travel': 'travel',
    };

    String lowerCategory = serverCategory.toLowerCase();
    return categoryMapping[lowerCategory] ?? 'other';
  }

  // Rest of your existing methods (onTransactionTypeChanged, showImageSourceOptions, etc.)
  void _onTransactionTypeChanged(bool isExpense) {
    String currentCategory = _categoryController.text;
    _isExpense.value = isExpense;
    List<String> newCategories = isExpense ? _categoriesExpense : _categoriesIncome;
    if (!newCategories.contains(currentCategory)) {
      _categoryController.text = '';
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    'Camera',
                    Icons.camera_alt,
                        () => _pickImage(ImageSource.camera),
                  ),
                  _buildImageSourceOption(
                    'Gallery',
                    Icons.photo_library,
                        () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = TransactionModel(
        userId: widget.currentUserId,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        category: _categoryController.text,
        isExpense: _isExpense.value,
        transactionDate: DateTime.now(),
        isRecurring: _isRecurring.value,
        recurringDuration: _isRecurring.value ? _selectedDuration : null,
      );

      widget.controller.addTransaction(transaction);
      
      
      Navigator.pop(context);

      Get.snackbar(
        'Success',
        'Transaction added successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionForm(),
                      _buildImageTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Add Transaction',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (!_hasProcessedReceipt) // Only show save button if receipt wasn't auto-processed
          TextButton(
            onPressed: _submitTransaction,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Transaction'),
          Tab(text: 'Receipt'),
        ],
      ),
    );
  }

  Widget _buildTransactionForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ]
              : [
            const Color(0xFFF8FAFC),
            const Color(0xFFE2E8F0),
            const Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type Toggle
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => GestureDetector(
                        onTap: () => _onTransactionTypeChanged(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _isExpense.value
                                ? Colors.red.withOpacity(0.1)
                                : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isExpense.value
                                  ? Colors.red
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle,
                                color: _isExpense.value
                                    ? Colors.red
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Expense',
                                  style: TextStyle(
                                    color: _isExpense.value
                                        ? Colors.red
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => GestureDetector(
                        onTap: () => _onTransactionTypeChanged(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: !_isExpense.value
                                ? Colors.green.withOpacity(0.1)
                                : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_isExpense.value
                                  ? Colors.green
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: !_isExpense.value
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Income',
                                  style: TextStyle(
                                    color: !_isExpense.value
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),

              // Amount Field
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Recurring Transaction Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Do you want to repeat this transaction?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Obx(() => Switch(
                          value: _isRecurring.value,
                          onChanged: (value) => _isRecurring.value = value,
                          activeColor: Theme.of(context).colorScheme.primary,
                        )),
                      ],
                    ),
                    
                    Obx(() => _isRecurring.value 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Repeat every',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedDuration,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                  items: _durationOptions.map((days) {
                                    String label;
                                    if (days == 1) label = '1 minute (testing)';
                                    else if (days == 7) label = '7 days (1 week)';
                                    else if (days == 14) label = '14 days (2 weeks)';
                                    else if (days == 30) label = '30 days (monthly)';
                                    else if (days == 90) label = '90 days (quarterly)';
                                    else if (days == 180) label = '180 days (half-yearly)';
                                    else if (days == 365) label = '365 days (yearly)';
                                    else label = '$days days';
                                    
                                    return DropdownMenuItem<int>(
                                      value: days,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedDuration = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Date and Category Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Field
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Field
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => DropdownButtonFormField<String>(
                      key: ValueKey('category_${_isExpense.value}'), // Add this key
                      value: _categoryController.text.isEmpty
                          ? null
                          : (_isExpense.value ? _categoriesExpense : _categoriesIncome)
                          .contains(_categoryController.text)
                          ? _categoryController.text
                          : null, // Only set value if it exists in current list
                      decoration: InputDecoration(
                        hintText: 'Select category',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      items: (_isExpense.value ? _categoriesExpense : _categoriesIncome)
                          .asMap()
                          .entries
                          .map((entry) {
                        int index = entry.key;
                        String category = entry.value;
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                (_isExpense.value
                                    ? _categoryIconsExpense[index]
                                    : _categoryIconsIncome[index]),
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _categoryController.text = value ?? '';
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    )),

                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description Field
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              const Color(0xFF1A1A1A),
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
            ]
                : [
              const Color(0xFFF8FAFC),
              const Color(0xFFE2E8F0),
              const Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt Scanner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo or upload an image of your receipt to automatically extract transaction details',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // Image Preview or Placeholder
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 60,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No receipt image selected',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a receipt to auto-fill transaction details',
                      style: TextStyle(
                        color:
                        isDark ? Colors.white38 : Colors.grey.shade400,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add Image Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _showImageSourceOptions,
                  icon: _isUploading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.add_a_photo),
                  label: Text(_isUploading
                      ? 'Processing...'
                      : (_selectedImage != null
                      ? 'Change Receipt'
                      : 'Scan Receipt')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _responseText = '';
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // Response Display
              if (_responseText.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Extraction Result:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _responseText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
