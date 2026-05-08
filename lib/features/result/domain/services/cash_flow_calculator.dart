import '../../../../features/income_expense/data/models/income_model.dart';
import '../../../../features/income_expense/data/models/expense_model.dart';
import '../../../../features/assets/data/models/asset_model.dart';
import '../../../../features/profile/data/models/user_profile_model.dart';

class YearData {
  final int year;
  final int age;
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double totalAssets;
  final double passiveIncome;

  const YearData({
    required this.year,
    required this.age,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.totalAssets,
    required this.passiveIncome,
  });
}

class CashFlowCalculator {
  /// 逐年模拟现金流
  /// [simulateUnemployment] 为 true 时关闭所有主动收入
  static List<YearData> simulate({
    required UserProfileModel profile,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required List<AssetModel> assets,
    required bool simulateUnemployment,
  }) {
    final currentYear = DateTime.now().year;
    final startAge = profile.currentAge;
    final maxAge = 80;
    final totalYears = maxAge - startAge;
    final results = <YearData>[];
    double runningAssets = assets.fold(0, (sum, a) => sum + a.currentValue);

    for (int i = 0; i <= totalYears; i++) {
      final year = currentYear + i;
      final age = startAge + i;
      final isRetired = age >= profile.retirementAge;

      // 计算当年收入（考虑起始/结束月份）
      double activeIncome = 0;
      double passiveIncome = 0;

      for (final income in incomes) {
        if (!income.isActiveInYear(year)) continue;
        if (income.type == IncomeType.active) {
          if (!simulateUnemployment || isRetired) {
            activeIncome += income.annualIncomeInYear(year);
          }
        } else {
          passiveIncome += income.annualIncomeInYear(year);
        }
      }

      // 计算当年支出（考虑起始/结束月份）
      double totalExpense = 0;
      for (final expense in expenses) {
        if (expense.isActiveInYear(year)) {
          totalExpense += expense.annualExpenseInYear(year);
        }
      }

      // 计算资产增值
      double assetReturn = 0;
      for (final asset in assets) {
        assetReturn += runningAssets * asset.annualReturnRate;
      }

      final totalIncome = activeIncome + passiveIncome + assetReturn;
      final netCashFlow = totalIncome - totalExpense;
      runningAssets += netCashFlow;

      results.add(YearData(
        year: year,
        age: age,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netCashFlow: netCashFlow,
        totalAssets: runningAssets,
        passiveIncome: passiveIncome,
      ));

      // 如果资产为负且持续，提前终止
      if (runningAssets < 0 && i > 3) break;
    }

    return results;
  }
}
