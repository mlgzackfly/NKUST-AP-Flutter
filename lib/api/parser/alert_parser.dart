part of 'ap_parser.dart';

/// Alert-related parsing methods for WebApParser.
extension AlertParserExtension on WebApParser {
  /// Parses midterm alerts data from HTML.
  ///
  /// Returns a [MidtermAlertsData] object with parsed alerts.
  MidtermAlertsData midtermAlertsParser(String? html) {
    final List<MidtermAlerts> courses = <MidtermAlerts>[];

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
            courses.add(
              MidtermAlerts(
                entry: tdData[0].text,
                className: tdData[1].text,
                title: tdData[2].text,
                group: tdData[3].text,
                instructors: tdData[4].text,
                reason: tdData[6].text,
                remark: tdData[7].text,
              ),
            );
          }
        }
      } on Exception catch (e, s) {
        CrashlyticsUtil.instance
            .recordError(e, s, reason: 'midtermAlertsParser');
      }
    }
    return MidtermAlertsData(courses: courses);
  }

  /// Parses reward and penalty data from HTML.
  ///
  /// Returns a [RewardAndPenaltyData] object with parsed rewards/penalties.
  RewardAndPenaltyData rewardAndPenaltyParser(String? html) {
    final List<RewardAndPenalty> items = <RewardAndPenalty>[];

    final Document document = parse(html);
    if (document.getElementsByTagName('table').length < 2) {
      return RewardAndPenaltyData(data: items);
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
        items.add(
          RewardAndPenalty(
            date: tdData[2].text,
            type: tdData[3].text,
            counts: tdData[4].text,
            reason: tdData[5].text,
          ),
        );
      }
    } on Exception catch (e, s) {
      CrashlyticsUtil.instance
          .recordError(e, s, reason: 'rewardAndPenaltyParser');
    }
    return RewardAndPenaltyData(data: items);
  }
}
