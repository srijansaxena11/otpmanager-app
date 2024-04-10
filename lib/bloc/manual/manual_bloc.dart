import 'package:diacritic/diacritic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';
import 'package:otp_manager/utils/base32.dart';
import 'package:otp_manager/utils/icon_picker_helper.dart';

import '../../domain/account_service.dart';
import '../../models/account.dart';
import '../../utils/uri_decoder.dart';
import 'manual_event.dart';
import 'manual_state.dart';

class ManualBloc extends Bloc<ManualEvent, ManualState> {
  final dynamic account; // Account | SharedAccount
  final AccountRepository accountRepository;
  final SharedAccountRepository sharedAccountRepository;
  final AccountService accountService;

  ManualBloc({
    this.account,
    required this.accountRepository,
    required this.sharedAccountRepository,
    required this.accountService,
  }) : super(ManualState.initial(account)) {
    on<AddOrEditAccount>(_onAddOrEditAccount);
    on<IconKeyChanged>(_onIconKeyChanged);
    on<NameChanged>(_onNameChanged);
    on<IssuerChanged>(_onIssuerChanged);
    on<SecretKeyChanged>(_onSecretKeyChanged);
    on<CodeTypeValueChanged>(_onCodeTypeValueChanged);
    on<IntervalValueChanged>(_onIntervalValueChanged);
    on<AlgorithmValueChanged>(_onAlgorithmValueChanged);
    on<DigitsValueChanged>(_onDigitsValueChanged);
  }

  void _updateAccount(Emitter<ManualState> emit, dynamic account, String msg) {
    if (account is Account) {
      accountRepository.update(account);
    } else {
      sharedAccountRepository.update(account);
    }
    emit(state.copyWith(message: msg));
  }

  bool _isFormValid(
      String name, String issuer, String secretKey, Emitter<ManualState> emit) {
    bool isValid = true;

    if (name.isEmpty) {
      emit(state.copyWith(nameError: "The account name is required"));
      isValid = false;
    } else if (name.length > 256) {
      emit(state.copyWith(
          nameError: "The account name cannot be longer than 256 characters"));
      isValid = false;
    }

    if (issuer.length > 256) {
      emit(state.copyWith(
          issuer: "The account issuer cannot be longer than 256 characters"));
      isValid = false;
    }

    if (account != null) return isValid;

    if (secretKey.isEmpty) {
      emit(state.copyWith(secretKeyError: "The secret key is required"));
      isValid = false;
    } else if (secretKey.length < 16) {
      emit(state.copyWith(
          secretKeyError:
              "The secret key cannot be shorter than 16 characters"));
      isValid = false;
    } else if (secretKey.length > 512) {
      emit(state.copyWith(
          secretKeyError:
              "The secret key cannot be longer than 512 characters"));
      isValid = false;
    } else if (!Base32.isValid(secretKey)) {
      emit(state.copyWith(
          secretKeyError: "The secret key is not base 32 encoded"));
      isValid = false;
    }

    return isValid;
  }

  void _onAddOrEditAccount(AddOrEditAccount event, Emitter<ManualState> emit) {
    String name = Uri.decodeFull(removeDiacritics(state.name.trim()));
    String issuer = Uri.decodeFull(removeDiacritics(state.issuer.trim()));
    String secretKey = state.secretKey.trim().toUpperCase();

    if (_isFormValid(name, issuer, secretKey, emit)) {
      int position = accountService.getLastPosition() + 1;

      if (account == null) {
        Account newAccount = Account(
          iconKey: state.iconKey,
          secret: secretKey,
          name: name,
          issuer: issuer,
          dbAlgorithm: UriDecoder.getAlgorithmFromString(state.algorithmValue),
          digits: state.digitsValue,
          type: state.codeTypeValue,
          period: state.codeTypeValue == "totp" ? state.intervalValue : null,
          position: position,
        );

        Account? sameAccount = accountRepository.getBySecret(secretKey);

        if (sameAccount == null) {
          accountRepository.add(newAccount);
          emit(state.copyWith(message: "New account has been added"));
        } else if (sameAccount.deleted) {
          newAccount.id = sameAccount.id;
          accountRepository.add(newAccount);
          emit(state.copyWith(message: "New account has been added"));
        } else {
          emit(
              state.copyWith(secretKeyError: "This secret key already exists"));
        }
      } else {
        account?.iconKey = state.iconKey;
        account?.name = name;
        account?.issuer = issuer;
        if (account is Account) {
          account?.dbAlgorithm =
              UriDecoder.getAlgorithmFromString(state.algorithmValue);
          account?.digits = state.digitsValue;
          account?.type = state.codeTypeValue;
          account?.period =
              state.codeTypeValue == "totp" ? state.intervalValue : null;
        }

        _updateAccount(emit, account!, "Account has been edited");
      }
    }
  }

  void _onIconKeyChanged(IconKeyChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(iconKey: event.key));
  }

  void _onNameChanged(NameChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(name: event.name, nameError: "null"));
  }

  void _onIssuerChanged(IssuerChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(issuer: event.issuer, issuerError: "null"));

    emit(
      state.copyWith(
        iconKey: event.issuer.isEmpty
            ? "default"
            : IconPickerHelper.findFirst(event.issuer),
      ),
    );
  }

  void _onSecretKeyChanged(SecretKeyChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(secretKey: event.secretKey, secretKeyError: "null"));
  }

  void _onCodeTypeValueChanged(
      CodeTypeValueChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(codeTypeValue: event.codeTypeValue));
  }

  void _onIntervalValueChanged(
      IntervalValueChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(intervalValue: event.intervalValue));
  }

  void _onAlgorithmValueChanged(
      AlgorithmValueChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(algorithmValue: event.algorithmValue));
  }

  void _onDigitsValueChanged(
      DigitsValueChanged event, Emitter<ManualState> emit) {
    emit(state.copyWith(digitsValue: event.digitsValue));
  }
}
