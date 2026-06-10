/// 免费版功能配置 — 全部公开，仅靠 AdSense 广告变现
class ProConfig {
  ProConfig._();

  /// 最大收支条目数（null = 无限）
  static const int? freeMaxEntries = null;

  /// 最大方案数（null = 无限）
  static const int? freeMaxScenarios = null;

  /// 是否启用语音输入
  static bool voiceInputEnabled() => true;

  /// 是否启用多情景模拟
  static bool multiScenarioEnabled() => true;

  /// 是否启用方案对比
  static bool scenarioCompareEnabled() => true;

  /// 是否启用城市模板
  static bool cityTemplatesEnabled() => true;

  /// 是否启用导出（PDF/Excel）
  static bool exportEnabled() => true;

  /// 是否启用高级图表
  static bool advancedChartsEnabled() => true;
}
