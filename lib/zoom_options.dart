class ZoomOptions {
  String? domain;
  String? appKey;
  String? appSecret;
  String? jwtToken;
  final String langCode;

  ZoomOptions(
      {this.domain,
      this.appKey,
      this.appSecret,
      this.jwtToken,
      this.langCode = "vi"});
}

class ZoomMeetingOptions {
  String? userId;
  String? displayName;
  String? meetingId;
  String? meetingPassword;
  String? zoomToken;
  String? zoomAccessToken;
  String? disableDialIn;
  String? disableDrive;
  String? disableInvite;
  String? disableShare;
  String? noDisconnectAudio;
  String? noAudio;
  String langCode;

  ZoomMeetingOptions(
      {this.userId,
      this.displayName,
      this.meetingId,
      this.meetingPassword,
      this.zoomToken,
      this.zoomAccessToken,
      this.disableDialIn,
      this.disableDrive,
      this.disableInvite,
      this.disableShare,
      this.noDisconnectAudio,
      this.noAudio,
      this.langCode = "vi"});
}

class ZoomMeetingOptionAll {
  //meeting params
  final String?
      displayName; // JoinMeetingParams , StartMeetingParamsWithoutLogin
  final String? meetingNo; // JoinMeetingParams , StartMeetingParams4NormalUser
  final String? password; // JoinMeetingParams
  final String? vanityID; // JoinMeetingParams , StartMeetingParams4NormalUser

  final String?
      userId; // JoinMeetingParam4WithoutLogin , StartMeetingParamsWithoutLogin
  final String?
      userType; // JoinMeetingParam4WithoutLogin , StartMeetingParamsWithoutLogin
  final String?
      zoomAccessToken; // JoinMeetingParam4WithoutLogin , StartMeetingParamsWithoutLogin

  //meeting options
  final String? customMeetingId;
  late int inviteOptions = 0;
  late int meetingViewsOptions = 0;
  final bool noBottomToolbar;
  final bool noChatMsgToast;
  final bool noDialInViaPhone;
  final bool noDialOutToPhone;
  final bool noDisconnectAudio;
  final bool noDrivingMode;
  final bool noInvite;
  final bool noMeetingEndMessage;
  final bool noMeetingErrorMessage;
  final bool noShare;
  final bool noTitlebar;
  final bool noUnmuteConfirmDialog;
  final bool noVideo;
  final bool noWebinarRegisterDialog;
  final String? participantId;
  final bool noAudio;
  final String? webinarToken; // JoinMeetingParams

// meeting view option
  final bool noButtonAudio;
  final bool noButtonLeave;
  final bool noButtonMore;
  final bool noButtonParticipants;
  final bool noButtonShare;
  final bool noButtonSwitchAudio;
  final bool noButtonSwitchCamera;
  final bool noButtonVideo;
  final bool noTextMeetingId;
  final bool noTextPassword;

  //invite option
  final bool inviteCopyUrl;
  final bool inviteDisableAll;
  final bool inviteEnableAll;
  final bool inviteViaEmail;
  final bool inviteViaSms;

  final String langCode;

