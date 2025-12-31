import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/models/reward_and_penalty_data.dart';
import 'package:nkust_ap/utils/global.dart';
import 'package:nkust_ap/utils/page_state.dart';
import 'package:nkust_ap/widgets/semester_picker.dart';
import 'package:sprintf/sprintf.dart';

class RewardAndPenaltyPage extends StatefulWidget {
  static const String routerName = '/user/reward-and-penalty';

  @override
  _RewardAndPenaltyPageState createState() => _RewardAndPenaltyPageState();
}

class _RewardAndPenaltyPageState extends State<RewardAndPenaltyPage> {
  final GlobalKey<SemesterPickerState> key = GlobalKey<SemesterPickerState>();

  late ApLocalizations ap;

  PageState state = PageState.loading;
  String? customStateHint;

  late Semester selectSemester;
  SemesterData? semesterData;
  late RewardAndPenaltyData rewardAndPenaltyData;

  bool isOffline = false;

  @override
  void initState() {
    AnalyticsUtil.instance.setCurrentScreen(
      'RewardAndPenaltyPage',
      'reward_and_penalty_page.dart',
    );
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
        title: Text(ap.rewardAndPenalty),
        backgroundColor: ApTheme.of(context).blue,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () {
          key.currentState!.pickSemester();
        },
      ),
      body: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const SizedBox(height: 8.0),
          SemesterPicker(
            key: key,
            featureTag: 'reward',
            onSelect: (Semester semester, int index) {
              setState(() {
                selectSemester = semester;
                state = PageState.loading;
              });
              _getMidtermAlertsData();
            },
          ),
          if (isOffline)
            Text(
              ap.offlineScore,
              style: TextStyle(color: ApTheme.of(context).grey),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _getMidtermAlertsData();
                AnalyticsUtil.instance.logEvent('refresh_swipe');
                return;
              },
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  String? get stateHint {
    switch (state) {
      case PageState.error:
        return ap.somethingError;
      case PageState.empty:
        return ap.rewardAndPenaltyEmpty;
      case PageState.offline:
        return ap.noOfflineData;
      case PageState.custom:
        return customStateHint;
      default:
        return '';
    }
  }

  IconData get stateIcon {
    switch (state) {
      case PageState.offline:
        return ApIcon.offlineBolt;
      case PageState.error:
      case PageState.empty:
      case PageState.custom:
      default:
        return ApIcon.classIcon;
    }
  }

  Widget _body() {
    switch (state) {
      case PageState.loading:
        return Container(
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      case PageState.finish:
        return ListView.builder(
          itemBuilder: (_, int index) {
            return _midtermAlertsItem(rewardAndPenaltyData.data[index]);
          },
          itemCount: rewardAndPenaltyData.data.length,
        );
      case PageState.empty:
      case PageState.error:
      case PageState.offline:
      case PageState.custom:
      case _:
        return InkWell(
          onTap: () {
            if (state == PageState.empty) {
              key.currentState!.pickSemester();
            } else {
              _getMidtermAlertsData();
            }
            AnalyticsUtil.instance.logEvent('retry_click');
          },
          child: HintContent(
            icon: ApIcon.classIcon,
            content: stateHint!,
          ),
        );
    }
  }

  Widget _midtermAlertsItem(RewardAndPenalty item) {
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
            item.reason,
            style: const TextStyle(fontSize: 18.0),
          ),
          trailing: Text(
            item.type,
            style: TextStyle(
              fontSize: 16.0,
              color: item.isReward ? Colors.green : Colors.red,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              sprintf(
                ap.rewardAndPenaltyContent,
                <dynamic>[
                  item.counts,
                  item.date,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getMidtermAlertsData() async {
    if (PreferenceUtil.instance.getBool(Constants.prefIsOfflineLogin, false)) {
      setState(() {
        state = PageState.offline;
      });
      return;
    }
    Helper.cancelToken!.cancel('');
    Helper.cancelToken = CancelToken();
    Helper.instance.getRewardAndPenalty(
      semester: selectSemester,
      callback: GeneralCallback<RewardAndPenaltyData>(
        onSuccess: (RewardAndPenaltyData data) {
          if (mounted) {
            setState(() {
              rewardAndPenaltyData = data;
              if (data.data.isEmpty) {
                state = PageState.empty;
              } else {
                state = PageState.finish;
              }
            });
          }
        },
        onFailure: (DioException e) {
          setState(() {
            state = PageState.custom;
            customStateHint = e.i18nMessage;
          });
          if (e.hasResponse) {
            AnalyticsUtil.instance.logApiEvent(
              'getRewardAndPenalty',
              e.response!.statusCode!,
              message: e.message ?? '',
            );
          }
        },
        onError: (GeneralResponse response) {
          setState(() {
            state = PageState.custom;
            customStateHint = response.getGeneralMessage(context);
          });
        },
      ),
    );
  }
}
