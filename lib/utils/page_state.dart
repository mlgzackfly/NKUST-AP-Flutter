/// 頁面狀態枚舉
///
/// 統一管理所有頁面的載入狀態，取代各頁面重複定義的 `_State` 枚舉
enum PageState {
  /// 載入中
  loading,

  /// 載入完成
  finish,

  /// 發生錯誤
  error,

  /// 無資料
  empty,

  /// 離線模式
  offline,

  /// 離線且無快取資料
  offlineEmpty,

  /// 校區不支援
  campusNotSupport,

  /// 使用者不支援
  userNotSupport,

  /// 就緒狀態（尚未開始載入）
  ready,

  /// 自訂狀態
  custom,

  /// PDF 檢視狀態
  pdf,
}
