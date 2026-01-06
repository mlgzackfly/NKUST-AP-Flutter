part of '../home_page.dart';

/// Data fetching logic for HomePage.
mixin HomeDataMixin on State<HomePage> {
  HomeState get state;
  set state(HomeState value);

  UserInfo? get userInfo;
  set userInfo(UserInfo? value);

  List<Announcement> get announcements;
  set announcements(List<Announcement> value);

  GlobalKey<HomePageScaffoldState> get homeKey;

  void _checkData();
  void _getUserPicture();

  void getAnnouncements() {
    AnnouncementHelper.instance.getAnnouncements(
      tags: <String>['nkust'],
      callback: GeneralCallback<List<Announcement>>(
        onFailure: (_) => setState(() => state = HomeState.error),
        onError: (_) => setState(() => state = HomeState.error),
        onSuccess: (List<Announcement> data) {
          announcements = data;
          if (mounted) {
            setState(() {
              if (data.isEmpty) {
                state = HomeState.empty;
              } else {
                state = HomeState.finish;
              }
            });
          }
        },
      ),
    );
  }

  void setupBusNotify(BuildContext context) {
    if (PreferenceUtil.instance.getBool(Constants.prefBusNotify, false)) {
      Helper.instance.getBusReservations(
        callback: GeneralCallback<BusReservationsData>(
          onSuccess: (BusReservationsData response) async {
            await Utils.setBusNotify(context, response.reservations);
          },
          onFailure: (DioException e) {
            if (e.hasResponse) {
              AnalyticsUtil.instance.logApiEvent(
                'getBusReservations',
                e.response!.statusCode!,
                message: e.message ?? '',
              );
            }
          },
          onError: (GeneralResponse e) => null,
        ),
      );
    }
  }

  Future<void> getUserInfo() async {
    if (PreferenceUtil.instance.getBool(Constants.prefIsOfflineLogin, false)) {
      userInfo = UserInfo.load(Helper.username!);
    } else {
      Helper.instance.getUsersInfo(
        callback: GeneralCallback<UserInfo>(
          onSuccess: (UserInfo data) {
            if (mounted) {
              setState(() {
                userInfo = data;
              });
              if (userInfo != null) {
                AnalyticsUtil.instance.logUserInfo(userInfo!);
                userInfo!.save(Helper.username!);
              }
              _checkData();
              if (PreferenceUtil.instance
                  .getBool(Constants.prefDisplayPicture, true)) {
                _getUserPicture();
              }
            }
          },
          onFailure: (DioException e) {
            if (e.hasResponse) {
              AnalyticsUtil.instance.logApiEvent(
                'getUserInfo',
                e.response!.statusCode!,
                message: e.message ?? '',
              );
            }
          },
          onError: (GeneralResponse e) => null,
        ),
      );
    }
  }

  Future<void> getUserPicture() async {
    try {
      if (userInfo != null && userInfo!.pictureUrl != null) {
        final Uint8List? response = await Helper.instance.getUserPicture();
        if (mounted) {
          setState(() {
            userInfo!.pictureBytes = response;
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
