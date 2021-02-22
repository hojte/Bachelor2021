import 'package:camera_platform_interface/src/types/camera_description.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'bndbox.dart';
import 'camera.dart';



const String ssd = "assets/ssd_mobilenet.tflite";
class HomeHooks extends HookWidget{
  final List<CameraDescription> cameras;

  HomeHooks(this.cameras);

  loadModel() async {
    String res;
    res = await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
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
    final _model = useState("");

    Function setRecognitions(recognitions, imageHeight, imageWidth) {
      _recognitions.value = recognitions;
      _imageHeight.value = imageHeight;
      _imageWidth.value = imageWidth;

    }
    Function onSelect(model) {
      _model.value = model;
      loadModel();
    }

    return(
    Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: (){
            _model.value = "";
          },

        ),
        title: Text("VidIt"),
        flexibleSpace: CustomAppBarDesign(),
      ),
      endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value),
      backgroundColor: appBarPrimary,

      body: _model.value=="" ?
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              color: Colors.teal,
              child: const Text(
                ssd,
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () => onSelect(ssd),
            ),
          ],
        ),
      )

          : Stack(
        children: [
          Camera(
            cameras,
            _model.value,
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
          :Text(""),

        ],
      ),
    )
    );
  }
}