  ZoomMeetingOptionAll(
      {
      //meeting params
      this.displayName,
      this.meetingNo,
      this.password,
      this.vanityID,
      this.userId,
      this.userType,
      this.zoomAccessToken,
      // meeting options
      this.customMeetingId,
      this.noBottomToolbar = false,
      this.noChatMsgToast = false,
      this.noDialInViaPhone = true,
      this.noDialOutToPhone = true,
      this.noDisconnectAudio = true,
      this.noDrivingMode = true,
      this.noInvite = true,
      this.noMeetingEndMessage = false,
      this.noMeetingErrorMessage = false,
      this.noShare = true,
      this.noTitlebar = false,
      this.noUnmuteConfirmDialog = true,
      this.noVideo = false,
      this.noWebinarRegisterDialog = true,
      this.participantId,
      this.noAudio = false, //startMeetingOptions , joinMeetingOptions
      this.webinarToken, //joinMeetingOptions

      //meeting view option
      this.noButtonAudio = false,
      this.noButtonLeave = false,
      this.noButtonMore = false,
      this.noButtonParticipants = true,
      this.noButtonShare = true,
      this.noButtonSwitchAudio = false,
      this.noButtonSwitchCamera = false,
      this.noButtonVideo = false,
      this.noTextMeetingId = true,
      this.noTextPassword = true,
      //invite option
      this.inviteCopyUrl = false,
      this.inviteDisableAll = true,
      this.inviteEnableAll = false,
      this.inviteViaEmail = false,
      this.inviteViaSms = false,
      this.langCode = 'vi'}) {
    this.meetingViewsOptions = (noButtonAudio ? 2 : 0) +
        (noButtonLeave ? 128 : 0) +
        (noButtonMore ? 16 : 0) +
        (noButtonParticipants ? 8 : 0) +
        (noButtonShare ? 4 : 0) +
        (noButtonSwitchAudio ? 512 : 0) +
        (noButtonSwitchCamera ? 256 : 0) +
        (noButtonVideo ? 1 : 0) +
        (noTextMeetingId ? 32 : 0) +
        (noTextPassword ? 64 : 0);

    this.inviteOptions = inviteDisableAll
        ? 0
        : inviteEnableAll
            ? 255
            : (inviteCopyUrl ? 4 : 0) +
                (inviteViaEmail ? 2 : 0) +
                (inviteViaSms ? 1 : 0);
  }

  Map<String, String?> toOptionMap() => {
        'displayName': displayName.toString(),
        'meetingNo': meetingNo.toString(),
        'password': password.toString(),
        'vanityID': vanityID.toString(),
        'userId': userId.toString(),
        'userType': userType.toString(),
        'zoomAccessToken': zoomAccessToken.toString(),
        'customMeetingId': customMeetingId.toString(),
        'inviteOptions': inviteOptions.toString(),
        'meetingViewsOptions': meetingViewsOptions.toString(),
        'noBottomToolbar': noBottomToolbar.toString(),
        'noChatMsgToast': noChatMsgToast.toString(),
        'noDialInViaPhone': noDialInViaPhone.toString(),
        'noDialOutToPhone': noDialOutToPhone.toString(),
        'noDisconnectAudio': noDisconnectAudio.toString(),
        'noDrivingMode': noDrivingMode.toString(),
        'noInvite': noInvite.toString(),
        'noMeetingEndMessage': noMeetingEndMessage.toString(),
        'noMeetingErrorMessage': noMeetingErrorMessage.toString(),
        'noShare': noShare.toString(),
        'noTitlebar': noTitlebar.toString(),
        'noUnmuteConfirmDialog': noUnmuteConfirmDialog.toString(),
        'noVideo': noVideo.toString(),
        'noWebinarRegisterDialog': noWebinarRegisterDialog.toString(),
        'participantId': participantId.toString(),
        'noAudio': noAudio.toString(),
        'webinarToken ': webinarToken.toString(),
        'noButtonAudio': noButtonAudio.toString(),
        'noButtonLeave': noButtonLeave.toString(),
        'noButtonMore': noButtonMore.toString(),
        'noButtonParticipants': noButtonParticipants.toString(),
        'noButtonShare': noButtonShare.toString(),
        'noButtonSwitchAudio': noButtonSwitchAudio.toString(),
        'noButtonSwitchCamera': noButtonSwitchCamera.toString(),
        'noButtonVideo': noButtonVideo.toString(),
        'noTextMeetingId': noTextMeetingId.toString(),
        'noTextPassword': noTextPassword.toString(),
        'inviteCopyUrl': inviteCopyUrl.toString(),
        'inviteDisableAll': inviteDisableAll.toString(),
        'inviteEnableAll': inviteEnableAll.toString(),
        'inviteViaEmail': inviteViaEmail.toString(),
        'inviteViaSms': inviteViaSms.toString(),
        'langCode': langCode.toString(),
      };
}

