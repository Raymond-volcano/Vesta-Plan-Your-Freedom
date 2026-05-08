import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/cash_flow_calculator.dart';
import '../../providers/result_provider.dart';

class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(simulationResultProvider);
    final simulateUnemployment = ref.watch(simulateUnemploymentProvider);
    final f = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('模拟结果'),
        actions: [
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
                SizedBox(
                  height: 300,
                  child: _AssetChart(results: results),
                ),
                const Gap(24),
                // ── 详细数据表格 ────────────────────────────
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
    );
  }

  Widget _buildSummaryCards(List<YearData> results, NumberFormat f) {
    final lastYear = results.last;
    final firstPositiveIndex = results.indexWhere((r) => r.totalAssets >= 0);
    final freedomYear = firstPositiveIndex >= 0
        ? results[firstPositiveIndex].year
        : null;

    // 找到被动收入超过支出的年份
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
                title: '${results.last.age}岁时总资产',
                value: '¥${f.format(lastYear.totalAssets.toInt())}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                icon: Icons.person_off,
                color: AppTheme.warmGold,
                title: '可自由生活年份',
                value: freedomYear?.toString() ?? '无法实现',
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
                  minY: minAsset * 1.1,
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
