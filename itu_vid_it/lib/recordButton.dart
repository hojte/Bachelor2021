import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class recordButton extends HookWidget{
  bool recording = false;
  CameraController controller;
  recordButton(CameraController controller){
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
        onPressed: (){
          if(!switchRecording.value){
            //start recording
            //save to phone
            controller.prepareForVideoRecording();
            controller.startVideoRecording();
            print('start video recording');

          }
          else{
            var file = controller.stopVideoRecording();
            print('stopping video recording');
            //controller.;
            }

          switchRecording.value = !switchRecording.value;
          recording = !recording;






        },
      ),


    );
  }


}