import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../data/models/user_profile_model.dart';

final profileBoxProvider = Provider<Box<UserProfileModel>>((ref) {
  return Hive.box<UserProfileModel>(AppConstants.profileBox);
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfileModel>((ref) {
  final box = ref.watch(profileBoxProvider);
  return ProfileNotifier(box);
});

class ProfileNotifier extends StateNotifier<UserProfileModel> {
  final Box<UserProfileModel> _box;

  ProfileNotifier(this._box) : super(_loadProfile(_box));

  static UserProfileModel _loadProfile(Box<UserProfileModel> box) {
    if (box.values.isEmpty) {
      return UserProfileModel(
        currentAge: 25,
        retirementAge: UserProfileModel.statutoryAge(25, Gender.male),
        genderIndex: 0,
      );
    }
    return box.values.first;
  }

  void save(UserProfileModel profile) {
    _box.clear();
    _box.add(profile);
    state = profile;
  }

  void updateAge(int currentAge) {
    final statutory = UserProfileModel.statutoryAge(currentAge, state.gender);
    final updated = state.copyWith(
      currentAge: currentAge,
      retirementAge: statutory,
    );
    save(updated);
  }

  void updateRetirementAge(int age) {
    final updated = state.copyWith(retirementAge: age);
    save(updated);
  }

  void updateGender(Gender gender) {
    final gIndex = gender.index;
    final statutory =
        UserProfileModel.statutoryAge(state.currentAge, gender);
    final updated = state.copyWith(
      genderIndex: gIndex,
      retirementAge: statutory,
    );
    save(updated);
  }
}
