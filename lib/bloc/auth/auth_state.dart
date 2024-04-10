import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final int attempts;
  final String password;
  final String message;
  final bool canShowFingerAuth;

  const AuthState({
    required this.attempts,
    required this.password,
    required this.message,
    required this.canShowFingerAuth,
  });

  const AuthState.initial()
      : attempts = 3,
        password = "",
        message = "",
        canShowFingerAuth = false;

  AuthState copyWith({
    int? attempts,
    String? password,
    String? message,
    bool? canShowFingerAuth,
  }) {
    return AuthState(
      attempts: attempts ?? this.attempts,
      password: password ?? this.password,
      message: message ?? this.message,
      canShowFingerAuth: canShowFingerAuth ?? this.canShowFingerAuth,
    );
  }

  @override
  List<Object> get props => [attempts, password, message, canShowFingerAuth];
}
