import '../models/financial_plan_model.dart';

/// Multi-objective Financial Planning Engine
///
/// Implements:
/// 1. Goal Feasibility Check
/// 2. Weighted Allocation Algorithm
/// 3. Stress Testing
/// 4. 12-Month Roadmap Generation
class FinancialPlanningEngine {
  // Constants for calculations
  static const double _emergencyFundMonths = 6.0; // 6 months of expenses
  static const double _inflationRate = 0.06; // 6% annual inflation - used in stress tests
  static const double _sipExpectedReturn = 0.12; // 12% annual return on SIP
  static const double _fdReturn = 0.07; // 7% annual return on FD
  static const double _emergencyFundReturn = 0.04; // 4% return on emergency fund - used in roadmap

  // Risk-based allocation base percentages
  static const Map<RiskAppetite, Map<InstrumentType, double>> _baseAllocations = {
    RiskAppetite.conservative: {
      InstrumentType.emergencyFund: 0.30,
      InstrumentType.sip: 0.20,
      InstrumentType.fd: 0.35,
      InstrumentType.rd: 0.15,
      InstrumentType.debtRepayment: 0.00,
    },
    RiskAppetite.moderate: {
      InstrumentType.emergencyFund: 0.25,
      InstrumentType.sip: 0.40,
      InstrumentType.fd: 0.20,
      InstrumentType.rd: 0.10,
      InstrumentType.debtRepayment: 0.05,
    },
    RiskAppetite.aggressive: {
      InstrumentType.emergencyFund: 0.15,
      InstrumentType.sip: 0.55,
      InstrumentType.fd: 0.10,
      InstrumentType.rd: 0.05,
      InstrumentType.debtRepayment: 0.15,
    },
  };

