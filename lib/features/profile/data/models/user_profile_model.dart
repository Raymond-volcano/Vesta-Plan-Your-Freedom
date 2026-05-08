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

  UserProfileModel({
    required this.currentAge,
    required this.retirementAge,
    this.targetMonthlyPassiveIncome = 0,
    this.genderIndex = 0,
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
  }) {
    return UserProfileModel(
      currentAge: currentAge ?? this.currentAge,
      retirementAge: retirementAge ?? this.retirementAge,
      targetMonthlyPassiveIncome:
          targetMonthlyPassiveIncome ?? this.targetMonthlyPassiveIncome,
      genderIndex: genderIndex ?? this.genderIndex,
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
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer.writeMap({
      0: obj.currentAge,
      1: obj.retirementAge,
      2: obj.targetMonthlyPassiveIncome,
      3: obj.genderIndex,
    });
  }
}
