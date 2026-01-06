part of '../home_page.dart';

/// Login-related logic for HomePage.
mixin HomeLoginMixin on State<HomePage> {
  bool get isLogin;
  set isLogin(bool value);

  UserInfo? get userInfo;
  set userInfo(UserInfo? value);

  Widget? get content;
  set content(Widget? value);

  HomeState get state;
  set state(HomeState value);

  GlobalKey<HomePageScaffoldState> get homeKey;

  bool get isMobile;

  void _getUserInfo();
  void _setupBusNotify(BuildContext context);
  void _getAnnouncements();

  void showLoginingSnackBar() {
    if (isLogin) return;
    homeKey.currentState
        ?.showSnackBar(
          text: ApLocalizations.of(context).logining,
          actionText: ApLocalizations.of(context).offlineLogin,
          onSnackBarTapped: offLineLogin,
        )
        ?.closed
        .then(
      (SnackBarClosedReason reason) {
        showLoginingSnackBar();
      },
    );
  }

  Future<void> performLogin() async {
    await Future<void>.delayed(const Duration(microseconds: 30));
    if (!mounted) return;
    showLoginingSnackBar();
    final String username =
        PreferenceUtil.instance.getString(Constants.prefUsername, '');
    final String password =
        PreferenceUtil.instance.getStringSecurity(Constants.prefPassword, '');

    if (!mounted) return;
    final ApLocalizations ap = ApLocalizations.of(context);
    Helper.instance.login(
      context: context,
      username: username,
      password: password,
      callback: GeneralCallback<LoginResponse?>(
        onSuccess: (LoginResponse? response) {
          if (isLogin) return;
          ShareDataWidget.of(context)!.data.loginResponse = response;
          isLogin = true;
          PreferenceUtil.instance.setBool(Constants.prefIsOfflineLogin, false);
          _getUserInfo();
          _setupBusNotify(context);
          if (state != HomeState.finish) {
            _getAnnouncements();
          }
          homeKey.currentState
            ?..hideSnackBar()
            ..showBasicHint(text: ap.loginSuccess);
        },
        onFailure: (DioException e) {
          if (isLogin) return;
          final String text = e.i18nMessage ?? ap.somethingError;
          homeKey.currentState?.showSnackBar(
            text: text,
            actionText: ap.retry,
            onSnackBarTapped: performLogin,
          );
          offLineLogin();
        },
        onError: (GeneralResponse response) async {
          if (isLogin) return;
          String message = '';
          if (response.statusCode == ApStatusCode.userDataError ||
              response.statusCode == ApStatusCode.passwordFiveTimesError) {
            Toast.show(ap.passwordError, context);
            await PreferenceUtil.instance
                .setBool(Constants.prefAutoLogin, false);
            checkLogin();
          } else {
            switch (response.statusCode) {
              case ApStatusCode.schoolServerError:
                message = ap.schoolServerError;
              case ApStatusCode.apiServerError:
                message = ap.apiServerError;
              case ApStatusCode.unknownError:
              case ApStatusCode.cancel:
                message = ap.loginFail;
              default:
                message = ap.somethingError;
            }
            homeKey.currentState?.showSnackBar(
              text: message,
              actionText: ap.retry,
              onSnackBarTapped: performLogin,
            );
            offLineLogin();
          }
        },
      ),
    );
  }

  void offLineLogin() {
    PreferenceUtil.instance.setBool(Constants.prefIsOfflineLogin, true);
    final ApLocalizations ap = ApLocalizations.of(context);
    UiUtil.instance.showToast(context, ap.loadOfflineData);
    isLogin = true;
    _getUserInfo();
    homeKey.currentState?.hideSnackBar();
  }

  void handleLoginSuccess(String? username, String? password) {
    isLogin = true;
    PreferenceUtil.instance.setBool(Constants.prefIsOfflineLogin, false);
    _getUserInfo();
    _setupBusNotify(context);
    if (state != HomeState.finish) {
      _getAnnouncements();
    }
    homeKey.currentState?.showBasicHint(
      text: ApLocalizations.of(context).loginSuccess,
    );
  }

  Future<void> openLoginPage() async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => LoginPage()),
    );
    checkLogin();
    if (result ?? false) {
      handleLoginSuccess(
        Helper.username,
        Helper.password,
      );
    }
  }

  Future<void> checkLogin() async {
    await Future<void>.delayed(const Duration(microseconds: 30));
    if (isLogin) {
      homeKey.currentState?.hideSnackBar();
    } else {
      if (!mounted) return;
      final ApLocalizations ap = ApLocalizations.of(context);
      final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
          controller = homeKey.currentState?.showSnackBar(
        text: ap.notLogin,
        actionText: ap.login,
        onSnackBarTapped: openLoginPage,
      );
      controller?.closed.then(
        (SnackBarClosedReason reason) {
          checkLogin();
        },
      );
    }
  }
}