  /// Generate complete financial plan
  FinancialPlan generatePlan(FinancialProfile profile) {
    final feasibilityResults = _analyzeGoalFeasibility(profile);
    final allocationPlan = _calculateWeightedAllocation(profile, feasibilityResults);
    final stressTests = _runStressTests(profile, allocationPlan);
    final roadmap = _generate12MonthRoadmap(profile, allocationPlan, feasibilityResults);
    final warnings = _generateWarnings(profile, feasibilityResults);
    final recommendations = _generateRecommendations(profile, feasibilityResults, allocationPlan);

    return FinancialPlan(
      profile: profile,
      feasibilityResults: feasibilityResults,
      allocationPlan: allocationPlan,
      stressTests: stressTests,
      roadmap: roadmap,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  // =====================================================
  // 1. GOAL FEASIBILITY CHECK
  // =====================================================

  List<GoalFeasibilityResult> _analyzeGoalFeasibility(FinancialProfile profile) {
    final results = <GoalFeasibilityResult>[];
    final availableSurplus = profile.monthlySurplus;

    for (final goal in profile.goals) {
      final requiredMonthly = goal.monthlyRequirement;

      // Calculate feasible contribution based on priority and available surplus
      // Higher priority goals get larger share of surplus
      final totalPriorityWeight = profile.goals.fold<double>(
        0, (sum, g) => sum + (1.0 / g.priority));

      final thisGoalWeight = (1.0 / goal.priority) / totalPriorityWeight;
      final feasibleContribution = availableSurplus * thisGoalWeight;

      final isFeasible = feasibleContribution >= requiredMonthly;

      // Calculate revised target date if not feasible
      final revisedDate = isFeasible
          ? goal.targetDate
          : _calculateRevisedTargetDate(goal, feasibleContribution);

      results.add(GoalFeasibilityResult(
        goal: goal,
        isFeasible: isFeasible,
        requiredMonthlyContribution: requiredMonthly,
        feasibleMonthlyContribution: feasibleContribution,
        shortfallReason: _getShortfallReason(goal, feasibleContribution, requiredMonthly),
        revisedTargetDate: revisedDate,
        formula: _buildFeasibilityFormula(goal, availableSurplus, thisGoalWeight),
      ));
    }

    return results;
  }

  String _buildFeasibilityFormula(
    FinancialGoal goal,
    double availableSurplus,
    double goalWeight
  ) {
    return '''
Goal Feasibility Formula:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Calculate Required Monthly Contribution
   Required = (Target Amount - Current Saved) / Months Until Target
   Required = (₹${goal.targetAmount.toStringAsFixed(0)} - ₹${goal.currentSaved.toStringAsFixed(0)}) / ${goal.monthsUntilTarget} months
   Required = ₹${goal.monthlyRequirement.toStringAsFixed(2)} / month

Step 2: Calculate Priority Weight
   Weight = (1 / Priority) / Σ(1 / Priorityᵢ)
   Weight = (1 / ${goal.priority}) / ${goalWeight.toStringAsFixed(4)}
   Weight = ${goalWeight.toStringAsFixed(2)} (${(goalWeight * 100).toStringAsFixed(1)}%)

Step 3: Calculate Feasible Contribution
   Feasible = Available Surplus × Weight
   Feasible = ₹${availableSurplus.toStringAsFixed(0)} × ${goalWeight.toStringAsFixed(4)}
   Feasible = ₹${(availableSurplus * goalWeight).toStringAsFixed(2)} / month

Step 4: Feasibility Check
   Feasible >= Required ?
   ₹${(availableSurplus * goalWeight).toStringAsFixed(2)} >= ₹${goal.monthlyRequirement.toStringAsFixed(2)} ?
   ${availableSurplus * goalWeight >= goal.monthlyRequirement ? 'YES - Goal is achievable' : 'NO - Goal needs adjustment'}
''';
  }

  DateTime _calculateRevisedTargetDate(FinancialGoal goal, double monthlyContribution) {
    if (monthlyContribution <= 0) {
      return DateTime.now().add(const Duration(days: 3650)); // 10 years
    }

    // Using compound interest formula for more accurate calculation
    // FV = PMT × [(1 + r)^n - 1] / r
    // Solving for n: n = log(FV × r / PMT + 1) / log(1 + r)

    final annualReturn = _getExpectedReturnForGoal(goal);
    final monthlyReturn = annualReturn / 12;
    final fv = goal.remainingAmount;

    if (monthlyReturn > 0) {
      final n = Math.log(fv * monthlyReturn / monthlyContribution + 1) /
                Math.log(1 + monthlyReturn);
      return DateTime.now().add(Duration(days: (n * 30).round()));
    } else {
      final months = fv / monthlyContribution;
      return DateTime.now().add(Duration(days: (months * 30).round()));
    }
  }

  String _getShortfallReason(
    FinancialGoal goal,
    double feasible,
    double required
  ) {
    final shortfall = required - feasible;
    if (shortfall <= 0) return 'No shortfall - goal is achievable';

    return '''
Shortfall: ₹${shortfall.toStringAsFixed(0)} per month
- Current surplus allocation: ₹${feasible.toStringAsFixed(0)}/month
- Required for goal: ₹${required.toStringAsFixed(0)}/month
- Gap: ${(shortfall / required * 100).toStringAsFixed(1)}% shortfall
''';
  }

  double _getExpectedReturnForGoal(FinancialGoal goal) {
    // Returns expected annual return based on goal timeline
    if (goal.monthsUntilTarget <= 12) return _fdReturn; // Short term: FD
    if (goal.monthsUntilTarget <= 36) return 0.08; // Medium term: Balanced
    return _sipExpectedReturn; // Long term: Equity
  }

  // =====================================================
  // 2. WEIGHTED ALLOCATION ALGORITHM
  // =====================================================

  AllocationPlan _calculateWeightedAllocation(
    FinancialProfile profile,
    List<GoalFeasibilityResult> feasibilityResults
  ) {
    final surplus = profile.monthlySurplus;
    final baseAllocation = _baseAllocations[profile.riskAppetite]!;

    // Calculate dynamic weights based on goals and risk
    final weights = _calculateDynamicWeights(profile, feasibilityResults);

    // Adjust base allocation with dynamic weights
    final adjustedAllocation = _adjustAllocationWithWeights(
      baseAllocation,
      weights,
      profile
    );

    // Convert percentages to amounts
    final allocations = <InstrumentAllocation>[];
    final steps = StringBuffer();

    steps.writeln('Allocation Calculation Steps:');
    steps.writeln('═══════════════════════════════════\n');
    steps.writeln('Input Parameters:');
    steps.writeln('  • Monthly Surplus: ₹${surplus.toStringAsFixed(0)}');
    steps.writeln('  • Risk Appetite: ${profile.riskAppetite.name.toUpperCase()}');
    steps.writeln('  • Emergency Fund Needed: ₹${(_emergencyFundMonths * profile.monthlyExpenses).toStringAsFixed(0)}');
    steps.writeln('  • Total Debts: ₹${profile.totalDebts.toStringAsFixed(0)}\n');

    for (final entry in adjustedAllocation.entries) {
      final amount = surplus * entry.value;
      allocations.add(InstrumentAllocation(
        instrument: entry.key,
        amount: amount,
        percentage: entry.value * 100,
        rationale: _getRationale(entry.key, profile, weights),
        formula: _buildAllocationFormula(entry.key, entry.value, surplus, weights, profile.riskAppetite),
      ));

      steps.writeln('${entry.key.name}:');
      steps.writeln('  Base Weight: ${(_baseAllocations[profile.riskAppetite]?[entry.key] ?? 0 * 100).toStringAsFixed(0)}%');
      steps.writeln('  Adjusted Weight: ${(entry.value * 100).toStringAsFixed(1)}%');
      steps.writeln('  Allocation: ₹${amount.toStringAsFixed(0)}\n');
    }

    return AllocationPlan(
      totalSurplus: surplus,
      allocations: allocations,
      weights: weights,
      calculationSteps: steps.toString(),
    );
  }

  Map<String, dynamic> _calculateDynamicWeights(
    FinancialProfile profile,
    List<GoalFeasibilityResult> feasibilityResults
  ) {
    final weights = <String, double>{};

    // Weight 1: Emergency Fund Priority (0-1)
    final emergencyFundGap = (_emergencyFundMonths * profile.monthlyExpenses) -
                            (profile.existingEmergencyFund ?? 0);
    weights['emergencyFundPriority'] = emergencyFundGap > 0
        ? (emergencyFundGap / (_emergencyFundMonths * profile.monthlyExpenses)).clamp(0.1, 0.5)
        : 0.1;

    // Weight 2: Debt Pressure (0-1)
    final debtToIncomeRatio = profile.totalDebts / profile.monthlyIncome;
    weights['debtPressure'] = debtToIncomeRatio.clamp(0, 0.4);

    // Weight 3: Goal Urgency (0-1)
    final nearestGoalMonths = profile.goals.isEmpty
        ? 120
        : profile.goals.map((g) => g.monthsUntilTarget).reduce((a, b) => a < b ? a : b);
    weights['goalUrgency'] = (1 - (nearestGoalMonths / 120)).clamp(0.1, 0.5);

    // Weight 4: Risk Adjustment (-0.2 to +0.2)
    switch (profile.riskAppetite) {
      case RiskAppetite.conservative:
        weights['riskAdjustment'] = -0.15;
        break;
      case RiskAppetite.moderate:
        weights['riskAdjustment'] = 0;
        break;
      case RiskAppetite.aggressive:
        weights['riskAdjustment'] = 0.15;
        break;
    }

    return weights;
  }

  Map<InstrumentType, double> _adjustAllocationWithWeights(
    Map<InstrumentType, double> baseAllocation,
    Map<String, dynamic> weights,
    FinancialProfile profile
  ) {
    final adjusted = Map<InstrumentType, double>.from(baseAllocation);

    // Adjust emergency fund allocation based on gap
    final efPriority = weights['emergencyFundPriority'] as double;
    adjusted[InstrumentType.emergencyFund] =
        (baseAllocation[InstrumentType.emergencyFund]! + efPriority * 0.2).clamp(0.1, 0.5);

    // Adjust debt repayment based on debt pressure
    final debtPressure = weights['debtPressure'] as double;
    adjusted[InstrumentType.debtRepayment] =
        (baseAllocation[InstrumentType.debtRepayment]! + debtPressure * 0.3).clamp(0, 0.4);

    // Adjust SIP based on risk and goal urgency
    final riskAdj = weights['riskAdjustment'] as double;
    final goalUrgency = weights['goalUrgency'] as double;
    adjusted[InstrumentType.sip] =
        (baseAllocation[InstrumentType.sip]! + riskAdj + goalUrgency * 0.1).clamp(0.1, 0.6);

    // Normalize to ensure total = 1.0
    final total = adjusted.values.fold(0.0, (sum, val) => sum + val);
    return adjusted.map((key, value) => MapEntry(key, value / total));
  }

  String _getRationale(
    InstrumentType instrument,
    FinancialProfile profile,
    Map<String, dynamic> weights
  ) {
    switch (instrument) {
      case InstrumentType.emergencyFund:
        final gap = (_emergencyFundMonths * profile.monthlyExpenses) - (profile.existingEmergencyFund ?? 0);
        return gap > 0
            ? 'Building emergency fund (${_emergencyFundMonths} months expenses = ₹${(_emergencyFundMonths * profile.monthlyExpenses).toStringAsFixed(0)})'
            : 'Maintaining emergency fund buffer';
      case InstrumentType.sip:
        return profile.riskAppetite == RiskAppetite.aggressive
            ? 'Aggressive wealth creation via equity (12% expected return)'
            : profile.riskAppetite == RiskAppetite.moderate
                ? 'Balanced growth via equity SIP (12% expected return)'
                : 'Conservative equity exposure for inflation beating (12% expected return)';
      case InstrumentType.fd:
        return 'Capital preservation with guaranteed returns (7% annual)';
      case InstrumentType.rd:
        return 'Disciplined savings with moderate returns (6.5% annual)';
      case InstrumentType.debtRepayment:
        final highInterestDebt = profile.existingDebts.entries
            .where((e) => e.value > 0)
            .fold(0.0, (sum, e) => sum + e.value);
        return highInterestDebt > 0
            ? 'High-interest debt elimination (effective return = interest saved)'
            : 'No high-priority debt';
      default:
        return 'Diversification';
    }
  }

  String _buildAllocationFormula(
    InstrumentType instrument,
    double weight,
    double surplus,
    Map<String, dynamic> weights,
    RiskAppetite riskAppetite
  ) {
    return '''
${instrument.name.toUpperCase()} Allocation Formula:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Base Weight (${riskAppetite.name}): ${(_baseAllocations[RiskAppetite.moderate]?[instrument] ?? 0 * 100).toStringAsFixed(0)}%

Adjustments Applied:
${instrument == InstrumentType.emergencyFund ? '  + Emergency Fund Priority: +${(weights['emergencyFundPriority'] * 20).toStringAsFixed(1)}%' : ''}
${instrument == InstrumentType.debtRepayment ? '  + Debt Pressure Factor: +${(weights['debtPressure'] * 30).toStringAsFixed(1)}%' : ''}
${instrument == InstrumentType.sip ? '  + Risk Adjustment: ${(weights['riskAdjustment'] * 100).toStringAsFixed(1)}%\n  + Goal Urgency: +${(weights['goalUrgency'] * 10).toStringAsFixed(1)}%' : ''}

Final Weight: ${(weight * 100).toStringAsFixed(1)}%
Allocation Amount: ₹${surplus.toStringAsFixed(0)} × ${(weight * 100).toStringAsFixed(1)}% = ₹${(surplus * weight).toStringAsFixed(0)}
''';
  }

  // =====================================================
  // 3. STRESS TESTING
  // =====================================================

  List<StressTestResult> _runStressTests(
    FinancialProfile profile,
    AllocationPlan allocationPlan
  ) {
    return [
      _jobLossScenario(profile, allocationPlan),
      _medicalEmergencyScenario(profile, allocationPlan),
      _inflationSpikeScenario(profile, allocationPlan),
    ];
  }

  StressTestResult _jobLossScenario(
    FinancialProfile profile,
    AllocationPlan plan
  ) {
    final emergencyFundAvailable = profile.existingEmergencyFund ?? 0;
    final monthlyExpenses = profile.monthlyExpenses;
    final jobLossDuration = 3; // months
    final totalNeeded = monthlyExpenses * jobLossDuration;

    final adjustments = <String>[];
    final revisedAllocations = <String, double>{};

    if (emergencyFundAvailable >= totalNeeded) {
      adjustments.add('Emergency fund covers 3 months expenses');
      adjustments.add('Pause SIP/FD contributions during job loss period');
      revisedAllocations['emergencyFund'] = -totalNeeded;
      revisedAllocations['sip'] = 0;
      revisedAllocations['fd'] = 0;
    } else {
      final shortfall = totalNeeded - emergencyFundAvailable;
      adjustments.add('Emergency fund shortfall: ₹${shortfall.toStringAsFixed(0)}');
      adjustments.add('Need to liquidate investments or reduce expenses');
      revisedAllocations['emergencyFund'] = -emergencyFundAvailable;
      revisedAllocations['sip'] = -(plan.allocations.firstWhere(
        (a) => a.instrument == InstrumentType.sip
      ).amount * jobLossDuration);
    }

    return StressTestResult(
      scenarioName: 'Job Loss (3 months)',
      description: 'Loss of income for 3 months - testing emergency fund adequacy',
      impactAmount: totalNeeded,
      impactDescription: 'Total impact: ₹${totalNeeded.toStringAsFixed(0)} needed for 3 months expenses',
      requiredAdjustments: adjustments,
      revisedAllocations: revisedAllocations,
      formula: '''
Job Loss Stress Test Formula:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scenario: Income loss for 3 months

Calculation:
  Monthly Expenses: ₹${monthlyExpenses.toStringAsFixed(0)}
  Duration: 3 months
  Total Needed: ₹${monthlyExpenses.toStringAsFixed(0)} × 3 = ₹${totalNeeded.toStringAsFixed(0)}

Emergency Fund Analysis:
  Available: ₹${emergencyFundAvailable.toStringAsFixed(0)}
  Required: ₹${totalNeeded.toStringAsFixed(0)}
  ${emergencyFundAvailable >= totalNeeded ? '✓ ADEQUATE' : '✗ SHORTFALL of ₹${(totalNeeded - emergencyFundAvailable).toStringAsFixed(0)}'}

Revised Allocation During Crisis:
  - Emergency Fund: -₹${(emergencyFundAvailable > totalNeeded ? totalNeeded : emergencyFundAvailable).toStringAsFixed(0)}
  - SIP: Paused (₹${plan.allocations.firstWhere((a) => a.instrument == InstrumentType.sip).amount.toStringAsFixed(0)}/month saved)
  - New Investments: Paused until income resumes
''',
    );
  }

  StressTestResult _medicalEmergencyScenario(
    FinancialProfile profile,
    AllocationPlan plan
  ) {
    final medicalExpense = 100000.0; // ₹1 Lakh
    final emergencyFundAvailable = profile.existingEmergencyFund ?? 0;
    final monthlySurplus = profile.monthlySurplus;

    final adjustments = <String>[];

    if (emergencyFundAvailable >= medicalExpense) {
      adjustments.add('Emergency fund covers medical expense');
      adjustments.add('Resume normal allocation after 1 month');
    } else if (emergencyFundAvailable + monthlySurplus >= medicalExpense) {
      adjustments.add('Use emergency fund + 1 month surplus');
      adjustments.add('Temporary reduction in SIP for ${((medicalExpense - emergencyFundAvailable) / monthlySurplus).ceil()} months');
    } else {
      adjustments.add('Emergency fund insufficient - consider health insurance');
      adjustments.add('May need to pause SIP for ${(medicalExpense / monthlySurplus).ceil()} months');
    }

    return StressTestResult(
      scenarioName: 'Medical Emergency (₹1 Lakh)',
      description: 'Unexpected medical expense of ₹1,00,000',
      impactAmount: medicalExpense,
      impactDescription: 'One-time expense of ₹${medicalExpense.toStringAsFixed(0)}',
      requiredAdjustments: adjustments,
      revisedAllocations: {
        'emergencyFund': -(emergencyFundAvailable > medicalExpense ? medicalExpense : emergencyFundAvailable),
        'surplus': -monthlySurplus,
      },
      formula: '''
Medical Emergency Stress Test Formula:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scenario: ₹1,00,000 medical expense

Impact Analysis:
  Emergency Fund: ₹${emergencyFundAvailable.toStringAsFixed(0)}
  Medical Expense: ₹${medicalExpense.toStringAsFixed(0)}
  ${emergencyFundAvailable >= medicalExpense ? '✓ Fully covered by emergency fund' :
    emergencyFundAvailable + monthlySurplus >= medicalExpense
      ? '✓ Covered with emergency fund + 1 month surplus'
      : '✗ Insufficient - need ₹${(medicalExpense - emergencyFundAvailable).toStringAsFixed(0)} more'}

Recovery Plan:
  Months to rebuild emergency fund: ${(medicalExpense / monthlySurplus).ceil()}
  Monthly surplus available: ₹${monthlySurplus.toStringAsFixed(0)}
''',
    );
  }

  StressTestResult _inflationSpikeScenario(
    FinancialProfile profile,
    AllocationPlan plan
  ) {
    final inflationIncrease = 0.02; // 2% spike
    final increasedExpenses = profile.monthlyExpenses * (1 + inflationIncrease);
    final expenseIncrease = increasedExpenses - profile.monthlyExpenses;
    final newSurplus = profile.monthlyIncome - increasedExpenses;

    final adjustments = <String>[];

    if (newSurplus > 0) {
      adjustments.add('Surplus reduced from ₹${profile.monthlySurplus.toStringAsFixed(0)} to ₹${newSurplus.toStringAsFixed(0)}');
      adjustments.add('Reduce SIP allocation proportionally');
      adjustments.add('Consider increasing income or reducing discretionary expenses');
    } else {
      adjustments.add('WARNING: Expenses exceed income!');
      adjustments.add('Immediate action needed: Reduce expenses or increase income');
      adjustments.add('Emergency fund will be depleted in ${(profile.existingEmergencyFund ?? 0) / expenseIncrease} months');
    }

    return StressTestResult(
      scenarioName: 'Inflation Spike (+2%)',
      description: 'Sustained 2% increase in inflation affecting all expenses',
      impactAmount: expenseIncrease * 12, // Annual impact
      impactDescription: 'Monthly expenses increase by ₹${expenseIncrease.toStringAsFixed(0)}; Annual impact: ₹${(expenseIncrease * 12).toStringAsFixed(0)}',
      requiredAdjustments: adjustments,
      revisedAllocations: {
        'originalSurplus': profile.monthlySurplus,
        'newSurplus': newSurplus,
        'reduction': profile.monthlySurplus - newSurplus,
      },
      formula: '''
Inflation Spike Stress Test Formula:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scenario: 2% inflation increase

Impact Calculation:
  Current Monthly Expenses: ₹${profile.monthlyExpenses.toStringAsFixed(0)}
  Inflation Increase: 2%
  Additional Monthly Cost: ₹${profile.monthlyExpenses.toStringAsFixed(0)} × 0.02 = ₹${expenseIncrease.toStringAsFixed(0)}
  New Monthly Expenses: ₹${increasedExpenses.toStringAsFixed(0)}

Surplus Impact:
  Original Surplus: ₹${profile.monthlySurplus.toStringAsFixed(0)}
  New Surplus: ₹${profile.monthlyIncome.toStringAsFixed(0)} - ₹${increasedExpenses.toStringAsFixed(0)} = ₹${newSurplus.toStringAsFixed(0)}
  Surplus Reduction: ${(profile.monthlySurplus - newSurplus) / profile.monthlySurplus * 100}

Annual Impact:
  ₹${expenseIncrease.toStringAsFixed(0)} × 12 = ₹${(expenseIncrease * 12).toStringAsFixed(0)} additional expenses per year
''',
    );
  }

  // =====================================================
  // 4. 12-MONTH ROADMAP GENERATION
  // =====================================================

  List<MonthlyRoadmapItem> _generate12MonthRoadmap(
    FinancialProfile profile,
    AllocationPlan plan,
    List<GoalFeasibilityResult> feasibilityResults
  ) {
    final roadmap = <MonthlyRoadmapItem>[];
    var cumulativeEmergencyFund = profile.existingEmergencyFund ?? 0;
    var cumulativeInvestments = profile.existingInvestments ?? 0;
    var remainingDebt = profile.totalDebts;

    final targetEmergencyFund = _emergencyFundMonths * profile.monthlyExpenses;

    for (int month = 1; month <= 12; month++) {
      final monthDate = DateTime.now().add(Duration(days: month * 30));
      final allocations = <InstrumentType, double>{};
      final actions = <String>[];

      for (final allocation in plan.allocations) {
        var amount = allocation.amount;

        // Adjust emergency fund allocation once target is reached
        if (allocation.instrument == InstrumentType.emergencyFund &&
            cumulativeEmergencyFund >= targetEmergencyFund) {
          // Redirect to SIP
          amount = allocation.amount * 0.5; // 50% to SIP instead
          allocations[InstrumentType.sip] = (allocations[InstrumentType.sip] ?? 0) + amount;
        } else {
          allocations[allocation.instrument] = amount;
        }

        // Update cumulative values
        if (allocation.instrument == InstrumentType.emergencyFund) {
          cumulativeEmergencyFund += amount;
        } else if (allocation.instrument == InstrumentType.sip ||
                   allocation.instrument == InstrumentType.fd) {
          cumulativeInvestments += amount;
        } else if (allocation.instrument == InstrumentType.debtRepayment) {
          remainingDebt = (remainingDebt - amount).clamp(0, double.infinity);
        }
      }

      // Generate action items
      if (month == 1) {
        actions.add('Start emergency fund with ₹${allocations[InstrumentType.emergencyFund]?.toStringAsFixed(0) ?? '0'}');
        actions.add('Set up SIP of ₹${allocations[InstrumentType.sip]?.toStringAsFixed(0) ?? '0'}');
        if (remainingDebt > 0) {
          actions.add('Begin debt repayment: ₹${allocations[InstrumentType.debtRepayment]?.toStringAsFixed(0) ?? '0'}/month');
        }
      }

      if (cumulativeEmergencyFund >= targetEmergencyFund && month <= 6) {
        actions.add('✓ Emergency fund target achieved! Redirecting surplus to investments.');
      }

      if (remainingDebt <= 0 && profile.totalDebts > 0) {
        actions.add('✓ All debts cleared! Full surplus available for investments.');
      }

      // Add goal-specific actions
      for (final result in feasibilityResults) {
        if (result.isFeasible && month % 3 == 0) {
          final contributed = result.feasibleMonthlyContribution * month;
          final progress = (contributed / result.goal.remainingAmount * 100);
          if (progress >= 25 && progress < 30) {
            actions.add('${result.goal.name}: ${progress.toStringAsFixed(0)}% complete');
          }
        }
      }

      roadmap.add(MonthlyRoadmapItem(
        monthNumber: month,
        month: monthDate,
        allocations: allocations,
        actions: actions,
        cumulativeEmergencyFund: cumulativeEmergencyFund,
        cumulativeInvestments: cumulativeInvestments,
        remainingDebt: remainingDebt,
        notes: _generateMonthNotes(month, allocations, cumulativeEmergencyFund, targetEmergencyFund),
      ));
    }

    return roadmap;
  }

  String _generateMonthNotes(
    int month,
    Map<InstrumentType, double> allocations,
    double cumulativeEF,
    double targetEF
  ) {
    final notes = StringBuffer();

    if (month == 1) {
      notes.writeln('Month 1: Foundation month - setting up all investment instruments.');
    }

    if (cumulativeEF >= targetEF && month > 1) {
      notes.writeln('Emergency fund complete! Additional funds redirected to wealth creation.');
    }

    if (month == 6) {
      notes.writeln('6-month review: Assess goal progress and rebalance if needed.');
    }

    if (month == 12) {
      notes.writeln('Annual review complete. Consider increasing SIP by 10% next year.');
    }

    return notes.toString();
  }

  // =====================================================
  // WARNINGS & RECOMMENDATIONS
  // =====================================================

  List<String> _generateWarnings(
    FinancialProfile profile,
    List<GoalFeasibilityResult> feasibilityResults
  ) {
    final warnings = <String>[];

    // Emergency fund warning
    if ((profile.existingEmergencyFund ?? 0) < _emergencyFundMonths * profile.monthlyExpenses) {
      warnings.add('⚠️ Emergency fund insufficient. Build 6 months expenses before aggressive investing.');
    }

    // High debt warning
    if (profile.totalDebts > profile.monthlyIncome * 6) {
      warnings.add('⚠️ High debt burden. Prioritize debt repayment over new investments.');
    }

    // Infeasible goals warning
    final infeasibleGoals = feasibilityResults.where((r) => !r.isFeasible).toList();
    if (infeasibleGoals.isNotEmpty) {
      warnings.add('⚠️ ${infeasibleGoals.length} goal(s) may need timeline adjustment: ${infeasibleGoals.map((g) => g.goal.name).join(', ')}');
    }

    // Negative surplus warning
    if (profile.monthlySurplus <= 0) {
      warnings.add('🚨 Expenses exceed income! Reduce expenses before any investing.');
    }

    return warnings;
  }

  List<String> _generateRecommendations(
    FinancialProfile profile,
    List<GoalFeasibilityResult> feasibilityResults,
    AllocationPlan allocationPlan
  ) {
    final recommendations = <String>[];

    // Based on risk appetite
    if (profile.riskAppetite == RiskAppetite.conservative && profile.goals.any((g) => g.monthsUntilTarget > 60)) {
      recommendations.add('Consider moderate allocation for long-term goals (>5 years) to beat inflation.');
    }

    // Based on goal feasibility
    final feasibleGoals = feasibilityResults.where((r) => r.isFeasible).toList();
    if (feasibleGoals.length == profile.goals.length && profile.goals.isNotEmpty) {
      recommendations.add('All goals are achievable! Consider increasing SIP by 10% annually.');
    }

    // Emergency fund specific
    if ((profile.existingEmergencyFund ?? 0) >= _emergencyFundMonths * profile.monthlyExpenses) {
      recommendations.add('Emergency fund is adequate. Focus on wealth creation via SIP.');
    }

    // Debt specific
    if (profile.totalDebts > 0) {
      final highInterestDebts = profile.existingDebts.entries.where((e) => e.value > profile.monthlyIncome);
      if (highInterestDebts.isNotEmpty) {
        recommendations.add('Prioritize high-interest debt repayment (credit cards, personal loans).');
      }
    }

    return recommendations;
  }
}

// Simple Math helper for logarithms
class Math {
  static double log(double x) => _logNatural(x) / _logNatural(10);
  static double _logNatural(double x) {
    if (x <= 0) return double.negativeInfinity;
    double result = 0.0;
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    for (int i = 0; i < 100; i++) {
      double term = y / (2 * i + 1);
      result += term;
      y *= y2;
      if (term.abs() < 1e-15) break;
    }
    return 2 * result;
  }
}
