import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/income_expense/providers/income_expense_provider.dart';
import '../../../../features/income_expense/data/models/income_model.dart';
import '../../../../features/income_expense/data/models/expense_model.dart';
import '../../../../features/assets/providers/asset_provider.dart';
import '../../../../features/assets/data/models/asset_model.dart';
import '../../../../features/profile/providers/profile_provider.dart';
import '../../../../features/profile/data/models/user_profile_model.dart';
import '../domain/services/cash_flow_calculator.dart';

final simulateUnemploymentProvider = StateProvider<bool>((ref) => false);

final simulationResultProvider = Provider<List<YearData>>((ref) {
  final profile = ref.watch(profileProvider);
  final incomes = ref.watch(incomeListProvider);
  final expenses = ref.watch(expenseListProvider);
  final assets = ref.watch(assetListProvider);
  final simulateUnemployment = ref.watch(simulateUnemploymentProvider);

  if (!profile.isConfigured) return [];

  return CashFlowCalculator.simulate(
    profile: profile,
    incomes: incomes,
    expenses: expenses,
    assets: assets,
    simulateUnemployment: simulateUnemployment,
  );
});

// ── Sensitivity Analysis ──────────────────────────────────────

class SensitivityItem {
  final String label;
  final double impactPercent; // positive = beneficial, negative = harmful
  const SensitivityItem({required this.label, required this.impactPercent});
}

final sensitivityProvider = Provider<List<SensitivityItem>>((ref) {
  final profile = ref.watch(profileProvider);
  final incomes = ref.watch(incomeListProvider);
  final expenses = ref.watch(expenseListProvider);
  final assets = ref.watch(assetListProvider);
  final simulateUnemployment = ref.watch(simulateUnemploymentProvider);

  if (!profile.isConfigured) return [];

  // Baseline simulation
  final baseline = CashFlowCalculator.simulate(
    profile: profile,
    incomes: incomes,
    expenses: expenses,
    assets: assets,
    simulateUnemployment: simulateUnemployment,
  );
  if (baseline.isEmpty) return [];
  final baselineFinal = baseline.last.totalAssets;
  if (baselineFinal == 0) return [];

  double simulateRun({
    List<IncomeModel>? overrideIncomes,
    List<ExpenseModel>? overrideExpenses,
    List<AssetModel>? overrideAssets,
    UserProfileModel? overrideProfile,
  }) {
    final result = CashFlowCalculator.simulate(
      profile: overrideProfile ?? profile,
      incomes: overrideIncomes ?? incomes,
      expenses: overrideExpenses ?? expenses,
      assets: overrideAssets ?? assets,
      simulateUnemployment: simulateUnemployment,
    );
    return result.isNotEmpty ? result.last.totalAssets : baselineFinal;
  }

  final impact = <SensitivityItem>[];

  // 月支出 +10%
  final expUp = simulateRun(
    overrideExpenses: expenses.map((e) => e.copyWith(monthlyAmount: e.monthlyAmount * 1.1)).toList(),
  );
  impact.add(SensitivityItem(
    label: '每月开销',
    impactPercent: (expUp - baselineFinal) / baselineFinal.abs() * 100,
  ));

  // 主动收入 +10%
  if (incomes.any((i) => i.type == IncomeType.active)) {
    final incUp = simulateRun(
      overrideIncomes: incomes.map((i) =>
          i.type == IncomeType.active ? i.copyWith(monthlyAmount: i.monthlyAmount * 1.1) : i).toList(),
    );
    impact.add(SensitivityItem(
      label: '工资收入',
      impactPercent: (incUp - baselineFinal) / baselineFinal.abs() * 100,
    ));
  }

  // 被动收入 +10%
  if (incomes.any((i) => i.type == IncomeType.passive)) {
    final passUp = simulateRun(
      overrideIncomes: incomes.map((i) =>
          i.type == IncomeType.passive ? i.copyWith(monthlyAmount: i.monthlyAmount * 1.1) : i).toList(),
    );
    impact.add(SensitivityItem(
      label: '理财收入',
      impactPercent: (passUp - baselineFinal) / baselineFinal.abs() * 100,
    ));
  }

  // 总资产 +10%
  if (assets.isNotEmpty) {
    final astUp = simulateRun(
      overrideAssets: assets.map((a) => a.copyWith(currentValue: a.currentValue * 1.1)).toList(),
    );
    impact.add(SensitivityItem(
      label: '启动本金',
      impactPercent: (astUp - baselineFinal) / baselineFinal.abs() * 100,
    ));
  }

  // 收益率 +1% (绝对值)
  if (assets.isNotEmpty) {
    final rateUp = simulateRun(
      overrideAssets: assets.map((a) => a.copyWith(annualReturnRate: a.annualReturnRate + 0.01)).toList(),
    );
    impact.add(SensitivityItem(
      label: '投资回报',
      impactPercent: (rateUp - baselineFinal) / baselineFinal.abs() * 100,
    ));
  }

  // 通胀率 +1% (绝对值)
  final inflUp = simulateRun(
    overrideProfile: profile.copyWith(annualInflationRate: profile.annualInflationRate + 0.01),
  );
  impact.add(SensitivityItem(
    label: '物价上涨',
    impactPercent: (inflUp - baselineFinal) / baselineFinal.abs() * 100,
  ));

  // 按绝对影响排序（最大的在前面）
  impact.sort((a, b) => b.impactPercent.abs().compareTo(a.impactPercent.abs()));

  return impact;
});
