import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:nkust_ap/models/mobile_cookies_data.dart';

/// Mixin providing cookie management functionality for API helpers.
///
/// This mixin requires the implementing class to have a [CookieJar] instance.
/// It provides methods for saving, restoring, and checking cookies.
///
/// Usage:
/// ```dart
/// class MyHelper with CookieManageable {
///   @override
///   late CookieJar cookieJar;
///
///   @override
///   String get cookieCheckUrl => 'https://api.example.com/check';
/// }
/// ```
mixin CookieManageable {
  /// The cookie jar instance for storing cookies.
  CookieJar get cookieJar;

  /// The Dio instance for making requests.
  Dio get dio;

  /// URL to check if cookies are still valid.
  /// Override this in implementing classes.
  String get cookieCheckUrl => '';

  /// Stored cookies data for persistence.
  MobileCookiesData? cookiesData;

  /// Restores cookies from a [MobileCookiesData] object.
  ///
  /// This is typically used when restoring a session from cached data.
  void setCookieFromData(MobileCookiesData data) {
    cookiesData = data;
    for (final MobileCookies element in data.cookies) {
      final Cookie tempCookie = Cookie(element.name, element.value);
      tempCookie.domain = element.domain;
      cookieJar.saveFromResponse(
        Uri.parse(element.path),
        <Cookie>[tempCookie],
      );
    }
  }

  /// Sets a single cookie for a specific URL.
  ///
  /// [url] is the URL to associate the cookie with.
  /// [cookieName] is the name of the cookie.
  /// [cookieValue] is the value of the cookie.
  /// [cookieDomain] is the optional domain for the cookie.
  void setCookie(
    String url, {
    required String cookieName,
    required String cookieValue,
    String? cookieDomain,
  }) {
    final Cookie tempCookie = Cookie(cookieName, cookieValue);
    tempCookie.domain = cookieDomain;
    cookieJar.saveFromResponse(
      Uri.parse(url),
      <Cookie>[tempCookie],
    );
  }

  /// Checks if the current cookies are still valid.
  ///
  /// Returns `true` if cookies are valid, `false` otherwise.
  /// Override [cookieCheckUrl] to specify the endpoint to check.
  Future<bool> isCookieAlive() async {
    if (cookieCheckUrl.isEmpty) {
      return false;
    }
    try {
      final Response<String> res = await dio.get<String>(cookieCheckUrl);
      return res.data == 'alive';
    } catch (_) {
      return false;
    }
  }

  /// Clears all cookies from the cookie jar.
  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
    cookiesData = null;
  }
}
