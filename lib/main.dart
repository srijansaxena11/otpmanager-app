import 'dart:io';

import 'package:flutter/material.dart' hide Router;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart' hide FileOutput;
import 'package:otp_manager/bloc/otp_manager/otp_manager_bloc.dart';
import 'package:otp_manager/domain/account_service.dart';
import 'package:otp_manager/domain/nextcloud_service.dart';
import 'package:otp_manager/logger/filter.dart';
import 'package:otp_manager/repository/interface/account_repository.dart';
import 'package:otp_manager/repository/impl/account_repository_impl.dart';
import 'package:otp_manager/repository/impl/nextcloud_repository_impl.dart';
import 'package:otp_manager/repository/impl/shared_account_repository_impl.dart';
import 'package:otp_manager/repository/impl/user_repository_impl.dart';
import 'package:otp_manager/repository/interface/nextcloud_repository.dart';
import 'package:otp_manager/repository/interface/shared_account_repository.dart';
import 'package:otp_manager/repository/interface/user_repository.dart';
import 'package:otp_manager/utils/encryption.dart';

import 'logger/file_output.dart';
import "object_box/objectbox.dart";
import 'otp_manager.dart';

late ObjectBox objectBox;

var logger = Logger(
  filter: Filter(),
  printer: PrettyPrinter(
    printEmojis: false,
    printTime: true,
    colors: false,
    methodCount: 4,
  ),
  output: MultiOutput([FileOutput(), ConsoleOutput()]),
);

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  objectBox = await ObjectBox.create();

  // ignore bad server certificate
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>(
          create: (_) => UserRepositoryImpl(),
        ),
        RepositoryProvider<AccountRepository>(
          create: (_) => AccountRepositoryImpl(),
        ),
        RepositoryProvider<SharedAccountRepository>(
          create: (_) => SharedAccountRepositoryImpl(),
        ),
        RepositoryProvider<NextcloudRepository>(
          create: (context) => NextcloudRepositoryImpl(
            userRepository: context.read<UserRepository>(),
          ),
        ),
        RepositoryProvider<Encryption>(
          create: (context) => Encryption(
            userRepository: context.read<UserRepository>(),
          ),
        ),
        RepositoryProvider<AccountService>(
          create: (context) => AccountService(
            accountRepository: context.read<AccountRepository>(),
            sharedAccountRepository: context.read<SharedAccountRepository>(),
          ),
        ),
        RepositoryProvider<NextcloudService>(
          create: (context) => NextcloudService(
            userRepository: context.read<UserRepository>(),
            accountService: context.read<AccountService>(),
            accountRepository: context.read<AccountRepository>(),
            nextcloudRepository: context.read<NextcloudRepository>(),
            sharedAccountRepository: context.read<SharedAccountRepository>(),
            encryption: context.read<Encryption>(),
          ),
        ),
      ],
      child: BlocProvider<OtpManagerBloc>(
        create: (context) => OtpManagerBloc(
          userRepository: context.read<UserRepository>(),
        ),
        child: const OtpManager(),
      ),
    ),
  );
}
