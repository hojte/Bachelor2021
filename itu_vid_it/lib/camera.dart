import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ituvidit/bleUI.dart';
import 'package:ituvidit/gridView.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/mountController.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:image/image.dart' as imglib;
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';

import 'bndbox.dart';
import 'colors.dart';

final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();

typedef void Callback(List<dynamic> list, int h, int w, TrackingData trackingData);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final BluetoothCharacteristic _bleCharacteristic;
  final debugModeValue;
  final gridViewValue;
  final autoZoomValue;
  final motEnabled;
  Camera(this.cameras, this._bleCharacteristic, this.debugModeValue, this.gridViewValue, this.autoZoomValue, this.motEnabled);

  @override
  _CameraState createState() => new _CameraState(debugModeValue, gridViewValue, autoZoomValue, motEnabled);
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  CameraDescription camera;
  TrackingData _trackingData = new TrackingData();
  int useFrontCam = 0;
  bool isRecording = false;
  FlutterAudioRecorder audioRecorder;
  String audioPath = '/VidIT_Audio';
  Recording audioFile;
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
  final gridViewValue;
  final autoZoomValue;
  final motEnabled;
  List<dynamic> detectedRecognitions = [];
  List<dynamic> trackedRecognition = []; // Previous locations of tracked object
  int objectMissingCount = 0;

  int deviceRotation;
  int deviceRotationOnRecordStart;
  int recordStartTime;
  _CameraState(this.debugModeValue, this.gridViewValue, this.autoZoomValue, this.motEnabled);
  String fileType = Platform.isAndroid ? 'jpg' : 'bgra';
  NativeDeviceOrientation nativeDeviceOrientation;
  NativeDeviceOrientation nativeDeviceOrientationOnStartRec;

  bool flashOn = false;

  bool bleValid = espCharacteristic!=null;
  Size screen;

  double maxX = 0.6;
  double minX = 0.4;
  double minY = 0.5;
  double maxY = 0.7;

  double zoomVal = 1.0;

  int saveStartMillis = 0;
  double estimatedSaveTime = 5;


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
              numResultsPerClass: 5,
              threshold: 0.35,
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
    await initAudioRecording();
    await audioRecorder.start();
    isRecording = true;
    recordStartTime = DateTime.now().millisecondsSinceEpoch;
    recordSeconds = 0;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      recordSeconds++;
    });
  }

  Future<void> initAudioRecording() async {
    int recordAudioTime = DateTime.now().millisecondsSinceEpoch;

    var path = videoDirectory + audioPath + recordAudioTime.toString();
    audioRecorder = FlutterAudioRecorder(path, audioFormat: AudioFormat.WAV);
    await audioRecorder.initialized;
  }

  Future<int> lengthOfAudio(File audio) async{
    var info = await _flutterFFprobe.getMediaInformation(audio.path);
    var properties = info.getMediaProperties();
// the given duration is in milliseconds, assuming you want to have seconds I divide by 1000
    return (double.parse(properties['duration'])*1000).toInt();
  }

  void stopRecording() async {
    isRecording = false;
    isProcessingVideo = true;
    int exactTimeRecorded = DateTime.now().millisecondsSinceEpoch - recordStartTime;
    audioFile = await audioRecorder.stop();
    await waitForSave();
    int audioDuration = await lengthOfAudio(File(audioFile.path));
    print('Exact time audio = $audioDuration ms');
    print('Exact time recorded = $exactTimeRecorded ms');
    int durationForFPSCalculation = audioDuration ?? exactTimeRecorded;
    int realFrameRate = (currentSavedIndex/(durationForFPSCalculation/1000)).floor();
    print("Frames per second = $currentSavedIndex/${(durationForFPSCalculation/1000)} = $realFrameRate");
    estimatedSaveTime = 0.461*exactTimeRecorded - 844;
    saveStartMillis = DateTime.now().millisecondsSinceEpoch;

    String saveTimeStamp = DateTime.now().toIso8601String();
    //ffmpeg -loop 1 -i image.jpg -i audio.wav -c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p -shortest out.mp4
    var argumentsFFMPEG = [
      '-r', realFrameRate.toString(),
      '-i', '$videoDirectory/VidIT%d.$fileType',
      '-i', '${audioFile.path}',
      '-r', realFrameRate.toString(), // Frames saved/recorded
      '-t', (audioDuration/1000).toString(),
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
      GallerySaver.saveVideo(videoDirectory+'/aVidITCapture$saveTimeStamp.mp4', albumName: "VidIt").then((value) {
        new Directory('$videoDirectory').delete(recursive: true);
        isProcessingVideo = false;
        if(mounted) setState(() {}); // update state, trigger rerender
      });
      // CleanUp
      currentFrameIndex = 0;
      currentSavedIndex = 0;
    });
    recordSeconds = 0;
    timer.cancel();
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

  bool compareRecognition(dynamic r1, dynamic r2) {
    // topLeft offset check
    double threshold = motEnabled.value ? 0.2 : 0.5;
    bool xMatch = (r1["rect"]["x"]-r2["rect"]["x"]).abs() < threshold;
    bool yMatch = (r1["rect"]["y"]-r2["rect"]["y"]).abs() < threshold;
    //print('X:$xMatch Y:$yMatch');
    bool wMatch = (r1["rect"]["w"]-r2["rect"]["w"]).abs() < threshold;
    bool hMatch = (r1["rect"]["h"]-r2["rect"]["h"]).abs() < threshold;
    //print('W:$wMatch H:$hMatch');
    if (xMatch && yMatch && wMatch && hMatch)
      return true;
    return false;
  }

  void setTracked(dynamic recognition) {
    trackedRecognition.clear();
    trackedRecognition.add(recognition);
  }

  void handleRecognitions(List<dynamic> recognitions) {
    detectedRecognitions = recognitions
        .where((recognition) => (recognition["detectedClass"] == "person" && recognition["confidenceInClass"]>0.45) || recognition["detectedClass"] == "bottle" || recognition["detectedClass"] == "stop sign")
        .toList();
    if(!motEnabled.value && detectedRecognitions.length > 1)
      detectedRecognitions = detectedRecognitions.sublist(0, 1);
    bool matchFound = false;
    if (trackedRecognition.isNotEmpty) {
      for(int i = 0; i < detectedRecognitions.length && !matchFound; i++) {
        dynamic recognition = detectedRecognitions[i];
        if (compareRecognition(recognition, trackedRecognition.first)) {
          detectedRecognitions[i]['track'] = true;
          if(trackedRecognition.length > 3) trackedRecognition.removeLast(); // delete oldest
          trackedRecognition.insert(0, recognition);
          matchFound = true;
          objectMissingCount = 0;
        }
      }
      int smoothDuration = 10;
      if (!matchFound && ++objectMissingCount < smoothDuration) { // flicker for 10 consecutive frames ~ 1 sec
        trackedRecognition.first['flickerSmoother'] = true;
        detectedRecognitions.insert(0, trackedRecognition.first);
      }
      else if(objectMissingCount >= smoothDuration) {
        trackedRecognition.clear();
        _trackingData = new TrackingData();
      }
    }

    if (detectedRecognitions.isNotEmpty && !matchFound) {
      trackedRecognition.clear();
      detectedRecognitions[0]['trackShift'] = true;
      trackedRecognition.add(detectedRecognitions[0]); // Just track the highest score
    }
    if (detectedRecognitions.isEmpty && trackedRecognition.isEmpty) {
      trackedRecognition.clear();
      _trackingData = new TrackingData();

      //Used to zoom out if there is not detection
      zoom(0.0, 0.0, 0.0, 0.0);
    }
    if(trackedRecognition.isNotEmpty) {
      double wCoord = trackedRecognition.first["rect"]["w"];
      double xCoord = trackedRecognition.first["rect"]["x"];
      double hCoord = trackedRecognition.first["rect"]["h"];
      double yCoord = trackedRecognition.first["rect"]["y"];

      _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, 0.0, 0.0, useFrontCam==1, minX, maxX, minY, maxY);

      if(autoZoomValue.value){
        zoom(wCoord, hCoord, xCoord, yCoord);
      }
      else {
        zoomVal = 1.0;
        if(mounted && controller.value.isInitialized) controller.setZoomLevel(zoomVal);
      }

    }
    isDetecting = false;
    if(mounted) setState(() {}); // update state, trigger rerender
  }
  void validateBle(bool bleIsValid) {
    // todo: maybe if not valid, notify homeHook -> bleUI -> update connection, instead of going back to front page to reconnect...
    bleValid = bleIsValid;
  }

  void toggleFlash() {
    controller.setFlashMode(flashOn ? FlashMode.torch : FlashMode.off)
        .then((value) => flashOn = !flashOn)
        .onError((error, stackTrace) => null); // ignore failed flash toggle
  }

  void setGridOffsets(_maxX, _minX, _minY, _maxY) {
    maxX = _maxX;
    maxY = _maxY;
    minY = _minY;
    minX = _minX;
  }
  void zoom(double wCoord, double hCoord, double xCoord, double yCoord) {
    if(!mounted) return;
    var area = wCoord * hCoord;
    double zoomInAndOutValue = 0.1;
    double minimumZoomInArea;
    double maximumZoomInArea;
    double maximumZoomOutArea;
    double maximumHeight;
    double minimumHeight;

    double xcenter = xCoord + wCoord/2.0;

    if(MediaQuery.of(context).orientation == Orientation.portrait){
      minimumZoomInArea = 0.0;
      maximumZoomInArea = 0.2;
      maximumZoomOutArea = 0.4;
      maximumHeight = 0.7;
      minimumHeight = 0.8;
    }
    else{
      minimumZoomInArea = 0.0;
      maximumZoomInArea = 0.1;
      maximumZoomOutArea = 0.2;
      maximumHeight = 0.4;
      minimumHeight = 0.8;
    }
    if(objectMissingCount>8 && zoomVal > 1.0){
      zoomVal = zoomVal-zoomInAndOutValue;
      if(controller.value.isInitialized) controller.setZoomLevel(zoomVal);
    }
    else if (area>minimumZoomInArea && area<maximumZoomInArea && zoomVal < 8.0 && (xcenter>0.25 && xcenter<0.75) && hCoord<maximumHeight ){
      zoomVal = zoomVal+zoomInAndOutValue;
      if(controller.value.isInitialized) controller.setZoomLevel(zoomVal);
    }
    else {
      if((zoomVal > 1.0 && area>maximumZoomOutArea) || (zoomVal > 1.0 && hCoord>minimumHeight)) {
        zoomVal = zoomVal-zoomInAndOutValue;
        if(controller.value.isInitialized) controller.setZoomLevel(zoomVal);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: SizedBox(
          child: CircularProgressIndicator(),
          height: 60,
          width: 60,
        ),
      );
    }
    screen = MediaQuery.of(context).size;

    double progression = (DateTime.now().millisecondsSinceEpoch-saveStartMillis)/estimatedSaveTime;
    Widget renderRecordIcon() {
      if (isProcessingVideo) return CircularProgressIndicator(value: progression < 1 ? progression : null);
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
        if(debugModeValue.value)
          Stack(
            children: [
              BndBox(
                detectedRecognitions,
                setTracked,
                previewH,
                previewW,
                screen.height,
                screen.width,
              ),
              if (gridViewValue.value)
                Grids(screen, setGridOffsets)

              else Container(),
            ],
          )
        else if (gridViewValue.value) Grids(screen, setGridOffsets) else Container(),
        Container(
            alignment: Alignment.topRight,
            margin: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                IconButton(
                  icon: Platform.isAndroid ?
                  Icon(Icons.flip_camera_android, color: Colors.white) :
                  Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () {
                    changeCameraLens();
                  },
                  iconSize: 40,
                ),
                IconButton(
                  icon: flashOn ?
                  Icon(Icons.flash_on, color: Colors.white) :
                  Icon(Icons.flash_off, color: Colors.white),
                  onPressed: () => toggleFlash(),
                  iconSize: 40,
                ),
                bleValid ?
                Icon(Icons.bluetooth_connected, color: Colors.white) :
                Icon(Icons.bluetooth_disabled, color: Colors.white),
              ]
              ,)
        ),


        MountController(_trackingData, widget._bleCharacteristic, validateBle),

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

