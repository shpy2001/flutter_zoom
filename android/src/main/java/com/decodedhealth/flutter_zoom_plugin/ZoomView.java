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

    ZoomView(Context context, BinaryMessenger messenger, int id) {
        textView = new TextView(context);
        this.context = context;

        methodChannel = new MethodChannel(messenger, "com.decodedhealth/flutter_zoom_plugin");
        methodChannel.setMethodCallHandler(this);

        meetingStatusChannel = new EventChannel(messenger, "com.decodedhealth/zoom_event_stream");
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
                inMeeting();
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
                        MeetingService meetingService = zoomSDK.getMeetingService();
                        meetingStatusChannel.setStreamHandler(new StatusStreamHandler(meetingService));
                        result.success(response);
                    }
                },
                initParams);
    }

    private void joinMeeting(MethodCall methodCall, MethodChannel.Result result) {

        Map<String, String> options = methodCall.arguments();

        ZoomSDK zoomSDK = ZoomSDK.getInstance();

        if(!zoomSDK.isInitialized()) {
            System.out.println("Not initialized!!!!!!");
            result.success(false);
            return;
        }

        zoomSDK.setSdkLocale(context,new Locale(options.get("langCode")));

        final MeetingService meetingService = zoomSDK.getMeetingService();

        JoinMeetingOptions opts = new JoinMeetingOptions();
        opts.no_invite = parseBoolean(options, "disableInvite", false);
        opts.no_share = parseBoolean(options, "disableShare", false);
        opts.no_driving_mode = parseBoolean(options, "disableDrive", false);
        opts.no_dial_in_via_phone = parseBoolean(options, "disableDialIn", false);
        opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false);
        opts.no_audio = parseBoolean(options, "noAudio", false);

        opts.no_video = false;
		opts.meeting_views_options = MeetingViewsOptions.NO_TEXT_PASSWORD + MeetingViewsOptions.NO_TEXT_MEETING_ID + MeetingViewsOptions.NO_BUTTON_PARTICIPANTS + MeetingViewsOptions.NO_BUTTON_SHARE;
        
        MeetingSettingsHelper msHelper = zoomSDK.getMeetingSettingsHelper();
        msHelper.setAutoConnectVoIPWhenJoinMeeting(true);
        msHelper.setMuteMyMicrophoneWhenJoinMeeting(true);
        msHelper.setTurnOffMyVideoWhenJoinMeeting(false);
        msHelper.disableShowVideoPreviewWhenJoinMeeting(true);

        JoinMeetingParams params = new JoinMeetingParams();

        params.displayName = options.get("userId");
        params.meetingNo = options.get("meetingId");
        params.password = options.get("meetingPassword");

        meetingService.joinMeetingWithParams(context, params, opts);
        result.success(true);
    }

    private void inMeeting(){
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

    private boolean parseBoolean(Map<String, String> options, String property, boolean defaultValue) {
        return options.get(property) == null ? defaultValue : Boolean.parseBoolean(options.get(property));
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

    @Override
    public void dispose() {}

    @Override
    public void onZoomAuthIdentityExpired() {

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
