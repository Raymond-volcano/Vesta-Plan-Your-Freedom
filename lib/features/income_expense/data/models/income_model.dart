import 'package:hive/hive.dart';

enum IncomeType {
  active('主动收入'),
  passive('被动收入');

  final String label;
  const IncomeType(this.label);
}

@HiveType(typeId: 0)
class IncomeModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double monthlyAmount;
  @HiveField(3)
  int startYear;
  @HiveField(4)
  int? endYear; // null = 永久
  @HiveField(5)
  IncomeType type;
  @HiveField(6)
  int startMonth; // 1-12
  @HiveField(7)
  int? endMonth; // 1-12, null = 永久

  IncomeModel({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.startYear,
    this.endYear,
    required this.type,
    this.startMonth = 1,
    this.endMonth,
  });

  double get annualAmount => monthlyAmount * 12;

  bool get isPermanent => endYear == null;

  bool isActiveInYear(int year) {
    if (year < startYear) return false;
    if (endYear != null && year > endYear!) return false;
    return true;
  }

  bool isActiveAt(int year, int month) {
    if (year < startYear || (endYear != null && year > endYear!)) return false;
    if (year == startYear && month < startMonth) return false;
    if (year == endYear && endMonth != null && month > endMonth!) return false;
    return true;
  }

  /// 当年实际收入（考虑起始/结束月份，折算全年）
  double annualIncomeInYear(int year) {
    if (!isActiveInYear(year)) return 0;
    int activeMonths = 12;

    if (year == startYear) {
      activeMonths -= (startMonth - 1);
    }
    if (year == endYear && endMonth != null) {
      activeMonths -= (12 - endMonth!);
    }

    return monthlyAmount * activeMonths;
  }

  IncomeModel copyWith({
    String? id,
    String? name,
    double? monthlyAmount,
    int? startYear,
    int? endYear,
    IncomeType? type,
    int? startMonth,
    int? endMonth,
    bool clearEndYear = false,
    bool clearEndMonth = false,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startYear: startYear ?? this.startYear,
      endYear: clearEndYear ? null : (endYear ?? this.endYear),
      type: type ?? this.type,
      startMonth: startMonth ?? this.startMonth,
      endMonth: clearEndMonth ? null : (endMonth ?? this.endMonth),
    );
  }
}

class IncomeModelAdapter extends TypeAdapter<IncomeModel> {
  @override
  final int typeId = 1;

  @override
  IncomeModel read(BinaryReader reader) {
    final fields = reader.readMap();
    return IncomeModel(
      id: fields[0] as String,
      name: fields[1] as String,
      monthlyAmount: (fields[2] as num).toDouble(),
      startYear: fields[3] as int,
      endYear: fields[4] as int?,
      type: IncomeType.values[fields[5] as int],
      startMonth: fields[6] as int? ?? 1,
      endMonth: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeModel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.name,
      2: obj.monthlyAmount,
      3: obj.startYear,
      4: obj.endYear,
      5: obj.type.index,
      6: obj.startMonth,
      7: obj.endMonth,
    });
  }
}
