import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/mountController.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/recordButton.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;

import 'bndbox.dart';

typedef void Callback(List<dynamic> list, int h, int w, TrackingData trackingData);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final BluetoothCharacteristic _bleCharacteristic;
  final debugModeValue;
  final recognitions;
  final imageHeight;
  final imageWidth;
  Size screen;

  Camera(this.cameras, this.setRecognitions, this._bleCharacteristic, this.debugModeValue, this.recognitions, this.imageHeight, this.imageWidth, this.screen);

  @override
  _CameraState createState() => new _CameraState(debugModeValue, recognitions, imageHeight, imageWidth, screen);
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  CameraDescription camera;
  int cameraFlip =0;
  TrackingData _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0);
  final debugModeValue;
  final recognitions;
  final imageHeight;
  final imageWidth;
  Size screen;
  _CameraState(this.debugModeValue, this.recognitions, this.imageHeight, this.imageWidth, this.screen );


  @override
  void initState() {
    super.initState();
    startCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void startCamera(){
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[cameraFlip],
        ResolutionPreset.veryHigh,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});


        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;
            //int startTime = new DateTime.now().millisecondsSinceEpoch;

            Tflite.detectObjectOnFrame(
              bytesList: img.planes.map((plane) {return plane.bytes;}).toList(),
              model: "SSDMobileNet",
              imageHeight: img.height,
              imageWidth: img.width,
              numResultsPerClass: 5,
              threshold: 0.5,
              rotation: 90,
            ).then((recognitions) {
              //print(recognitions);


              //making a new list that only contains detectedClass: person
              List<dynamic> newRecognitions = List<dynamic>();
              try {
                int newRecognitionIndex= recognitions.indexOf(recognitions.firstWhere((element) =>
                element.toString().contains("detectedClass: person")
                    //todo --> slet linjen her for kun at tracke personer
                    || element.toString().contains("detectedClass: bottle")));

                newRecognitions.add(recognitions[newRecognitionIndex]);
              }catch(e) {
                // no person found
              }

              if(newRecognitions.length>0){
                if (Platform.isAndroid) {
                  String wCoord= newRecognitions[0].toString().split(",")[0].replaceFirst("{rect: {w: ", "").trim();
                  String xCoord= newRecognitions[0].toString().split(",")[1].replaceFirst("x: ", "").trim();
                  String hCoord= newRecognitions[0].toString().split(",")[2].replaceFirst("h: ", "").trim();
                  String yCoord= newRecognitions[0].toString().split(",")[3].replaceFirst("y: ", "").replaceFirst("}", "").trim();

                  double testSpeed = 0.0;//todo --> fix this compared to earlier frame coords
                  _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, testSpeed);

                  // Android-specific code
                } else if (Platform.isIOS) {

                  String wCoord= newRecognitions[0].toString().split("rect:")[1].split(",")[1].replaceFirst("w: ", "").trim();
                  String xCoord= newRecognitions[0].toString().split("rect:")[1].split(",")[2].replaceFirst("x: ", "").trim();
                  String hCoord= newRecognitions[0].toString().split("rect:")[1].split(",")[3].replaceFirst("h: ", "").replaceFirst("}}", "").trim();
                  String yCoord= newRecognitions[0].toString().split("rect:")[1].split(",")[0].replaceFirst("{y: ","").trim();

                  double testSpeed = 0.0;//todo --> fix this compared to earlier frame coords
                  _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, testSpeed);
                }
              }
              else{
                _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0);
              }
              widget.setRecognitions(newRecognitions, img.height, img.width, _trackingData);
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
        //Back camera
        cameraFlip = 0;
      });
      camera = cameras[0];
    }
    else {
      setState(() {
        //Front camera
        cameraFlip = 1;
      });
      camera = cameras[1];
    }
    if (camera != null) {
      startCamera();
    }
    else {
      print('Asked camera not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final switchRecording = false;
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
        debugModeValue.value ?
        BndBox(
          recognitions.value == null ? [] : recognitions.value,
          math.max(imageHeight.value, imageWidth.value),
          math.min(imageHeight.value, imageWidth.value),
          screen.height,
          screen.width,
        )
            :
        Container(),
        Container(
          alignment: Alignment.topRight,
          child: FloatingActionButton(
            child: Icon(Icons.flip_camera_android),
            onPressed: () {
            changeCameraLens();
            },
          ) ,
        ),


        MountController(_trackingData, widget._bleCharacteristic),

        recordButton(controller)

      ],
    );
  }
}

