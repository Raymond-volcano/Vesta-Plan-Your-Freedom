import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pro 状态 — 全部功能免费公开，无需付费
///
/// 本 app 靠 AdSense 广告变现，Pro 概念已移除。
/// 此 provider 保留仅用于兼容，始终返回已解锁状态。
class ProStatus {
  final bool isPro;
  final DateTime? expiryDate;

  const ProStatus({this.isPro = true, this.expiryDate});

  /// 始终有效
  bool get isValid => true;
}

/// Pro 状态 Provider — 始终返回已解锁
final proStatusProvider = Provider<ProStatus>((ref) {
  return const ProStatus(isPro: true);
});

/// 占位，保留引用兼容
class ProStatusNotifier extends StateNotifier<ProStatus> {
  ProStatusNotifier() : super(const ProStatus(isPro: true));
}
