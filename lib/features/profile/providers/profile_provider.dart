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

  void updateUnemploymentStartYear(int? year) {
    final updated = state.copyWith(
      unemploymentStartYear: year,
      clearUnemploymentStart: year == null,
    );
    save(updated);
  }

  void updateUnemploymentStartMonth(int? month) {
    final updated = state.copyWith(unemploymentStartMonth: month);
    save(updated);
  }

  void updateUnemploymentBenefit(double amount) {
    final updated = state.copyWith(unemploymentBenefit: amount);
    save(updated);
  }

  void updateUnemploymentBenefitMonths(int months) {
    final updated = state.copyWith(unemploymentBenefitMonths: months);
    save(updated);
  }

  void updatePensionAmount(double amount) {
    final updated = state.copyWith(pensionAmount: amount);
    save(updated);
  }

  void updateInflationRate(double rate) {
    final updated = state.copyWith(annualInflationRate: rate);
    save(updated);
  }

  void updateUnemploymentExtraExpense(double amount) {
    final updated = state.copyWith(unemploymentExtraExpense: amount);
    save(updated);
  }

  void updateUnemploymentExtraExpenseMonths(int months) {
    final updated = state.copyWith(unemploymentExtraExpenseMonths: months);
    save(updated);
  }
}
