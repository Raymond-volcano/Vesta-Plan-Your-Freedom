import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../income_expense/data/models/income_model.dart';
import '../../income_expense/data/models/expense_model.dart';
import '../../assets/data/models/asset_model.dart';
import '../../profile/data/models/user_profile_model.dart';
import '../domain/services/cash_flow_calculator.dart';
import '../providers/result_provider.dart';

class ExportService {
  static final _f = NumberFormat('#,###');

  /// 导出 PDF 报告并调用分享
  static Future<String> exportReport({
    required UserProfileModel profile,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required List<AssetModel> assets,
    required List<YearData> simulation,
    required List<SensitivityItem> sensitivity,
    required bool simulateUnemployment,
  }) async {
    final pdf = pw.Document();

    // 封面
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          _buildHeader(),
          pw.SizedBox(height: 30),
          _buildProfileTable(profile, assets),
          pw.SizedBox(height: 20),
          _buildSummaryCards(simulation),
          pw.SizedBox(height: 20),
          _buildIncomeExpenseTable(incomes, expenses),
          pw.SizedBox(height: 20),
          _buildSimulationTable(simulation),
          pw.SizedBox(height: 20),
          _buildSensitivityTable(sensitivity),
        ],
      ),
    );

    // 保存到临时目录
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/financial_report_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    // 分享
    await Share.shareXFiles([XFile(path)], text: '财务自由计划报告');

    return path;
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('财务自由计划报告',
            style: pw.TextStyle(
                fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('生成时间：${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildProfileTable(
      UserProfileModel profile, List<AssetModel> assets) {
    final totalAssets = assets.fold<double>(0, (s, a) => s + a.currentValue);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('基本信息',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['项目', '值'],
          data: [
            ['当前年龄', '${profile.currentAge} 岁'],
            ['计划退休年龄', '${profile.retirementAge} 岁'],
            ['性别', profile.gender.label],
            ['年通胀率', '${(profile.annualInflationRate * 100).toStringAsFixed(1)}%'],
            ['总资产', '¥${_f.format(totalAssets.toInt())}'],
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCards(List<YearData> simulation) {
    final last = simulation.lastOrNull;
    if (last == null) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('核心指标',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['指标', '值'],
          data: [
            ['80 岁总资产', '¥${_f.format(last.totalAssets.toInt())}'],
            ['最终月被动收入', '¥${_f.format(last.passiveIncome.toInt())}'],
            ['最终月净现金流', '¥${_f.format(last.netCashFlow.toInt())}'],
            ...() {
              for (int i = 0; i < simulation.length; i++) {
                if (simulation[i].totalAssets < 0) {
                  return [['资产耗尽年龄', '${simulation[i].age} 岁']];
                }
              }
              return <List<String>>[['资产耗尽年龄', '未耗尽']];
            }(),
            ...() {
              for (final y in simulation) {
                if (y.passiveIncome >= y.totalExpense) {
                  return [['财务自由年龄', '${y.age} 岁']];
                }
              }
              return <List<String>>[['财务自由年龄', '未达成']];
            }(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildIncomeExpenseTable(
      List<IncomeModel> incomes, List<ExpenseModel> expenses) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('收支明细',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('收入',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: const ['名称', '月金额', '类型', '起止时间'],
          data: incomes.map((i) {
            final period = i.isPermanent
                ? '${i.startYear}年起'
                : '${i.startYear}-${i.endYear}年';
            return [
              i.name,
              '¥${_f.format(i.monthlyAmount.toInt())}',
              i.type.label,
              period,
            ];
          }).toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Text('支出',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: const ['名称', '月金额', '起止时间'],
          data: expenses.map((e) {
            final period = e.isPermanent
                ? '${e.startYear}年起'
                : '${e.startYear}-${e.endYear}年';
            return [
              e.name,
              '¥${_f.format(e.monthlyAmount.toInt())}',
              period,
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSimulationTable(List<YearData> simulation) {
    // 只打印每 5 年一行的数据，避免 PDF 过长
    final sampled = <YearData>[];
    for (int i = 0; i < simulation.length; i += 5) {
      sampled.add(simulation[i]);
    }
    if (sampled.last != simulation.last) {
      sampled.add(simulation.last);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('逐年模拟数据（抽样）',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerRight,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: const ['年龄', '年收入', '年支出', '净现金流', '总资产', '被动收入'],
          data: sampled.map((y) {
            return [
              '${y.age}',
              '¥${_f.format(y.totalIncome.toInt())}',
              '¥${_f.format(y.totalExpense.toInt())}',
              '¥${_f.format(y.netCashFlow.toInt())}',
              '¥${_f.format(y.totalAssets.toInt())}',
              '¥${_f.format(y.passiveIncome.toInt())}',
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildSensitivityTable(List<SensitivityItem> items) {
    if (items.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('制约因素分析',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerRight,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: const ['因素', '对总资产的影响'],
          data: items.map((s) {
            final sign = s.impactPercent >= 0 ? '+' : '';
            return [
              s.label,
              '${sign}${s.impactPercent.toStringAsFixed(1)}%',
            ];
          }).toList(),
        ),
      ],
    );
  }
}
