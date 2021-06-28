import Flutter
import UIKit
import MobileRTC
import MobileRTC.MobileRTCConstants

public class SwiftFlutterZoomPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let factory = ZoomViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "flutter_zoom_plugin")
    }
}


public class ZoomViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private weak var messenger: (NSObjectProtocol & FlutterBinaryMessenger)?
    
    init(messenger: (NSObjectProtocol & FlutterBinaryMessenger)?) {
        self.messenger = messenger
        super.init()
    }
    
    public func create(
        withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
    ) -> FlutterPlatformView {
        return ZoomView(frame, viewId: viewId, messenger: messenger, args: args)
    }
}

public class AuthenticationDelegate: NSObject, MobileRTCAuthDelegate {
    
    private var result: FlutterResult?
    
    
    public func onAuth(_ result: FlutterResult?) -> AuthenticationDelegate {
        self.result = result
        return self
    }
    
    
    public func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {

        if returnValue == .success {
            self.result?([0, 0])
        } else {
            self.result?([1, 0])
        }
        
        self.result = nil
    }
    
    public func onMobileRTCLoginResult(_ returnValue: MobileRTCLoginFailReason) {
        self.result?(getLoginErrorCode(returnValue))
    }

    
    public func onMobileRTCLogoutReturn(_ returnValue: Int) {
        
    }

    public func getLoginErrorCode(_ state: MobileRTCLoginFailReason?) -> Int {
        var code : Int
        switch state {
        case .emailLoginDiable:
            code = 1
            break
        case .loginTokenInvalid:
            code = 10
            break
        case .success:
            code = 0
            break
        case .userNotExist:
            code = 2
            break
        case .accountLocked:
            code = 4
            break
        case .otherIssue:
            code = 100
            break
        case .wrongPassword:
            code = 3
            break
        case .phoneNumberFormatInValid:
            code = 9
            break
        case .sdkNeedUpdate:
            code = 5
            break
        case .smsCodeError:
            code = 7
            break
        case .smsCodeExpired:
            code = 8
            break
        case .tooManyFailedAttempts:
            code = 6
            break
        default:
            code = 100
        }
        return code
    }
    
   
}

public class ZoomView: NSObject, FlutterPlatformView, MobileRTCMeetingServiceDelegate, FlutterStreamHandler {
    let frame: CGRect
    let viewId: Int64
    var channel: FlutterMethodChannel
    var authenticationDelegate: AuthenticationDelegate
    
    var statusEventChannel: FlutterEventChannel
    var eventSink: FlutterEventSink?
    
    init(_ frame: CGRect, viewId: Int64, messenger: (NSObjectProtocol & FlutterBinaryMessenger)?, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = FlutterMethodChannel(name: "com.decodedhealth/flutter_zoom_plugin", binaryMessenger: messenger!)
        self.authenticationDelegate = AuthenticationDelegate()
        self.statusEventChannel = FlutterEventChannel(name: "com.decodedhealth/zoom_event_stream", binaryMessenger: messenger!)

        super.init()
        
        self.statusEventChannel.setStreamHandler(self)
        self.channel.setMethodCallHandler(self.onMethodCall)
    }
    
    public func view() -> UIView {
        
        let label = UILabel(frame: frame)
        label.text = "Zoom"
        return label
    }
    
