import 'package:equatable/equatable.dart';
import 'package:otp_manager/models/user.dart';

class AccountDetailsState extends Equatable {
  final dynamic account; // Account | ShareAccount
  final String message;
  final String password;
  final String serverUrl;

  const AccountDetailsState({
    required this.account,
    required this.message,
    required this.password,
    required this.serverUrl,
  });

  AccountDetailsState.initial(this.account, User user)
      : message = "",
        password = user.password!,
        serverUrl = user.url;

  AccountDetailsState copyWith({String? message}) {
    return AccountDetailsState(
      account: account,
      message: message ?? this.message,
      password: password,
      serverUrl: serverUrl,
    );
  }

  @override
  List<Object> get props => [message];
}
