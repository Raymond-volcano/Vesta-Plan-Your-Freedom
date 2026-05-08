import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/result/domain/services/cash_flow_calculator.dart';
import '../../../../features/result/presentation/widgets/advanced_charts.dart';
import '../../data/models/scenario_model.dart';
import '../../providers/scenario_provider.dart';

/// 方案对比页面 — 叠加显示多个方案的模拟结果
class ScenarioComparePage extends ConsumerWidget {
  const ScenarioComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(scenarioListProvider);
    if (scenarios.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('方案对比')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('至少需要 2 个方案才能对比',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    // 为每个方案运行模拟
    final results = scenarios.map((s) {
      final data = s;
      final years = CashFlowCalculator.simulate(
        profile: data.profile,
        incomes: data.incomes,
        expenses: data.expenses,
        assets: data.assets,
        simulateUnemployment: false,
      );
      return _ScenarioResult(scenario: s, years: years);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('方案对比')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('资产走势对比',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _CompareLineChart(results: results),
          ),
          const Gap(24),
          const Text('关键指标对比',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _CompareTable(results: results),
          const Gap(24),
          const Text('综合能力对比',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('收入水平、最终资产、被动收入、自由年龄、投资回报五个维度',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          _RadarCompare(results: results),
        ],
      ),
    );
  }
}

// ── 内部数据模型 ────────────────────────────────────────────
class _ScenarioResult {
  final ScenarioModel scenario;
  final List<YearData> years;
  const _ScenarioResult({required this.scenario, required this.years});
}

// ── 对比折线图 ──────────────────────────────────────────────
class _CompareLineChart extends StatelessWidget {
  final List<_ScenarioResult> results;
  const _CompareLineChart({required this.results});

  static const _lineColors = [
    AppTheme.primaryTeal,
    AppTheme.successGreen,
    AppTheme.warmGold,
    AppTheme.errorRed,
    AppTheme.accentCyan,
  ];

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    // 计算全局最大值用于 Y 轴缩放
    double maxAssets = 0;
    double minAssets = 0;
    for (final r in results) {
      for (final y in r.years) {
        if (y.totalAssets > maxAssets) maxAssets = y.totalAssets;
        if (y.totalAssets < minAssets) minAssets = y.totalAssets;
      }
    }
    final yMax = maxAssets * 1.2;
    final yMin = minAssets * 1.2;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
        child: Column(
          children: [
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: results.first.years.length.toDouble() - 1,
                  minY: yMin < 0 ? yMin : 0,
                  maxY: yMax > 0 ? yMax : 1,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => const FlLine(
                      color: AppTheme.dividerColor,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return const Text('0',
                                style: TextStyle(color: AppTheme.textHint, fontSize: 9));
                          }
                          return Text(_formatY(value),
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 9));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('年龄',
                          style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= results.first.years.length) {
                            return const SizedBox.shrink();
                          }
                          return Text('${results.first.years[idx].age}',
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 9));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: results.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return LineChartBarData(
                      spots: r.years.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.totalAssets);
                      }).toList(),
                      color: _lineColors[i % _lineColors.length],
                      barWidth: 2,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 图例
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: results.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _lineColors[i % _lineColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(r.scenario.name,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatY(double value) {
    if (value.abs() >= 10000) {
      return '${(value / 10000).toStringAsFixed(0)}万';
    }
    return value.toStringAsFixed(0);
  }
}

// ── 对比表格 ────────────────────────────────────────────────
class _CompareTable extends StatelessWidget {
  final List<_ScenarioResult> results;
  const _CompareTable({required this.results});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat('#,###');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 表头
            Row(
              children: [
                const SizedBox(width: 80),
                ...results.map((r) {
                  final label = ScenarioLabel.fromJson(r.scenario.label);
                  return Expanded(
                    child: Text(
                      r.scenario.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _labelColor(label),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const Divider(height: 24),
            // 指标行
            _metricRow('80岁总资产', results, (r) {
              final last = r.years.lastOrNull;
              return last != null ? '¥${f.format(last.totalAssets.toInt())}' : '-';
            }),
            _metricRow('最终月被动收入', results, (r) {
              final last = r.years.lastOrNull;
              return last != null ? '¥${f.format(last.passiveIncome.toInt())}' : '-';
            }),
            _metricRow('月净现金流', results, (r) {
              final last = r.years.lastOrNull;
              return last != null
                  ? '¥${f.format(last.netCashFlow.toInt())}'
                  : '-';
            }),
            _metricRow('资产耗尽年龄', results, (r) {
              for (int i = 0; i < r.years.length; i++) {
                if (r.years[i].totalAssets < 0) {
                  return '${r.years[i].age} 岁';
                }
              }
              return '未耗尽';
            }),
            _metricRow('财务自由年龄', results, (r) {
              for (final y in r.years) {
                if (y.passiveIncome >= y.totalExpense) {
                  return '${y.age} 岁';
                }
              }
              return '未达成';
            }),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, List<_ScenarioResult> results, String Function(_ScenarioResult) getValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ),
          ...results.map((r) => Expanded(
                child: Text(
                  getValue(r),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              )),
        ],
      ),
    );
  }

  Color _labelColor(ScenarioLabel label) {
    switch (label) {
      case ScenarioLabel.baseline: return AppTheme.primaryTeal;
      case ScenarioLabel.optimistic: return AppTheme.successGreen;
      case ScenarioLabel.conservative: return AppTheme.warmGold;
      case ScenarioLabel.extreme: return AppTheme.errorRed;
      case ScenarioLabel.custom: return AppTheme.accentCyan;
    }
  }
}

// ── 雷达对比图 ──────────────────────────────────────────────
class _RadarCompare extends StatelessWidget {
  final List<_ScenarioResult> results;
  const _RadarCompare({required this.results});

  @override
  Widget build(BuildContext context) {
    // 构建雷达图数据
    final allRadarData = results.map((r) {
      final last = r.years.lastOrNull;
      if (last == null) return null;

      double totalReturnRate = 0.05;
      final assets = r.scenario.assets;
      if (assets.isNotEmpty) {
        totalReturnRate =
            assets.fold<double>(0, (s, a) => s + a.annualReturnRate) / assets.length;
      }

      return buildRadarData(
        r.scenario.name,
        r.years,
        weightedReturnRate: totalReturnRate,
      );
    }).whereNotNull().expand((list) => list).toList();

    if (allRadarData.length < 2) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: ScenarioRadarChart(scenarios: allRadarData),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: results.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: ScenarioRadarChart.chartColors[i % ScenarioRadarChart.chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(r.scenario.name,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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

extension _IterableExtensions<T> on Iterable<T?> {
  Iterable<T> whereNotNull() => where((e) => e != null).cast<T>();
}
