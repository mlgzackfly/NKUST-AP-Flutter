import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ap_common/ap_common.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/api/ap_helper.dart';
import 'package:nkust_ap/api/ap_status_code.dart';
import 'package:nkust_ap/api/api_endpoints.dart';
import 'package:nkust_ap/api/base_api_helper.dart';
import 'package:nkust_ap/api/mixins/cookie_manageable.dart';
import 'package:nkust_ap/api/parser/mobile_nkust_parser.dart'
    show BusInfo, MobileNkustParser;
import 'package:nkust_ap/config/constants.dart';
import 'package:nkust_ap/models/booking_bus_data.dart';
import 'package:nkust_ap/models/bus_data.dart' show BusData, BusTime;
import 'package:nkust_ap/models/bus_reservations_data.dart'
    show BusReservation, BusReservationsData;
import 'package:nkust_ap/models/bus_violation_records_data.dart'
    show BusViolationRecordsData, Reservation;
import 'package:nkust_ap/models/cancel_bus_data.dart';
import 'package:nkust_ap/models/login_response.dart';
import 'package:nkust_ap/models/midterm_alerts_data.dart';
import 'package:nkust_ap/models/mobile_cookies_data.dart';
import 'package:nkust_ap/pages/mobile_nkust_page.dart';

class MobileNkustHelper extends BaseApiHelper with CookieManageable {
  MobileNkustHelper() {
    // Select random user agent before initialization
    final Random random = Random();
    final int i = random.nextInt(userAgentList.length);
    _selectedUserAgent = userAgentList[i];
    _initDio();
  }

  late String _selectedUserAgent;

  @override
  String get baseUrl => ApiEndpoints.mobileBaseUrl;

  static String get mobileBaseUrl => ApiEndpoints.mobileBaseUrl;
  static String get busBaseUrl => ApiEndpoints.vmsBaseUrl;

