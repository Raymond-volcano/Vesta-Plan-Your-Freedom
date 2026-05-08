# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Analyze (no errors expected)
dart analyze lib/

# Run on device
flutter run

# Run on web (debugging)
flutter run -d chrome

# Build web
flutter build web --no-tree-shake-icons

# Build Android APK (debug)
flutter build apk --debug
```

## Project Structure

Flutter financial planning app with Riverpod state management, Hive local storage, and fl_chart visualizations.

### State Management Pattern

**Riverpod** with Hive persistence. Each data domain follows:

```
Hive Box → BoxProvider → StateNotifierProvider → UI (ConsumerWidget/ConsumerStatefulWidget)
```

12 providers total across the app.

### Key Architecture

```
lib/
  main.dart                        # Entry: init Hive, register adapters, open boxes
  app.dart                         # MaterialApp.router with GoRouter
  core/
    constants/app_constants.dart    # Hive box names, adapter type IDs
    router/app_router.dart          # GoRouter: 4 bottom tabs + /assets
    theme/app_theme.dart            # Colors (teal/gold palette), Material 3 theme
    pro/pro_config.dart             # Pro feature flags and Free limits
  features/
    income_expense/                 # Income (active/passive) and expense CRUD
      models/income_model.dart      # IncomeModel: name, amount, start/end year/month, type
      models/expense_model.dart     # ExpenseModel: name, amount, start/end year/month
      providers/income_expense_provider.dart  # incomeListProvider, expenseListProvider
      pages/income_expense_page.dart
    assets/                         # Asset/liability CRUD
      models/asset_model.dart       # AssetModel: name, value, annualReturnRate
      providers/asset_provider.dart # assetListProvider
      pages/assets_page.dart
    profile/                        # User settings
      models/user_profile_model.dart # age, retirement, gender, unemployment, pension, inflation
      providers/profile_provider.dart # profileProvider (singleton)
      pages/profile_page.dart
    result/                         # Simulation and charts
      domain/services/cash_flow_calculator.dart  # Year-by-year simulation engine
      providers/result_provider.dart             # simulationResultProvider, sensitivityProvider
      pages/result_page.dart                     # 4 charts + sensitivity analysis + insights
    dashboard/                      # Home page with summary cards
      models/dashboard_data.dart    # DashboardData, dashboardDataProvider
      pages/dashboard_page.dart     # Total assets, income, cash flow cards
    pro/                            # Pro version features (in progress)
      providers/pro_status_provider.dart
      pages/paywall_page.dart
      widgets/pro_badge.dart, pro_gate.dart
```

### Simulation Engine (`CashFlowCalculator.simulate()`)

Year-by-year projection from current age to age 80. Each year computes:

1. **Active income** (suppressed during unemployment unless retired)
2. **Passive income** (always active)
3. **Unemployment benefit** (capped by benefit months)
4. **Pension** (grows 5%/year after retirement)
5. **Expenses** (inflation-compounded annually)
6. **Asset returns** (blended weighted-average return rate)
7. **Net cash flow** = total income - total expense → added to running assets

Output: `List<YearData>` with fields: year, age, totalIncome, totalExpense, netCashFlow, totalAssets, passiveIncome.

### Chart Types (fl_chart ^0.68.0)

- `LineChart` — total assets trend, passive income vs expenses
- `PieChart` — asset composition (donut style)
- `BarChart` — sensitivity analysis (horizontal bars)
- Future: radar, waterfall, stacked charts (Pro)

### Theme

Material 3 with teal seed (`#0D9488`). Gold (`#F59E0B`) for Pro/warning states. Card-based layout with rounded 16px corners, no elevation.

### Pro Version Architecture

- **Free limits**: ≤3 income/expense entries, ≤2 scenarios
- **ScenarioModel**: stores data snapshots as JSON strings in Hive (avoiding nested generics)
- **Scenarios are standalone snapshots** — editing one doesn't affect others
- **Access control**: `ProGate` widget wraps Pro features; `proStatusProvider` (SharedPreferences) gates access
- **Multi-scenario**: auto-generates optimistic/conservative/extreme from baseline by adjusting income/expense/return/inflation rates

### Important Development Notes

- Hive adapters are **hand-written** using `reader.readMap()`/`writer.writeMap()` (not code-generated)
- `UserProfileModel` stores as singleton: `_box.clear()` then `_box.add()` on each save
- `kIsWeb` check in `main.dart` skips `Hive.initFlutter()` for web (Hive uses IndexedDB)
- Web data is in-memory only — refreshes lose data (debugging only)
- `shared_preferences` is used for `proStatusProvider` only
- No test files exist yet
