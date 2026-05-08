import '../../income_expense/data/models/income_model.dart';
import '../../income_expense/data/models/expense_model.dart';

/// 城市模板 — 内置各大城市的典型经济参数
class CityTemplate {
  final String cityName;
  final String description;
  final double avgMonthlySalary;
  final double socialInsuranceRate; // 社保+公积金总扣款比例
  final double annualInflationRate;
  final List<TemplateExpense> typicalExpenses;

  const CityTemplate({
    required this.cityName,
    required this.description,
    required this.avgMonthlySalary,
    required this.socialInsuranceRate,
    required this.annualInflationRate,
    required this.typicalExpenses,
  });

  /// 生成收入列表（工资 + 社保折损后实际到手）
  List<IncomeModel> createIncomes(String idPrefix, int startYear) {
    final afterTax = avgMonthlySalary * (1 - socialInsuranceRate);
    return [
      IncomeModel(
        id: '${idPrefix}_salary',
        name: '工资收入',
        monthlyAmount: afterTax,
        startYear: startYear,
        type: IncomeType.active,
        startMonth: 1,
      ),
    ];
  }

  /// 生成支出列表
  List<ExpenseModel> createExpenses(String idPrefix, int startYear) {
    return typicalExpenses.map((e) {
      return ExpenseModel(
        id: '${idPrefix}_${e.name}',
        name: e.name,
        monthlyAmount: e.amount,
        startYear: startYear,
        startMonth: 1,
      );
    }).toList();
  }
}

class TemplateExpense {
  final String name;
  final double amount;
  const TemplateExpense(this.name, this.amount);
}

// ── 城市数据 ──────────────────────────────────────────────────

/// 北京模板
const beijingTemplate = CityTemplate(
  cityName: '北京',
  description: '首都，高收入高消费',
  avgMonthlySalary: 18000,
  socialInsuranceRate: 0.22,
  annualInflationRate: 0.03,
  typicalExpenses: [
    TemplateExpense('房租/房贷', 6000),
    TemplateExpense('餐饮', 3000),
    TemplateExpense('交通', 800),
    TemplateExpense('日用品', 600),
    TemplateExpense('通讯网络', 200),
    TemplateExpense('社交娱乐', 1000),
    TemplateExpense('医疗健康', 400),
    TemplateExpense('服装护肤', 600),
  ],
);

/// 上海模板
const shanghaiTemplate = CityTemplate(
  cityName: '上海',
  description: '经济中心，收入消费双高',
  avgMonthlySalary: 17000,
  socialInsuranceRate: 0.22,
  annualInflationRate: 0.03,
  typicalExpenses: [
    TemplateExpense('房租/房贷', 5500),
    TemplateExpense('餐饮', 3000),
    TemplateExpense('交通', 700),
    TemplateExpense('日用品', 600),
    TemplateExpense('通讯网络', 200),
    TemplateExpense('社交娱乐', 1200),
    TemplateExpense('医疗健康', 400),
    TemplateExpense('服装护肤', 600),
  ],
);

/// 广州模板
const guangzhouTemplate = CityTemplate(
  cityName: '广州',
  description: '一线城市中生活成本相对温和',
  avgMonthlySalary: 13000,
  socialInsuranceRate: 0.20,
  annualInflationRate: 0.03,
  typicalExpenses: [
    TemplateExpense('房租/房贷', 3500),
    TemplateExpense('餐饮', 2500),
    TemplateExpense('交通', 500),
    TemplateExpense('日用品', 500),
    TemplateExpense('通讯网络', 180),
    TemplateExpense('社交娱乐', 800),
    TemplateExpense('医疗健康', 300),
    TemplateExpense('服装护肤', 400),
  ],
);

/// 深圳模板
const shenzhenTemplate = CityTemplate(
  cityName: '深圳',
  description: '年轻城市，高收入高房价',
  avgMonthlySalary: 16000,
  socialInsuranceRate: 0.21,
  annualInflationRate: 0.03,
  typicalExpenses: [
    TemplateExpense('房租/房贷', 5000),
    TemplateExpense('餐饮', 2800),
    TemplateExpense('交通', 600),
    TemplateExpense('日用品', 500),
    TemplateExpense('通讯网络', 200),
    TemplateExpense('社交娱乐', 1000),
    TemplateExpense('医疗健康', 350),
    TemplateExpense('服装护肤', 500),
  ],
);

/// 所有可用城市模板列表
const allCityTemplates = [
  beijingTemplate,
  shanghaiTemplate,
  guangzhouTemplate,
  shenzhenTemplate,
];
