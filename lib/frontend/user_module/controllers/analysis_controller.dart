import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/pdf_service.dart';
import '../services/stock_market_service.dart';

class AnalysisController extends GetxController {
  final TransactionService _service = TransactionService();
  final StockMarketService _stockMarketService = StockMarketService(); // Add stock market service
  
  var transactions = <TransactionModel>[].obs;
  var filteredTransactions = <TransactionModel>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isGeneratingPdf = false.obs;
  
  // New properties for stock market data
  final isLoadingMarketData = true.obs;
  final marketDataError = ''.obs;
  final marketIndices = <String, dynamic>{}.obs;
  final topGainers = <Map<String, dynamic>>[].obs;

  // Chart screenshot keys
  final GlobalKey expenseChartKey = GlobalKey();
  final GlobalKey incomeChartKey = GlobalKey();
  final GlobalKey monthlyTrendsChartKey = GlobalKey(); // Add key for monthly trends chart

  @override
  void onInit() {
    super.onInit();
    loadUserIdAndFetchTransactions();
    fetchMarketData(); // Add this to fetch market data on init
  }
  
  Future<void> loadUserIdAndFetchTransactions() async {
    try {
      // Get userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null && userId.isNotEmpty) {
        await fetchTransactions(userId);
      } else {
        // Fallback to default user ID if needed
        await fetchTransactions('687a5088ef80ce4d11f829aa');
      }
    } catch (e) {
      errorMessage.value = 'Failed to load user data: $e';
    }
  }
  
    Future<void> fetchTransactions(String userId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final fetchedTransactions = await _service.fetchTransactionsByUser(userId);
      transactions.value = fetchedTransactions;
      filteredTransactions.value = fetchedTransactions; // Use all transactions
      
    } catch (e) {
      errorMessage.value = 'Failed to load transactions: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get expense data for pie chart
  Map<String, double> getExpenseData() {
    final expenseTransactions = filteredTransactions
        .where((tx) => tx.isExpense)
        .toList();
    
    final Map<String, double> categoryTotals = {};
    
    for (var transaction in expenseTransactions) {
      final category = transaction.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
    }
    
    return categoryTotals;
  }
  
  // Get income data for pie chart
  Map<String, double> getIncomeData() {
    final incomeTransactions = filteredTransactions
        .where((tx) => !tx.isExpense)
        .toList();
    
    final Map<String, double> categoryTotals = {};
    
    for (var transaction in incomeTransactions) {
      final category = transaction.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
    }
    
    return categoryTotals;
  }
  
  // Get expense data for line chart (grouped by date)
  Map<DateTime, double> getExpenseLineData() {
    final expenseTransactions = filteredTransactions
        .where((tx) => tx.isExpense)
        .toList();
    
    final Map<DateTime, double> dateTotals = {};
    
    for (var transaction in expenseTransactions) {
      final date = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      dateTotals[date] = (dateTotals[date] ?? 0) + transaction.amount;
    }
    
    return dateTotals;
  }
  
  // Get income data for line chart (grouped by date)
  Map<DateTime, double> getIncomeLineData() {
    final incomeTransactions = filteredTransactions
        .where((tx) => !tx.isExpense)
        .toList();
    
    final Map<DateTime, double> dateTotals = {};
    
    for (var transaction in incomeTransactions) {
      final date = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      dateTotals[date] = (dateTotals[date] ?? 0) + transaction.amount;
    }
    
    return dateTotals;
  }
  
  // Get monthly trends data for both income and expenses
  List<MonthlyTrendsData> getMonthlyTrendsData() {
    if (filteredTransactions.isEmpty) {
      return [];
    }

    // Group transactions by year-month
    final Map<String, Map<String, double>> monthlyData = {};

    for (var transaction in filteredTransactions) {
      final year = transaction.transactionDate.year;
      final month = transaction.transactionDate.month;
      final String monthKey = '$year-${month.toString().padLeft(2, '0')}';

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
      }

      if (transaction.isExpense) {
        monthlyData[monthKey]!['expense'] = (monthlyData[monthKey]!['expense'] ?? 0) + transaction.amount;
      } else {
        monthlyData[monthKey]!['income'] = (monthlyData[monthKey]!['income'] ?? 0) + transaction.amount;
      }
    }

    // Sort months chronologically
    final sortedKeys = monthlyData.keys.toList()..sort();

    // Take only the last 6 months or all if less than 6
    final displayKeys = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    // Convert to list of MonthlyTrendsData
    return displayKeys.map((key) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      final monthName = DateFormat('MMM').format(DateTime(year, month));

      return MonthlyTrendsData(
        monthName,
        monthlyData[key]!['income']!,
        monthlyData[key]!['expense']!,
        DateTime(year, month),
      );
    }).toList();
  }

  // Get total expenses
  double get totalExpenses {
    return filteredTransactions
        .where((tx) => tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  // Get total income
  double get totalIncome {
    return filteredTransactions
        .where((tx) => !tx.isExpense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
  
  // Get net amount (income - expenses)
  double get netAmount {
    return totalIncome - totalExpenses;
  }
  
  // Take a screenshot of a widget using its GlobalKey
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary boundary = 
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = 
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget: $e');
      return null;
    }
  }
  
  // Generate PDF report, send to server, and open locally
  Future<void> generatePdfReport() async {
    try {
      isGeneratingPdf.value = true;
      Get.snackbar(
        'Generating Report',
        'Please wait while we prepare your financial report...',
        duration: const Duration(seconds: 2),
      );
      
      // Capture chart screenshots if keys are attached to widgets
      Uint8List? expenseChartImage;
      Uint8List? incomeChartImage;
      Uint8List? monthlyTrendsImage;

      try {
        expenseChartImage = await captureWidget(expenseChartKey);
        incomeChartImage = await captureWidget(incomeChartKey);
        monthlyTrendsImage = await captureWidget(monthlyTrendsChartKey);
      } catch (e) {
        print('Error capturing charts: $e');
        // Continue without chart images
      }
      
      // Get user name (or fallback to default)
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      String userName = 'User';
    
      
      if (userData != null) {
        try {
          // Try to parse user data for name
          final userDataMap = jsonDecode(userData) as Map<String, dynamic>;
          userName = userDataMap['username'] ?? 'User';
        } catch (e) {
          print('Error parsing user data: $e');
          // Continue with default name
        }
      }
      
      // Generate PDF report with financial data and chart images
      final pdfFile = await PdfService.generateFinancialReport(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netAmount: netAmount,
        expenseData: getExpenseData(),
        incomeData: getIncomeData(),
        userName: userName,
        expenseChartImage: expenseChartImage,
        incomeChartImage: incomeChartImage,
        monthlyTrendsChartImage: monthlyTrendsImage,
      );
      
      // Send PDF to server
      try {
        // Get user ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        
        final result = await PdfService.sendPdfToServer(
          pdfFile,
          userId: userId,
          totalIncome: totalIncome,
          totalExpenses: totalExpenses,
          netAmount: netAmount,
        );
        
        // Extract email, file path and download URL from response
        final userEmail = result['email'] as String;
        final filePath = result['filePath'] as String;
        final downloadUrl = result['downloadUrl'] as String;

        Get.snackbar(
          'Report Sent',
          'Your financial report has been sent to $userEmail successfully!',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () {
              // Open download URL in browser
              launchDownloadUrl(downloadUrl);
            },
            child: const Text(
              'DOWNLOAD',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        
        print('Report sent to email: $userEmail');
        print('File saved at: $filePath');
        print('Download URL: $downloadUrl');
      } catch (e) {
        print('Error sending PDF to server: $e');
        Get.snackbar(
          'Warning',
          'Report generated but failed to send to server: $e',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      
      // Open the generated PDF
      await PdfService.openPDF(pdfFile);
      
      Get.snackbar(
        'Report Generated',
        'Your financial report has been generated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error generating PDF report: $e');
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isGeneratingPdf.value = false;
    }
  }

  // New method to fetch market data
  Future<void> fetchMarketData() async {
    isLoadingMarketData.value = true;
    marketDataError.value = '';
    
    try {
      // Fetch market indices
      final indicesData = await _stockMarketService.getMarketIndices();
      marketIndices.value = indicesData['indices'] ?? {};
      
      // Fetch top gainers
      final gainersData = await _stockMarketService.getTopGainers();
      topGainers.value = (gainersData['gainers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      
    } catch (e) {
      marketDataError.value = 'Failed to load market data: ${e.toString()}';
    } finally {
      isLoadingMarketData.value = false;
    }
  }

  // Add this method to refresh market data
  void refreshMarketData() {
    fetchMarketData();
  }

  // Launch URL to download PDF
  Future<void> launchDownloadUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('Download URL launched: $url');
      } else {
        print('Could not launch URL: $url');
        Get.snackbar(
          'Error',
          'Could not open download link',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      Get.snackbar(
        'Error',
        'Failed to open download link: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// Class to hold monthly trends data
class MonthlyTrendsData {
  final String month;
  final double income;
  final double expense;
  final DateTime date; // Store actual date for sorting

  MonthlyTrendsData(this.month, this.income, this.expense, this.date);
}