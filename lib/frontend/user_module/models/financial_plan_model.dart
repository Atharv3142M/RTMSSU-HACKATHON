import 'package:intl/intl.dart';

/// Risk appetite levels
enum RiskAppetite {
  conservative,  // Low risk, prefers FD/RD
  moderate,      // Balanced mix
  aggressive,    // High equity exposure
}

/// Financial goal types
enum GoalType {
  emergencyFund,
  houseDownPayment,
  retirement,
  education,
  marriage,
  car,
  vacation,
  other,
}

/// Investment instrument types
enum InstrumentType {
  emergencyFund,  // Liquid fund / Savings
  sip,           // Equity mutual fund SIP
  fd,            // Fixed deposit
  rd,            // Recurring deposit
  debtRepayment, // Loan/credit card payoff
  gold,          // Gold ETF / Sovereign gold bond
  nps,           // National Pension System
}

/// User financial profile input
class FinancialProfile {
  final double monthlyIncome;
  final double monthlyExpenses;
  final List<FinancialGoal> goals;
  final RiskAppetite riskAppetite;
  final double? existingEmergencyFund;
  final Map<String, double> existingDebts; // debt name -> outstanding amount
  final double? existingInvestments;

  FinancialProfile({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.goals,
    required this.riskAppetite,
    this.existingEmergencyFund,
    Map<String, double>? existingDebts,
    this.existingInvestments,
  }) : existingDebts = existingDebts ?? {};

  double get monthlySurplus => monthlyIncome - monthlyExpenses;

  double get totalDebts => existingDebts.values.fold(0, (sum, debt) => sum + debt);

  Map<String, dynamic> toJson() {
    return {
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'monthlySurplus': monthlySurplus,
      'goals': goals.map((g) => g.toJson()).toList(),
      'riskAppetite': riskAppetite.name,
      'existingEmergencyFund': existingEmergencyFund,
      'existingDebts': existingDebts,
      'existingInvestments': existingInvestments,
    };
  }
}

/// Individual financial goal
class FinancialGoal {
  final String id;
  final String name;
  final GoalType type;
  final double targetAmount;
  final DateTime targetDate;
  final double currentSaved;
  final int priority; // 1 = highest priority

  FinancialGoal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.targetDate,
    this.currentSaved = 0,
    this.priority = 5,
  });

  double get remainingAmount => targetAmount - currentSaved;

  int get monthsUntilTarget => targetDate.difference(DateTime.now()).inDays ~/ 30;

  double get monthlyRequirement => monthsUntilTarget > 0 ? remainingAmount / monthsUntilTarget : remainingAmount;

  bool get isAchievable => monthlyRequirement <= (targetAmount - currentSaved);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'targetAmount': targetAmount,
      'targetDate': DateFormat('yyyy-MM-dd').format(targetDate),
      'currentSaved': currentSaved,
      'priority': priority,
      'remainingAmount': remainingAmount,
      'monthsUntilTarget': monthsUntilTarget,
      'monthlyRequirement': monthlyRequirement,
    };
  }
}

/// Result of goal feasibility analysis
class GoalFeasibilityResult {
  final FinancialGoal goal;
  final bool isFeasible;
  final double requiredMonthlyContribution;
  final double feasibleMonthlyContribution;
  final String shortfallReason;
  final DateTime revisedTargetDate;
  final String formula;

  GoalFeasibilityResult({
    required this.goal,
    required this.isFeasible,
    required this.requiredMonthlyContribution,
    required this.feasibleMonthlyContribution,
    required this.shortfallReason,
    required this.revisedTargetDate,
    required this.formula,
  });

  double get shortfall => requiredMonthlyContribution - feasibleMonthlyContribution;

  int get monthsDelay => revisedTargetDate.difference(goal.targetDate).inDays ~/ 30;
}

/// Allocation result for a single instrument
class InstrumentAllocation {
  final InstrumentType instrument;
  final double amount;
  final double percentage;
  final String rationale;
  final String formula;

  InstrumentAllocation({
    required this.instrument,
    required this.amount,
    required this.percentage,
    required this.rationale,
    required this.formula,
  });
}

/// Complete allocation plan
class AllocationPlan {
  final double totalSurplus;
  final List<InstrumentAllocation> allocations;
  final Map<String, dynamic> weights;
  final String calculationSteps;

  AllocationPlan({
    required this.totalSurplus,
    required this.allocations,
    required this.weights,
    required this.calculationSteps,
  });

  double get totalAllocated => allocations.fold(0, (sum, a) => sum + a.amount);
}

/// Stress test scenario result
class StressTestResult {
  final String scenarioName;
  final String description;
  final double impactAmount;
  final String impactDescription;
  final List<String> requiredAdjustments;
  final Map<String, double> revisedAllocations;
  final String formula;

  StressTestResult({
    required this.scenarioName,
    required this.description,
    required this.impactAmount,
    required this.impactDescription,
    required this.requiredAdjustments,
    required this.revisedAllocations,
    required this.formula,
  });
}

/// Month-by-month roadmap item
class MonthlyRoadmapItem {
  final int monthNumber;
  final DateTime month;
  final Map<InstrumentType, double> allocations;
  final List<String> actions;
  final double cumulativeEmergencyFund;
  final double cumulativeInvestments;
  final double remainingDebt;
  final String notes;

  MonthlyRoadmapItem({
    required this.monthNumber,
    required this.month,
    required this.allocations,
    required this.actions,
    required this.cumulativeEmergencyFund,
    required this.cumulativeInvestments,
    required this.remainingDebt,
    required this.notes,
  });
}

/// Complete financial plan output
class FinancialPlan {
  final FinancialProfile profile;
  final List<GoalFeasibilityResult> feasibilityResults;
  final AllocationPlan allocationPlan;
  final List<StressTestResult> stressTests;
  final List<MonthlyRoadmapItem> roadmap;
  final List<String> warnings;
  final List<String> recommendations;

  FinancialPlan({
    required this.profile,
    required this.feasibilityResults,
    required this.allocationPlan,
    required this.stressTests,
    required this.roadmap,
    required this.warnings,
    required this.recommendations,
  });
}
