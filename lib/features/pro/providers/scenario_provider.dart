import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../income_expense/data/models/income_model.dart';
import '../../income_expense/data/models/expense_model.dart';
import '../../assets/data/models/asset_model.dart';
import '../../profile/data/models/user_profile_model.dart';
import '../../income_expense/providers/income_expense_provider.dart';
import '../../assets/providers/asset_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/models/scenario_model.dart';

/// 方案 Box Provider
final scenarioBoxProvider = Provider<Box<ScenarioModel>>((ref) {
  return Hive.box<ScenarioModel>(AppConstants.scenarioBox);
});

/// 方案列表 Provider
final scenarioListProvider = StateNotifierProvider<ScenarioListNotifier, List<ScenarioModel>>((ref) {
  final box = ref.watch(scenarioBoxProvider);
  return ScenarioListNotifier(box, ref);
});

/// 当前选中的方案 ID（null = 仅用 Free 模式）
final activeScenarioIdProvider = StateProvider<String?>((ref) => null);

/// 当前方案数据（派生）
final activeScenarioProvider = Provider<ScenarioModel?>((ref) {
  final id = ref.watch(activeScenarioIdProvider);
  if (id == null) return null;
  final scenarios = ref.watch(scenarioListProvider);
  final idValue = id;
  return scenarios.where((s) => s.id == idValue).firstOrNull;
});

class ScenarioListNotifier extends StateNotifier<List<ScenarioModel>> {
  final Box<ScenarioModel> _box;
  final Ref _ref;

  ScenarioListNotifier(this._box, this._ref) : super(_box.values.toList());

  /// 从当前实时数据创建新方案
  Future<void> createFromCurrentData({
    required String name,
    ScenarioLabel label = ScenarioLabel.custom,
  }) async {
    final incomes = _ref.read(incomeListProvider);
    final expenses = _ref.read(expenseListProvider);
    final assets = _ref.read(assetListProvider);
    final profile = _ref.read(profileProvider);

    final scenario = ScenarioModel.fromCurrentData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      label: label,
      incomes: incomes,
      expenses: expenses,
      assets: assets,
      profile: profile,
    );

    await _box.add(scenario);
    state = _box.values.toList();

