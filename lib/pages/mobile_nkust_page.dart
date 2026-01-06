import 'dart:developer';

import 'package:ap_common/ap_common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nkust_ap/api/mobile_nkust_helper.dart';
import 'package:nkust_ap/config/constants.dart';
import 'package:nkust_ap/models/mobile_cookies_data.dart';
import 'package:nkust_ap/utils/app_localizations.dart';

class MobileNkustPage extends StatefulWidget {
  final String? username;
  final String? password;
  final bool clearCache;

  const MobileNkustPage({
    super.key,
    this.username,
    this.password,
    this.clearCache = false,
  });

  @override
  _MobileNkustPageState createState() => _MobileNkustPageState();
}

class _MobileNkustPageState extends State<MobileNkustPage> {
  late AppLocalizations app;

  InAppWebViewController? _webViewController;

  bool finish = false;

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.loginAuth),
        backgroundColor: ApTheme.of(context).blue,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              DialogUtils.showDefault(
                context: context,
                title: app.loginAuth,
                content: app.mobileNkustLoginDescription,
              );
            },
            child: Text(app.clickShowDescription),
          ),
        ],
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              child: const Icon(Icons.done_outline),
              onPressed: () {
                MobileNkustHelper.instance.getScores();
              },
            )
          : null,
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(MobileNkustHelper.loginUrl),
        ),
        initialSettings: InAppWebViewSettings(
          clearCache: widget.clearCache,
          userAgent: MobileNkustHelper.instance.userAgent,
        ),
        onWebViewCreated: (InAppWebViewController webViewController) {
          _webViewController = webViewController;
          UiUtil.instance.showToast(context, app.mobileNkustLoginHint);
        },
        onJsPrompt: (
          InAppWebViewController controller,
          JsPromptRequest jsPromptRequest,
        ) async {
          return;
        },
        onPageCommitVisible:
            (InAppWebViewController controller, Uri? title) async {
          final Uri? uri = await controller.getUrl();
          if (uri.toString() == MobileNkustHelper.loginUrl) {
            await _webViewController?.evaluateJavascript(
              source: 'document.getElementsByName("Account")[0].value '
                  '= "${widget.username}";',
            );
            await _webViewController?.evaluateJavascript(
              source: 'document.getElementsByName("Password")[0].value'
                  ' = "${widget.password}";',
            );
            await _webViewController?.evaluateJavascript(
              source: 'document.getElementsByName("RememberMe")[0].checked '
                  '= true;',
            );
          }
        },
        onTitleChanged:
            (InAppWebViewController controller, String? title) async {
          final Uri? uri = await controller.getUrl();
          if (uri.toString() == MobileNkustHelper.homeUrl) {
            _finishLogin();
          }
        },
        onLoadStop: (InAppWebViewController controller, Uri? title) {},
      ),
    );
  }

  Future<void> _finishLogin() async {
    if (finish) {
      return;
    } else {
      finish = true;
    }
    final List<Cookie> cookies = await CookieManager.instance().getCookies(
      url: WebUri(MobileNkustHelper.mobileBaseUrl),
    );
    final MobileCookiesData data =
        MobileCookiesData(cookies: <MobileCookies>[]);
    for (final Cookie element in cookies) {
      data.cookies.add(
        MobileCookies(
          path: MobileNkustHelper.homeUrl,
          name: element.name,
          value: element.value.toString(),
          domain: element.domain ??
              (element.name == '.AspNetCore.Cookies'
                  ? 'mobile.nkust.edu.tw'
                  : '.nkust.edu.tw'),
        ),
      );
      if (kDebugMode) {
        log(
          'Cookie: ${element.name}: '
          '${element.value} ${element.domain} ${element.expiresDate} \n',
        );
      }
    }
    MobileNkustHelper.instance.setCookieFromData(data);
    data.save();
    PreferenceUtil.instance.setInt(
      Constants.mobileCookiesLastTime,
      DateTime.now().microsecondsSinceEpoch,
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
