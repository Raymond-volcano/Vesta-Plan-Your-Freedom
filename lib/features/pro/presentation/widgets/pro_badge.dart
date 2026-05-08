import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Pro 角标组件 — 在 Pro 功能右上角显示 "PRO" 标签
class ProBadge extends StatelessWidget {
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;

  const ProBadge({
    super.key,
    this.fontSize = 9,
    this.horizontalPadding = 4,
    this.verticalPadding = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.warmGold, Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
