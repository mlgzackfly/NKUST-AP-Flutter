import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/models/midterm_alerts_data.dart';
import 'package:nkust_ap/models/reward_and_penalty_data.dart';
import 'package:nkust_ap/models/room_data.dart';

part 'alert_parser.dart';
part 'course_parser.dart';
part 'room_parser.dart';
part 'score_parser.dart';
part 'user_parser.dart';

// ignore_for_file: unreachable_from_main

final String specialSpace = String.fromCharCode(160);

/// Main parser class for WebAP HTML responses.
///
/// This class provides parsing methods for various WebAP pages.
/// Methods are organized into extensions in separate part files:
/// - [UserParserExtension]: Login and user info parsing
/// - [CourseParserExtension]: Semester and course table parsing
/// - [ScoreParserExtension]: Score parsing
/// - [AlertParserExtension]: Midterm alerts and reward/penalty parsing
/// - [RoomParserExtension]: Room list and room course table parsing
class WebApParser {
  static WebApParser? _instance;

  // ignore: prefer_constructors_over_static_methods
  static WebApParser get instance {
    return _instance ??= WebApParser();
  }

  /// Clears transfer encoding artifacts from HTML bytes.
  ///
  /// This method handles chunked transfer encoding by removing
  /// hexadecimal chunk size indicators from the response.
  String clearTransEncoding(List<int> htmlBytes) {
    // htmlBytes is fixed-length list, need copy.
    final List<int> tempData = List<int>.from(htmlBytes);

    //Add /r/n on first word.
    tempData.insert(0, 10);
    tempData.insert(0, 13);

    int startIndex = 0;
    for (int i = 0; i < tempData.length - 1; i++) {
      //check i and i+1 is /r/n
      if (tempData[i] == 13 && tempData[i + 1] == 10) {
        if (i - startIndex - 2 <= 4 && i - startIndex - 2 > 0) {
          //check in this range word is number or A~F (Hex)
          int removeCount = 0;
          for (int strIndex = startIndex + 2; strIndex < i; strIndex++) {
            if ((tempData[strIndex] > 47 && tempData[strIndex] < 58) ||
                (tempData[strIndex] > 64 && tempData[strIndex] < 71) ||
                (tempData[strIndex] > 96 && tempData[strIndex] < 103)) {
              removeCount++;
            }
          }
          if (removeCount == i - startIndex - 2) {
            tempData.removeRange(startIndex, i + 2);
          }
          //Subtract offset
          i -= i - startIndex - 2;
          startIndex -= i - startIndex - 2;
        }
        startIndex = i;
      }
    }

    return utf8.decode(tempData, allowMalformed: true);
  }
}
