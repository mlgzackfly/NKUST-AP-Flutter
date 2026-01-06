import 'dart:convert';

import 'package:ap_common/ap_common.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:nkust_ap/models/bus_data.dart';
import 'package:nkust_ap/models/bus_reservations_data.dart';
import 'package:nkust_ap/models/bus_violation_records_data.dart';
import 'package:nkust_ap/models/midterm_alerts_data.dart';

/// Bus information for reservation availability.
class BusInfo {
  final bool canReserve;
  final String description;

  const BusInfo({
    required this.canReserve,
    required this.description,
  });
}

class MobileNkustParser {
  /// Parses bus violation records from HTML.
  ///
  /// Returns a list of [Reservation] objects.
  static List<Reservation> busViolationRecords(
    String rawHtml, {
    required bool paidStatus,
  }) {
    final Document document = html.parse(rawHtml);
    final List<Reservation> result = <Reservation>[];
    final DateFormat format = DateFormat('yyyy/MM/dd HH:mm');

    for (final Element trElement in document.getElementsByTagName('tr')) {
      final List<Element> tdElements = trElement.getElementsByTagName('td');
      final Element timeElement = tdElements[1].getElementsByTagName('div')[0];
      final List<String> startAndGoal = tdElements[3].text.split(' 到 ');

      result.add(
        Reservation(
          time: format.parse(
            '${timeElement.text.substring(0, 10)} '
            '${timeElement.text.substring(14)}',
          ),
          startStation: startAndGoal[0],
          endStation: startAndGoal[1],
          amountend: int.parse(tdElements[4].text),
          isPayment: paidStatus,
          homeCharteredBus: false,
        ),
      );
    }
    return result;
  }

  /// Parses bus user records from HTML.
  ///
  /// Returns a list of [BusReservation] objects.
  static List<BusReservation> busUserRecords(
    String rawHtml, {
    required String startStation,
    required String endStation,
  }) {
    final Document document = html.parse(rawHtml);
    final List<BusReservation> result = <BusReservation>[];

    for (final Element trElement in document.getElementsByTagName('tr')) {
      final String cancelKey =
          trElement.getElementsByTagName('input')[0].attributes['value'] ?? '';
      final List<Element> tdElements = trElement.getElementsByTagName('td');
      final String dateTime = '${tdElements[1].text.substring(0, 10)} '
          '${tdElements[1].text.substring(14)}';

      result.add(
        BusReservation(
          dateTime: dateTime,
          cancelKey: cancelKey,
          start: startStation,
          end: endStation,
          state: '',
          travelState: '',
        ),
      );
    }

    return result;
  }

  static CourseData courseTable(dynamic rawHtml) {
    final Document document = html.parse(rawHtml);

    final Map<String, dynamic> result = <String, dynamic>{
      'courses': <Map<String, dynamic>>[],
      'timeCodes': <Map<String, dynamic>>[],
    };
    final List<Element> inputElements = document.getElementsByTagName('input');
    final List<Map<String, dynamic>> coursesJson =
        jsonDecode(inputElements[0].attributes['value']!)
            as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> periodTimeJson =
        jsonDecode(inputElements[1].attributes['value']!)
            as List<Map<String, dynamic>>;

    for (final Map<String, dynamic> periodTime in periodTimeJson) {
      (result['timeCodes'] as List<Map<String, dynamic>>).add(
        <String, dynamic>{
          'title': "第${periodTime["PeriodName"]}節",
          'startTime':
              //ignore: avoid_dynamic_calls, lines_longer_than_80_chars
              "${periodTime["BegTime"].substring(0, 2)}:${periodTime["BegTime"].substring(2, 4)}",
          'endTime':
              //ignore: avoid_dynamic_calls, lines_longer_than_80_chars
              "${periodTime["EndTime"].substring(0, 2)}:${periodTime["EndTime"].substring(2, 4)}",
        },
      );
    }

    for (final Map<String, dynamic> course in coursesJson) {
      final Map<String, dynamic> temp = <String, dynamic>{
        'code': course['SelectCode'].toString(),
        'title': course['CourseName'].toString(),
        'className': course['ClassNameAbr'].toString(),
        'group': course['CourseGroup'].toString(),
        'units': course['Credit'].toString(),
        'hours': course['Hour'].toString(),
        'required': course['OptionName'].toString(),
        'at': course['Annual'],
        'sectionTimes': <Map<String, dynamic>>[],
        'instructors': (course['TeacherName'] as String).split(','),
        'location': <String, dynamic>{
          'building': '',
          'room': course['CourseRoom'] ?? '',
        },
      };
      final bool hasMorning = periodTimeJson[0]['PeriodName'] == 'M';
      final List<dynamic> courseWeekPeriod =
          course['CourseWeekPeriod'] as List<dynamic>;
      for (final dynamic time in courseWeekPeriod) {
        //ignore: avoid_dynamic_calls
        final int weekday = int.tryParse(time['CourseWeek'] as String) ?? 0;
        //ignore: avoid_dynamic_calls
        final int? sectionIndex = int.tryParse(time['CoursePeriod'] as String);
        if (weekday <= 0 || weekday > 7 || sectionIndex == null) continue;
        (temp['sectionTimes'] as List<Map<String, dynamic>>).add(
          <String, dynamic>{
            'weekday': weekday,
            'index': sectionIndex - (hasMorning ? 0 : 1),
          },
        );
      }
      (result['courses'] as List<Map<String, dynamic>>).add(temp);
    }

    return CourseData.fromJson(result);
  }

