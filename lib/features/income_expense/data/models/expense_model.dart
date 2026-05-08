import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class ExpenseModel extends HiveObject {
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
  int startMonth; // 1-12
  @HiveField(6)
  int? endMonth; // 1-12, null = 永久

  ExpenseModel({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.startYear,
    this.endYear,
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

  /// 当年实际支出（考虑起始/结束月份，折算全年）
  double annualExpenseInYear(int year) {
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

  ExpenseModel copyWith({
    String? id,
    String? name,
    double? monthlyAmount,
    int? startYear,
    int? endYear,
    int? startMonth,
    int? endMonth,
    bool clearEndYear = false,
    bool clearEndMonth = false,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startYear: startYear ?? this.startYear,
      endYear: clearEndYear ? null : (endYear ?? this.endYear),
      startMonth: startMonth ?? this.startMonth,
      endMonth: clearEndMonth ? null : (endMonth ?? this.endMonth),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlyAmount': monthlyAmount,
        'startYear': startYear,
        'endYear': endYear,
        'startMonth': startMonth,
        'endMonth': endMonth,
      };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        name: json['name'] as String,
        monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
        startYear: json['startYear'] as int,
        endYear: json['endYear'] as int?,
        startMonth: json['startMonth'] as int? ?? 1,
        endMonth: json['endMonth'] as int?,
      );
}

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 2;

  @override
  ExpenseModel read(BinaryReader reader) {
    final fields = reader.readMap();
    return ExpenseModel(
      id: fields[0] as String,
      name: fields[1] as String,
      monthlyAmount: (fields[2] as num).toDouble(),
      startYear: fields[3] as int,
      endYear: fields[4] as int?,
      startMonth: fields[5] as int? ?? 1,
      endMonth: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.name,
      2: obj.monthlyAmount,
      3: obj.startYear,
      4: obj.endYear,
      5: obj.startMonth,
      6: obj.endMonth,
    });
  }
}
