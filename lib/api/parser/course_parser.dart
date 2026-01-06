part of 'ap_parser.dart';

/// Course and semester parsing methods for WebApParser.
extension CourseParserExtension on WebApParser {
  /// Parses semester data from HTML.
  Map<String, dynamic> semestersParser(String? html) {
    final Map<String, dynamic> data = <String, dynamic>{
      'data': <Map<String, dynamic>>[],
      'default': <String, dynamic>{
        'year': '108',
        'value': '2',
        'text': '108學年第二學期(Parse失敗)',
      },
    };
    final Document document = parse(html);

    final List<Element> ymsElements =
        document.getElementById('yms_yms')!.getElementsByTagName('option');
    if (ymsElements.length < 30) {
      //parse fail.
      return data;
    }
    for (int i = 0; i < ymsElements.length; i++) {
      (data['data'] as List<Map<String, dynamic>>).add(
        <String, dynamic>{
          'year': ymsElements[i].attributes['value']!.split('#')[0],
          'value': ymsElements[i].attributes['value']!.split('#')[1],
          'text': ymsElements[i].text,
        },
      );
      if (ymsElements[i].attributes['selected'] != null) {
        //set default
        data['default'] = <String, dynamic>{
          'year': ymsElements[i].attributes['value']!.split('#')[0],
          'value': ymsElements[i].attributes['value']!.split('#')[1],
          'text': ymsElements[i].text,
        };
      }
    }
    return data;
  }

  /// Parses course table data from HTML.
  Future<Map<String, dynamic>> coursetableParser(dynamic html) async {
    dynamic rawHtml;
    if (html is Uint8List) {
      rawHtml = clearTransEncoding(html);
    } else {
      rawHtml = html;
    }

    final Map<String, List<Map<String, dynamic>>> data =
        <String, List<Map<String, dynamic>>>{
      'courses': <Map<String, dynamic>>[],
      'timeCodes': <Map<String, dynamic>>[],
    };
    final Document document = parse(rawHtml);

    if (document.getElementsByTagName('table').isEmpty) {
      //table not found
      return data;
    }
    try {
      //the top table parse
      final List<Element> topTable =
          document.getElementsByTagName('table')[0].getElementsByTagName('tr');
      for (int i = 1; i < topTable.length; i++) {
        final List<Element> td = topTable[i].getElementsByTagName('td');
        data['courses']?.add(
          <String, dynamic>{
            'code': td[0].text,
            'title': td[1].text.trim(),
            'className': td[2].text,
            'group': td[3].text,
            'units': td[4].text,
            'hours': td[5].text,
            'required': td[6].text,
            'at': td[7].text,
            'sectionTimes': <Map<String, dynamic>>[],
            'instructors': td[9].text.split(','),
            'location': <String, dynamic>{
              'building': '',
              'room': td[10].text,
            },
          },
        );
      }
    } catch (e, s) {
      if (kDebugMode) rethrow;
      if (FirebaseCrashlyticsUtils.isSupported) {
        await CrashlyticsUtil.instance.recordError(
          e,
          s,
          reason: 'Section A = '
              "${document.getElementsByTagName("table")[0].innerHtml}",
        );
      }
    }

    //the second talbe.

    final Element table2 = document.getElementsByTagName('table')[1];
    //make timetable
    final List<Element> trs = table2.getElementsByTagName('tr');
    final List<Element> timeCodeElements = <Element>[];
    try {
      //remark:Best split is regex but... Chinese have some difficulty Q_Q
      for (int i = 1; i < trs.length; i++) {
        final Element timeCodeElement = trs[i].getElementsByTagName('td')[0];
        timeCodeElements.add(timeCodeElement);
        final String temptext = timeCodeElement.text.replaceAll(' ', '');
        if (temptext.length < 10 && i == 1) {
          data['timeCodes']?.add(
            <String, dynamic>{
              'title': '第M節',
              'startTime': '07:10',
              'endTime': '08:00',
            },
          );
          continue;
        }
        final String title = temptext
            .substring(0, temptext.length - 10)
            .replaceAll(specialSpace, '')
            .replaceAll(' ', '');
        final String courseTimeRange = temptext
            .substring(temptext.length - 10)
            .replaceAll(specialSpace, '');
        final List<String> courseTimeSlits = courseTimeRange.split('-');
        final String startTime = courseTimeSlits[0];
        final String endTime = courseTimeSlits[1];
        data['timeCodes']?.add(
          <String, dynamic>{
            'title': title,
            'startTime':
                '${startTime.substring(0, 2)}:${startTime.substring(2, 4)}',
            'endTime': '${endTime.substring(0, 2)}:${endTime.substring(2, 4)}',
          },
        );
      }
    } catch (e, s) {
      if (kDebugMode) rethrow;
      if (FirebaseCrashlyticsUtils.isSupported) {
        final StringBuffer htmlStringBuffer = StringBuffer();
        for (final Element value in timeCodeElements) {
          htmlStringBuffer.write(value.innerHtml);
        }
        await CrashlyticsUtil.instance.recordError(
          e,
          s,
          reason: htmlStringBuffer.toString(),
        );
      }
    }
    //make each day.
    final List<String> weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    try {
      for (int weekdayIndex = 0;
          weekdayIndex < weekdays.length;
          weekdayIndex++) {
        for (int rwaTimeCodeIndex = 1;
            rwaTimeCodeIndex < data['timeCodes']!.length + 1;
            rwaTimeCodeIndex++) {
          final Element sectionElement =
              table2.getElementsByTagName('tr')[rwaTimeCodeIndex];
          final List<Element> sectionTds =
              sectionElement.getElementsByTagName('td');
          final Element eachDays = sectionTds[weekdayIndex + 1];
          final List<String> splitData = eachDays.outerHtml
              .substring(35, eachDays.outerHtml.length - 11)
              .split('<br>');
          if (splitData.length <= 1) {
            continue;
          }
          String courseName =
              splitData[0].replaceAll('\n', '').replaceAll('(18週)', '');
          if (courseName.lastIndexOf('>') > -1) {
            courseName = courseName
                .substring(courseName.lastIndexOf('>') + 1, courseName.length)
                .replaceAll('&nbsp;', '')
                .replaceAll(';', '');
          }
          courseName = courseName.replaceAll('(1週)', '');
          for (int i = 0; i < data['courses']!.length; i++) {
            if (data['courses']![i]['title'] == courseName) {
              for (int j = 0; j < data['timeCodes']!.length; j++) {
                if (j == rwaTimeCodeIndex - 1) {
                  (data['courses']![i]['sectionTimes'] as List<dynamic>).add(
                    <String, dynamic>{
                      'index': j,
                      'weekday': weekdayIndex + 1,
                    },
                  );
                }
              }
            }
          }
        }
      }
    } catch (e, s) {
      if (kDebugMode) rethrow;
      if (FirebaseCrashlyticsUtils.isSupported) {
        await CrashlyticsUtil.instance.recordError(
          e,
          s,
          reason: 'Section C = ${table2.innerHtml}',
        );
      }
    }
    return data;
  }
}
