import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/bloc/qr_code_scanner/qr_code_scanner_event.dart';
import 'package:otp_manager/bloc/qr_code_scanner/qr_code_scanner_state.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';

import '../../domain/account_service.dart';
import '../../models/account.dart';
import '../../utils/uri_decoder.dart';

class QrCodeScannerBloc extends Bloc<QrCodeScannerEvent, QrCodeScannerState> {
  final AccountRepository accountRepository;
  final AccountService accountService;

  QrCodeScannerBloc({
    required this.accountRepository,
    required this.accountService,
  }) : super(
          const QrCodeScannerState.initial(),
        ) {
    on<ErrorChanged>(_onErrorChanged);
    on<DecodeAndStoreAccounts>(_onDecodeAndStoreAccounts);
  }

  void _onErrorChanged(ErrorChanged event, Emitter<QrCodeScannerState> emit) {
    emit(state.copyWith(error: event.error));
  }

  void _onDecodeAndStoreAccounts(
      DecodeAndStoreAccounts event, Emitter<QrCodeScannerState> emit) async {
    List<Account> newAccounts = UriDecoder().decodeQrCode(
      event.accounts,
      isGoogle: UriDecoder.isGoogle(event.accounts),
    );

    var atLeastOneAdded = false;

    for (var account in newAccounts) {
      if (!accountRepository.alreadyExists(account.secret)) {
        atLeastOneAdded = true;
        account.position = accountService.getLastPosition() + 1;
        accountRepository.add(account);
      }
    }

    if (!atLeastOneAdded) {
      emit(state.copyWith(
          error:
              "${newAccounts.length > 1 ? "These accounts are already registered" : "This account is already registered"}.\nMake sure you are in sync and try again."));
    } else {
      emit(state.copyWith(
          addWithSuccess: newAccounts.length > 1
              ? "New accounts have been added"
              : "New account has been added"));
    }
  }
}
