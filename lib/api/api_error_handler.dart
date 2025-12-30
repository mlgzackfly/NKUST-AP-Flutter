import 'dart:ui';

import 'package:ap_common/ap_common.dart';
import 'package:ap_common_firebase/ap_common_firebase.dart';
import 'package:nkust_ap/api/helper.dart';

/// API 錯誤處理工具類別
///
/// 提供統一的錯誤處理方法，減少重複程式碼
class ApiErrorHandler {
  /// 處理可選回調的錯誤
  ///
  /// 用於回調為可選參數的方法，如 [Helper.getUsersInfo]、[Helper.getSemester] 等
  /// 當 [callback] 為 null 時，會重新拋出 [DioException]
  static Future<void> handleOptionalCallback<T>({
    required Object error,
    required StackTrace stackTrace,
    GeneralCallback<T>? callback,
  }) async {
    if (error is DioException) {
      callback?.onFailure(error);
      if (callback == null) throw error;
    } else {
      callback?.onError(GeneralResponse.unknownError());
      await _recordCrashlytics(error, stackTrace);
    }
  }

  /// 處理必需回調的錯誤（簡單模式）
  ///
  /// 用於回調為必需參數且不需要伺服器錯誤檢查的方法
  static Future<void> handleCallback<T>({
    required Object error,
    required StackTrace stackTrace,
    required GeneralCallback<T> callback,
  }) async {
    if (error is DioException) {
      callback.onFailure(error);
    } else {
      callback.onError(GeneralResponse.unknownError());
      await _recordCrashlytics(error, stackTrace);
    }
  }

  /// 處理必需回調的錯誤，含伺服器錯誤檢查
  ///
  /// 用於回調為必需參數的方法，如 [Helper.getBusReservations] 等
  /// 會檢查 [DioException] 是否為伺服器錯誤並呼叫對應的回調方法
  static Future<void> handleCallbackWithServerCheck<T>({
    required Object error,
    required StackTrace stackTrace,
    required GeneralCallback<T> callback,
    VoidCallback? onHasResponse,
  }) async {
    if (error is DioException) {
      if (error.hasResponse) {
        onHasResponse?.call();
        if (error.isServerError) {
          callback.onError(error.serverErrorResponse);
        } else {
          callback.onFailure(error);
        }
      } else {
        callback.onFailure(error);
      }
    } else {
      callback.onError(GeneralResponse.unknownError());
      await _recordCrashlytics(error, stackTrace);
    }
  }

  /// 記錄錯誤到 Firebase Crashlytics
  static Future<void> _recordCrashlytics(
    Object error,
    StackTrace stackTrace,
  ) async {
    if (FirebaseCrashlyticsUtils.isSupported) {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }
}
