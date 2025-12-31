import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/config/constants.dart';

typedef SemesterCallback = void Function(Semester semester, int index);

class SemesterPicker extends StatefulWidget {
  final SemesterCallback? onSelect;
  final String? featureTag;

  const SemesterPicker({super.key, this.onSelect, this.featureTag});

  @override
  SemesterPickerState createState() => SemesterPickerState();
}

class SemesterPickerState extends State<SemesterPicker> {
  SemesterData? semesterData;
  Semester? selectSemester;

  int currentIndex = 0;

  @override
  void initState() {
    _getSemester();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (semesterData != null) pickSemester();
        if (widget.featureTag != null) {
          AnalyticsUtil.instance
              .logEvent('${widget.featureTag}_item_picker_click');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 16.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              selectSemester?.text ?? '',
              style: TextStyle(
                color: ApTheme.of(context).semesterText,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(width: 8.0),
            Icon(
              ApIcon.keyboardArrowDown,
              color: ApTheme.of(context).semesterText,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSemesterData() async {
    final SemesterData? cacheData = SemesterData.load();
    if (cacheData != null) {
      semesterData = cacheData;
      widget.onSelect
          ?.call(cacheData.defaultSemester, cacheData.defaultIndex);
      if (mounted) {
        setState(() {
          selectSemester = cacheData.defaultSemester;
        });
      }
    }
  }

  Future<void> _getSemester() async {
    if (PreferenceUtil.instance.getBool(Constants.prefIsOfflineLogin, false)) {
      _loadSemesterData();
      return;
    }
    Helper.instance.getSemester(
      callback: GeneralCallback<SemesterData>(
        onSuccess: (SemesterData data) {
          semesterData = data;
          data.save();
          final String _ = PreferenceUtil.instance.getString(
            ApConstants.currentSemesterCode,
            ApConstants.semesterLatest,
          );
          final String newSemester =
              '${Helper.username}_${data.defaultSemester.code}';
          PreferenceUtil.instance.setString(
            ApConstants.currentSemesterCode,
            newSemester,
          );
          if (mounted) {
            currentIndex = data.defaultIndex;
            widget.onSelect?.call(
              data.defaultSemester,
              data.defaultIndex,
            );
            setState(() {
              selectSemester = data.defaultSemester;
            });
          }
        },
        onFailure: (DioException e) {
          if (e.i18nMessage != null) {
            UiUtil.instance.showToast(context, e.i18nMessage!);
          }
          if (e.hasResponse) {
            AnalyticsUtil.instance.logApiEvent(
              'getSemester',
              e.response!.statusCode!,
              message: e.message ?? '',
            );
          }
        },
        onError: (GeneralResponse response) {
          UiUtil.instance
              .showToast(context, response.getGeneralMessage(context));
        },
      ),
    );
  }

  void pickSemester() {
    final SemesterData data = semesterData!;
    showDialog<int>(
      context: context,
      builder: (BuildContext context) => SimpleOptionDialog(
        title: ApLocalizations.of(context).pickSemester,
        items: <String>[
          for (final Semester item in data.data) item.text,
        ],
        index: currentIndex,
        onSelected: (int index) {
          currentIndex = index;
          widget.onSelect!(data.data[currentIndex], currentIndex);
          setState(() {
            selectSemester = data.data[currentIndex];
          });
        },
      ),
    );
  }
}