    // 自动切换到这个新方案
    _setActiveId(scenario.id);
  }

  /// 复制方案
  Future<void> duplicate(String id, String newName) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final original = state[index];
    final copy = ScenarioModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName,
      label: original.label,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      incomesJson: original.incomesJson,
      expensesJson: original.expensesJson,
      assetsJson: original.assetsJson,
      profileJson: original.profileJson,
    );

    await _box.add(copy);
    state = _box.values.toList();
  }

  /// 重命名
  Future<void> rename(String id, String newName) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final updated = state[index].copyWithData(name: newName);
    await _box.putAt(index, updated);
    state = _box.values.toList();
  }

  /// 删除方案
  Future<void> delete(String id) async {
    final index = state.indexWhere((s) => s.id == id);
    if (index == -1) return;

    await _box.deleteAt(index);
    state = _box.values.toList();

    // 如果删除了当前激活的方案，清除 activeId
    final activeId = _ref.read(activeScenarioIdProvider);
    if (activeId == id) {
      _setActiveId(null);
    }
  }

  /// 切换方案 — 将方案数据加载到当前界面的 Provider 中
  Future<void> switchTo(String id) async {
    final scenario = state.where((s) => s.id == id).firstOrNull;
    if (scenario == null) return;

    // 将方案快照数据写入 Hive 实时 box
    await _writeScenarioToLiveBoxes(scenario);
    _setActiveId(id);
  }

  /// 将当前数据同步到当前方案
  Future<void> syncCurrentToActive() async {
    final activeId = _ref.read(activeScenarioIdProvider);
    if (activeId == null) return;

    final index = state.indexWhere((s) => s.id == activeId);
    if (index == -1) return;

    final incomes = _ref.read(incomeListProvider);
    final expenses = _ref.read(expenseListProvider);
    final assets = _ref.read(assetListProvider);
    final profile = _ref.read(profileProvider);

    final updated = state[index].copyWithData(
      incomes: incomes,
      expenses: expenses,
      assets: assets,
      profile: profile,
    );

    await _box.putAt(index, updated);
    state = _box.values.toList();
  }

  /// 将方案快照写入实时 Hive Box（切换方案时调用）
  Future<void> _writeScenarioToLiveBoxes(ScenarioModel scenario) async {
    // 写入 incomes
    final incomeBox = Hive.box<IncomeModel>(AppConstants.incomeBox);
    await incomeBox.clear();
    for (final income in scenario.incomes) {
      await incomeBox.add(income);
    }
    _ref.invalidate(incomeListProvider);

    // 写入 expenses
    final expenseBox = Hive.box<ExpenseModel>(AppConstants.expenseBox);
    await expenseBox.clear();
    for (final expense in scenario.expenses) {
      await expenseBox.add(expense);
    }
    _ref.invalidate(expenseListProvider);

    // 写入 assets
    final assetBox = Hive.box<AssetModel>(AppConstants.assetBox);
    await assetBox.clear();
    for (final asset in scenario.assets) {
      await assetBox.add(asset);
    }
    _ref.invalidate(assetListProvider);

    // 写入 profile
    final profileBox = Hive.box<UserProfileModel>(AppConstants.profileBox);
    await profileBox.clear();
    await profileBox.add(scenario.profile);
    _ref.invalidate(profileProvider);
  }

  /// 从基准方案自动生成 3 个情景（乐观/保守/极端下行）
  Future<void> generateScenarios(String baselineId) async {
    final index = state.indexWhere((s) => s.id == baselineId);
    if (index == -1) return;

    final baseline = state[index];
    final baseIncomes = baseline.incomes;
    final baseExpenses = baseline.expenses;
    final baseAssets = baseline.assets;
    final baseProfile = baseline.profile;

    Future<void> createScenario({
      required String name,
      required ScenarioLabel label,
      required double incomeFactor,     // 1.0 = unchanged
      required double expenseFactor,    // 1.0 = unchanged
      required double returnRateDelta,  // absolute change, e.g. 0.02 = +2%
      required double inflationDelta,  // absolute change, e.g. -0.01 = -1%
    }) async {
      final now = DateTime.now();
      final scenario = ScenarioModel(
        id: now.millisecondsSinceEpoch.toString(),
        name: name,
        label: label.jsonValue,
        createdAt: now,
        updatedAt: now,
        incomesJson: ScenarioModel.encodeIncomes(
          baseIncomes.map((i) => i.copyWith(
            monthlyAmount: (i.monthlyAmount * incomeFactor)
                .roundToDouble(),
          )).toList(),
        ),
        expensesJson: ScenarioModel.encodeExpenses(
          baseExpenses.map((e) => e.copyWith(
            monthlyAmount: (e.monthlyAmount * expenseFactor)
                .roundToDouble(),
          )).toList(),
        ),
        assetsJson: ScenarioModel.encodeAssets(
          baseAssets.map((a) => a.copyWith(
            annualReturnRate: (a.annualReturnRate + returnRateDelta)
                .clamp(0, 1),
          )).toList(),
        ),
        profileJson: ScenarioModel.encodeProfile(
          baseProfile.copyWith(
            annualInflationRate:
                (baseProfile.annualInflationRate + inflationDelta)
                    .clamp(0, 0.2),
          ),
        ),
      );
      await _box.add(scenario);
    }

    await createScenario(
      name: '${baseline.name} - 乐观',
      label: ScenarioLabel.optimistic,
      incomeFactor: 1.2,
      expenseFactor: 0.9,
      returnRateDelta: 0.02,
      inflationDelta: -0.01,
    );

    await createScenario(
      name: '${baseline.name} - 保守',
      label: ScenarioLabel.conservative,
      incomeFactor: 0.9,
      expenseFactor: 1.1,
      returnRateDelta: -0.02,
      inflationDelta: 0.01,
    );

    await createScenario(
      name: '${baseline.name} - 极端下行',
      label: ScenarioLabel.extreme,
      incomeFactor: 0.7,
      expenseFactor: 1.2,
      returnRateDelta: -0.05,
      inflationDelta: 0.03,
    );

    state = _box.values.toList();
  }

  Future<void> _setActiveId(String? id) async {
    _ref.read(activeScenarioIdProvider.notifier).state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString('active_scenario_id', id);
    } else {
      await prefs.remove('active_scenario_id');
    }
  }
}
