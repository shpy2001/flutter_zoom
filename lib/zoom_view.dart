import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_zoom_plugin/zoom_options.dart';

typedef void ZoomViewCreatedCallback(ZoomViewController controller);

extension StringExtension on String {
  T toEnum<T>(List<T> list, T defaultEnum) =>
      list.firstWhere((d) => d.toString().split('.')[1] == this,
          orElse: () => defaultEnum);
}

class ZoomView extends StatefulWidget {
  const ZoomView({
    Key? key,
    this.zoomOptions,
    this.meetingOptions,
    this.onViewCreated,
  }) : super(key: key);

  final ZoomViewCreatedCallback? onViewCreated;
  final ZoomOptions? zoomOptions;
  final ZoomMeetingOptions? meetingOptions;

  @override
  State<StatefulWidget> createState() => _ZoomViewState();
}

class _ZoomViewState extends State<ZoomView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'flutter_zoom_plugin',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'flutter_zoom_plugin',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the flutter_zoom_plugin plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onViewCreated == null) {
      return;
    }

    var controller = new ZoomViewController._(id);
    widget.onViewCreated!(controller);
  }
}

class ZoomViewController {
  ZoomViewController._(int id)
      : _methodChannel =
            new MethodChannel('com.decodedhealth/flutter_zoom_plugin'),
        _zoomStatusEventChannel =
            new EventChannel("com.decodedhealth/zoom_event_stream");

  final MethodChannel _methodChannel;
  final EventChannel _zoomStatusEventChannel;

  Future<ZoomApiError> initZoom(ZoomOptions options) async {
    var optionMap = new Map<String, String?>();
    optionMap.putIfAbsent("sdkToken", () => options.jwtToken);
    optionMap.putIfAbsent("appKey", () => options.appKey);
    optionMap.putIfAbsent("appSecret", () => options.appSecret);
    optionMap.putIfAbsent("domain", () => options.domain);
    optionMap.putIfAbsent("langCode", () => options.langCode);

    var ret = await _methodChannel.invokeMethod('init', optionMap);
    return zoomApiErrorFromInt[ret[0]] ?? ZoomApiError.ZOOM_API_INVALID_STATUS;
  }

  Future<ZoomAuthenticationError> loginWithEmail(String email, String password,
      {bool shouldLogout = true}) async {
    if (shouldLogout) await logout();

    var optionMap = new Map<String, String?>();
    optionMap.putIfAbsent("email", () => email);
    optionMap.putIfAbsent("password", () => password);
    var ret = await _methodChannel.invokeMethod('login_with_email', optionMap);
    return zoomAuthenticationErrorFromInt[ret] ??
        ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_OTHER_ISSUE;
  }

  Future<List?> loginWithSso(String sso, {bool shouldLogout = true}) async {
    if (shouldLogout) await logout();
    var optionMap = new Map<String, String?>();
    optionMap.putIfAbsent("token", () => sso);
    return _methodChannel.invokeMethod('login_with_sso', optionMap);
  }

  Future<ZoomAccountInfo> getLoggedAccountInfo() async {
    var retList = await _methodChannel.invokeMethod('get_logged_account_info');
    return ZoomAccountInfo(email: retList![0], name: retList![1]);
  }

  Future<bool?> logout() async {
    return _methodChannel.invokeMethod('logout');
  }

  Future<ZoomMeetingError> startInstantMeeting(
      ZoomMeetingOptionAll options) async {
    var ret = await _methodChannel.invokeMethod(
        'start_instant_meeting', options.toOptionMap());
    print('SFLINK SDK FLUTTER: startInstantMeeting $ret');
    return zoomMeetingErrorFromInt[ret] ??
        ZoomMeetingError.MEETING_ERROR_UNKNOWN;
  }

  Future<bool?> startMeeting(ZoomMeetingOptions options) async {
    var optionMap = new Map<String, String?>();
    optionMap.putIfAbsent("userId", () => options.userId);
    optionMap.putIfAbsent("displayName", () => options.displayName);
    optionMap.putIfAbsent("meetingId", () => options.meetingId);
    optionMap.putIfAbsent("meetingPassword", () => options.meetingPassword);
    optionMap.putIfAbsent("zoomToken", () => options.zoomToken);
    optionMap.putIfAbsent("zoomAccessToken", () => options.zoomAccessToken);
    optionMap.putIfAbsent("disableDialIn", () => options.disableDialIn);
    optionMap.putIfAbsent("disableDrive", () => options.disableDrive);
    optionMap.putIfAbsent("disableInvite", () => options.disableInvite);
    optionMap.putIfAbsent("disableShare", () => options.disableShare);
    optionMap.putIfAbsent("noDisconnectAudio", () => options.noDisconnectAudio);
    optionMap.putIfAbsent("noAudio", () => options.noAudio);

    return _methodChannel.invokeMethod('start', optionMap);
  }

  Future<bool?> joinMeeting(ZoomMeetingOptions options) async {
    var optionMap = new Map<String, String?>();
    optionMap.putIfAbsent("userId", () => options.userId);
    optionMap.putIfAbsent("meetingId", () => options.meetingId);
    optionMap.putIfAbsent("meetingPassword", () => options.meetingPassword);
    optionMap.putIfAbsent("disableDialIn", () => options.disableDialIn);
    optionMap.putIfAbsent("disableDrive", () => options.disableDrive);
    optionMap.putIfAbsent("disableInvite", () => options.disableInvite);
    optionMap.putIfAbsent("disableShare", () => options.disableShare);
    optionMap.putIfAbsent("noDisconnectAudio", () => options.noDisconnectAudio);
    optionMap.putIfAbsent("noAudio", () => options.noAudio);
    optionMap.putIfAbsent("langCode", () => options.langCode);

    return _methodChannel.invokeMethod('join', optionMap);
  }

