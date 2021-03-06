import 'dart:async';
import 'dart:io';

import 'package:flutter_zoom_plugin/zoom_view.dart';
import 'package:flutter_zoom_plugin/zoom_options.dart';

import 'package:flutter/material.dart';

class MeetingWidget extends StatelessWidget {
  final ZoomOptions zoomOptions = ZoomOptions(
    domain: "zoom.us",
    appKey: "appKey",
    appSecret: "appSecret",
  );
  final ZoomMeetingOptionAll meetingOptions = ZoomMeetingOptionAll(
    noTextMeetingId: true,
    noTextPassword: true,
    noTitlebar: false,
    noShare: true,
    noButtonShare: true,
    noAudio: true,
    noButtonParticipants: true,
  );

  late Timer timer;

  MeetingWidget({required String meetingId, required String meetingPassword}) {
    // this.zoomOptions = new ZoomOptions(
    //   domain: "zoom.us",
    //   appKey: "appKey",
    //   appSecret: "appSecret",
    // );
    meetingOptions.meetingNo = meetingId;
    meetingOptions.password = meetingPassword;
  }

  bool _isMeetingEnded(String status) {
    var result = false;

    if (Platform.isAndroid)
      result = status == "MEETING_STATUS_DISCONNECTING" ||
          status == "MEETING_STATUS_FAILED";
    else
      result = status == "MEETING_STATUS_IDLE";

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text('Loading meeting '),
      ),
      body: Padding(
          padding: EdgeInsets.all(16.0),
          child: ZoomView(onViewCreated: (controller) {
            print("Created the view");

            controller.initZoom(this.zoomOptions).then((results) {
              print("initialised");
              print(results);

              if (results == ZoomApiError.ZOOM_API_ERROR_SUCCESS) {
                controller.zoomStatusEvents.listen((status) {
                  print("Meeting Status Stream: " +
                      status[0] +
                      " - " +
                      status[1]);
                  if (_isMeetingEnded(status[0])) {
                    Navigator.pop(context);
                    timer.cancel();
                  }
                });

                print("listen on event channel");

                controller
                    .joinMeeting(this.meetingOptions)
                    .then((joinMeetingResult) {
                  timer = Timer.periodic(new Duration(seconds: 2), (timer) {
                    controller
                        .meetingStatus(this.meetingOptions.meetingNo!)
                        .then((status) {
                      print('Meeting Status Polling: $status');
                    });
                  });
                });
              }
            }).catchError((error) {
              print("Error");
              print(error);
            });
          })),
    );
  }
}
