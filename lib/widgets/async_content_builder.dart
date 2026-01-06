import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/utils/page_state.dart';

/// A widget that handles common page loading states.
///
/// This widget provides a unified way to display loading, error, empty,
/// and success states across all pages in the app.
///
/// Example usage:
/// ```dart
/// AsyncContentBuilder<UserData>(
///   state: state,
///   data: userData,
///   builder: (data) => UserProfileWidget(data: data),
///   onRetry: _loadUserData,
///   emptyMessage: '無使用者資料',
/// )
/// ```
class AsyncContentBuilder<T> extends StatelessWidget {
  const AsyncContentBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.data,
    this.onRetry,
    this.customStateHint,
    this.emptyMessage,
    this.errorMessage,
    this.offlineMessage,
    this.loadingWidget,
    this.emptyIcon,
    this.errorIcon,
  });

  /// Current page state.
  final PageState state;

  /// Data to display when state is [PageState.finish].
  final T? data;

  /// Builder function to create the content widget.
  final Widget Function(T data) builder;

  /// Callback when user taps retry.
  final VoidCallback? onRetry;

  /// Custom hint message for [PageState.custom] state.
  final String? customStateHint;

  /// Message to display when data is empty.
  final String? emptyMessage;

  /// Message to display on error.
  final String? errorMessage;

  /// Message to display when offline.
  final String? offlineMessage;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Icon for empty state.
  final IconData? emptyIcon;

  /// Icon for error state.
  final IconData? errorIcon;

  @override
  Widget build(BuildContext context) {
    final ApLocalizations ap = ApLocalizations.of(context);

    switch (state) {
      case PageState.loading:
        return loadingWidget ?? _buildLoadingWidget();

      case PageState.finish:
        if (data != null) {
          return builder(data as T);
        }
        return _buildHintContent(
          icon: emptyIcon ?? ApIcon.classIcon,
          content: emptyMessage ?? ap.noData,
          onTap: onRetry,
        );

      case PageState.empty:
        return _buildHintContent(
          icon: emptyIcon ?? ApIcon.classIcon,
          content: emptyMessage ?? ap.noData,
          onTap: onRetry,
        );

      case PageState.error:
        return _buildHintContent(
          icon: errorIcon ?? ApIcon.warning,
          content: errorMessage ?? ap.somethingError,
          onTap: onRetry,
        );

      case PageState.offline:
      case PageState.offlineEmpty:
        return _buildHintContent(
          icon: ApIcon.offlineBolt,
          content: offlineMessage ?? ap.noOfflineData,
          onTap: onRetry,
        );

      case PageState.userNotSupport:
        return _buildHintContent(
          icon: ApIcon.permIdentity,
          content: ap.userNotSupport,
          onTap: onRetry,
        );

      case PageState.campusNotSupport:
        return _buildHintContent(
          icon: ApIcon.warning,
          content: ap.campusNotSupport,
          onTap: onRetry,
        );

      case PageState.custom:
        return _buildHintContent(
          icon: errorIcon ?? ApIcon.warning,
          content: customStateHint ?? '',
          onTap: onRetry,
        );

      case PageState.ready:
      case PageState.pdf:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildHintContent({
    required IconData icon,
    required String content,
    VoidCallback? onTap,
  }) {
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: HintContent(
          icon: icon,
          content: content,
        ),
      );
    }
    return HintContent(
      icon: icon,
      content: content,
    );
  }
}

/// A convenient wrapper for [AsyncContentBuilder] with [RefreshIndicator].
class RefreshableAsyncContent<T> extends StatelessWidget {
  const RefreshableAsyncContent({
    super.key,
    required this.state,
    required this.builder,
    required this.onRefresh,
    this.data,
    this.customStateHint,
    this.emptyMessage,
    this.errorMessage,
    this.offlineMessage,
  });

  final PageState state;
  final T? data;
  final Widget Function(T data) builder;
  final Future<void> Function() onRefresh;
  final String? customStateHint;
  final String? emptyMessage;
  final String? errorMessage;
  final String? offlineMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: AsyncContentBuilder<T>(
        state: state,
        data: data,
        builder: builder,
        onRetry: () => onRefresh(),
        customStateHint: customStateHint,
        emptyMessage: emptyMessage,
        errorMessage: errorMessage,
        offlineMessage: offlineMessage,
      ),
    );
  }
}
