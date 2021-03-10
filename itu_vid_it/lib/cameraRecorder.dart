import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

class CameraRecorder {
  CameraController recController;
  CameraDescription cameraDescription;
  CameraRecorder(this.cameraDescription);

  Future<void> startRecording() async {
    await initializeRecordController();
    await recController.prepareForVideoRecording();
    await recController.startVideoRecording();
  }
  Future<XFile> endRecording() async {
      return await recController.stopVideoRecording();
  }

  Future<String> storageDirectory() async{
    final Directory getDirectory = await pathProvider.getApplicationDocumentsDirectory();
    final String videoDirectory = '${getDirectory.path}/Videos';
    await Directory(videoDirectory).create(recursive: true);
    String time = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath = '$videoDirectory/VidITClip$time.mp4';
    return filePath;
  }

  Future initializeRecordController() async {
    //var cameras = await availableCameras();
    recController = new CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );
    await recController.initialize();
  }
}

