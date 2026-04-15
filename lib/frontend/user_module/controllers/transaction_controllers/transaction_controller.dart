import 'package:get/get.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class TransactionController extends GetxController{
  final TransactionService _service = TransactionService();

  var transactions = <TransactionModel>[].obs;
  var filteredTransactions = <TransactionModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Filter state variables
  var selectedDateFilter = ''.obs;
  var selectedTypeFilter = ''.obs;

  // Filter options
  final List<Map<String, String>> dateFilterOptions = [
    {'value': 'this_month', 'label': 'This Month'},
    {'value': 'two_months', 'label': 'Last 2 Months'},
    {'value': 'six_months', 'label': 'Last 6 Months'},
    {'value': 'all', 'label': 'All Time'},
  ];

  final List<Map<String, String>> typeFilterOptions = [
    {'value': 'all', 'label': 'All Transactions'},
    {'value': 'expense', 'label': 'Expenses Only'},
    {'value': 'income', 'label': 'Income Only'},
  ];

  @override
  void onInit() async{
    super.onInit();
    // Don't fetch transactions here, let the HomePage handle it with the correct userId
    // No need to call fetchTransactions with a hardcoded ID
  }

  // Get transactions to display (filtered or all)
  List<TransactionModel> get displayTransactions {
    return filteredTransactions.isNotEmpty ? filteredTransactions : transactions;
  }

  // Check if any filters are active
  bool get hasActiveFilters {
    return (selectedDateFilter.value.isNotEmpty && selectedDateFilter.value != 'all') ||
           (selectedTypeFilter.value.isNotEmpty && selectedTypeFilter.value != 'all');
  }

  // Get active filters count
  int get activeFiltersCount {
    int count = 0;
    if (selectedDateFilter.value.isNotEmpty && selectedDateFilter.value != 'all') count++;
    if (selectedTypeFilter.value.isNotEmpty && selectedTypeFilter.value != 'all') count++;
    return count;
  }

  // Apply filters to transactions
  void applyFilters() {
    List<TransactionModel> filtered = List.from(transactions);
    
    // Apply date filter
    if (selectedDateFilter.value.isNotEmpty && selectedDateFilter.value != 'all') {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (selectedDateFilter.value) {
        case 'this_month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'two_months':
          startDate = DateTime(now.year, now.month - 2, 1);
          break;
        case 'six_months':
          startDate = DateTime(now.year, now.month - 6, 1);
          break;
        default:
          startDate = DateTime(1900, 1, 1); // Very old date to show all
      }
      
      filtered = filtered.where((tx) => 
        tx.transactionDate.isAfter(startDate.subtract(const Duration(days: 1)))
      ).toList();
    }
    
    // Apply type filter
    if (selectedTypeFilter.value.isNotEmpty && selectedTypeFilter.value != 'all') {
      filtered = filtered.where((tx) {
        if (selectedTypeFilter.value == 'expense') {
          return tx.isExpense;
        } else if (selectedTypeFilter.value == 'income') {
          return !tx.isExpense;
        }
        return true;
      }).toList();
    }
    
    filteredTransactions.assignAll(filtered);
  }

  // Clear all filters
  void clearFilters() {
    selectedDateFilter.value = '';
    selectedTypeFilter.value = '';
    filteredTransactions.clear();
  }

  // Get filter description for UI
  String getFilterDescription() {
    List<String> descriptions = [];
    
    if (selectedDateFilter.value.isNotEmpty && selectedDateFilter.value != 'all') {
      final option = dateFilterOptions.firstWhere(
        (opt) => opt['value'] == selectedDateFilter.value,
        orElse: () => {'label': 'Unknown'},
      );
      descriptions.add(option['label']!);
    }
    
    if (selectedTypeFilter.value.isNotEmpty && selectedTypeFilter.value != 'all') {
      final option = typeFilterOptions.firstWhere(
        (opt) => opt['value'] == selectedTypeFilter.value,
        orElse: () => {'label': 'Unknown'},
      );
      descriptions.add(option['label']!);
    }
    
    return descriptions.join(' • ');
  }

  Future<void> fetchTransactions(String userId) async{
    try{
      if (userId.isEmpty) {
        print('Error: Cannot fetch transactions with an empty userId');
        errorMessage.value = 'Invalid user ID';
        return;
      }
      
      isLoading.value = true;
      errorMessage.value = '';
      print('Starting to fetch transactions for user: $userId');
      
      final fetched = await _service.fetchTransactionsByUser(userId);
      print('Transactions fetched for userId $userId: ${fetched.length} transactions');
      
      transactions.assignAll(fetched);
      
      // Clear any filters when loading new user data
      clearFilters();
      
      print('Transactions assigned to observable: ${transactions.length}');
    } catch (e) {
      print('Error in fetchTransactions for userId $userId: $e');
      errorMessage.value = 'Failed to load transactions: ${e.toString()}';
    } finally {
      isLoading.value = false;
      print('Fetch transactions completed for userId $userId. Loading: ${isLoading.value}');
    }
  }

  Future<void> addTransaction(TransactionModel txn) async{
    try{
      print('TransactionController: Starting to add transaction: $txn');
      isLoading.value = true;
      errorMessage.value = '';
      
      final success = await _service.addTransaction(txn);
      print('TransactionController: Add transaction result: $success');
      
      if(success){
        print('TransactionController: Adding transaction to local list');
        transactions.add(txn);
        await fetchTransactions(txn.userId);
        print('TransactionController: Transaction added successfully. Total transactions: ${transactions.length}');
      }else{
        print('TransactionController: Failed to add transaction');
        errorMessage.value = 'Failed to add transaction';
      }
    }catch(e){
      print('TransactionController: Error in addTransaction: $e');
      errorMessage.value = e.toString();
    }finally{
      isLoading.value = false;
      print('TransactionController: Add transaction completed. Loading: ${isLoading.value}');
    }
  }

  Future<void> deleteTransaction(String transactionId) async{
    try{
      print('TransactionController: Starting to delete transaction: $transactionId');
      isLoading.value = true;
      errorMessage.value = '';
      
      final success = await _service.deleteTransaction(transactionId);
      print('TransactionController: Delete transaction result: $success');
      
      if(success){
        print('TransactionController: Removing transaction from local list');
        transactions.removeWhere((t) => t.transactionId == transactionId);
        print('TransactionController: Transaction deleted successfully. Remaining transactions: ${transactions.length}');
      }else{
        print('TransactionController: Failed to delete transaction');
        errorMessage.value = 'Failed to delete transaction';
      }
    }catch(e){
      print('TransactionController: Error in deleteTransaction: $e');
      errorMessage.value = e.toString();
    }finally{
      isLoading.value = false;
      print('TransactionController: Delete transaction completed. Loading: ${isLoading.value}');
    }
  }
}
