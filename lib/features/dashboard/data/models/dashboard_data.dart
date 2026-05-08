import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../income_expense/data/models/income_model.dart';
import '../../../income_expense/providers/income_expense_provider.dart';
import '../../../assets/providers/asset_provider.dart';

class DashboardData {
  final double totalAssets;
  final double totalPassiveMonthlyIncome;
  final double totalMonthlyExpense;
  final double monthlyNetCashFlow;

  const DashboardData({
    required this.totalAssets,
    required this.totalPassiveMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.monthlyNetCashFlow,
  });
}

final dashboardDataProvider = Provider<DashboardData>((ref) {
  final incomes = ref.watch(incomeListProvider);
  final expenses = ref.watch(expenseListProvider);
  final assets = ref.watch(assetListProvider);

  final totalAssets = assets.fold<double>(0, (sum, a) => sum + a.currentValue);
  final passiveMonthly = incomes
      .where((i) => i.type == IncomeType.passive)
      .fold<double>(0, (sum, i) => sum + i.monthlyAmount);
  final totalExpense = expenses.fold<double>(0, (sum, e) => sum + e.monthlyAmount);

  return DashboardData(
    totalAssets: totalAssets,
    totalPassiveMonthlyIncome: passiveMonthly,
    totalMonthlyExpense: totalExpense,
    monthlyNetCashFlow: passiveMonthly - totalExpense,
  );
});
