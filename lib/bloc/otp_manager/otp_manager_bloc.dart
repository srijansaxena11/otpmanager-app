import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/bloc/otp_manager/otp_manager_event.dart';
import 'package:otp_manager/bloc/otp_manager/otp_manager_state.dart';
import 'package:otp_manager/repository/interface/user_repository.dart';

class OtpManagerBloc extends Bloc<OtpManagerEvent, OtpManagerState> {
  final UserRepository userRepository;

  OtpManagerBloc({required this.userRepository})
      : super(OtpManagerState.initial(
          userRepository.get(),
          userRepository.isLogged(),
        )) {
    on<CopyWithTapToggled>(_onCopyWithTapToggled);
    on<DarkThemeToggled>(_onDarkThemeToggled);
  }

  void _onCopyWithTapToggled(
      CopyWithTapToggled event, Emitter<OtpManagerState> emit) {
    final user = userRepository.get();
    user?.copyWithTap = !user.copyWithTap;
    userRepository.update(user!);
    emit(state.copyWith(copyWithTap: user.copyWithTap));
  }

  void _onDarkThemeToggled(
      DarkThemeToggled event, Emitter<OtpManagerState> emit) {
    final user = userRepository.get();
    user?.darkTheme = !user.darkTheme;
    userRepository.update(user!);
    emit(state.copyWith(darkTheme: user.darkTheme));
  }
}
