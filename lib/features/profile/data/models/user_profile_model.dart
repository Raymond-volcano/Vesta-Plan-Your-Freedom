import 'package:hive/hive.dart';

enum Gender {
  male('男'),
  female('女');

  final String label;
  const Gender(this.label);
}

@HiveType(typeId: 5)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  int currentAge;
  @HiveField(1)
  int retirementAge;
  @HiveField(2)
  double targetMonthlyPassiveIncome; // 保留字段，但不再在UI中显示
  @HiveField(3)
  int genderIndex; // 0=male, 1=female
  @HiveField(5)
  double unemploymentBenefit; // 每月失业金
  @HiveField(6)
  int unemploymentBenefitMonths; // 失业金领取月数
  @HiveField(7)
  double pensionAmount; // 每月养老金
  @HiveField(8)
  int? unemploymentStartYear; // 失业开始年份（null=不模拟）
  @HiveField(9)
  int? unemploymentStartMonth; // 失业开始月份
  @HiveField(10)
  double annualInflationRate; // 年通胀率（如0.03=3%）
  @HiveField(11)
  double unemploymentExtraExpense; // 失业期间每月额外支出（保险/医保）
  @HiveField(12)
  int unemploymentExtraExpenseMonths; // 额外支出持续月数

  UserProfileModel({
    required this.currentAge,
    required this.retirementAge,
    this.targetMonthlyPassiveIncome = 0,
    this.genderIndex = 0,
    this.unemploymentBenefit = 0,
    this.unemploymentBenefitMonths = 0,
    this.pensionAmount = 0,
    this.unemploymentStartYear,
    this.unemploymentStartMonth,
    this.annualInflationRate = 0.03,
    this.unemploymentExtraExpense = 0,
    this.unemploymentExtraExpenseMonths = 0,
  });

  Gender get gender => Gender.values[genderIndex];

  int get yearsToRetirement => retirementAge - currentAge;

  bool get isConfigured => currentAge > 0 && retirementAge > 0;

  /// 根据中国渐进式延迟退休政策计算法定退休年龄
  static int statutoryAge(int currentAge, Gender gender) {
    final birthYear = DateTime.now().year - currentAge;

    switch (gender) {
      case Gender.male:
        // 男：原60岁，2025年起每3个月延1个月，最多延3年→63
        if (birthYear <= 1965) return 60;
        if (birthYear >= 1977) return 63;
        return 60 + ((birthYear - 1965) * 3 ~/ 12).clamp(0, 3);

      case Gender.female:
        // 简化：女性按原55岁（干部标准），渐进至58
        if (birthYear <= 1970) return 55;
        if (birthYear >= 1982) return 58;
        return 55 + ((birthYear - 1970) * 3 ~/ 12).clamp(0, 3);
    }
  }

  UserProfileModel copyWith({
    int? currentAge,
    int? retirementAge,
    double? targetMonthlyPassiveIncome,
    int? genderIndex,
    double? unemploymentBenefit,
    int? unemploymentBenefitMonths,
    double? pensionAmount,
    int? unemploymentStartYear,
    int? unemploymentStartMonth,
    double? annualInflationRate,
    double? unemploymentExtraExpense,
    int? unemploymentExtraExpenseMonths,
    bool clearUnemploymentStart = false,
  }) {
    return UserProfileModel(
      currentAge: currentAge ?? this.currentAge,
      retirementAge: retirementAge ?? this.retirementAge,
      targetMonthlyPassiveIncome:
          targetMonthlyPassiveIncome ?? this.targetMonthlyPassiveIncome,
      genderIndex: genderIndex ?? this.genderIndex,
      unemploymentBenefit: unemploymentBenefit ?? this.unemploymentBenefit,
      unemploymentBenefitMonths:
          unemploymentBenefitMonths ?? this.unemploymentBenefitMonths,
      pensionAmount: pensionAmount ?? this.pensionAmount,
      unemploymentStartYear: clearUnemploymentStart
          ? null
          : (unemploymentStartYear ?? this.unemploymentStartYear),
      unemploymentStartMonth: clearUnemploymentStart
          ? null
          : (unemploymentStartMonth ?? this.unemploymentStartMonth),
      annualInflationRate: annualInflationRate ?? this.annualInflationRate,
      unemploymentExtraExpense:
          unemploymentExtraExpense ?? this.unemploymentExtraExpense,
      unemploymentExtraExpenseMonths:
          unemploymentExtraExpenseMonths ?? this.unemploymentExtraExpenseMonths,
    );
  }
}

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 5;

  @override
  UserProfileModel read(BinaryReader reader) {
    final fields = reader.readMap();
    return UserProfileModel(
      currentAge: fields[0] as int,
      retirementAge: fields[1] as int,
      targetMonthlyPassiveIncome: (fields[2] as num?)?.toDouble() ?? 0,
      genderIndex: fields[3] as int? ?? 0,
      unemploymentBenefit: (fields[5] as num?)?.toDouble() ?? 0,
      unemploymentBenefitMonths: fields[6] as int? ?? 0,
      pensionAmount: (fields[7] as num?)?.toDouble() ?? 0,
      unemploymentStartYear: fields[8] as int?,
      unemploymentStartMonth: fields[9] as int?,
      annualInflationRate: (fields[10] as num?)?.toDouble() ?? 0.03,
      unemploymentExtraExpense: (fields[11] as num?)?.toDouble() ?? 0,
      unemploymentExtraExpenseMonths: fields[12] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer.writeMap({
      0: obj.currentAge,
      1: obj.retirementAge,
      2: obj.targetMonthlyPassiveIncome,
      3: obj.genderIndex,
      5: obj.unemploymentBenefit,
      6: obj.unemploymentBenefitMonths,
      7: obj.pensionAmount,
      8: obj.unemploymentStartYear,
      9: obj.unemploymentStartMonth,
      10: obj.annualInflationRate,
      11: obj.unemploymentExtraExpense,
      12: obj.unemploymentExtraExpenseMonths,
    });
  }
}
