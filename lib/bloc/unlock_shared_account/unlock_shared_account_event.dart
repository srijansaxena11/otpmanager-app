import 'package:equatable/equatable.dart';

class UnlockSharedAccountEvent extends Equatable {
  const UnlockSharedAccountEvent();

  @override
  List<Object> get props => [];
}

class PasswordChanged extends UnlockSharedAccountEvent {
  const PasswordChanged({required this.password});

  final String password;

  @override
  List<Object> get props => [password];
}

class PasswordSubmit extends UnlockSharedAccountEvent {}

class ResetAttempts extends UnlockSharedAccountEvent {}
