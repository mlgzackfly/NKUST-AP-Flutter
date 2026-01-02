import 'dart:io';

import 'package:ap_common/ap_common.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/io.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/config/constants.dart';

/// Base class for all API helpers providing common functionality.
///
/// This class provides:
/// - Dio initialization with common settings
/// - Cookie management
/// - Proxy configuration
/// - Cache management
abstract class BaseApiHelper {
  late Dio dio;
  late CookieJar cookieJar;
  DioCacheManager? _cacheManager;

  /// The base URL for this helper's API endpoints.
  String get baseUrl;

  /// User agent string for HTTP requests.
  String get userAgent =>
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/84.0.4147.89 Safari/537.36';

  /// Additional headers to be added to all requests.
  Map<String, dynamic> get additionalHeaders => <String, dynamic>{};

  /// Whether to clear cache on initialization.
  bool get clearCacheOnInit => false;

  /// Connection timeout in milliseconds.
  int get connectTimeoutMs => Constants.timeoutMs;

  /// Receive timeout in milliseconds.
  int get receiveTimeoutMs => Constants.timeoutMs;

  /// Cache manager instance, available after [dioInit] is called.
  DioCacheManager? get cacheManager => _cacheManager;

  /// Initializes the Dio instance with common settings.
  ///
  /// This method sets up:
  /// - Cookie jar for session management
  /// - Cache interceptor (if supported)
  /// - Common headers (user-agent, connection)
  /// - Timeout settings
  /// - Native adapter for iOS/macOS/Android
  void dioInit() {
    dio = Dio();
    cookieJar = CookieJar();

    // Setup cache manager if supported
    if (Helper.isSupportCacheData) {
      _cacheManager = DioCacheManager(CacheConfig(baseUrl: baseUrl));
      dio.interceptors.add(_cacheManager!.interceptor as Interceptor);

      if (clearCacheOnInit) {
        _cacheManager!.clearAll();
      }
    }

    // Add cookie manager
    // Use PrivateCookieManager to overwrite origin CookieManager, because
    // Cookie name of the NKUST ap system not follow the RFC6265. :(
    dio.interceptors.add(PrivateCookieManager(cookieJar));

    // Set common headers
    dio.options.headers['user-agent'] = userAgent;
    dio.options.headers['Connection'] = 'close';
    dio.options.headers.addAll(additionalHeaders);

    // Set timeouts
    dio.options.connectTimeout = Duration(milliseconds: connectTimeoutMs);
    dio.options.receiveTimeout = Duration(milliseconds: receiveTimeoutMs);

    // Use native adapter for better performance on mobile/desktop
    if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
      dio.httpClientAdapter = NativeAdapter();
    }
  }

  /// Configures a proxy for all HTTP requests.
  ///
  /// [proxyIP] should be in the format "host:port".
  void setProxy(String proxyIP) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final HttpClient client = HttpClient();
      client.findProxy = (Uri uri) {
        return 'PROXY $proxyIP';
      };
      return client;
    };
  }

  /// Clears a specific cache entry by key.
  Future<void> clearCache(String cacheKey) async {
    if (_cacheManager != null) {
      await _cacheManager!.delete(cacheKey);
    }
  }

  /// Clears all cached data.
  Future<void> clearAllCache() async {
    if (_cacheManager != null) {
      await _cacheManager!.clearAll();
    }
  }
}
