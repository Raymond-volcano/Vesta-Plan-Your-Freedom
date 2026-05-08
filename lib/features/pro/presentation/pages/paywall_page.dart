import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/pro_status_provider.dart';

/// Pro 升级页面 — 展示 Pro 功能列表 + 解锁入口
class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  static const _features = [
    _FeatureItem(
      icon: Icons.account_balance_wallet,
      title: '无限收支条目',
      desc: '自由添加收入与支出项目，不受数量限制',
    ),
    _FeatureItem(
      icon: Icons.compare_arrows,
      title: '多情景模拟',
      desc: '同时查看乐观、基准、保守、极端 4 种财务情景',
    ),
    _FeatureItem(
      icon: Icons.save_alt,
      title: '无限方案保存',
      desc: '保存多个财务方案，随时切换和对比',
    ),
    _FeatureItem(
      icon: Icons.compare,
      title: '方案对比分析',
      desc: '并排对比不同方案的资产走势和关键指标',
    ),
    _FeatureItem(
      icon: Icons.bar_chart,
      title: '高级图表',
      desc: '雷达图、堆积图等高级可视化分析',
    ),
    _FeatureItem(
      icon: Icons.picture_as_pdf,
      title: 'PDF / Excel 导出',
      desc: '一键导出详细财务报告，方便分享和存档',
    ),
    _FeatureItem(
      icon: Icons.location_city,
      title: '城市模板',
      desc: '北上广深等城市默认参数，快速初始化方案',
    ),
    _FeatureItem(
      icon: Icons.mic,
      title: '语音输入',
      desc: '用语音快速录入收支数据',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('升级 Pro'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头部
          const SizedBox(height: 8),
          const Icon(Icons.workspace_premium, size: 64, color: AppTheme.warmGold),
          const SizedBox(height: 12),
          const Text(
            '财务自由希望 Pro',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '解锁全部高级功能，更好地规划你的财务自由之路',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // 功能列表
          ..._features.map((f) => _buildFeatureRow(f)),
          const SizedBox(height: 24),

          // 解锁按钮
          _buildUnlockButton(context, ref),
          const SizedBox(height: 12),

          // 恢复购买
          Center(
            child: TextButton(
              onPressed: () => ref.read(proStatusProvider.notifier).restorePurchase(),
              child: const Text(
                '恢复购买',
                style: TextStyle(fontSize: 13, color: AppTheme.textHint),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          await ref.read(proStatusProvider.notifier).unlockPro();
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎉 已解锁 Pro 版！')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.warmGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          '解锁 Pro 版',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
