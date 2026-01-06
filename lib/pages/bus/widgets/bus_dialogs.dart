import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/models/bus_data.dart';
import 'package:nkust_ap/utils/app_localizations.dart';

/// Utility class for showing bus-related dialogs.
abstract class BusDialogs {
  /// Shows a confirmation dialog for booking a bus.
  static Future<bool?> showBookingConfirmation({
    required BuildContext context,
    required BusTime busTime,
    required String startStation,
  }) {
    final AppLocalizations app = AppLocalizations.of(context);
    final ApLocalizations ap = ApLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => YesNoDialog(
        title: '${busTime.getSpecialTrainTitle(app)}'
            "${busTime.specialTrain == '0' ? app.reserve : ''}",
        contentWidget: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: ApTheme.of(context).grey,
              height: 1.3,
              fontSize: 16.0,
            ),
            children: <TextSpan>[
              TextSpan(
                text: '${busTime.getTime()} $startStation\n',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '${app.destination}：${busTime.getEnd(app)}\n\n',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (busTime.description != null &&
                  busTime.description!.isNotEmpty)
                TextSpan(
                  text:
                      '${busTime.description!.replaceAll('<br />', '\n')}\n\n',
                  style: TextStyle(
                    color: ApTheme.of(context).grey,
                    height: 1.3,
                    fontSize: 14.0,
                  ),
                ),
              TextSpan(
                text: app.busReserveConfirmTitle,
                style: TextStyle(color: ApTheme.of(context).grey),
              ),
            ],
          ),
        ),
        leftActionText: ap.cancel,
        rightActionText: app.reserve,
        rightActionFunction: () => Navigator.of(context).pop(true),
      ),
    );
  }

  /// Shows a confirmation dialog for canceling a bus reservation.
  static Future<bool?> showCancelConfirmation({
    required BuildContext context,
    required BusTime busTime,
  }) {
    final AppLocalizations app = AppLocalizations.of(context);
    final ApLocalizations ap = ApLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => YesNoDialog(
        title: app.busCancelReserve,
        contentWidget: Text(
          '${app.busCancelReserveConfirmContent1}${busTime.getStart(app)}'
          '${app.busCancelReserveConfirmContent2}${busTime.getEnd(app)}\n'
          '${busTime.getTime()}${app.busCancelReserveConfirmContent3}',
          textAlign: TextAlign.center,
        ),
        leftActionText: ap.back,
        rightActionText: ap.determine,
        rightActionFunction: () => Navigator.of(context).pop(true),
      ),
    );
  }

  /// Shows a success dialog after booking a bus.
  static void showBookingSuccess({
    required BuildContext context,
    required BusTime busTime,
  }) {
    final AppLocalizations app = AppLocalizations.of(context);
    final ApLocalizations ap = ApLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) => DefaultDialog(
        title: app.busReserveSuccess,
        contentWidget: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            style: TextStyle(
              color: ApTheme.of(context).grey,
              height: 1.3,
              fontSize: 16.0,
            ),
            children: <TextSpan>[
              TextSpan(
                text: '${app.busReserveDate}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${busTime.getDate()}\n'),
              TextSpan(
                text: '${app.busReserveLocation}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${busTime.getStart(app)}${app.campus}\n'),
              TextSpan(
                text: '${app.busReserveTime}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: busTime.getTime()),
            ],
          ),
        ),
        actionText: ap.iKnow,
        actionFunction: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  /// Shows a success dialog after canceling a bus reservation.
  static void showCancelSuccess({
    required BuildContext context,
    required BusTime busTime,
  }) {
    final AppLocalizations app = AppLocalizations.of(context);
    final ApLocalizations ap = ApLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) => DefaultDialog(
        title: app.busCancelReserveSuccess,
        contentWidget: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            style: TextStyle(
              color: ApTheme.of(context).grey,
              height: 1.3,
              fontSize: 16.0,
            ),
            children: <TextSpan>[
              TextSpan(
                text: '${app.busReserveCancelDate}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${busTime.getDate()}\n'),
              TextSpan(
                text: '${app.busReserveCancelLocation}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '${busTime.getStart(app)}${app.campus}\n'),
              TextSpan(
                text: '${app.busReserveCancelTime}：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: busTime.getTime()),
            ],
          ),
        ),
        actionText: ap.iKnow,
        actionFunction: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }
}
