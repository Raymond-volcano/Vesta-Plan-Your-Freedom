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
    const maxAge = 80;
    final totalYears = maxAge - startAge;
    final results = <YearData>[];
    double runningAssets = assets.fold(0, (sum, a) => sum + a.currentValue);

    for (int i = 0; i <= totalYears; i++) {
      final year = currentYear + i;
      final age = startAge + i;
      final isRetired = age >= profile.retirementAge;

      // 是否处于失业状态（从指定年份开始）
      bool isUnemployed = simulateUnemployment;
      if (profile.unemploymentStartYear != null && year < profile.unemploymentStartYear!) {
        isUnemployed = false;
      }

      // 计算当年收入（考虑起始/结束月份）
      double activeIncome = 0;
      double passiveIncome = 0;

      for (final income in incomes) {
        if (!income.isActiveInYear(year)) continue;
        if (income.type == IncomeType.active) {
          if (!isUnemployed || isRetired) {
            activeIncome += income.annualIncomeInYear(year);
          }
        } else {
          passiveIncome += income.annualIncomeInYear(year);
        }
      }

      // 失业金收入（有领取月数限制）
      double unemploymentBenefitIncome = 0;
      if (isUnemployed && profile.unemploymentBenefit > 0 && profile.unemploymentBenefitMonths > 0) {
        final startYear = profile.unemploymentStartYear ?? currentYear;
        if (year >= startYear) {
          final yearsSinceUnemployed = year - startYear;
          final remainingMonths = profile.unemploymentBenefitMonths - yearsSinceUnemployed * 12;
          if (remainingMonths > 0) {
            final monthsThisYear = remainingMonths < 12 ? remainingMonths : 12;
            unemploymentBenefitIncome = profile.unemploymentBenefit * monthsThisYear;
          }
        }
      }

      // 养老金收入（退休后，每年按 5% 增长）
      double pensionIncome = 0;
      if (isRetired && profile.pensionAmount > 0) {
        final yearsSinceRetirement = age - profile.retirementAge;
        pensionIncome = profile.pensionAmount * 12 *
            math.pow(1.05, yearsSinceRetirement.toDouble()).toDouble();
      }

      // 计算当年支出（考虑起始/结束月份）
      double totalExpense = 0;
      for (final expense in expenses) {
        if (expense.isActiveInYear(year)) {
          totalExpense += expense.annualExpenseInYear(year);
        }
      }

      // 通胀调整（每年复利）
      if (profile.annualInflationRate > 0 && i > 0) {
        totalExpense *= math.pow(1 + profile.annualInflationRate, i).toDouble();
      }

      // 失业额外支出（保险/医保等）
      double extraExpense = 0;
      if (isUnemployed && profile.unemploymentExtraExpense > 0 && profile.unemploymentExtraExpenseMonths > 0) {
        final startYear = profile.unemploymentStartYear ?? currentYear;
        if (year >= startYear) {
          final yearsSinceUnemployed = year - startYear;
          final remainingMonths = profile.unemploymentExtraExpenseMonths - yearsSinceUnemployed * 12;
          if (remainingMonths > 0) {
            final monthsThisYear = remainingMonths < 12 ? remainingMonths : 12;
            extraExpense = profile.unemploymentExtraExpense * monthsThisYear;
          }
        }
      }
      totalExpense += extraExpense;

      // 计算资产增值（加权平均收益率）
      double assetReturn = 0;
      if (assets.isNotEmpty && runningAssets > 0) {
        final totalValue = assets.fold<double>(0, (s, a) => s + a.currentValue);
        final blendedRate = totalValue > 0
            ? assets.fold<double>(
                    0, (s, a) => s + a.currentValue * a.annualReturnRate) /
                totalValue
            : 0.0;
        assetReturn = runningAssets * blendedRate;
      }

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

      // 如果资产为负且持续，提前终止
      if (runningAssets < 0 && i > 3) break;
    }

    return results;
  }
}
