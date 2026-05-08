import 'dart:math' as math;
import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class AssetModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double currentValue;
  @HiveField(3)
  double annualReturnRate; // 百分比，如 0.05 表示 5%

  AssetModel({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.annualReturnRate,
  });

  double get annualReturn => currentValue * annualReturnRate;

  double projectedValue(int years) {
    return currentValue * math.pow(1 + annualReturnRate, years).toDouble();
  }

  AssetModel copyWith({
    String? id,
    String? name,
    double? currentValue,
    double? annualReturnRate,
  }) {
    return AssetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      currentValue: currentValue ?? this.currentValue,
      annualReturnRate: annualReturnRate ?? this.annualReturnRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currentValue': currentValue,
        'annualReturnRate': annualReturnRate,
      };

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        id: json['id'] as String,
        name: json['name'] as String,
        currentValue: (json['currentValue'] as num).toDouble(),
        annualReturnRate: (json['annualReturnRate'] as num).toDouble(),
      );
}

class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override
  final int typeId = 4;

  @override
  AssetModel read(BinaryReader reader) {
    final fields = reader.readMap();
    return AssetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      currentValue: (fields[2] as num).toDouble(),
      annualReturnRate: (fields[3] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer.writeMap({
      0: obj.id,
      1: obj.name,
      2: obj.currentValue,
      3: obj.annualReturnRate,
    });
  }
}