  static MidtermAlertsData midtermAlerts(dynamic rawHtml) {
    final Document document = html.parse(rawHtml);
    final List<MidtermAlerts> courses = <MidtermAlerts>[];

    // 嘗試使用 datatable 結構（與成績頁面類似）
    final Element? datatable = document.getElementById('datatable');
    if (datatable != null) {
      final List<Element> trElements = datatable.getElementsByTagName('tr');
      // 跳過表頭
      for (int i = 1; i < trElements.length; i++) {
        final List<Element> tdElements =
            trElements[i].getElementsByTagName('td');
        // 預期欄位：序號、班級、課程名稱、分組、授課教師、預警原因、備註
        if (tdElements.length >= 5) {
          courses.add(
            MidtermAlerts(
              entry: tdElements[0].text.trim(),
              className: tdElements[1].text.trim(),
              title: tdElements[2].text.trim(),
              group: tdElements.length > 3 ? tdElements[3].text.trim() : '',
              instructors:
                  tdElements.length > 4 ? tdElements[4].text.trim() : '',
              reason: tdElements.length > 5 ? tdElements[5].text.trim() : null,
              remark: tdElements.length > 6 ? tdElements[6].text.trim() : null,
            ),
          );
        }
      }
    } else {
      // 備用方案：嘗試解析一般 table 結構
      final List<Element> tables = document.getElementsByTagName('table');
      for (final Element table in tables) {
        final List<Element> trElements = table.getElementsByTagName('tr');
        for (int i = 1; i < trElements.length; i++) {
          final List<Element> tdElements =
              trElements[i].getElementsByTagName('td');
          if (tdElements.length >= 5) {
            courses.add(
              MidtermAlerts(
                entry: tdElements[0].text.trim(),
                className: tdElements[1].text.trim(),
                title: tdElements[2].text.trim(),
                group: tdElements.length > 3 ? tdElements[3].text.trim() : '',
                instructors:
                    tdElements.length > 4 ? tdElements[4].text.trim() : '',
                reason:
                    tdElements.length > 5 ? tdElements[5].text.trim() : null,
                remark:
                    tdElements.length > 6 ? tdElements[6].text.trim() : null,
              ),
            );
          }
        }
        // 如果找到有效資料就停止
        if (courses.isNotEmpty) break;
      }
    }

    return MidtermAlertsData(courses: courses);
  }

  /// Parses bus info from HTML.
  ///
  /// Returns a [BusInfo] object with reservation availability.
  static BusInfo busInfo(String? rawHtml) {
    final Document document = html.parse(rawHtml);
    final String canNotReserveText =
        document.getElementById('BusMemberStop')!.attributes['value']!;
    final bool canReserve = !bool.fromEnvironment(
      canNotReserveText,
    );
    final List<Element> elements =
        document.getElementsByClassName('alert alert-danger alert-dismissible');
    String description = '';
    if (elements.isNotEmpty) {
      description = elements.first.text;
    }
    return BusInfo(
      canReserve: canReserve,
      description: description.trim().replaceAll(' ', ''),
    );
  }

