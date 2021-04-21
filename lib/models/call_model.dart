class CallModel{
  String channelId;
  String callerName;
  String callerPic;
  String response;
  String calltype;
  bool calling;
  CallModel.fromMap(Map<String,dynamic> map){
    this.channelId=map['channel_id'];
    this.callerName=map['caller_name'];
    this.calltype=map['callType'];
    try{
    this.callerPic=map['caller_pic'][0];
    }catch(e){}
    this.response=map['response'];
    this.calling=map['calling'];

  }

}