/// API 端點集中管理
///
/// 將所有 API URL 集中於此類別，便於維護和環境切換
class ApiEndpoints {
  ApiEndpoints._();

  // ===== 基礎域名 =====
  static const String apiHost = 'nkust.taki.dog';
  static const String apiVersion = 'v3';
  static const String webApHost = 'webap.nkust.edu.tw';
  static const String mobileHost = 'mobile.nkust.edu.tw';
  static const String vmsHost = 'vms.nkust.edu.tw';
  static const String leaveHost = 'leave.nkust.edu.tw';
  static const String oosafHost = 'oosaf.nkust.edu.tw';
  static const String stdSysHost = 'stdsys.nkust.edu.tw';
  static const String busKuasHost = 'bus.kuas.edu.tw';
  static const String acadHost = 'acad.nkust.edu.tw';

  // ===== 基礎 URL =====
  static String get apiBaseUrl => 'https://$apiHost/$apiVersion';
  static String get webApBaseUrl => 'https://$webApHost';
  static String get mobileBaseUrl => 'https://$mobileHost';
  static String get vmsBaseUrl => 'https://$vmsHost';
  static String get leaveBaseUrl => 'https://$leaveHost';
  static String get oosafBaseUrl => 'https://$oosafHost';
  static String get stdSysBaseUrl => 'https://$stdSysHost';
  static String get busKuasBaseUrl => 'http://$busKuasHost';
  static String get acadBaseUrl => 'https://$acadHost';

  // ===== WebAP 端點 =====
  static const String webApLogout = '/nkust/reclear.jsp';
  static const String webApValidateCode = '/nkust/validateCode.jsp';
  static const String webApValidateCodeForUid = '/nkust/validateCode_foruid.jsp';
  static const String webApIndexMain = '/nkust/index_main.html';
  static const String webApLogin = '/nkust/perchk.jsp';
  static const String webApKeepOldPassword = '/nkust/system/sys010_stay.jsp';
  static const String webApFunction = '/nkust/fnc.jsp';
  static const String webApSystemReferer = '/nkust/system/sys001_00.jsp';
  static const String webApGetUid = '/nkust/system/getuid_1.jsp';

  // ===== Mobile NKUST 端點 =====
  static const String mobileHome = '/Home/Index';
  static const String mobileCourse = '/Student/Course';
  static const String mobileScore = '/Student/Grades';
  static const String mobileMidAlerts = '/Student/Grades/MidWarning';
  static const String mobilePhoto = '/Common/GetStudentPhoto';
  static const String mobileCheckExpire = '/Account/CheckExpire';
  static const String mobileLoginByPortal = '/Account/LoginBySkytekPortalNewWindow';

  // ===== VMS 校車端點 =====
  static const String vmsBusTimetablePage = '/Bus/Bus/Timetable';
  static const String vmsBusTimetableApi = '/Bus/Bus/GetTimetableGrid';
  static const String vmsBusBook = '/Bus/Bus/CreateReserve';
  static const String vmsBusUnbook = '/Bus/Bus/CancelReserve';
  static const String vmsBusReservePage = '/Bus/Bus/Reserve';
  static const String vmsBusReserveApi = '/Bus/Bus/GetReserveGrid';
  static const String vmsBusViolationPage = '/Bus/Bus/Illegal';
  static const String vmsBusViolationApi = '/Bus/Bus/GetIllegalGrid';

  // ===== Leave 請假端點 =====
  static const String leaveLogon = '/LogOn.aspx';
  static const String leaveMasterIndex = '/masterindex.aspx';
  static const String leaveQuery = '/AK002MainM.aspx';
  static const String leaveSubmit = '/CK001MainM.aspx';
  static const String leaveSkyDir = '/SkyDir.aspx';

  // ===== OOSAF 端點 =====
  static const String oosafLoginByPortal = '/Account/LoginBySkytekPortalNewWindow';

  // ===== StdSys 學生系統端點 =====
  static const String stdSysLoginByPortal = '/Student/Account/LoginBySkytekPortalNewWindow';
  static const String stdSysDocStatus = '/student/Doc/Status';
  static const String stdSysDocDownload = '/student/Doc/Status/Download';

  // ===== Bus KUAS 舊公車系統端點 =====
  static const String busKuasScripts = '/API/Scripts/a1';
  static const String busKuasLogin = '/API/Users/login';
  static const String busKuasFrequencies = '/API/Frequencys/getAll';
  static const String busKuasReservesAdd = '/API/Reserves/add';
  static const String busKuasReservesRemove = '/API/Reserves/remove';
  static const String busKuasReservesOwn = '/API/Reserves/getOwn';
  static const String busKuasIllegalsOwn = '/API/Illegals/getOwn';

  // ===== Acad 學術系統端點 =====
  static const String acadNotifications = '/app/index.php?Action=mobilercglist';

  // ===== 完整 URL 取得方法 =====
  static String getWebApUrl(String endpoint) => '$webApBaseUrl$endpoint';
  static String getMobileUrl(String endpoint) => '$mobileBaseUrl$endpoint';
  static String getVmsUrl(String endpoint) => '$vmsBaseUrl$endpoint';
  static String getLeaveUrl(String endpoint) => '$leaveBaseUrl$endpoint';
  static String getOosafUrl(String endpoint) => '$oosafBaseUrl$endpoint';
  static String getStdSysUrl(String endpoint) => '$stdSysBaseUrl$endpoint';
  static String getBusKuasUrl(String endpoint) => '$busKuasBaseUrl$endpoint';
  static String getAcadUrl(String endpoint) => '$acadBaseUrl$endpoint';

  // ===== 動態端點生成 =====
  static String getWebApQueryUrl(String queryQid) =>
      '$webApBaseUrl/nkust/${queryQid.substring(0, 2)}_pro/$queryQid.jsp';
}
