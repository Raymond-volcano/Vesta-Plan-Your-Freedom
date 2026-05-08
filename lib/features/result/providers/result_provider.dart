import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/income_expense/providers/income_expense_provider.dart';
import '../../../../features/assets/providers/asset_provider.dart';
import '../../../../features/profile/providers/profile_provider.dart';
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
