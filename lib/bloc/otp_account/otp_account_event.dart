import 'package:equatable/equatable.dart';

class OtpAccountEvent extends Equatable {
  const OtpAccountEvent();

  @override
  List<Object> get props => [];
}

class GenerateOtpCode extends OtpAccountEvent {
  const GenerateOtpCode({required this.account});

  final dynamic account; // Account | SharedAccount

  @override
  List<Object> get props => [account];
}

class IncrementCounter extends OtpAccountEvent {
  const IncrementCounter({required this.account});

  final dynamic account; // Account | SharedAccount

  @override
  List<Object> get props => [account];
}
