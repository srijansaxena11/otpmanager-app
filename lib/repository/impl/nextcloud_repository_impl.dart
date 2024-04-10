import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:otp_manager/repository/interface/user_repository.dart';

import '../../main.dart' show logger;
import '../../models/user.dart';
import '../interface/nextcloud_repository.dart';

class NextcloudRepositoryImpl extends NextcloudRepository {
  final UserRepository userRepository;
  late final User? user = userRepository.get();

  NextcloudRepositoryImpl({required this.userRepository});

  @override
  Future<void> sendHttpRequest({
    required String resource,
    required Map<String, dynamic> data,
    void Function(http.Response)? onComplete,
    void Function(http.Response)? onFailed,
    void Function()? onError,
  }) async {
    logger.d("NextcloudRepositoryImpl._sendHttpRequest start");

    if (user == null) {
      onError?.call();
      return;
    }

    await http
        .post(
          Uri.parse("${user?.url}/ocs/v2.php/apps/otpmanager/$resource"),
          headers: {
            'Authorization': 'Bearer ${user?.appPassword}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 5))
        .then((response) {
      if (response.statusCode == 200) {
        onComplete?.call(response);
      } else {
        logger.e("statusCode: ${response.statusCode}\nbody: ${response.body}");
        onFailed?.call(response);
      }
    }).catchError((e, stackTrace) {
      logger.e(e);
      onError?.call();
    });
  }
}
