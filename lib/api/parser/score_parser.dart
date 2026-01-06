part of 'ap_parser.dart';

/// Score parsing methods for WebApParser.
extension ScoreParserExtension on WebApParser {
  /// Parses score data from HTML.
  Map<String, dynamic> scoresParser(String? html) {
    final Document document = parse(html);

    final Map<String, dynamic> data = <String, dynamic>{
      'scores': <Map<String, dynamic>>[],
      'detail': <String, dynamic>{
        'conduct': null,
        'classRank': null,
        'departmentRank': null,
        'average': null,
      },
    };
    //detail part
    try {
      final RegExp exp = RegExp('.{0,4}：([0-9./]{0,})');
      final Iterable<RegExpMatch> matches = exp.allMatches(
        document
            .getElementsByTagName('caption')[0]
            .getElementsByTagName('div')[0]
            .text,
      );
      data['detail'] = <String, dynamic>{
        'conduct': double.parse(matches.elementAt(0).group(1)!),
        'classRank': matches.elementAt(2).group(1),
        'departmentRank': matches.elementAt(3).group(1),
        'average': (matches.elementAt(1).group(1) != '')
            ? double.parse(matches.elementAt(1).group(1)!)
            : 0.0,
      };
    } catch (e, s) {
      CrashlyticsUtil.instance.recordError(e, s, reason: 'scoreParser detail');
    }
    //scores part

    try {
      final List<Element> table =
          document.getElementsByTagName('table')[1].getElementsByTagName('tr');
      for (int scoresIndex = 1; scoresIndex < table.length; scoresIndex++) {
        final List<Element> td = table[scoresIndex].getElementsByTagName('td');
        (data['scores'] as List<Map<String, dynamic>>).add(
          <String, dynamic>{
            'title': td[1].text,
            'units': td[2].text,
            'hours': td[3].text,
            'required': td[4].text,
            'at': td[5].text,
            'middleScore': td[6].text,
            'semesterScore': td[7].text,
            'remark': td[8].text,
          },
        );
      }
    } catch (e, s) {
      CrashlyticsUtil.instance.recordError(e, s, reason: 'scoreParser scores');
    }
    return data;
  }
}
