import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/services/cash_flow_calculator.dart';
import '../../providers/result_provider.dart';
import '../../../profile/data/models/user_profile_model.dart';

/// 深度个性化分析报告
class DeepInsight extends StatelessWidget {
  final UserProfileModel profile;
  final List<YearData> simulation;
  final List<SensitivityItem> sensitivity;
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;

  const DeepInsight({
    required this.profile,
    required this.simulation,
    required this.sensitivity,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
  });

  @override
  Widget build(BuildContext context) {
    final last = simulation.lastOrNull;
    if (last == null) return const SizedBox.shrink();

    final insights = _generateInsights();
    final milestones = _calculateMilestones();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.assessment, '财务健康评分'),
        const SizedBox(height: 12),
        _HealthScoreCard(score: insights.score, label: insights.scoreLabel, detail: insights.scoreDetail),
        const SizedBox(height: 20),
        _sectionHeader(Icons.timeline, '关键里程碑'),
        const SizedBox(height: 12),
        ...milestones.map((m) => _MilestoneRow(milestone: m)),
        const SizedBox(height: 20),
        _sectionHeader(Icons.tips_and_updates, '个性化建议'),
        const SizedBox(height: 12),
        ...insights.recommendations.map((r) => _RecommendationCard(recommendation: r)),
        const SizedBox(height: 20),
        _sectionHeader(Icons.warning_amber, '风险提示'),
        const SizedBox(height: 12),
        ...insights.risks.map((r) => _RiskCard(risk: r)),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryTeal),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  _InsightResult _generateInsights() {
    final recommendations = <_Recommendation>[];
    final risks = <_Risk>[];
    final savingsRate = totalMonthlyIncome > 0
        ? 1 - (totalMonthlyExpense / totalMonthlyIncome)
        : 0.0;

    // 评分逻辑
    int score = 60;
    final reasons = <String>[];

    // 是否资产耗尽
    bool depleted = false;
    int depletionAge = 0;
    for (final y in simulation) {
      if (y.totalAssets < 0) {
        depleted = true;
        depletionAge = y.age;
        break;
      }
    }
    if (!depleted) {
      score += 20;
      reasons.add('资产可持续至 ${simulation.last.age} 岁');
    } else {
      score -= 20;
      reasons.add('资产将在 $depletionAge 岁耗尽');
      risks.add(_Risk(
        title: '资产耗尽风险',
        description: '你的资产预计在 $depletionAge 岁耗尽，届时将无法维持当前生活水平。建议提高储蓄率或延迟退休。',
        severity: _RiskSeverity.high,
      ));
    }

    // 财务自由达成
    bool achievedFreedom = false;
    int freedomAge = 0;
    for (final y in simulation) {
      if (y.passiveIncome >= y.totalExpense) {
        achievedFreedom = true;
        freedomAge = y.age;
        break;
      }
    }
    if (achievedFreedom) {
      score += 15;
      reasons.add('预计 $freedomAge 岁实现财务自由');
    } else {
      score -= 10;
      reasons.add('目前无法在 80 岁前实现财务自由');
    }

    // 储蓄率评分
    if (savingsRate >= 0.4) {
      score += 10;
      reasons.add('储蓄率${(savingsRate * 100).toStringAsFixed(0)}%，非常健康');
    } else if (savingsRate >= 0.2) {
      score += 5;
      reasons.add('储蓄率${(savingsRate * 100).toStringAsFixed(0)}%，处于健康区间');
    } else if (savingsRate >= 0.1) {
      reasons.add('储蓄率${(savingsRate * 100).toStringAsFixed(0)}%，建议提升至 20% 以上');
      recommendations.add(_Recommendation(
        title: '提高储蓄率',
        description: '当前储蓄率仅 ${(savingsRate * 100).toStringAsFixed(0)}%。建议将月储蓄率提升至 20-30%，'
            '可显著改善最终资产状况。每多存 10% 的收入，退休时资产可能增加 50% 以上。',
        icon: Icons.savings,
        color: AppTheme.primaryTeal,
      ));
    } else {
      score -= 10;
      reasons.add('支出超过收入，需要立即调整');
      recommendations.add(_Recommendation(
        title: '紧急：缩减支出',
        description: '当前支出(${(totalMonthlyExpense).toStringAsFixed(0)}元/月)已超过收入(${(totalMonthlyIncome).toStringAsFixed(0)}元/月)。'
            '建议立即审查非必要开支，优先削减可选消费。',
        icon: Icons.warning_amber,
        color: AppTheme.errorRed,
      ));
    }

    // 基于灵敏度分析的建议
    if (sensitivity.isNotEmpty && !depleted) {
      final biggestFactor = sensitivity.first;
      if (biggestFactor.impactPercent.abs() >= 20) {
        if (biggestFactor.impactPercent < 0) {
          recommendations.add(_Recommendation(
            title: '重点关注：${biggestFactor.label}',
            description: '「${biggestFactor.label}」对你的财务目标影响最大（${biggestFactor.impactPercent.toStringAsFixed(1)}%）。'
                '建议优先管理这方面的风险，制定应对预案。',
            icon: Icons.track_changes,
            color: AppTheme.warmGold,
          ));
        } else {
          recommendations.add(_Recommendation(
            title: '最大机遇：${biggestFactor.label}',
            description: '「${biggestFactor.label}」对你的财富增长最有利（+${biggestFactor.impactPercent.toStringAsFixed(1)}%）。'
                '可以重点在这方面的优化上投入精力。',
            icon: Icons.trending_up,
            color: AppTheme.successGreen,
          ));
        }
      }
    }

    // 退休年龄建议
    if (!depleted && profile.retirementAge < 65) {
      final currentYearsToRetirement = profile.retirementAge - profile.currentAge;
      if (currentYearsToRetirement > 0) {
        recommendations.add(_Recommendation(
          title: '退休规划',
          description: '距离计划退休还有 $currentYearsToRetirement 年。建议每 3 年重新评估一次计划，'
              '根据实际情况调整储蓄和投资策略。考虑渐进式退休（先半退再全退）可降低财务压力。',
          icon: Icons.event,
          color: AppTheme.accentCyan,
        ));
      }
    }

    // 投资多样化建议
    recommendations.add(_Recommendation(
      title: '投资多样化',
      description: '不要把所有资金放在单一资产类别。建议分散投资于股票、债券、基金等不同风险等级的产品。'
          '随着年龄增长，逐步降低高风险资产的比例。',
      icon: Icons.account_balance,
      color: AppTheme.primaryTeal,
    ));

    // 风险提示
    if (savingsRate < 0.2 && !depleted) {
      risks.add(_Risk(
        title: '储蓄不足风险',
        description: '低储蓄率意味着抗风险能力较弱。建议建立至少 6 个月支出的应急基金，'
            '以应对失业、疾病等突发情况。',
        severity: _RiskSeverity.medium,
      ));
    }

    if (profile.annualInflationRate > 0.03) {
      risks.add(_Risk(
        title: '通胀风险',
        description: '你设定的通胀率(${(profile.annualInflationRate * 100).toStringAsFixed(1)}%)偏高。'
            '高通胀会显著侵蚀购买力，建议投资回报率至少超过通胀率 3-4% 才能实现资产增值。',
        severity: _RiskSeverity.medium,
      ));
    }

    // 评分等级
    String scoreLabel;
    if (score >= 90) scoreLabel = '非常健康';
    else if (score >= 75) scoreLabel = '良好';
    else if (score >= 60) scoreLabel = '一般';
    else if (score >= 40) scoreLabel = '需要关注';
    else scoreLabel = '急需调整';

    final scoreDetail = reasons.join(' · ');

    return _InsightResult(
      score: score.clamp(0, 100),
      scoreLabel: scoreLabel,
      scoreDetail: scoreDetail,
      recommendations: recommendations,
      risks: risks,
    );
  }

  List<_Milestone> _calculateMilestones() {
    final milestones = <_Milestone>[];
    final f = NumberFormat('#,###');

    // 各里程碑年龄
    int? passiveIncome25Age;
    int? passiveIncome50Age;
    int? passiveIncome75Age;
    int? freedomAge;
    int? depletionAge;

    for (final y in simulation) {
      if (y.totalExpense > 0) {
        final ratio = y.passiveIncome / y.totalExpense;
        if (ratio >= 0.25 && passiveIncome25Age == null) passiveIncome25Age = y.age;
        if (ratio >= 0.5 && passiveIncome50Age == null) passiveIncome50Age = y.age;
        if (ratio >= 0.75 && passiveIncome75Age == null) passiveIncome75Age = y.age;
        if (ratio >= 1.0 && freedomAge == null) freedomAge = y.age;
      }
      if (y.totalAssets < 0 && depletionAge == null) {
        depletionAge = y.age;
      }
    }

    if (passiveIncome25Age != null) {
      milestones.add(_Milestone(
        age: passiveIncome25Age,
        label: '被动收入覆盖 25% 支出',
        color: AppTheme.accentCyan,
        icon: Icons.trending_up,
      ));
    }
    if (passiveIncome50Age != null) {
      milestones.add(_Milestone(
        age: passiveIncome50Age,
        label: '被动收入覆盖 50% 支出',
        color: AppTheme.primaryTeal,
        icon: Icons.trending_up,
      ));
    }
    if (passiveIncome75Age != null) {
      milestones.add(_Milestone(
        age: passiveIncome75Age,
        label: '被动收入覆盖 75% 支出',
        color: AppTheme.successGreen,
        icon: Icons.trending_up,
      ));
    }
    if (freedomAge != null) {
      milestones.add(_Milestone(
        age: freedomAge,
        label: '财务自由！被动收入 ≥ 支出',
        color: AppTheme.warmGold,
        icon: Icons.emoji_events,
      ));
    }
    if (depletionAge != null) {
      milestones.add(_Milestone(
        age: depletionAge,
        label: '资产耗尽',
        color: AppTheme.errorRed,
        icon: Icons.warning,
      ));
    }
    if (depletionAge == null && simulation.isNotEmpty) {
      milestones.add(_Milestone(
        age: simulation.last.age,
        label: '模拟期末仍有资产 ¥${f.format(simulation.last.totalAssets.toInt())}',
        color: AppTheme.successGreen,
        icon: Icons.check_circle,
      ));
    }

    return milestones;
  }
}