    public func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
        case "init":
            self.initZoom(call: call, result: result)
        case "join":
            self.joinMeeting(call: call, result: result)
        case "start":
            self.startMeeting(call: call, result: result)
        case "meeting_status":
            self.meetingStatus(call: call, result: result)
        case "in_meeting":
            self.inMeeting(call: call, result: result)
        case "in_meeting_config":
            self.inMeetingConfig(call: call)
        case "login_with_email":
            self.loginWithEmail(call: call, result: result)
        case "login_with_sso":
            self.loginWithSso(call: call, result: result)
        case "start_instant_meeting":
            self.startInstantMeeting(call: call, result: result)
        case "logout":
            self.logout(result: result)
        case "get_meeting_password":
            self.getMeetingPassword(result: result)
        case "get_logged_account_info":
            self.getLoggedAccountInfo(result: result);
        case "releaseListener":
            self.releaseListener();
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func initZoom(call: FlutterMethodCall, result: @escaping FlutterResult)  {
        
        let pluginBundle = Bundle(for: type(of: self))
        let pluginBundlePath = pluginBundle.bundlePath
        let arguments = call.arguments as! Dictionary<String, String>
        
        let context = MobileRTCSDKInitContext()
        context.domain = arguments["domain"]!
        context.enableLog = true
        context.bundleResPath = pluginBundlePath
        MobileRTC.shared().initialize(context)
        MobileRTC.shared().setLanguage(arguments["langCode"]!)
        
        let auth = MobileRTC.shared().getAuthService()
        auth?.delegate = self.authenticationDelegate.onAuth(result)
        auth?.clientKey = arguments["appKey"]!
        auth?.clientSecret = arguments["appSecret"]!
        auth?.jwtToken = arguments["sdkToken"]!
        auth?.sdkAuth()
    }

    public func releaseListener(){
        let auth = MobileRTC.shared().getAuthService()
        if auth != nil {
            auth!.delegate = nil
        }

        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService != nil {
            meetingService!.delegate = nil
        }

    }
    
    public func loginWithEmail(call: FlutterMethodCall, result: @escaping FlutterResult)  {
        let auth = MobileRTC.shared().getAuthService()

        let arguments = call.arguments as! Dictionary<String, String>

            if auth != nil {
                auth!.delegate = self.authenticationDelegate.onAuth(result)
                if !auth!.login(withEmail: arguments["email"]!, password: arguments["password"]!, rememberMe: false) {
                    result(100)
                }
            }else {
                result(100)
            }
    }
    
    public func loginWithSso(call: FlutterMethodCall, result: @escaping FlutterResult)  {
        let auth = MobileRTC.shared().getAuthService()
        let arguments = call.arguments as! Dictionary<String, String>

        if auth != nil {
            if auth!.isLoggedIn() {
                result(0)
            }
            else if auth!.login(withSSOToken: arguments["token"]!, rememberMe: false) {
                result(0)
            }else{
                result(6)
            }
        }else{
            result(6)
        }
    }
    
    
    
    public func logout(result: @escaping FlutterResult)  {
        let auth = MobileRTC.shared().getAuthService()
        if auth != nil {
            if auth!.isLoggedIn() {
                auth?.logoutRTC()
            }
        }
        result(true)
    }
    
    public func getMeetingPassword(result: @escaping FlutterResult)  {
        let meetingInviteHelper = MobileRTCInviteHelper.sharedInstance()
        result([meetingInviteHelper.ongoingMeetingNumber , meetingInviteHelper.rawMeetingPassword ])
    }
    public func getLoggedAccountInfo(result: @escaping FlutterResult)  {
        let accountInfo = MobileRTC.shared().getAuthService()?.getAccountInfo()
        if accountInfo == nil {
            result(["",""])
            return
        }
        result([accountInfo!.getEmailAddress() , accountInfo!.getUserName() ])
    }
    
    public func meetingStatus(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService != nil {
            
            let meetingState = meetingService?.getMeetingState()
            result(getStateMessage(meetingState))
        } else {
            result(["MEETING_STATUS_UNKNOWN", ""])
        }
    }
    
    // public func joinMeeting(call: FlutterMethodCall, result: FlutterResult) {
        
    //     let meetingService = MobileRTC.shared().getMeetingService()
    //     let meetingSettings = MobileRTC.shared().getMeetingSettings()
        
    //     if meetingService != nil {
            
    //         let arguments = call.arguments as! Dictionary<String, String?>

