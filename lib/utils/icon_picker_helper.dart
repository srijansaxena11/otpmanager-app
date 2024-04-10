import 'package:flutter/material.dart';
import 'package:otp_manager/utils/simple_icons.dart';

class IconPickerHelper {
  static String findFirst(String toFind) {
    toFind = toFind.replaceAll(" ", "").toLowerCase();

    return simpleIcons.keys
        .firstWhere((v) => v.contains(toFind), orElse: () => "default");
  }

  static Map<String, Icon> findBestMatch(String toFind) {
    toFind = toFind.replaceAll(" ", "").toLowerCase();

    Map<String, Icon> iconsBestMatch = {};

    simpleIcons.forEach((key, value) {
      if (iconsBestMatch.length != 3 && key.contains(toFind)) {
        iconsBestMatch[key] = value;
      }
    });

    return iconsBestMatch;
  }
}
