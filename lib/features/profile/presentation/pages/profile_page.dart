import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../income_expense/providers/income_expense_provider.dart';
import '../../data/models/user_profile_model.dart';
import '../../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final expenses = ref.watch(expenseListProvider);
    final f = NumberFormat('#,###');
    final totalMonthlyExpense =
        expenses.fold<double>(0, (s, e) => s + e.monthlyAmount);
    final statutory =
        UserProfileModel.statutoryAge(profile.currentAge, profile.gender);

    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 基本信息 ──────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.primaryTeal),
                      SizedBox(width: 8),
                      Text('基本信息',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 性别选择
                  const Text('性别',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: Gender.values.map((g) {
                      final selected = profile.gender == g;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: g == Gender.male ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(profileProvider.notifier)
                                .updateGender(g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryTeal
                                    : AppTheme.primaryTeal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primaryTeal
                                      : AppTheme.dividerColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    g == Gender.male
                                        ? Icons.male
                                        : Icons.female,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    g.label,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // 年龄滑块
                  _AgeSlider(
                    label: '当前年龄',
                    value: profile.currentAge.toDouble(),
                    min: 18,
                    max: 70,
                    onChanged: (v) {
                      ref.read(profileProvider.notifier).updateAge(v.toInt());
                    },
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),
          // ── 退休年龄 ──────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event, color: AppTheme.warmGold),
                      SizedBox(width: 8),
                      Text('退休设置',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 法定退休年龄
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warmGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance,
                                color: AppTheme.warmGold, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '法定退休年龄 ${statutory} 岁',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppTheme.warmGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '根据现行渐进式延迟退休政策自动计算',
                          style: const TextStyle(
                              color: AppTheme.textHint, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 计划退休年龄（可微调）
                  const Text('计划退休年龄',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: profile.retirementAge
                              .clamp(profile.currentAge + 1, 80)
                              .toDouble(),
                          min: profile.currentAge + 1,
                          max: 80,
                          divisions: 80 - profile.currentAge - 1,
                          activeColor: AppTheme.warmGold,
                          onChanged: (v) {
                            ref
                                .read(profileProvider.notifier)
                                .updateRetirementAge(v.toInt());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${profile.retirementAge}岁',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: AppTheme.primaryTeal),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '距离退休还有 ${profile.yearsToRetirement} 年',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '计划 ${profile.retirementAge} 岁退休',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),
          // ── 失业模拟设置 ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.work_off, color: AppTheme.warmGold),
                      SizedBox(width: 8),
                      Text('失业模拟设置',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _UnemploymentForm(profile: profile),
                ],
              ),
            ),
          ),
          const Gap(16),
          // ── 养老金设置 ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.elderly, color: AppTheme.primaryTeal),
                      SizedBox(width: 8),
                      Text('养老金设置',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PensionForm(profile: profile),
                ],
              ),
            ),
          ),
          const Gap(16),
          // ── 财务自由目标 ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flag, color: AppTheme.successGreen),
                      SizedBox(width: 8),
                      Text('财务自由目标',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 目标被动收入 = 当前月支出
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('目标被动月收入',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(
                                '¥${f.format(totalMonthlyExpense.toInt())}/月',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '= 当前月支出',
                                style: const TextStyle(
                                    color: AppTheme.textHint, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.accentCyan, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '当被动收入 ≥ 月支出时，即实现财务自由。'
                            '请先在「收支」中添加您的支出记录。',
                            style:
                                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),
          // ── 使用说明 ──────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.accentCyan),
                      SizedBox(width: 8),
                      Text('使用说明',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. 设置性别和当前年龄，退休年龄自动计算\n'
                    '2. 在「收支管理」中添加收入与支出\n'
                    '3. 在「资产管理」中添加资产\n'
                    '4. 前往「结果」页查看财务自由模拟',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.8,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 失业模拟表单 ──────────────────────────────────────────────
class _UnemploymentForm extends ConsumerStatefulWidget {
  final UserProfileModel profile;
  const _UnemploymentForm({required this.profile});

  @override
  ConsumerState<_UnemploymentForm> createState() => _UnemploymentFormState();
}

class _UnemploymentFormState extends ConsumerState<_UnemploymentForm> {
  late TextEditingController _startYearController;
  late int? _startMonth;
  late TextEditingController _benefitController;
  late TextEditingController _benefitMonthsController;
  late TextEditingController _extraExpenseController;
  late TextEditingController _extraExpenseMonthsController;

  @override
  void initState() {
    super.initState();
    _startYearController = TextEditingController(
      text: widget.profile.unemploymentStartYear?.toString() ?? '',
    );
    _startMonth = widget.profile.unemploymentStartMonth;
    _benefitController = TextEditingController(
      text: widget.profile.unemploymentBenefit > 0
          ? widget.profile.unemploymentBenefit.toStringAsFixed(0)
          : '',
    );
    _benefitMonthsController = TextEditingController(
      text: widget.profile.unemploymentBenefitMonths > 0
          ? widget.profile.unemploymentBenefitMonths.toString()
          : '',
    );
    _extraExpenseController = TextEditingController(
      text: widget.profile.unemploymentExtraExpense > 0
          ? widget.profile.unemploymentExtraExpense.toStringAsFixed(0)
          : '',
    );
    _extraExpenseMonthsController = TextEditingController(
      text: widget.profile.unemploymentExtraExpenseMonths > 0
          ? widget.profile.unemploymentExtraExpenseMonths.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _startYearController.dispose();
    _benefitController.dispose();
    _benefitMonthsController.dispose();
    _extraExpenseController.dispose();
    _extraExpenseMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 失业开始年月
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _startYearController,
                decoration: const InputDecoration(
                  labelText: '失业开始年份',
                  hintText: '如：2026',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  ref.read(profileProvider.notifier).updateUnemploymentStartYear(
                    int.tryParse(v),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: _startMonth,
                decoration: const InputDecoration(labelText: '月'),
                items: [const DropdownMenuItem(value: null, child: Text('')), ...List.generate(12, (i) => i + 1).map((m) {
                  return DropdownMenuItem(value: m, child: Text('${m}月'));
                }).toList()],
                onChanged: (v) {
                  setState(() => _startMonth = v);
                  ref.read(profileProvider.notifier).updateUnemploymentStartMonth(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 失业金
        TextField(
          controller: _benefitController,
          decoration: const InputDecoration(
            labelText: '每月失业金 (¥)',
            hintText: '如：3000',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            ref.read(profileProvider.notifier).updateUnemploymentBenefit(
              double.tryParse(v) ?? 0,
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _benefitMonthsController,
          decoration: const InputDecoration(
            labelText: '失业金领取月数',
            hintText: '如：24',
            suffixText: '个月',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            ref.read(profileProvider.notifier).updateUnemploymentBenefitMonths(
              int.tryParse(v) ?? 0,
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Text('失业额外支出',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('失业后可能需要自己承担保险、医保等费用',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(
          controller: _extraExpenseController,
          decoration: const InputDecoration(
            labelText: '每月额外支出 (¥)',
            hintText: '如：2000',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            ref.read(profileProvider.notifier).updateUnemploymentExtraExpense(
              double.tryParse(v) ?? 0,
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _extraExpenseMonthsController,
          decoration: const InputDecoration(
            labelText: '额外支出持续月数',
            hintText: '如：6',
            suffixText: '个月',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            ref.read(profileProvider.notifier).updateUnemploymentExtraExpenseMonths(
              int.tryParse(v) ?? 0,
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        // 通胀率
        _InflationSlider(
          value: widget.profile.annualInflationRate,
          onChanged: (v) {
            ref.read(profileProvider.notifier).updateInflationRate(v);
          },
        ),
      ],
    );
  }
}

// ── 通胀率滑块 ──────────────────────────────────────────────
class _InflationSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _InflationSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('年通胀率',
                style: TextStyle(color: AppTheme.textSecondary)),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 0.10),
          min: 0,
          max: 0.10,
          divisions: 20,
          activeColor: AppTheme.warmGold,
          onChanged: onChanged,
        ),
        const Text('用于模拟每年支出增长',
            style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
      ],
    );
  }
}

// ── 养老金表单 ──────────────────────────────────────────────
class _PensionForm extends ConsumerStatefulWidget {
  final UserProfileModel profile;
  const _PensionForm({required this.profile});

  @override
  ConsumerState<_PensionForm> createState() => _PensionFormState();
}

class _PensionFormState extends ConsumerState<_PensionForm> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.profile.pensionAmount > 0
          ? widget.profile.pensionAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: '每月养老金 (¥)',
            hintText: '如：5000',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            ref.read(profileProvider.notifier).updatePensionAmount(
              double.tryParse(v) ?? 0,
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentCyan, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '养老金每年按 5% 自动增长',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgeSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _AgeSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: AppTheme.textSecondary)),
            Text(
              '${value.toInt()} 岁',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppTheme.primaryTeal,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
