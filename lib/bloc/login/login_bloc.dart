import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp_manager/bloc/login/login_event.dart';
import 'package:otp_manager/bloc/login/login_state.dart';
import 'package:otp_manager/repository/interface/user_repository.dart';

import '../../main.dart' show logger;
import '../../models/user.dart';
import '../../routing/constants.dart';
import '../../routing/navigation_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepository userRepository;

  final NavigationService _navigationService = NavigationService();

  LoginBloc({required this.userRepository})
      : super(const LoginState.initial()) {
    on<UrlSubmit>(_onUrlSubmit);
    on<UrlChanged>(_onUrlChanged);
  }

  void _onUrlSubmit(UrlSubmit event, Emitter<LoginState> emit) {
    String url = state.url.trim();

    url = url.endsWith("/") ? url.substring(0, url.length - 1) : url;

    if (url.toString() == "http://localhost") {
      userRepository.update(
        User(
          url: url,
          appPassword: "test",
          isGuest: true,
        ),
      );
      _navigationService.resetToScreen(homeRoute);
    } else {
      try {
        _navigationService.navigateTo(
          webViewerRoute,
          arguments: url,
        );
      } catch (e) {
        logger.e(e);

        emit(
          state.copyWith(
            url: url,
            error: "The URL entered is not valid!",
          ),
        );
      }
    }
  }

  void _onUrlChanged(UrlChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(url: event.url, error: ""));
  }
}
