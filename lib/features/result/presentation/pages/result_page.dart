import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/assets/providers/asset_provider.dart';
import '../../../../features/assets/data/models/asset_model.dart';
import '../../../../features/income_expense/providers/income_expense_provider.dart';
import '../../../../features/profile/providers/profile_provider.dart';
import '../../domain/services/cash_flow_calculator.dart';
import '../../providers/result_provider.dart';
import '../../services/export_service.dart';
import '../widgets/advanced_charts.dart';
import '../widgets/deep_insight.dart';

class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(simulationResultProvider);
    final simulateUnemployment = ref.watch(simulateUnemploymentProvider);
    final assets = ref.watch(assetListProvider);
    final incomes = ref.watch(incomeListProvider);
    final expenses = ref.watch(expenseListProvider);
    final sensitivity = ref.watch(sensitivityProvider);
    final f = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('模拟结果'),
        actions: [
          // 导出报告
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出 PDF 报告',
            onPressed: results.isEmpty
                ? null
                : () => _exportReport(context, ref),
          ),
          // 模拟失业开关
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('模拟失业', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              Switch(
                value: simulateUnemployment,
                activeColor: AppTheme.warmGold,
                onChanged: (v) {
                  ref.read(simulateUnemploymentProvider.notifier).state = v;
                },
              ),
            ],
          ),
        ],
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    '请先在「我的」页面设置年龄',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '并添加收支和资产数据',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 关键数据摘要 ────────────────────────────
                _buildSummaryCards(results, f),
                const Gap(24),
                // ── 图表 ──────────────────────────────────────
                const Text(
                  '总资产走势',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: SizedBox(
                    height: 300,
                    child: _AssetChart(results: results),
                  ),
                ),
                const Gap(24),
                // ── 被动收入 vs 总支出 ──────────────────────
                const Text(
                  '被动收入 vs 总支出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: _PassiveVsExpenseChart(results: results),
                ),
                const Gap(24),
                // ── 资产构成 ──────────────────────────────────
                const Text(
                  '资产构成',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: _AssetPieChart(assets: assets),
                ),
                const Gap(24),
                // ── 制约因素分析 ──────────────────────────────
                const Text(
                  '制约因素分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: _SensitivityChart(items: sensitivity),
                ),
                const SizedBox(height: 12),
                _SensitivityInsight(items: sensitivity),
                const Gap(24),
                // ── Pro 高级图表 ────────────────────────────────────
                _ProAdvancedCharts(results: results, sensitivity: sensitivity),
                const Gap(24),
                // ── 深度个性化报告 ──────────────────────────────────
                _ProDeepInsight(
                  simulation: results,
                  sensitivity: sensitivity,
                  totalMonthlyIncome: incomes.fold<double>(0, (s, i) => s + i.monthlyAmount),
                  totalMonthlyExpense: expenses.fold<double>(0, (s, e) => s + e.monthlyAmount),
                ),
                const Gap(24),
                // ── 详细数据表格 ────────────────────────────
                RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '逐年数据',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...results.map((yearData) => _buildYearRow(yearData, f)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
    final incomes = ref.read(incomeListProvider);
    final expenses = ref.read(expenseListProvider);
    final assets = ref.read(assetListProvider);
    final profile = ref.read(profileProvider);
    final results = ref.read(simulationResultProvider);
    final sensitivity = ref.read(sensitivityProvider);
    final simulateUnemployment = ref.read(simulateUnemploymentProvider);

    if (results.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ExportService.exportReport(
        profile: profile,
        incomes: incomes,
        expenses: expenses,
        assets: assets,
        simulation: results,
        sensitivity: sensitivity,
        simulateUnemployment: simulateUnemployment,
      );
      if (context.mounted) {
        Navigator.of(context).pop(); // 关掉 loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告已生成并分享')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  Widget _buildSummaryCards(List<YearData> results, NumberFormat f) {
    final lastYear = results.last;
    const maxAge = 80;
    final achievedFreedom = lastYear.age >= maxAge;

    // 资产耗尽年份（如果模拟提前终止）
    int? depletionIndex;
    for (int i = 1; i < results.length; i++) {
      if (results[i].totalAssets < 0) {
        depletionIndex = i;
        break;
      }
    }
    final depletionAge = depletionIndex != null ? results[depletionIndex].age : null;

    // 被动收入超过支出的年份
    int? freedomViaPassive;
    for (final r in results) {
      if (r.passiveIncome >= r.totalExpense) {
        freedomViaPassive = r.year;
        break;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                icon: Icons.flag,
                color: AppTheme.primaryTeal,
                title: '${lastYear.age}岁时总资产',
                value: '¥${f.format(lastYear.totalAssets.toInt())}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                icon: achievedFreedom ? Icons.celebration : Icons.warning_amber,
                color: achievedFreedom ? AppTheme.successGreen : AppTheme.warmGold,
                title: achievedFreedom ? '财务自由可达' : '资产耗尽年龄',
                value: achievedFreedom ? '是 ✓' : '${depletionAge ?? lastYear.age} 岁',
              ),
            ),
          ],
        ),
        if (freedomViaPassive != null) ...[
          const SizedBox(height: 12),
          _MiniCard(
            icon: Icons.volunteer_activism,
            color: AppTheme.successGreen,
            title: '被动收入覆盖支出年份',
            value: freedomViaPassive.toString(),
            wide: true,
          ),
        ],
      ],
    );
  }

  Widget _buildYearRow(YearData data, NumberFormat f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.year}年',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    '${data.age}岁',
                    style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                '¥${f.format(data.totalAssets.toInt())}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: data.totalAssets >= 0 ? AppTheme.primaryTeal : AppTheme.errorRed,
                ),
              ),
            ),
            Text(
              '${data.netCashFlow >= 0 ? '+' : ''}¥${f.format(data.netCashFlow.toInt())}',
              style: TextStyle(
                fontSize: 13,
                color: data.netCashFlow >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final bool wide;

  const _MiniCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(wide ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: wide ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── fl_chart 折线图 ────────────────────────────────────────────
class _AssetChart extends StatelessWidget {
  final List<YearData> results;
  const _AssetChart({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox();

    final maxAsset = results.fold<double>(
      0,
      (max, r) => r.totalAssets > max ? r.totalAssets : max,
    );
    final minAsset = results.fold<double>(
      0,
      (min, r) => r.totalAssets < min ? r.totalAssets : min,
    );
    final assetRange = (maxAsset - minAsset).clamp(1, double.infinity);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: assetRange / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.dividerColor,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('年份',
                          style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _calcInterval(results.length),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= results.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${results[index].year}',
                              style: const TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('资产 (¥)',
                          style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('¥0',
                              style: TextStyle(color: AppTheme.textHint, fontSize: 10));
                          final v = value.toInt();
                          if (v >= 10000) {
                            return Text('${(v ~/ 10000)}万',
                                style: const TextStyle(color: AppTheme.textHint, fontSize: 10));
                          }
                          return Text('$v',
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (results.length - 1).toDouble(),
                  minY: (minAsset * 0.9).clamp(0, double.infinity),
                  maxY: maxAsset * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: results.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.totalAssets);
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryTeal,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.spotIndex;
                          final data = results[index];
                          return LineTooltipItem(
                            '${data.year}年 (${data.age}岁)\n'
                            '资产: ¥${NumberFormat('#,###').format(data.totalAssets.toInt())}\n'
                            '净现金流: ${data.netCashFlow >= 0 ? '+' : ''}¥${NumberFormat('#,###').format(data.netCashFlow.toInt())}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calcInterval(int count) {
    if (count <= 10) return 1;
    if (count <= 20) return 2;
    if (count <= 40) return 5;
    return 10;
  }
}

// ── 被动收入 vs 总支出折线图 ────────────────────────────────────
class _PassiveVsExpenseChart extends StatelessWidget {
  final List<YearData> results;
  const _PassiveVsExpenseChart({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox();

    final maxExpense = results.fold<double>(0, (m, r) => r.totalExpense > m ? r.totalExpense : m);
    final maxPassive = results.fold<double>(0, (m, r) => r.passiveIncome > m ? r.passiveIncome : m);
    final overallMax = (maxExpense > maxPassive ? maxExpense : maxPassive) * 1.1;
    final range = overallMax.clamp(1, double.infinity);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: range / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.dividerColor,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('年份',
                          style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _calcInterval(results.length),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= results.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${results[index].year}',
                                style: const TextStyle(color: AppTheme.textHint, fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('金额 (¥)',
                          style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('¥0',
                              style: TextStyle(color: AppTheme.textHint, fontSize: 10));
                          final v = value.toInt();
                          if (v >= 10000) return Text('${(v ~/ 10000)}万',
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10));
                          return Text('$v',
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (results.length - 1).toDouble(),
                  minY: 0,
                  maxY: overallMax,
                  lineBarsData: [
                    LineChartBarData(
                      spots: results.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.passiveIncome))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.successGreen,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      dashArray: [6, 3],
                    ),
                    LineChartBarData(
                      spots: results.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.totalExpense))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.errorRed,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.spotIndex;
                          final data = results[index];
                          final isPassive = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${data.year}年 (${data.age}岁)\n'
                            '${isPassive ? "被动收入" : "总支出"}: '
                            '¥${NumberFormat("#,###").format((isPassive ? data.passiveIncome : data.totalExpense).toInt())}',
                            TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: isPassive ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 图例
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppTheme.successGreen, '被动收入 (虚线)'),
                const SizedBox(width: 20),
                _legendDot(AppTheme.errorRed, '总支出'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calcInterval(int count) {
    if (count <= 10) return 1;
    if (count <= 20) return 2;
    if (count <= 40) return 5;
    return 10;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ── 资产构成饼图 ────────────────────────────────────────────────
class _AssetPieChart extends StatelessWidget {
  final List<AssetModel> assets;
  const _AssetPieChart({required this.assets});

  static const _pieColors = [
    AppTheme.primaryTeal,
    AppTheme.warmGold,
    AppTheme.successGreen,
    AppTheme.accentCyan,
    AppTheme.primaryLight,
    AppTheme.primaryDark,
    Colors.orange,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text('暂无资产数据',
                style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: assets.asMap().entries.map((e) {
                    final i = e.key;
                    final asset = e.value;
                    return PieChartSectionData(
                      color: _pieColors[i % _pieColors.length],
                      value: asset.currentValue.clamp(1, double.infinity),
                      title: '${asset.name}\n¥${NumberFormat("#,###").format(asset.currentValue.toInt())}',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      radius: 80,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 图例
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: assets.asMap().entries.map((e) {
                final i = e.key;
                final asset = e.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _pieColors[i % _pieColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${asset.name} (¥${NumberFormat("#,###").format(asset.currentValue.toInt())})',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 制约因素分析柱状图 ──────────────────────────────────────────
class _SensitivityChart extends StatelessWidget {
  final List<SensitivityItem> items;
  const _SensitivityChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text('请先添加收支和资产数据',
                style: TextStyle(color: AppTheme.textHint, fontSize: 14)),
          ),
        ),
      );
    }

    final maxAbs = items.fold<double>(0, (m, i) => i.impactPercent.abs() > m ? i.impactPercent.abs() : m);
    final axisMax = (maxAbs * 1.3).clamp(1, double.infinity).toDouble();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: items.length * 54.0 + 30,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = items[groupIndex];
                        final sign = item.impactPercent >= 0 ? '+' : '';
                        return BarTooltipItem(
                          '${item.label}: ${sign}${item.impactPercent.toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('影响 (%)',
                          style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: ((axisMax / 3).clamp(1, double.infinity)).toDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10));
                          return Text('${value.toInt()}%',
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: -axisMax,
                  maxY: axisMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: false,
                    getDrawingVerticalLine: (value) {
                      if (value == 0) {
                        return FlLine(color: AppTheme.textSecondary, strokeWidth: 1);
                      }
                      return FlLine(color: AppTheme.dividerColor, strokeWidth: 0.5);
                    },
                  ),
                  barGroups: items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (item.impactPercent.clamp(-axisMax, axisMax)).toDouble(),
                          width: 28,
                          color: item.impactPercent >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 标签列
            ...items.asMap().entries.map((e) {
              final item = e.value;
              final sign = item.impactPercent >= 0 ? '+' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.impactPercent >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.label}: ${sign}${item.impactPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: item.impactPercent >= 0 ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── 分析说明卡片 ──────────────────────────────────────────────
class _SensitivityInsight extends StatelessWidget {
  final List<SensitivityItem> items;
  const _SensitivityInsight({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // 最佳机会（正向影响最大）
    SensitivityItem? best;
    for (final i in items) {
      if (i.impactPercent > 0 && (best == null || i.impactPercent > best.impactPercent)) {
        best = i;
      }
    }
    // 最大风险（负向影响最大）
    SensitivityItem? worst;
    for (final i in items) {
      if (i.impactPercent < 0 && (worst == null || i.impactPercent < worst.impactPercent)) {
        worst = i;
      }
    }

    final sentences = <String>[];

    if (best != null) {
      final abs = best.impactPercent.abs();
      if (abs >= 50) {
        sentences.add('「${best.label}」对你的财富影响巨大，提升${best.label}是加速实现目标最有效的方式。');
      } else if (abs >= 20) {
        sentences.add('「${best.label}」对你的财务状况有明显帮助，重点提升这个方面能让你更快达成目标。');
      } else {
        sentences.add('「${best.label}」对你的财富有积极影响，可以持续关注。');
      }
    }

    if (worst != null) {
      final abs = worst.impactPercent.abs();
      if (abs >= 50) {
        sentences.add('「${worst.label}」是最大的财务风险，它会严重侵蚀你的资产。建议严控这方面的支出，留足应急资金。');
      } else if (abs >= 20) {
        sentences.add('「${worst.label}」是需要警惕的风险因素，建议提前做好应对准备。');
      } else {
        sentences.add('「${worst.label}」的影响相对可控，但也要留意。');
      }
    }

    if (sentences.isEmpty) {
      sentences.add('各因素对你的财务目标影响相对均衡。继续保持当前计划，同时关注收支变化即可。');
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.warmGold),
                const SizedBox(width: 6),
                const Text(
                  '分析建议',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final sentence in sentences)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  sentence,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pro 高级图表区域 ─────────────────────────────────────────
class _ProAdvancedCharts extends ConsumerWidget {
  final List<YearData> results;
  final List<SensitivityItem> sensitivity;

  const _ProAdvancedCharts({required this.results, required this.sensitivity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bar_chart, size: 18, color: AppTheme.warmGold),
            SizedBox(width: 8),
            Text('高级图表',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: '收入构成变化',
          subtitle: '主动收入 vs 被动收入随时间变化',
          child: IncomeStackedChart(years: results),
        ),
        const Gap(12),
        _ChartCard(
          title: '资产变化归因',
          subtitle: '起始资产 → 净现金流 → 投资回报 → 最终资产',
          child: AssetWaterfallChart(years: results),
        ),
        const Gap(12),
        _ChartCard(
          title: '储蓄率 × 回报率敏感度',
          subtitle: '不同储蓄率和投资回报率下的最终资产',
          child: SensitivityHeatmap(
            baseSavingsRate: 0.3,
            baseReturnRate: 0.05,
          ),
        ),
      ],
    );
  }
}

// ── 深度个性化报告（Pro） ─────────────────────────────────
class _ProDeepInsight extends ConsumerWidget {
  final List<YearData> simulation;
  final List<SensitivityItem> sensitivity;
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;

  const _ProDeepInsight({
    required this.simulation,
    required this.sensitivity,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.assessment, size: 18, color: AppTheme.warmGold),
            SizedBox(width: 8),
            Text('深度分析报告',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        DeepInsight(
          profile: profile,
          simulation: simulation,
          sensitivity: sensitivity,
          totalMonthlyIncome: totalMonthlyIncome,
          totalMonthlyExpense: totalMonthlyExpense,
        ),
      ],
    );
  }
}

// ── 图表卡片包装 ──────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
