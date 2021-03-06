package com.decodedhealth.flutter_zoom_plugin;

import android.content.Context;
import android.view.View;
import android.widget.TextView;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Locale;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import us.zoom.sdk.JoinMeetingOptions;
import us.zoom.sdk.JoinMeetingParams;
import us.zoom.sdk.StartMeetingParamsWithoutLogin;
import us.zoom.sdk.StartMeetingOptions;
import us.zoom.sdk.MeetingService;
import us.zoom.sdk.AccountService;
import us.zoom.sdk.MeetingStatus;
import us.zoom.sdk.ZoomError;
import us.zoom.sdk.ZoomSDK;
import us.zoom.sdk.ZoomSDKAuthenticationListener;
import us.zoom.sdk.ZoomSDKInitParams;
import us.zoom.sdk.ZoomSDKInitializeListener;

import us.zoom.sdk.MeetingViewsOptions;
import us.zoom.sdk.MeetingSettingsHelper;
import us.zoom.sdk.InMeetingService;
import us.zoom.sdk.InMeetingVideoController;
import us.zoom.sdk.InMeetingAudioController;
import us.zoom.sdk.InMeetingUserList;
import us.zoom.sdk.InMeetingUserInfo;


public class ZoomView  implements PlatformView,
        MethodChannel.MethodCallHandler,
        ZoomSDKAuthenticationListener {
    private final TextView textView;
    private final MethodChannel methodChannel;
    private final Context context;
    private final EventChannel meetingStatusChannel;
    private final EventChannel authStatusChannel;

    ZoomView(Context context, BinaryMessenger messenger, int id) {
        textView = new TextView(context);
        this.context = context;

        methodChannel = new MethodChannel(messenger, "com.decodedhealth/flutter_zoom_plugin");
        methodChannel.setMethodCallHandler(this);

        meetingStatusChannel = new EventChannel(messenger, "com.decodedhealth/zoom_event_stream");
        authStatusChannel = new EventChannel(messenger, "com.decodedhealth/zoom_auth_event_stream");
    }

    @Override
    public View getView() {
        return textView;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "init":
                init(methodCall, result);
                break;
            case "join":
                joinMeeting(methodCall, result);
                break;
            case "start":
                startMeeting(methodCall, result);
                break;
            case "meeting_status":
                meetingStatus(result);
                break;
            case "in_meeting":
                inMeeting(methodCall, result);
                break;
            case "in_meeting_config":
                inMeetingConfig(methodCall);
                break;
            case "login_with_email":
                loginWithEmail(methodCall,result);
                break;
            case "login_with_sso":
                loginWithSso(methodCall,result);
                break;
            case "start_instant_meeting":
                startInstantMeeting(methodCall,result);
                break;
            case "logout":
                logout(result);
                break;
            case "get_meeting_password":
                getMeetingPassword(result);
                break;
            case "get_logged_account_info":
                getLoggedAccountInfo(result);
                break;
            case "releaseListener":
            releaseListener();
                break;
            default:
                result.notImplemented();
        }

    }

    private void init(final MethodCall methodCall, final MethodChannel.Result result) {

        Map<String, String> options = methodCall.arguments();

        ZoomSDK zoomSDK = ZoomSDK.getInstance();

        if(zoomSDK.isInitialized()) {
            List<Integer> response = Arrays.asList(0, 0);
            System.out.println("ZOOM SDK FLUTTER : had isInitialized !!!!!!!!!!!!!!");
            result.success(response);
            return;
        }


        ZoomSDKInitParams initParams = new ZoomSDKInitParams();
        initParams.jwtToken = options.get("sdkToken");
        initParams.appKey = options.get("appKey");
        initParams.appSecret = options.get("appSecret");
        initParams.domain = options.get("domain");

        final String langCode = options.get("langCode");
        zoomSDK.initialize(
                context,
                new ZoomSDKInitializeListener() {
                    @Override
                    public void onZoomAuthIdentityExpired() {
                        System.out.println("ZOOM SDK FLUTTER : expired ");
                    }

                    @Override
                    public void onZoomSDKInitializeResult(int errorCode, int internalErrorCode) {
                        System.out.println("ZOOM SDK FLUTTER : ini finished");

                        List<Integer> response = Arrays.asList(errorCode, internalErrorCode);

                        if (errorCode != ZoomError.ZOOM_ERROR_SUCCESS) {
                            System.out.println("Failed to initialize Zoom SDK --- ErrCode:" + errorCode + "-- inErr: " + internalErrorCode);
                            result.success(response);
                            return;
                        }

                        ZoomSDK zoomSDK = ZoomSDK.getInstance();
                        zoomSDK.setSdkLocale(context,new Locale(langCode));

                        MeetingService meetingService = zoomSDK.getMeetingService();
                        meetingStatusChannel.setStreamHandler(new StatusStreamHandler(meetingService));
                        result.success(response);
                    }
                },
                initParams);
    }

    private void releaseListener(){

    }

    // private void joinMeeting(MethodCall methodCall, MethodChannel.Result result) {

    //     Map<String, String> options = methodCall.arguments();

    //     ZoomSDK zoomSDK = ZoomSDK.getInstance();

    //     if(!zoomSDK.isInitialized()) {
    //         System.out.println("Not initialized!!!!!!");
    //         result.success(false);
    //         return;
    //     }

    //     zoomSDK.setSdkLocale(context,new Locale(options.get("langCode")));

    //     final MeetingService meetingService = zoomSDK.getMeetingService();

    //     JoinMeetingOptions opts = new JoinMeetingOptions();
    //     opts.no_invite = parseBoolean(options, "disableInvite", false);
    //     opts.no_share = parseBoolean(options, "disableShare", false);
    //     opts.no_driving_mode = parseBoolean(options, "disableDrive", false);
    //     opts.no_dial_in_via_phone = parseBoolean(options, "disableDialIn", false);
    //     opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false);
    //     opts.no_audio = parseBoolean(options, "noAudio", false);

    //     opts.no_video = false;
	// 	opts.meeting_views_options = MeetingViewsOptions.NO_TEXT_PASSWORD + MeetingViewsOptions.NO_TEXT_MEETING_ID + MeetingViewsOptions.NO_BUTTON_PARTICIPANTS + MeetingViewsOptions.NO_BUTTON_SHARE;
        
    //     MeetingSettingsHelper msHelper = zoomSDK.getMeetingSettingsHelper();
    //     msHelper.setAutoConnectVoIPWhenJoinMeeting(true);
    //     msHelper.setMuteMyMicrophoneWhenJoinMeeting(true);
    //     msHelper.setTurnOffMyVideoWhenJoinMeeting(false);
    //     msHelper.disableShowVideoPreviewWhenJoinMeeting(true);

    //     JoinMeetingParams params = new JoinMeetingParams();

    //     params.displayName = options.get("userId");
    //     params.meetingNo = options.get("meetingId");
    //     params.password = options.get("meetingPassword");

    //     meetingService.joinMeetingWithParams(context, params, opts);
    //     result.success(true);
    // }

    private void inMeeting(MethodCall methodCall, MethodChannel.Result result){
        InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
        InMeetingAudioController mInMeetingAudioController = mInMeetingService.getInMeetingAudioController();
        mInMeetingAudioController.connectAudioWithVoIP();

        InMeetingVideoController mInMeetingVideoController = mInMeetingService.getInMeetingVideoController();
        List<Long> userList = mInMeetingService.getInMeetingUserList();
        // int count = userList.getUserCount();
        if(userList != null){
            for(int i=0; i<userList.size(); i++) {
                InMeetingUserInfo userInfo = mInMeetingService.getUserInfoById(userList.get(i));
                if(userInfo.getInMeetingUserRole() == InMeetingUserInfo.InMeetingUserRole.USERROLE_HOST) {
                mInMeetingVideoController.pinVideo(true,userInfo.getUserId());
                }
            }
        }
    }

    private void inMeetingConfig(MethodCall methodCall){
        // InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
        Map<String, String> options = methodCall.arguments();
        if(!options.get("setMeetingTopic").equals("-1")){
            System.out.println("setMeetingTopic " + options.get("setMeetingTopic"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            System.out.println(mInMeetingService.setMeetingTopic(options.get("setMeetingTopic")));
        }

        if(!options.get("changeName").equals("-1")){
            System.out.println("changeName " + options.get("changeName"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            System.out.println(mInMeetingService.changeName(options.get("changeName"), mInMeetingService.getMyUserID()));
        }
       
        if(!options.get("allowParticipantsToRename").equals("-1")){
            System.out.println("allowParticipantsToRename " + options.get("allowParticipantsToRename"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            System.out.println(mInMeetingService.allowParticipantsToRename(Boolean.parseBoolean(options.get("allowParticipantsToRename"))));
        }
        if(!options.get("allowParticipantsToUnmuteSelf").equals("-1")){
            System.out.println("allowParticipantsToUnmuteSelf " + options.get("allowParticipantsToUnmuteSelf"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            System.out.println(mInMeetingService.allowParticipantsToUnmuteSelf(Boolean.parseBoolean(options.get("allowParticipantsToUnmuteSelf"))));
        }
        if(!options.get("muteMyAudio").equals("-1")){
            System.out.println("muteMyAudio " + options.get("muteMyAudio"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            InMeetingAudioController mInMeetingAudioController = mInMeetingService.getInMeetingAudioController();
            System.out.println(mInMeetingAudioController.muteMyAudio(Boolean.parseBoolean(options.get("muteMyAudio"))));
        }
        if(!options.get("muteMyVideo").equals("-1")){
            System.out.println("muteMyVideo0 " + options.get("muteMyVideo"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            InMeetingVideoController mInMeetingVideoController = mInMeetingService.getInMeetingVideoController();
            System.out.println(mInMeetingVideoController.muteMyVideo(Boolean.parseBoolean(options.get("muteMyVideo"))));
        }

        
        if(Boolean.parseBoolean(options.get("shouldPinHost"))){
            System.out.println("shouldPinHost " + options.get("shouldPinHost"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            List<Long> userList = mInMeetingService.getInMeetingUserList();
            if(userList != null){
                for(int i=0; i<userList.size(); i++) {
                    if(mInMeetingService.isHostUser(userList.get(i))){
                        InMeetingVideoController mInMeetingVideoController = mInMeetingService.getInMeetingVideoController();
                        mInMeetingVideoController.pinVideo(true,userList.get(i));
                        break;
                    }
                }
            }
        }
        if(Boolean.parseBoolean(options.get("shouldSpotlightHost"))){
            System.out.println("shouldSpotlightHost " + options.get("shouldSpotlightHost"));
            InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
            List<Long> userList = mInMeetingService.getInMeetingUserList();
            InMeetingVideoController mInMeetingVideoController = mInMeetingService.getInMeetingVideoController();
            mInMeetingVideoController.spotLightVideo(true,mInMeetingService.getMyUserID());
        }
    }
    
    private void getMeetingPassword(MethodChannel.Result result){
        InMeetingService mInMeetingService = ZoomSDK.getInstance().getInMeetingService();
        result.success(Arrays.asList(String.valueOf(mInMeetingService.getCurrentMeetingNumber()),mInMeetingService.getMeetingPassword()));
    }

    private void getLoggedAccountInfo(MethodChannel.Result result){
        AccountService mAccountService = ZoomSDK.getInstance().getAccountService();
        if (mAccountService == null) {
            result.success(Arrays.asList("",""));
            return;
        }
        result.success(Arrays.asList(String.valueOf(mAccountService.getAccountEmail()),mAccountService.getAccountName()));
    }

    private void startMeeting(MethodCall methodCall, MethodChannel.Result result) {

        Map<String, String> options = methodCall.arguments();

        ZoomSDK zoomSDK = ZoomSDK.getInstance();

        if(!zoomSDK.isInitialized()) {
            System.out.println("Not initialized!!!!!!");
            result.success(false);
            return;
        }

        final MeetingService meetingService = zoomSDK.getMeetingService();

        StartMeetingOptions opts = new StartMeetingOptions();
        opts.no_invite = parseBoolean(options, "disableInvite", false);
        opts.no_share = parseBoolean(options, "disableShare", false);
        opts.no_driving_mode = parseBoolean(options, "disableDrive", false);
        opts.no_dial_in_via_phone = parseBoolean(options, "disableDialIn", false);
        opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false);
        opts.no_audio = parseBoolean(options, "noAudio", false);

        StartMeetingParamsWithoutLogin params = new StartMeetingParamsWithoutLogin();

		params.userId = options.get("userId");
        params.displayName = options.get("displayName");
        params.meetingNo = options.get("meetingId");
		params.userType = MeetingService.USER_TYPE_API_USER;
		// params.zoomToken = options.get("zoomToken");
		params.zoomAccessToken = options.get("zoomAccessToken");
		
        meetingService.startMeetingWithParams(context, params, opts);

        result.success(true);
    }

    private void startInstantMeeting(MethodCall methodCall, MethodChannel.Result result) {
        Map<String, String> options = methodCall.arguments();
        ZoomSDK zoomSDK = ZoomSDK.getInstance();

        if(!zoomSDK.isInitialized()) {
            System.out.println("Not initialized!!!!!!");
            result.success(998);
            return;
        }

        // if(!zoomSDK.isLoggedIn()) {
        //     result.success(999);
        //     return;
        // }

        final MeetingService meetingService = zoomSDK.getMeetingService();

        StartMeetingOptions opts = new StartMeetingOptions();
        opts.custom_meeting_id = options.get("customMeetingId");
        opts.invite_options = Integer.parseInt(options.get("inviteOptions")); 
        opts.meeting_views_options = Integer.parseInt(options.get("meetingViewsOptions")); 
        opts.no_bottom_toolbar = parseBoolean(options, "noBottomToolbar", false); 
        opts.no_chat_msg_toast = parseBoolean(options, "noChatMsgToast", false); 
        opts.no_dial_in_via_phone = parseBoolean(options, "noDialInViaPhone", false); 
        opts.no_dial_out_to_phone = parseBoolean(options, "noDialOutToPhone", false); 
        opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false); 
        opts.no_driving_mode = parseBoolean(options, "noDrivingMode", false); 
        opts.no_invite = parseBoolean(options, "noInvite", false); 
        opts.no_meeting_end_message = parseBoolean(options, "noMeetingEndMessage", false); 
        opts.no_meeting_error_message = parseBoolean(options, "noMeetingErrorMessage", false); 
        opts.no_share = parseBoolean(options, "noShare", false); 
        opts.no_titlebar = parseBoolean(options, "noTitlebar", false); 
        opts.no_unmute_confirm_dialog = parseBoolean(options, "noUnmuteConfirmDialog", false); 
        opts.no_video = parseBoolean(options, "noVideo", false); 
        opts.no_webinar_register_dialog = parseBoolean(options, "noWebinarRegisterDialog", false); 
        opts.participant_id = options.get("participantId"); 
        opts.no_audio = parseBoolean(options, "noAudio", false); 

        MeetingSettingsHelper msHelper = zoomSDK.getMeetingSettingsHelper();
        msHelper.disableShowVideoPreviewWhenJoinMeeting(true);

        int ret = meetingService.startInstantMeeting(context, opts);

       
        result.success(ret);
    }

    private void joinMeeting(MethodCall methodCall, MethodChannel.Result result) {

        Map<String, String> options = methodCall.arguments();

        ZoomSDK zoomSDK = ZoomSDK.getInstance();

        if(!zoomSDK.isInitialized()) {
            System.out.println("Not initialized!!!!!!");
            result.success(998);
            return;
        }

        zoomSDK.setSdkLocale(context,new Locale(options.get("langCode")));

        final MeetingService meetingService = zoomSDK.getMeetingService();

        JoinMeetingOptions opts = new JoinMeetingOptions();
        opts.custom_meeting_id = options.get("customMeetingId");
        opts.invite_options = Integer.parseInt(options.get("inviteOptions")); 
        opts.meeting_views_options = Integer.parseInt(options.get("meetingViewsOptions")); 
        opts.no_bottom_toolbar = parseBoolean(options, "noBottomToolbar", false); 
        opts.no_chat_msg_toast = parseBoolean(options, "noChatMsgToast", false); 
        opts.no_dial_in_via_phone = parseBoolean(options, "noDialInViaPhone", false); 
        opts.no_dial_out_to_phone = parseBoolean(options, "noDialOutToPhone", false); 
        opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false); 
        opts.no_driving_mode = parseBoolean(options, "noDrivingMode", false); 
        opts.no_invite = parseBoolean(options, "noInvite", false); 
        opts.no_meeting_end_message = parseBoolean(options, "noMeetingEndMessage", false); 
        opts.no_meeting_error_message = parseBoolean(options, "noMeetingErrorMessage", false); 
        opts.no_share = parseBoolean(options, "noShare", false); 
        opts.no_titlebar = parseBoolean(options, "noTitlebar", false); 
        opts.no_unmute_confirm_dialog = parseBoolean(options, "noUnmuteConfirmDialog", false); 
        opts.no_video = parseBoolean(options, "noVideo", false); 
        opts.no_webinar_register_dialog = parseBoolean(options, "noWebinarRegisterDialog", false); 
        opts.participant_id = options.get("participantId"); 
        opts.no_audio = parseBoolean(options, "noAudio", false); 
        opts.participant_id = options.get("webinarToken "); 

        MeetingSettingsHelper msHelper = zoomSDK.getMeetingSettingsHelper();
        msHelper.setAutoConnectVoIPWhenJoinMeeting(true);
        msHelper.setMuteMyMicrophoneWhenJoinMeeting(parseBoolean(options, "noAudio", false));
        msHelper.setTurnOffMyVideoWhenJoinMeeting(parseBoolean(options, "noVideo", false));
        msHelper.disableShowVideoPreviewWhenJoinMeeting(true);

        JoinMeetingParams params = new JoinMeetingParams();

        params.displayName = options.get("displayName");
        params.meetingNo = options.get("meetingNo");
        params.password = options.get("password");

        
        result.success(meetingService.joinMeetingWithParams(context, params, opts));
    }
   

    private void meetingStatus(MethodChannel.Result result) {

        ZoomSDK zoomSDK = ZoomSDK.getInstance();

        if(!zoomSDK.isInitialized()) {
            System.out.println("Not initialized!!!!!!");
            result.success(Arrays.asList("MEETING_STATUS_UNKNOWN", "SDK not initialized"));
            return;
        }

        MeetingService meetingService = zoomSDK.getMeetingService();

        if(meetingService == null) {
            result.success(Arrays.asList("MEETING_STATUS_UNKNOWN", "No status available"));
            return;
        }

        MeetingStatus status = meetingService.getMeetingStatus();
        result.success(status != null ? Arrays.asList(status.name(), "") :  Arrays.asList("MEETING_STATUS_UNKNOWN", "No status available"));
    }

    private void loginWithEmail(final MethodCall methodCall,final MethodChannel.Result result) {
        Map<String, String> options = methodCall.arguments();
        ZoomSDK zoomSDK = ZoomSDK.getInstance();
        final ZoomSDKAuthenticationListener listener = new ZoomSDKAuthenticationListener(){
            @Override
	        public void onZoomSDKLoginResult(long result1) {
                result.success(result1);
                ZoomSDK.getInstance().removeAuthenticationListener(this);
            }
            @Override
	        public void onZoomSDKLogoutResult(long result1) {
                result.success(result1);
                ZoomSDK.getInstance().removeAuthenticationListener(this);
            }
            @Override
	        public void onZoomAuthIdentityExpired() {
                System.out.println("onZoomAuthIdentityExpired");
            }
            @Override
	        public void onZoomIdentityExpired() {
                System.out.println("onZoomIdentityExpired");
            }
        };
        zoomSDK.addAuthenticationListener(listener);

        if(zoomSDK.isLoggedIn()) {
            zoomSDK.tryAutoLoginZoom();
        }else{
            long ret = zoomSDK.loginWithZoom(options.get("email"),options.get("password"));
            if (ret != 0) {
                zoomSDK.removeAuthenticationListener(listener);
                result.success(100);
            }
        }
       
    }
    
    private void loginWithSso(MethodCall methodCall, MethodChannel.Result result) {
        Map<String, String> options = methodCall.arguments();
        ZoomSDK zoomSDK = ZoomSDK.getInstance();
        if(zoomSDK.isLoggedIn()) {
            System.out.println("ZOOM SDK FLUTTER : isLoggedIn ");
            result.success(zoomSDK.tryAutoLoginZoom());
        }else{
            result.success(zoomSDK.loginWithSSOToken(options.get("token")));
        }
    }
    
    
    private void logout(MethodChannel.Result result) {
        ZoomSDK zoomSDK = ZoomSDK.getInstance();
        if(zoomSDK.isLoggedIn()) {
            zoomSDK.logoutZoom();
        }
        result.success(true);
    }

    private boolean parseBoolean(Map<String, String> options, String property, boolean defaultValue) {
        return options.get(property) == null ? defaultValue : Boolean.parseBoolean(options.get(property));
    }

    @Override
    public void dispose() {}

    @Override
    public void onZoomAuthIdentityExpired() {
        System.out.println("ZOOM SDK FLUTTER : expired 1");
    }

    @Override
    public void onZoomSDKLoginResult(long result) {

    }

    @Override
    public void onZoomSDKLogoutResult(long result) {

    }

    @Override
    public void onZoomIdentityExpired() {

    }
}
