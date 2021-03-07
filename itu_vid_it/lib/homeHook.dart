import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/bluetooth.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';
import 'package:ituvidit/static.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'bndbox.dart';
import 'camera.dart';



class HomeHooks extends HookWidget{
  final List<CameraDescription> cameras;

  HomeHooks(this.cameras);

  loadModel() async {
    String res;
    res = await Tflite.loadModel(
        model: "assets/lite-model_ssd_mobilenet_v1_1_metadata_2.tflite",
        //model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt");
    print(res);
  }

  @override
  Widget build(BuildContext context) {
    //Values and setter used for debugmode in the drawer
    final debugModeValue = useState(true);
    void setDebugModeValue(bool val){
      debugModeValue.value = val;
    }

    Size screen = MediaQuery.of(context).size;
    final _recognitions = useState();
    final _imageHeight = useState(0);
    final _imageWidth = useState(0);
    final isTracking = useState(false);

    void setRecognitions(recognitions, imageHeight, imageWidth) {
      _recognitions.value = recognitions;
      _imageHeight.value = imageHeight;
      _imageWidth.value = imageWidth;

    }

    return(
        Scaffold(
          appBar: AppBar(
            //Only show backarrow if _model.value is not ""
            leading: !isTracking.value ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                isTracking.value = false;
              },
            ) : null,
            title: Text("VidIt"),
            flexibleSpace: CustomAppBarDesign(),
          ),
          endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value),
          backgroundColor: appBarPrimary,
          body: !isTracking.value ?
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  color: Colors.teal,
                  child: const Text(
                    "Start Tracking",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    loadModel();
                    isTracking.value = true;
                  },
                ),
                RaisedButton(
                  child: Text("Detect in Image"),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => StaticImage(),
                    ),
                    );
                  },
                ),
                FlutterBlueWidget(),
              ],
            ),
          )
              : Stack(
            children: [
              Camera(
                cameras,
                setRecognitions,
              ),
              debugModeValue.value ?
              BndBox(
                _recognitions.value == null ? [] : _recognitions.value,
                math.max(_imageHeight.value, _imageWidth.value),
                math.min(_imageHeight.value, _imageWidth.value),
                screen.height,
                screen.width,
              )
                  :
              Container(),
            ],
          ),
        )
    );
  }
}