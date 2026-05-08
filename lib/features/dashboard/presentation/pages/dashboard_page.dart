import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../income_expense/data/models/income_model.dart';
import '../../../income_expense/providers/income_expense_provider.dart';
import '../../../assets/providers/asset_provider.dart';
import '../../../profile/providers/profile_provider.dart';

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final incomes = ref.watch(incomeListProvider);
  final expenses = ref.watch(expenseListProvider);
  final assets = ref.watch(assetListProvider);
  final profile = ref.watch(profileProvider);

  final totalAssets = assets.fold<double>(0, (sum, a) => sum + a.currentValue);
  final passiveMonthlyIncome = incomes
      .where((i) => i.type == IncomeType.passive)
      .fold<double>(0, (sum, i) => sum + i.monthlyAmount);
  final activeMonthlyIncome = incomes
      .where((i) => i.type == IncomeType.active)
      .fold<double>(0, (sum, i) => sum + i.monthlyAmount);
  final totalMonthlyExpense =
      expenses.fold<double>(0, (sum, e) => sum + e.monthlyAmount);
  final monthlyNetCashFlow =
      (activeMonthlyIncome + passiveMonthlyIncome) - totalMonthlyExpense;

  return DashboardSummary(
    totalAssets: totalAssets,
    passiveMonthlyIncome: passiveMonthlyIncome,
    activeMonthlyIncome: activeMonthlyIncome,
    totalMonthlyExpense: totalMonthlyExpense,
    monthlyNetCashFlow: monthlyNetCashFlow,
    yearsToRetirement: profile.yearsToRetirement,
    retirementAge: profile.retirementAge,
    isProfileConfigured: profile.isConfigured,
  );
});

class DashboardSummary {
  final double totalAssets;
  final double passiveMonthlyIncome;
  final double activeMonthlyIncome;
  final double totalMonthlyExpense;
  final double monthlyNetCashFlow;
  final int yearsToRetirement;
  final int retirementAge;
  final bool isProfileConfigured;

  const DashboardSummary({
    required this.totalAssets,
    required this.passiveMonthlyIncome,
    required this.activeMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.monthlyNetCashFlow,
    required this.yearsToRetirement,
    required this.retirementAge,
    required this.isProfileConfigured,
  });
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final f = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('财务自由希望'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardSummaryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 总资产卡片 ──────────────────────────────────
            _SummaryCard(
              icon: Icons.account_balance_wallet,
              iconColor: AppTheme.primaryTeal,
              title: '总资产',
              value: '¥${f.format(summary.totalAssets.toInt())}',
              subtitle: '含 ${summary.totalAssets > 0 ? '资产增值' : '暂无数据'}',
              onTap: () => context.go('/assets'),
            ),
            const Gap(12),
            // ── 被动收入卡片 ────────────────────────────────
            _SummaryCard(
              icon: Icons.vertical_distribute,
              iconColor: AppTheme.accentCyan,
              title: '被动月收入',
              value: '¥${f.format(summary.passiveMonthlyIncome.toInt())}/月',
              subtitle: '主动收入 ¥${f.format(summary.activeMonthlyIncome.toInt())}/月',
            ),
            const Gap(12),
            // ── 月净现金流卡片 ──────────────────────────────
            _SummaryCard(
              icon: Icons.trending_up,
              iconColor: summary.monthlyNetCashFlow >= 0
                  ? AppTheme.successGreen
                  : AppTheme.errorRed,
              title: '月净现金流',
              value: '¥${f.format(summary.monthlyNetCashFlow.toInt())}/月',
              subtitle: '支出 ¥${f.format(summary.totalMonthlyExpense.toInt())}/月',
            ),
            const Gap(12),
            // ── 预计自由时间卡片 ────────────────────────────
            _SummaryCard(
              icon: Icons.celebration,
              iconColor: AppTheme.warmGold,
              title: '距离退休',
              value: summary.isProfileConfigured
                  ? '${summary.yearsToRetirement} 年'
                  : '请先设置个人信息',
              subtitle: summary.isProfileConfigured
                  ? '目标退休年龄 ${summary.retirementAge} 岁'
                  : '前往「我的」页面设置年龄',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
      );
  }
}