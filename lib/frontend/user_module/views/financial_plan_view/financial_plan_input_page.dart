import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/financial_plan_model.dart';

class FinancialPlanInputPage extends StatefulWidget {
  const FinancialPlanInputPage({super.key});

  @override
  State<FinancialPlanInputPage> createState() => _FinancialPlanInputPageState();
}

class _FinancialPlanInputPageState extends State<FinancialPlanInputPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _emergencyFundController = TextEditingController();
  final _existingInvestmentsController = TextEditingController();

  // Goals
  final List<Map<String, dynamic>> _goals = [];

  // Form state
  RiskAppetite _riskAppetite = RiskAppetite.moderate;

  // Add goal form
  final _goalNameController = TextEditingController();
  final _goalTargetController = TextEditingController();
  final _goalCurrentController = TextEditingController();
  final _goalPriorityController = TextEditingController(text: '5');
  DateTime _goalTargetDate = DateTime.now().add(const Duration(days: 365));
  GoalType _selectedGoalType = GoalType.other;

  void _addGoal() {
    if (_goalNameController.text.isEmpty ||
        _goalTargetController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in required goal fields');
      return;
    }

    setState(() {
      _goals.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _goalNameController.text,
        'type': _selectedGoalType,
        'targetAmount': double.tryParse(_goalTargetController.text) ?? 0,
        'currentSaved': double.tryParse(_goalCurrentController.text) ?? 0,
        'targetDate': _goalTargetDate,
        'priority': int.tryParse(_goalPriorityController.text) ?? 5,
      });

      // Clear form
      _goalNameController.clear();
      _goalTargetController.clear();
      _goalCurrentController.clear();
      _goalPriorityController.text = '5';
    });

    Navigator.pop(context);
  }

  void _submitPlan() {
    if (!_formKey.currentState!.validate()) return;
    if (_goals.isEmpty) {
      Get.snackbar('Error', 'Please add at least one financial goal');
      return;
    }

    final income = double.tryParse(_incomeController.text) ?? 0;
    final expenses = double.tryParse(_expensesController.text) ?? 0;

    if (income <= 0) {
      Get.snackbar('Error', 'Please enter valid monthly income');
      return;
    }

    if (expenses <= 0) {
      Get.snackbar('Error', 'Please enter valid monthly expenses');
      return;
    }

    if (income <= expenses) {
      Get.snackbar('Warning', 'Your expenses exceed income. Consider reducing expenses first.');
    }

    final profile = FinancialProfile(
      monthlyIncome: income,
      monthlyExpenses: expenses,
      goals: _goals.map((g) => FinancialGoal(
        id: g['id'],
        name: g['name'],
        type: g['type'],
        targetAmount: g['targetAmount'],
        currentSaved: g['currentSaved'],
        targetDate: g['targetDate'],
        priority: g['priority'],
      )).toList(),
      riskAppetite: _riskAppetite,
      existingEmergencyFund: double.tryParse(_emergencyFundController.text) ?? 0,
      existingInvestments: double.tryParse(_existingInvestmentsController.text) ?? 0,
    );

    Navigator.pop(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        title: Text(
          'Create Financial Plan',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitPlan,
            child: Text(
              'Generate Plan',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Income & Expenses
              _buildSectionTitle(context, 'Monthly Finances'),
              _buildCard(
                context,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _incomeController,
                      label: 'Monthly Income',
                      hint: '₹ e.g., 50000',
                      prefix: '₹',
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _expensesController,
                      label: 'Monthly Expenses',
                      hint: '₹ e.g., 35000',
                      prefix: '₹',
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Existing Savings
              _buildSectionTitle(context, 'Existing Savings & Investments'),
              _buildCard(
                context,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _emergencyFundController,
                      label: 'Emergency Fund Available',
                      hint: '₹ Current savings for emergencies',
                      prefix: '₹',
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _existingInvestmentsController,
                      label: 'Other Investments',
                      hint: '₹ SIP, FD, Stocks, etc.',
                      prefix: '₹',
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: Risk Appetite
              _buildSectionTitle(context, 'Risk Profile'),
              _buildCard(
                context,
                child: Column(
                  children: [
                    _buildRiskOption(
                      context,
                      RiskAppetite.conservative,
                      'Conservative',
                      'Prefer safe investments (FD, RD). Low returns but capital protection.',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildRiskOption(
                      context,
                      RiskAppetite.moderate,
                      'Moderate',
                      'Balanced mix of equity and debt. Moderate risk for better returns.',
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildRiskOption(
                      context,
                      RiskAppetite.aggressive,
                      'Aggressive',
                      'High equity exposure. Can tolerate volatility for maximum growth.',
                      isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 4: Financial Goals
              _buildSectionTitle(context, 'Financial Goals'),
              if (_goals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(style: BorderStyle.solid, width: 1, color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No goals added yet',
                        style: TextStyle(color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your financial goals to get started',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.54)),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _goals.map((goal) => _buildGoalItem(goal, isDark)).toList(),
                ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddGoalDialog(context, isDark),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Goal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitPlan,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Financial Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String prefix,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: '$prefix ',
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskOption(BuildContext context, RiskAppetite risk, String title, String description, bool isDark) {
    final isSelected = _riskAppetite == risk;
    return GestureDetector(
      onTap: () => setState(() => _riskAppetite = risk),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${goal['targetAmount'].toStringAsFixed(0)} by ${_formatDate(goal['targetDate'])}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => setState(() => _goals.remove(goal)),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Financial Goal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Goal Name
              _buildTextField(
                controller: _goalNameController,
                label: 'Goal Name',
                hint: 'e.g., House Down Payment',
                prefix: '',
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Goal Type
              Text('Goal Type', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              DropdownButtonFormField<GoalType>(
                value: _selectedGoalType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: GoalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _selectedGoalType = v!),
              ),
              const SizedBox(height: 16),

              // Target Amount
              _buildTextField(
                controller: _goalTargetController,
                label: 'Target Amount',
                hint: '₹ e.g., 500000',
                prefix: '₹',
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Current Saved
              _buildTextField(
                controller: _goalCurrentController,
                label: 'Already Saved',
                hint: '₹ Current savings for this goal',
                prefix: '₹',
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Target Date
              Text('Target Date', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _goalTargetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _goalTargetDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_goalTargetDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Priority
              Text('Priority (1 = Highest, 5 = Lowest)', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _goalPriorityController,
                label: 'Priority Level',
                hint: '1-5 (1 = Most Important)',
                prefix: '',
                isDark: isDark,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Goal'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expensesController.dispose();
    _emergencyFundController.dispose();
    _existingInvestmentsController.dispose();
    _goalNameController.dispose();
    _goalTargetController.dispose();
    _goalCurrentController.dispose();
    _goalPriorityController.dispose();
    super.dispose();
  }
}
