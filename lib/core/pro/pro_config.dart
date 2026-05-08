/// Pro 功能的 Feature Flag 和免费版限制配置
class ProConfig {
  ProConfig._();

  /// 免费版最大收支条目数
  static const int freeMaxEntries = 3;

  /// 免费版最大方案数
  static const int freeMaxScenarios = 2;

  /// Pro 版最大方案数（null = 无限）
  static const int? proMaxScenarios = null;

  /// 是否启用语音输入
  static bool voiceInputEnabled(bool isPro) => isPro;

  /// 是否启用多情景模拟
  static bool multiScenarioEnabled(bool isPro) => isPro;

  /// 是否启用方案对比
  static bool scenarioCompareEnabled(bool isPro) => isPro;

  /// 是否启用城市模板
  static bool cityTemplatesEnabled(bool isPro) => isPro;

  /// 是否启用导出（PDF/Excel）
  static bool exportEnabled(bool isPro) => isPro;

  /// 是否启用高级图表
  static bool advancedChartsEnabled(bool isPro) => isPro;
}
