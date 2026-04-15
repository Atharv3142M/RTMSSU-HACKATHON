import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ml_based_personal_finance_optimizer/frontend/user_module/controllers/transaction_controllers/transaction_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/goal_model.dart';
import '../services/goal_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

class GoalController extends GetxController {
  final GoalService _goalService = GoalService();
  final TransactionService _transactionService = TransactionService();
  final formKey = GlobalKey<FormState>();
  
  // Form controllers
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final descriptionController = TextEditingController();
  final depositAmountController = TextEditingController();
  final withdrawAmountController = TextEditingController();
  
  // Selected dates
  Rx<DateTime> selectedStartDate = DateTime.now().obs;
  Rx<DateTime> selectedEndDate = DateTime.now().add(const Duration(days: 30)).obs;
  
  // Observable variables
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var goals = <Goal>[].obs;
  var errorMessage = ''.obs;
  var userId = ''.obs;
  var availableBalance = 0.0.obs;
  var transactions = <TransactionModel>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadUserId();
  }
  
  @override
  void onClose() {
    titleController.dispose();
    amountController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    descriptionController.dispose();
    depositAmountController.dispose();
    withdrawAmountController.dispose();
    super.onClose();
  }
  
  // Load user ID from shared preferences
  Future<void> loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      
      if (storedUserId != null && storedUserId.isNotEmpty) {
        userId.value = storedUserId;
        fetchGoals();
        fetchTransactions(); // Fetch transactions to calculate available balance
      } else {
        // Fallback to default user ID if needed
        userId.value = '687a5088ef80ce4d11f829aa'; // Replace with your default user ID
        fetchGoals();
        fetchTransactions();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load user data: $e';
    }
  }
  
  // Fetch transactions to calculate available balance
  Future<void> fetchTransactions() async {
    if (userId.value.isEmpty) {
      errorMessage.value = 'User ID is not available';
      return;
    }
    
    try {
      transactions.value = await _transactionService.fetchTransactionsByUser(userId.value);
      calculateAvailableBalance();
    } catch (e) {
      errorMessage.value = 'Failed to load transactions: $e';
    }
  }
  
  // Calculate available balance (total income - total expenses)
  void calculateAvailableBalance() {
    final totalIncome = transactions
        .where((tx) => !tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    
    final totalExpenses = transactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    
    availableBalance.value = totalIncome - totalExpenses;
  }
  
  // Fetch all goals for the current user
  Future<void> fetchGoals() async {
    if (userId.value.isEmpty) {
      errorMessage.value = 'User ID is not available';
      return;
    }
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final fetchedGoals = await _goalService.getGoals(userId.value);
      goals.value = fetchedGoals;
    } catch (e) {
      errorMessage.value = 'Failed to load goals: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Add a new goal
  Future<void> addGoal() async {

    final transactionController = Get.find<TransactionController>();

    if (!formKey.currentState!.validate()) return;
    
    try {
      isSubmitting.value = true;
      errorMessage.value = '';
      
      final targetAmount = double.parse(amountController.text.trim());
      
      // Validate that the goal amount is realistic
      if (targetAmount > availableBalance.value * 10) {
        Get.snackbar(
          'Unrealistic Goal',
          'Your goal amount seems too high compared to your financial capacity. Consider a more achievable target.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
      
      final newGoal = Goal(
        userId: userId.value,
        title: titleController.text.trim(),
        targetAmount: targetAmount,
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        description: descriptionController.text.trim(),
      );
      
      print("Attempting to add goal with userId: ${userId.value}");
      print("Goal data: ${newGoal.toJson()}");
      
      await _goalService.addGoal(newGoal);
      await transactionController.addTransaction(TransactionModel(userId: userId.value, amount: targetAmount, isExpense: true, transactionDate: DateTime.now(), category: 'Goal',description: descriptionController.text));
      clearForm();
      await fetchGoals(); // Refresh the goals list
      Get.back(); // Close the add goal dialog/screen
      
      // Ensure HomePage refreshes by calling fetchTransactions on the controller
      await transactionController.fetchTransactions(userId.value);

      Get.snackbar(
        'Success',
        'Goal added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error adding goal: $e");
      errorMessage.value = 'Failed to add goal: $e';
      Get.snackbar(
        'Error',
        'Failed to add goal: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
  
  // Delete a goal
  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalService.deleteGoal(goalId);
      fetchGoals(); // Refresh the goals list
      
      Get.snackbar(
        'Success',
        'Goal deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete goal: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Edit an existing goal
  Future<void> editGoal(Goal goal) async {
    if (!formKey.currentState!.validate()) return;
    
    try {
      isSubmitting.value = true;
      errorMessage.value = '';
      
      final updatedGoal = Goal(
        id: goal.id,
        userId: userId.value,
        title: titleController.text.trim(),
        targetAmount: double.parse(amountController.text.trim()),
        currentAmount: goal.currentAmount, // Maintain current amount
        startDate: selectedStartDate.value,
        endDate: selectedEndDate.value,
        description: descriptionController.text.trim(),
      );
      
      print("Attempting to update goal with ID: ${goal.id}");
      print("Goal data: ${updatedGoal.toJson()}");
      
      await _goalService.editGoal(updatedGoal);
      clearForm();
      Get.back(); // Close the edit goal dialog/screen
      fetchGoals(); // Refresh the goals list
      
      Get.snackbar(
        'Success',
        'Goal updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Error updating goal: $e");
      errorMessage.value = 'Failed to update goal: $e';
      Get.snackbar(
        'Error',
        'Failed to update goal: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
  
  // Load goal data into form for editing
  void loadGoalForEditing(Goal goal) {
    titleController.text = goal.title;
    amountController.text = goal.targetAmount.toString();
    descriptionController.text = goal.description ?? '';
    
    selectedStartDate.value = goal.startDate;
    startDateController.text = DateFormat('dd/MM/yyyy').format(goal.startDate);
    
    selectedEndDate.value = goal.endDate;
    endDateController.text = DateFormat('dd/MM/yyyy').format(goal.endDate);
  }
  
  // Validate deposit amount
  String? validateDepositAmount(String? value, {double? maxAllowed}) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    
    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than zero';
      }
      
      // Check if we have enough available balance
      if (amount > availableBalance.value) {
        return 'Insufficient funds. You only have ₹${availableBalance.value.toStringAsFixed(2)} available';
      }
      
      // If maxAllowed is provided, check against it
      if (maxAllowed != null && amount > maxAllowed) {
        return 'Cannot exceed ₹${maxAllowed.toStringAsFixed(2)}';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid number';
    }
  }
  
  // Validate withdrawal amount
  String? validateWithdrawalAmount(String? value, double currentAmount) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    
    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than zero';
      }
      
      if (amount > currentAmount) {
        return 'Cannot withdraw more than ₹${currentAmount.toStringAsFixed(2)}';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid number';
    }
  }
  
  // Deposit money to a goal
  Future<void> depositToGoal(String goalId, double amount) async {
    // Fetch latest available balance
    await fetchTransactions();
    
    // Validate deposit amount against available balance
    final validationError = validateDepositAmount(amount.toString());
    if (validationError != null) {
      Get.snackbar(
        'Validation Error',
        validationError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      // First create a transaction to record this as an expense
      final transaction = TransactionModel(
        userId: userId.value,
        amount: amount,
        category: 'Savings Goal',
        description: 'Deposit to goal',
        isExpense: true, // Mark as expense since money is being taken from available funds
        transactionDate: DateTime.now(),
      );
      
      // Add the transaction
      await _transactionService.addTransaction(transaction);
      
      // Then update the goal
      await _goalService.depositToGoal(goalId, amount);
      depositAmountController.clear();
      fetchGoals(); // Refresh the goals list
      fetchTransactions(); // Update available balance
      
      // Ensure HomePage refreshes by calling fetchTransactions on the TransactionController
      final transactionController = Get.find<TransactionController>();
      await transactionController.fetchTransactions(userId.value);
      
      Get.snackbar(
        'Success',
        'Deposit successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to make deposit: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Withdraw money from a goal
  Future<void> withdrawFromGoal(String goalId, double amount, double currentAmount) async {
    // Validate withdrawal amount against current goal amount
    final validationError = validateWithdrawalAmount(amount.toString(), currentAmount);
    if (validationError != null) {
      Get.snackbar(
        'Validation Error',
        validationError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      // First record this as income
      final transaction = TransactionModel(
        userId: userId.value,
        amount: amount,
        category: 'Savings Goal',
        description: 'Withdrawal from goal',
        isExpense: false, // Mark as income since money is being added to available funds
        transactionDate: DateTime.now(),
      );
      
      // Add the transaction
      await _transactionService.addTransaction(transaction);
      
      // Then update the goal
      await _goalService.withdrawFromGoal(goalId, amount);
      withdrawAmountController.clear();
      fetchGoals(); // Refresh the goals list
      fetchTransactions(); // Update available balance
      
      // Ensure HomePage refreshes by calling fetchTransactions on the TransactionController
      final transactionController = Get.find<TransactionController>();
      await transactionController.fetchTransactions(userId.value);
      
      Get.snackbar(
        'Success',
        'Withdrawal successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to withdraw: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Select start date
  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != selectedStartDate.value) {
      selectedStartDate.value = picked;
      startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }
  
  // Select end date
  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEndDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != selectedEndDate.value) {
      selectedEndDate.value = picked;
      endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }
  
  // Clear form fields
  void clearForm() {
    titleController.clear();
    amountController.clear();
    descriptionController.clear();
    
    selectedStartDate.value = DateTime.now();
    startDateController.text = DateFormat('dd/MM/yyyy').format(selectedStartDate.value);
    
    selectedEndDate.value = DateTime.now().add(const Duration(days: 30));
    endDateController.text = DateFormat('dd/MM/yyyy').format(selectedEndDate.value);
  }
  
  // Initialize form fields
  void initializeForm() {
    startDateController.text = DateFormat('dd/MM/yyyy').format(selectedStartDate.value);
    endDateController.text = DateFormat('dd/MM/yyyy').format(selectedEndDate.value);
  }
} 