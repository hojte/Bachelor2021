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

  @override
  Widget build(BuildContext context) {
    //Values and setter used for debugmode in the drawer
    final debugModeValue = useState(true);
    void setDebugModeValue(bool val){
      debugModeValue.value = val;
    }

    final bleCharacteristic = useState();
    void setCharacteristic(BluetoothCharacteristic characteristic){
      bleCharacteristic.value = characteristic;
    }

    final isTracking = useState(false);
    Widget renderStartTrackingButton() {
      return TextButton(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Start Tracking",
                style: TextStyle(color: Colors.black, fontSize: 35),
              ), Icon(Icons.send_sharp, color: Colors.black, size: 80,)]),
        onPressed: () {
          loadModel();
          isTracking.value = true;
        },
      );
    }
    Widget renderRemoteControlButton() {
      return TextButton(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Controls",
                style: TextStyle(color: bleCharacteristic.value != null ?
                Colors.black : Colors.white.withOpacity(0.3), fontSize: 35),
              ),
              Icon(Icons.control_camera, color: bleCharacteristic.value != null ?
              Colors.black : Colors.white.withOpacity(0.3), size: 80)]),
        onPressed: () {
          if (bleCharacteristic.value == null) return;
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => MountManualController(bleCharacteristic.value),
          ),
          );
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
          endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value),
          backgroundColor: appBarPrimary,
          body: !isTracking.value ?
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: renderStartTrackingButton()),
                Divider(thickness: 2,),
                Expanded(child: FlutterBlueWidget(setCharacteristic)),
                Divider(thickness: 2,),
                Expanded(child: renderRemoteControlButton()),
              ],
            ),
          )
              : Stack(
            children: [
              Camera(
                cameras,
                bleCharacteristic.value,
                debugModeValue,
              ),
            ],
          ),
        )
    );
  }
}