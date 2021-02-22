import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/main.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

const String ssd = "SSD MobileNet";

typedef void Callback(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;

  Camera(this.cameras, this.model, this.setRecognitions);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  CameraDescription camera;
  int cameraFlip =0;


  @override
  void initState() {
    super.initState();
    startCamera(camera);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void startCamera(CameraDescription camera){
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[cameraFlip],
        ResolutionPreset.medium,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
        print("juuuuuuuuuu " + controller.toString());

        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;

            int startTime = new DateTime.now().millisecondsSinceEpoch;

            Tflite.detectObjectOnFrame(
              bytesList: img.planes.map((plane) {
                return plane.bytes;
              }).toList(),
              model: "SSDMobileNet",
              imageHeight: img.height,
              imageWidth: img.width,
              imageMean: 127.5,
              imageStd: 127.5,
              numResultsPerClass: 1,
              threshold: 0.4,
            ).then((recognitions) {
              //print(recognitions);

              int endTime = new DateTime.now().millisecondsSinceEpoch;
              //print("Detection took ${endTime - startTime}");

              widget.setRecognitions(recognitions, img.height, img.width);

              isDetecting = false;
            });
          }
        });
      });
    }
  }

  void changeCameraLens() {
    // get current lens direction (front / rear)
    final lensDirection = controller.description.lensDirection;
    if (lensDirection == CameraLensDirection.front) {
      setState(() {
        cameraFlip =0;
      });
      camera = cameras[0];
    }
    else {
      setState(() {
        cameraFlip =1;
      });
      camera = cameras[1];
    }
    if (camera != null) {
      startCamera(camera);
    }
    else {
      print('Asked camera not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return Stack(
      children: [
        OverflowBox(
        maxHeight:
        screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
          maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
          child: CameraPreview(controller),
        ),
        Container(
          alignment: Alignment.topRight,
          child: FloatingActionButton(
            child: Icon(Icons.flip_camera_android),
            onPressed: () {
              changeCameraLens();
            },
          ) ,
        ),
      ],
    );
  }
}

