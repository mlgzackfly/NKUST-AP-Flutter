import 'package:intl/intl.dart';
import 'package:nkust_ap/models/bus_data.dart';
import 'package:nkust_ap/models/bus_reservations_data.dart';
import 'package:nkust_ap/models/bus_violation_records_data.dart';

/// Converts a timestamp from the bus API to an ISO 8601 datetime string.
String busRealTime(dynamic timestamp) {
  late int time;
  if (timestamp is String) {
    time = int.parse(timestamp);
  } else if (timestamp is int) {
    time = timestamp;
  } else if (timestamp is double) {
    time = timestamp.round();
  } else {
    throw ArgumentError('Invalid timestamp type: ${timestamp.runtimeType}');
  }
  final DateTime date = DateTime.fromMillisecondsSinceEpoch(
    ((time / 10000000 - 62135596800) * 1000).round(),
  );
  return date.toIso8601String();
}

/// Converts an integer to a boolean (0 = false, non-zero = true).
bool intToBool(int a) => a != 0;

/// Parses bus timetable data from API response.
///
/// Returns a [BusData] object with parsed bus times.
BusData busTimeTableParser(
  Map<String, dynamic> data, {
  BusReservationsData? busReservations,
}) {
  final List<BusTime> busTimes = <BusTime>[];
  final List<dynamic> rawList = data['data'] as List<dynamic>;

  for (int i = 0; i < rawList.length; i++) {
    final Map<String, dynamic> item = rawList[i] as Map<String, dynamic>;
    final String specialTrain = item['SpecialTrain']?.toString() ?? '0';
    final bool isHomeCharteredBus = specialTrain == '1';

    String cancelKey = '';
    if (busReservations != null) {
      final DateFormat format = DateFormat('yyyy/MM/dd HH:mm');
      final DateTime departureDateTime =
          format.parse(busRealTime(item['runDateTime']));

      for (final BusReservation reservation in busReservations.reservations) {
        if (format.parse(reservation.dateTime) == departureDateTime &&
            reservation.start == item['startStation']) {
          cancelKey = reservation.cancelKey;
          break;
        }
      }
    }

    busTimes.add(
      BusTime(
        endEnrollDateTime: DateTime.parse(
          busRealTime(item['EndEnrollDateTime']),
        ),
        departureTime: DateTime.parse(busRealTime(item['runDateTime'])),
        startStation: item['startStation'] as String,
        endStation: item['endStation'] as String,
        busId: item['busId'].toString(),
        reserveCount: int.parse(item['reserveCount'] as String),
        limitCount: int.parse(item['limitCount'] as String),
        isReserve: intToBool(int.parse(item['isReserve'] as String) + 1),
        specialTrain: specialTrain,
        description: item['SpecialTrainRemark'] as String?,
        cancelKey: cancelKey,
        homeCharteredBus: isHomeCharteredBus,
      ),
    );
  }

  return BusData(
    canReserve: true,
    timetable: busTimes,
  );
}

/// Parses bus reservations data from API response.
///
/// Returns a [BusReservationsData] object with parsed reservations.
BusReservationsData busReservationsParser(Map<String, dynamic> data) {
  final List<BusReservation> reservations = <BusReservation>[];
  final List<dynamic> rawList = data['data'] as List<dynamic>;

  for (final dynamic item in rawList) {
    final Map<String, dynamic> map = item as Map<String, dynamic>;
    reservations.add(
      BusReservation(
        dateTime: busRealTime(map['time']),
        cancelKey: map['key'] as String,
        start: map['start'] as String,
        end: map['end'] as String,
        state: map['state']?.toString() ?? '',
        travelState: map['SpecialTrain']?.toString() ?? '',
      ),
    );
  }

  return BusReservationsData(reservations: reservations);
}

/// Parses bus violation records from API response.
///
/// Returns a [BusViolationRecordsData] object with parsed violations.
BusViolationRecordsData busViolationRecordsParser(Map<String, dynamic> data) {
  final List<Reservation> reservations = <Reservation>[];
  final List<dynamic> rawList = data['data'] as List<dynamic>;

  for (final dynamic item in rawList) {
    final Map<String, dynamic> map = item as Map<String, dynamic>;
    final String specialTrain = map['SpecialTrain']?.toString() ?? '0';

    reservations.add(
      Reservation(
        time: DateTime.parse(busRealTime(map['runBus'])),
        startStation: map['start'] as String,
        endStation: map['end'] as String,
        amountend: _parseAmount(map['costMoney']),
        isPayment: _parseIsPayment(map['receipt']),
        homeCharteredBus: specialTrain == '1',
      ),
    );
  }

  return BusViolationRecordsData(reservations: reservations);
}

/// Helper to parse amount which might be int or String.
int _parseAmount(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Helper to parse payment status which might be bool, int, or String.
bool _parseIsPayment(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}
