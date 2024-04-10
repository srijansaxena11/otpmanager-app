import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/bloc/account_details/account_details_event.dart';
import 'package:otp_manager/bloc/account_details/account_details_state.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';
import 'package:otp_manager/repository/interface/user_repository.dart';
import 'package:otp_manager/routing/constants.dart';

import '../../domain/account_service.dart';
import '../../routing/navigation_service.dart';

class AccountDetailsBloc
    extends Bloc<AccountDetailsEvent, AccountDetailsState> {
  final UserRepository userRepository;
  final AccountRepository accountRepository;
  final AccountService accountService;
  final SharedAccountRepository sharedAccountRepository;
  final dynamic account; // Account | SharedAccount

  final NavigationService _navigationService = NavigationService();

  AccountDetailsBloc({
    required this.userRepository,
    required this.accountRepository,
    required this.accountService,
    required this.sharedAccountRepository,
    required this.account,
  }) : super(
          AccountDetailsState.initial(account, userRepository.get()!),
        ) {
    on<DeleteAccount>(_onDeleteAccount);
  }

  void _onDeleteAccount(
      DeleteAccount event, Emitter<AccountDetailsState> emit) {
    accountService.setAsDeleted(state.account);

    emit(state.copyWith(
        message: "${state.account.type.toUpperCase()} has been removed"));
    _navigationService.resetToScreen(homeRoute);
  }
}
