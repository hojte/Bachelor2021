import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/bleUI.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';
import 'package:ituvidit/mountManualController.dart';
import 'package:tflite/tflite.dart';
import 'camera.dart';

class HomeHooks extends HookWidget{
  final List<CameraDescription> cameras;
  HomeHooks(this.cameras);

  loadModel() async {
    String res;
    res = await Tflite.loadModel(
        model: "assets/lite-model_ssd_mobilenet_v1_1_metadata_2.tflite",
        labels: "assets/ssd_mobilenet.txt");
    print(res);
  }
  Widget remoteControls(BuildContext context, BluetoothCharacteristic bleCharacteristic){
    return ElevatedButton(
      style: ElevatedButton.styleFrom(primary: Colors.teal[300]),
      child: Text("Mount Remote Controls", style: TextStyle(color: Colors.black),),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => MountManualController(bleCharacteristic),
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //Values and setter used for debugmode in the drawer
    final debugModeValue = useState(true);
    void setDebugModeValue(bool val){
      debugModeValue.value = val;
    }

    final gridViewValue = useState(false);
    void setGridViewValue(bool val){
      gridViewValue.value = val;
    }

    final bleCharacteristic = useState();
    void setCharacteristic(BluetoothCharacteristic characteristic){
      bleCharacteristic.value = characteristic;
    }

    final isTracking = useState(false);
    Widget renderStartTrackingButton() {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: Colors.teal[300]),
        child: Text(
          "Start Tracking",
          style: TextStyle(color: Colors.black),
        ),
        onPressed: () {
          loadModel();
          isTracking.value = true;
        },
      );
    }

    return(
        Scaffold(
          appBar: AppBar(
            leading: isTracking.value ? IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                isTracking.value = false;
              },
            ) : null,
            title: Text("VidIt"),
            flexibleSpace: CustomAppBarDesign(),
          ),
          endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value, setGridViewValue, gridViewValue.value),
          backgroundColor: appBarPrimary,
          body: !isTracking.value ?
          Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  renderStartTrackingButton(),
                  FlutterBlueWidget(setCharacteristic),
                  remoteControls(context, bleCharacteristic.value),
                ],
              ),
          )
              : Stack(
            children: [
              Camera(
                cameras,
                bleCharacteristic.value,
                debugModeValue,
                gridViewValue
              ),
            ],
          ),
        )
    );
  }
}