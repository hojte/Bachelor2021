
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

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
  TrackingData([this.wCoord = 0, this.xCoord = 0, this.hCoord = 0, this.yCoord = 0, this.xSpeed = 0, this.ySpeed = 0]);
  Map<String,dynamic> get map {
    return {
      "wCoord":wCoord,
      "xCoord":xCoord,
      "hCoord":hCoord,
      "yCoord":yCoord,
      "xSpeed":xSpeed,
      "ySpeed":ySpeed
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

      double xcenter = x + w/2.0;
      double ycenter = y + h/2.0;
      double minX = 0.45;
      double maxX = 0.55;
      double minY = 0.55;
      double maxY = 0.65;

      double xSpeed = calculateSpeed(xcenter);
      double ySpeed = calculateSpeed(ycenter)/10;
      String xAndYSpeed;
      if(tXSpeed == "0.0" && tYSpeed=="0.0"){
        xAndYSpeed = xSpeed.toString()+":"+ySpeed.toString();
      }
      else{
        xAndYSpeed= tXSpeed+":"+tYSpeed;
      }

      if(ycenter<minY && xcenter > maxX){
        return "U&R:"+xAndYSpeed;
      }
      else if(ycenter<minY && xcenter<minX){
        return "U&L:"+xAndYSpeed;
      }
      else if(ycenter > maxY && xcenter > maxX){
        return "D&R:"+xAndYSpeed;
      }
      else if(ycenter > maxY && xcenter<minX){
        return "D&L:"+xAndYSpeed;
      }
      else if(xcenter > maxX){
        return "R:"+xAndYSpeed;
      }
      else if(xcenter<minX){
        return "L:"+xAndYSpeed;
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
  }

  double calculateSpeed(double position){
    //print(position);
    double maxSpeed = 750.0;
    double mediumSpeed = 500.0;
    double minSpeed = 250.0;
    if(position>0.0 && position<0.125 || position>0.875 && position<1.0 ) return maxSpeed;
    else if (position>0.125 && position <0.25 || position>0.75 && position<0.875) return mediumSpeed;
    else if (position>0.25 && position <0.375 || position>0.625 && position<0.75) return minSpeed;
    //else if (position>0.375 && position <0.5 || position>0.5 && position<0.625) return minSpeed;
    else return 0.0;
  }



  String get checkData{
    if(trackingData.xCoord == 0 && trackingData.wCoord == 0 && trackingData.yCoord == 0 && trackingData.hCoord == 0) return "No data";
    return "Data looks fine";
  }
}