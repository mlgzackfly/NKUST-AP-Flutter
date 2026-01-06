part of '../home_page.dart';

/// Configuration and version checking logic for HomePage.
mixin HomeConfigMixin on State<HomePage> {
  static const String prefApiKey = 'inkust_api_key';

  bool get busEnable;
  set busEnable(bool value);

  bool get leaveEnable;
  set leaveEnable(bool value);

  Future<void> checkAppData({bool first = false}) async {
    final AppLocalizations app = AppLocalizations.of(context);
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion =
        PreferenceUtil.instance.getString(Constants.prefCurrentVersion, '');
    AnalyticsUtil.instance.setUserProperty(
      Constants.versionCode,
      packageInfo.buildNumber,
    );
    if (currentVersion != packageInfo.buildNumber && first) {
      final Map<String, dynamic>? rawData = await FileAssets.changelogData;
      final String updateNoteContent = (rawData![packageInfo.buildNumber]
          as Map<String, dynamic>)[ApLocalizations.current.locale] as String;
      if (!mounted) return;
      DialogUtils.showUpdateContent(
        context,
        'v${packageInfo.version}\n'
        '$updateNoteContent',
      );
      PreferenceUtil.instance.setString(
        Constants.prefCurrentVersion,
        packageInfo.buildNumber,
      );
    }
    VersionInfo versionInfo;
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(seconds: 10),
        ),
      );
      await remoteConfig.fetchAndActivate();
      final List<String> leaveTimeCode = List<String>.from(
        jsonDecode(remoteConfig.getString(Constants.leavesTimeCode))
            as List<dynamic>,
      );
      final List<String> mobileNkustUserAgent = List<String>.from(
        jsonDecode(
          remoteConfig.getString(Constants.mobileNkustUserAgent),
        ) as List<dynamic>,
      );
      busEnable = remoteConfig.getBool(Constants.busEnable);
      leaveEnable = remoteConfig.getBool(Constants.leaveEnable);
      PreferenceUtil.instance.setBool(Constants.busEnable, busEnable);
      PreferenceUtil.instance.setBool(Constants.leaveEnable, leaveEnable);
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        Helper.selector = CrawlerSelector.fromRawJson(
          remoteConfig.getString(Constants.crawlerSelector),
        );
        Helper.selector!.save();
      }
      final SemesterData semesterData = SemesterData.fromRawJson(
        remoteConfig.getString(Constants.semesterData),
      );
      semesterData.save();
      PreferenceUtil.instance
          .setStringList(Constants.leavesTimeCode, leaveTimeCode);
      PreferenceUtil.instance.setStringList(
        Constants.mobileNkustUserAgent,
        mobileNkustUserAgent,
      );
      MobileNkustHelper.userAgentList = mobileNkustUserAgent;
      versionInfo = VersionInfo(
        code: remoteConfig.getInt(ApConstants.appVersion),
        isForceUpdate: remoteConfig.getBool(ApConstants.isForceUpdate),
        content: remoteConfig.getString(ApConstants.newVersionContent),
      );
      if (first) {
        if (!mounted) return;
        DialogUtils.showNewVersionContent(
          context: context,
          appName: app.appName,
          iOSAppId: '1439751462',
          defaultUrl: 'https://www.facebook.com/NKUST.ITC/',
          githubRepositoryName: 'NKUST-ITC/NKUST-AP-Flutter',
          windowsPath:
              'https://github.com/NKUST-ITC/NKUST-AP-Flutter/releases/download/%s/nkust_ap_windows.zip',
          snapStoreId: 'nkust-ap',
          versionInfo: versionInfo,
        );
      }
    } catch (e) {
      Helper.selector = CrawlerSelector.load();
      busEnable = PreferenceUtil.instance.getBool(Constants.busEnable, true);
      leaveEnable =
          PreferenceUtil.instance.getBool(Constants.leaveEnable, true);
    }
    setState(() {});
  }
}