  /// Parses bus timetable from HTML.
  ///
  /// Returns a list of [BusTime] objects.
  static List<BusTime> busTimeTable(
    dynamic rawHtml, {
    String? time,
    String? startStation,
    String? endStation,
  }) {
    final Document document = html.parse(rawHtml);
    final List<BusTime> result = <BusTime>[];
    final DateFormat format = DateFormat('yyyy/MM/dd HH:mm');

    final List<Element> allRows = document.getElementsByTagName('tr');
    for (int rowIndex = 1; rowIndex < allRows.length; rowIndex++) {
      final Element trElement = allRows[rowIndex];

      // Find input elements by ID attribute within the row
      // instead of creating a new Document for each row
      final List<Element> inputElements =
          trElement.getElementsByTagName('input');
      final Map<String, String> inputValues = <String, String>{
        for (final Element input in inputElements)
          if (input.attributes['id'] != null)
            input.attributes['id']!: input.attributes['value'] ?? '',
      };

      final bool canBook = inputValues['ReserveEnable'] != null;
      final String busId = inputValues['BusId'] ?? '';
      final String cancelKey = inputValues['ReserveId'] ?? '';
      final bool isReserve =
          inputValues['ReserveStateCode'] == '0' && cancelKey != '0';

      final List<Element> tdElements =
          trElement.getElementsByTagName('td').sublist(1);

      final DateTime departureTime =
          format.parse('$time ${tdElements[0].text}');
      final int reserveCount = int.parse(tdElements[1].text);

      bool homeCharteredBus = false;
      String specialTrain = '';
      String? description;

      if (tdElements[2].text != '') {
        if (tdElements[2].getElementsByTagName('button').isNotEmpty) {
          final String typeString = tdElements[2]
              .getElementsByTagName('button')[0]
              .text
              .replaceAll(' ', '')
              .replaceAll('\n', '');
          if (typeString == '返鄉專車') {
            homeCharteredBus = true;
          }
          if (typeString == '試辦專車') {
            specialTrain = '2';
          }
          description = tdElements[2]
              .getElementsByTagName('button')[0]
              .attributes['data-content'];
        }
      }

      result.add(
        BusTime(
          departureTime: departureTime,
          startStation: startStation ?? '',
          endStation: endStation ?? '',
          busId: busId,
          reserveCount: reserveCount,
          limitCount: 999,
          isReserve: isReserve,
          specialTrain: specialTrain,
          description: description,
          cancelKey: cancelKey,
          homeCharteredBus: homeCharteredBus,
          canBook: canBook,
        ),
      );
    }
    return result;
  }

  static ScoreData scores(dynamic rawHtml) {
    final Document document = html.parse(rawHtml);
    // generate scores list
    if (document.getElementById('datatable') == null) {
      return ScoreData.empty();
    }
    final List<Map<String, dynamic>> scoresList = <Map<String, dynamic>>[];
    //skip table header
    final List<Element> trElements =
        document.getElementById('datatable')!.getElementsByTagName('tr');
    if (trElements.length <= 1) {
      return ScoreData.empty();
    }

    for (final Element trElement in trElements.sublist(1)) {
      // select td element
      final List<Element> tdElements = trElement.getElementsByTagName('td');

      if (tdElements.length < 8) {
        // continue;
        return ScoreData.empty();
      }
      scoresList.add(<String, String>{
        'title': tdElements[0].text,
        'units': tdElements[1].text,
        'hours': tdElements[2].text,
        'required': tdElements[3].text,
        'at': tdElements[4].text,
        'middleScore': tdElements[5].text,
        'semesterScore': tdElements[6].text,
        'remark': tdElements[7].text,
      });
    }

    //detail data
    final List<Element> detailDiv =
        document.getElementsByClassName('text-bold text-info');

    if (detailDiv.length < 4) {
      return ScoreData.empty();
    }

    // Helper to extract clean value from parent text
    String extractValue(int index) {
      return detailDiv[index]
          .parent!
          .text
          .replaceAll(detailDiv[index].text, '')
          .replaceAll('\n', '')
          .replaceAll(' ', '');
    }

    final String averageStr = extractValue(0);
    final String conductStr = extractValue(1);

    return ScoreData.fromJson(
      <String, dynamic>{
        'scores': scoresList,
        'detail': <String, dynamic>{
          'average': double.parse(averageStr),
          'conduct': double.parse(conductStr),
          'classRank': extractValue(2),
          'departmentRank': extractValue(3),
        },
      },
    );
  }

  static UserInfo userInfo(dynamic rawHtml) {
    final Document document = html.parse(rawHtml);
    final List<Element> list = document.getElementsByClassName('user-header');
    if (list.isNotEmpty) {
      final List<Element> p = list[0].getElementsByTagName('p');
      if (p.length >= 2) {
        return UserInfo(
          id: p[0].text.split(' ').first,
          department: p[0].text.split(' ').last,
          name: p[1].text,
        );
      }
    }
    return UserInfo.empty();
  }

  static String getCSRF(dynamic rawHtml) {
    final Document document = html.parse(rawHtml);
    for (final Element inputElement in document.getElementsByTagName('input')) {
      if ((inputElement.attributes['name'] ?? '') ==
          '__RequestVerificationToken') {
        return inputElement.attributes['value']!;
      }
    }
    return '';
  }
}
