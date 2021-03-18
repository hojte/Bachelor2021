import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/mountController.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:image/image.dart' as imglib;
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'bndbox.dart';

final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

typedef void Callback(List<dynamic> list, int h, int w, TrackingData trackingData);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final BluetoothCharacteristic _bleCharacteristic;
  final debugModeValue;
  final screen;
  Camera(this.cameras, this._bleCharacteristic, this.debugModeValue, this.screen);

  @override
  _CameraState createState() => new _CameraState(debugModeValue, screen);
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  CameraDescription camera;
  TrackingData _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0);
  int useFrontCam = 0;
  bool isRecording = false;
  bool isSaving = false;
  bool isProcessingVideo = false;
  String videoDirectory;
  int currentFrameIndex = 0;
  int currentSavedIndex = 0;
  int imgWidth = 1920;
  int imgHeight = 1080;
  int deviceRotation;
  Timer timer;
  int recordSeconds = 0;
  final debugModeValue;
  List<dynamic> filteredRecognitions = [];
  Size screen;
  int deviceRotationOnRecordStart;
  int recordStartTime;
  _CameraState(this.debugModeValue, this.screen);


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

  //Returns when we are done saving images
  Future<void> waitForSave() async {
    if (currentFrameIndex == currentSavedIndex) return;
    //wait a bit more for last images to be saved
    await Future.delayed(Duration(milliseconds: 500)); //fixme not good practise
    print('done saving');
    return;
  }

  Future<int> saveTemporaryFile(index, img) async {
    String filePath = '$videoDirectory/VidIT$index.jpg';
    await File(filePath).writeAsBytes(img.planes[0].bytes);
    return index;
  }

  void startCamera() {
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[useFrontCam],
        ResolutionPreset.veryHigh,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888
      );

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {}); //update state

        controller.startImageStream((CameraImage img) {
          if (isRecording) {
            currentFrameIndex++;
            isSaving = true;
            saveTemporaryFile(currentFrameIndex, img).then((value) {
              //print("saved $value/$currentFrameIndex");
              currentSavedIndex = value;
            });
          }
          if (!isDetecting) {
            isDetecting = true;
            imglib.Image imageToBeAnalyzed;
            if(Platform.isAndroid)
              imageToBeAnalyzed = imglib.decodeJpg(img.planes[0].bytes);
            else imageToBeAnalyzed = imglib.Image.fromBytes(
              img.width,
              img.height,
              img.planes[0].bytes,
              format: imglib.Format.bgra,
            );
            imageToBeAnalyzed = imglib.copyResize(imageToBeAnalyzed, width: 300, height: 300);
            switch (MediaQuery.of(context).orientation) {
              case Orientation.portrait:
                deviceRotation = 90;
                break;
              case Orientation.landscape:
                deviceRotation = 0;
                break;
            }
            imageToBeAnalyzed = imglib.copyRotate(imageToBeAnalyzed, deviceRotation);
            if (useFrontCam == 1) imageToBeAnalyzed = imglib.flipVertical(imageToBeAnalyzed);
              Tflite.detectObjectOnBinary(
                binary: imageToByteListUint8(imageToBeAnalyzed, 300),
                model: "SSDMobileNet",
                numResultsPerClass: 3,
                threshold: 0.45,
              ).then((recognitions) {
                handleRecognitions(recognitions);
              });
          }
        });
      });
    }
  }

  void startRecording() async {
    Directory getDirectory;
    if (Platform.isIOS) getDirectory = await pathProvider.getTemporaryDirectory();
    else getDirectory = await pathProvider.getExternalStorageDirectory();
    String time = DateTime.now().toIso8601String();
    videoDirectory = '${getDirectory.path}/Videos/VidITDir-$time';
    await Directory(videoDirectory).create(recursive: true);
    print('dir created @ $videoDirectory');
    deviceRotationOnRecordStart = deviceRotation;
    isRecording = true;
    recordStartTime = DateTime.now().millisecondsSinceEpoch;
    recordSeconds = 0;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      recordSeconds++;
    });
  }

  void stopRecording() {
    isRecording = false;
    waitForSave().then((value) {
      isProcessingVideo = true;
      int exactTimeRecorded = DateTime.now().millisecondsSinceEpoch - recordStartTime;
      print('Exact time recorded = $exactTimeRecorded ms');
      int realFrameRate = (currentSavedIndex/(exactTimeRecorded/1000)).floor();
      print("Frames per second = $currentSavedIndex/${(exactTimeRecorded/1000)} = $realFrameRate");

      var argumentsFFMPEG = [
        '-r', realFrameRate.toString(), // Frames saved/recorded
        '-i', '$videoDirectory/VidIT%01d.jpg',
      ];
      if(deviceRotationOnRecordStart==90 && useFrontCam == 1) argumentsFFMPEG.addAll(['-vf', 'transpose=2']); //90 counter clockwise
      else if(deviceRotationOnRecordStart==90) argumentsFFMPEG.addAll(['-vf', 'transpose=1']); // 90 clockwise
      argumentsFFMPEG.add('$videoDirectory/aVidITCapture.mp4');

      _flutterFFmpeg.executeWithArguments(argumentsFFMPEG)
          .then((rc) {
        print("FFmpeg process exited with rc $rc");
        GallerySaver.saveVideo(videoDirectory+'/aVidITCapture.mp4').then((value) {
          print("saved: $value");
          isProcessingVideo = false;
          setState(() {}); // update state, trigger rerender
        });
        // CleanUp
        print("Deleting $currentSavedIndex files");
        for (int i = 1; i<currentSavedIndex+1; i++) {
          File("$videoDirectory/VidIT$i.jpg").delete();
        }
        currentFrameIndex = 0;
        currentSavedIndex = 0;
      });
      recordSeconds = 0;
      timer.cancel();
    });
  }

  void changeCameraLens() {
    // get current lens direction (front / rear)
    final lensDirection = controller.description.lensDirection;
    if (lensDirection == CameraLensDirection.front) {
      setState(() {
        //Back camera
        useFrontCam = 0;
      });
      camera = cameras[0];
    }
    else {
      setState(() {
        //Front camera
        useFrontCam = 1;
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

  void handleRecognitions(List<dynamic> recognitions) {
    //print(newRecognitions);
    //making a new list that only contains detectedClass: person
    var tempFilter = [];
    try {
      int newRecognitionIndex= recognitions.indexOf(recognitions.firstWhere((element) =>
      element.toString().contains("detectedClass: person")
          //todo --> slet linjen her for kun at tracke personer
          || element.toString().contains("detectedClass: bottle")));

      tempFilter.add(recognitions[newRecognitionIndex]);
    } catch(e) {
      // no person found
    }

    filteredRecognitions = tempFilter;

    if(filteredRecognitions.length>0){
      if (Platform.isAndroid) { // Android-specific code
        String wCoord= filteredRecognitions[0].toString().split(",")[0].replaceFirst("{rect: {w: ", "").trim();
        String xCoord= filteredRecognitions[0].toString().split(",")[1].replaceFirst("x: ", "").trim();
        String hCoord= filteredRecognitions[0].toString().split(",")[2].replaceFirst("h: ", "").trim();
        String yCoord= filteredRecognitions[0].toString().split(",")[3].replaceFirst("y: ", "").replaceFirst("}", "").trim();

        double testSpeed = 0.0;//todo --> fix this compared to earlier frame coords
        _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, testSpeed);

      } else if (Platform.isIOS) {
        String wCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[1].replaceFirst("w: ", "").trim();
        String xCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[2].replaceFirst("x: ", "").trim();
        String hCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[3].replaceFirst("h: ", "").replaceFirst("}}", "").trim();
        String yCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[0].replaceFirst("{y: ","").trim();

        double testSpeed = 0.0;//todo --> fix this compared to earlier frame coords
        _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, testSpeed);
      }
    }
    else{
      _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0);
    }
    isDetecting = false;
    setState(() {}); // update state, trigger rerender
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }
/*
    var tmpSize = MediaQuery.of(context).size;
    var screenH = math.max(tmpSize.height, tmpSize.width);
    var screenW = math.min(tmpSize.height, tmpSize.width);
    tmpSize = controller.value.previewSize;
    var previewH = math.max(tmpSize.height, tmpSize.width);
    var previewW = math.min(tmpSize.height, tmpSize.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;
*/
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    Widget renderRecordIcon() {
      if (isProcessingVideo) return CircularProgressIndicator();
      else if (isRecording) return Icon(Icons.stop_circle);
      else return Icon(Icons.slow_motion_video_sharp);
    }

    return Stack(
      children: [
        OverflowBox(
          maxHeight: height,
          // screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
          maxWidth: width,
          //screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
          child: CameraPreview(controller),
        ),
        debugModeValue.value ?
        BndBox(
          filteredRecognitions,
          math.max(imgHeight, imgWidth),
          math.min(imgHeight, imgWidth),
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

        !Platform.isIOS ? FloatingActionButton(
            child: renderRecordIcon(),
            backgroundColor: isRecording ? Colors.red : Colors.green,
            onPressed: () {
              isRecording ? stopRecording() : startRecording();
            }
        ) : Container(),
        Text("$recordSeconds"),
      ],
    );
  }
}

Uint8List imageToByteListUint8(imglib.Image image, int inputSize) {
  var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
  var buffer = Uint8List.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var i = 0; i < inputSize; i++) {
    for (var j = 0; j < inputSize; j++) {
      var pixel = image.getPixel(j, i);
      buffer[pixelIndex++] = imglib.getRed(pixel);
      buffer[pixelIndex++] = imglib.getGreen(pixel);
      buffer[pixelIndex++] = imglib.getBlue(pixel);
    }
  }
  return convertedBytes.buffer.asUint8List();
}

