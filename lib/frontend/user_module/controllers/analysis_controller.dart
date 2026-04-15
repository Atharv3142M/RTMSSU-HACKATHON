import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  final selectedRiskAppetite = 'Moderate'.obs;
  final monthlyIncomeInput = TextEditingController(text: '80000');
  final monthlyExpenseInput = TextEditingController(text: '50000');
  final emergencyGoalInput = TextEditingController(text: '300000');
  final emergencyMonthsInput = TextEditingController(text: '18');
  final houseGoalInput = TextEditingController(text: '1200000');
  final houseMonthsInput = TextEditingController(text: '60');
  final retirementGoalInput = TextEditingController(text: '5000000');
  final retirementMonthsInput = TextEditingController(text: '240');
  final debtInput = TextEditingController(text: '200000');
  final plannerResult = Rxn<PlanningResult>();

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
      calculatePlanningEngine();
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
      calculatePlanningEngine();
      
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

  void calculatePlanningEngine() {
    final income = _parseDouble(monthlyIncomeInput.text);
    final expense = _parseDouble(monthlyExpenseInput.text);
    final emergencyGoal = _parseDouble(emergencyGoalInput.text);
    final emergencyMonths = _parseInt(emergencyMonthsInput.text);
    final houseGoal = _parseDouble(houseGoalInput.text);
    final houseMonths = _parseInt(houseMonthsInput.text);
    final retirementGoal = _parseDouble(retirementGoalInput.text);
    final retirementMonths = _parseInt(retirementMonthsInput.text);
    final debt = _parseDouble(debtInput.text);

    final surplus = max(0.0, income - expense);
    final riskMap = {'Low': 0.8, 'Moderate': 1.0, 'High': 1.2};
    final riskMultiplier = riskMap[selectedRiskAppetite.value] ?? 1.0;
    final safeMonths = max(1, emergencyMonths);
    final houseSafeMonths = max(1, houseMonths);
    final retireSafeMonths = max(1, retirementMonths);

    final emergencyNeedPerMonth = emergencyGoal / safeMonths;
    final houseNeedPerMonth = houseGoal / houseSafeMonths;
    final retirementNeedPerMonth = retirementGoal / retireSafeMonths;
    final debtNeedPerMonth = debt > 0 ? debt / 24 : 0.0;

    final wEmergency = emergencyNeedPerMonth * 1.5;
    final wSip = retirementNeedPerMonth * riskMultiplier;
    final wFd = houseNeedPerMonth * (1.3 - (riskMultiplier - 0.8));
    final wDebt = debtNeedPerMonth * 1.4;
    final totalW = max(1.0, wEmergency + wSip + wFd + wDebt);

    final emergencyAlloc = surplus * (wEmergency / totalW);
    final sipAlloc = surplus * (wSip / totalW);
    final fdAlloc = surplus * (wFd / totalW);
    final debtAlloc = surplus * (wDebt / totalW);

    GoalFeasibility buildGoal(String name, double target, int months, double monthlyAllocation) {
      final achievable = monthlyAllocation * max(1, months);
      final isAchievable = achievable >= target;
      final requiredTimelineMonths = monthlyAllocation > 0 ? (target / monthlyAllocation).ceil() : 9999;
      return GoalFeasibility(
        name: name,
        targetAmount: target,
        timelineMonths: months,
        monthlyAllocation: monthlyAllocation,
        achievableAmount: achievable,
        isAchievable: isAchievable,
        requiredTimelineMonths: requiredTimelineMonths,
        math: '$name feasibility = monthly allocation ($monthlyAllocation) x timeline months ($months) = $achievable.',
      );
    }

    final goals = [
      buildGoal('Emergency Fund', emergencyGoal, safeMonths, emergencyAlloc),
      buildGoal('House Down Payment', houseGoal, houseSafeMonths, fdAlloc),
      buildGoal('Retirement', retirementGoal, retireSafeMonths, sipAlloc),
    ];

    final stressTests = _buildStressTests(
      income: income,
      expense: expense,
      surplus: surplus,
      emergencyAllocation: emergencyAlloc,
      sipAllocation: sipAlloc,
      fdAllocation: fdAlloc,
      debtAllocation: debtAlloc,
    );

    final roadmap = List<RoadmapMonth>.generate(12, (index) {
      final month = index + 1;
      return RoadmapMonth(
        month: month,
        emergency: emergencyAlloc,
        sip: sipAlloc,
        fd: fdAlloc,
        debtRepayment: debtAlloc,
        math:
            'Month $month allocation follows weighted formula: surplus ($surplus) x weight share.',
      );
    });

    plannerResult.value = PlanningResult(
      monthlyIncome: income,
      monthlyExpense: expense,
      monthlySurplus: surplus,
      riskAppetite: selectedRiskAppetite.value,
      weights: AllocationWeights(
        emergency: wEmergency,
        sip: wSip,
        fd: wFd,
        debt: wDebt,
        total: totalW,
        math:
            'Weight formulas: emergency=(goal/month)*1.5, SIP=(retirement/month)*riskMultiplier, FD=(house/month)*(1.3-(riskMultiplier-0.8)), debt=(debt/24)*1.4.',
      ),
      allocations: MonthlyAllocations(
        emergency: emergencyAlloc,
        sip: sipAlloc,
        fd: fdAlloc,
        debtRepayment: debtAlloc,
        math:
            'Allocation formula: category = surplus ($surplus) x categoryWeight / totalWeight ($totalW).',
      ),
      goals: goals,
      stressTests: stressTests,
      roadmap: roadmap,
    );
  }

  List<StressTestResult> _buildStressTests({
    required double income,
    required double expense,
    required double surplus,
    required double emergencyAllocation,
    required double sipAllocation,
    required double fdAllocation,
    required double debtAllocation,
  }) {
    final noIncomeDeficit = max(0.0, (expense * 3) - (surplus * 3));
    final inflationExpense = expense * 1.02;
    final inflationSurplus = max(0.0, income - inflationExpense);
    final inflationDropPct = surplus == 0 ? 0.0 : ((surplus - inflationSurplus) / surplus) * 100;
    return [
      StressTestResult(
        scenario: 'Job loss for 3 months',
        impact: 'Needs emergency buffer of ₹${noIncomeDeficit.toStringAsFixed(0)} to survive 3 months.',
        adjustment:
            'Increase emergency allocation by 20% until emergency fund >= 3 x monthly expenses.',
        math:
            'Deficit = (monthly expense x 3) - (monthly surplus x 3) = (${expense.toStringAsFixed(0)} x 3) - (${surplus.toStringAsFixed(0)} x 3).',
      ),
      StressTestResult(
        scenario: 'Medical emergency of ₹1L',
        impact: 'Immediate ₹100000 drawdown from emergency corpus.',
        adjustment:
            'Temporarily divert 30% SIP + 20% FD into emergency replenishment for 6 months.',
        math:
            'Replenishment/month = (SIP x 0.30) + (FD x 0.20) = ${sipAllocation.toStringAsFixed(0)} x 0.30 + ${fdAllocation.toStringAsFixed(0)} x 0.20.',
      ),
      StressTestResult(
        scenario: 'Inflation spike of 2%',
        impact: 'Monthly expense rises to ₹${inflationExpense.toStringAsFixed(0)} and surplus drops ${inflationDropPct.toStringAsFixed(1)}%.',
        adjustment:
            'Trim discretionary expenses by 2% or increase income to recover lost surplus.',
        math:
            'New expense = expense x 1.02, new surplus = income - new expense = ${income.toStringAsFixed(0)} - ${inflationExpense.toStringAsFixed(0)}.',
      ),
    ];
  }

  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0.0;
  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

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

  @override
  void onClose() {
    monthlyIncomeInput.dispose();
    monthlyExpenseInput.dispose();
    emergencyGoalInput.dispose();
    emergencyMonthsInput.dispose();
    houseGoalInput.dispose();
    houseMonthsInput.dispose();
    retirementGoalInput.dispose();
    retirementMonthsInput.dispose();
    debtInput.dispose();
    super.onClose();
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

class PlanningResult {
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlySurplus;
  final String riskAppetite;
  final AllocationWeights weights;
  final MonthlyAllocations allocations;
  final List<GoalFeasibility> goals;
  final List<StressTestResult> stressTests;
  final List<RoadmapMonth> roadmap;

  PlanningResult({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlySurplus,
    required this.riskAppetite,
    required this.weights,
    required this.allocations,
    required this.goals,
    required this.stressTests,
    required this.roadmap,
  });
}

class AllocationWeights {
  final double emergency;
  final double sip;
  final double fd;
  final double debt;
  final double total;
  final String math;

  AllocationWeights({
    required this.emergency,
    required this.sip,
    required this.fd,
    required this.debt,
    required this.total,
    required this.math,
  });
}

class MonthlyAllocations {
  final double emergency;
  final double sip;
  final double fd;
  final double debtRepayment;
  final String math;

  MonthlyAllocations({
    required this.emergency,
    required this.sip,
    required this.fd,
    required this.debtRepayment,
    required this.math,
  });
}

class GoalFeasibility {
  final String name;
  final double targetAmount;
  final int timelineMonths;
  final double monthlyAllocation;
  final double achievableAmount;
  final bool isAchievable;
  final int requiredTimelineMonths;
  final String math;

  GoalFeasibility({
    required this.name,
    required this.targetAmount,
    required this.timelineMonths,
    required this.monthlyAllocation,
    required this.achievableAmount,
    required this.isAchievable,
    required this.requiredTimelineMonths,
    required this.math,
  });
}

class StressTestResult {
  final String scenario;
  final String impact;
  final String adjustment;
  final String math;

  StressTestResult({
    required this.scenario,
    required this.impact,
    required this.adjustment,
    required this.math,
  });
}

class RoadmapMonth {
  final int month;
  final double emergency;
  final double sip;
  final double fd;
  final double debtRepayment;
  final String math;

  RoadmapMonth({
    required this.month,
    required this.emergency,
    required this.sip,
    required this.fd,
    required this.debtRepayment,
    required this.math,
  });
}