  static String get loginUrl => mobileBaseUrl;
  static String get homeUrl =>
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobileHome);
  static String get courseUrl =>
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobileCourse);
  static String get scoreUrl =>
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobileScore);
  static String get pictureUrl =>
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobilePhoto);
  static String get midAlertsUrl =>
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobileMidAlerts);
  static String get busTimetablePageUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusTimetablePage);
  static String get busTimetableApiUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusTimetableApi);
  static String get busBookApiUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusBook);
  static String get busUnbookApiUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusUnbook);
  static String get busUserRecordPageUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusReservePage);
  static String get busUserRecordApiUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusReserveApi);
  static String get busViolationRecordsPageUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusViolationPage);
  static String get busViolationRecordsApiUrl =>
      ApiEndpoints.getVmsUrl(ApiEndpoints.vmsBusViolationApi);

  static String get checkExpireUrl =>
      ApiEndpoints.getMobileUrl(ApiEndpoints.mobileCheckExpire);

  static MobileNkustHelper? _instance;

  static bool get isSupport =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  String get userAgent => _selectedUserAgent;

  @override
  String get cookieCheckUrl => checkExpireUrl;

  static List<String> userAgentList = <String>[
    'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.16 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1667.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2762.73 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2226.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/30.0.1599.17 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.62 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1623.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML like Gecko) Chrome/44.0.2403.155 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.93 Safari/537.36',
  ];

  //ignore: prefer_constructors_over_static_methods
  static MobileNkustHelper get instance {
    return _instance ??= MobileNkustHelper();
  }

  /// Resets the singleton instance, disposing of all resources.
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  /// MobileNkustHelper uses custom Dio initialization with dual cookie
  /// managers.
  void _initDio() {
    dioInit();
    dio.options.followRedirects = false;
    // Clear default interceptors and add custom cookie managers
    dio.interceptors.clear();
    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(PrivateCookieManager(WebApHelper.instance.cookieJar));
    cookieJar.loadForRequest(Uri.parse(baseUrl));
  }

  Future<Response<dynamic>> generalRequest(
    String url, {
    Map<String, dynamic>? firstRequestHeader,
    String? otherRequestUrl,
    Map<String, dynamic>? otherRequestHeader,
    Map<String, dynamic>? data,
  }) async {
    Response<dynamic> response = await dio.get(
      url,
      options: Options(headers: firstRequestHeader),
    );

    if (data != null) {
      if (otherRequestUrl != null) {
        final Map<String, dynamic> requestData = <String, dynamic>{
          '__RequestVerificationToken': MobileNkustParser.getCSRF(
            response.data,
          ),
        };
        requestData.addAll(data);

        response = await dio.post<dynamic>(
          otherRequestUrl,
          data: requestData,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: otherRequestHeader,
          ),
        );
      }
    }
    return response;
  }

  Future<void> loginVms({
    required String username,
    required String password,
  }) async {
    try {
      final Response<dynamic> _ = await generalRequest(
        busBaseUrl,
        otherRequestUrl: busBaseUrl,
        data: <String, dynamic>{
          'Account': username,
          'Password': password,
          'RememberMe': 'true',
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 302) {
        return;
      } else {
        rethrow;
      }
    }
  }

  Future<LoginResponse> login({
    required BuildContext context,
    required String username,
    required String password,
    bool clearCache = false,
  }) async {
    final MobileCookiesData? data = MobileCookiesData.load();
    if (data != null && !clearCache) {
      MobileNkustHelper.instance.setCookieFromData(data);
      final bool isCookieAlive =
          await MobileNkustHelper.instance.isCookieAlive();
      if (isCookieAlive) {
        final DateTime now = DateTime.now();
        final int lastTime = PreferenceUtil.instance.getInt(
          Constants.mobileCookiesLastTime,
          now.microsecondsSinceEpoch,
        );
        AnalyticsUtil.instance.logEvent(
          'cookies_persistence_time',
          parameters: <String, dynamic>{
            'time': now.microsecondsSinceEpoch - lastTime,
          },
        );
        return LoginResponse();
      }
    }
    if (!context.mounted) return LoginResponse();
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MobileNkustPage(
          username: username,
          password: password,
          clearCache: clearCache,
        ),
      ),
    );
    if (result ?? false) {
      return LoginResponse();
    } else {
      throw GeneralResponse(statusCode: ApStatusCode.cancel, message: 'cancel');
    }
  }

  Future<CourseData> getCourseTable({
    String? year,
    String? semester,
  }) async {
    Response<dynamic> response;
    if (year == null || semester == null) {
      response = await generalRequest(
        courseUrl,
        firstRequestHeader: <String, String>{'Referer': homeUrl},
      );
    } else {
      response = await generalRequest(
        courseUrl,
        data: <String, String>{
          'Yms': '$year-$semester',
        },
        firstRequestHeader: <String, String>{'Referer': courseUrl},
      );
    }

    final dynamic rawHtml = response.data;
    final CourseData courseData = MobileNkustParser.courseTable(rawHtml);
    return courseData;
  }

  Future<MidtermAlertsData> getMidAlerts({
    String? year,
    String? semester,
  }) async {
    Response<dynamic> response;
    if (year == null || semester == null) {
      response = await generalRequest(
        midAlertsUrl,
        firstRequestHeader: <String, String>{'Referer': homeUrl},
      );
    } else {
      response = await generalRequest(
        midAlertsUrl,
        data: <String, String>{'Yms': '$year-$semester'},
        firstRequestHeader: <String, String>{'Referer': midAlertsUrl},
      );
    }

    final dynamic rawHtml = response.data;
    final MidtermAlertsData midtermAlertsData =
        MobileNkustParser.midtermAlerts(rawHtml);
    return midtermAlertsData;
  }

  Future<ScoreData> getScores({
    String? year,
    String? semester,
  }) async {
    Response<dynamic> response;
    if (year == null || semester == null) {
      response = await generalRequest(
        scoreUrl,
        firstRequestHeader: <String, String>{'Referer': homeUrl},
      );
    } else {
      response = await generalRequest(
        scoreUrl,
        data: <String, String>{'Yms': '$year-$semester'},
        firstRequestHeader: <String, String>{'Referer': scoreUrl},
      );
    }

    final dynamic rawHtml = response.data;
    final ScoreData courseData = MobileNkustParser.scores(rawHtml);
    return courseData;
  }

  Future<UserInfo> getUserInfo() async {
    final Response<dynamic> response = await generalRequest(
      homeUrl,
      firstRequestHeader: <String, String>{'Referer': homeUrl},
    );
    final dynamic rawHtml = response.data;
    final UserInfo data = MobileNkustParser.userInfo(rawHtml);
    return data;
  }

  Future<Uint8List?> getUserPicture() async {
    dio.options.headers['Accept'] =
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8';
    final Response<Uint8List> response = await dio.get<Uint8List>(
      pictureUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, String>{'Referer': homeUrl},
      ),
    );
    return response.data;
  }

  Future<BusData> busTimeTableQuery({
    required DateTime fromDateTime,
  }) async {
    // support DateTime or {year,month,day}.
    final String year = fromDateTime.year.toString();
    String month = fromDateTime.month.toString();
    String day = fromDateTime.day.toString();
    for (int i = 0; month.length < 2; i++) {
      month = '0$month';
    }
    for (int i = 0; day.length < 2; i++) {
      day = '0$day';
    }

    //get main CSRF
    final Response<String> request = await dio.get<String>(
      busTimetablePageUrl,
      options: Options(
        headers: <String, String>{
          'Referer': homeUrl,
        },
      ),
    );

    final BusInfo busInfo = MobileNkustParser.busInfo(request.data);

    final List<Response<dynamic>> requestsList = <Response<dynamic>>[];
    final List<List<String>> requestsDataList = <List<String>>[
      <String>['建工', '燕巢'],
      <String>['燕巢', '建工'],
      <String>['第一', '建工'],
      <String>['建工', '第一'],
    ];
    for (final List<String> requestData in requestsDataList) {
      final Response<dynamic> r = await dio.post(
        busTimetableApiUrl,
        data: <String, String>{
          'driveDate': '$year/$month/$day',
          'beginStation': requestData[0],
          'endStation': requestData[1],
          '__RequestVerificationToken': MobileNkustParser.getCSRF(request.data),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: <String, String>{'Referer': busTimetablePageUrl},
        ),
      );
      requestsList.add(r);
    }

    final List<BusTime> timetable = <BusTime>[];

    for (int i = 0; i < requestsList.length; i++) {
      timetable.addAll(
        MobileNkustParser.busTimeTable(
          await requestsList[i].data,
          time: '$year/$month/$day',
          startStation: requestsDataList[i][0],
          endStation: requestsDataList[i][1],
        ),
      );
    }
    return BusData(
      canReserve: busInfo.canReserve,
      description: busInfo.description,
      timetable: timetable,
    );
  }

  Future<BookingBusData> busBook({
    required String busId,
  }) async {
    final Response<dynamic> request = await generalRequest(
      busTimetablePageUrl,
      otherRequestUrl: busBookApiUrl,
      data: <String, String>{'busId': busId},
      firstRequestHeader: <String, String>{'Referer': homeUrl},
      otherRequestHeader: <String, String>{'Referer': busTimetablePageUrl},
    );

    Map<String, dynamic>? data;
    if (request.data is String &&
        request.headers['Content-Type']![0].contains('text/html')) {
      data = jsonDecode(request.data as String) as Map<String, dynamic>;
    } else if (request.data is Map<String, dynamic>) {
      data = request.data as Map<String, dynamic>;
    }
    return BookingBusData(
      success: (data!['success'] as bool) && data['title'] == '預約成功',
    );
  }

  Future<CancelBusData> busUnBook({
    required String busId,
  }) async {
    final Response<dynamic> request = await generalRequest(
      busTimetablePageUrl,
      otherRequestUrl: busUnbookApiUrl,
      data: <String, String>{'reserveId': busId},
      firstRequestHeader: <String, String>{'Referer': homeUrl},
      otherRequestHeader: <String, String>{'Referer': busTimetablePageUrl},
    );

    Map<String, dynamic>? data;
    if (request.data is String &&
        request.headers['Content-Type']![0].contains('text/html')) {
      data = jsonDecode(request.data as String) as Map<String, dynamic>;
    } else if (request.data is Map<String, dynamic>) {
      data = request.data as Map<String, dynamic>;
    }
    return CancelBusData(
      success: (data!['success'] as bool) && data['title'] == '取消成功',
    );
  }

  Future<BusReservationsData> busUserRecord() async {
    //get main CSRF
    final Response<dynamic> request = await dio.get(
      busUserRecordPageUrl,
      options: Options(headers: <String, String>{'Referer': homeUrl}),
    );

    final List<Response<dynamic>> requestsList = <Response<dynamic>>[];
    final List<List<String>> requestsDataList = <List<String>>[
      <String>['建工', '燕巢'],
      <String>['燕巢', '建工'],
      <String>['第一', '建工'],
      <String>['建工', '第一'],
    ];
    for (final List<String> requestData in requestsDataList) {
      final Response<dynamic> r = await dio.post(
        busUserRecordApiUrl,
        data: <String, dynamic>{
          'reserveStateCode': 0,
          'beginStation': requestData[0],
          'endStation': requestData[1],
          'pageNum': 1,
          'pageSize': Constants.mobilePageSize,
          '__RequestVerificationToken': MobileNkustParser.getCSRF(request.data),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: <String, String>{'Referer': busUserRecordPageUrl},
        ),
      );
      requestsList.add(r);
    }

    final List<BusReservation> reservations = <BusReservation>[];

    for (int i = 0; i < requestsList.length; i++) {
      // add <table> tag to avoid parser error.
      reservations.addAll(
        MobileNkustParser.busUserRecords(
          '<table>${await requestsList[i].data}</table>',
          startStation: requestsDataList[i][0],
          endStation: requestsDataList[i][1],
        ),
      );
    }

    return BusReservationsData(reservations: reservations);
  }

  Future<BusViolationRecordsData> busViolationRecords() async {
    // paid request
    final Response<dynamic> paidRequest = await generalRequest(
      busViolationRecordsPageUrl,
      otherRequestUrl: busViolationRecordsApiUrl,
      data: <String, dynamic>{
        'paid': true,
        'pageNum': 1,
        'pageSize': 100,
      },
      firstRequestHeader: <String, String>{
        'Referer': homeUrl,
      },
      otherRequestHeader: <String, String>{
        'Referer': busViolationRecordsPageUrl,
      },
    );
    // not pay request
    final Response<dynamic> notPaidRequest = await generalRequest(
      busViolationRecordsPageUrl,
      otherRequestUrl: busViolationRecordsApiUrl,
      data: <String, dynamic>{
        'paid': false,
        'pageNum': 1,
        'pageSize': 100,
      },
      firstRequestHeader: <String, String>{
        'Referer': homeUrl,
      },
      otherRequestHeader: <String, String>{
        'Referer': busViolationRecordsPageUrl,
      },
    );

    final List<Reservation> reservations = <Reservation>[];
    reservations.addAll(
      MobileNkustParser.busViolationRecords(
        '<table> ${paidRequest.data} </table>',
        paidStatus: true,
      ),
    );
    reservations.addAll(
      MobileNkustParser.busViolationRecords(
        '<table> ${notPaidRequest.data} </table>',
        paidStatus: false,
      ),
    );

    return BusViolationRecordsData(reservations: reservations);
  }
}
