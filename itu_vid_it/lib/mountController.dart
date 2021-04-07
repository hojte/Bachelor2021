
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class MountController extends StatelessWidget{
  final TrackingData _trackingData;
  final BluetoothCharacteristic bleCharacteristic;
  final validateBle;

  MountController(this._trackingData, this.bleCharacteristic, this.validateBle(bool isBleValid));


  Future<bool> sendDataToESP(List<int> byteList) async {

    if(bleCharacteristic==null) return false;
    try {
      await bleCharacteristic.write(byteList, withoutResponse: true);
    } catch (e) {
      return false;
    }
    return true;
  }
  @override
  Widget build(BuildContext context) {
    ComputeData cd = ComputeData(_trackingData);

    //If no data is computed then it just keeps rotating to the direction of the previous direction
    if(cd.checkData == "Data looks fine"){
      //print(cd.boundingBoxCenter);
      sendDataToESP(utf8.encode(cd.boundingBoxCenter)).then((value) => validateBle(value));
    }
    return Container();
  }
}

class TrackingData {
  double wCoord;
  double xCoord;
  double hCoord;
  double yCoord;
  double xSpeed;
  double ySpeed;
  bool isFrontCamera;
  Size screen;
  TrackingData([this.wCoord = 0, this.xCoord = 0, this.hCoord = 0, this.yCoord = 0, this.xSpeed = 0, this.ySpeed = 0, this.screen, this.isFrontCamera = false, ]);
  Map<String,dynamic> get map {
    return {
      "wCoord":wCoord,
      "xCoord":xCoord,
      "hCoord":hCoord,
      "yCoord":yCoord,
      "xSpeed":xSpeed,
      "ySpeed":ySpeed,
      "screen": screen,
      "isFrontCamera": isFrontCamera
    };
  }

}

class ComputeData {
  TrackingData trackingData;
  ComputeData(this.trackingData);


  String get boundingBoxCenter {
    if(trackingData.xCoord != null){
      String tXSpeed =  trackingData.xSpeed.toString();
      String tYSpeed =  trackingData.ySpeed.toString();


      double x = trackingData.xCoord;
      double y = trackingData.yCoord;
      double w = trackingData.wCoord;
      double h = trackingData.hCoord;
      bool isFrontCam = trackingData.isFrontCamera;

      double xcenter = x + w/2.0;
      double ycenter = y + h/2.0;
      double minX = (trackingData.screen.width/100)*40;
      double maxX = (trackingData.screen.width/100)*60;
      double minY = (trackingData.screen.height/100)*50;
      double maxY = (trackingData.screen.height/100)*70;

      double xSpeed = calculateSpeed(xcenter);
      double ySpeed = calculateSpeed(ycenter)/5;
      String xAndYSpeed;
      if(tXSpeed == "0.0" && tYSpeed=="0.0"){
        xAndYSpeed = xSpeed.toString()+":"+ySpeed.toString();
      }
      else{
        xAndYSpeed= tXSpeed+":"+tYSpeed;
      }

      if(ycenter<minY && xcenter > maxX){

        return (isFrontCam ? "U&L:" : "U&R:")+xAndYSpeed ;
      }
      else if(ycenter<minY && xcenter<minX){
        return (isFrontCam ? "U&R:" : "U&L:")+xAndYSpeed;
      }
      else if(ycenter > maxY && xcenter > maxX){
        return (isFrontCam ? "D&L:" : "D&R:")+xAndYSpeed;
      }
      else if(ycenter > maxY && xcenter<minX){
        return (isFrontCam ? "D&R:" : "D&L:")+xAndYSpeed;
      }
      else if(xcenter > maxX){
        return (isFrontCam ? "L:" : "R:")+xAndYSpeed;
      }
      else if(xcenter<minX){
        return (isFrontCam ? "R:" : "L:")+xAndYSpeed;
      }
      else if(ycenter > maxY){
        return "D:"+xAndYSpeed;
      }
      else if(ycenter<minY){
        return "U:"+xAndYSpeed;
      }
      else return "H:"+xAndYSpeed;
    }
    //Dont return anything to keep motor moving
     return "H:"+"0.0";
  }

  double calculateSpeed(double position){
    //print(position);
    double maxSpeed = 750.0;
    double mediumSpeed = 500.0;
    double minSpeed = 250.0;

    if(position>0.0 && position<0.125 || position>0.875 && position<1.0 ) return maxSpeed;
    else if (position>0.125 && position <0.25 || position>0.75 && position<0.875) return mediumSpeed;
    else if (position>0.25 && position <0.4 || position>0.60 && position<0.75) return minSpeed;
    //else if (position>0.375 && position <0.5 || position>0.5 && position<0.625) return minSpeed;
    else return 0.0;
  }



  String get checkData{
    if(trackingData.xCoord == 0 && trackingData.wCoord == 0 && trackingData.yCoord == 0 && trackingData.hCoord == 0) return "No data";
    return "Data looks fine";
  }
}