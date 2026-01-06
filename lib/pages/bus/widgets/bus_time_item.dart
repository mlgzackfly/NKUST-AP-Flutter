import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/models/bus_data.dart';
import 'package:nkust_ap/utils/app_localizations.dart';

/// A list item widget displaying bus time information.
///
/// Shows the time, reservation count, special train status, and
/// current reservation state. Tappable for booking or canceling.
class BusTimeItem extends StatelessWidget {
  const BusTimeItem({
    super.key,
    required this.busTime,
    required this.onTap,
  });

  /// The bus time data to display.
  final BusTime busTime;

  /// Called when the item is tapped.
  final VoidCallback? onTap;

  TextStyle _textStyle(BuildContext context) => TextStyle(
        color: busTime.getColorState(context),
        fontSize: 18.0,
        decorationColor: ApTheme.of(context).greyText,
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations app = AppLocalizations.of(context);
    final ApLocalizations ap = ApLocalizations.of(context);

    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildIcon(context),
                _buildTime(context),
                _buildReserveCount(context, ap),
                _buildSpecialTrain(context, app),
                _buildTimeIcon(context),
                _buildReserveState(context, app),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: ApTheme.of(context).grey, height: 0.0),
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Expanded(
      child: Icon(
        ApIcon.directionsBus,
        size: 20.0,
        color: busTime.getColorState(context),
      ),
    );
  }

  Widget _buildTime(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Text(
        busTime.getTime(),
        textAlign: TextAlign.center,
        style: _textStyle(context),
      ),
    );
  }

  Widget _buildReserveCount(BuildContext context, ApLocalizations ap) {
    return Expanded(
      flex: 2,
      child: Text(
        '${busTime.reserveCount} ${ap.people}',
        textAlign: TextAlign.center,
        style: _textStyle(context),
      ),
    );
  }

  Widget _buildSpecialTrain(BuildContext context, AppLocalizations? app) {
    return Expanded(
      flex: 3,
      child: Text(
        busTime.getSpecialTrainTitle(app),
        textAlign: TextAlign.center,
        style: _textStyle(context),
      ),
    );
  }

  Widget _buildTimeIcon(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Icon(
        ApIcon.accessTime,
        size: 20.0,
        color: busTime.getColorState(context),
      ),
    );
  }

  Widget _buildReserveState(BuildContext context, AppLocalizations? app) {
    return Expanded(
      flex: 3,
      child: Text(
        busTime.getReserveState(app),
        textAlign: TextAlign.center,
        style: _textStyle(context),
      ),
    );
  }
}
