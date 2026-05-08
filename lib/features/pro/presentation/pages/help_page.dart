import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 帮助手册 — 介绍 App 各功能的使用方法
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _sections = [
    _HelpSection(
      icon: Icons.dashboard,
      title: '首页',
      items: [
        '总资产：汇总你添加的所有资产总值，点击可进入资产管理页面',
        '被动月收入：所有被动收入（理财、房租等）的月度总和',
        '主动月收入：所有主动收入（工资、兼职等）的月度总和',
        '月净现金流：主动收入 + 被动收入 - 总支出',
        '退休倒计时：显示距离计划退休还有多少年',
      ],
    ),
    _HelpSection(
      icon: Icons.account_balance,
      title: '收支管理',
      items: [
        '分三个标签页：主动收入、被动收入、支出',
        '点击右下角 + 按钮添加条目，填写名称、月金额、起止时间',
        '点击已有条目可编辑修改',
        '左右滑动条目可删除（需确认）',
        '免费版最多添加 3 条收支，Pro 版无限制',
      ],
    ),
    _HelpSection(
      icon: Icons.account_balance_wallet,
      title: '资产管理',
      items: [
        '添加你的各类资产（存款、股票、房产、理财等）',
        '每项资产需填写名称、当前价值、年化收益率',
        '顶部总额卡片可一键修改总资产，已有资产按比例调整',
        '点击条目可编辑，滑动可删除',
      ],
    ),
    _HelpSection(
      icon: Icons.person,
      title: '个人信息设置',
      items: [
        '性别：影响法定退休年龄的计算（中国渐进式延迟退休政策）',
        '年龄：当前年龄，用于计算退休倒计时',
        '计划退休年龄：你希望退休的年龄（可早于或晚于法定年龄）',
        '通胀率：每年物价上涨幅度，默认 3%，影响未来支出计算',
        '失业模拟：可设置失业开始时间、失业金金额、额外支出',
        '养老金：退休后每月可领取的养老金金额（每年增长5%）',
      ],
    ),
    _HelpSection(
      icon: Icons.analytics,
      title: '模拟结果',
      items: [
        '总资产走势图：展示从当前到80岁的资产变化曲线',
        '被动收入 vs 总支出：对比两条曲线，交叉点即"财务自由点"',
        '资产构成饼图：查看各资产占总资产的比重',
        '制约因素分析：柱状图显示每个因素变化对最终资产的影响程度',
        '分析建议：根据数据自动生成个性化的财务建议',
        '逐年数据：可滚动查看每一年的详细资产和现金流数据',
        '右上角开关可模拟失业情景',
      ],
    ),
    _HelpSection(
      icon: Icons.compare_arrows,
      title: '方案管理 (Pro)',
      items: [
        '在"我的"页面进入方案管理',
        '点击"保存当前方案"将当前数据存为一个方案',
        '可创建多个方案，在不同方案间切换',
        '切换方案时，当前数据会自动替换为方案数据',
        '支持重命名、复制和删除操作',
        'Pro 版可无限保存方案',
      ],
    ),
    _HelpSection(
      icon: Icons.workspace_premium,
      title: 'Pro 版功能',
      items: [
        '无限收支条目：不再受 3 条限制',
        '多情景模拟：自动生成乐观/基准/保守/极端 4 种情景',
        '无限方案保存与对比',
        'PDF / Excel 导出：一键导出详细财务报告',
        '高级图表：雷达图、堆积图等可视化分析',
        '城市模板：北上广深默认参数快速初始化',
        '语音输入：语音录入收支数据',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助手册'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头部
          const SizedBox(height: 8),
          const Icon(Icons.help_outline, size: 48, color: AppTheme.primaryTeal),
          const SizedBox(height: 12),
          const Text(
            '财务自由希望 · 使用指南',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '一步步教你使用各个功能，更好地规划财务自由之路',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // 推荐使用流程
          Card(
            color: AppTheme.primaryTeal.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.route, color: AppTheme.primaryTeal, size: 18),
                      SizedBox(width: 8),
                      Text('推荐使用流程',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _step(1, '设置个人信息', '在"我的"页面填写年龄、性别、退休计划'),
                  _step(2, '添加收支', '在"收支管理"中添加你的收入和支出项目'),
                  _step(3, '添加资产', '在"资产管理"中添加你的各类资产'),
                  _step(4, '查看结果', '在"结果"页面查看模拟数据和图表分析'),
                  _step(5, '优化方案', '根据分析建议调整参数，保存不同方案对比'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 各功能说明
          ..._sections.map((s) => _buildSection(s)),
        ],
      ),
    );
  }

  Widget _step(int number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_HelpSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(section.icon, color: AppTheme.primaryTeal, size: 20),
                  const SizedBox(width: 10),
                  Text(section.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              for (final item in section.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(color: AppTheme.primaryTeal)),
                      Expanded(
                        child: Text(item,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSection {
  final IconData icon;
  final String title;
  final List<String> items;
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.items,
  });
}
