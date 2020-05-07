import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/config/constants.dart';
import 'package:nkust_ap/models/midterm_alerts_data.dart';
import 'package:nkust_ap/models/semester_data.dart';
import 'package:nkust_ap/utils/app_localizations.dart';
import 'package:nkust_ap/utils/firebase_analytics_utils.dart';
import 'package:nkust_ap/utils/utils.dart';
import 'package:nkust_ap/widgets/semester_picker.dart';
import 'package:sprintf/sprintf.dart';

enum _State { loading, finish, error, empty, offline }

class MidtermAlertsPage extends StatefulWidget {
  static const String routerName = "/user/midtermAlerts";

  @override
  _MidtermAlertsPageState createState() => _MidtermAlertsPageState();
}

class _MidtermAlertsPageState extends State<MidtermAlertsPage> {
  final key = GlobalKey<SemesterPickerState>();

  ApLocalizations ap;

  _State state = _State.loading;

  Semester selectSemester;
  SemesterData semesterData;
  MidtermAlertsData midtermAlertData;

  bool isOffline = false;

  @override
  void initState() {
    //TODO FA
    //FA.setCurrentScreen('ScorePage', 'score_page.dart');
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ap.midtermAlerts),
        backgroundColor: ApTheme.of(context).blue,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () {
          key.currentState.pickSemester();
        },
      ),
      body: Container(
        child: Flex(
          direction: Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(height: 8.0),
            SemesterPicker(
                key: key,
                onSelect: (semester, index) {
                  setState(() {
                    selectSemester = semester;
                    state = _State.loading;
                  });
                  _getMidtermAlertsData();
                }),
            if (isOffline)
              Text(
                ap.offlineScore,
                style: TextStyle(color: ApTheme.of(context).grey),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _getMidtermAlertsData();
                  FA.logAction('refresh', 'swipe');
                  return null;
                },
                child: _body(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _body() {
    switch (state) {
      case _State.loading:
        return Container(
            child: CircularProgressIndicator(), alignment: Alignment.center);
      case _State.empty:
      case _State.error:
        return FlatButton(
          onPressed: () {
            if (state == _State.error)
              _getMidtermAlertsData();
            else
              key.currentState.pickSemester();
            FA.logAction('retry', 'click');
          },
          child: HintContent(
            icon: ApIcon.classIcon,
            content:
                state == _State.error ? ap.clickToRetry : ap.midtermAlertsEmpty,
          ),
        );
      case _State.offline:
        return HintContent(
          icon: ApIcon.classIcon,
          content: ap.noOfflineData,
        );
      default:
        return ListView.builder(
          itemBuilder: (_, index) {
            return _midtermAlertsItem(midtermAlertData.courses[index]);
          },
          itemCount: midtermAlertData.courses.length,
        );
    }
  }

  Widget _midtermAlertsItem(MidtermAlerts item) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            item.title,
            style: TextStyle(fontSize: 18.0),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              sprintf(
                ap.midtermAlertsContent,
                [
                  item.reason ?? '',
                  item.remark ?? '',
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _getMidtermAlertsData() async {
    if (Preferences.getBool(Constants.PREF_IS_OFFLINE_LOGIN, false)) {
      setState(() {
        state = _State.offline;
      });
      return;
    }
    Helper.cancelToken.cancel('');
    Helper.cancelToken = CancelToken();
    Helper.instance.getMidtermAlerts(semester: selectSemester).then((response) {
      if (mounted)
        setState(() {
          if (response == null) {
            state = _State.empty;
          } else {
            if (response.courses.length == 0) {
              state = _State.empty;
            } else {
              midtermAlertData = response;
              state = _State.finish;
            }
          }
        });
    }).catchError((e) {
      if (e is DioError) {
        switch (e.type) {
          case DioErrorType.RESPONSE:
            Utils.handleResponseError(context, 'getCourseTables', mounted, e);
            break;
          case DioErrorType.CANCEL:
            break;
          default:
            if (mounted)
              setState(() {
                state = _State.error;
              });
            Utils.handleDioError(context, e);
            break;
        }
      } else {
        throw e;
      }
    });
  }
}
