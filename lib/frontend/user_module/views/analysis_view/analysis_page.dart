import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../controllers/analysis_controller.dart';

class AnalysisPage extends StatelessWidget {
  final AnalysisController controller = Get.put(AnalysisController());

  AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financial Analysis',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          // PDF Download Button
          Obx(() => controller.isGeneratingPdf.value
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.download_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Download PDF Report',
                  onPressed: () => controller.generatePdfReport(),
                )),
        ],
      ),
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadUserIdAndFetchTransactions(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCards(context),
              const SizedBox(height: 32),
              
              // Download Report Button
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: controller.isGeneratingPdf.value 
                    ? null 
                    : controller.generatePdfReport,
                  icon: controller.isGeneratingPdf.value
                      ? Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 8),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    controller.isGeneratingPdf.value
                      ? 'Generating PDF...'
                      : 'Download Financial Report',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Charts Sections (moved before market data)
              _buildChartsSection(context),
              const SizedBox(height: 32),
              _buildMonthlyTrendsChart(context),
              const SizedBox(height: 32),
              
              // Market Data Section (moved after charts)
              _buildMarketDataSection(context),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildModernBottomNav(context),
    );
  }

  Widget _buildModernBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 80, // Increased height to prevent overflow
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface.withOpacity(0.7)
                : Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomAppBar(
            elevation: 0,
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 12,
            height: 90, // Match container height
            padding: EdgeInsets.zero, // Remove default padding
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ModernBottomNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: false,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/homePage');
                    },
                  ),
                  _ModernBottomNavItem(
                    icon: Icons.analytics_outlined,
                    activeIcon: Icons.analytics_rounded,
                    label: 'Analytics',
                    isActive: true,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/analysis');
                    },
                  ), // Space for FAB
                  _ModernBottomNavItem(
                    icon: Icons.flag_outlined,
                    activeIcon: Icons.flag_rounded,
                    label: 'Goals',
                    isActive: false,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/goals');
                    },
                  ),
                  _ModernBottomNavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    isActive: false,
                    theme: theme,
                    onTap: () {
                      Get.offNamed('/user-profile');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final cards = [
      _buildSummaryCard(
        context,
        'Total Income',
        controller.totalIncome,
        Color(0xFF81C784),
        Icons.trending_up,
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      _buildSummaryCard(
        context,
        'Total Expenses',
        controller.totalExpenses,
        Color(0xFFE57373),
        Icons.trending_down,
        Theme.of(context).colorScheme.onErrorContainer,
      ),
      _buildSummaryCard(
        context,
        'Net Amount',
        controller.netAmount,
        controller.netAmount >= 0
            ? Color(0xFF64B5F6)
            : Theme.of(context).colorScheme.tertiaryContainer,
        controller.netAmount >= 0 ? Icons.account_balance : Icons.warning,
        controller.netAmount >= 0
            ? Theme.of(context).colorScheme.onSecondaryContainer
            : Theme.of(context).colorScheme.onTertiaryContainer,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cards[0],
        const SizedBox(height: 12),
        cards[1],
        const SizedBox(height: 12),
        cards[2],
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
    Color iconTextColor,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconTextColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconTextColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: iconTextColor.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Category Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // Expense chart with RepaintBoundary for PDF generation
        RepaintBoundary(
          key: controller.expenseChartKey,
          child: _buildPieChart(
            context,
            controller.getExpenseData(),
            'Expenses',
          ),
        ),
        const SizedBox(height: 32),
        // Income chart with RepaintBoundary for PDF generation
        RepaintBoundary(
          key: controller.incomeChartKey,
          child: _buildDonutChart(
            context,
            controller.getIncomeData(),
            'Income',
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<String, double> data,
    String title,
  ) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return _buildEmptyChart(context, title);
    }

    final List<Color> colors = [
      const Color(0xFFA8D5BA), // Pastel mint green
      const Color(0xFFFFCBCB), // Pastel pink/peach
      const Color(0xFFFFF6B7), // Pale yellow
      const Color(0xFFFFB6B9), // Soft red/coral
      const Color(0xFFD6E5FA), // Pastel sky blue
      const Color(0xFFFFECD2), // Creamy orange
      const Color(0xFFC4C1E0), // Lavender pastel
      const Color(0xFFB2DFDB), // Pastel teal
      const Color(0xFFFFE082), // Pastel yellow/amber
      const Color(0xFFD1C4E9), // Pastel purple
      const Color(0xFFFFB5E8), // Light pastel pink
    ];

    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    // Create the chart data
    List<ChartData> chartData = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      return ChartData(
        category,
        amount,
        colors[index % colors.length],
      );
    }).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12,right: 7,left: 7,top: 12),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 340,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: ₹point.y',
                  duration: 1500,
                ),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => double.parse(((data.amount / total) * 100).toStringAsFixed(1)),
                  dataLabelMapper: (ChartData data, _) => '${((data.amount / total) * 100).toStringAsFixed(1)}%',
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '15%',
                      ),
                      labelIntersectAction: LabelIntersectAction.shift,
                      useSeriesColor: true,
                    ),
                    radius: '75%',
                    explode: true,
                    explodeIndex: 0,
                    explodeOffset: '10%',
                    // Add animations
                    animationDuration: 1500,
                    enableTooltip: true,
                  )
                ],
                annotations: <CircularChartAnnotation>[
                  CircularChartAnnotation(
                      widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\₹${total.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ))
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDataTable(context, entries, total, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(
    BuildContext context,
    Map<String, double> data,
    String title,
  ) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return _buildEmptyChart(context, title);
    }

    final List<Color> colors = [
      const Color(0xFF6699CC), // Blue
      const Color(0xFFEE8866), // Salmon
      const Color(0xFF88BBAA), // Teal
      const Color(0xFFDDAA33), // Gold
      const Color(0xFF997799), // Purple
      const Color(0xFFFFB366), // Light orange
      const Color(0xFF44AA99), // Green
      const Color(0xFFBB5566), // Red
      const Color(0xFF9988DD), // Lavender
      const Color(0xFF55BBAA), // Aqua
    ];

    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    // Create the chart data
    List<ChartData> chartData = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      return ChartData(
        category,
        amount,
        colors[index % colors.length],
      );
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: SfCircularChart(
                title: ChartTitle(
                  text: title,
                  textStyle: theme.textTheme.titleSmall,
                ),
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: ₹point.y',
                  duration: 1500,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.amount,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '15%',
                      ),
                    ),
                    innerRadius: '60%',
                    radius: '80%',
                    explode: true,
                    // Add animations
                    animationDuration: 1500,
                    enableTooltip: true,
                  )
                ],
                annotations: <CircularChartAnnotation>[
                  CircularChartAnnotation(
                      widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\₹${total.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ))
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDataTable(context, entries, total, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      BuildContext context,
      List<MapEntry<String, double>> entries,
      double total,
      List<Color> colors) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value.key;
        final amount = entry.value.value;
        final percentage = (amount / total) * 100;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '\₹${amount.toStringAsFixed(2)}  (${percentage.toStringAsFixed(1)}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyTrendsChart(BuildContext context) {
    final theme = Theme.of(context);

    // Get real data from controller
    final List<MonthlyTrendsData> monthlyData = controller.getMonthlyTrendsData();

    if (monthlyData.isEmpty) {
      return _buildEmptyChart(context, 'Monthly Trends');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Trends',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: controller.monthlyTrendsChartKey,
              child: SizedBox(
                height: 300,
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    labelStyle: theme.textTheme.bodySmall,
                  ),
                  primaryYAxis: NumericAxis(
                    numberFormat:
                        NumberFormat.currency(symbol: '\₹', decimalDigits: 0),
                    majorGridLines: const MajorGridLines(
                        width: 0.5, dashArray: <double>[5, 5]),
                    axisLine: const AxisLine(width: 0),
                    labelStyle: theme.textTheme.bodySmall,
                  ),
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.top,
                    overflowMode: LegendItemOverflowMode.wrap,
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: true,
                    animationDuration: 1000,
                    format: 'point.x: ₹point.y',
                  ),
                  crosshairBehavior: CrosshairBehavior(
                    enable: true,
                    lineType: CrosshairLineType.both,
                    activationMode: ActivationMode.singleTap,
                    lineColor: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePinching: true,
                    enableDoubleTapZooming: true,
                    enablePanning: true,
                    zoomMode: ZoomMode.x,
                  ),
                  trackballBehavior: TrackballBehavior(
                    enable: true,
                    activationMode: ActivationMode.singleTap,
                    tooltipSettings: const InteractiveTooltip(
                      format: 'point.x: ₹point.y',
                      enable: true,
                    ),
                  ),
                  series: <CartesianSeries<MonthlyTrendsData, String>>[
                    ColumnSeries<MonthlyTrendsData, String>(
                      name: 'Income',
                      dataSource: monthlyData,
                      xValueMapper: (MonthlyTrendsData data, _) => data.month,
                      yValueMapper: (MonthlyTrendsData data, _) => data.income,
                      color: const Color(0xFF81C784), // Green for income
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      width: 0.4,
                      spacing: 0.2,
                      animationDuration: 1500,
                      enableTooltip: true,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: monthlyData.length <= 4, // Only show labels if there are few data points
                        labelAlignment: ChartDataLabelAlignment.outer,
                        textStyle: theme.textTheme.bodySmall,
                      ),
                    ),
                    ColumnSeries<MonthlyTrendsData, String>(
                      name: 'Expenses',
                      dataSource: monthlyData,
                      xValueMapper: (MonthlyTrendsData data, _) => data.month,
                      yValueMapper: (MonthlyTrendsData data, _) => data.expense,
                      color: const Color(0xFFE57373), // Red for expenses
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      width: 0.4,
                      spacing: 0.2,
                      animationDuration: 1500,
                      enableTooltip: true,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: monthlyData.length <= 4, // Only show labels if there are few data points
                        labelAlignment: ChartDataLabelAlignment.outer,
                        textStyle: theme.textTheme.bodySmall,
                      ),
                    ),
                    // Add a line series to show the net trend
                    LineSeries<MonthlyTrendsData, String>(
                      name: 'Net',
                      dataSource: monthlyData,
                      xValueMapper: (MonthlyTrendsData data, _) => data.month,
                      yValueMapper: (MonthlyTrendsData data, _) => data.income - data.expense,
                      color: theme.colorScheme.primary,
                      width: 2,
                      markerSettings: const MarkerSettings(
                        isVisible: true,
                        height: 8,
                        width: 8,
                        shape: DataMarkerType.circle,
                      ),
                      animationDuration: 2000,
                      enableTooltip: true,
                    ),
                  ],
                ),
              ),
            ),

            // Add summary stats
            if (monthlyData.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildMonthlySummary(context, monthlyData),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget to show summary of monthly trends
  Widget _buildMonthlySummary(BuildContext context, List<MonthlyTrendsData> data) {
    final theme = Theme.of(context);

    // Calculate average income and expense
    final avgIncome = data.fold(0.0, (sum, item) => sum + item.income) / data.length;
    final avgExpense = data.fold(0.0, (sum, item) => sum + item.expense) / data.length;

    // Find highest income and expense month
    final highestIncome = data.reduce((curr, next) =>
        curr.income > next.income ? curr : next);
    final highestExpense = data.reduce((curr, next) =>
        curr.expense > next.expense ? curr : next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Summary',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
          context,
          'Average Monthly Income:',
          '₹${avgIncome.toStringAsFixed(0)}',
          icon: Icons.arrow_upward,
          color: Colors.green,
        ),
        _buildSummaryRow(
          context,
          'Average Monthly Expense:',
          '₹${avgExpense.toStringAsFixed(0)}',
          icon: Icons.arrow_downward,
          color: Colors.red,
        ),
        _buildSummaryRow(
          context,
          'Highest Income Month:',
          '${highestIncome.month} (₹${highestIncome.income.toStringAsFixed(0)})',
          icon: Icons.trending_up,
          color: Colors.blue,
        ),
        _buildSummaryRow(
          context,
          'Highest Expense Month:',
          '${highestExpense.month} (₹${highestExpense.expense.toStringAsFixed(0)})',
          icon: Icons.trending_down,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    {required IconData icon, required Color color}
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Container(
      height: 190,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline,
              size: 54, color: theme.hintColor.withOpacity(0.28)),
          const SizedBox(height: 14),
          Text(
            'No Data Available',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.hintColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'No $title data found for the selected time period.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor.withOpacity(0.57),
            ),
          ),
        ],
      ),
    );
  }

  // Updated method for market data section
  Widget _buildMarketDataSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Indian Market Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Refresh button for market data
            Obx(() => controller.isLoadingMarketData.value
              ? Container(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                  onPressed: controller.refreshMarketData,
                  tooltip: 'Refresh market data',
                ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Market indices section
        _buildMarketIndicesCards(context),
        const SizedBox(height: 24),
        
        // Top gainers section
        Text(
          'Top Indian Stocks',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildTopGainersCard(context),
      ],
    );
  }

  // Widget to show market indices
  Widget _buildMarketIndicesCards(BuildContext context) {
    final theme = Theme.of(context);
    
    return Obx(() {
      if (controller.marketDataError.value.isNotEmpty) {
        return _buildErrorCard(controller.marketDataError.value, context);
      }
      
      if (controller.marketIndices.isEmpty && !controller.isLoadingMarketData.value) {
        return _buildErrorCard("No market data available", context);
      }
      
      return Container(
        height: 160, // Increased height for better display
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: controller.marketIndices.entries.map((entry) {
            final indexName = entry.key;
            final indexData = entry.value as Map<String, dynamic>;
            final isPositive = indexData['is_positive'] as bool? ?? false;
            
            // Get appropriate icon based on index name
            IconData indexIcon = Icons.show_chart;
            if (indexName.contains('Nifty')) {
              indexIcon = Icons.trending_up;
            } else if (indexName.contains('Sensex')) {
              indexIcon = Icons.bar_chart;
            } else if (indexName.contains('VIX')) {
              indexIcon = Icons.timeline;
            }
            
            return Container(
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              indexIcon,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Small Indian flag indicator
                          Container(
                            width: 20,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        indexName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        // Format based on the index value's magnitude
                        indexName.contains('VIX')
                            ? '₹${(indexData['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'
                            : '₹${_formatLargeNumber((indexData['price'] as num?) ?? 0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${(indexData['change'] as num?)?.toStringAsFixed(2) ?? '0.00'} (${(indexData['percent_change'] as num?)?.toStringAsFixed(2) ?? '0.00'}%)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
  
  // Helper method to format large numbers for better readability
  String _formatLargeNumber(num value) {
    if (value >= 100000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else if (value >= 10000) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }
  
  // Widget to show top gainers
  Widget _buildTopGainersCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Obx(() {
      if (controller.marketDataError.value.isNotEmpty) {
        return _buildErrorCard(controller.marketDataError.value, context);
      }
      
      if (controller.topGainers.isEmpty && !controller.isLoadingMarketData.value) {
        return _buildErrorCard("No top gainers data available", context);
      }
      
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.topGainers.map((stock) {
              final isPositive = stock['is_positive'] as bool? ?? true;
              // Get clean stock name (remove .NS or .BSE suffix)
              final stockSymbol = (stock['symbol'] as String? ?? '')
                  .replaceAll('.NS', '')
                  .replaceAll('.BSE', '');
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            stockSymbol,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${(stock['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up : Icons.trending_down,
                            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${(stock['percent_change'] as num?)?.toStringAsFixed(2) ?? '0.00'}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
  
  // Widget to show error messages
  Widget _buildErrorCard(String message, BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: controller.refreshMarketData,
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}

class _ModernBottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ModernBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Using your app theme colors
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final backgroundColor = isActive
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : Colors.transparent;
    final borderColor = isActive
        ? theme.colorScheme.primary.withOpacity(0.4)
        : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(
              horizontal: 2), // Small margin to prevent overflow
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                color: isActive ? activeColor : inactiveColor,
                size: 22, // Slightly smaller to prevent overflow
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Smaller font size to prevent overflow
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Prevent text overflow
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChartData {
  final String category;
  final double amount;
  final Color color;

  ChartData(this.category, this.amount, this.color);
}