    //         MobileRTC.shared().setLanguage(arguments["langCode"]!!)
    //         // let langCode = arguments["langCode"]! != nil;
    //         // if langCode {
    //         //     MobileRTC.shared().setLanguage(arguments["langCode"]!!)
    //         // }
            
            
    //         meetingSettings?.disableDriveMode(parseBoolean(data: arguments["disableDrive"]!, defaultValue: false))
    //         meetingSettings?.disableCall(in: parseBoolean(data: arguments["disableDialIn"]!, defaultValue: false))
    //         meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: false))
    //         meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: false))
    //         meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["disableShare"]!, defaultValue: false)
    //         meetingSettings?.meetingInviteHidden = parseBoolean(data: arguments["disableDrive"]!, defaultValue: false)
       
    //         // meetingSettings?.topBarHidden = true;

    //         meetingSettings?.meetingTitleHidden = true;
    //         meetingSettings?.meetingPasswordHidden = true;
    //         meetingSettings?.meetingParticipantHidden = true;
    //         meetingSettings?.meetingLeaveHidden = false;
    //         meetingSettings?.meetingInviteHidden = true;
    //         // meetingSettings?.enableCustomMeeting = true;
    //         meetingSettings?.setMuteVideoWhenJoinMeeting(false)
    //         meetingSettings?.disableVirtualBackground(false)
    //         meetingSettings?.disableCopyMeetingUrl(true)
    //         meetingSettings?.disableShowVideoPreview(whenJoinMeeting:true)
            
    //         var params = [
    //             kMeetingParam_Username: arguments["userId"]!!,
    //             kMeetingParam_MeetingNumber: arguments["meetingId"]!!
    //         ]
            
    //         let param = MobileRTCMeetingJoinParam();
    //         param.noVideo = false;
    //         param.userName = arguments["userId"]!!;
    //         param.meetingNumber = arguments["meetingId"]!!
            
    //         let hasPassword = arguments["meetingPassword"]! != nil
    //         if hasPassword {
    //             params[kMeetingParam_MeetingPassword] = arguments["meetingPassword"]!!
    //             param.password = arguments["meetingPassword"]!!
    //         }
            
    //         let response = meetingService?.joinMeeting(with: param)
            
    //         if let response = response {
    //             print("Got response from join: \(response)")
    //         }

    //         result(true)
    //     } else {
    //         result(false)
    //     }
    // }

