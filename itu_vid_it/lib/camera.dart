import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ituvidit/main.dart';
import 'package:ituvidit/mountController.dart';
import 'package:tflite/tflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'dart:math' as math;

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();


typedef void Callback(List<dynamic> list, int h, int w, TrackingData trackingData);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final BluetoothCharacteristic _bleCharacteristic;

  Camera(this.cameras, this.setRecognitions, this._bleCharacteristic);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  CameraDescription camera;
  TrackingData _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0);
  int cameraFlip = 0;
  File videoFile;
  bool isRecording = false;
  bool isSaving = false;
  String videoDirectory;
  int currentFrameIndex = 0;

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
    while(isSaving)
      await Future.delayed(Duration(seconds: 1));
    print('done saving');
    return;
  }

  Future<int> saveTemporaryFile(index, img) async {
    String filePath = '$videoDirectory/VidIT$index.yuv';
    await File(filePath).writeAsBytes(img.planes[0].bytes);
    return index;
  }

  void startCamera() {
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[cameraFlip],
        ResolutionPreset.max,
      );

      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            if (isRecording) {
              currentFrameIndex++;
              isSaving = true;
              File('$videoDirectory/VidIT.yuv').writeAsBytes(img.planes[0].bytes, mode: FileMode.append).then((value) => print('wrote'));
              //if (currentFrameIndex>9) stopRecording(); // for taking short test vids

              /*saveTemporaryFile(currentFrameIndex, img).then((frameSaved) {
                print('saved $frameSaved/$currentFrameIndex');
              });*/
              /*imgConvert.convertImageToPngBytes(img, filePath, currentFrameIndex).then((frameSaved) {
                print('saved=$frameSaved/$currentFrameIndex');
                if (!isRecording) {
                  if (frameSaved==currentFrameIndex) isSaving = false;
                }
              });*/

              // }
            }
            //isDetecting = true;
            //int startTime = new DateTime.now().millisecondsSinceEpoch;
            /*Tflite.detectObjectOnFrame(
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
                String wCoord= newRecognitions[0].toString().split(",")[0].replaceFirst("{rect: {w: ", "").trim();
                String xCoord= newRecognitions[0].toString().split(",")[1].replaceFirst("x: ", "").trim();
                String hCoord= newRecognitions[0].toString().split(",")[2].replaceFirst("h: ", "").trim();
                String yCoord= newRecognitions[0].toString().split(",")[3].replaceFirst("y: ", "").replaceFirst("}", "").trim();

                double testSpeed = 500.0;//todo --> fix this compared to earlier frame coords
                _trackingData = new TrackingData(wCoord, xCoord, hCoord, yCoord, testSpeed);
              }
              else{
                _trackingData = new TrackingData("0.0", "0.0", "0.0", "0.0", 0.0);
              }
              widget.setRecognitions(newRecognitions, img.height, img.width, _trackingData);
              isDetecting = false;
            });*/
          }
        });
      });
    }
  }

  void startRecording() async {
    //final Directory getDirectory = await pathProvider.getTemporaryDirectory();
    final Directory getDirectory = await pathProvider.getExternalStorageDirectory();
    String time = DateTime.now().toIso8601String();
    videoDirectory = '${getDirectory.path}/Videos/VidItPngSequence-$time';
    await Directory(videoDirectory).create(recursive: true);
    //final String filePath = '$videoDirectory/VidITClip$time.mp4'; // use when we can build mp4 succesfully
    print('dir created $videoDirectory');
    //videoFile = File(filepath);
    isRecording = true;
  }

  void stopRecording() {
    isRecording = false;
    //waitForSave().then((value) {
      print("COMPOSING MP4!!"); // todo> calculate framerate, input correct resolution based on img.height and width, correct format yuv/bgr
      _flutterFFmpeg.execute("-r 30 -f rawvideo -s 1280x720 -vcodec rawvideo -i $videoDirectory/VidIT.yuv -c:v libx264 -pix_fmt yuv420p $videoDirectory/LOL.mp4").then((rc) {
        print("FFmpeg process exited with rc $rc");
        print('Saving video');
        //GallerySaver.saveVideo(videoDirectory+'LOL.mp4');
        currentFrameIndex = 0;
      });
  //  });

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

        MountController(_trackingData, widget._bleCharacteristic),

        FloatingActionButton(
            child: isRecording ? Icon(Icons.stop_circle) : Icon(Icons.slow_motion_video_sharp),
            backgroundColor: isRecording ? Colors.red : Colors.green,
            onPressed: () {
              isRecording ? stopRecording() : startRecording();
            }
        ),
      ],
    );
  }
}

