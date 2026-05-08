import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/income_model.dart';
import '../../data/models/expense_model.dart';
import '../../providers/income_expense_provider.dart';

class IncomeExpensePage extends ConsumerStatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  ConsumerState<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends ConsumerState<IncomeExpensePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收支管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '主动收入'),
            Tab(text: '被动收入'),
            Tab(text: '支出'),
          ],
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.primaryTeal,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomeList(
            type: IncomeType.active,
            onEdit: (income) => _showIncomeDialog(existing: income),
          ),
          _IncomeList(
            type: IncomeType.passive,
            onEdit: (income) => _showIncomeDialog(existing: income),
          ),
          _ExpenseList(
            onEdit: (expense) => _showExpenseDialog(existing: expense),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(_tabController.index),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(int tabIndex) {
    if (tabIndex == 2) {
      _showExpenseDialog();
    } else {
      _showIncomeDialog(
        type: tabIndex == 0 ? IncomeType.active : IncomeType.passive,
      );
    }
  }

  void _showIncomeDialog({IncomeModel? existing, IncomeType? type}) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController =
        TextEditingController(text: existing?.monthlyAmount.toString() ?? '');
    final startYearController = TextEditingController(
        text: existing?.startYear.toString() ?? DateTime.now().year.toString());
    int startMonth = existing?.startMonth ?? 1;
    bool isPermanent = existing?.isPermanent ?? true;
    final endYearController =
        TextEditingController(text: existing?.endYear?.toString() ?? '');
    int? endMonth = existing?.endMonth;
    IncomeType selectedType = existing?.type ?? type ?? IncomeType.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑收入' : '添加收入'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == null) ...[
                  DropdownButtonFormField<IncomeType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: '收入类型'),
                    items: IncomeType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const Gap(12),
                ],
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '如：工资、房租收入',
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '月金额 (¥)',
                    hintText: '如：15000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const Gap(12),
                // 开始年月
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: startYearController,
                        decoration: const InputDecoration(labelText: '开始年'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: startMonth,
                        decoration: const InputDecoration(labelText: '月'),
                        items: List.generate(12, (i) => i + 1).map((m) {
                          return DropdownMenuItem(value: m, child: Text('${m}月'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => startMonth = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                SwitchListTile(
                  title: const Text('永久有效'),
                  value: isPermanent,
                  onChanged: (v) {
                    setDialogState(() => isPermanent = v);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (!isPermanent) ...[
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: endYearController,
                          decoration: const InputDecoration(labelText: '结束年'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: endMonth ?? 12,
                          decoration: const InputDecoration(labelText: '月'),
                          items: List.generate(12, (i) => i + 1).map((m) {
                            return DropdownMenuItem(value: m, child: Text('${m}月'));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => endMonth = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0;
                final startYear = int.tryParse(startYearController.text) ?? DateTime.now().year;
                final endYear = isPermanent ? null : int.tryParse(endYearController.text);

                if (name.isEmpty || amount <= 0) return;

                final income = IncomeModel(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  monthlyAmount: amount,
                  startYear: startYear,
                  startMonth: startMonth,
                  endYear: endYear,
                  endMonth: isPermanent ? null : endMonth,
                  type: selectedType,
                );

                if (isEdit) {
                  ref.read(incomeListProvider.notifier).update(existing.id, income);
                } else {
                  ref.read(incomeListProvider.notifier).add(income);
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDialog({ExpenseModel? existing}) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController =
        TextEditingController(text: existing?.monthlyAmount.toString() ?? '');
    final startYearController =
        TextEditingController(text: existing?.startYear.toString() ?? DateTime.now().year.toString());
    int startMonth = existing?.startMonth ?? 1;
    bool isPermanent = existing?.isPermanent ?? true;
    final endYearController =
        TextEditingController(text: existing?.endYear?.toString() ?? '');
    int? endMonth = existing?.endMonth;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑支出' : '添加支出'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '如：房租、餐饮',
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '月金额 (¥)',
                    hintText: '如：8000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const Gap(12),
                // 开始年月
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: startYearController,
                        decoration: const InputDecoration(labelText: '开始年'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: startMonth,
                        decoration: const InputDecoration(labelText: '月'),
                        items: List.generate(12, (i) => i + 1).map((m) {
                          return DropdownMenuItem(value: m, child: Text('${m}月'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => startMonth = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                SwitchListTile(
                  title: const Text('永久有效'),
                  value: isPermanent,
                  onChanged: (v) => setDialogState(() => isPermanent = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!isPermanent) ...[
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: endYearController,
                          decoration: const InputDecoration(labelText: '结束年'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: endMonth ?? 12,
                          decoration: const InputDecoration(labelText: '月'),
                          items: List.generate(12, (i) => i + 1).map((m) {
                            return DropdownMenuItem(value: m, child: Text('${m}月'));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => endMonth = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text) ?? 0;
                final startYear = int.tryParse(startYearController.text) ?? DateTime.now().year;
                final endYear = isPermanent ? null : int.tryParse(endYearController.text);

                if (name.isEmpty || amount <= 0) return;

                final expense = ExpenseModel(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  monthlyAmount: amount,
                  startYear: startYear,
                  startMonth: startMonth,
                  endYear: endYear,
                  endMonth: isPermanent ? null : endMonth,
                );

                if (isEdit) {
                  ref.read(expenseListProvider.notifier).update(existing.id, expense);
                } else {
                  ref.read(expenseListProvider.notifier).add(expense);
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Income List ────────────────────────────────────────────────
class _IncomeList extends ConsumerWidget {
  final IncomeType type;
  final void Function(IncomeModel income)? onEdit;
  const _IncomeList({required this.type, this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomes = ref.watch(incomeListProvider)
        .where((i) => i.type == type)
        .toList();
    final totalMonthly = incomes.fold<double>(0, (s, i) => s + i.monthlyAmount);
    final f = NumberFormat('#,###');

    return Column(
      children: [
        // 统计摘要
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryTeal, AppTheme.primaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('月总额', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                '¥${f.format(totalMonthly.toInt())}/月',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '年总额 ¥${f.format((totalMonthly * 12).toInt())}/年',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        // 列表
        Expanded(
          child: incomes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无${type.label}记录',
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '点击右下角 + 添加',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    final yearRange = _formatDateRange(
                      income.startYear, income.startMonth,
                      income.endYear, income.endMonth,
                      income.isPermanent,
                    );
                    return Dismissible(
                      key: Key(income.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('删除「${income.name}」？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('删除', style: TextStyle(color: AppTheme.errorRed)),
                            ),
                          ],
                        ),
                      ).then((v) => v ?? false),
                      onDismissed: (_) {
                        ref.read(incomeListProvider.notifier).delete(income.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: onEdit != null ? () => onEdit!(income) : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            income.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(yearRange),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥${f.format(income.monthlyAmount.toInt())}/月',
                                style: TextStyle(
                                  color: type == IncomeType.passive
                                      ? AppTheme.successGreen
                                      : AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '¥${f.format(income.annualAmount.toInt())}/年',
                                style: const TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Expense List ───────────────────────────────────────────────
class _ExpenseList extends ConsumerWidget {
  final void Function(ExpenseModel expense)? onEdit;
  const _ExpenseList({this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final totalMonthly = expenses.fold<double>(0, (s, e) => s + e.monthlyAmount);
    final f = NumberFormat('#,###');

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.errorRed, Color(0xFFF87171)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('月总支出', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                '¥${f.format(totalMonthly.toInt())}/月',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '年总支出 ¥${f.format((totalMonthly * 12).toInt())}/年',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无支出记录',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '点击右下角 + 添加',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final yearRange = _formatDateRange(
                      expense.startYear, expense.startMonth,
                      expense.endYear, expense.endMonth,
                      expense.isPermanent,
                    );
                    return Dismissible(
                      key: Key(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('删除「${expense.name}」？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('删除', style: TextStyle(color: AppTheme.errorRed)),
                            ),
                          ],
                        ),
                      ).then((v) => v ?? false),
                      onDismissed: (_) {
                        ref.read(expenseListProvider.notifier).delete(expense.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: onEdit != null ? () => onEdit!(expense) : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            expense.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(yearRange),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥${f.format(expense.monthlyAmount.toInt())}/月',
                                style: const TextStyle(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '¥${f.format(expense.annualAmount.toInt())}/年',
                                style: const TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String _formatDateRange(
  int startYear, int startMonth,
  int? endYear, int? endMonth,
  bool isPermanent,
) {
  final start = '$startYear.${startMonth.toString().padLeft(2, '0')}';
  if (isPermanent) return '$start → 永久';
  final end = '${endYear}.${endMonth?.toString().padLeft(2, '0') ?? '??'}';
  return '$start → $end';
}
