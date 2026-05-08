import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../data/models/income_model.dart';
import '../data/models/expense_model.dart';

// ── Income Box ──────────────────────────────────────────────────
final incomeBoxProvider = Provider<Box<IncomeModel>>((ref) {
  return Hive.box<IncomeModel>(AppConstants.incomeBox);
});

final incomeListProvider = StateNotifierProvider<IncomeListNotifier, List<IncomeModel>>((ref) {
  final box = ref.watch(incomeBoxProvider);
  return IncomeListNotifier(box);
});

class IncomeListNotifier extends StateNotifier<List<IncomeModel>> {
  final Box<IncomeModel> _box;

  IncomeListNotifier(this._box) : super(_box.values.toList());

  void add(IncomeModel income) {
    _box.add(income);
    state = _box.values.toList();
  }

  void update(String id, IncomeModel updated) {
    final index = _box.values.toList().indexWhere((e) => e.id == id);
    if (index != -1) {
      _box.putAt(index, updated);
      state = _box.values.toList();
    }
  }

  void delete(String id) {
    final index = _box.values.toList().indexWhere((e) => e.id == id);
    if (index != -1) {
      _box.deleteAt(index);
      state = _box.values.toList();
    }
  }
}

// ── Expense Box ────────────────────────────────────────────────
final expenseBoxProvider = Provider<Box<ExpenseModel>>((ref) {
  return Hive.box<ExpenseModel>(AppConstants.expenseBox);
});

final expenseListProvider = StateNotifierProvider<ExpenseListNotifier, List<ExpenseModel>>((ref) {
  final box = ref.watch(expenseBoxProvider);
  return ExpenseListNotifier(box);
});

class ExpenseListNotifier extends StateNotifier<List<ExpenseModel>> {
  final Box<ExpenseModel> _box;

  ExpenseListNotifier(this._box) : super(_box.values.toList());

  void add(ExpenseModel expense) {
    _box.add(expense);
    state = _box.values.toList();
  }

  void update(String id, ExpenseModel updated) {
    final index = _box.values.toList().indexWhere((e) => e.id == id);
    if (index != -1) {
      _box.putAt(index, updated);
      state = _box.values.toList();
    }
  }

  void delete(String id) {
    final index = _box.values.toList().indexWhere((e) => e.id == id);
    if (index != -1) {
      _box.deleteAt(index);
      state = _box.values.toList();
    }
  }
}
