import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp/otp.dart';
import 'package:otp_manager/domain/nextcloud_service.dart';
import 'package:otp_manager/models/account.dart';
import 'package:otp_manager/models/shared_account.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';

import '../home/home_bloc.dart';
import '../home/home_event.dart';
import 'otp_account_event.dart';
import 'otp_account_state.dart';

class OtpAccountBloc extends Bloc<OtpAccountEvent, OtpAccountState> {
  final HomeBloc homeBloc;
  final AccountRepository accountRepository;
  final NextcloudService nextcloudService;
  final SharedAccountRepository sharedAccountRepository;

  OtpAccountBloc({
    required this.homeBloc,
    required this.accountRepository,
    required this.nextcloudService,
    required this.sharedAccountRepository,
  }) : super(const OtpAccountState.initial()) {
    on<IncrementCounter>(_onIncrementCounter);
    on<GenerateOtpCode>(_onGenerateOtpCode);
  }

  String _getOtp(dynamic account) {
    if (account is SharedAccount && !account.unlocked) {
      return "Click here to unlock your shared account";
    }

    if (account.type == "totp") {
      return OTP.generateTOTPCodeString(
        account.secret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: account.algorithm,
        interval: account.period as int,
        length: account.digits as int,
        isGoogle: true,
      );
    } else if (account.type == "hotp") {
      if (account.counter! >= 0) {
        return OTP.generateHOTPCodeString(
          account.secret,
          account.counter!,
          algorithm: account.algorithm,
          length: account.digits as int,
          isGoogle: true,
        );
      }
      return "Click here to generate HOTP code";
    }

    return "null";
  }

  void _onIncrementCounter(
      IncrementCounter event, Emitter<OtpAccountState> emit) async {
    emit(state.copyWith(disableIncrement: true));
    int? updatedCounter = await nextcloudService.updateCounter(event.account);

    if (updatedCounter == null) {
      homeBloc.add(const ShowMessage(
          message: "There was an error while incrementing counter"));
      homeBloc.add(const ShowMessage(message: ""));
    } else {
      event.account.counter = updatedCounter;

      if (event.account is Account) {
        accountRepository.add(event.account); // update without sync
      } else {
        sharedAccountRepository.add(event.account); // update without sync
      }

      emit(state.copyWith(otpCode: _getOtp(event.account)));
    }

    await Future.delayed(const Duration(seconds: 1));

    emit(state.copyWith(disableIncrement: false));
  }

  void _onGenerateOtpCode(
      GenerateOtpCode event, Emitter<OtpAccountState> emit) async {
    emit(state.copyWith(otpCode: _getOtp(event.account)));
  }
}
