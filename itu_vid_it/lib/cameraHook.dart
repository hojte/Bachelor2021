import 'package:camera/camera.dart';
import 'package:camera_platform_interface/src/types/camera_description.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

import 'colors.dart';


typedef void Callback(List<dynamic> list, int h, int w);

class CameraHook extends HookWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;


  CameraHook(this.cameras, this.model, this.setRecognitions);


  @override
  Widget build(BuildContext context) {
    final isDetecting = useState(false);
    final cameraFlip = useState(0);
    final isMounted = useIsMounted();
    CameraController controller;
    controller = new CameraController(cameras[0], ResolutionPreset.medium);

    useEffect(() {
      controller.initialize();
      print("sdkflsajflsajfdsajflksajflksajlkdf "+controller.toString());
      // This will cancel the subscription when the widget is disposed
      // or if the callback is called again.
      //return controller.dispose();
    },
      // when the stream change, useEffect will call the callback again.
      [controller],
    );


    controller.dispose();

    return Text("data");
  }
}
