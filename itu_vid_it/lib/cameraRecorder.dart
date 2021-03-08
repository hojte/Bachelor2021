import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';

class cameraRecorder {
  CameraController controller;
  cameraRecorder(CameraController controller){
    this.controller = controller;
  }

  Future<void> startRecording() async{
    final CameraController cameraController = controller;
    try{
    await cameraController.prepareForVideoRecording();
    await cameraController.startVideoRecording();
    } on CameraException catch(e){
      e.toString();

    }
  }
  Future<XFile> endRecording() async {
    final CameraController cameraController = controller;

    try {
      return await cameraController.stopVideoRecording();
    } on CameraException catch(e){
      e.toString();
      return null;
    }
  }

  Future<String> storageDirectory() async{
    final Directory getDirectory = await getApplicationDocumentsDirectory();
    final String videoDirectory = '${getDirectory.path}/Videos';
    await Directory(videoDirectory).create(recursive: true);
    String time = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath = '$videoDirectory/$time.mp4';
    return filePath;

  }
}

