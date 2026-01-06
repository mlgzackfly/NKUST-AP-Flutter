import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:nkust_ap/api/ap_status_code.dart';
import 'package:nkust_ap/api/api_endpoints.dart';
import 'package:nkust_ap/api/base_api_helper.dart';
import 'package:nkust_ap/api/parser/nkust_parser.dart';
import 'package:nkust_ap/utils/captcha_utils.dart';
import 'package:sprintf/sprintf.dart';

class NKUSTHelper extends BaseApiHelper {
  static NKUSTHelper? _instance;

  static int reTryCountsLimit = 3;
  static int reTryCounts = 0;

  @override
  String get baseUrl => ApiEndpoints.webApBaseUrl;

  //ignore: prefer_constructors_over_static_methods
  static NKUSTHelper get instance {
    return _instance ??= NKUSTHelper();
  }

  /// Resets the singleton instance, disposing of all resources.
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  NKUSTHelper() {
    dioInit();
  }

  Future<Uint8List?> getUidValidationImage() async {
    final Response<Uint8List> response = await dio.get<Uint8List>(
      ApiEndpoints.getWebApUrl(ApiEndpoints.webApValidateCodeForUid),
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, dynamic>{
          'Referer': '${ApiEndpoints.webApBaseUrl}/',
        },
      ),
    );
    return response.data;
  }

  Future<void> getUsername({
    required String rocId,
    required DateTime birthday,
    required GeneralCallback<UserInfo> callback,
  }) async {
    final String birthdayText = sprintf('%03i%02i%02i', <int>[
      birthday.year - 1911,
      birthday.month,
      birthday.day,
    ]);

    for (int i = 0; i < 5; i++) {
      final String captchaCode = await CaptchaUtils.extractByEucDist(
        bodyBytes: (await getUidValidationImage())!,
      );

      final List<Cookie> cookies = await cookieJar
          .loadForRequest(Uri.parse(ApiEndpoints.webApBaseUrl));
      final String cookieHeader = cookies
          .map((Cookie cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');

      final http.Response response = await http.post(
        Uri(
          scheme: 'https',
          host: ApiEndpoints.webApHost,
          path: ApiEndpoints.webApGetUid,
          queryParameters: <String, String>{
            'uid': rocId,
            'bir': birthdayText,
            'Text3': captchaCode,
            'kind': '2',
          },
        ),
        headers: <String, String>{
          'Connection': 'close',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': '${ApiEndpoints.webApBaseUrl}/',
          'Cookie': cookieHeader,
        },
      );

      if (!response.body.contains('驗證碼')) {
        final Document document = parse(response.body);
        final List<Element> elements = document.getElementsByTagName('b');

        if (elements.length >= 4) {
          final UserInfo userInfo = UserInfo(
            id: elements[4].text.replaceAll(' ', ''),
            name: elements[2].text,
            className: '',
            department: '',
          );
          callback.onSuccess(userInfo);
        } else if (elements.length == 1) {
          callback.onError(
            GeneralResponse(
              statusCode: 404,
              message: elements[0].text,
            ),
          );
        } else {
          callback.onError(
            GeneralResponse.unknownError(),
          );
        }

        return;
      }
    }

    throw GeneralResponse(
      statusCode: ApStatusCode.unknownError,
      message: 'captcha error or unknown error',
    );
  }

  Future<NotificationsData> getNotifications(int page) async {
    final int baseIndex = (page - 1) * 15;
    if (reTryCounts > reTryCountsLimit) {
      throw StateError('Retry limit exceeded');
    }
    final Response<String> res = await dio.post<String>(
      ApiEndpoints.getAcadUrl(ApiEndpoints.acadNotifications),
      data: <String, dynamic>{
        'Rcg': 232,
        'Op': 'getpartlist',
        'Page': page - 1,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    List<Map<String, dynamic>> acadData;
    if (res.statusCode == 200 && res.data != null) {
      acadData = acadParser(
        html: (json.decode(res.data!) as Map<String, dynamic>)['content']
            as String,
        baseIndex: baseIndex,
      );
      reTryCounts = 0;
    } else {
      reTryCounts++;
      return getNotifications(page);
    }
    return NotificationsData.fromJson(<String, dynamic>{
      'data': <String, dynamic>{
        'page': page + 1,
        'notification': acadData,
      },
    });
  }
}