// ── 内部模型 ────────────────────────────────────────────────

class _InsightResult {
  final int score;
  final String scoreLabel;
  final String scoreDetail;
  final List<_Recommendation> recommendations;
  final List<_Risk> risks;

  const _InsightResult({
    required this.score,
    required this.scoreLabel,
    required this.scoreDetail,
    required this.recommendations,
    required this.risks,
  });
}

class _Recommendation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _Recommendation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

enum _RiskSeverity { medium, high }

class _Risk {
  final String title;
  final String description;
  final _RiskSeverity severity;

  const _Risk({required this.title, required this.description, required this.severity});
}

class _Milestone {
  final int age;
  final String label;
  final Color color;
  final IconData icon;

  const _Milestone({required this.age, required this.label, required this.color, required this.icon});
}

// ── UI 组件 ─────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final int score;
  final String label;
  final String detail;

  const _HealthScoreCard({required this.score, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75 ? AppTheme.successGreen
        : score >= 50 ? AppTheme.warmGold
        : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.15),
                  color: color,
                ),
                Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final _Milestone milestone;
  const _MilestoneRow({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: milestone.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(milestone.icon, size: 16, color: milestone.color),
          ),
          const SizedBox(width: 12),
          Text('${milestone.age} 岁', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(milestone.label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final _Recommendation recommendation;
  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: recommendation.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: recommendation.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: recommendation.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(recommendation.icon, size: 18, color: recommendation.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(recommendation.description,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final _Risk risk;
  const _RiskCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = risk.severity == _RiskSeverity.high
        ? AppTheme.errorRed
        : risk.severity == _RiskSeverity.medium
            ? AppTheme.warmGold
            : AppTheme.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 4),
                Text(risk.description,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
