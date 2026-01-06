import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/models/leave_model.dart';

/// A card widget displaying a leave date with selectable time slots.
///
/// This widget shows a date header with a remove button, and a grid
/// of time code buttons that can be toggled on/off.
class LeaveDatePickerCard extends StatelessWidget {
  const LeaveDatePickerCard({
    super.key,
    required this.leaveModel,
    required this.timeCodes,
    required this.onRemove,
    required this.onTimeCodeToggle,
  });

  /// The leave model containing date and selection state.
  final LeaveModel leaveModel;

  /// List of time code labels to display in the grid.
  final List<String> timeCodes;

  /// Called when the remove button is tapped.
  final VoidCallback onRemove;

  /// Called when a time code is toggled.
  final void Function(int index) onTimeCodeToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 8.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 4.0),
            _buildHeader(context),
            _buildTimeCodeGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Text(leaveModel.formattedDate),
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            ApIcon.cancel,
            size: 20.0,
            color: ApTheme.of(context).red,
          ),
          onPressed: onRemove,
        ),
      ],
    );
  }

  Widget _buildTimeCodeGrid(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: timeCodes.length,
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = leaveModel.selected[index];
          return InkWell(
            onTap: () => onTimeCodeToggle(index),
            child: Container(
              margin: const EdgeInsets.all(4.0),
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                border: Border.all(color: ApTheme.of(context).blueAccent),
                color: isSelected ? ApTheme.of(context).blueAccent : null,
              ),
              alignment: Alignment.center,
              child: Text(
                timeCodes[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : ApTheme.of(context).blueAccent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
