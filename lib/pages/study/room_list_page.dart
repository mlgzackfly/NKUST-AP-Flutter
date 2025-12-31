import 'package:ap_common/ap_common.dart';
import 'package:flutter/material.dart';
import 'package:nkust_ap/api/helper.dart';
import 'package:nkust_ap/models/room_data.dart';
import 'package:nkust_ap/pages/study/room_course_page.dart';
import 'package:nkust_ap/utils/app_localizations.dart';
import 'package:nkust_ap/utils/page_state.dart';

class RoomListPage extends StatefulWidget {
  @override
  _RoomListPageState createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  late AppLocalizations app;

  PageState state = PageState.loading;

  int campusIndex = 0;
  int roomIndex = 0;

  RoomData? roomData;
  CourseData? courseData;

  String? customStateHint;

  @override
  void initState() {
    _getRoomList();
    AnalyticsUtil.instance.setCurrentScreen(
      'RoomListPage',
      'room_list_page.dart',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(ApLocalizations.of(context).roomList),
      ),
      body: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ItemPicker(
            dialogTitle: app.campus,
            items: app.campuses,
            currentIndex: campusIndex,
            onSelected: (int index) {
              setState(() => campusIndex = index);
              _getRoomList();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _getRoomList();
                return;
              },
              child: body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget body() {
    switch (state) {
      case PageState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case PageState.finish:
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(roomData!.data[index].name),
              onTap: () {
                roomIndex = index;
                ApUtils.pushCupertinoStyle(
                  context,
                  EmptyRoomPage(
                    room: roomData!.data[roomIndex],
                  ),
                );
              },
            );
          },
          itemCount: roomData!.data.length,
        );
      case PageState.custom:
      case _:
        return InkWell(
          onTap: () {
            _getRoomList();
            AnalyticsUtil.instance.logEvent('retry_click');
          },
          child: HintContent(
            icon: ApIcon.classIcon,
            content: customStateHint ?? '',
          ),
        );
    }
  }

  Future<void> _getRoomList() async {
    Helper.instance.getRoomList(
      campusCode: campusIndex + 1,
      callback: GeneralCallback<RoomData>(
        onSuccess: (RoomData data) {
          setState(() {
            roomData = data;
            if (roomData != null) {
              state = PageState.finish;
            } else {
              state = PageState.custom;
              customStateHint = ApLocalizations.of(context).somethingError;
            }
          });
        },
        onFailure: (DioException e) {
          if (e.type != DioExceptionType.cancel) {
            setState(() {
              state = PageState.custom;
              customStateHint = e.i18nMessage;
            });
          }
          if (e.hasResponse) {
            AnalyticsUtil.instance.logApiEvent(
              'getRoomCourseTables',
              e.response!.statusCode!,
              message: e.message ?? '',
            );
          }
        },
        onError: (GeneralResponse generalResponse) {
          setState(() {
            state = PageState.custom;
            customStateHint = generalResponse.getGeneralMessage(context);
          });
        },
      ),
    );
  }
}
