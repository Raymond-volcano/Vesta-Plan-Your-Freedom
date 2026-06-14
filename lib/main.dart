import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'features/income_expense/data/models/income_model.dart';
import 'features/income_expense/data/models/expense_model.dart';
import 'features/assets/data/models/asset_model.dart';
import 'features/profile/data/models/user_profile_model.dart';
import 'features/pro/data/models/scenario_model.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 初始化 Hive（Web 使用 IndexedDB，移动端/桌面用文件存储） ──
  if (kIsWeb) {
    await Hive.init();
  } else {
    await Hive.initFlutter();
  }

  // 注册 TypeAdapter（手写）
  Hive.registerAdapter(IncomeModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(AssetModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());
  Hive.registerAdapter(ScenarioModelAdapter());

  // 打开 Boxes
  await Future.wait([
    Hive.openBox<IncomeModel>(AppConstants.incomeBox),
    Hive.openBox<ExpenseModel>(AppConstants.expenseBox),
    Hive.openBox<AssetModel>(AppConstants.assetBox),
    Hive.openBox<UserProfileModel>(AppConstants.profileBox),
    Hive.openBox<ScenarioModel>(AppConstants.scenarioBox),
  ]);

  runApp(
    const ProviderScope(child: FinancialFreedomApp()),
  );
}
