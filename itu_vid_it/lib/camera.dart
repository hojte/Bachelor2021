import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ituvidit/gridView.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/mountController.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:image/image.dart' as imglib;
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

import 'bndbox.dart';
import 'colors.dart';

final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

typedef void Callback(List<dynamic> list, int h, int w, TrackingData trackingData);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final BluetoothCharacteristic _bleCharacteristic;
  final debugModeValue;
  Camera(this.cameras, this._bleCharacteristic, this.debugModeValue);

  @override
  _CameraState createState() => new _CameraState(debugModeValue);
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  CameraDescription camera;
  TrackingData _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0,0.0);
  int useFrontCam = 0;
  bool isRecording = false;
  bool isSaving = false;
  bool isProcessingVideo = false;
  String videoDirectory;
  int currentFrameIndex = 0;
  int currentSavedIndex = 0;
  int imgWidth = 1920;
  int imgHeight = 1080;
  Timer timer;
  int recordSeconds = 0;
  final debugModeValue;
  List<dynamic> filteredRecognitions = [];

  int deviceRotation;
  int deviceRotationOnRecordStart;
  int recordStartTime;
  _CameraState(this.debugModeValue);
  String fileType = Platform.isAndroid ? 'jpg' : 'bgra';
  NativeDeviceOrientation nativeDeviceOrientation;
  NativeDeviceOrientation nativeDeviceOrientationOnStartRec;

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    if (isRecording) stopRecording();
    super.dispose();
  }

  //Returns when we are done saving images
  Future<void> waitForSave() async {
    if (currentFrameIndex == currentSavedIndex) return;
    //wait a bit more for last images to be saved
    await Future.delayed(Duration(milliseconds: 200)); //fixme not good practise
    print('done saving');
    return;
  }

  Future<int> saveTemporaryFile(index, img) async {
    String filePath = '$videoDirectory/VidIT$index.$fileType';
    if (Platform.isAndroid)
      await File(filePath).writeAsBytes(img.planes[0].bytes);
    if (Platform.isIOS)
      await File(filePath).writeAsBytes(imglib.Image.fromBytes( //maybe
        img.width,
        img.height,
        img.planes[0].bytes,
        format: imglib.Format.bgra,
      ).getBytes());
    //await File(filePath).writeAsBytes(img.planes[0].bytes); // maybe II
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
          if (deviceRotation == 0) // update native rotation
            NativeDeviceOrientationCommunicator().orientation()
                .then((rotation) => nativeDeviceOrientation = rotation);
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
            else if (Platform.isIOS) imageToBeAnalyzed = imglib.Image.fromBytes(
              img.width,
              img.height,
              img.planes[0].bytes,
              format: imglib.Format.bgra,
            );

            imageToBeAnalyzed = imglib.copyResize(imageToBeAnalyzed, width: 300, height: 300);
            if (mounted)
              switch (MediaQuery.of(context).orientation) {
                case Orientation.portrait:
                  deviceRotation = 90;
                  break;
                case Orientation.landscape:
                  deviceRotation = 0;
                  break;
              }
            imageToBeAnalyzed = imglib.copyRotate(imageToBeAnalyzed, deviceRotation);
            if (useFrontCam == 1) {
              if(Platform.isAndroid){
                imageToBeAnalyzed = imglib.flipVertical(imageToBeAnalyzed);
                if (deviceRotation == 0 && nativeDeviceOrientation == NativeDeviceOrientation.landscapeLeft) {
                  imageToBeAnalyzed = imglib.flipHorizontal(imageToBeAnalyzed);
                  imageToBeAnalyzed = imglib.flipVertical(imageToBeAnalyzed);
                }
              }
              if(Platform.isIOS){
                if(nativeDeviceOrientation == NativeDeviceOrientation.landscapeRight) {
                  imageToBeAnalyzed = imglib.flipHorizontal(imageToBeAnalyzed);
                  imageToBeAnalyzed = imglib.flipVertical(imageToBeAnalyzed);
                }
              }
            }

            else if (deviceRotation == 0 && nativeDeviceOrientation == NativeDeviceOrientation.landscapeRight){
              imageToBeAnalyzed = imglib.flipHorizontal(imageToBeAnalyzed);
              imageToBeAnalyzed = imglib.flipVertical(imageToBeAnalyzed);
            }
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
    else if (Platform.isAndroid) getDirectory = await pathProvider.getExternalStorageDirectory();
    videoDirectory = '${getDirectory.path}/tmp';
    await Directory(videoDirectory).create(recursive: true);
    print('Directory created @ $videoDirectory');
    deviceRotationOnRecordStart = deviceRotation;
    nativeDeviceOrientationOnStartRec = await NativeDeviceOrientationCommunicator().orientation();
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
      String saveTimeStamp = DateTime.now().toIso8601String();
      var argumentsFFMPEG = [
        '-r', realFrameRate.toString(), // Frames saved/recorded
        '-i', '$videoDirectory/VidIT%d.$fileType',
        '-preset', 'ultrafast',
      ];
      // check if in portrait mode
      if(deviceRotationOnRecordStart==90 && useFrontCam == 1)
        argumentsFFMPEG.addAll(['-vf', 'transpose=2']); //90 counter clockwise
      else if(deviceRotationOnRecordStart==90)
        argumentsFFMPEG.addAll(['-vf', 'transpose=1']); // 90 clockwise
      else if(nativeDeviceOrientationOnStartRec == NativeDeviceOrientation.landscapeRight)
        argumentsFFMPEG.addAll(['-vf', 'transpose=2,transpose=2']); //upside down 180
      argumentsFFMPEG.add('$videoDirectory/aVidITCapture$saveTimeStamp.mp4');

      _flutterFFmpeg.executeWithArguments(argumentsFFMPEG)
          .then((rc) {
        print("FFmpeg process exited with rc $rc");
        GallerySaver.saveVideo(videoDirectory+'/aVidITCapture$saveTimeStamp.mp4').then((value) {
          print("saved: $value");
          isProcessingVideo = false;
          //Delete MP4:
          File(videoDirectory+'/aVidITCapture$saveTimeStamp.mp4').delete();
          if(mounted) setState(() {}); // update state, trigger rerender
        });
        // CleanUp
        for (int i = 1; i<currentSavedIndex+1; i++) {
          File("$videoDirectory/VidIT$i.$fileType").delete();
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


        _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, 0.0,0.0);

      } else if (Platform.isIOS) {
        String wCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[1].replaceFirst("w: ", "").trim();
        String xCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[2].replaceFirst("x: ", "").trim();
        String hCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[3].replaceFirst("h: ", "").replaceFirst("}}", "").trim();
        String yCoord= filteredRecognitions[0].toString().split("rect:")[1].split(",")[0].replaceFirst("{y: ","").trim();

        _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, 0.0,0.0);
      }
    }
    else{
      _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0,0.0);
    }
    isDetecting = false;
    if(mounted) setState(() {}); // update state, trigger rerender
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    Size screen = MediaQuery.of(context).size;

    Widget renderRecordIcon() {
      if (isProcessingVideo) return CircularProgressIndicator();
      else if (isRecording) return Icon(Icons.stop, color: Colors.red);
      else return Icon(Icons.fiber_manual_record_rounded, color: Colors.red);
    }

    int previewH = math.max(imgHeight, imgWidth);
    int previewW = math.min(imgHeight, imgWidth);

    return Stack(
      children: [
        OverflowBox(
          maxHeight: screen.height,
          //minHeight: screen.height,
          maxWidth: screen.width,
          minWidth: screen.width,
          child: CameraPreview(controller),
        ),
        debugModeValue.value ?
        Stack(
          children: [
            BndBox(
              filteredRecognitions,
              previewH,
              previewW,
              screen.height,
              screen.width,
            ),
            //Spread operator === ULÆKKERT
            ...Grids(screen),
              ],
            )

            :
        Container(),
        Container(
          alignment: Alignment.topRight,
          margin: EdgeInsets.only(top: 20),
          child: IconButton(
            icon: Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: () {
              changeCameraLens();
            },
            iconSize: 40,
          ) ,
        ),


        MountController(_trackingData, widget._bleCharacteristic),

        Container(
            alignment: Alignment.bottomCenter,
            margin: EdgeInsets.all(25),
            child: new Material(
              color: Colors.transparent,
              child: Ink(
                decoration: ShapeDecoration(
                    color: appBarSecondary.withOpacity(0.3),
                    shape: CircleBorder()
                ),
                child: IconButton(
                  icon: renderRecordIcon(),
                  onPressed: () {
                    isRecording ? stopRecording() : startRecording();
                  },
                  iconSize: 40,
                ),
              ),
            )

        ),
        Text("${(recordSeconds/60/60).floor()}:${(recordSeconds/60).floor()-(recordSeconds/60/60).floor()*60}:${recordSeconds-(recordSeconds/60).floor()*60}"),
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

