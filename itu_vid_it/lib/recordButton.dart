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

class recordButton extends HookWidget{
  bool recording = false;
  CameraController controller;
  XFile xfile;

  recordButton(CameraController controller ){
    this.controller = controller;


  }

  @override
  Widget build(BuildContext context) {
    final switchRecording = useState(recording);
    return Container(
      alignment: Alignment.bottomCenter,
      child: FloatingActionButton(
        child: switchRecording.value ? Icon(Icons.stop_circle) : Icon(Icons.slow_motion_video_sharp),
        backgroundColor: switchRecording.value ? Colors.red : Colors.green,
        onPressed: () async {
          if(!switchRecording.value){
            //start recording
            //save to phone

            //await cameraRecorder(controller).startRecording();

            print('start video recording');
            await cameraRecorder(controller).startRecording();
            /*
            ImagePicker.pickVideo(source: ImageSource.camera).then((File file) {
              if (file != null) {
                var tempFile = file;
                GallerySaver.saveVideo(tempFile.path);

              }

            });*/

          }
          else{
            await cameraRecorder(controller).endRecording().then((file) {
              xfile = file;
             // GallerySaver.saveVideo(file);

            });
            /*
            var file = await cameraRecorder(controller).endRecording();
            videoFile = XFile(file.toString());
            var k = videoFile.;

            print('file' + videoFile.toString());
            print('Video is being saved');

            //videoFile.saveTo(cameraRecorder(controller).storageDirectory().toString());
            String time = DateTime.now().millisecondsSinceEpoch.toString();
            await GallerySaver.saveVideo();
*/



            }

          switchRecording.value = !switchRecording.value;
          recording = !recording;






        },
      ),


    );
  }


}