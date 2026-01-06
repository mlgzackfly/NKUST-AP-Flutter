import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:crypto/crypto.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:nkust_ap/api/api_endpoints.dart';
import 'package:nkust_ap/api/base_api_helper.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/api/mixins/retryable.dart';
import 'package:nkust_ap/api/parser/api_tool.dart';
import 'package:nkust_ap/api/parser/bus_parser.dart';
import 'package:nkust_ap/config/constants.dart';
import 'package:nkust_ap/models/booking_bus_data.dart';
import 'package:nkust_ap/models/bus_data.dart';
import 'package:nkust_ap/models/bus_reservations_data.dart';
import 'package:nkust_ap/models/bus_violation_records_data.dart';
import 'package:nkust_ap/models/cancel_bus_data.dart';

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class BusEncrypt {
  //0 is from first, 1 is from last.
  static int? seedDirection;

  static String? seedValue;

  BusEncrypt({required String jsCode}) {
    jsEncryptCodeParser(jsCode);
  }

  void jsEncryptCodeParser(String content) {
    // http://bus.kuas.edu.tw/API/Scripts/a1
    final RegExp seedFromFirstRegex = RegExp(r"encA2\('((\d|\w){0,32})'");
    final RegExp seedFromLastRegex =
        RegExp(r"encA2\(e(\w|\d|\s|\W){0,3}'((\d|\w){0,32})'\)");

    final Iterable<RegExpMatch> firstMatches =
        seedFromFirstRegex.allMatches(content);
    final Iterable<RegExpMatch> lastMatches =
        seedFromLastRegex.allMatches(content);
    String? seedFromFirst;
    String? seedFromLast;

    if (firstMatches.isNotEmpty) {
      seedFromFirst = firstMatches.toList()[firstMatches.length - 1].group(1);
    }
    if (lastMatches.isNotEmpty) {
      seedFromLast = lastMatches.toList()[lastMatches.length - 1].group(2);
    }
    findEndString(content, seedFromFirst);
    if (findEndString(content, seedFromFirst) >
        findEndString(content, seedFromLast)) {
      seedDirection = 0;
      seedValue = seedFromFirst;
      return;
    }
    seedDirection = 1;
    seedValue = seedFromLast;
  }

  String encA1(String value) {
    if (seedDirection == null || seedValue == null) {
      throw Exception('Seed get error');
    }
    if (seedDirection == 0) {
      return generateMd5('$seedValue$value');
    }
    return generateMd5('$value$seedValue');
  }

  String loginEncrypt(String username, String password) {
    String g = '419191959';
    String i = '930672927';
    String j = '1088434686';
    String k = '260123741';

    g = generateMd5('J$g');
    i = generateMd5('E$i');
    j = generateMd5('R$j');
    k = generateMd5('Y$k');
    final String usernameMD5 = generateMd5(username + encA1(g));
    final String passwordMD5 =
        generateMd5('$username${password}JERRY${encA1(i)}');

    String l = generateMd5('$usernameMD5${passwordMD5}KUAS${encA1(j)}');
    l = generateMd5(l + usernameMD5 + encA1('ITALAB') + encA1(k));
    l = generateMd5('$l${password}MIS$k');

    return json.encode(
      <String, String>{
        'a': l,
        'b': g,
        'c': i,
        'd': j,
        'e': k,
        'f': passwordMD5,
      },
    );
  }

  int findEndString(String content, String? targetString) {
    if (targetString == null) {
      return -1;
    }
    int index = -1;
    int res = 0;
    while (res != -1) {
      res = content.indexOf(targetString, res);
      if (res != -1) {
        index = res;
        res += 1;
      }
    }
    return index;
  }
}

class BusHelper extends BaseApiHelper {
  BusHelper() {
    dioInit();
  }

  static BusHelper? _instance;

  /// Bus API has higher retry limit due to frequent session timeouts.
  @override
  int get retryLimit => Constants.busRetryLimit;

  bool isLogin = false;

  static String? userTimeTableSelectCacheKey;
  static String userRecordsCacheKey = '${Helper.username}_busUserRecords';
  static String userViolationRecordsCacheKey =
      '${Helper.username}_busViolationRecords';
  static late BusEncrypt busEncryptObject;
  static String busHost = '${ApiEndpoints.busKuasBaseUrl}/';

