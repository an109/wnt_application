import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/views/Profile/domain/entities/ProfileEntity.dart';
import '../../../../core/error/data_state.dart';
import '../../domain/usecase/get_profile_usecase.dart';
import '../../domain/usecase/patch_profile_usecase.dart';
import '../../domain/usecase/update_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';



class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final PatchProfileUseCase patchProfileUseCase;

  ProfileEntity? _currentProfile;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.patchProfileUseCase,
  }) : super(const ProfileInitial()) {
    on<GetProfileEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<PatchProfileEvent>(_onPatchProfile);
    on<UpdateProfileFieldEvent>(_onUpdateProfileField);
  }

  Future<void> _onGetProfile(
      GetProfileEvent event,
      Emitter<ProfileState> emit,
      ) async {
    emit(const ProfileLoading());

    final result = await getProfileUseCase();

    if (result is DataSuccess<ProfileEntity>) {
      _currentProfile = result.data;
      emit(ProfileLoaded(result.data!));
    } else if (result is DataFailed<ProfileEntity>) {
      final errorMessage = result.error?.message ?? 'Failed to load profile';
      emit(ProfileError(errorMessage));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfileEvent event,
      Emitter<ProfileState> emit,
      ) async {
    if (_currentProfile == null) {
      emit(const ProfileError('No profile loaded'));
      return;
    }

    emit(ProfileUpdateLoading(event.profile));

    final result = await updateProfileUseCase(event.profile);

    if (result is DataSuccess<ProfileEntity>) {
      _currentProfile = result.data;
      emit(ProfileUpdateSuccess(result.data!));
    } else if (result is DataFailed<ProfileEntity>) {
      final errorMessage = result.error?.message ?? 'Failed to update profile';
      emit(ProfileError(errorMessage));
    }
  }

  Future<void> _onPatchProfile(
      PatchProfileEvent event,
      Emitter<ProfileState> emit,
      ) async {
    if (_currentProfile == null) {
      emit(const ProfileError('No profile loaded'));
      return;
    }

    emit(ProfileUpdateLoading(event.profile));

    final result = await patchProfileUseCase(event.profile);

    if (result is DataSuccess<ProfileEntity>) {
      _currentProfile = result.data;
      emit(ProfileUpdateSuccess(result.data!));
    } else if (result is DataFailed<ProfileEntity>) {
      final errorMessage = result.error?.message ?? 'Failed to update profile';
      emit(ProfileError(errorMessage));
    }
  }

  Future<void> _onUpdateProfileField(
      UpdateProfileFieldEvent event,
      Emitter<ProfileState> emit,
      ) async {
    if (_currentProfile == null) {
      emit(const ProfileError('No profile loaded'));
      return;
    }

    // Update the current profile with new fields
    final updatedProfile = _currentProfile!.copyWith(
      title: event.fields['title'] ?? _currentProfile!.title,
      firstName: event.fields['firstName'] ?? _currentProfile!.firstName,
      lastName: event.fields['lastName'] ?? _currentProfile!.lastName,
      email: event.fields['email'] ?? _currentProfile!.email,
      phoneCode: event.fields['phoneCode'] ?? _currentProfile!.phoneCode,
      phoneNumber: event.fields['phoneNumber'] ?? _currentProfile!.phoneNumber,
      dob: event.fields['dob'] ?? _currentProfile!.dob,
      address: event.fields['address'] ?? _currentProfile!.address,
      city: event.fields['city'] ?? _currentProfile!.city,
      state: event.fields['state'] ?? _currentProfile!.state,
      country: event.fields['country'] ?? _currentProfile!.country,
      pinCode: event.fields['pinCode'] ?? _currentProfile!.pinCode,
      newsletter: event.fields['newsletter'] ?? _currentProfile!.newsletter,
      smsAlerts: event.fields['smsAlerts'] ?? _currentProfile!.smsAlerts,
    );

    _currentProfile = updatedProfile;
    emit(ProfileLoaded(updatedProfile));
  }

  ProfileEntity? get currentProfile => _currentProfile;
}