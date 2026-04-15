import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/financial_plan_model.dart';
import '../../services/financial_planning_engine.dart';
import 'financial_plan_input_page.dart';

class FinancialPlanPage extends StatefulWidget {
  const FinancialPlanPage({super.key});

  @override
  State<FinancialPlanPage> createState() => _FinancialPlanPageState();
}

class _FinancialPlanPageState extends State<FinancialPlanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FinancialPlan? _plan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generatePlan(FinancialProfile profile) {
    setState(() => _isLoading = true);

    // Simulate calculation time
    Future.delayed(const Duration(milliseconds: 500), () {
      final engine = FinancialPlanningEngine();
      _plan = engine.generatePlan(profile);
      setState(() => _isLoading = false);
      _tabController.animateTo(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
      appBar: _plan != null
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              elevation: 0,
              title: Text(
                'Financial Plan',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'Goals'),
                  Tab(text: 'Allocation'),
                  Tab(text: 'Stress Test'),
                ],
              ),
            )
          : AppBar(
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              elevation: 0,
              title: Text(
                'Financial Planning',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : _plan == null
              ? _buildInputScreen(context, isDark)
              : _buildPlanContent(context, isDark),
    );
  }

  Widget _buildInputScreen(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            Text(
              'Create Your Financial Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get a personalized 12-month roadmap with\nmath-backed allocations for your financial goals',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.54),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToInput(context),
                icon: const Icon(Icons.add),
                label: const Text('Create New Plan'),
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
          ],
        ),
      ),
    );
  }

  void _navigateToInput(BuildContext context) async {
    final profile = await Navigator.push<FinancialProfile>(
      context,
      MaterialPageRoute(builder: (_) => const FinancialPlanInputPage()),
    );

    if (profile != null) {
      _generatePlan(profile);
    }
  }

  Widget _buildPlanContent(BuildContext context, bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildSummaryTab(context, isDark),
        _buildGoalsTab(context, isDark),
        _buildAllocationTab(context, isDark),
        _buildStressTestTab(context, isDark),
      ],
    );
  }

  Widget _buildSummaryTab(BuildContext context, bool isDark) {
    final plan = _plan!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Summary Card
          _buildCard(
            context,
            title: 'Your Financial Profile',
            child: Column(
              children: [
                _buildSummaryRow(
                    'Monthly Income', '₹${plan.profile.monthlyIncome.toStringAsFixed(0)}', isDark),
                const SizedBox(height: 8),
                _buildSummaryRow(
                    'Monthly Expenses', '₹${plan.profile.monthlyExpenses.toStringAsFixed(0)}', isDark),
                const Divider(height: 24),
                _buildSummaryRow(
                    'Monthly Surplus', '₹${plan.profile.monthlySurplus.toStringAsFixed(0)}',
                    isDark,
                    valueColor: Colors.green),
                _buildSummaryRow(
                    'Risk Profile',
                    plan.profile.riskAppetite.name.toUpperCase(),
                    isDark,
                    isBadge: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Goals',
                  '${plan.profile.goals.length}',
                  Icons.flag,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Feasible',
                  '${plan.feasibilityResults.where((r) => r.isFeasible).length}/${plan.profile.goals.length}',
                  Icons.check_circle,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Warnings
          if (plan.warnings.isNotEmpty) ...[
            _buildCard(
              context,
              title: 'Warnings',
              color: Colors.orange.withOpacity(0.1),
              borderColor: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.warnings
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(w, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations
          _buildCard(
            context,
            title: 'Recommendations',
            color: Colors.green.withOpacity(0.1),
            borderColor: Colors.green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plan.recommendations
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r, style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(BuildContext context, bool isDark) {
    final plan = _plan!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.feasibilityResults.length,
      itemBuilder: (context, index) {
        final result = plan.feasibilityResults[index];
        return _buildGoalCard(context, result, isDark);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalFeasibilityResult result, bool isDark) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isFeasible ? Icons.check_circle : Icons.warning,
                  color: result.isFeasible ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.goal.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: () => _showMathBottomSheet(context, 'Goal Feasibility Math', result.formula),
                  tooltip: 'Show Math',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressIndicator(
              context,
              current: result.feasibleMonthlyContribution,
              target: result.requiredMonthlyContribution,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip('Required', '₹${result.requiredMonthlyContribution.toStringAsFixed(0)}/mo', isDark),
                _buildInfoChip('Feasible', '₹${result.feasibleMonthlyContribution.toStringAsFixed(0)}/mo', isDark),
                _buildInfoChip(
                  'Timeline',
                  result.isFeasible
                      ? '${result.goal.monthsUntilTarget} months'
                      : '+${result.monthsDelay} months',
                  isDark,
                  valueColor: result.isFeasible ? null : Colors.orange,
                ),
              ],
            ),
            if (!result.isFeasible) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adjustment Needed:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(result.shortfallReason, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationTab(BuildContext context, bool isDark) {
    final plan = _plan!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Allocation overview card
          _buildCard(
            context,
            title: 'Monthly Allocation Plan',
            subtitle: 'Based on your risk profile: ${plan.profile.riskAppetite.name.toUpperCase()}',
            child: Column(
              children: [
                // Allocation bars
                ...plan.allocationPlan.allocations.map((alloc) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(alloc.instrument.name.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.calculate, size: 18),
                            onPressed: () => _showMathBottomSheet(context,
                                '${alloc.instrument.name} Allocation', alloc.formula),
                            tooltip: 'Show Math',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAllocationBar(
                        context,
                        alloc.percentage,
                        alloc.amount,
                        isDark,
                      ),
                      const SizedBox(height: 4),
                      Text(alloc.rationale,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6))),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Calculation steps
          _buildCard(
            context,
            title: 'Calculation Details',
            child: SingleChildScrollView(
              child: Text(
                plan.allocationPlan.calculationSteps,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStressTestTab(BuildContext context, bool isDark) {
    final plan = _plan!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.stressTests.length,
      itemBuilder: (context, index) {
        final test = plan.stressTests[index];
        return _buildStressTestCard(context, test, isDark);
      },
    );
  }

  Widget _buildStressTestCard(BuildContext context, StressTestResult test, bool isDark) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStressTestIcon(test.scenarioName),
                  color: _getStressTestColor(test.scenarioName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    test.scenarioName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: () => _showMathBottomSheet(context, test.scenarioName, test.formula),
                  tooltip: 'Show Math',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              test.description,
              style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                test.impactDescription,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Required Adjustments:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...test.requiredAdjustments.map((adj) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Colors.orange)),
                  Expanded(child: Text(adj)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HELPER WIDGETS
  // =====================================================

  Widget _buildCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? child,
    Color? color,
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark,
      {Color? valueColor, bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7))),
        isBadge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context,
      {required double current, required double target, required bool isDark}) {
    final percentage = (current / target * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress to monthly requirement',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6))),
            Text('${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: percentage >= 100 ? Colors.green : Colors.orange,
                )),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: isDark ? Colors.white.withOpacity(0.24) : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 100 ? Colors.green : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, bool isDark, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6))),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationBar(BuildContext context, double percentage, double amount, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: isDark ? Colors.white.withOpacity(0.24) : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12)),
            Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showMathBottomSheet(BuildContext context, String title, String formula) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.24) : Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  formula,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStressTestIcon(String scenarioName) {
    if (scenarioName.contains('Job')) return Icons.work_off;
    if (scenarioName.contains('Medical')) return Icons.local_hospital;
    if (scenarioName.contains('Inflation')) return Icons.trending_up;
    return Icons.warning;
  }

  Color _getStressTestColor(String scenarioName) {
    if (scenarioName.contains('Job')) return Colors.orange;
    if (scenarioName.contains('Medical')) return Colors.red;
    if (scenarioName.contains('Inflation')) return Colors.orange;
    return Colors.grey;
  }
}
