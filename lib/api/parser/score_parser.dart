part of 'ap_parser.dart';

/// Score parsing methods for WebApParser.
extension ScoreParserExtension on WebApParser {
  /// Parses score data from HTML.
  ///
  /// Returns a [ScoreData] object with parsed scores.
  ScoreData scoresParser(String? html) {
    final Document document = parse(html);

    final List<Score> scores = <Score>[];
    double? conduct;
    String? classRank;
    String? departmentRank;
    double? average;

    // Detail part
    try {
      final RegExp exp = RegExp('.{0,4}：([0-9./]{0,})');
      final Iterable<RegExpMatch> matches = exp.allMatches(
        document
            .getElementsByTagName('caption')[0]
            .getElementsByTagName('div')[0]
            .text,
      );
      conduct = double.parse(matches.elementAt(0).group(1)!);
      classRank = matches.elementAt(2).group(1);
      departmentRank = matches.elementAt(3).group(1);
      final String avgStr = matches.elementAt(1).group(1) ?? '';
      average = avgStr.isNotEmpty ? double.parse(avgStr) : 0.0;
    } catch (e, s) {
      CrashlyticsUtil.instance.recordError(e, s, reason: 'scoreParser detail');
    }

    // Scores part
    try {
      final List<Element> table =
          document.getElementsByTagName('table')[1].getElementsByTagName('tr');
      for (int scoresIndex = 1; scoresIndex < table.length; scoresIndex++) {
        final List<Element> td = table[scoresIndex].getElementsByTagName('td');
        scores.add(
          Score.fromJson(<String, dynamic>{
            'title': td[1].text,
            'units': td[2].text,
            'hours': td[3].text,
            'required': td[4].text,
            'at': td[5].text,
            'middleScore': td[6].text,
            'semesterScore': td[7].text,
            'remark': td[8].text,
          }),
        );
      }
    } catch (e, s) {
      CrashlyticsUtil.instance.recordError(e, s, reason: 'scoreParser scores');
    }

    return ScoreData(
      scores: scores,
      detail: Detail(
        conduct: conduct,
        classRank: classRank,
        departmentRank: departmentRank,
        average: average,
      ),
    );
  }
}
