import 'package:flutter/material.dart';

/// Pro 功能拦截组件 — 已弃用，所有功能免费公开
///
/// 直接显示 child，不做任何拦截。
class ProGate extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return child;
  }
}
