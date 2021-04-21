import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:hookup4u/models/call_model.dart';
import 'call.dart';

class PickupScreen extends StatefulWidget {
  final CallModel call;
  PickupScreen({this.call});

  @override
  _PickupScreenState createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  @override
  void dispose() async {
    _controller.dispose();
    FlutterRingtonePlayer.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer.play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true, // Android only - API >= 28
      volume: 1, // Android only - API >= 28
      asAlarm: false, // Android only - all APIs
    );
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.5,
      duration: Duration(seconds: 3),
    )..repeat();
  }
 bool haspoped=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance
          .collection("calls")
          .document(widget.call.channelId)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Text('Connecting');
        }
        var call = CallModel.fromMap(snapshot.data.data);
        if (call.calling) {
          switch (call.response) {
            case 'Awaiting':
              return Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      
                      child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                        CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(call.callerPic),
                    ),
                    SizedBox(height:10),
                    Text('${call.callerName} is calling you',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black
                    ),
                    ),
                      ],),
                    ),
                    
                   
                     
                    Container(
                      height: 100,
                      margin: const EdgeInsets.only(bottom:100),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            backgroundColor: Colors.green,
                            key: UniqueKey(),
                            child: Icon(call.calltype == 'VideoCall'
                                ? Icons.video_call
                                : Icons.call),
                            onPressed: () async {
                               await FlutterRingtonePlayer.stop();
                              snapshot.data.reference.updateData(
                                  {'calling': true, 'response': 'Pickup'});
                            },
                          ),
                          FloatingActionButton(
                            backgroundColor: Colors.redAccent,
                            key: UniqueKey(),
                            child: Icon(Icons.clear),
                            onPressed: () async {
                              snapshot.data.reference.updateData(
                                  {'calling': false, 'response': 'Cancled'});
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            case 'Pickup':
              return CallPage(
                channelName: call.channelId,
                callType: call.calltype,
                role: ClientRole.Broadcaster,
              );
            default:
              return Center(child: Text('Call ended'));
          }
        }
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if(!haspoped){
            haspoped=true;
          Navigator.pop(context);
          }
        });

        return Center(child: Text('Call ended'));
      },
    ));
  }
}
