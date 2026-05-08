import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/pro/pro_config.dart';
import '../../data/models/scenario_model.dart';
import '../../providers/scenario_provider.dart';
import '../../providers/pro_status_provider.dart';
import 'paywall_page.dart';

/// 方案列表页面
class ScenarioListPage extends ConsumerWidget {
  const ScenarioListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(scenarioListProvider);
    final activeId = ref.watch(activeScenarioIdProvider);
    final proStatus = ref.watch(proStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('财务方案'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存当前方案',
            onPressed: () => _saveCurrentScenario(context, ref),
          ),
        ],
      ),
      body: scenarios.isEmpty
          ? _buildEmpty(context, ref)
          : _buildList(context, ref, scenarios, activeId, proStatus),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            '还没有保存方案',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮将当前数据保存为方案',
            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _saveCurrentScenario(context, ref),
            icon: const Icon(Icons.save),
            label: const Text('保存当前方案'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<ScenarioModel> scenarios,
    String? activeId,
    ProStatus proStatus,
  ) {
    final canAdd = proStatus.isValid || scenarios.length < ProConfig.freeMaxScenarios;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!proStatus.isValid && scenarios.length >= ProConfig.freeMaxScenarios)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: AppTheme.warmGold.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.warmGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '免费版最多保存 $ProConfig.freeMaxScenarios 个方案，升级 Pro 可创建无限方案',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ...scenarios.map((s) => _ScenarioCard(
              scenario: s,
              isActive: s.id == activeId,
              onTap: () => _switchScenario(context, ref, s.id),
              onRename: () => _renameScenario(context, ref, s.id),
              onDuplicate: () => _duplicateScenario(context, ref, s),
              onDelete: () => _deleteScenario(context, ref, s.id),
            )),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: canAdd
                ? () => _saveCurrentScenario(context, ref)
                : () => _showUpgradePrompt(context),
            icon: const Icon(Icons.add),
            label: const Text('新建方案'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryTeal,
              side: const BorderSide(color: AppTheme.primaryTeal),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (scenarios.isNotEmpty) ...[
          const Gap(8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _generateScenarios(context, ref, scenarios.first.id),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成多情景'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.warmGold,
                side: const BorderSide(color: AppTheme.warmGold),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (scenarios.length >= 2) ...[
            const Gap(8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/scenarios/compare'),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('对比方案'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _generateScenarios(BuildContext context, WidgetRef ref, String baselineId) async {
    final proStatus = ref.read(proStatusProvider);
    if (!proStatus.isValid) {
      _showUpgradePrompt(context);
      return;
    }
    final scenarios = ref.read(scenarioListProvider);
    if (scenarios.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多同时对比 5 个方案，请先删除一些')),
      );
      return;
    }
    await ref.read(scenarioListProvider.notifier).generateScenarios(baselineId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已生成 3 个情景方案'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _saveCurrentScenario(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存方案'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入方案名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(scenarioListProvider.notifier).createFromCurrentData(name: name);
    }
  }

  void _switchScenario(BuildContext context, WidgetRef ref, String id) async {
    await ref.read(scenarioListProvider.notifier).switchTo(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已切换方案'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _renameScenario(BuildContext context, WidgetRef ref, String id) {
    final scenarios = ref.read(scenarioListProvider);
    final scenario = scenarios.where((s) => s.id == id).firstOrNull;
    if (scenario == null) return;
    final controller = TextEditingController(text: scenario.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) ref.read(scenarioListProvider.notifier).rename(id, name);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _duplicateScenario(BuildContext context, WidgetRef ref, ScenarioModel scenario) {
    final controller = TextEditingController(text: '${scenario.name} (副本)');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('复制方案'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) ref.read(scenarioListProvider.notifier).duplicate(scenario.id, name);
              Navigator.pop(ctx);
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _deleteScenario(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除方案'),
        content: const Text('确定要删除这个方案吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(scenarioListProvider.notifier).delete(id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showUpgradePrompt(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
  }
}

// ── 方案卡片 ──────────────────────────────────────────────────
class _ScenarioCard extends StatelessWidget {
  final ScenarioModel scenario;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ScenarioCard({
    required this.scenario,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label = ScenarioLabel.fromJson(scenario.label);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: AppTheme.primaryTeal, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _labelColor(label).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_labelIcon(label), color: _labelColor(label)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(scenario.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('当前',
                                style: TextStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (label != ScenarioLabel.custom)
                          Text(label.label, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                        if (label != ScenarioLabel.custom) ...[
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.textHint)),
                          const SizedBox(width: 8),
                        ],
                        Text(_formatDate(scenario.updatedAt),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'switch': onTap(); break;
                    case 'rename': onRename(); break;
                    case 'duplicate': onDuplicate(); break;
                    case 'delete': onDelete(); break;
                  }
                },
                itemBuilder: (_) => [
                  if (!isActive)
                    const PopupMenuItem(value: 'switch', child: Text('切换到此方案')),
                  const PopupMenuItem(value: 'rename', child: Text('重命名')),
                  const PopupMenuItem(value: 'duplicate', child: Text('复制')),
                  const PopupMenuItem(value: 'delete',
                      child: Text('删除', style: TextStyle(color: AppTheme.errorRed))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _labelColor(ScenarioLabel label) {
    switch (label) {
      case ScenarioLabel.baseline: return AppTheme.primaryTeal;
      case ScenarioLabel.optimistic: return AppTheme.successGreen;
      case ScenarioLabel.conservative: return AppTheme.warmGold;
      case ScenarioLabel.extreme: return AppTheme.errorRed;
      case ScenarioLabel.custom: return AppTheme.accentCyan;
    }
  }

  IconData _labelIcon(ScenarioLabel label) {
    switch (label) {
      case ScenarioLabel.baseline: return Icons.balance;
      case ScenarioLabel.optimistic: return Icons.trending_up;
      case ScenarioLabel.conservative: return Icons.trending_flat;
      case ScenarioLabel.extreme: return Icons.trending_down;
      case ScenarioLabel.custom: return Icons.edit;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

