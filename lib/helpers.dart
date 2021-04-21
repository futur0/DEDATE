import 'package:permission_handler/permission_handler.dart';

Future<void> handleCameraAndMic(callType) async {
  await PermissionHandler().requestPermissions(callType == "VideoCall"
      ? [PermissionGroup.camera, PermissionGroup.microphone]
      : [PermissionGroup.microphone]);
}