class ZoomInMeetingConfig {
  final String? setMeetingTopic;
  final String? allowParticipantsToRename;
  final String? allowParticipantsToUnmuteSelf;
  ZoomInMeetingConfig(
      {this.setMeetingTopic,
      this.allowParticipantsToRename,
      this.allowParticipantsToUnmuteSelf});

  Map<String, String> toOptionMap() => {
        'setMeetingTopic': setMeetingTopic ?? '-1',
        'allowParticipantsToRename': allowParticipantsToRename ?? '-1',
        'allowParticipantsToUnmuteSelf': allowParticipantsToUnmuteSelf ?? '-1',
      };
}

enum ZoomMeetingStatus {
  MEETING_STATUS_CONNECTING,
  MEETING_STATUS_DISCONNECTING,
  MEETING_STATUS_FAILED,
  MEETING_STATUS_IDLE,
  MEETING_STATUS_IN_WAITING_ROOM,
  MEETING_STATUS_INMEETING,
  MEETING_STATUS_RECONNECTING,
  MEETING_STATUS_UNKNOWN,
  MEETING_STATUS_WAITINGFORHOST,
  MEETING_STATUS_WEBINAR_DEPROMOTE,
  MEETING_STATUS_WEBINAR_PROMOTE,
  //ios only below
  MEETING_STATUS_ENDED,
  MEETING_STATUS_LOCKED,
  MEETING_STATUS_UNLOCKED,
  MEETING_STATUS_JOIN_BO,
  MEETING_STATUS_LEAVE_BO,
  MEETING_STATUS_WAIT_EX_SESION_KEY,
}

enum ZoomApiError {
  ZOOM_API_ERROR_EMAIL_LOGIN_IS_DISABLED,
  ZOOM_API_ERROR_FAILED_CLIENT_INCOMPATIBLE,
  ZOOM_API_ERROR_FAILED_NULLPOINTER,
  ZOOM_API_ERROR_FAILED_WRONGPARAMETERS,
  ZOOM_API_ERROR_SUCCESS,
  ZOOM_API_INVALID_STATUS
}

enum ZoomMeetingError {
  MEETING_ERROR_CLIENT_INCOMPATIBLE,
  MEETING_ERROR_DISALLOW_HOST_RESGISTER_WEBINAR,
  MEETING_ERROR_DISALLOW_PANELIST_REGISTER_WEBINAR,
  MEETING_ERROR_EXIT_WHEN_WAITING_HOST_START,
  MEETING_ERROR_HOST_DENY_EMAIL_REGISTER_WEBINAR,
  MEETING_ERROR_INCORRECT_MEETING_NUMBER,
  MEETING_ERROR_INVALID_ARGUMENTS,
  MEETING_ERROR_INVALID_STATUS,
  MEETING_ERROR_LOCKED,
  MEETING_ERROR_MEETING_NOT_EXIST,
  MEETING_ERROR_MEETING_OVER,
  MEETING_ERROR_MMR_ERROR,
  MEETING_ERROR_NETWORK_ERROR,
  MEETING_ERROR_NETWORK_UNAVAILABLE,
  MEETING_ERROR_NO_MMR,
  MEETING_ERROR_REGISTER_WEBINAR_FULL,
  MEETING_ERROR_REMOVED_BY_HOST,
  MEETING_ERROR_RESTRICTED,
  MEETING_ERROR_RESTRICTED_JBH,
  MEETING_ERROR_SESSION_ERROR,
  MEETING_ERROR_SUCCESS,
  MEETING_ERROR_TIMEOUT,
  MEETING_ERROR_UNKNOWN,
  MEETING_ERROR_USER_FULL,
  MEETING_ERROR_WEB_SERVICE_FAILED,
  MEETING_ERROR_WEBINAR_ENFORCE_LOGIN,
  MEETING_ERROR_HOST_NOT_LOGIN,
  MEETING_ERROR_SDK_NOT_INIT,
}
