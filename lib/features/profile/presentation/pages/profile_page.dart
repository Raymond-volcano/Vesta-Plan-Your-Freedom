import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../income_expense/providers/income_expense_provider.dart';
import '../../../income_expense/data/models/expense_model.dart';
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