    public func inMeeting(call: FlutterMethodCall, result: @escaping FlutterResult){
        let meetingService = MobileRTC.shared().getMeetingService()
        let userList = meetingService?.getInMeetingUserList()
            if userList != nil {
               for user in (userList! as [Any]) {
                   print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",user)
                   if (meetingService!.isHostUser(user as! UInt)){
                       print("bbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
                       meetingService?.pinVideo(true,withUser: user as! UInt)
                   }
               }
            }
    }

    public func inMeetingConfig(call: FlutterMethodCall){
        let meetingService = MobileRTC.shared().getMeetingService()
        let arguments = call.arguments as! Dictionary<String, String?>
        
        if arguments["setMeetingTopic"]!! != "-1" {
            meetingService?.setMeetingTopic(arguments["setMeetingTopic"]!!)
        }

        if arguments["allowParticipantsToRename"]!! != "-1" {
            meetingService?.allowParticipants(toRename :parseBoolean(data: arguments["allowParticipantsToRename"]!, defaultValue: false))
        }
        if arguments["allowParticipantsToUnmuteSelf"]!! != "-1" {
            meetingService?.allowParticipants(toUnmuteSelf : parseBoolean(data: arguments["allowParticipantsToUnmuteSelf"]!, defaultValue: false))
        }
        if arguments["muteMyAudio"]!! != "-1" {
            if parseBoolean(data: arguments["muteMyAudio"]!, defaultValue: false) {
                meetingService?.muteMyAudio(false)
            }else{
                meetingService?.connectMyAudio(true)
            }
            
            // meetingService?.muteMyAudio(mute: parseBoolean(data: arguments["muteMyAudio"]!, defaultValue: false))
        }
        if arguments["muteMyVideo"]!! != "-1" {
            meetingService?.muteMyVideo(parseBoolean(data: arguments["muteMyVideo"]!, defaultValue: false))
        }
    }

    public func startInstantMeeting(call: FlutterMethodCall, result: @escaping FlutterResult)  {
        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()

        let arguments = call.arguments as! Dictionary<String, String?>

        if meetingService != nil {

            //opts.no_bottom_toolbar = parseBoolean(options, "noBottomToolbar", false); 
            meetingSettings?.bottomBarHidden = parseBoolean(data: arguments["noBottomToolbar"]!, defaultValue: false)

            //opts.no_chat_msg_toast = parseBoolean(options, "noChatMsgToast", false);

            //opts.no_dial_in_via_phone = parseBoolean(options, "noDialInViaPhone", false);
            meetingSettings?.disableCall(in : parseBoolean(data: arguments["noDialInViaPhone"]!, defaultValue: true)) 
            //opts.no_dial_out_to_phone = parseBoolean(options, "noDialOutToPhone", false); 
            meetingSettings?.disableCallOut(parseBoolean(data: arguments["noDialOutToPhone"]!, defaultValue: true))

            //opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false); 
            meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: true))

            //opts.no_driving_mode = parseBoolean(options, "noDrivingMode", false); 
            meetingSettings?.disableDriveMode(parseBoolean(data: arguments["noDrivingMode"]!, defaultValue: false))

            //opts.no_invite = parseBoolean(options, "noInvite", false); 
            meetingSettings?.meetingInviteHidden = parseBoolean(data: arguments["noInvite"]!, defaultValue: true)

            //opts.no_meeting_end_message = parseBoolean(options, "noMeetingEndMessage", false); 
            //opts.no_meeting_error_message = parseBoolean(options, "noMeetingErrorMessage", false); 

            //opts.no_share = parseBoolean(options, "noShare", false); 
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["noShare"]!, defaultValue: false)

            //opts.no_titlebar = parseBoolean(options, "noTitlebar", false); 
            meetingSettings?.meetingTitleHidden = parseBoolean(data: arguments["noTitlebar"]!, defaultValue: false)
            
            //opts.no_unmute_confirm_dialog = parseBoolean(options, "noUnmuteConfirmDialog", false); 

            //opts.no_video = parseBoolean(options, "noVideo", false); 
            meetingSettings?.setMuteVideoWhenJoinMeeting(parseBoolean(data: arguments["noVideo"]!, defaultValue: false))

            //opts.no_webinar_register_dialog = parseBoolean(options, "noWebinarRegisterDialog", false); 
            //opts.participant_id = options.get("participantId"); 

