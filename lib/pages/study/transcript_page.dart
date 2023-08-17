import 'dart:io' as io;
import 'dart:typed_data';
import 'package:ap_common/l10n/l10n.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/views/pdf_view.dart';
import 'package:ap_common_firebase/utils/firebase_analytics_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nkust_ap/api/helper.dart';

import '../../../api/ap_helper.dart';


class TranscriptPage extends StatefulWidget {
  static const String routerName = '/transcript';
  final bool clearCache;

  const TranscriptPage({
    Key? key,
    this.clearCache = false,
  }) : super(key: key);

  @override
  TranscriptPageState createState() => TranscriptPageState();
}

class TranscriptPageState extends State<TranscriptPage> {
  PdfState pdfState = PdfState.loading;

  late ApLocalizations ap;

  Uint8List? data;

  CookieManager cookieManager = CookieManager.instance();

  Future<bool>? _login;

  @override
  void initState() {
    _getTranscript();
    super.initState();
    _login = Future<bool>.microtask(() => login());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.transcript),
        backgroundColor: ApTheme.of(context).blue,
      ),
      body: PdfView(
        state: pdfState,
        data: data,
        onRefresh: () {
          setState(() => pdfState = PdfState.loading);
          _getTranscript();
        },
      ),
    );
  }

  Future<bool> login() async {
    try {
      await WebApHelper.instance.loginToMobile();
      final List<io.Cookie> cookies =
      await WebApHelper.instance.cookieJar.loadForRequest(
        Uri.parse('https://webap.nkust.edu.tw'),
      );
      for (final io.Cookie cookie in cookies) {
        cookieManager.setCookie(
          url: Uri.parse('https://webap.nkust.edu.tw'),
          name: cookie.name,
          value: cookie.value,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _getTranscript() async {
    try {
      Helper.instance.getTranscript(
        callback: GeneralCallback<Uint8List?>(
          onSuccess: (Uint8List? pdfData) {
            if (mounted) {
              setState(
                () {
                  data = pdfData;
                  pdfState = PdfState.finish;
                },
              );
            }
          },
          onFailure: (DioError e) async {
            if (e.hasResponse) {
              FirebaseAnalyticsUtils.instance.logApiEvent(
                'getTranscript',
                e.response!.statusCode!,
                message: e.message,
              );
            }
          },
          onError: (GeneralResponse generalResponse) async {
            if (mounted) {
              setState(
                () => pdfState = PdfState.error,
              );
            }
          },
        ),
      );
    } catch (e) {
      setState(
        () {
          pdfState = PdfState.error;
        },
      );
      rethrow;
    }
  }
}
