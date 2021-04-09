
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
  TrackingData([this.wCoord = 0, this.xCoord = 0, this.hCoord = 0, this.yCoord = 0, this.xSpeed = 0, this.ySpeed = 0, this.isFrontCamera = false, ]);
  Map<String,dynamic> get map {
    return {
      "wCoord":wCoord,
      "xCoord":xCoord,
      "hCoord":hCoord,
      "yCoord":yCoord,
      "xSpeed":xSpeed,
      "ySpeed":ySpeed,
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
      double minX = 0.40;
      double maxX = 0.60;
      double minY = 0.50;
      double maxY = 0.80;

      double xSpeed = calculateSpeed(xcenter, minX, maxX);
      double ySpeed = calculateSpeed(ycenter,minY,maxY);
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
      else if(ycenter < minY){
        return "U:"+xAndYSpeed;
      }
      else if(ycenter > maxY){
        return "D:"+xAndYSpeed;
      }
      else return "H:"+xAndYSpeed;
    }
    //Dont return anything to keep motor moving
    return "H:"+"0.0";
  }

  double calculateSpeed(double position, double minBound, double maxBound){
    double maxSpeed = 750.0;
    double mediumSpeed = 500.0;
    double minSpeed = 300.0;

    double lowQuarter = (((1-minBound)/100)*25);
    double lowHalf = (((1-minBound)/100)*50);
    double highQuarter = (((1-maxBound)/100)*25)+maxBound;
    double highHalf = (((1-maxBound)/100)*50)+maxBound;

    if(position>0.0 && position<lowQuarter || position>highHalf && position<1.0 ) return maxSpeed;
    else if (position>lowQuarter && position <lowHalf || position>highQuarter && position<highHalf) return mediumSpeed;
    else if (position>lowHalf && position <minBound || position>maxBound && position<highQuarter) return minSpeed;
    else return 0.0;
  }

  String get checkData{
    if(trackingData.xCoord == 0 && trackingData.wCoord == 0 && trackingData.yCoord == 0 && trackingData.hCoord == 0) return "No data";
    return "Data looks fine";
  }
}