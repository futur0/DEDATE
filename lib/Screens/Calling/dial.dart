import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u/models/user_model.dart';
import 'package:hookup4u/util/color.dart';
import 'call.dart';
class DialCall extends StatefulWidget {
  // final String channelName;
  final User receiver;
  final String callType;
  final User sender;
  const DialCall({this.receiver, this.callType,this.sender});

  @override
  _DialCallState createState() => _DialCallState();
}

class _DialCallState extends State<DialCall> {
  bool ispickup = false;
  final 
  //final db = Firestore.instance;
  CollectionReference callRef = Firestore.instance.collection("calls");
  @override
  void initState() {
    _addCallingData();
    super.initState();
  }

  _addCallingData() async {
    await callRef.document(widget.receiver.id).setData({
      'callType': widget.callType,
      'calling': true,
      'response': "Awaiting",
      'caller_name':widget.sender.name,
      'caller_pic':widget.sender.imageUrl,
      'channel_id': widget.receiver.id,
      'last_call': FieldValue.serverTimestamp()
    });
  }

  @override
  void dispose() async {
    super.dispose();
    // ispickup = true;
    // await callRef
    //     .document(widget.receiver.id)
    //     .setData({'calling': false}, merge: true);
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: StreamBuilder<DocumentSnapshot>(
              stream: callRef
                  .document(widget.receiver.id)
                  .snapshots(),
              builder: (_,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                    print('called');
          //  Future.delayed(Duration(seconds: 30), () async {
          //         if (!ispickup) {
          //           await callRef
          //               .document(widget.receiver.id)
          //               .updateData({'response': 'Not-answer'});
          //         }
          //       });
                if (!snapshot.hasData) {
                  return Container();
                } else
                  try {
                    switch (snapshot.data.data['response']) {
                      case "Awaiting":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: Colors.grey,
                                radius: 60,
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      60,
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          widget.receiver.imageUrl[0] ?? '',
                                      useOldImageOnUrlChange: true,
                                      placeholder: (context, url) =>
                                          CupertinoActivityIndicator(
                                        radius: 15,
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.error,
                                            color: Colors.black,
                                            size: 30,
                                          ),
                                          Text(
                                            "Enable to load",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Text("Calling to ${widget.receiver.name}...",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              RaisedButton.icon(
                                  color: primaryColor,
                                  icon: Icon(
                                    Icons.call_end,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "END",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    await callRef
                                        .document(widget.receiver.id)
                                        .updateData({'response': "Call_Cancelled"},
                                           );
                                    // Navigator.pop(context);
                                  })
                            ],
                          );
                        }
                        break;
                      case "Pickup":
                        {
                         return CallPage(
                               channelName:  widget.receiver.id,
                              role: ClientRole.Broadcaster,
                              callType: snapshot.data.data['callType'],
                            );
                          // Navigator.pushReplacement(context,
                          //   MaterialPageRoute(builder: (_)=>CallPage(
                          //      channelName:  widget.receiver.id,
                          //     role: ClientRole.Broadcaster,
                          //     callType: snapshot.data.data['callType'],
                          //   )));
                          // 
                        }
                        break;
                      case "Decline":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text("${widget.receiver.name} is Busy",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              RaisedButton.icon(
                                  color: primaryColor,
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "Back",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  })
                            ],
                          );
                        }
                        break;
                      case "Not-answer":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text("${widget.receiver.name} is Not-answering",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              RaisedButton.icon(
                                  color: primaryColor,
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "Back",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  })
                            ],
                          );
                        }
                        break;
                      //call end
                      default:
                        {
                          Navigator.pop(context);
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Call ended'),
                              ));
                          return Container(
                            child: Text("Call Ended..."),
                          );
                        }
                        break;
                    }
                  }
                  //  else if (!snapshot.data.documents[0]['calling']) {
                  //   Navigator.pop(context);
                  // }
                  catch (e) {
                    return Container();
                  }
              })),
    );
  }
}
