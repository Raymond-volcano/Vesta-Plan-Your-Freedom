import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../data/models/asset_model.dart';

final assetBoxProvider = Provider<Box<AssetModel>>((ref) {
  return Hive.box<AssetModel>(AppConstants.assetBox);
});

final assetListProvider = StateNotifierProvider<AssetListNotifier, List<AssetModel>>((ref) {
  final box = ref.watch(assetBoxProvider);
  return AssetListNotifier(box);
});

class AssetListNotifier extends StateNotifier<List<AssetModel>> {
  final Box<AssetModel> _box;

  AssetListNotifier(this._box) : super(_box.values.toList());

  void add(AssetModel asset) {
    _box.add(asset);
    state = _box.values.toList();
  }

  void update(String id, AssetModel updated) {
    final index = _box.values.toList().indexWhere((e) => e.id == id);
    if (index != -1) {
      _box.putAt(index, updated);
      state = _box.values.toList();
    }
  }

  void delete(String id) {
    final index = _box.values.toList().indexWhere((e) => e.id == id);
    if (index != -1) {
      _box.deleteAt(index);
      state = _box.values.toList();
    }
  }

  void updateAll(List<AssetModel> updatedAssets) {
    for (final asset in updatedAssets) {
      final index = _box.values.toList().indexWhere((e) => e.id == asset.id);
      if (index != -1) {
        _box.putAt(index, asset);
      }
    }
    state = _box.values.toList();
  }
}
