import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/pro_status_provider.dart';
import 'pro_badge.dart';

/// Pro 功能拦截组件
///
/// 包裹需要 Pro 权限的功能：
/// ```dart
/// ProGate(
///   child: AdvancedChart(),
///   title: '高级图表',
/// )
/// ```
class ProGate extends ConsumerWidget {
  final Widget child;
  final String? title;
  final String? description;
  final Widget? lockedChild;

  const ProGate({
    super.key,
    required this.child,
    this.title,
    this.description,
    this.lockedChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proStatus = ref.watch(proStatusProvider);

    if (proStatus.isValid) {
      return child;
    }

    if (lockedChild != null) return lockedChild!;

    return _buildLocked(context);
  }

  Widget _buildLocked(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showUpgradeSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const ProBadge(),
                        if (title != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warmGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '升级',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warmGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpgradeSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _PaywallPage(),
      ),
    );
  }
}

/// 简化版升级页面（内嵌在 ProGate 中）
class _PaywallPage extends StatelessWidget {
  const _PaywallPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('升级 Pro')),
      body: const Center(
        child: Text('完整版升级页面待接入'),
      ),
    );
  }
}
