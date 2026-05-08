import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../income_expense/data/models/income_model.dart';
import '../../../income_expense/data/models/expense_model.dart';
import '../../../assets/data/models/asset_model.dart';
import '../../../profile/data/models/user_profile_model.dart';

/// 方案标签
enum ScenarioLabel {
  baseline('基准'),
  optimistic('乐观'),
  conservative('保守'),
  extreme('极端下行'),
  custom('自定义');

  final String label;
  const ScenarioLabel(this.label);

  String get jsonValue => name;
  static ScenarioLabel fromJson(String value) {
    return ScenarioLabel.values.firstWhere((e) => e.name == value, orElse: () => ScenarioLabel.custom);
  }
}

/// 方案模型 — 保存一份完整的财务数据快照
///
/// 使用 JSON 字符串存储列表数据，避免 Hive 嵌套泛型问题。
@HiveType(typeId: 6)
class ScenarioModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String label;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  // JSON 序列化的数据快照
  @HiveField(5)
  String incomesJson;

  @HiveField(6)
  String expensesJson;

  @HiveField(7)
  String assetsJson;

  @HiveField(8)
  String profileJson;

  ScenarioModel({
    required this.id,
    required this.name,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
    String? incomesJson,
    String? expensesJson,
    String? assetsJson,
    String? profileJson,
  })  : incomesJson = incomesJson ?? '[]',
        expensesJson = expensesJson ?? '[]',
        assetsJson = assetsJson ?? '[]',
        profileJson = profileJson ?? '{}';

  // ── 反序列化辅助方法 ────────────────────────────────────

  List<IncomeModel> get incomes {
    final list = jsonDecode(incomesJson) as List;
    return list.map((e) => IncomeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  List<ExpenseModel> get expenses {
    final list = jsonDecode(expensesJson) as List;
    return list.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  List<AssetModel> get assets {
    final list = jsonDecode(assetsJson) as List;
    return list.map((e) => AssetModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  UserProfileModel get profile => UserProfileModel.fromJson(jsonDecode(profileJson) as Map<String, dynamic>);

  // ── 序列化辅助方法 ────────────────────────────────────

  ScenarioModel copyWithData({
    List<IncomeModel>? incomes,
    List<ExpenseModel>? expenses,
    List<AssetModel>? assets,
    UserProfileModel? profile,
    String? name,
    ScenarioLabel? label,
  }) {
    return ScenarioModel(
      id: id,
      name: name ?? this.name,
      label: (label ?? ScenarioLabel.fromJson(this.label)).jsonValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      incomesJson: incomes != null ? encodeIncomes(incomes) : incomesJson,
      expensesJson: expenses != null ? encodeExpenses(expenses) : expensesJson,
      assetsJson: assets != null ? encodeAssets(assets) : assetsJson,
      profileJson: profile != null ? encodeProfile(profile) : profileJson,
    );
  }

  static String encodeIncomes(List<IncomeModel> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static String encodeExpenses(List<ExpenseModel> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static String encodeAssets(List<AssetModel> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static String encodeProfile(UserProfileModel p) => jsonEncode(p.toJson());

  /// 从当前实时数据创建快照
  factory ScenarioModel.fromCurrentData({
    required String id,
    required String name,
    required ScenarioLabel label,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required List<AssetModel> assets,
    required UserProfileModel profile,
  }) {
    final now = DateTime.now();
    return ScenarioModel(
      id: id,
      name: name,
      label: label.jsonValue,
      createdAt: now,
      updatedAt: now,
      incomesJson: encodeIncomes(incomes),
      expensesJson: encodeExpenses(expenses),
      assetsJson: encodeAssets(assets),
      profileJson: encodeProfile(profile),
    );
  }
}

/// Hive TypeAdapter（手写）
class ScenarioModelAdapter extends TypeAdapter<ScenarioModel> {
  @override
  final int typeId = 6;

  @override
  ScenarioModel read(BinaryReader reader) {
    final fields = reader.readMap();
    return ScenarioModel(
      id: fields[0] as String,
      name: fields[1] as String,
      label: fields[2] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[3] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      incomesJson: fields[5] as String?,
      expensesJson: fields[6] as String?,
      assetsJson: fields[7] as String?,
      profileJson: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScenarioModel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.name,
      2: obj.label,
      3: obj.createdAt.millisecondsSinceEpoch,
      4: obj.updatedAt.millisecondsSinceEpoch,
      5: obj.incomesJson,
      6: obj.expensesJson,
      7: obj.assetsJson,
      8: obj.profileJson,
    });
  }
}
