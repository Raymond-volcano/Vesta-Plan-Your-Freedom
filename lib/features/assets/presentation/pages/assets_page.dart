import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';
import '../../providers/asset_provider.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetListProvider);
    final f = NumberFormat('#,###');
    final totalValue = assets.fold<double>(0, (s, a) => s + a.currentValue);

    return Scaffold(
      appBar: AppBar(title: const Text('资产管理')),
      body: Column(
        children: [
          // 总资产卡片
          GestureDetector(
          onTap: () => _showEditTotalDialog(context, ref, totalValue, assets),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentCyan, AppTheme.primaryTeal],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '总资产价值',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${f.format(totalValue.toInt())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${assets.length} 项资产（点击可编辑总资产）',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ),
          // 列表
          Expanded(
            child: assets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          '暂无资产',
                          style:
                              TextStyle(color: AppTheme.textHint, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '点击右下角 + 添加资产或负债',
                          style:
                              TextStyle(color: AppTheme.textHint, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return Dismissible(
                        key: Key(asset.id),
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
                            content: Text('删除「${asset.name}」？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('删除',
                                    style:
                                        TextStyle(color: AppTheme.errorRed)),
                              ),
                            ],
                          ),
                        ).then((v) => v ?? false),
                        onDismissed: (_) {
                          ref
                              .read(assetListProvider.notifier)
                              .delete(asset.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            onTap: () => _showEditDialog(
                                context, ref, asset),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentCyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.monetization_on,
                                  color: AppTheme.accentCyan),
                            ),
                            title: Text(
                              asset.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '年化 ${(asset.annualReturnRate * 100).toStringAsFixed(1)}%'
                              '  |  点击编辑',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '¥${f.format(asset.currentValue.toInt())}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '+¥${f.format((asset.currentValue * asset.annualReturnRate).toInt())}/年',
                                  style: const TextStyle(
                                    color: AppTheme.successGreen,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加资产'),
        content: _AssetForm(
          nameController: nameController,
          valueController: valueController,
          rateController: rateController,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final value = double.tryParse(valueController.text) ?? 0;
              final rate = (double.tryParse(rateController.text) ?? 0) / 100;

              if (name.isEmpty || value <= 0) return;

              ref.read(assetListProvider.notifier).add(AssetModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    currentValue: value,
                    annualReturnRate: rate,
                  ));
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, AssetModel asset) {
    final nameController = TextEditingController(text: asset.name);
    final valueController =
        TextEditingController(text: asset.currentValue.toString());
    final rateController = TextEditingController(
        text: (asset.annualReturnRate * 100).toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑资产'),
        content: _AssetForm(
          nameController: nameController,
          valueController: valueController,
          rateController: rateController,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final value = double.tryParse(valueController.text) ?? 0;
              final rate = (double.tryParse(rateController.text) ?? 0) / 100;

              if (name.isEmpty || value <= 0) return;

              final updated = asset.copyWith(
                name: name,
                currentValue: value,
                annualReturnRate: rate,
              );
              ref.read(assetListProvider.notifier).update(asset.id, updated);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showEditTotalDialog(BuildContext context, WidgetRef ref,
      double currentTotal, List<AssetModel> assets) {
    final controller =
        TextEditingController(text: currentTotal.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑总资产'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '总资产价值 (¥)',
            hintText: '如：5000000',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTotal = double.tryParse(controller.text.trim()) ?? 0;
              if (newTotal <= 0) return;

              if (assets.isEmpty) {
                ref.read(assetListProvider.notifier).add(AssetModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: '总资产',
                      currentValue: newTotal,
                      annualReturnRate: 0,
                    ));
              } else if (currentTotal > 0) {
                final ratio = newTotal / currentTotal;
                final updated = assets
                    .map((a) => a.copyWith(
                        currentValue: a.currentValue * ratio))
                    .toList();
                ref.read(assetListProvider.notifier).updateAll(updated);
              } else {
                final eachValue = newTotal / assets.length;
                final updated = assets
                    .map((a) => a.copyWith(currentValue: eachValue))
                    .toList();
                ref.read(assetListProvider.notifier).updateAll(updated);
              }

              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _AssetForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController valueController;
  final TextEditingController rateController;

  const _AssetForm({
    required this.nameController,
    required this.valueController,
    required this.rateController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '名称',
            hintText: '如：房产、股票、存款',
          ),
        ),
        const Gap(12),
        TextField(
          controller: valueController,
          decoration: const InputDecoration(
            labelText: '当前价值 (¥)',
            hintText: '如：1000000',
          ),
          keyboardType: TextInputType.number,
        ),
        const Gap(12),
        TextField(
          controller: rateController,
          decoration: const InputDecoration(
            labelText: '年化收益率 (%)',
            hintText: '如：5.0',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
