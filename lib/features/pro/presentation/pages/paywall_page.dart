import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 升级页面 — 已全部免费开放
///
/// 本 app 所有功能免费公开，通过 AdSense 广告变现。
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('财务自由希望'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                size: 80,
                color: AppTheme.warmGold,
              ),
              const SizedBox(height: 20),
              const Text(
                '全部功能已免费开放 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '本工具完全免费使用，通过页面广告支持运营。\n祝你早日实现财务自由！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.favorite,
                size: 32,
                color: AppTheme.primaryTeal.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
