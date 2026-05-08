import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pro 状态
class ProStatus {
  final bool isPro;
  final DateTime? expiryDate; // null = 永久

  const ProStatus({this.isPro = false, this.expiryDate});

  /// 当前是否可以使用 Pro 功能（未过期）
  bool get isValid => isPro && (expiryDate == null || expiryDate!.isAfter(DateTime.now()));
}

/// Pro 状态 Provider（SharedPreferences 持久化）
final proStatusProvider = StateNotifierProvider<ProStatusNotifier, ProStatus>((ref) {
  return ProStatusNotifier();
});

class ProStatusNotifier extends StateNotifier<ProStatus> {
  ProStatusNotifier() : super(const ProStatus()) {
    _load();
  }

  static const _key = 'pro_status';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool(_key) ?? false;
    // 暂不处理 expiryDate，默认永久
    if (isPro) {
      state = const ProStatus(isPro: true);
    }
  }

  /// 解锁 Pro（生产环境接入 IAP）
  Future<void> unlockPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const ProStatus(isPro: true);
  }

  /// 恢复购买
  Future<void> restorePurchase() async {
    await _load();
  }
}
