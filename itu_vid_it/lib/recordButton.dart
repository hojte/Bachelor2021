import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ituvidit/camera.dart';
import 'package:ituvidit/cameraRecorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class RecordButton extends HookWidget{
  CameraDescription cameraDescription;
  final startCamera;
  RecordButton(this.cameraDescription, this.startCamera);



  @override
  Widget build(BuildContext context) {
    final recorder = useState(CameraRecorder(cameraDescription));
    final switchRecording = useState(false);
    return Container(
      alignment: Alignment.bottomCenter,
      child: FloatingActionButton(
        child: switchRecording.value ? Icon(Icons.stop_circle) : Icon(Icons.slow_motion_video_sharp),
        backgroundColor: switchRecording.value ? Colors.red : Colors.green,
        onPressed: () {
          if(!switchRecording.value){
            print('start video recording');
            //await recorder.value.initializeRecordController();
            recorder.value.startRecording().then((value) => null);
            startCamera();

            /*
            ImagePicker.pickVideo(source: ImageSource.camera).then((File file) {
              if (file != null) {
                var tempFile = file;
                GallerySaver.saveVideo(tempFile.path);

              }

            });*/

          }
          else{
            recorder.value.endRecording().then((xFile) {
              recorder.value.storageDirectory().then((path) {
                xFile.saveTo(path);
                print("Saved to $path");
              });
            });
          }
          switchRecording.value = !switchRecording.value;
        },
      ),


    );
  }


}