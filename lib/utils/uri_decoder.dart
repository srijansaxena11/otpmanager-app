import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:diacritic/diacritic.dart';
import 'package:otp/otp.dart';
import 'package:otp_manager/utils/algorithms.dart';

import '../../generated_protoc/google_auth.pb.dart';
import '../models/account.dart';

class UriDecoder {
  Map _getNameAndIssuer(Uri queryUriParams) {
    Map params = {};

    var query = queryUriParams.queryParameters;
    var path = queryUriParams.path;

    if (path.contains(':')) {
      var tmp = path.split(':');
      params["issuer"] = tmp[0].replaceAll("/", "");
      params["name"] = tmp[1];
    } else if (path.contains('@')) {
      var tmp = path.split('@');
      params["name"] = tmp[0].replaceAll("/", "");
      params["issuer"] = tmp[1];
    } else if (query["issuer"] != null) {
      params["name"] = path.replaceAll("/", "");
      params["issuer"] = query["issuer"];
    } else {
      params["name"] = path.replaceAll("/", "");
    }

    return params;
  }

  static int getAlgorithmFromString(String algorithm) {
    int algo = Algorithms.sha1.index;

    if (algorithm.contains("SHA256")) {
      algo = Algorithms.sha256.index;
    } else if (algorithm.contains("SHA512")) {
      algo = Algorithms.sha512.index;
    }

    return algo;
  }

  static String getAlgorithmFromAlgo(Algorithm? algorithm) {
    if (algorithm == Algorithm.SHA256) {
      return "SHA256";
    } else if (algorithm == Algorithm.SHA512) {
      return "SHA512";
    }

    return "SHA1";
  }

  List<Account> decodeGoogleUri(Uri uri) {
    String? data = uri.queryParameters["data"];
    Uint8List decoded = base64.decode(data!);

    var payload = MigrationPayload.fromBuffer(decoded);

    List<Account> accounts = [];

    payload.otpParameters.asMap().forEach((index, params) {
      var tmp = params.toProto3Json() as Map;
      tmp["name"] = Uri.decodeFull(removeDiacritics(tmp["name"].toString()));
      String secret = base32
          .encode(Uint8List.fromList(payload.otpParameters[index].secret))
          .toUpperCase();

      var newAccount = Account(
        secret: secret,
        name:
            tmp["name"].contains(':') ? tmp["name"].split(':')[1] : tmp["name"],
        issuer: Uri.decodeFull(removeDiacritics(tmp["issuer"] ?? "")),
        dbAlgorithm: getAlgorithmFromString(tmp["algorithm"]),
        digits: 6,
        type: tmp["type"],
        period: 30,
      );

      accounts.add(newAccount);
    });

    return accounts;
  }

  List<Account> decodeQrCode(String uri, {bool isGoogle = false}) {
    var uriDecoded = Uri.parse(uri);

    List<Account> accounts = [];

    if (isGoogle) {
      accounts = decodeGoogleUri(uriDecoded);
    } else {
      var tmp = uriDecoded.queryParameters;
      var nameAndIssuer = _getNameAndIssuer(uriDecoded);

      var newAccount = Account(
        secret: tmp["secret"].toString().toUpperCase(),
        name: removeDiacritics(Uri.decodeFull(nameAndIssuer["name"])),
        issuer: removeDiacritics(Uri.decodeFull(nameAndIssuer["issuer"] ?? "")),
        dbAlgorithm: getAlgorithmFromString(tmp["algorithm"].toString()),
        digits: int.tryParse(tmp["digits"].toString()),
        type: uriDecoded.host,
        period: int.tryParse(tmp["period"].toString()),
      );

      accounts.add(newAccount);
    }

    return accounts;
  }

  static bool isGoogle(String uri) {
    return uri.contains("otpauth-migration://offline?data=");
  }

  static bool isValid(String uri) {
    return uri.contains("otpauth");
  }
}
