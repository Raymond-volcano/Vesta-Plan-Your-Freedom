import 'dart:math' as math;
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

/// 1.05^n 快速查找表（避免重复计算 pow）
final _pow105Cache = <int, double>{};
double _pow105(int n) {
  if (n <= 0) return 1.0;
  return _pow105Cache.putIfAbsent(n, () => math.pow(1.05, n).toDouble());
}

/// 计算某笔收入在指定年份的实际月数
int _activeIncomeMonths(IncomeModel income, int year) {
  if (!income.isActiveInYear(year)) return 0;
  int months = 12;
  if (year == income.startYear) months -= (income.startMonth - 1);
  if (year == income.endYear && income.endMonth != null) months -= (12 - income.endMonth!);
  return months;
}

/// 计算某笔支出在指定年份的实际月数
int _activeExpenseMonths(ExpenseModel expense, int year) {
  if (!expense.isActiveInYear(year)) return 0;
  int months = 12;
  if (year == expense.startYear) months -= (expense.startMonth - 1);
  if (year == expense.endYear && expense.endMonth != null) months -= (12 - expense.endMonth!);
  return months;
}

class CashFlowCalculator {
  /// 逐年模拟现金流（性能优化版）
  static List<YearData> simulate({
    required UserProfileModel profile,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required List<AssetModel> assets,
    required bool simulateUnemployment,
  }) {
    final currentYear = DateTime.now().year;
    final startAge = profile.currentAge;
    const maxAge = 80;
    final totalYears = maxAge - startAge;
    if (totalYears <= 0) return [];

    final results = <YearData>[];
    double runningAssets = 0;
    for (int k = 0; k < assets.length; k++) {
      runningAssets += assets[k].currentValue;
    }

    // 预计算通胀系数
    final inflFactors = <double>[];
    if (profile.annualInflationRate > 0) {
      double factor = 1.0;
      final rate = 1 + profile.annualInflationRate;
      for (int i = 0; i <= totalYears; i++) {
        inflFactors.add(factor);
        factor *= rate;
      }
    }

    // 预计算资产加权平均收益率
    double blendedRate = 0;
    double totalAssetValue = 0;
    for (int k = 0; k < assets.length; k++) {
      totalAssetValue += assets[k].currentValue;
    }
    if (totalAssetValue > 0) {
      for (int k = 0; k < assets.length; k++) {
        blendedRate += (assets[k].currentValue / totalAssetValue) * assets[k].annualReturnRate;
      }
    }

    // 缓存频繁访问的 profile 字段
    final retirementAge = profile.retirementAge;
    final hasBenefit = profile.unemploymentBenefit > 0 && profile.unemploymentBenefitMonths > 0;
    final hasPension = profile.pensionAmount > 0;
    final hasExtraExpense = profile.unemploymentExtraExpense > 0 && profile.unemploymentExtraExpenseMonths > 0;
    final unemployStartYear = profile.unemploymentStartYear ?? currentYear;
    final benefitMonths = profile.unemploymentBenefitMonths;
    final benefitAmount = profile.unemploymentBenefit;
    final extraExpenseMonths = profile.unemploymentExtraExpenseMonths;
    final extraExpenseAmount = profile.unemploymentExtraExpense;
    final pensionAmount = profile.pensionAmount;
    final inflEnabled = inflFactors.isNotEmpty;

    for (int i = 0; i <= totalYears; i++) {
      final year = currentYear + i;
      final age = startAge + i;
      final isRetired = age >= retirementAge;
      final isUnemployed = simulateUnemployment && year >= unemployStartYear;
      final activeEnabled = !isUnemployed || isRetired;

      // 收入
      double activeIncome = 0;
      double passiveIncome = 0;
      for (int k = 0; k < incomes.length; k++) {
        final income = incomes[k];
        if (income.isActiveInYear(year)) {
          final months = _activeIncomeMonths(income, year);
          if (income.type == IncomeType.active) {
            if (activeEnabled) activeIncome += income.monthlyAmount * months;
          } else {
            passiveIncome += income.monthlyAmount * months;
          }
        }
      }

      // 失业金
      double unemploymentBenefitIncome = 0;
      if (isUnemployed && hasBenefit) {
        final yearsSince = year - unemployStartYear;
        final remaining = benefitMonths - yearsSince * 12;
        if (remaining > 0) {
          unemploymentBenefitIncome = benefitAmount * (remaining < 12 ? remaining : 12);
        }
      }

      // 养老金（退休后每年 5% 复利）
      double pensionIncome = 0;
      if (isRetired && hasPension) {
        pensionIncome = pensionAmount * 12 * _pow105(age - retirementAge);
      }

      // 支出
      double totalExpense = 0;
      for (int k = 0; k < expenses.length; k++) {
        final expense = expenses[k];
        if (expense.isActiveInYear(year)) {
          totalExpense += expense.monthlyAmount * _activeExpenseMonths(expense, year);
        }
      }

      // 通胀调整
      if (inflEnabled) totalExpense *= inflFactors[i];

      // 失业额外支出
      double extraExpense = 0;
      if (isUnemployed && hasExtraExpense) {
        final yearsSince = year - unemployStartYear;
        final remaining = extraExpenseMonths - yearsSince * 12;
        if (remaining > 0) {
          extraExpense = extraExpenseAmount * (remaining < 12 ? remaining : 12);
        }
      }
      totalExpense += extraExpense;

      // 资产增值
      final assetReturn = runningAssets > 0 ? runningAssets * blendedRate : 0.0;

      final totalIncome = activeIncome + passiveIncome + unemploymentBenefitIncome + pensionIncome + assetReturn;
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

      if (runningAssets < 0 && i > 3) break;
    }

    return results;
  }
}
