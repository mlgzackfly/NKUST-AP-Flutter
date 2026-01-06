import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' show parse;
import 'package:http_parser/http_parser.dart';
import 'package:nkust_ap/api/ap_helper.dart';
import 'package:nkust_ap/api/ap_status_code.dart';
import 'package:nkust_ap/api/api_endpoints.dart';
import 'package:nkust_ap/api/base_api_helper.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/api/mixins/cookie_manageable.dart';
import 'package:nkust_ap/api/parser/leave_parser.dart';
import 'package:nkust_ap/models/leave_data.dart';
import 'package:nkust_ap/models/leave_submit_data.dart';
import 'package:nkust_ap/models/leave_submit_info_data.dart';
import 'package:nkust_ap/models/login_response.dart';
import 'package:nkust_ap/pages/leave_nkust_page.dart';

class LeaveHelper extends BaseApiHelper with CookieManageable {
  LeaveHelper() {
    _initDio();
  }

  static String get basePath => ApiEndpoints.leaveBaseUrl;
  static String get home =>
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveMasterIndex);

  static LeaveHelper? _instance;

  //ignore: prefer_constructors_over_static_methods
  static LeaveHelper get instance {
    return _instance ??= LeaveHelper();
  }

  /// Resets the singleton instance, disposing of all resources.
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  int reLoginReTryCountsLimit = 3;
  int reLoginReTryCounts = 0;

  bool? isLogin;

  @override
  String get baseUrl => ApiEndpoints.leaveBaseUrl;

  @override
  Map<String, dynamic> get additionalHeaders => <String, dynamic>{
        'Origin': 'http://${ApiEndpoints.leaveHost}',
        'Upgrade-Insecure-Requests': '1',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Referer': ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveLogon),
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7,ja;q=0.6',
      };

  /// LeaveHelper shares cookie jar with WebApHelper for SSO support.
  void _initDio() {
    dioInit();
    // Override to use WebApHelper's cookie jar for SSO
    cookieJar = WebApHelper.instance.cookieJar;
    dio.interceptors.clear();
    dio.interceptors.add(PrivateCookieManager(cookieJar));
    dio.options.headers.addAll(additionalHeaders);
  }

  Future<LoginResponse> login({
    required BuildContext context,
    required String username,
    required String password,
    bool clearCache = false,
  }) async {
    // final data = MobileCookiesData.load();
    // if (data != null && !clearCache) {
    //   MobileNkustHelper.instance.setCookieFromData(data);
    //   final isCookieAlive = await MobileNkustHelper.instance.isCookieAlive();
    //   if (isCookieAlive) {
    //     final now = DateTime.now();
    //     final lastTime = PreferenceUtil.instance.getInt(
    //       Constants.MOBILE_COOKIES_LAST_TIME,
    //       now.microsecondsSinceEpoch,
    //     );
    //     AnalyticsUtil.analytics.logEvent(
    //       name: 'cookies_persistence_time',
    //       parameters: {
    //         'time': now.microsecondsSinceEpoch - lastTime,
    //       },
    //     );
    //     return LoginResponse();
    //   }
    // }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => LeaveNkustPage(
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

  Future<LeaveData> getLeaves({String? year, String? semester}) async {
    if (Helper.username == null || Helper.password == null) {
      throw StateError('Retry limit exceeded');
    }
    if (reLoginReTryCounts > reLoginReTryCountsLimit) {
      throw StateError('Retry limit exceeded');
    }
    if (!(isLogin ?? false)) {
      await WebApHelper.instance.loginToLeave();
      reLoginReTryCounts++;
    }
    final Response<String> res = await dio.get<String>(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveQuery),
    );
    final Map<String?, dynamic> requestData = allInputValueParser(res.data);
    requestData[r'ctl00$ContentPlaceHolder1$SYS001$DropDownListYms'] =
        '$year-$semester';
    requestData[r'ctl00$ContentPlaceHolder1$Button1	'] = '確定送出';
    requestData.remove(r'ctl00$ButtonLogOut');
    final Response<String> queryRequest = await dio.post<String>(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveQuery),
      data: requestData,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    return LeaveData.fromJson(leaveQueryParser(queryRequest.data));
  }

  Future<LeaveSubmitInfoData> getLeavesSubmitInfo() async {
    if (Helper.username == null || Helper.password == null) {
      throw StateError('Retry limit exceeded');
    }
    if (reLoginReTryCounts > reLoginReTryCountsLimit) {
      throw StateError('Retry limit exceeded');
    }
    if (!(isLogin ?? false)) {
      await WebApHelper.instance.loginToLeave();
      reLoginReTryCounts++;
    }
    Response<String> res = await dio.get<String>(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
    );
    Map<String?, dynamic> requestData = hiddenInputGet(res.data);
    requestData[r'ctl00$ContentPlaceHolder1$CK001$ButtonEnter'] = '進入請假作業';

    res = await dio.post(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
      data: requestData,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    final String fakeDate =
        '${DateTime.now().year - 1911}/${DateTime.now().month}/${DateTime.now().day}';
    requestData = hiddenInputGet(res.data, removeTdElement: true);
    requestData[r'ctl00$ContentPlaceHolder1$CK001$DateUCCBegin$text1'] =
        fakeDate;
    requestData[r'ctl00$ContentPlaceHolder1$CK001$DateUCCEnd$text1'] = fakeDate;
    requestData[r'ctl00$ContentPlaceHolder1$CK001$ButtonCommit'] = '下一步';
    res = await dio.post(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
      data: requestData,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return LeaveSubmitInfoData.fromJson(leaveSubmitInfoParser(res.data)!);
  }

  Future<Response<dynamic>?> leavesSubmit(
    LeaveSubmitData data, {
    XFile? proofImage,
  }) async {
    //force relogin to aviod error.
    await WebApHelper.instance.loginToLeave();

    Response<String> res = await dio.get<String>(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
    );

    Map<String?, dynamic> requestData = hiddenInputGet(res.data);
    requestData[r'ctl00$ContentPlaceHolder1$CK001$ButtonEnter'] = '進入請假作業';

    res = await dio.post(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
      data: requestData,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    requestData = hiddenInputGet(res.data, removeTdElement: true);
    final DateFormat dateFormate = DateFormat('yyyy/MM/dd');
    final DateTime beginDate = dateFormate.parse(data.days[0].day!);
    final DateTime endDate =
        dateFormate.parse(data.days[data.days.length - 1].day!);

    requestData[r'ctl00$ContentPlaceHolder1$CK001$DateUCCBegin$text1'] =
        '${beginDate.year - 1911}/${beginDate.month}/${beginDate.day}';

    requestData[r'ctl00$ContentPlaceHolder1$CK001$DateUCCEnd$text1'] =
        '${endDate.year - 1911}/${endDate.month}/${endDate.day}';

    requestData[r'ctl00$ContentPlaceHolder1$CK001$ButtonCommit'] = '下一步';
    res = await dio.post(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
      data: requestData,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    if (res.data.toString().contains('alert(')) {
      return null;
    }
    final Map<String, dynamic>? submitData =
        leaveSubmitInfoParser(res.data.toString());
    final Map<String, dynamic> globalRequestData = <String, dynamic>{};

    globalRequestData[r'ctl00$ContentPlaceHolder1$CK001$TextBoxReason'] =
        data.reasonText;
    globalRequestData[r'ctl00$ContentPlaceHolder1$CK001$ddlTeach'] =
        data.teacherId;
    globalRequestData[
            r'ctl00$ContentPlaceHolder1$CK001$RadioButtonListOption'] =
        data.leaveTypeId;
    if (data.delayReasonText != null && res.data.toString().contains('延遲理由')) {
      globalRequestData[r'ctl00$ContentPlaceHolder1$CK001$TextBoxDelayReason'] =
          data.delayReasonText;
    }
    final html.Document document = parse(res.data.toString());

    final List<html.Element> trObj =
        document.getElementsByClassName('mGrid')[0].getElementsByTagName('tr');
    if (trObj.length < 2) {
      return null;
    }
    final List<String?> clickList = <String?>[];
    for (int i = 1; i < trObj.length; i++) {
      final List<html.Element> td = trObj[i].getElementsByTagName('td');
      final List<String> leaveDays = data.days[i - 1].dayClass!;
      for (int l = 0; l < leaveDays.length; l++) {
        clickList.add(
          td[(submitData!['timeCodes'] as List<dynamic>).indexOf(leaveDays[l]) +
                  3]
              .getElementsByTagName('input')[0]
              .attributes['name'],
        );
      }
    }

    for (int i = 0; i < clickList.length; i++) {
      final Map<String?, dynamic> requestData =
          hiddenInputGet(res.data.toString());
      requestData.addAll(globalRequestData);

      requestData[clickList[i]] = '';
      res = await dio.post(
        ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
        data: requestData,
        options: Options(
          followRedirects: false,
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      //click covid-19 alert.
    }
    requestData = hiddenInputGet(res.data.toString());
    requestData.addAll(globalRequestData);
    if (res.data.toString().contains('ContentPlaceHolder1_CK001_cbFlag')) {
      requestData[r'ctl00$ContentPlaceHolder1$CK001$cbFlag'] = 'on';
    }
    requestData[r'ctl00$ContentPlaceHolder1$CK001$ButtonCommit2'] = '下一步';
    res = await dio.post(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
      data: requestData,
      options: Options(
        followRedirects: false,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    requestData = hiddenInputGet(res.data.toString());
    requestData[r'ctl00$ContentPlaceHolder1$CK001$ButtonSend'] = '存檔';
    if (proofImage != null) {
      requestData[r'ctl00$ContentPlaceHolder1$CK001$FileUpload1'] =
          await MultipartFile.fromFile(
        proofImage.path,
        filename: 'proof_image.jpg',
        contentType: MediaType.parse('image/jpeg'),
      );
    }

    final FormData formData =
        FormData.fromMap(requestData as Map<String, dynamic>);

    dio.options.headers['Content-Type'] =
        'multipart/form-data; boundary=${formData.boundary}';
    res = await dio.post(
      ApiEndpoints.getLeaveUrl(ApiEndpoints.leaveSubmit),
      data: formData,
    );

    if (res.data.toString().contains('假單存檔成功')) {
      return res;
    }

    return null;
  }
}
