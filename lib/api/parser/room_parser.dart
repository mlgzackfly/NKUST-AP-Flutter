part of 'ap_parser.dart';

/// Room and room course table parsing methods for WebApParser.
extension RoomParserExtension on WebApParser {
  /// Parses room list data from HTML.
  ///
  /// Returns a [RoomData] object with parsed rooms.
  RoomData roomListParser(String? html) {
    final List<Room> rooms = <Room>[];

    final Document document = parse(html);
    final List<Element> table =
        document.getElementById('room_id')!.getElementsByTagName('option');
    try {
      for (int i = 1; i < table.length; i++) {
        rooms.add(
          Room(
            name: table[i].text,
            id: table[i].attributes['value'] ?? '0035',
          ),
        );
      }
    } on Exception catch (e, s) {
      CrashlyticsUtil.instance.recordError(e, s, reason: 'roomListParser');
    }
    return RoomData(data: rooms);
  }

  /// Parses room course table data from HTML.
  ///
  /// Returns a [CourseData] object with parsed course table.
  CourseData roomCourseTableQueryParser(dynamic html) {
    dynamic rawHtml;

    if (html is Uint8List) {
      rawHtml = clearTransEncoding(html);
    } else {
      rawHtml = html;
    }

    final Document document = parse(rawHtml);

    final Map<String, dynamic> data = <String, dynamic>{
      'courses': <String, dynamic>{},
      'coursetable': <String, List<dynamic>>{
        'timeCodes': <String>[],
        'Monday': <Map<String, dynamic>>[],
        'Tuesday': <Map<String, dynamic>>[],
        'Wednesday': <Map<String, dynamic>>[],
        'Thursday': <Map<String, dynamic>>[],
        'Friday': <Map<String, dynamic>>[],
        'Saturday': <Map<String, dynamic>>[],
        'Sunday': <Map<String, dynamic>>[],
      },
      '_temp_time': <Map<String, dynamic>>{},
      'timeCodes': <Map<String, dynamic>>[],
    };

    final Map<String, dynamic> courseTable =
        data['coursetable'] as Map<String, dynamic>;

    final Map<String, dynamic> courses =
        data['courses'] as Map<String, dynamic>;

    if (document.getElementsByTagName('table').isEmpty) {
      //table not found
      // return data;
    }
    try {
      //the top table parse
      if (document.getElementsByTagName('table').isNotEmpty) {
        final List<Element> topTable = document
            .getElementsByTagName('table')[0]
            .getElementsByTagName('tr');
        for (int i = 1; i < topTable.length; i++) {
          final List<Element> td = topTable[i].getElementsByTagName('td');
          courses.addAll(
            <String, Map<String, dynamic>>{
              "${td[1].text.replaceAll(specialSpace, '')}"
                      "${td[10].text.replaceAll(specialSpace, '')}":
                  <String, dynamic>{
                'code': td[0].text.replaceAll(specialSpace, ''),
                'title': td[1].text.replaceAll(specialSpace, ''),
                'className': td[2].text.replaceAll(specialSpace, ''),
                'group': td[3].text.replaceAll(specialSpace, ''),
                'units': td[4].text.replaceAll(specialSpace, ''),
                'hours': td[5].text.replaceAll(specialSpace, ''),
                'required': td[7].text.replaceAll(specialSpace, ''),
                'at': td[8].text.replaceAll(specialSpace, ''),
                'times': td[9].text.replaceAll(specialSpace, ''),
                'sectionTimes': <Map<String, dynamic>>[],
                'location': null,
                'instructors':
                    td[10].text.replaceAll(specialSpace, '').split(','),
              },
            },
          );
        }
      }
      data['courses'] = courses;
    } on Exception catch (e, s) {
      CrashlyticsUtil.instance
          .recordError(e, s, reason: 'roomCourseTableQueryParser courses');
    }

    //the second talbe.

    //make timetable
    final List<Element> secondTable = document.getElementsByTagName('table');
    if (secondTable.isNotEmpty) {
      try {
        final List<Element> td = secondTable[1].getElementsByTagName('tr');
        //remark:Best split is regex but... Chinese have some difficulty Q_Q
        for (int i = 1; i < td.length; i++) {
          String temptext =
              td[i].getElementsByTagName('td')[0].text.replaceAll(' ', '');
          temptext = temptext
              .substring(0, temptext.length - 10)
              .replaceAll(specialSpace, '');
          temptext = temptext.substring(1, temptext.length - 1);
          (courseTable['timeCodes'] as List<String>).add(temptext);
        }
      } on Exception catch (e, s) {
        CrashlyticsUtil.instance
            .recordError(e, s, reason: 'roomCourseTableQueryParser timeCodes');
      }
    }
    //make each day.
    final List<String> keyName = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    String tmpCourseName = '';
    try {
      final Map<String, dynamic> tempTime = <String, dynamic>{};

      // Cache table and rows to avoid repeated DOM queries
      final Element table2 = document.getElementsByTagName('table')[1];
      final List<Element> tableRows = table2.getElementsByTagName('tr');
      final int timeCodesLength =
          (courseTable['timeCodes'] as List<dynamic>).length;

      for (int key = 0; key < keyName.length; key++) {
        for (int eachSession = 1;
            eachSession < timeCodesLength + 1;
            eachSession++) {
          final Element rowElement = tableRows[eachSession];
          final List<Element> rowTds = rowElement.getElementsByTagName('td');
          final Element eachDays = rowTds[key + 1];

          final String eachDaysOuterHtml = eachDays.outerHtml;
          final List<String> splitData = eachDaysOuterHtml
              .substring(
                eachDaysOuterHtml.indexOf('; font-family: 細明體') + 20,
                eachDaysOuterHtml.indexOf(';</font>'),
              )
              .split('<br>');

          final String eachDaysDate = rowTds[0].outerHtml;

          final List<String> courseTime = eachDaysDate
              .substring(
                eachDaysDate.indexOf('&nbsp;<br>') + 10,
                eachDaysDate.indexOf('&nbsp;<br><br><'),
              )
              .split('<br>');
          String tempSection =
              courseTime[0].replaceAll(' ', '').replaceAll(specialSpace, '');
          tempSection = tempSection.substring(1, tempSection.length - 1);

          // Cache split result to avoid repeated string operations
          final List<String> timeParts = courseTime[1].split('-');
          final String startTime =
              '${timeParts[0].substring(0, 2)}:${timeParts[0].substring(2, 4)}';
          final String endTime =
              '${timeParts[1].substring(0, 2)}:${timeParts[1].substring(2, 4)}';

          tempTime.addAll(<String, dynamic>{
            tempSection: <String, dynamic>{
              'startTime': startTime,
              'endTime': endTime,
              'section': tempSection,
            },
          });

          if (splitData.length <= 1) {
            continue;
          }
          String title = splitData[0].replaceAll('\n', '');

          if (title.lastIndexOf('>') > -1) {
            title = title
                .substring(title.lastIndexOf('>') + 1, title.length)
                .replaceAll('&nbsp;', '')
                .replaceAll(';', '');
          }

          (courseTable[keyName[key]] as List<dynamic>).add(
            <String, dynamic>{
              'title': title.replaceAll('&nbsp;', ''),
              'date': <String, dynamic>{
                'startTime': startTime,
                'endTime': endTime,
                'section': tempSection,
              },
              'rawInstructors': splitData[1]
                  .replaceAll(specialSpace, '')
                  .replaceAll('&nbsp;', ''),
              'instructors': splitData[1].replaceAll('&nbsp;', '').split(','),
            },
          );
        }
      }
      data['_temp_time'] = tempTime;
      // mix weekday to course.
      for (int weekKeyIndex = 0;
          weekKeyIndex < keyName.length;
          weekKeyIndex++) {
        final List<dynamic> courses =
            courseTable[keyName[weekKeyIndex]] as List<dynamic>;
        for (final dynamic course in courses) {
          final Map<String, dynamic> temp = <String, dynamic>{
            'weekday': weekKeyIndex + 1,
            //ignore: avoid_dynamic_calls
            'index': data['_temp_time']
                .values
                .toList()
                //ignore: avoid_dynamic_calls
                .indexOf(data['_temp_time'][course['date']['section']]),
          };
          //ignore: avoid_dynamic_calls
          tmpCourseName = "${course['title']}${course['rawInstructors']}";
          //ignore: avoid_dynamic_calls
          data['courses'][tmpCourseName]['sectionTimes'].add(temp);
        }
      }
      // courses to list
      //ignore: avoid_dynamic_calls
      data['courses'] = data['courses'].values.toList();
      data.remove('coursetable');
      //ignore: avoid_dynamic_calls
      data['_temp_time'] = data['_temp_time'].values.toList();
      for (int timeCodeIndex = 0;
          timeCodeIndex < (data['_temp_time'] as List<dynamic>).length;
          timeCodeIndex++) {
        //ignore: avoid_dynamic_calls
        data['timeCodes'].add(<String, dynamic>{
          //ignore: avoid_dynamic_calls
          'title': data['_temp_time'][timeCodeIndex]['section'],
          //ignore: avoid_dynamic_calls
          'startTime': data['_temp_time'][timeCodeIndex]['startTime'],
          //ignore: avoid_dynamic_calls
          'endTime': data['_temp_time'][timeCodeIndex]['endTime'],
        });
      }
      data.remove('_temp_time');
    } catch (e, s) {
      CrashlyticsUtil.instance
          .recordError(e, s, reason: 'course name = $tmpCourseName');
    }

    return CourseData.fromJson(data);
  }
}
