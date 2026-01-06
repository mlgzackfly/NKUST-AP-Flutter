import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:nkust_ap/api/ap_status_code.dart';
import 'package:nkust_ap/api/api_endpoints.dart';
import 'package:nkust_ap/api/base_api_helper.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/api/leave_helper.dart';
import 'package:nkust_ap/api/mobile_nkust_helper.dart';
import 'package:nkust_ap/api/parser/ap_parser.dart';
import 'package:nkust_ap/api/parser/api_tool.dart';
import 'package:nkust_ap/models/login_response.dart';
import 'package:nkust_ap/models/midterm_alerts_data.dart';
import 'package:nkust_ap/models/reward_and_penalty_data.dart';
import 'package:nkust_ap/models/room_data.dart';
import 'package:nkust_ap/utils/captcha_utils.dart';

class WebApHelper extends BaseApiHelper {
  static WebApHelper? _instance;

  bool isLogin = false;

  String? pictureUrl;

  @override
  String get baseUrl => ApiEndpoints.webApBaseUrl;

  //cache key name
  static String get semesterCacheKey => 'semesterCacheKey';

  static String get coursetableCacheKey =>
      '${Helper.username}_coursetableCacheKey';

  static String get scoresCacheKey => '${Helper.username}_scoresCacheKey';

  static String get userInfoCacheKey => '${Helper.username}_userInfoCacheKey';

  //ignore: prefer_constructors_over_static_methods
  static WebApHelper get instance {
    return _instance ??= WebApHelper();
  }

  /// Resets the singleton instance, disposing of all resources.
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  WebApHelper() {
    dioInit();
  }

  Future<void> logout() async {
    try {
      await dio.post(ApiEndpoints.getWebApUrl(ApiEndpoints.webApLogout));
    } catch (_) {}
  }

