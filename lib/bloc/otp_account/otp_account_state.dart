import 'package:equatable/equatable.dart';

class OtpAccountState extends Equatable {
  final String? otpCode;
  final bool disableIncrement;

  const OtpAccountState({
    required this.otpCode,
    required this.disableIncrement,
  });

  const OtpAccountState.initial()
      : this(otpCode: null, disableIncrement: false);

  OtpAccountState copyWith({String? otpCode, bool? disableIncrement}) {
    return OtpAccountState(
      otpCode: otpCode == "null" ? null : otpCode ?? this.otpCode,
      disableIncrement: disableIncrement ?? this.disableIncrement,
    );
  }

  @override
  List<Object?> get props => [otpCode, disableIncrement];
}