            //opts.no_audio = parseBoolean(options, "noAudio", false); 
            meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: false))

            //inviteCopyUrl
            meetingSettings?.disableCopyMeetingUrl(!parseBoolean(data: arguments["inviteCopyUrl"]!, defaultValue: false))
            
            //noButtonAudio
            meetingSettings?.meetingAudioHidden = parseBoolean(data: arguments["noButtonAudio"]!, defaultValue: true)
            //noButtonLeave
            meetingSettings?.meetingLeaveHidden = parseBoolean(data: arguments["noButtonLeave"]!, defaultValue: true)
            //noButtonMore
            meetingSettings?.meetingMoreHidden = parseBoolean(data: arguments["noButtonMore"]!, defaultValue: true)
            //noButtonParticipants
            meetingSettings?.meetingParticipantHidden = parseBoolean(data: arguments["noButtonParticipants"]!, defaultValue: true)
            //noButtonShare
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["noButtonShare"]!, defaultValue: true)
            
            //noButtonSwitchAudio
            //noButtonSwitchCamera

            //noButtonVideo
            meetingSettings?.meetingVideoHidden = parseBoolean(data: arguments["noButtonVideo"]!, defaultValue: true)

            //noTextMeetingId

            //noTextPassword
            meetingSettings?.meetingPasswordHidden = parseBoolean(data: arguments["noTextPassword"]!, defaultValue: true)
            
            

            meetingSettings?.disableShowVideoPreview(whenJoinMeeting:true)

            //   opts.custom_meeting_id = options.get("customMeetingId");
            meetingService?.customizeMeetingTitle(arguments["customMeetingId"]!)

            let user: MobileRTCMeetingStartParam4LoginlUser = MobileRTCMeetingStartParam4LoginlUser.init()
            let param: MobileRTCMeetingStartParam = user
            param.meetingNumber = ""

            result(getMeetingErrorCode(meetingService?.startMeeting(with: param)))
        }else{
            result(998)
        }
    }

    public func joinMeeting(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()

        let arguments = call.arguments as! Dictionary<String, String?>
        
        if meetingService != nil {
            
            //opts.no_bottom_toolbar = parseBoolean(options, "noBottomToolbar", false); 
            meetingSettings?.bottomBarHidden = parseBoolean(data: arguments["noBottomToolbar"]!, defaultValue: false)

            //opts.no_chat_msg_toast = parseBoolean(options, "noChatMsgToast", false);

            //opts.no_dial_in_via_phone = parseBoolean(options, "noDialInViaPhone", false);
            meetingSettings?.disableCall(in : parseBoolean(data: arguments["noDialInViaPhone"]!, defaultValue: true)) 
            //opts.no_dial_out_to_phone = parseBoolean(options, "noDialOutToPhone", false); 
            meetingSettings?.disableCallOut(parseBoolean(data: arguments["noDialOutToPhone"]!, defaultValue: true))

            //opts.no_disconnect_audio = parseBoolean(options, "noDisconnectAudio", false); 
            meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: true))

            //opts.no_driving_mode = parseBoolean(options, "noDrivingMode", false); 
            meetingSettings?.disableDriveMode(parseBoolean(data: arguments["noDrivingMode"]!, defaultValue: false))

            //opts.no_invite = parseBoolean(options, "noInvite", false); 
            meetingSettings?.meetingInviteHidden = parseBoolean(data: arguments["noInvite"]!, defaultValue: true)

            //opts.no_meeting_end_message = parseBoolean(options, "noMeetingEndMessage", false); 
            //opts.no_meeting_error_message = parseBoolean(options, "noMeetingErrorMessage", false); 

            //opts.no_share = parseBoolean(options, "noShare", false); 
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["noShare"]!, defaultValue: false)

            //opts.no_titlebar = parseBoolean(options, "noTitlebar", false); 
            meetingSettings?.meetingTitleHidden = parseBoolean(data: arguments["noTitlebar"]!, defaultValue: false)
            
            //opts.no_unmute_confirm_dialog = parseBoolean(options, "noUnmuteConfirmDialog", false); 

            //opts.no_video = parseBoolean(options, "noVideo", false); 
            meetingSettings?.setMuteVideoWhenJoinMeeting(parseBoolean(data: arguments["noVideo"]!, defaultValue: false))

            //opts.no_webinar_register_dialog = parseBoolean(options, "noWebinarRegisterDialog", false); 
            //opts.participant_id = options.get("participantId"); 

            //opts.no_audio = parseBoolean(options, "noAudio", false); 
            meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: false))

            //inviteCopyUrl
            meetingSettings?.disableCopyMeetingUrl(!parseBoolean(data: arguments["inviteCopyUrl"]!, defaultValue: false))
            
            //noButtonAudio
            meetingSettings?.meetingAudioHidden = parseBoolean(data: arguments["noButtonAudio"]!, defaultValue: true)
            //noButtonLeave
            meetingSettings?.meetingLeaveHidden = parseBoolean(data: arguments["noButtonLeave"]!, defaultValue: true)
            //noButtonMore
            meetingSettings?.meetingMoreHidden = parseBoolean(data: arguments["noButtonMore"]!, defaultValue: true)
            //noButtonParticipants
            meetingSettings?.meetingParticipantHidden = parseBoolean(data: arguments["noButtonParticipants"]!, defaultValue: true)
            //noButtonShare
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["noButtonShare"]!, defaultValue: true)
            
            //noButtonSwitchAudio
            //noButtonSwitchCamera

            //noButtonVideo
            meetingSettings?.meetingVideoHidden = parseBoolean(data: arguments["noButtonVideo"]!, defaultValue: true)

            //noTextMeetingId

            //noTextPassword
            meetingSettings?.meetingPasswordHidden = parseBoolean(data: arguments["noTextPassword"]!, defaultValue: true)
            
            

            meetingSettings?.disableShowVideoPreview(whenJoinMeeting:true)

            //   opts.custom_meeting_id = options.get("customMeetingId");
            meetingService?.customizeMeetingTitle(arguments["customMeetingId"]!)
            
            
            let param = MobileRTCMeetingJoinParam();
            // param.noVideo = false;
            param.userName = arguments["displayName"]!!;
            param.meetingNumber = arguments["meetingNo"]!!
            param.password = arguments["password"]!!

            // let hasPassword = arguments["password"]! != nil
            // if hasPassword {
            //     param.password = arguments["password"]!!
            // }
            let ret = meetingService?.joinMeeting(with: param)
            result(getMeetingErrorCode(ret))
        } else {
            result(998)
        }
    }

    public func startMeeting(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()
        
        if meetingService != nil {
            
            let arguments = call.arguments as! Dictionary<String, String?>
            
            meetingSettings?.disableDriveMode(parseBoolean(data: arguments["disableDrive"]!, defaultValue: false))
            meetingSettings?.disableCall(in: parseBoolean(data: arguments["disableDialIn"]!, defaultValue: false))
            meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: false))
            meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: false))
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["disableShare"]!, defaultValue: false)
            meetingSettings?.meetingInviteHidden = parseBoolean(data: arguments["disableDrive"]!, defaultValue: false)

            let user: MobileRTCMeetingStartParam4WithoutLoginUser = MobileRTCMeetingStartParam4WithoutLoginUser.init()
            
            user.userType = MobileRTCUserType.apiUser
            user.meetingNumber = arguments["meetingId"]!!
            user.userName = arguments["displayName"]!!
            // user.userToken = arguments["zoomToken"]!!
            user.userID = arguments["userId"]!!
            user.zak = arguments["zoomAccessToken"]!!

            let param: MobileRTCMeetingStartParam = user
            
            let response = meetingService?.startMeeting(with: param)
            
            if let response = response {
                print("Got response from start: \(response)")
            }
            result(true)
        } else {
            result(false)
        }
    }
    
    private func parseBoolean(data: String?, defaultValue: Bool) -> Bool {
        var result: Bool
        
        if let unwrappeData = data {
            result = NSString(string: unwrappeData).boolValue
        } else {
            result = defaultValue
        }
        return result
    }
    
    
    
    
    public func onMeetingError(_ error: MobileRTCMeetError, message: String?) {
        
    }
    
    public func getMeetErrorMessage(_ errorCode: MobileRTCMeetError) -> String {
        
        let message = ""
        // switch (errorCode) {
        //     case MobileRTCAuthError_Success:
        //         message = "Authentication success."
        //         break
        //     case MobileRTCAuthError_KeyOrSecretEmpty:
        //         message = "SDK key or secret is empty."
        //         break
        //     case MobileRTCAuthError_KeyOrSecretWrong:
        //         message = "SDK key or secret is wrong."
        //         break
        //     case MobileRTCAuthError_AccountNotSupport:
        //         message = "Your account does not support SDK."
        //         break
        //     case MobileRTCAuthError_AccountNotEnableSDK:
        //         message = "Your account does not support SDK."
        //         break
        //     case MobileRTCAuthError_Unknown:
        //         message = "Unknown error.Please try again."
        //         break
        //     default:
        //         message = "Unknown error.Please try again."
        //         break
        // }
        return message
    }
    
    public func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(getStateMessage(state))
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService == nil {
            return FlutterError(code: "Zoom SDK error", message: "ZoomSDK is not initialized", details: nil)
        }
        meetingService?.delegate = self
        
        return nil
    }
     
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func getMeetingErrorCode(_ state: MobileRTCMeetError?) -> Int {
        var code : Int
        switch state {
        case .meetingClientIncompatible:
            code = 4
            break
        case .registerWebinarHostRegister:
            code = 17
            break
        case .registerWebinarPanelistRegister:
            code = 18
            break
        case .registerWebinarDeniedEmail:
            code = 19
            break
        case .invalidArguments:
            code = 99
            break
        case .meetingLocked:
            code = 12
            break
        case .meetingNotExist:
            code = 9
            break
        case .meetingOver:
            code = 8
            break
        case .mmrError:
            code = 6
            break
        case .networkError:
            code = 5
            break
        case .noMMR:
            code = 11
            break
        case .registerWebinarFull:
            code = 16
            break
        case .removedByHost:
            code = 22
            break
        case .meetingRestricted:
            code = 13
            break
        case .meetingRestrictedJBH:
            code = 14
            break
        case .sessionError:
            code = 7
            break
        case .success:
            code = 0
            break
        case .unknown:
            code = 100
            break
        case .meetingUserFull:
            code = 10
            break
        case .registerWebinarEnforceLogin:
            code = 20
            break
        default:
            code = 100
        }
        return code
    }
    
    private func getStateMessage(_ state: MobileRTCMeetingState?) -> [String] {
        
        var message: [String]
        
        switch state {
        case .idle:
            message = ["MEETING_STATUS_IDLE", "No meeting is running"]
            break
        case .connecting:
            message = ["MEETING_STATUS_CONNECTING", "Connect to the meeting server"]
            break
        case .waitingForHost:
            message = ["MEETING_STATUS_WAITINGFORHOST", "Waiting for the host to start the meeting."]
            break
        case .inMeeting:
            message = ["MEETING_STATUS_INMEETING", "Meeting is ready and in process"]
            break
        case .disconnecting:
            message = ["MEETING_STATUS_DISCONNECTING", "Disconnect the meeting server, user leaves meeting."]
            break
        case .reconnecting:
            message = ["MEETING_STATUS_RECONNECTING", "Reconnecting meeting server."]
            break
        case .failed:
            message = ["MEETING_STATUS_FAILED", "Failed to connect the meeting server."]
            break
        case .ended:
            message = ["MEETING_STATUS_ENDED", "Meeting ends."]
            break
        case .unknow:
            message = ["MEETING_STATUS_UNKNOWN", "Unknown status."]
            break
        case .locked:
            message = ["MEETING_STATUS_LOCKED", "Locked status."]
            break
        case .unlocked:
            message = ["MEETING_STATUS_UNLOCKED", "unLocked status."]
            break
        case .inWaitingRoom:
            message = ["MEETING_STATUS_IN_WAITING_ROOM", "inWaitingRoom status."]
            break
        case .joinBO:
            message = ["MEETING_STATUS_JOIN_BO", "joinBO status."]
            break
        case .leaveBO:
            message = ["MEETING_STATUS_LEAVE_BO", "leaveBO status."]
            break
        case .waitingExternalSessionKey:
            message = ["MEETING_STATUS_WAIT_EX_SESION_KEY", "waitingExternalSessionKey status."]
            break
        case .webinarPromote:
            message = ["MEETING_STATUS_WEBINAR_PROMOTE", "Upgrade the attendees to panelist in webinar"]
            break
        case .webinarDePromote:
            message = ["MEETING_STATUS_WEBINAR_DEPROMOTE", "Demote the attendees from the panelist"]
            break
        default:
            message = ["", ""]
        }
        
        return message
    }
    
}
