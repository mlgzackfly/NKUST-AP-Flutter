import 'dart:io';
import 'dart:typed_data';

import 'package:ap_common/callback/general_callback.dart';
import 'package:ap_common/models/course_data.dart';
import 'package:ap_common/models/score_data.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' as html;
import 'package:cookie_jar/cookie_jar.dart';

class MobileNkustHelper {
  static const BASE_URL = 'https://mobile.nkust.edu.tw';

  static const LOGIN = '$BASE_URL/';
  static const HOME = '$BASE_URL/Home/Index';
  static const COURSE = '$BASE_URL/Student/Course';
  static const SCORE = '$BASE_URL/Student/Grades';

  static Dio dio;

  static CookieJar cookieJar;

  static MobileNkustHelper _instance;

  int captchaErrorCount = 0;

  static MobileNkustHelper get instance {
    if (_instance == null) {
      _instance = MobileNkustHelper();
      dio = Dio(
        BaseOptions(
          followRedirects: false,
          headers: {
            "user-agent":
                "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
          },
        ),
      );
      initCookiesJar();
    }
    return _instance;
  }

  static initCookiesJar() {
    cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(BASE_URL));
  }

  void setCookie(
    String url, {
    String cookieName,
    String cookieValue,
    String cookieDomain,
  }) {
    Cookie _tempCookie = Cookie(cookieName, cookieValue);
    _tempCookie.domain = cookieDomain;
    cookieJar.saveFromResponse(
      Uri.parse(url),
      [_tempCookie],
    );
  }

  Future<CourseData> getCourseTable({
    GeneralCallback<CourseData> callback,
  }) async {
    try {
      dio.options.headers['Connection'] =
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';
      dio.options.headers['Accept'] = 'keep-alive';
      final response = await dio.get(COURSE);
      final rawHtml = response.data;
      if (kDebugMode) debugPrint(rawHtml);
      final courseData = CourseParser.courseTable(rawHtml);
      return callback != null ? callback.onSuccess(courseData) : courseData;
    } catch (e) {
      if (e is DioError) print(e.request.path);
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
  }

  Future<ScoreData> getScores({
    GeneralCallback<ScoreData> callback,
  }) async {
    try {
      dio.options.headers['Connection'] =
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';
      dio.options.headers['Accept'] = 'keep-alive';
      final response = await dio.get(
        SCORE,
        // data: FormData.fromMap(
        //   {
        //     'Yms': '109-1',
        //   },
        // ),
      );
      final rawHtml = response.data;
      if (kDebugMode) debugPrint(rawHtml);
      final courseData = CourseParser.scores(rawHtml);
      return callback != null ? callback.onSuccess(courseData) : courseData;
    } catch (e) {
      if (e is DioError) print(e.request.path);
      callback?.onError(GeneralResponse.unknownError());
      throw e;
    }
  }
}

class CourseParser {
  static CourseData courseTable(rawHtml) {
    final courseData = CourseData();
    return courseData;
  }

  static ScoreData scores(rawHtml) {
    final scoreData = ScoreData();
    return scoreData;
  }
}