  @override
  String get baseUrl => ApiEndpoints.busKuasBaseUrl;

  @override
  bool get clearCacheOnInit => true;

  //ignore: prefer_constructors_over_static_methods
  static BusHelper get instance {
    return _instance ??= BusHelper();
  }

  /// Resets the singleton instance, disposing of all resources.
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  Future<void> loginPrepare() async {
    // Get global cookie. Only cookies get from the root directory can be used.
    await dio.head(busHost);
    // This function will download encrypt js bus login required.
    final Response<String> res = await dio.get<String>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasScripts),
    );
    busEncryptObject = BusEncrypt(jsCode: res.data!);
  }

  Future<Map<String, dynamic>?> busLogin() async {
    /*
    Return type Map<String, dynamic>(from Json)
    response data (from NKUST)
    {
      'success': true,
      'code': 200,
      'message': 'User Name',
      'count': 1,
      'data': {}
    }
    Code:
    200: Login success.
    400: Wrong campus or not found user.
    302: Wrong password.
    */
    if (Helper.username == null || Helper.password == null) {
      throw StateError('Retry limit exceeded');
    }

    await loginPrepare();

    final Response<Map<String, dynamic>> res =
        await dio.post<Map<String, dynamic>>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasLogin),
      data: <String, String?>{
        'account': Helper.username,
        'password': Helper.password,
        'n': busEncryptObject.loginEncrypt(
          Helper.username!,
          Helper.password!,
        ),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (res.data!['code'] == 200 && res.data!['success'] == true) {
      isLogin = true;
    }
    return res.data;
  }

  Future<BusData> timeTableQuery({
    required String year,
    required String month,
    required String day,
  }) async {
    if (!canRetry) {
      throw const RetryLimitExceededException();
    }

    if (!isLogin) {
      await busLogin();
    }

    final Future<BusReservationsData> userRecord = busReservations();

    userTimeTableSelectCacheKey =
        '${Helper.username}_busCacheTimTable$year$month$day';
    Options options;
    dynamic requestData;
    if (!Helper.isSupportCacheData) {
      requestData = <String, dynamic>{
        'data': json.encode(<String, String?>{
          'y': year,
          'm': month,
          'd': day,
        }),
        'operation': '全部',
        'page': 1,
        'start': 0,
        'limit': Constants.busTimeTablePageSize,
      };
      options = Options(contentType: Headers.formUrlEncodedContentType);
    } else {
      dio.options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      requestData = formUrlEncoded(
        <String, dynamic>{
          'data': json.encode(<String, String?>{
            'y': year,
            'm': month,
            'd': day,
          }),
          'operation': '全部',
          'page': 1,
          'start': 0,
          'limit': Constants.busTimeTablePageSize,
        },
      );
      options = buildCacheOptions(
        Constants.defaultCacheDuration,
        primaryKey: userTimeTableSelectCacheKey,
      );
    }
    final Response<Map<String, dynamic>> res =
        await dio.post<Map<String, dynamic>>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasFrequencies),
      data: requestData,
      options: options,
    );

    if (res.data!['code'] == 400 &&
        (res.data!['message'] as String).contains('未登入或是登入逾')) {
      // Remove fail cache.
      if (Helper.isSupportCacheData) {
        cacheManager?.delete(userTimeTableSelectCacheKey!);
      }
      incrementRetryCount();
      await busLogin();
      return timeTableQuery(year: year, month: month, day: day);
    }
    resetRetryCount();
    return BusData.fromJson(
      busTimeTableParser(res.data!, busReservations: await userRecord),
    );
  }

  Future<BookingBusData> busBook({required String busId}) async {
    if (!canRetry) {
      throw const RetryLimitExceededException();
    }

    if (!isLogin) {
      await busLogin();
    }
    if (Helper.isSupportCacheData) {
      cacheManager?.delete(userRecordsCacheKey);
      cacheManager?.delete(userTimeTableSelectCacheKey!);
    }

    final Response<Map<String, dynamic>> res =
        await dio.post<Map<String, dynamic>>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasReservesAdd),
      data: <String, dynamic>{
        'busId': int.parse(busId),
      },
    );

    if (res.data!['code'] == 400 &&
        (res.data!['message'] as String).contains('未登入或是登入逾')) {
      incrementRetryCount();
      await busLogin();
      return busBook(busId: busId);
    }
    return BookingBusData.fromJson(res.data!);
  }

  Future<CancelBusData> busUnBook({required String busId}) async {
    if (!canRetry) {
      throw const RetryLimitExceededException();
    }

    if (!isLogin) {
      await busLogin();
    }
    final Response<Map<String, dynamic>> res =
        await dio.post<Map<String, dynamic>>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasReservesRemove),
      data: <String, dynamic>{
        'reserveId': int.parse(busId),
      },
    );

    if (res.data!['code'] == 400 &&
        (res.data!['message'] as String).contains('未登入或是登入逾')) {
      incrementRetryCount();
      await busLogin();
      return busUnBook(busId: busId);
    }
    // Clear all cookie, because we can't sure user on which page.
    // two page can cencel bus.
    if (Helper.isSupportCacheData) cacheManager?.clearAll();

    return CancelBusData.fromJson(res.data!);
  }

  Future<BusReservationsData> busReservations() async {
    if (!canRetry) {
      throw const RetryLimitExceededException();
    }

    if (!isLogin) {
      await busLogin();
    }
    Options options;
    dynamic requestData;
    if (!Helper.isSupportCacheData) {
      requestData = <String, dynamic>{
        'page': 1,
        'start': 0,
        'limit': Constants.busTimeTablePageSize,
      };
      options = Options(contentType: Headers.formUrlEncodedContentType);
    } else {
      dio.options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      requestData = formUrlEncoded(<String, dynamic>{
        'page': 1,
        'start': 0,
        'limit': Constants.busTimeTablePageSize,
      });
      options = buildCacheOptions(
        Constants.defaultCacheDuration,
        primaryKey: userRecordsCacheKey,
      );
    }

    final Response<Map<String, dynamic>> res =
        await dio.post<Map<String, dynamic>>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasReservesOwn),
      data: requestData,
      options: options,
    );

    if (res.data!['code'] == 400 &&
        (res.data!['message'] as String).contains('未登入或是登入逾')) {
      if (Helper.isSupportCacheData) cacheManager?.delete(userRecordsCacheKey);
      incrementRetryCount();
      await busLogin();
      return busReservations();
    }
    resetRetryCount();
    return BusReservationsData.fromJson(
      busReservationsParser(res.data!),
    );
  }

  Future<BusViolationRecordsData> busViolationRecords() async {
    if (!canRetry) {
      throw const RetryLimitExceededException();
    }

    if (!isLogin) {
      await busLogin();
    }
    Options options;
    dynamic requestData;
    if (!Helper.isSupportCacheData) {
      requestData = <String, int>{
        'page': 1,
        'start': 0,
        'limit': Constants.busViolationPageSize,
      };
      options = Options(contentType: Headers.formUrlEncodedContentType);
    } else {
      dio.options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      requestData = formUrlEncoded(<String, int>{
        'page': 1,
        'start': 0,
        'limit': Constants.busViolationPageSize,
      });
      options = buildCacheOptions(
        Constants.defaultCacheDuration,
        primaryKey: userViolationRecordsCacheKey,
      );
    }

    final Response<Map<String, dynamic>> res =
        await dio.post<Map<String, dynamic>>(
      ApiEndpoints.getBusKuasUrl(ApiEndpoints.busKuasIllegalsOwn),
      data: requestData,
      options: options,
    );

    if (res.data!['code'] == 400 &&
        (res.data!['message'] as String).contains('未登入或是登入逾')) {
      if (Helper.isSupportCacheData) {
        cacheManager?.delete(userViolationRecordsCacheKey);
      }
      incrementRetryCount();
      await busLogin();
      return busViolationRecords();
    }
    resetRetryCount();
    return BusViolationRecordsData.fromJson(
      busViolationRecordsParser(res.data!),
    );
  }
}
