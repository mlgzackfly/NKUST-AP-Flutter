part of 'ap_parser.dart';

/// Alert-related parsing methods for WebApParser.
extension AlertParserExtension on WebApParser {
  /// Parses midterm alerts data from HTML.
  Map<String, dynamic> midtermAlertsParser(String? html) {
    final Map<String, dynamic> data = <String, dynamic>{
      'courses': <Map<String, dynamic>>[],
    };

    final Document document = parse(html);
    final List<Element> table = document.getElementsByTagName('table');
    if (table.length > 1) {
      try {
        final List<Element> td = table[1].getElementsByTagName('tr');
        for (int i = 1; i < td.length; i++) {
          final List<Element> tdData = td[i].getElementsByTagName('td');
          if (tdData.length < 5) {
            continue;
          }
          if (tdData[5].text[0] == '是') {
            (data['courses'] as List<Map<String, dynamic>>).add(
              <String, dynamic>{
                'entry': tdData[0].text,
                'className': tdData[1].text,
                'title': tdData[2].text,
                'group': tdData[3].text,
                'instructors': tdData[4].text,
                'reason': tdData[6].text,
                'remark': tdData[7].text,
              },
            );
          }
        }
      } on Exception catch (e, s) {
        CrashlyticsUtil.instance
            .recordError(e, s, reason: 'midtermAlertsParser');
      }
    }
    return data;
  }

  /// Parses reward and penalty data from HTML.
  Map<String, dynamic> rewardAndPenaltyParser(String? html) {
    final Map<String, dynamic> data = <String, dynamic>{
      'data': <Map<String, dynamic>>[],
    };

    final Document document = parse(html);
    if (document.getElementsByTagName('table').length < 2) {
      return data;
    }
    final List<Element> table = document
        .getElementsByTagName('table')[1]
        .getElementsByTagName('tr')[1]
        .getElementsByTagName('tr');
    try {
      for (int i = 1; i < table.length; i++) {
        final List<Element> tdData = table[i].getElementsByTagName('td');
        if (tdData.length < 5) {
          continue;
        }
        if (tdData[3].text.length < 2) {
          continue;
        }
        (data['data'] as List<Map<String, dynamic>>).add(
          <String, dynamic>{
            'date': tdData[2].text,
            'type': tdData[3].text,
            'counts': tdData[4].text,
            'reason': tdData[5].text,
          },
        );
      }
    } on Exception catch (e, s) {
      CrashlyticsUtil.instance
          .recordError(e, s, reason: 'rewardAndPenaltyParser');
    }
    return data;
  }
}