  Future<Uint8List?> getValidationImage() async {
    final Response<Uint8List> response = await dio.get<Uint8List>(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApValidateCode),
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, dynamic>{
          'Referer': ApiEndpoints.getWebApUrl(ApiEndpoints.webApIndexMain),
        },
      ),
    );
    return response.data;
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    //
    /*
    Retrun type Int
    -1: captcha error
    0 : Login Success
    1 : Password error or not found user
    2 : Relogin
    3 : Not found login message
    */
    //
    for (int i = 0; i < 5; i++) {
      try {
        final String captchaCode = await CaptchaUtils.extractByEucDist(
          bodyBytes: (await getValidationImage())!,
        );

        final Response<dynamic> res = await dio.post(
          ApiEndpoints.getWebApUrl(ApiEndpoints.webApLogin),
          data: <String, String>{
            'uid': username,
            'pwd': password,
            'etxt_code': captchaCode,
          },
          options: Options(contentType: 'application/x-www-form-urlencoded'),
        );
        Helper.username = username;
        Helper.password = password;
        final int code = WebApParser.instance.apLoginParser(res.data);
        switch (code) {
          case -1:
            //Captcha error, go retry.
            break;
          case 4:
            //Stay old password and relogin.
            await stayOldPwd();
            return login(username: username, password: password);
          case 0:
            isLogin = true;
            return LoginResponse(
              expireTime: DateTime.now().add(const Duration(hours: 6)),
            );
          case 1:
            throw GeneralResponse(
              statusCode: ApStatusCode.userDataError,
              message: 'username or password error',
            );
          case 5:
            throw GeneralResponse(
              statusCode: ApStatusCode.passwordFiveTimesError,
              message: 'username or password error',
            );
          case 500:
            throw GeneralResponse(
              statusCode: ApStatusCode.schoolServerError,
              message: 'school server error',
            );
          default:
            throw GeneralResponse(
              statusCode: code,
              message: 'unknown error',
            );
        }
      } catch (e, s) {
        CrashlyticsUtil.instance.recordError(e, s);
      }
    }
    //
    throw GeneralResponse(
      statusCode: ApStatusCode.unknownError,
      message: 'captcha error or unknown error',
    );
  }

  Future<Response<dynamic>> stayOldPwd() async {
    final Response<dynamic> res = await dio.post(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApKeepOldPassword),
      data: <String, String>{
        'cpwd': '',
        'opwd': '',
        'spwd': '',
      },
      options: Options(
        followRedirects: false,
        validateStatus: (int? status) {
          return status! < 500;
        },
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
    return res;
  }

  Future<LoginResponse> loginToMobile() async {
    // Login leave.nkust from webap.
    if (!canRetry) {
      throw GeneralResponse(
        statusCode: ApStatusCode.networkConnectFail,
        message: 'Login exceeded retry limit',
      );
    }
    await checkLogin();
    await apQuery('ag304_01', null);

    Response<String> res = await dio.post<String>(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApFunction),
      data: <String, String>{'fncid': 'CK004'},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );

    final Map<String, dynamic> skyDirectData =
        WebApParser.instance.webapToleaveParser(res.data);

    res = await tempDio.post(
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobileLoginByPortal),
      data: skyDirectData,
      options: Options(
        followRedirects: false,
        validateStatus: (int? status) {
          return status! < 500;
        },
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    if (res.statusCode == 200 && res.data!.contains('/Student/Leave/Create')) {
      return LoginResponse(
        expireTime: DateTime.now().add(const Duration(hours: 1)),
      );
    } else {
      throw GeneralResponse(statusCode: ApStatusCode.cancel, message: 'cancel');
    }
  }

  Future<LoginResponse> loginToOosaf() async {
    // Login oosaf.nkust from webap.
    if (!canRetry) {
      throw GeneralResponse(
        statusCode: ApStatusCode.networkConnectFail,
        message: 'Login exceeded retry limit',
      );
    }
    await checkLogin();
    await apQuery('ag304_01', null);

    Response<String> res = await dio.post<String>(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApFunction),
      data: <String, String>{'fncid': 'CK004'},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );

    final Map<String, dynamic> skyDirectData =
        WebApParser.instance.webapToleaveParser(res.data);

    res = await tempDio.post(
      ApiEndpoints.getOosafUrl(ApiEndpoints.oosafLoginByPortal),
      data: skyDirectData,
      options: Options(
        followRedirects: false,
        validateStatus: (int? status) {
          return status! < 500;
        },
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    if (res.statusCode == 200 && res.data!.contains('/Student/Leave/Create')) {
      return LoginResponse(
        expireTime: DateTime.now().add(const Duration(hours: 1)),
      );
    } else {
      throw GeneralResponse(statusCode: ApStatusCode.cancel, message: 'cancel');
    }
  }

  Future<LoginResponse> loginToStdsys() async {
    // Login stdsys.nkust from webap.
    if (!canRetry) {
      throw GeneralResponse(
        statusCode: ApStatusCode.networkConnectFail,
        message: 'Login exceeded retry limit',
      );
    }
    await checkLogin();
    await apQuery('ag304_01', null);

    Response<String> res = await dio.post<String>(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApFunction),
      data: <String, String>{'fncid': 'CK004'},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );

    final Map<String, dynamic> skyDirectData =
        WebApParser.instance.webapToleaveParser(res.data);

    res = await tempDio.post(
      ApiEndpoints.getStdSysUrl(ApiEndpoints.stdSysLoginByPortal),
      data: skyDirectData,
      options: Options(
        followRedirects: false,
        validateStatus: (int? status) {
          return status! < 500;
        },
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    if (res.statusCode == 200 && res.data!.contains('/Student/Home/Index')) {
      return LoginResponse(
        expireTime: DateTime.now().add(const Duration(hours: 1)),
      );
    } else {
      throw GeneralResponse(statusCode: ApStatusCode.cancel, message: 'cancel');
    }
  }

  Future<LoginResponse> loginToLeave() async {
    // Login leave.nkust from webap.
    if (!canRetry) {
      throw GeneralResponse(
        statusCode: ApStatusCode.networkConnectFail,
        message: 'Login exceeded retry limit',
      );
    }
    await checkLogin();
    await apQuery('ag304_01', null);

    Response<String> res = await dio.post(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApFunction),
      data: <String, String>{'fncid': 'CK004'},
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    final Map<String?, dynamic> skyDirectData =
        WebApParser.instance.webapToleaveParser(res.data);
    res = await dio.get<String>(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSkyDir),
      queryParameters: <String, dynamic>{
        'u': skyDirectData['uid'],
        'r': skyDirectData['ls_randnum'],
      },
      options: Options(
        followRedirects: false,
        validateStatus: (int? status) {
          return status! < 500;
        },
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
    if (res.data!.contains('masterindex.aspx')) {
      res = await dio.get(
        ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveMasterIndex),
        options: Options(
          followRedirects: false,
          validateStatus: (int? status) {
            return status! < 500;
          },
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      LeaveHelper.instance.isLogin = true;
      return LoginResponse(
        expireTime: DateTime.now().add(const Duration(hours: 1)),
      );
    }
    throw GeneralResponse(statusCode: ApStatusCode.cancel, message: 'cancel');
  }

  Future<LoginResponse?> checkLogin() async {
    return isLogin
        ? null
        : await login(username: Helper.username!, password: Helper.password!);
  }

  Future<Response<dynamic>> apQuery(
    String queryQid,
    Map<String, String?>? queryData, {
    String? cacheKey,
    Duration? cacheExpiredTime,
    bool? bytesResponse,
  }) async {
    /*
    Retrun type Response <Dio>
    */
    if (!canRetry) {
      throw GeneralResponse(
        statusCode: ApStatusCode.networkConnectFail,
        message: 'Login exceeded retry limit',
      );
    }
    await checkLogin();
    final String url = ApiEndpoints.getWebApQueryUrl(queryQid);
    final String refererUrl =
        '${ApiEndpoints.getWebApUrl(ApiEndpoints.webApSystemReferer)}?spath=ag_pro/$queryQid.jsp?';
    Options options;
    dynamic requestData;
    if (cacheKey == null) {
      options = Options(contentType: 'application/x-www-form-urlencoded');
      dio.options.headers['Referer'] = refererUrl;
      if (bytesResponse != null) {
        options.responseType = ResponseType.bytes;
      }
      requestData = queryData;
    } else {
      dio.options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      dio.options.headers['Referer'] = refererUrl;
      Options? otherOptions;
      if (bytesResponse != null) {
        otherOptions = Options(responseType: ResponseType.bytes);
      }
      options = buildConfigurableCacheOptions(
        options: otherOptions,
        maxAge: cacheExpiredTime ?? const Duration(seconds: 60),
        primaryKey: cacheKey,
      );
      requestData = formUrlEncoded(queryData);
    }
    Response<dynamic> request;

    if (bytesResponse != null) {
      request = await dio.post<List<int>>(
        url,
        data: requestData,
        options: options,
      );
    } else {
      request = await dio.post<dynamic>(
        url,
        data: requestData,
        options: options,
      );
    }

    if (WebApParser.instance.apLoginParser(request.data) == 2) {
      if (Helper.isSupportCacheData) cacheManager?.delete(cacheKey!);
      incrementRetryCount();
      await login(username: Helper.username!, password: Helper.password!);
      return apQuery(queryQid, queryData, bytesResponse: bytesResponse);
    }
    resetRetryCount();
    return request;
  }

  Future<UserInfo> userInfoCrawler() async {
    if (!Helper.isSupportCacheData) {
      final Response<dynamic> query = await apQuery('ag003', null);
      final UserInfo data = UserInfo.fromJson(
        WebApParser.instance.apUserInfoParser(query.data as String),
      );
      pictureUrl = data.pictureUrl;
      return data;
    }
    final Response<dynamic> query = await apQuery(
      'ag003',
      null,
      cacheKey: userInfoCacheKey,
      cacheExpiredTime: const Duration(hours: 6),
    );

    final Map<String, dynamic> parsedData =
        WebApParser.instance.apUserInfoParser(query.data as String);
    if (parsedData['id'] == null) {
      cacheManager?.delete(userInfoCacheKey);
    }
    final UserInfo data = UserInfo.fromJson(
      WebApParser.instance.apUserInfoParser(query.data as String),
    );
    pictureUrl = data.pictureUrl;
    return data;
  }

  Future<Uint8List?> getUserPicture() async {
    dio.options.headers['Accept'] =
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8';
    final Response<Uint8List> response = await dio.get<Uint8List>(
      pictureUrl!,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );
    return response.data;
  }

  Future<SemesterData> semesters() async {
    if (!Helper.isSupportCacheData) {
      final Response<dynamic> query = await apQuery('ag304_01', null);
      return SemesterData.fromJson(
        WebApParser.instance.semestersParser(query.data as String),
      );
    }
    final Response<dynamic> query = await apQuery(
      'ag304_01',
      null,
      cacheKey: semesterCacheKey,
      cacheExpiredTime: const Duration(hours: 3),
    );
    final Map<String, dynamic> parsedData =
        WebApParser.instance.semestersParser(query.data as String);
    if ((parsedData['data'] as List<dynamic>).isEmpty) {
      //data error delete cache
      cacheManager?.delete(semesterCacheKey);
    }

    return SemesterData.fromJson(parsedData);
  }

  Future<Response<Uint8List>> getEnrollmentLetter() async {
    await loginToStdsys();

    final List<Cookie> cookies =
        await cookieJar.loadForRequest(Uri.parse(ApiEndpoints.stdSysBaseUrl));
    final String cookieHeader = cookies
        .map((Cookie cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');

    final Response<Uint8List> response = await dio.get<Uint8List>(
      ApiEndpoints.getStdSysUrl(ApiEndpoints.stdSysDocDownload),
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, dynamic>{
          'Referer': ApiEndpoints.getStdSysUrl(ApiEndpoints.stdSysDocStatus),
          'Cookie': cookieHeader,
        },
      ),
    );
    return response;
  }

  Future<ScoreData> scores(String? years, String? semesterValue) async {
    await checkLogin();
    if (!Helper.isSupportCacheData) {
      final Response<dynamic> query = await apQuery(
        'ag008',
        <String, String?>{'arg01': years, 'arg02': semesterValue},
      );
      return ScoreData.fromJson(
        WebApParser.instance.scoresParser(query.data as String),
      );
    }
    final Response<dynamic> query = await apQuery(
      'ag008',
      <String, String?>{'arg01': years, 'arg02': semesterValue},
      cacheKey: '${scoresCacheKey}_${years}_$semesterValue',
      cacheExpiredTime: const Duration(hours: 6),
    );

    final Map<String, dynamic> parsedData =
        WebApParser.instance.scoresParser(query.data as String);
    if ((parsedData['scores'] as List<dynamic>).isEmpty) {
      cacheManager?.delete('${scoresCacheKey}_${years}_$semesterValue');
    }

    return ScoreData.fromJson(
      parsedData,
    );
  }

  Future<CourseData> getCourseTable({
    String? year,
    String? semester,
  }) async {
    if (!Helper.isSupportCacheData) {
      final Response<dynamic> query = await apQuery(
        'ag222',
        <String, String?>{
          'arg01': year,
          'arg02': semester,
        },
        bytesResponse: true,
      );
      return CourseData.fromJson(
        await WebApParser.instance.coursetableParser(query.data),
      );
    }
    final Response<dynamic> query = await apQuery(
      'ag222',
      <String, String?>{'arg01': year, 'arg02': semester},
      cacheKey: '${coursetableCacheKey}_${year}_$semester',
      cacheExpiredTime: const Duration(hours: 6),
      bytesResponse: true,
    );
    final Map<String, dynamic> parsedData =
        await WebApParser.instance.coursetableParser(query.data);
    if ((parsedData['courses'] as List<dynamic>).isEmpty) {
      cacheManager?.delete('${coursetableCacheKey}_${year}_$semester');
    }
    return CourseData.fromJson(
      parsedData,
    );
  }

  Future<MidtermAlertsData> midtermAlerts(
    String? years,
    String? semesterValue,
  ) async {
    final Response<dynamic> query = await apQuery(
      'ag009',
      <String, String?>{'arg01': years, 'arg02': semesterValue},
    );

    return MidtermAlertsData.fromJson(
      WebApParser.instance.midtermAlertsParser(query.data as String),
    );
  }

  Future<RewardAndPenaltyData> rewardAndPenalty(
    String? years,
    String? semesterValue,
  ) async {
    final Response<dynamic> query = await apQuery(
      'ak010',
      <String, String?>{'arg01': years, 'arg02': semesterValue},
    );

    return RewardAndPenaltyData.fromJson(
      WebApParser.instance.rewardAndPenaltyParser(query.data as String),
    );
  }

  Future<RoomData> roomList(
    String cmpAreaId,
    String? years,
    String? semesterValue,
  ) async {
    /*
    cmpAreaId
    1=建工/2=燕巢/3=第一/4=楠梓/5=旗津
    */
    final Response<dynamic> query = await apQuery(
      'ag302_01',
      <String, String>{
        'yms_yms': '$years#$semesterValue',
        'cmp_area_id': cmpAreaId,
      },
    );

    return RoomData.fromJson(
      WebApParser.instance.roomListParser(query.data as String),
    );
  }

  Future<CourseData> roomCourseTableQuery(
    String? roomId,
    String? years,
    String? semesterValue,
  ) async {
    final Response<dynamic> query = await apQuery(
      'ag302_02',
      <String, String?>{'room_id': roomId, 'yms_yms': '$years#$semesterValue'},
      bytesResponse: true,
    );

    return CourseData.fromJson(
      WebApParser.instance.roomCourseTableQueryParser(query.data),
    );
  }

  Future<void> loginVms() async {
    await MobileNkustHelper.instance.loginVms(
      username: Helper.username!,
      password: Helper.password!,
    );
  }
}
