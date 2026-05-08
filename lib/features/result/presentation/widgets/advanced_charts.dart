import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/cash_flow_calculator.dart';

// ── 雷达图：多方案多维度对比 ─────────────────────────────────
class ScenarioRadarChart extends StatelessWidget {
  final List<_RadarScenarioData> scenarios;
  final double maxValue;

  const ScenarioRadarChart({
    required this.scenarios,
    this.maxValue = 100,
  });

  static const _dimensions = ['收入水平', '最终资产', '被动收入', '自由年龄', '投资回报'];
  static const chartColors = [
    AppTheme.primaryTeal,
    AppTheme.successGreen,
    AppTheme.warmGold,
    AppTheme.errorRed,
    AppTheme.accentCyan,
  ];

  @override
  Widget build(BuildContext context) {
    if (scenarios.isEmpty) return const SizedBox.shrink();

    final dataSets = scenarios.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      return RadarDataSet(
        fillColor: chartColors[i % chartColors.length].withOpacity(0.15),
        borderColor: chartColors[i % chartColors.length],
        borderWidth: 2,
        dataEntries: [
          RadarEntry(value: s.incomeLevel),
          RadarEntry(value: s.finalAssets),
          RadarEntry(value: s.passiveIncome),
          RadarEntry(value: s.freedomAge),
          RadarEntry(value: s.returnRate),
        ],
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          dataSets: dataSets,
          titlePositionPercentageOffset: 0.25,
          titleTextStyle: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          getTitle: (index, _) => RadarChartTitle(text: _dimensions[index % _dimensions.length]),
          ticksTextStyle: const TextStyle(fontSize: 9, color: AppTheme.textHint),
          radarBorderData: BorderSide(color: AppTheme.dividerColor, width: 0.5),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

/// 雷达图用的单方案数据（各维度已归一化 0-100，越高越好）
class _RadarScenarioData {
  final String name;
  final double incomeLevel;
  final double finalAssets;
  final double passiveIncome;
  final double freedomAge;  // 越高越好（取反）
  final double returnRate;

  const _RadarScenarioData({
    required this.name,
    required this.incomeLevel,
    required this.finalAssets,
    required this.passiveIncome,
    required this.freedomAge,
    required this.returnRate,
  });
}

/// 从模拟结果构造雷达图数据
List<_RadarScenarioData> buildRadarData(
  String name,
  List<YearData> years, {
  required double weightedReturnRate,
}) {
  const max = 100.0;
  final last = years.lastOrNull;
  if (last == null) return [];

  // 收入水平：基于最终被动收入估算
  final incomeLevel = (last.passiveIncome / 50000).clamp(0, 1) * max;

  // 最终资产
  final finalAssets = (last.totalAssets / 10000000).clamp(0, 1) * max;

  // 被动收入
  final passiveIncome = (last.passiveIncome / 30000).clamp(0, 1) * max;

  // 自由年龄（越低越好，取反）
  int freedomYear = years.length; // default: never
  for (int i = 0; i < years.length; i++) {
    if (years[i].passiveIncome >= years[i].totalExpense) {
      freedomYear = i;
      break;
    }
  }
  final ageInverse = years.length - freedomYear;
  final freedomAge = (ageInverse / years.length).clamp(0, 1) * max;

  // 投资回报
  final returnRate = (weightedReturnRate / 0.15).clamp(0, 1) * max;

  return [
    _RadarScenarioData(
      name: name,
      incomeLevel: incomeLevel,
      finalAssets: finalAssets,
      passiveIncome: passiveIncome,
      freedomAge: freedomAge,
      returnRate: returnRate,
    ),
  ];
}

// ── 收入堆积图：收入来源构成随时间变化 ────────────────────
class IncomeStackedChart extends StatelessWidget {
  final List<YearData> years;
  final int sampleInterval; // 每隔几年取一个数据点

  const IncomeStackedChart({
    required this.years,
    this.sampleInterval = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (years.isEmpty) return const SizedBox.shrink();

    // 采样数据
    final sampled = <YearData>[];
    for (int i = 0; i < years.length; i += sampleInterval) {
      sampled.add(years[i]);
    }
    if (sampled.last != years.last) {
      sampled.add(years.last);
    }

    final maxIncome = sampled.fold<double>(0, (s, y) => math.max(s, y.totalIncome));

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxIncome * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? '主动收入' : '被动收入';
                return BarTooltipItem(
                  '$label\n¥${NumberFormat('#,###').format(rod.toY.toInt())}',
                  const TextStyle(fontSize: 11, color: Colors.white),
                );
              },
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
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '${(value / 10000).toStringAsFixed(0)}万',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textHint),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('年龄', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sampled.length) return const SizedBox.shrink();
                  return Text(
                    '${sampled[idx].age}',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textHint),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppTheme.dividerColor,
              strokeWidth: 0.5,
            ),
          ),
          barGroups: sampled.asMap().entries.map((entry) {
            final i = entry.key;
            final y = entry.value;
            final active = y.totalIncome - y.passiveIncome;
            final passive = y.passiveIncome;

            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: active + passive,
                color: AppTheme.primaryTeal,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: active + passive,
                fromY: active,
                color: AppTheme.warmGold,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// ── 瀑布图：资产变化归因分析 ──────────────────────────────
class AssetWaterfallChart extends StatelessWidget {
  final List<YearData> years;

  const AssetWaterfallChart({required this.years});

  @override
  Widget build(BuildContext context) {
    if (years.length < 2) return const SizedBox.shrink();

    final f = NumberFormat('#,###');

    // 计算累计值
    final startAssets = years.first.totalAssets;
    final endAssets = years.last.totalAssets;

    double totalNetCashFlow = 0;
    for (int i = 0; i < years.length; i++) {
      totalNetCashFlow += years[i].netCashFlow;
    }

    // 投资回报 = endAssets - startAssets - totalNetCashFlow
    final totalReturn = endAssets - startAssets - totalNetCashFlow;

    // 构建瀑布图数据：4 个柱子
    final items = [
      _WaterfallItem('起始资产', startAssets, true, AppTheme.accentCyan),
      _WaterfallItem('净现金流贡献', totalNetCashFlow, totalNetCashFlow >= 0, AppTheme.successGreen),
      _WaterfallItem('投资回报贡献', totalReturn, totalReturn >= 0, AppTheme.primaryTeal),
      _WaterfallItem('最终资产', endAssets, true, AppTheme.warmGold),
    ];

    // 计算累计基线
    final baseValues = <double>[0, startAssets, startAssets + math.max(0, totalNetCashFlow), 0];

    final maxVal = items.fold<double>(0, (s, item) => math.max(s, item.value));

    return SizedBox(
      height: 240,
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                minY: items.any((i) => i.value < 0) ? maxVal * -0.2 : 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = items[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.label}\n¥${f.format(item.value.toInt())}',
                        const TextStyle(fontSize: 11, color: Colors.white),
                      );
                    },
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
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${(value / 10000).toStringAsFixed(0)}万',
                          style: const TextStyle(fontSize: 9, color: AppTheme.textHint),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                        return Text(
                          items[idx].label,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.dividerColor,
                    strokeWidth: 0.5,
                  ),
                ),
                barGroups: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final base = baseValues[i];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: base + item.value,
                      fromY: base,
                      color: item.color,
                      width: 28,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(item.value >= 0 ? 4 : 0),
                        bottom: Radius.circular(item.value < 0 ? 4 : 0),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
            ),
          ),
          const SizedBox(height: 8),
          // 图例
          Wrap(
            spacing: 16,
            children: [
              _legendItem('起始/最终', AppTheme.accentCyan),
              _legendItem('净现金流', AppTheme.successGreen),
              _legendItem('投资回报', AppTheme.primaryTeal),
              _legendItem('最终资产', AppTheme.warmGold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _WaterfallItem {
  final String label;
  final double value;
  final bool isPositive;
  final Color color;
  const _WaterfallItem(this.label, this.value, this.isPositive, this.color);
}

// ── 热力图：储蓄率×回报率敏感度 ──────────────────────────
class SensitivityHeatmap extends StatelessWidget {
  final double baseSavingsRate;
  final double baseReturnRate;

  const SensitivityHeatmap({
    required this.baseSavingsRate,
    required this.baseReturnRate,
  });

  @override
  Widget build(BuildContext context) {
    // 生成 5×5 网格：储蓄率 0.5x / 0.75x / 1x / 1.25x / 1.5x
    // 回报率 -2% / -1% / 基准 / +1% / +2%
    final savingsFactors = [0.5, 0.75, 1.0, 1.25, 1.5];
    final returnDeltas = [-0.02, -0.01, 0.0, 0.01, 0.02];

    // 简化模型：最终资产 ≈ 启动资金×(1+r)^n + 年储蓄×((1+r)^n-1)/r
    // 这里直接用相对值
    final baseResult = _simplifiedModel(baseSavingsRate, baseReturnRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('颜色越深 = 最终资产越高',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              // 表头：回报率
              Row(
                children: [
                  const SizedBox(width: 44),
                  ...returnDeltas.map((d) => Expanded(
                        child: Text(
                          '${d >= 0 ? '+' : ''}${(d * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 4),
              // 数据行
              ...savingsFactors.asMap().entries.map((entry) {
                final sf = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(sf * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ),
                      ...returnDeltas.map((rd) {
                        final result = _simplifiedModel(baseSavingsRate * sf, baseReturnRate + rd);
                        final ratio = baseResult > 0 ? result / baseResult : 1.0;
                        final intensity = (ratio - 0.5).clamp(0.0, 1.5) / 1.5;
                        return Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                Colors.red.shade100,
                                Colors.green.shade400,
                                intensity,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                result >= 10000
                                    ? '${(result / 10000).toStringAsFixed(0)}万'
                                    : result.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: intensity > 0.6 ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _heatLegend('低', Colors.red.shade100),
            Container(width: 60, height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade100, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.circular(4),
                )),
            _heatLegend('高', Colors.green.shade400),
          ],
        ),
      ],
    );
  }

  Widget _heatLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
    );
  }
}

/// 简化财务模型估算最终资产
/// 年储蓄 = 收入×储蓄率, 持续 n 年复利
double _simplifiedModel(double savingsRate, double annualReturn) {
  // 假设：月收入 15000，工作 30 年
  const monthlyIncome = 15000.0;
  const workingYears = 30;
  final annualSavings = monthlyIncome * 12 * savingsRate;
  if (annualReturn == 0) return annualSavings * workingYears;
  return annualSavings * ((math.pow(1 + annualReturn, workingYears) - 1) / annualReturn);
}