  Future<ZoomMeetingStatus> meetingStatus(String meetingId) async {
    var optionMap = new Map<String, String>();
    optionMap.putIfAbsent("meetingId", () => meetingId);

    return ((_methodChannel.invokeMethod('meeting_status', optionMap)
            as List)[0] as String)
        .toEnum(
            ZoomMeetingStatus.values, ZoomMeetingStatus.MEETING_STATUS_UNKNOWN);
  }

  Future<List?> getMeetingPassword() async {
    return _methodChannel.invokeMethod('get_meeting_password');
  }

  Future<List?> inMeeting() async {
    return _methodChannel.invokeMethod('in_meeting');
  }

  void inMeetingConfig(ZoomInMeetingConfig options) {
    _methodChannel.invokeMethod('in_meeting_config', options.toOptionMap());
  }

  Stream<dynamic> get zoomStatusEvents {
    return _zoomStatusEventChannel.receiveBroadcastStream();
  }

  static Map<int, ZoomApiError> zoomApiErrorFromInt = {
    9: ZoomApiError.ZOOM_API_ERROR_EMAIL_LOGIN_IS_DISABLED,
    8: ZoomApiError.ZOOM_API_ERROR_FAILED_CLIENT_INCOMPATIBLE,
    1: ZoomApiError.ZOOM_API_ERROR_FAILED_NULLPOINTER,
    6: ZoomApiError.ZOOM_API_ERROR_FAILED_WRONGPARAMETERS,
    0: ZoomApiError.ZOOM_API_ERROR_SUCCESS,
    101: ZoomApiError.ZOOM_API_INVALID_STATUS
  };

  static Map<int, ZoomAuthenticationError> zoomAuthenticationErrorFromInt = {
    1: ZoomAuthenticationError.ZOOM_AUTH_EMAIL_LOGIN_DISABLE,
    10: ZoomAuthenticationError.ZOOM_AUTH_ERROR_LOGINTOKENINVALID,
    0: ZoomAuthenticationError.ZOOM_AUTH_ERROR_SUCCESS,
    2: ZoomAuthenticationError.ZOOM_AUTH_ERROR_USER_NOT_EXIST,
    4: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_ACCOUNTLOCKED,
    100: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_OTHER_ISSUE,
    3: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_PASSWORD,
    9: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_PHONENUMBERFORMATINVALID,
    5: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_SDKNEEDUPDATE,
    7: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_SMSCODEERROR,
    8: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_SMSCODEEXPIRED,
    6: ZoomAuthenticationError.ZOOM_AUTH_ERROR_WRONG_TOOMANY_FAILED_ATTEMPTS,
  };

  static Map<int, ZoomMeetingError> zoomMeetingErrorFromInt = {
    4: ZoomMeetingError.MEETING_ERROR_CLIENT_INCOMPATIBLE,
    17: ZoomMeetingError.MEETING_ERROR_DISALLOW_HOST_RESGISTER_WEBINAR,
    18: ZoomMeetingError.MEETING_ERROR_DISALLOW_PANELIST_REGISTER_WEBINAR,
    21: ZoomMeetingError.MEETING_ERROR_EXIT_WHEN_WAITING_HOST_START,
    19: ZoomMeetingError.MEETING_ERROR_HOST_DENY_EMAIL_REGISTER_WEBINAR,
    1: ZoomMeetingError.MEETING_ERROR_INCORRECT_MEETING_NUMBER,
    99: ZoomMeetingError.MEETING_ERROR_INVALID_ARGUMENTS,
    101: ZoomMeetingError.MEETING_ERROR_INVALID_STATUS,
    12: ZoomMeetingError.MEETING_ERROR_LOCKED,
    9: ZoomMeetingError.MEETING_ERROR_MEETING_NOT_EXIST,
    8: ZoomMeetingError.MEETING_ERROR_MEETING_OVER,
    6: ZoomMeetingError.MEETING_ERROR_MMR_ERROR,
    5: ZoomMeetingError.MEETING_ERROR_NETWORK_ERROR,
    3: ZoomMeetingError.MEETING_ERROR_NETWORK_UNAVAILABLE,
    11: ZoomMeetingError.MEETING_ERROR_NO_MMR,
    16: ZoomMeetingError.MEETING_ERROR_REGISTER_WEBINAR_FULL,
    22: ZoomMeetingError.MEETING_ERROR_REMOVED_BY_HOST,
    13: ZoomMeetingError.MEETING_ERROR_RESTRICTED,
    14: ZoomMeetingError.MEETING_ERROR_RESTRICTED_JBH,
    7: ZoomMeetingError.MEETING_ERROR_SESSION_ERROR,
    0: ZoomMeetingError.MEETING_ERROR_SUCCESS,
    2: ZoomMeetingError.MEETING_ERROR_TIMEOUT,
    100: ZoomMeetingError.MEETING_ERROR_UNKNOWN,
    10: ZoomMeetingError.MEETING_ERROR_USER_FULL,
    15: ZoomMeetingError.MEETING_ERROR_WEB_SERVICE_FAILED,
    20: ZoomMeetingError.MEETING_ERROR_WEBINAR_ENFORCE_LOGIN,
    999: ZoomMeetingError.MEETING_ERROR_HOST_NOT_LOGIN,
    998: ZoomMeetingError.MEETING_ERROR_SDK_NOT_INIT
  };
}
