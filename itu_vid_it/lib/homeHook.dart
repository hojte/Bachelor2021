import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tflite/tflite.dart';

import 'package:ituvidit/bleUI.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';
import 'package:ituvidit/mountManualController.dart';

import 'camera.dart';

class HomeHooks extends HookWidget{
  final List<CameraDescription> cameras;
  PermissionStatus permission;
  HomeHooks(this.cameras);

  loadModel() async {
    await Tflite.loadModel(
        numThreads: 4, // unsure if this helps performance
        useGpuDelegate: true, // only release
        model: "assets/lite-model_ssd_mobilenet_v1_1_metadata_2.tflite",
        labels: "assets/ssd_mobilenet.txt");
  }

  Future<void> checkPermissions() async {
    permission = await Permission.camera.status;
    if (permission.isGranted) {
      // do nothing
    } else{
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
        Permission.camera,
      ].request();
      permission = await Permission.camera.status;
    }
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
    checkPermissions();

    final isTracking = useState(false);
    Widget renderStartTrackingButton() {
      return TextButton(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Text(
                    "Start Tracking",
                    style: TextStyle(color: Colors.black, fontSize: 35),
                  ),
                  Container(width: 200, padding: EdgeInsets.only(top: 100))
                ],
              ),
              Icon(Icons.send_sharp, color: Colors.black, size: 80,)]),
        onPressed: () async {
          if(permission.isDenied || permission.isUndetermined || permission.isPermanentlyDenied || permission.isLimited){
            await checkPermissions();
            if(permission.isGranted){
              loadModel();
              isTracking.value = true;
            }
          } else{
            loadModel();
            isTracking.value = true;
          }
        },
      );
    }
    Widget renderRemoteControlButton() {
      return TextButton(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Text(
                    "Controls",
                    style: TextStyle(color: bleCharacteristic.value != null ?
                    Colors.black : Colors.white.withOpacity(0.3), fontSize: 35),
                  ),
                  bleCharacteristic.value == null ? Container(
                      width: 250,
                      padding: EdgeInsets.only(top: 100),
                      child: Text(
                          "No mount connected",
                          style: TextStyle(color: Colors.white.withOpacity(0.3)))
                  ) : Container(width: 200,),
                ],
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
          endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value, setGridViewValue, gridViewValue.value),
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
                  gridViewValue
              ),
            ],
          ),
        )
    );
  }
}