import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/bloc/home/home_event.dart';
import 'package:otp_manager/bloc/unlock_shared_account/unlock_shared_account_event.dart';
import 'package:otp_manager/bloc/unlock_shared_account/unlock_shared_account_state.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';

import '../../domain/nextcloud_service.dart';
import '../../routing/navigation_service.dart';
import '../home/home_bloc.dart';

class UnlockSharedAccountBloc
    extends Bloc<UnlockSharedAccountEvent, UnlockSharedAccountState> {
  final NextcloudService nextcloudService;
  final SharedAccountRepository sharedAccountRepository;
  final int accountId;
  final HomeBloc homeBloc;

  final NavigationService _navigationService = NavigationService();

  UnlockSharedAccountBloc({
    required this.sharedAccountRepository,
    required this.nextcloudService,
    required this.accountId,
    required this.homeBloc,
  }) : super(
          const UnlockSharedAccountState.initial(),
        ) {
    on<PasswordSubmit>(_onPasswordSubmit);
    on<PasswordChanged>(_onPasswordChanged);
    on<ResetAttempts>(_onResetAttempts);
  }

  void _onResetAttempts(
      ResetAttempts event, Emitter<UnlockSharedAccountState> emit) {
    emit(state.copyWith(attempts: 3));
  }

  void _onPasswordChanged(
      PasswordChanged event, Emitter<UnlockSharedAccountState> emit) {
    emit(state.copyWith(password: event.password, errorMsg: ""));
  }

  void _error(Emitter<UnlockSharedAccountState> emit, String msg) {
    emit(state.copyWith(errorMsg: msg, attempts: state.attempts - 1));

    if (state.attempts == 0) {
      emit(state.copyWith(attempts: 3));
    }
  }

  void _onPasswordSubmit(
      PasswordSubmit event, Emitter<UnlockSharedAccountState> emit) async {
    String? result =
        await nextcloudService.unlockSharedAccount(accountId, state.password);

    if (result == null) {
      homeBloc.add(
          const ShowMessage(message: "Shared account unlocked with success"));
      homeBloc.add(NextcloudSync());
      _navigationService.goBack();
    } else {
      _error(emit, result);
    }
  }
}
