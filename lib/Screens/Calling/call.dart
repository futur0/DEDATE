import 'dart:async';
import 'package:agora_rtc_engine/rtc_local_view.dart' as localview;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as remoteview;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u/models/call_model.dart';
import 'package:hookup4u/util/color.dart';
import 'package:hookup4u/gettoken.dart';
import 'utils/settings.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';

class CallPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  /// non-modifiable client role of the page
  final ClientRole role;
  final String callType;

  /// Creates a call page with given channel name.
  const CallPage({Key key, this.channelName, this.role, this.callType})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool disable = true;
  RtcEngine engine;

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk

    super.dispose();
 
  }

  disposeAll() async{
    try {
     await engine?.leaveChannel();
     await engine?.destroy();
     
    }  catch (e) {
    }
   // Navigator.pop(context);
   
   
  }

  listenCallEvent() async {
    Firestore.instance
        .collection("calls")
        .document(widget.channelName)
        .snapshots()
        .listen((doc) {
      if (doc.data != null) {
        var call = CallModel.fromMap(doc.data);
        if (!call.calling) {
         disposeAll();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    listenCallEvent();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initRtcEngine();
    // _addAgoraEventHandlers();
    // await engine.enableWebSdkInteroperability(true);
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    // configuration.dimensions =Size(1920, 1080);
    await engine.setVideoEncoderConfiguration(configuration);
    bool isPublisher = widget.role == ClientRole.Broadcaster ? true : false;
    final token = await getToken(widget.channelName, isPublisher);
    await engine.joinChannel(token.token, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initRtcEngine() async {
    engine = await RtcEngine.createWithConfig(RtcEngineConfig(APP_ID));
    widget.callType == "VideoCall"
        ? await engine.enableVideo()
        : await engine.enableAudio();
       
    await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await engine.setClientRole(widget.role);
    _addListeners();
  }

  _addListeners() {
    engine?.setEventHandler(RtcEngineEventHandler(
      userJoined: (uid, elapsed) {
      _users.add(uid);
      if(widget.callType=='AudioCall'){
        
         engine.setEnableSpeakerphone(false);
       }
      setState(() {});
    }));
  }

  /// Add agora event handlers
  // void _addAgoraEventHandlers() {
  //   // engine.onError = (dynamic code) {
  //   //   setState(() {
  //   //     final info = 'onError: $code';
  //   //     _infoStrings.add(info);
  //   //   });
  //   // };

  //   engine.onJoinChannelSuccess = (
  //     String channel,
  //     int uid,
  //     int elapsed,
  //   ) {
  //     setState(() {
  //       final info = 'onJoinChannel: $channel, uid: $uid';
  //       _infoStrings.add(info);
  //     });
  //   };

  //   engine.onLeaveChannel = () {
  //     setState(() {
  //       _infoStrings.add('onLeaveChannel');
  //       _users.clear();
  //     });
  //   };

  //   engine.onUserJoined = (int uid, int elapsed) {
  //     setState(() {
  //       final info = 'userJoined: $uid';
  //       _infoStrings.add(info);
  //       _users.add(uid);
  //     });
  //   };

  //   engine.onUserOffline = (int uid, int reason) {
  //     setState(() {
  //       final info = 'userOffline: $uid';
  //       _infoStrings.add(info);
  //       _users.remove(uid);
  //     });
  //     Navigator.pop(context);
  //   };

  //   engine.onFirstRemoteVideoFrame = (
  //     int uid,
  //     int width,
  //     int height,
  //     int elapsed,
  //   ) {
  //     setState(() {
  //       final info = 'firstRemoteVideo: $uid ${width}x $height';
  //       _infoStrings.add(info);
  //     });
  //   };
  // }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(localview.SurfaceView());
    }
    _users.forEach((int uid) => list.add(remoteview.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  bool showRemoteLarge=true;
  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            
           _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]]),
            
          ],
        ));
      // case 3:
      //   return Container(
      //       child: Column(
      //     children: <Widget>[
      //       _expandedVideoRow(views.sublist(0, 2)),
      //       _expandedVideoRow(views.sublist(2, 3))
      //     ],
      //   ));
      // case 4:
      //   return Container(
      //       child: Column(
      //     children: <Widget>[
      //       _expandedVideoRow(views.sublist(0, 1)),
      //       _expandedVideoRow(views.sublist(2, 4))
      //     ],
      //   ));
      default:
    }
    return Container();
  }

  /// Toolbar layout
  Widget _videoToolbar() {
    if (widget.role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : primaryColor,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? primaryColor : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: Icon(
              Icons.switch_camera,
              color: primaryColor,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: _disVideo,
            child: Icon(
              disable ? Icons.videocam : Icons.videocam_off,
              color: disable ? primaryColor : Colors.white,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: !disable ? primaryColor : Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
        ],
      ),
    );
  }

  _toggleLoud(){
   setState(() {
      loud=!loud;
    });
    engine.setEnableSpeakerphone(loud);
     
    
  }
bool loud=false;
  Widget _audioToolbar() {
    if (widget.role == ClientRole.Audience) return Container();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : primaryColor,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: muted ? primaryColor : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: _toggleLoud,
            child: Icon(
              loud ? Icons.volume_down : Icons.volume_mute,
              color: loud ? Colors.white : primaryColor,
              size: 20.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: loud ? primaryColor : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
        ],
      ),
    );
  }

  void _onCallEnd(BuildContext context) {
     Firestore.instance
        .collection("calls")
        .document(widget.channelName)
        .updateData({
          'calling':false,
          'response':'CallEnded'
        });
   
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    engine.switchCamera();
  }

  _disVideo() {
    setState(() {
      disable = !disable;
    });
    engine.enableLocalVideo(disable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: <Widget>[
            widget.callType == "VideoCall"
                ? _viewRows()
                : Container(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: primaryColor,
                    ),
                  ),
            // _panel(),
            widget.callType == "VideoCall" ? _videoToolbar() : _audioToolbar()
          ],
        ),
      ),
    );
  }
}
