part of 'ap_parser.dart';

/// User authentication and info parsing methods for WebApParser.
extension UserParserExtension on WebApParser {
  /// Parses login result from HTML.
  ///
  /// Return type Int:
  /// - 0: Login Success
  /// - 1: Password error or not found user
  /// - 2: Relogin
  /// - 3: Not found login message
  /// - 4: Not found error message
  /// - 5: Already logged in
  /// - -1: Captcha error
  /// - 500: Server busy
  /// - 999: Unknown error
  int apLoginParser(dynamic html) {
    String rawHtml;
    if (html is Uint8List) {
      rawHtml = clearTransEncoding(html);
    } else if (html is String) {
      rawHtml = html;
      if (rawHtml.contains('onclick="go_change()')) {
        return 4;
      }
      // 驗證碼錯誤
      if (rawHtml.contains('驗證碼')) {
        return -1;
      }
      if (rawHtml.contains("top.location.href='f_index.html'")) {
        return 0;
      }
      if (rawHtml.contains(";top.location.href='index.html'")) {
        final RegExp regex = RegExp(r"alert\('(.*)'\);");
        final String? match = regex.allMatches(rawHtml).elementAt(1).group(1);
        if (match == null) {
          return 999;
        } else if (match.contains('無此帳號或密碼不正確')) {
          return 1;
        } else if (match.contains('您先前已登入')) {
          return 5;
        } else if (match.contains('繁忙')) {
          return 500;
        }
        return 999;
      }
      if (rawHtml.contains("location.href='relogin.jsp'") ||
          rawHtml.contains("top.location.href='../index.html';")) {
        return 2;
      }
    }
    return 3;
  }

  /// Parses user info from HTML.
  Map<String, dynamic> apUserInfoParser(String? html) {
    final Map<String, dynamic> data = <String, dynamic>{
      'educationSystem': null,
      'department': null,
      'className': null,
      'id': null,
      'name': null,
      'pictureUrl': null,
    };
    final Document document = parse(html);
    final List<Element> tdElements = document.getElementsByTagName('td');
    if (tdElements.length < 15) {
      // parse data error.
      data['id'] = Helper.username;
      return data;
    }
    try {
      final String imageUrl = document
          .getElementsByTagName('img')[0]
          .attributes['src']!
          .substring(2);
      data['educationSystem'] = tdElements[3].text.replaceAll('學　　制：', '');
      data['department'] = tdElements[4].text.replaceAll('科　　系：', '');
      data['className'] = tdElements[8].text.replaceAll('班　　級：', '');
      data['id'] = tdElements[9].text.replaceAll('學　　號：', '');
      data['name'] = tdElements[10].text.replaceAll('姓　　名：', '');
      data['pictureUrl'] = 'https://webap.nkust.edu.tw/nkust$imageUrl';
    } catch (e, s) {
      if (FirebaseCrashlyticsUtils.isSupported) {
        CrashlyticsUtil.instance.recordError(
          e,
          s,
          reason: document.outerHtml,
        );
      }
    }
    return data;
  }

  /// Parses webapp to leave transition data from HTML.
  Map<String, dynamic> webapToleaveParser(String? html) {
    final Map<String, dynamic> data = <String, dynamic>{};
    final Document document = parse(html);
    final List<Element> inputElements = document.getElementsByTagName('input');
    for (final Element element in inputElements) {
      if (element.attributes['id'] != null) {
        data.addAll(
          <String, dynamic>{
            element.attributes['id']!: element.attributes['value'],
          },
        );
      }
    }
    return data;
  }
}
